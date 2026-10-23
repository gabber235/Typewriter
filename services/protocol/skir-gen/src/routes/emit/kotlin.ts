import type { CodeGenerator } from "skir-internal";

import { UNKNOWN_SLUG, type Outcome, type OutcomeResponse } from "../../outcomes.js";
import { importedKotlinSymbol, kotlinWrapperClass } from "../../symbols.js";
import { lowerCamel, quoted } from "../../text.js";
import { REPLY_INBOX } from "../grants.js";
import type { Channel, TransportLimits } from "../manifest.js";
import {
  clientSubject,
  hasSide,
  type ResolvedMethod,
  type ResolvedRoute,
  type ResolvedRoutes,
} from "../resolve.js";

const COMMUNICATOR = "com.typewritermc.services.libs.communicator";

/** The hand written route scopes and their subject templates the generated contracts extend. */
const SCOPES = "com.typewritermc.protocol.transport";

const GENERATED_PACKAGE = "com.typewritermc.protocol.transport.generated";

const ROUTE_IMPORTS = [
  `${COMMUNICATOR}.contract.OperationName`,
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
    ${kotlinWrapperClass(symbols, location, internalError)}(${internalErrorRecord}.partial()),
) { response ->
    when (response.kind) {
${arms.join("\n")}
        else -> ResponseClassification.internalError(${kotlinString(UNKNOWN_SLUG)})
    }
}`;
}

/**
 * The `limits` argument of a route that raises a manifest ceiling, or nothing: a contract without
 * limits uses the transport's, which the services NATS transport is constructed with from
 * TRANSPORT_LIMITS.
 */
function routeLimits(route: ResolvedRoute, defaults: TransportLimits): string {
  const raised = [
    ...(route.limits.requestMaxBytes === defaults.requestMaxBytes ? [] : [`requestMaxBytes = ${route.limits.requestMaxBytes}`]),
    ...(route.limits.replyMaxBytes === defaults.replyMaxBytes ? [] : [`replyMaxBytes = ${route.limits.replyMaxBytes}`]),
  ];
  return raised.length === 0 ? "" : `\n    limits = TRANSPORT_LIMITS.copy(${raised.join(", ")}),`;
}

function routeFile(
  routes: readonly ResolvedRoute[],
  realm: boolean,
  path: string,
  symbols: CodeGenerator.SymbolProvider,
  defaults: TransportLimits,
): CodeGenerator.OutputFile {
  const scope = realm ? "RealmRouteScope" : "ServiceRouteScope";
  const template = realm ? "realmTemplate()" : "serviceTemplate()";
  const imports = [
    ...ROUTE_IMPORTS,
    `${SCOPES}.${scope}`,
    `${SCOPES}.${realm ? "realmTemplate" : "serviceTemplate"}`,
  ].map((name) => `import ${name}`);
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
    const { flow } = route;
    const contract = CONTRACT_BUILDERS[flow.kind];
    imports.push(`import ${COMMUNICATOR}.skir.${contract}`);
    switch (flow.kind) {
      case "unary":
      case "scatter": {
        const method = importedKotlinSymbol(symbols.method(flow.method.module, flow.method.method));
        imports.push(...method.imports);
        blocks.push(`private val ${requestAddress} = ${kotlinString(serviceSubject(route, "request"))}.${template}
val ${scope}.${name} get() = ${contract}(
    method = ${method.name}, name = OperationName.of(${operation}),
    address = ${requestAddress}.subscribedAt(this), responsePolicy = ${policyOf(flow.method)},${routeLimits(route, defaults)}
)`);
        break;
      }
      case "watch": {
        const method = importedKotlinSymbol(symbols.method(flow.method.module, flow.method.method));
        const update = symbols.record(flow.updates.payload).reference;
        imports.push(...method.imports);
        blocks.push(`private val ${requestAddress} = ${kotlinString(serviceSubject(route, "request"))}.${template}
private val ${updateAddress} = ${kotlinString(serviceSubject(route, "updates"))}.${template}
val ${scope}.${name} get() = ${contract}(
    method = ${method.name}, updateSerializer = ${update}.serializer,
    name = OperationName.of(${operation}), requestAddress = ${requestAddress}.subscribedAt(this),
    updateAddress = ${updateAddress}, initialPolicy = ${policyOf(flow.method)},${routeLimits(route, defaults)}
)`);
        break;
      }
      case "event": {
        const payload = symbols.record(flow.payload).reference;
        blocks.push(`private val ${name}Address = ${kotlinString(serviceSubject(route, "event"))}.${template}
val ${scope}.${name} get() = ${contract}(
    serializer = ${payload}.serializer, name = OperationName.of(${operation}), address = ${name}Address,
)`);
        break;
      }
    }
  }
  return { path, code: kotlinFile(GENERATED_PACKAGE, imports, [...policies.values(), ...blocks]) };
}

/**
 * The manifest payload framing limits, which the services NATS transport is constructed with, and the
 * reply time to live, which bounds how long a service waits for replies it requested.
 */
function limitsFile({ chunkBytes, windowFrames, requestMaxBytes, replyMaxBytes, replyTtlMs }: TransportLimits): CodeGenerator.OutputFile {
  const blocks = [
    `/** Payload framing limits of the transport route manifest; routes that raise a ceiling carry their own. */
val TRANSPORT_LIMITS =
    TransportLimits(
        chunkBytes = ${chunkBytes},
        windowFrames = ${windowFrames},
        requestMaxBytes = ${requestMaxBytes},
        replyMaxBytes = ${replyMaxBytes},
    )`,
    `/** How long a responder may send replies after it received a request, so no requester waits longer. */
val TRANSPORT_REPLY_TTL: Duration = ${replyTtlMs}.milliseconds`,
  ];
  const imports = [
    `import ${COMMUNICATOR}.transfer.TransportLimits`,
    "import kotlin.time.Duration",
    "import kotlin.time.Duration.Companion.milliseconds",
  ];
  return { path: "TransportLimits.kt", code: kotlinFile(GENERATED_PACKAGE, imports, blocks) };
}

/** The service reply inbox prefix rule of {@link REPLY_INBOX}, which the backend grants. */
function replyInboxFile(): CodeGenerator.OutputFile {
  const values = REPLY_INBOX.service;
  const pattern = [REPLY_INBOX.root, ...values.map((value) => `{${value}}`)].join(".");
  const prefix = [REPLY_INBOX.root, ...values.map((value) => `\${${value}}`)].join(".");
  const parameters = values.map((value) => `${value}: String`).join(", ");
  const block = `/**
 * The reply inbox prefix of a service connection, \`${pattern}\`. Its reply inboxes are single tokens below
 * it, and the backend grants the connection exactly those.
 */
fun serviceReplyInboxPrefix(${parameters}): String = "${prefix}"`;
  return { path: "ReplyInboxes.kt", code: kotlinFile(GENERATED_PACKAGE, [], [block]) };
}

/**
 * Emits the Kotlin contracts of the routes a service role takes part in for the services runtime:
 * realm routes, the service routes of the registered service, the payload framing limits and reply
 * time to live, and the service reply inbox prefix.
 */
export function emitKotlin(
  { limits, roles, routes }: ResolvedRoutes,
  symbols: CodeGenerator.SymbolProvider,
): CodeGenerator.OutputFile[] {
  const serviceRoutes = routes.filter((route) => hasSide(route, roles, "service"));
  for (const route of serviceRoutes) {
    if (route.scope !== "realm" && route.scope !== "service") {
      throw new Error(`Kotlin route ${route.name} has unsupported scope ${route.scope}`);
    }
  }
  return [
    routeFile(
      serviceRoutes.filter((route) => route.scope === "realm"),
      true,
      "RealmRoutes.kt",
      symbols,
      limits,
    ),
    routeFile(
      serviceRoutes.filter((route) => route.scope === "service"),
      false,
      "ServiceRegistrationRoutes.kt",
      symbols,
      limits,
    ),
    limitsFile(limits),
    replyInboxFile(),
  ];
}
