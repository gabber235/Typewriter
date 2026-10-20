import type { CodeGenerator } from "skir-internal";

import { transferFieldName } from "../../symbols.js";
import {
  BLANK,
  indent,
  lines,
  quoted,
  render,
  separated,
  upperCamel,
  type Lines,
} from "../../text.js";
import { CONSUMER_NAME, grantSubject, type GrantToken } from "../grants.js";
import type { Delivery, RoleDeclaration, RoleDeclarations, ScopeKind } from "../manifest.js";
import {
  clientSubject,
  hasSide,
  routeChannel,
  type ResolvedRoute,
  type ResolvedRoutes,
} from "../resolve.js";
import type { Parameter, SubjectTemplate } from "../subject.js";

const PANEL_IMPORT = 'import "package:typewriter_panel/typewriter_panel.dart";';
const RECORD_ID_IMPORT =
  'import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart" as _skir;';

const HEADER =
  "// GENERATED CODE. DO NOT MODIFY BY HAND\n" +
  "// ignore_for_file: cascade_invocations, constant_identifier_names, curly_braces_in_flow_control_structures, no_leading_underscores_for_library_prefixes, unnecessary_this, use_raw_strings\n\n";

const dartString = (value: string) => quoted(value, "escaped");

/** One part of an interpolated Dart string: literal text or a validated identifier variable. */
type StringPart = { readonly text: string } | { readonly variable: string } | { readonly expression: string };

/** Renders parts as one interpolated Dart string literal, such as `"cloud.to.user.$user.create"`. */
function interpolated(parts: readonly StringPart[]): string {
  const body = parts
    .map((part) => {
      if ("text" in part) {
        return dartString(part.text).slice(1, -1);
      }
      return "variable" in part ? `$${part.variable}` : `\${${part.expression}}`;
    })
    .join("");
  return `"${body}"`;
}

/** Joins subject tokens with the `.` separator. */
function dotted(tokens: readonly StringPart[]): StringPart[] {
  return tokens.flatMap((token, index) => (index === 0 ? [token] : [{ text: "." }, token]));
}

/** A route scope identity as the generated Dart API takes it. */
interface ScopeParameter {
  readonly parameter: Parameter;
  readonly name: string;
  readonly type: "_skir.RecordId" | "String";
}

function scopeParameters(scope: ScopeKind): readonly ScopeParameter[] {
  const organization: ScopeParameter = {
    parameter: "organization",
    name: "organizationId",
    type: "_skir.RecordId",
  };
  const user: ScopeParameter = { parameter: "user", name: "userId", type: "String" };
  const service: ScopeParameter = { parameter: "service", name: "serviceId", type: "String" };
  switch (scope) {
    case "realm":
      return [organization, { parameter: "realm", name: "realmId", type: "_skir.RecordId" }];
    case "organization_actor":
      return [user, organization];
    case "organization":
      return [organization];
    case "user":
      return [user];
    case "service":
      return [service];
    case "internal_component":
      return [];
  }
}

function variableName(parameter: Parameter): string {
  return parameter === "transfer_id" ? "transfer" : parameter;
}

/** Each item is followed by a requested empty line, as the original generator spaced them. */
function spaced(items: readonly string[]): Lines {
  return items.flatMap((item) => [item, BLANK]);
}

function scopeSignature(scope: ScopeKind): Lines {
  return spaced(scopeParameters(scope).map(({ name, type }) => `required ${type} ${name},`));
}

/** Binds validated scope identities; with a subject, only the identities it captures. */
function scopeValues(scope: ScopeKind, subject?: SubjectTemplate): Lines {
  return spaced(
    scopeParameters(scope)
      .filter(({ parameter }) => !subject || subject.has(parameter))
      .map(({ parameter, name, type }) =>
        type === "_skir.RecordId"
          ? `final ${variableName(parameter)} = ${name}.id.transportIdentity;`
          : `final ${variableName(parameter)} = ${name}.transportIdentity;`,
      ),
  );
}

function scopeArguments(scope: ScopeKind): Lines {
  return spaced(scopeParameters(scope).map(({ name }) => `${name}: ${name},`));
}

function subjectExpression(template: SubjectTemplate, transferField?: string): string {
  const parts = template.tokens.map((token): StringPart => {
    if (token.kind === "literal") {
      return { text: token.value };
    }
    if (token.parameter === "transfer_id") {
      if (!transferField) {
        throw new Error("bounded Dart subject requires a transfer field");
      }
      return { expression: `${transferField}.transportTransfer` };
    }
    return { variable: variableName(token.parameter) };
  });
  return interpolated(dotted(parts));
}

/** Renders granted tokens as a Dart expression; wildcards become `*`. */
function grantExpression(tokens: readonly GrantToken[]): string {
  const parts = tokens.map((token): StringPart => {
    switch (token.kind) {
      case "literal":
        return { text: token.value };
      case "wildcard":
        return { text: "*" };
      case "parameter":
        return { variable: variableName(token.parameter) };
      case "consumer":
        throw new Error("panel subscriptions never name a consumer");
    }
  });
  return interpolated(dotted(parts));
}

/** Collects the import directives of the referenced Skir declarations. */
class Imports {
  private readonly directives = new Set<string>([PANEL_IMPORT, RECORD_ID_IMPORT]);

  /** Returns the symbol reference after recording its imports. */
  use(symbol: CodeGenerator.Symbol): string {
    for (const directive of symbol.imports) {
      this.directives.add(directive);
    }
    return symbol.reference;
  }

  lines(): Lines {
    return [...this.directives].sort();
  }
}

/** Dart expressions of the consumer identity tuple values, by {@link CONSUMER_NAME} entry. */
const CONSUMER_VALUES: Record<(typeof CONSUMER_NAME.tuple)[number], string> = {
  actor: "actor",
  organization: "organization",
  session: "session",
  projection: "projection",
};

const CONSUMER_RULE = lines(`String _persistentConsumerName({required String actor, required String? organization, required String session, required String projection}) {
    final identity = jsonEncode([${CONSUMER_NAME.tuple.map((name) => CONSUMER_VALUES[name]).join(", ")}]);
    final encoded = base64Url.encode(utf8.encode(identity)).replaceAll("=", "");
    return ${interpolated([{ text: CONSUMER_NAME.prefix }, { variable: "encoded" }])};
}`);

const RUNTIME = lines(String.raw`final class PersistentProjectionRoute {
    const PersistentProjectionRoute({required this.id, required this.organizationScoped});
    final String id;
    final bool organizationScoped;
    String consumerName(NatsClient client) {
        final organization = client.organizationId;
        if (organizationScoped && organization == null) {
            throw StateError("Persistent organization projection requires an admitted organization");
        }
        return _persistentConsumerName(
            actor: client.actorId.transportIdentity,
            organization: organizationScoped ? organization?.transportIdentity : null,
            session: client.connectionSession.transportSession,
            projection: id,
        );
    }
}`);

/** Names the Dart operation of a unary route, disambiguating routes that share a request type. */
function unaryOperationName(
  route: ResolvedRoute,
  { roles, routes }: ResolvedRoutes,
  requestKey: string,
): string {
  const collisions = routes.filter(
    (candidate) =>
      candidate.flow.kind === "unary" &&
      hasSide(candidate, roles, "panel") &&
      candidate.flow.method.request.record.key === requestKey,
  );
  if (collisions.length === 1) {
    return "operation";
  }
  const unique = route.operation
    .split(".")
    .reverse()
    .find((part) =>
      collisions.every(
        (candidate) => candidate.name === route.name || !candidate.operation.split(".").includes(part),
      ),
    );
  if (unique === undefined) {
    throw new Error(`cannot disambiguate Dart operation for ${route.name}`);
  }
  return `${unique}Operation`;
}

function emitUnary(
  route: ResolvedRoute,
  resolved: ResolvedRoutes,
  symbols: CodeGenerator.SymbolProvider,
  imports: Imports,
): Lines | undefined {
  const { flow } = route;
  if (flow.kind !== "unary" || !hasSide(route, resolved.roles, "panel")) {
    return undefined;
  }
  const requestAddress = clientSubject(route, "request");
  if (!requestAddress) {
    return undefined;
  }
  const method = imports.use(symbols.method(flow.method.module, flow.method.method));
  const requestType = imports.use(symbols.record(flow.method.request));
  const responseType = imports.use(symbols.record(flow.method.response));
  const operationName = unaryOperationName(route, resolved, flow.method.request.record.key);
  return [
    `extension ${dartName(route)}Nats on ${requestType} {`,
    `    SkirRouteOperation<${responseType}> ${operationName}({`,
    ...indent(scopeSignature(route.scope), 2),
    "    }) {",
    ...indent(scopeValues(route.scope), 2),
    ...lines(`        final method = ${method};
        return SkirRouteOperation(
            subject: ${subjectExpression(requestAddress)},
            requestBytes: method.requestSerializer.toBytes(this),
            responseSerializer: method.responseSerializer,
        );
    }
}`),
  ];
}

function deliveryExpression(delivery: Delivery, name: string): string {
  return delivery.kind === "transient"
    ? "const ProjectionDelivery.ephemeral()"
    : `ProjectionDelivery.persistent(
                stream: ${dartString(delivery.stream)},
                consumer: ${name}Projection.consumerName(ref.read(natsProvider)),
            )`;
}

/** The panel role parties that receive a channel of the route. */
function panelReceivers(
  route: ResolvedRoute,
  roles: RoleDeclarations,
  channel: "updates" | "event",
): RoleDeclaration[] {
  return (routeChannel(route, channel)?.receivers ?? []).flatMap((party) => {
    const role = "role" in party ? roles.get(party.role) : undefined;
    return role?.side === "panel" ? [role] : [];
  });
}

function emitWatch(
  route: ResolvedRoute,
  roles: RoleDeclarations,
  symbols: CodeGenerator.SymbolProvider,
  imports: Imports,
): Lines | undefined {
  const { flow } = route;
  if (flow.kind !== "watch" || !hasSide(route, roles, "panel")) {
    return undefined;
  }
  const requestAddress = clientSubject(route, "request");
  const updateAddress = clientSubject(route, "updates");
  if (!requestAddress || !updateAddress) {
    return undefined;
  }
  const eventType = imports.use(symbols.record(flow.updates.payload));
  const method = imports.use(symbols.method(flow.method.module, flow.method.method));
  const requestType = imports.use(symbols.record(flow.method.request));
  const responseType = imports.use(symbols.record(flow.method.response));
  const name = dartName(route);
  const { delivery } = flow.updates;
  // The consumer identity carries the organization exactly when the receiving role is bound to one.
  const organizationScoped = panelReceivers(route, roles, "updates").some((role) =>
    role.tenant.includes("organization"),
  );
  const projection =
    delivery.kind === "persistent"
      ? lines(`const ${name}Projection = PersistentProjectionRoute(
    id: ${dartString(delivery.projection)},
    organizationScoped: ${organizationScoped},
);`)
      : [];
  return [
    ...projection,
    `extension ${name}Nats on ${requestType} {`,
    `    SkirRouteOperation<${responseType}> operation({`,
    ...indent(scopeSignature(route.scope), 2),
    "    }) {",
    ...indent(scopeValues(route.scope), 2),
    ...lines(`        final method = ${method};
        return SkirRouteOperation(
            subject: ${subjectExpression(requestAddress)},
            requestBytes: method.requestSerializer.toBytes(this),
            responseSerializer: method.responseSerializer,
        );
    }

    Stream<TData> watch<TData>(Ref ref, {`),
    ...indent(scopeSignature(route.scope), 2),
    ...lines(`        required TData Function(${responseType}) snapshot,
        required TData Function(TData, ${eventType}) reduce,
        required ProjectionReconciliation<TData, ${responseType}, ${eventType}> reconciliation,
        Stream<${eventType}>? confirmedEvents,
        TData Function(TData, ${eventType})? reduceConfirmed,
        TData Function(TData, TData)? reconcileSnapshot,
        TData? initialValue,
    }) {`),
    // The operation validates the complete scope. Only bind identities the update subject uses.
    ...indent(scopeValues(route.scope, updateAddress), 2),
    "        final operation = this.operation(",
    ...indent(scopeArguments(route.scope), 3),
    ...lines(`        );
        return ref.watchProjection<TData, ${responseType}, ${eventType}>(
            subject: operation.subject,
            eventSubject: ${subjectExpression(updateAddress)},
            requestBytes: operation.requestBytes,
            responseSerializer: operation.responseSerializer,
            eventSerializer: ${eventType}.serializer,
            snapshot: snapshot, reduce: reduce, delivery: ${deliveryExpression(delivery, name)},
            reconciliation: reconciliation, confirmedEvents: confirmedEvents,
            reduceConfirmed: reduceConfirmed, reconcileSnapshot: reconcileSnapshot,
            initialValue: initialValue,
        );
    }
}`),
  ];
}

function emitBoundedWatch(
  route: ResolvedRoute,
  roles: RoleDeclarations,
  symbols: CodeGenerator.SymbolProvider,
  imports: Imports,
): Lines | undefined {
  const { flow } = route;
  if (flow.kind !== "bounded_watch" || !hasSide(route, roles, "panel")) {
    return undefined;
  }
  const requestAddress = clientSubject(route, "request");
  const updateAddress = clientSubject(route, "updates");
  if (!requestAddress || !updateAddress) {
    return undefined;
  }
  const method = imports.use(symbols.method(flow.method.module, flow.method.method));
  const requestType = imports.use(symbols.record(flow.method.request));
  const responseType = imports.use(symbols.record(flow.method.response));
  const field = `this.${transferFieldName(flow.transferField)}`;
  return [
    `extension ${dartName(route)}Nats on ${requestType} {`,
    `    Stream<${responseType}> watch(SkirMutationClient transport, {`,
    ...indent(scopeSignature(route.scope), 2),
    "    }) {",
    ...indent(scopeValues(route.scope), 2),
    ...lines(`        final method = ${method};
        return transport.watchRequest(
            ${subjectExpression(requestAddress)},
            ${subjectExpression(updateAddress, field)},
            method.requestSerializer.toBytes(this),
            method.responseSerializer,
        );
    }
}`),
  ];
}

function emitEvent(
  route: ResolvedRoute,
  roles: RoleDeclarations,
  symbols: CodeGenerator.SymbolProvider,
  imports: Imports,
): Lines | undefined {
  const { flow } = route;
  if (flow.kind !== "event" || flow.binding.kind !== "skir" || !hasSide(route, roles, "panel")) {
    return undefined;
  }
  const address = clientSubject(route, "event");
  if (!address) {
    return undefined;
  }
  const payloadType = imports.use(symbols.record(flow.binding.payload));
  const name = dartName(route);
  let projection: Lines = [];
  // A panel subscriber receiving every publisher's personal subject subscribes to a pattern and
  // reads the publisher back from each subject.
  const subscriber = panelReceivers(route, roles, "event").find(
    (role) => role.personal === "user" && address.has("user"),
  );
  if (subscriber) {
    const subscription = grantExpression(grantSubject(address, subscriber, true));
    let userIndex: number | undefined;
    const rejected = address.tokens.map((token, index) => {
      if (token.kind === "literal") {
        return `|| parts[${index}] != ${dartString(token.value)}`;
      }
      if (token.parameter === "organization") {
        return `|| parts[${index}] != organization`;
      }
      if (token.parameter === "user") {
        userIndex = index;
        return "";
      }
      throw new Error(`unsupported Dart event projection in ${route.name}`);
    });
    if (userIndex === undefined) {
      throw new Error("user projection has no user token");
    }
    projection = indent(
      lines(`static String subscriptionPattern({
    required _skir.RecordId organizationId,
}) {
    final organization = organizationId.id.transportIdentity;
    return ${subscription};
}

static String? userIdFromSubject(
    String subject, {
    required _skir.RecordId organizationId,
}) {
    final organization = organizationId.id.transportIdentity;
    final parts = subject.split(".");
    if (parts.length != ${address.tokens.length} ${rejected.join("")}) return null;
    final userId = parts[${userIndex}];
    return userId.isTransportIdentity ? userId : null;
}`),
    );
  }
  return [
    ...lines(`final class ${name}Event {
    const ${name}Event._();

    static final serializer = ${payloadType}.serializer;

    static String subject({`),
    ...indent(scopeSignature(route.scope), 2),
    "    }) {",
    ...indent(scopeValues(route.scope), 2),
    ...lines(`        return ${subjectExpression(address)};
    }
`),
    ...projection,
    "}",
  ];
}

function dartName(route: ResolvedRoute): string {
  return `${upperCamel(route.name)}Route`;
}

/**
 * Emits the panel transport routes: one extension per panel request route, an event class per panel
 * event, and the consumer naming rule of persistent projections. The backend owns the panel's
 * permissions; the panel never derives them.
 */
export function emitDart(
  resolved: ResolvedRoutes,
  symbols: CodeGenerator.SymbolProvider,
): CodeGenerator.OutputFile[] {
  const { roles } = resolved;
  const imports = new Imports();
  const declarations = resolved.routes.flatMap((route) => {
    const declaration =
      emitUnary(route, resolved, symbols, imports) ??
      emitWatch(route, roles, symbols, imports) ??
      emitBoundedWatch(route, roles, symbols, imports) ??
      emitEvent(route, roles, symbols, imports);
    return declaration ? [declaration] : [];
  });
  const body = separated([...declarations, RUNTIME, CONSUMER_RULE]);
  return [
    {
      path: "transport_routes.dart",
      code: HEADER + render([...imports.lines(), BLANK, ...body]),
    },
  ];
}
