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
import { routeGrants } from "../grants.js";
import type { Delivery, Direction, ScopeKind } from "../manifest.js";
import type { ResolvedRoute } from "../resolve.js";
import type { Parameter, SubjectTemplate } from "../subject.js";

const PANEL_IMPORT = 'import "package:typewriter_panel/typewriter_panel.dart";';
const RECORD_ID_IMPORT =
  'import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart" as _skir;';

const HEADER =
  "// GENERATED CODE. DO NOT MODIFY BY HAND\n" +
  "// ignore_for_file: cascade_invocations, constant_identifier_names, curly_braces_in_flow_control_structures, no_leading_underscores_for_library_prefixes, prefer_adjacent_string_concatenation, prefer_interpolation_to_compose_strings, unnecessary_this, use_raw_strings\n\n";

const dartString = (value: string) => quoted(value, "escaped");

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
    case "bound_service":
      return [service, organization];
    case "native":
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
          ? `final ${variableName(parameter)} = ${name}.id._transportIdentity;`
          : `final ${variableName(parameter)} = ${name}._transportIdentity;`,
      ),
  );
}

function scopeArguments(scope: ScopeKind): Lines {
  return spaced(scopeParameters(scope).map(({ name }) => `${name}: ${name},`));
}

function subjectExpression(template: SubjectTemplate, transferField?: string): string {
  return template.tokens
    .map((token) => {
      if (token.kind === "literal") {
        return dartString(token.value);
      }
      if (token.parameter === "transfer_id") {
        if (!transferField) {
          throw new Error("bounded Dart subject requires a transfer field");
        }
        return `${transferField}._transportTransfer`;
      }
      return variableName(token.parameter);
    })
    .join('+ "." +');
}

function grantSubject(
  template: SubjectTemplate,
  transferToken: boolean,
  wildcards: readonly Parameter[],
): string {
  return template.tokens
    .map((token) => {
      if (token.kind === "literal") {
        return dartString(token.value);
      }
      if (wildcards.includes(token.parameter)) {
        return '"*"';
      }
      if (token.parameter === "transfer_id") {
        if (!transferToken) {
          throw new Error("transfer grant requires a bounded wildcard");
        }
        return '"*"';
      }
      return variableName(token.parameter);
    })
    .join('+ "." +');
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

function realmDiscoveryParts(anchor: string): { prefix: string; suffix: string } {
  const realm = anchor.indexOf("{realm}");
  if (realm < 0) {
    throw new Error("Realm discovery anchor has no Realm token");
  }
  const prefix = anchor.slice(0, realm);
  const rest = anchor.slice(realm + "{realm}".length);
  if (prefix.includes("{")) {
    throw new Error("Realm discovery prefix contains an unresolved parameter");
  }
  const organization = rest.indexOf("{organization}");
  if (organization < 0) {
    throw new Error("Realm discovery suffix has no organization token");
  }
  const before = rest.slice(0, organization);
  const after = rest.slice(organization + "{organization}".length);
  if (before.includes("{") || after.includes("{")) {
    throw new Error("Realm discovery suffix contains an unsupported parameter");
  }
  return { prefix, suffix: `${dartString(before)} + organization + ${dartString(after)}` };
}

function permission(direction: Direction, expression: string): Lines {
  return [`${direction}.add(${expression});`, BLANK];
}

function panelPermissions(routes: readonly ResolvedRoute[]): Lines {
  const user: Array<string | typeof BLANK> = [];
  const organization: Array<string | typeof BLANK> = [];
  const realm: Array<string | typeof BLANK> = [];
  let realmAnchor: string | undefined;
  for (const route of routes) {
    const specs = routeGrants(route);
    route.grants.forEach((grant, index) => {
      if (grant.side !== "panel") {
        return;
      }
      const spec = specs[index]!;
      const expression = grantSubject(spec.endpoint, spec.transferToken, spec.wildcardParameters);
      if (route.scope === "user" && spec.role === "authenticated_user") {
        user.push(...permission(spec.direction, expression));
      } else if (
        (route.scope === "organization_actor" || route.scope === "organization") &&
        spec.role === "organization_member"
      ) {
        organization.push(...permission(spec.direction, expression));
      } else if (route.scope === "realm" && spec.role === "organization_member") {
        if (spec.direction === "publish" && !spec.transferToken && realmAnchor === undefined) {
          realmAnchor = spec.endpoint.toString();
        }
        realm.push(...permission(spec.direction, expression));
      } else {
        throw new Error(`unsupported panel grant scope in ${route.name}`);
      }
    });

    const { flow } = route;
    if (
      flow.kind !== "watch" ||
      flow.updates.delivery.kind !== "persistent" ||
      !flow.requests.has("panel")
    ) {
      continue;
    }
    const { stream, projection } = flow.updates.delivery;
    const event = flow.updates.addresses.get("panel");
    if (!event) {
      throw new Error(`persistent panel route ${route.name} has no update address`);
    }
    let target;
    if (route.scope === "user") {
      target = user;
    } else if (route.scope === "organization_actor" || route.scope === "organization") {
      target = organization;
    } else {
      throw new Error(`persistent panel route has unsupported scope ${route.scope}`);
    }
    target.push(
      ...lines(`_grantPersistentProjection(
    publish,
    stream: ${dartString(stream)},
    consumer: _persistentConsumerName(
        actor: user, organization: ${route.scope === "user" ? "null" : "organization"}, session: session,
        projection: ${dartString(projection)},
    ),
    filter: ${grantSubject(event, false, [])},
);`),
      BLANK,
    );
  }
  if (realmAnchor === undefined) {
    throw new Error("panel Realm grants need a discovery anchor");
  }
  const anchor = realmDiscoveryParts(realmAnchor);
  return [
    ...lines(String.raw`final class TransportPermissionGrant {
    TransportPermissionGrant({required Set<String> publish, required Set<String> subscribe})
        : publish = Set.unmodifiable(publish), subscribe = Set.unmodifiable(subscribe);
    final Set<String> publish;
    final Set<String> subscribe;
}

TransportPermissionGrant panelTransportPermissions({
    required String actorId,
    required _skir.RecordId? organizationId,
    required String connectionSession,
    required Iterable<_skir.RecordId> realmIds,
}) {
    final user = actorId._transportIdentity;
    final session = connectionSession._transportSession;
    final publish = <String>{"\$SYS.REQ.USER.INFO"};
    final subscribe = <String>{"_INBOX.$user.$session.*"};`),
    ...indent(user),
    ...lines(`    final organization = organizationId?.id._transportIdentity;
    final realms = realmIds.map((value) => value.id._transportIdentity).toSet();
    if (organizationId != null || realms.isNotEmpty) {
        if (organization == null) throw StateError("Realm permissions require an admitted organization");`),
    ...indent(organization, 2),
    "        for (final realm in realms) {",
    ...indent(realm, 3),
    ...lines(`        }
    }
    return TransportPermissionGrant(publish: publish, subscribe: subscribe);
}

extension GeneratedRealmAdmission on ServerPermissionSnapshot {
    Set<_skir.RecordId> admittedRealms(NatsClient client) {
        final organization = client.organizationId?._transportIdentity;
        if (organization == null) return const {};
        const prefix = ${dartString(anchor.prefix)};
        final suffix = ${anchor.suffix};`),
    ...lines(String.raw`        return publish.where((subject) => subject.startsWith(prefix) && subject.endsWith(suffix))
            .map((subject) => subject.substring(prefix.length, subject.length - suffix.length))
            .where((realm) => realm._isTransportIdentity)
            .map((realm) => _skir.RecordId(table: "realm_instance", key: _skir.RecordIdKey.wrapString(realm)))
            .where((realm) => realm.admittedBy(this, client)).toSet();
    }
}

extension GeneratedRealmPermission on _skir.RecordId {
    bool admittedBy(ServerPermissionSnapshot snapshot, NatsClient client) {
        final required = panelTransportPermissions(
            actorId: client.actorId,
            organizationId: client.organizationId == null ? null : _skir.RecordId(
                table: "organization", key: _skir.RecordIdKey.wrapString(client.organizationId!),
            ),
            connectionSession: client.connectionSession, realmIds: [this],
        );
        return snapshot.publish.containsAll(required.publish) && snapshot.subscribe.containsAll(required.subscribe);
    }
}

void _grantPersistentProjection(Set<String> publish, {required String stream, required String consumer, required String filter}) {
    publish.addAll({
        "\$JS.API.STREAM.INFO.$stream",
        "\$JS.API.CONSUMER.CREATE.$stream.$consumer.$filter",
        "\$JS.API.CONSUMER.INFO.$stream.$consumer",
        "\$JS.API.CONSUMER.MSG.NEXT.$stream.$consumer",
        "\$JS.API.CONSUMER.DELETE.$stream.$consumer",
    });
}`),
  ];
}

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
            actor: client.actorId._transportIdentity,
            organization: organizationScoped ? organization?._transportIdentity : null,
            session: client.connectionSession._transportSession,
            projection: id,
        );
    }
}

String _persistentConsumerName({required String actor, required String? organization, required String session, required String projection}) {
    final identity = jsonEncode([actor, organization, session, projection]);
    final encoded = base64Url.encode(utf8.encode(identity)).replaceAll("=", "");
    return "TW_$encoded";
}

extension _TransportSegment on String {
    static final _identity = RegExp("^[^\\s.*>{}]+\$");
    static final _transfer = RegExp("^[A-Za-z0-9_\\-]{1,64}\$");
    static final _session = RegExp("^[a-f0-9]{32}\$");
    bool get _isTransportIdentity => _identity.hasMatch(this);
    String get _transportIdentity {
        if (!_isTransportIdentity) throw ArgumentError.value(this, "identity", "Invalid identity segment");
        return this;
    }
    String get _transportTransfer {
        if (!_transfer.hasMatch(this)) throw ArgumentError.value(this, "transferId", "Invalid transfer segment");
        return this;
    }
    String get _transportSession {
        if (!_session.hasMatch(this)) throw ArgumentError.value(this, "connectionSession", "Invalid connection session");
        return this;
    }
}`);

/** Names the Dart operation of a unary route, disambiguating routes that share a request type. */
function unaryOperationName(
  route: ResolvedRoute,
  routes: readonly ResolvedRoute[],
  requestKey: string,
): string {
  const collisions = routes.filter(
    (candidate) =>
      candidate.flow.kind === "unary" &&
      candidate.flow.requests.has("panel") &&
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
  routes: readonly ResolvedRoute[],
  symbols: CodeGenerator.SymbolProvider,
  imports: Imports,
): Lines | undefined {
  const { flow } = route;
  if (flow.kind !== "unary") {
    return undefined;
  }
  const requestAddress = flow.requests.get("panel");
  if (!requestAddress) {
    return undefined;
  }
  const method = imports.use(symbols.method(flow.method.module, flow.method.method));
  const requestType = imports.use(symbols.record(flow.method.request));
  const responseType = imports.use(symbols.record(flow.method.response));
  const operationName = unaryOperationName(route, routes, flow.method.request.record.key);
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

function emitWatch(
  route: ResolvedRoute,
  symbols: CodeGenerator.SymbolProvider,
  imports: Imports,
): Lines | undefined {
  const { flow } = route;
  if (flow.kind !== "watch") {
    return undefined;
  }
  const requestAddress = flow.requests.get("panel");
  const updateAddress = flow.updates.addresses.get("panel");
  if (!requestAddress || !updateAddress) {
    return undefined;
  }
  const eventType = imports.use(symbols.record(flow.updates.payload));
  const method = imports.use(symbols.method(flow.method.module, flow.method.method));
  const requestType = imports.use(symbols.record(flow.method.request));
  const responseType = imports.use(symbols.record(flow.method.response));
  const name = dartName(route);
  const { delivery } = flow.updates;
  const projection =
    delivery.kind === "persistent"
      ? lines(`const ${name}Projection = PersistentProjectionRoute(
    id: ${dartString(delivery.projection)},
    organizationScoped: ${route.scope === "organization" || route.scope === "organization_actor"},
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
  symbols: CodeGenerator.SymbolProvider,
  imports: Imports,
): Lines | undefined {
  const { flow } = route;
  if (flow.kind !== "bounded_watch") {
    return undefined;
  }
  const requestAddress = flow.requests.get("panel");
  const updateAddress = flow.updates.get("panel");
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
  symbols: CodeGenerator.SymbolProvider,
  imports: Imports,
): Lines | undefined {
  const { flow } = route;
  if (flow.kind !== "event" || flow.binding.kind !== "skir") {
    return undefined;
  }
  const address = flow.addresses.get("panel");
  if (!address) {
    return undefined;
  }
  const payloadType = imports.use(symbols.record(flow.binding.payload));
  const name = dartName(route);
  let projection: Lines = [];
  if (address.subscriptionWildcards.includes("user")) {
    const subscription = grantSubject(address.subject, false, address.subscriptionWildcards);
    let userIndex: number | undefined;
    const rejected = address.subject.tokens.map((token, index) => {
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
    final organization = organizationId.id._transportIdentity;
    return ${subscription};
}

static String? userIdFromSubject(
    String subject, {
    required _skir.RecordId organizationId,
}) {
    final organization = organizationId.id._transportIdentity;
    final parts = subject.split(".");
    if (parts.length != ${address.subject.tokens.length} ${rejected.join("")}) return null;
    final userId = parts[${userIndex}];
    return userId._isTransportIdentity ? userId : null;
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
    ...lines(`        return ${subjectExpression(address.subject)};
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
 * event, and the permission set the panel must hold for its admitted user, organization and realms.
 */
export function emitDart(
  routes: readonly ResolvedRoute[],
  symbols: CodeGenerator.SymbolProvider,
): CodeGenerator.OutputFile[] {
  const imports = new Imports();
  const declarations = routes.flatMap((route) => {
    const declaration =
      emitUnary(route, routes, symbols, imports) ??
      emitWatch(route, symbols, imports) ??
      emitBoundedWatch(route, symbols, imports) ??
      emitEvent(route, symbols, imports);
    return declaration ? [declaration] : [];
  });
  const body = separated([...declarations, panelPermissions(routes), RUNTIME]);
  return [
    {
      path: "transport_routes.dart",
      code: HEADER + render([...imports.lines(), BLANK, ...body]),
    },
  ];
}
