import type { CodeGenerator } from "skir-internal";

import { UNKNOWN_SLUG, type Outcome, type OutcomeResponse } from "../../outcomes.js";
import { fillTemplate, importedKotlinSymbol } from "../../symbols.js";
import { lowerCamel, quoted, upperCamel } from "../../text.js";
import { bucketName, everyKeyFilter, REPLY_INBOX } from "../grants.js";
import {
  ENVELOPE_HEADROOM_BYTES,
  type Channel,
  type RoleDeclarations,
  type ScopeKind,
  type TransportLimits,
} from "../manifest.js";
import { IDENTITY_PARAMETERS, replyInboxes, replyInboxText } from "../replies.js";
import {
  clientSubject,
  hasSide,
  routeChannel,
  type ResolvedBucket,
  type ResolvedMethod,
  type ResolvedRoute,
  type ResolvedRoutes,
} from "../resolve.js";
import { scopeParameters, type Parameter } from "../subject.js";

const COMMUNICATOR = "com.typewritermc.services.libs.communicator";

/** The hand written route scopes and their subject templates the generated contracts extend. */
const SCOPES = "com.typewritermc.protocol.transport";

const GENERATED_PACKAGE = "com.typewritermc.protocol.transport.generated";

const ROUTE_IMPORTS = [
  `${COMMUNICATOR}.contract.OperationName`,
  `${COMMUNICATOR}.contract.ReplyAddressRule`,
  `${COMMUNICATOR}.contract.ResponseClassification`,
  `${COMMUNICATOR}.contract.ResponsePolicy`,
];

/** The Skir contract builder of each flow kind. */
const CONTRACT_BUILDERS = {
  unary: "skirUnaryContract",
  scatter: "skirScatterContract",
  watch: "skirWatchContract",
  event: "skirEventContract",
} as const;

const kotlinString = (value: string) => quoted(value, "escaped");

/** The subject service code uses for a channel of the route. */
function serviceSubject(route: ResolvedRoute, channel: Channel): string {
  const subject = clientSubject(route, channel);
  if (!subject) {
    throw new Error(`Kotlin route ${route.name} has no service ${channel} subject`);
  }
  return subject.toString();
}

function kotlinFile(
  packageName: string,
  imports: Iterable<string>,
  blocks: readonly string[],
): string {
  const directives = [...new Set(imports)].sort().map((line) => `${line}\n`);
  const importSection = directives.length === 0 ? "" : `${directives.join("")}\n`;
  return `package ${packageName}\n\n${importSection}${blocks.join("\n\n")}\n`;
}

const CLASSIFICATION: Record<Outcome, string> = {
  success: "success",
  domain_error: "domainError",
  internal_error: "internalError",
};

/** The name of the generated policy of a response record, such as `queryAuthoringStateResponsePolicy`. */
function policyName(response: OutcomeResponse): string {
  const name = response.location.recordAncestors.map((record) => record.name.text).join("");
  return `${name.charAt(0).toLowerCase()}${name.slice(1)}Policy`;
}

/**
 * Emits the response policy of one response enum: the internal_error wrapper is the reply when a
 * handler fails, and each variant classifies by its Skir name. The generated unknown variant falls
 * to the internal error arm.
 */
function emitPolicy(response: OutcomeResponse, symbols: CodeGenerator.SymbolProvider): string {
  const { location, internalError, internalErrorPayload } = response;
  const type = symbols.record(location).reference;
  const internalErrorRecord = symbols.record(internalErrorPayload).reference;
  const arms = response.variants.map(
    ({ field, outcome, slug }) =>
      `        ${symbols.variant(location, field).reference} -> ResponseClassification.${CLASSIFICATION[outcome]}(${kotlinString(slug)})`,
  );
  return `private val ${policyName(response)} = ResponsePolicy<${type}>(
    ${fillTemplate(symbols.variantConstructor(location, internalError), `${internalErrorRecord}.partial()`)},
) { response ->
    when (response.kind) {
${arms.join("\n")}
        else -> ResponseClassification.internalError(${kotlinString(UNKNOWN_SLUG)})
    }
}`;
}

/**
 * The `limits` argument of a route whose limits differ from the manifest defaults, or nothing: a
 * contract without limits uses the transport's, which the services NATS transport is constructed
 * with from TRANSPORT_LIMITS. A route differs when it raises a ceiling or when its framed replies
 * wait for credit.
 */
function routeLimits(route: ResolvedRoute, defaults: TransportLimits): string {
  const changed = [
    ...(route.limits.requestMaxBytes === defaults.requestMaxBytes ? [] : [`requestMaxBytes = ${route.limits.requestMaxBytes}`]),
    ...(route.limits.replyMaxBytes === defaults.replyMaxBytes ? [] : [`replyMaxBytes = ${route.limits.replyMaxBytes}`]),
    ...(route.limits.replyCredit === defaults.replyCredit ? [] : [`replyCredit = ${route.limits.replyCredit}`]),
  ];
  return changed.length === 0 ? "" : `\n    limits = TRANSPORT_LIMITS.copy(${changed.join(", ")}),`;
}

/**
 * The content ceilings of a route that raises a payload ceiling: the largest `bytes` content its
 * request or reply moves, which is the raised ceiling less {@link ENVELOPE_HEADROOM_BYTES}. Code that
 * admits content checks against these, so admitted content always fits the encoded payload.
 */
function contentCeilings(route: ResolvedRoute, defaults: TransportLimits): string[] {
  const constant = (direction: "request" | "reply", maxBytes: number) => {
    const name = `${route.name.toUpperCase()}_${direction.toUpperCase()}_CONTENT_MAX_BYTES`;
    return `/** The largest content a ${route.name} ${direction} moves: its ${maxBytes} byte ceiling less the Skir envelope. */
const val ${name}: Long = ${maxBytes - ENVELOPE_HEADROOM_BYTES}L`;
  };
  return [
    ...(route.limits.requestMaxBytes === defaults.requestMaxBytes ? [] : [constant("request", route.limits.requestMaxBytes)]),
    ...(route.limits.replyMaxBytes === defaults.replyMaxBytes ? [] : [constant("reply", route.limits.replyMaxBytes)]),
  ];
}

/** The generated matcher of each reply inbox side, such as `isPanelReplyInbox`. */
const REPLY_INBOX_MATCHERS = { panel: "isPanelReplyInbox", service: "isServiceReplyInbox" } as const;

/** The Kotlin scope property holding a bound identity, such as `serviceId` on `ServiceRouteScope`. */
const scopeProperty = (parameter: Parameter) => `${parameter}Id`;

/**
 * The `replyAddresses` argument of a request route: the server answers only reply inboxes of its
 * callers, each bound to the caller the route scope names. See {@link replyInboxes}.
 */
function replyAddresses(route: ResolvedRoute, roles: RoleDeclarations, scopeOf = "scope"): string {
  const callers = routeChannel(route, "request")?.publishers ?? [];
  const shapes = replyInboxes(callers, route.scope, roles);
  const checks = shapes.map((shape) => {
    const bindings = shape.bound.map((parameter) => `, ${parameter} = ${scopeOf}.${scopeProperty(parameter)}`);
    return `${REPLY_INBOX_MATCHERS[shape.side]}(reply${bindings.join("")})`;
  });
  const scope = shapes.some((shape) => shape.bound.length > 0) ? "scope" : "_";
  const comment = shapes.length === 0 ? "no caller inbox" : shapes.map(replyInboxText).join(", ");
  return `\n    // Answers ${comment}.\n    replyAddresses = ReplyAddressRule { ${scope}, reply -> ${checks.length === 0 ? "false" : checks.join(" || ")} },`;
}

/** The hand written Kotlin scope, its subject template reader and the generated file of each route scope services take part in. */
const KOTLIN_SCOPES: Partial<Record<ScopeKind, { scope: string; template: string; path: string }>> = {
  realm: { scope: "RealmRouteScope", template: "realmTemplate", path: "RealmRoutes.kt" },
  service: { scope: "ServiceRouteScope", template: "serviceTemplate", path: "ServiceRegistrationRoutes.kt" },
  realm_actor: { scope: "RealmActorRouteScope", template: "realmActorTemplate", path: "RealmActorRoutes.kt" },
  organization_actor: {
    scope: "OrganizationActorRouteScope",
    template: "organizationActorTemplate",
    path: "OrganizationRoutes.kt",
  },
};

/**
 * The scope a realm actor route's server registers on: it hears every member's requests in its realm, so its
 * contract leaves the caller open.
 */
const REALM_ACTOR_SERVER_SCOPE = "RealmRouteScope";

/**
 * How the contracts of one route are addressed. A route whose subjects carry free values gets its own address
 * class, the scope and one string per free value, and its contracts become functions of the free values; every
 * other route is addressed by its scope.
 */
interface Addressing {
  /** The address type of the route's contracts. */
  readonly type: string;
  /** Declarations the route needs before its contracts: the address class, if any. */
  readonly declarations: readonly string[];
  /** The typed template expression of a subject. */
  template(subject: string): string;
  /** The contract accessor head, such as `val RealmRouteScope.name get()` or `fun RealmRouteScope.name(engine: String)`. */
  accessor(name: string): string;
  /** The address the accessor's contract is bound to, inside the accessor. */
  readonly bound: string;
  /** The expression reaching the scope from an address, for reply inbox bindings. */
  readonly scopeOf: string;
}

function addressing(route: ResolvedRoute, scope: string, reader: string): Addressing {
  const free = [...new Set(route.channels.flatMap((channel) => channel.address.freeValues()))];
  if (free.length === 0) {
    return {
      type: scope,
      declarations: [],
      template: (subject) => `${kotlinString(subject)}.${reader}()`,
      accessor: (name) => `val ${scope}.${name} get()`,
      bound: "this",
      scopeOf: "scope",
    };
  }
  const type = `${upperCamel(route.name)}Address`;
  const identities = scopeParameters(route.scope);
  const values = [
    ...identities.map((parameter) => `${kotlinString(parameter)} to it.scope.${scopeProperty(parameter)}`),
    ...free.map((name) => `${kotlinString(name)} to it.${lowerCamel(name)}`),
  ];
  const scopeValue = `${scope}(${identities.map((parameter) => `${scopeProperty(parameter)} = it.require(${kotlinString(parameter)})`).join(", ")})`;
  const parsed = [`scope = ${scopeValue}`, ...free.map((name) => `${lowerCamel(name)} = it.require(${kotlinString(name)})`)];
  const fields = free.map((name) => `val ${lowerCamel(name)}: String`);
  return {
    type,
    declarations: [
      `/** The address of the ${route.name} route: its scope and the free values ${free.map((name) => `{${name}}`).join(", ")} of its subjects. */
data class ${type}(val scope: ${scope}, ${fields.join(", ")})`,
    ],
    template: (subject) => `${kotlinString(subject)}.addressTemplate<${type}>(
    render = { addressValuesOf(${values.join(", ")}) },
    parse = { ${type}(${parsed.join(", ")}) },
)`,
    accessor: (name) => `fun ${scope}.${name}(${fields.map((field) => field.replace("val ", "")).join(", ")})`,
    bound: `${type}(this, ${free.map((name) => lowerCamel(name)).join(", ")})`,
    scopeOf: "scope.scope",
  };
}

function routeFile(
  routes: readonly ResolvedRoute[],
  kind: ScopeKind,
  symbols: CodeGenerator.SymbolProvider,
  defaults: TransportLimits,
  roles: RoleDeclarations,
): CodeGenerator.OutputFile {
  const { scope, template: reader, path } = KOTLIN_SCOPES[kind]!;
  const imports = [...ROUTE_IMPORTS, `${SCOPES}.${scope}`, `${SCOPES}.${reader}`].map((name) => `import ${name}`);
  const policies = new Map<string, string>();
  const policyOf = (method: ResolvedMethod): string => {
    const key = method.response.record.key;
    if (!policies.has(key)) {
      policies.set(key, emitPolicy(method.outcomes, symbols));
    }
    return policyName(method.outcomes);
  };
  const blocks: string[] = [];
  for (const route of routes) {
    const name = lowerCamel(route.name);
    const requestAddress = `${name}RequestAddress`;
    const updateAddress = `${name}UpdateAddress`;
    const operation = kotlinString(route.operation);
    const address = addressing(route, scope, reader);
    if (address.declarations.length > 0) {
      imports.push(`import ${COMMUNICATOR}.address.addressTemplate`, `import ${COMMUNICATOR}.address.addressValuesOf`);
      blocks.push(...address.declarations);
    }
    const { flow } = route;
    const contract = CONTRACT_BUILDERS[flow.kind];
    imports.push(`import ${COMMUNICATOR}.skir.${contract}`);
    switch (flow.kind) {
      case "unary":
      case "scatter": {
        const method = importedKotlinSymbol(symbols.method(flow.method.module, flow.method.method));
        imports.push(...method.imports);
        const build = (bound: string) => `${contract}(
    method = ${method.name}, name = OperationName.of(${operation}),
    address = ${bound}, responsePolicy = ${policyOf(flow.method)},${replyAddresses(route, roles, address.scopeOf)}${routeLimits(route, defaults)}
)`;
        blocks.push(`private val ${requestAddress} = ${address.template(serviceSubject(route, "request"))}
${address.accessor(name)} = ${build(`${requestAddress}.subscribedAt(${address.bound})`)}`);
        if (kind === "realm_actor") {
          imports.push(`import ${SCOPES}.${REALM_ACTOR_SERVER_SCOPE}`);
          blocks.push(`/** The ${route.name} contract its server registers: every member's requests in this realm. */
val ${REALM_ACTOR_SERVER_SCOPE}.${name} get() = ${build(`${requestAddress}.subscribedWhere("organization" to organizationId, "realm" to realmId)`)}`);
        }
        break;
      }
      case "watch": {
        const method = importedKotlinSymbol(symbols.method(flow.method.module, flow.method.method));
        const update = symbols.record(flow.updates.payload).reference;
        imports.push(...method.imports);
        blocks.push(`private val ${requestAddress} = ${address.template(serviceSubject(route, "request"))}
private val ${updateAddress} = ${address.template(serviceSubject(route, "updates"))}
${address.accessor(name)} = ${contract}(
    method = ${method.name}, updateSerializer = ${update}.serializer,
    name = OperationName.of(${operation}), requestAddress = ${requestAddress}.subscribedAt(${address.bound}),
    updateAddress = ${updateAddress}, initialPolicy = ${policyOf(flow.method)},${replyAddresses(route, roles, address.scopeOf)}${routeLimits(route, defaults)}
)`);
        break;
      }
      case "event": {
        const payload = symbols.record(flow.payload).reference;
        blocks.push(`private val ${name}Address = ${address.template(serviceSubject(route, "event"))}
${address.accessor(name)} = ${contract}(
    serializer = ${payload}.serializer, name = OperationName.of(${operation}), address = ${name}Address,
)`);
        break;
      }
    }
    blocks.push(...contentCeilings(route, defaults));
  }
  return { path, code: kotlinFile(GENERATED_PACKAGE, imports, [...policies.values(), ...blocks]) };
}

/**
 * The manifest payload framing limits, which the services NATS transport is constructed with. Their
 * reply time to live also bounds how long a service waits for replies it requested.
 */
function limitsFile({
  chunkBytes,
  windowFrames,
  requestMaxBytes,
  replyMaxBytes,
  frameInactivityMs,
  replyTtlMs,
  replyCredit,
}: TransportLimits): CodeGenerator.OutputFile {
  const blocks = [
    `/** Payload framing limits of the transport route manifest; routes whose limits differ carry their own. */
val TRANSPORT_LIMITS =
    TransportLimits(
        chunkBytes = ${chunkBytes},
        windowFrames = ${windowFrames},
        requestMaxBytes = ${requestMaxBytes},
        replyMaxBytes = ${replyMaxBytes},
        frameInactivity = ${frameInactivityMs}.milliseconds,
        replyTtl = ${replyTtlMs}.milliseconds,
        replyCredit = ${replyCredit},
    )`,
  ];
  const imports = [
    `import ${COMMUNICATOR}.transfer.TransportLimits`,
    "import kotlin.time.Duration.Companion.milliseconds",
  ];
  return { path: "TransportLimits.kt", code: kotlinFile(GENERATED_PACKAGE, imports, blocks) };
}

/**
 * The matcher of one side's reply inboxes, `isPanelReplyInbox(reply, user)`: the root, one token per
 * identity value and one reply token, each identity that names a subject identity optionally bound.
 */
function replyInboxMatcher(side: "panel" | "service"): string {
  const values = REPLY_INBOX[side];
  const pattern = [REPLY_INBOX.root, ...values.map((value) => `{${value}}`), "{token}"].join(".");
  const bindable = values.flatMap((value, index) => {
    const parameter = IDENTITY_PARAMETERS[value];
    return parameter ? [{ parameter, index: index + 1 }] : [];
  });
  const parameters = bindable.map(({ parameter }) => `${parameter}: String? = null`);
  const checks = [
    `tokens.size == ${values.length + 2}`,
    `tokens[0] == ${kotlinString(REPLY_INBOX.root)}`,
    ...bindable.map(({ parameter, index }) => `(${parameter} == null || tokens[${index}] == ${parameter})`),
  ];
  const names = bindable.map(({ parameter }) => `[${parameter}]`).join(", ");
  return `/**
 * Whether [reply] is a ${side} reply inbox, \`${pattern}\`${names ? `, of ${names} when given` : ""}. A server answers only
 * the reply inboxes of its route's callers, so a request cannot aim the answer at a subject its sender may not publish.
 */
fun ${REPLY_INBOX_MATCHERS[side]}(${["reply: MessageAddress", ...parameters].join(", ")}): Boolean {
    val tokens = reply.value.split('.')
    return ${checks.join(" &&\n        ")}
}`;
}

/** The service reply inbox prefix rule of {@link REPLY_INBOX}, which the backend grants, and every side's matcher. */
function replyInboxFile(): CodeGenerator.OutputFile {
  const values = REPLY_INBOX.service;
  const pattern = [REPLY_INBOX.root, ...values.map((value) => `{${value}}`)].join(".");
  const prefix = [REPLY_INBOX.root, ...values.map((value) => `\${${value}}`)].join(".");
  const parameters = values.map((value) => `${value}: String`).join(", ");
  const block = `/**
 * The reply inbox prefix of a service connection, \`${pattern}\`. Its reply inboxes are single tokens below
 * it; the backend lets the connection listen at any depth below it, since a JetStream client listens one token
 * deeper.
 */
fun serviceReplyInboxPrefix(${parameters}): String = "${prefix}"`;
  const imports = [`import ${COMMUNICATOR}.address.MessageAddress`];
  const blocks = [block, replyInboxMatcher("panel"), replyInboxMatcher("service")];
  return { path: "ReplyInboxes.kt", code: kotlinFile(GENERATED_PACKAGE, imports, blocks) };
}

/**
 * Emits the Kotlin contracts of the routes a service role takes part in for the services runtime:
 * realm routes, the service routes of the registered service, the payload framing limits and reply
 * time to live, the service reply inbox prefix, and the reply inbox matchers each request contract
 * answers its callers by.
 */
export function emitKotlin(
  { limits, roles, routes, buckets }: ResolvedRoutes,
  symbols: CodeGenerator.SymbolProvider,
): CodeGenerator.OutputFile[] {
  const serviceRoutes = routes.filter((route) => hasSide(route, roles, "service"));
  for (const route of serviceRoutes) {
    if (!KOTLIN_SCOPES[route.scope]) {
      throw new Error(`Kotlin route ${route.name} has unsupported scope ${route.scope}`);
    }
  }
  const scopes = Object.keys(KOTLIN_SCOPES) as ScopeKind[];
  return [
    ...scopes.map((kind) =>
      routeFile(
        serviceRoutes.filter((route) => route.scope === kind),
        kind,
        symbols,
        limits,
        roles,
      ),
    ),
    limitsFile(limits),
    replyInboxFile(),
    bucketsFile(buckets),
  ];
}

/**
 * Each realm key value bucket's name and the declaration its owner creates it with, so the realm
 * that creates a bucket and the engines that write it name the same one.
 */
function bucketsFile(buckets: readonly ResolvedBucket[]): CodeGenerator.OutputFile {
  const imports = [`import ${COMMUNICATOR}.kv.KeyValueBucketDeclaration`, "import kotlin.time.Duration.Companion.seconds"];
  const blocks = buckets.map(({ declaration }) => {
    const name = `${upperCamel(declaration.name)}Bucket`;
    const key = declaration.key.map((token) => `<${token}>`).join(".");
    return `/** The \`${declaration.name}\` key value bucket of one realm; its keys are \`${key}\`. */
object ${name} {
    /** The bucket of [realm], \`${bucketName(declaration.name, "<realm>")}\`. */
    fun name(realm: String): String {
        require(realm.matches(BUCKET_REALM)) { "A realm id in a bucket name holds only letters, digits, - and _: $realm" }
        return "${bucketName(declaration.name, "$realm")}"
    }

    /** The key filter of every key, \`${everyKeyFilter(declaration)}\`, which a watch of the whole bucket uses within its grants. */
    const val EVERY_KEY: String = "${everyKeyFilter(declaration)}"

    /** How the realm creates the bucket of [realm]. */
    fun declaration(realm: String): KeyValueBucketDeclaration =
        KeyValueBucketDeclaration(name(realm), markerTtl = ${declaration.markerTtlSeconds}.seconds)
}`;
  });
  const realm = `/** The characters a bucket name allows, which a realm id must keep to. */
private val BUCKET_REALM = Regex("[A-Za-z0-9_-]+")`;
  return { path: "TransportBuckets.kt", code: kotlinFile(GENERATED_PACKAGE, imports, [realm, ...blocks]) };
}
