import type { CodeGenerator } from "skir-internal";

import { importedKotlinSymbol, transferFieldName } from "../../symbols.js";
import { lowerCamel, quoted } from "../../text.js";
import type { Channel } from "../manifest.js";
import { clientSubject, hasSide, type ResolvedRoute, type ResolvedRoutes } from "../resolve.js";

const COMMUNICATOR = "com.typewritermc.services.libs.communicator";

/** The hand written route scopes and their subject templates the generated contracts extend. */
const SCOPES = "com.typewritermc.protocol.transport";

const ROUTE_IMPORTS = [
  `${COMMUNICATOR}.address.MessageAddress`,
  `${COMMUNICATOR}.contract.EventContract`,
  `${COMMUNICATOR}.contract.OperationName`,
  `${COMMUNICATOR}.contract.ResponseClassifier`,
  `${COMMUNICATOR}.contract.ResponsePolicy`,
  `${COMMUNICATOR}.skir.asPayloadCodec`,
  `${COMMUNICATOR}.skir.skirUnaryContract`,
  `${COMMUNICATOR}.skir.skirWatchContract`,
  "com.typewritermc.services.libs.telemetry.ErrorSlug",
];

const LOADER_IMPORTS = [
  `${SCOPES}.RealmRouteScope`,
  `${SCOPES}.realmTemplate`,
  `${COMMUNICATOR}.contract.EventContract`,
  `${COMMUNICATOR}.contract.OperationName`,
  `${COMMUNICATOR}.contract.ResponsePolicy`,
  `${COMMUNICATOR}.contract.ScatterContract`,
  "com.typewritermc.services.libs.telemetry.ErrorSlug",
];

const LOADER_PACKAGE = "com.typewritermc.loader.rollout";

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
  return `package ${packageName}\n\n${directives.join("")}\n${blocks.join("\n\n")}\n`;
}

function routeFile(
  routes: readonly ResolvedRoute[],
  realm: boolean,
  path: string,
  symbols: CodeGenerator.SymbolProvider,
): CodeGenerator.OutputFile {
  const scope = realm ? "RealmRouteScope" : "ServiceRouteScope";
  const template = realm ? "realmTemplate()" : "serviceTemplate()";
  const imports = [
    ...ROUTE_IMPORTS,
    `${SCOPES}.${scope}`,
    `${SCOPES}.${realm ? "realmTemplate" : "serviceTemplate"}`,
  ].map((name) => `import ${name}`);
  const blocks: string[] = [];
  for (const route of routes) {
    const name = lowerCamel(route.name);
    const requestAddress = `${name}RequestAddress`;
    const updateAddress = `${name}UpdateAddress`;
    const operation = kotlinString(route.operation);
    const slug = kotlinString(route.failureSlug);
    const { flow } = route;
    switch (flow.kind) {
      case "unary": {
        const method = importedKotlinSymbol(symbols.method(flow.method.module, flow.method.method));
        const response = symbols.record(flow.method.response).reference;
        imports.push(...method.imports);
        blocks.push(`private val ${requestAddress} = ${kotlinString(serviceSubject(route, "request"))}.${template}
fun ${scope}.${name}(policy: ResponsePolicy<${response}>) = skirUnaryContract(
    method = ${method.name}, name = OperationName.of(${operation}),
    address = ${requestAddress}.subscribedAt(this), responsePolicy = policy,
    failureSlug = ErrorSlug.of(${slug}),
)`);
        break;
      }
      case "watch": {
        const method = importedKotlinSymbol(symbols.method(flow.method.module, flow.method.method));
        const response = symbols.record(flow.method.response).reference;
        const update = symbols.record(flow.updates.payload).reference;
        imports.push(...method.imports);
        blocks.push(`private val ${requestAddress} = ${kotlinString(serviceSubject(route, "request"))}.${template}
private val ${updateAddress} = ${kotlinString(serviceSubject(route, "updates"))}.${template}
fun ${scope}.${name}(policy: ResponsePolicy<${response}>, updates: ResponseClassifier<${update}>) = skirWatchContract(
    method = ${method.name}, updateSerializer = ${update}.serializer,
    name = OperationName.of(${operation}), requestAddress = ${requestAddress}.subscribedAt(this),
    updateAddress = ${updateAddress}, initialPolicy = policy, updateClassifier = updates,
    failureSlug = ErrorSlug.of(${slug}),
)`);
        break;
      }
      case "bounded_watch": {
        const method = importedKotlinSymbol(symbols.method(flow.method.module, flow.method.method));
        const request = symbols.record(flow.method.request).reference;
        const response = symbols.record(flow.method.response).reference;
        const update = serviceSubject(route, "updates").replace(/(\.\{transfer_id\})+$/u, "");
        const resolver = `MessageAddress.of("\${${updateAddress}.render(routeScope).value}.\${request.${transferFieldName(flow.transferField)}}")`;
        imports.push(...method.imports);
        blocks.push(`private val ${requestAddress} = ${kotlinString(serviceSubject(route, "request"))}.${template}
private val ${updateAddress} = ${kotlinString(update)}.${template}
fun ${scope}.${name}(policy: ResponsePolicy<${response}>, updates: ResponseClassifier<${response}>) = skirWatchContract(
    method = ${method.name}, updateSerializer = ${response}.serializer,
    name = OperationName.of(${operation}), requestAddress = ${requestAddress}.subscribedAt(this),
    updateAddress = ${updateAddress}, initialPolicy = policy, updateClassifier = updates,
    failureSlug = ErrorSlug.of(${slug}),
    updateAddressResolver = { routeScope, request: ${request} -> ${resolver} },
)`);
        break;
      }
      case "scatter":
        break;
      case "event": {
        if (flow.binding.kind !== "skir") {
          break;
        }
        const payload = symbols.record(flow.binding.payload).reference;
        blocks.push(`private val ${name}Address = ${kotlinString(serviceSubject(route, "event"))}.${template}
val ${scope}.${name} get() = EventContract(
    OperationName.of(${operation}), ${name}Address,
    ${payload}.serializer.asPayloadCodec(), ErrorSlug.of(${slug}),
)`);
        break;
      }
    }
  }
  return { path, code: kotlinFile("com.typewritermc.protocol.transport.generated", imports, blocks) };
}

/**
 * Emits the Kotlin contracts of the routes a service role takes part in for the services runtime:
 * realm routes and the service routes of the registered service.
 */
export function emitKotlin(
  { roles, routes }: ResolvedRoutes,
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
    ),
    routeFile(
      serviceRoutes.filter((route) => route.scope === "service"),
      false,
      "ServiceRegistrationRoutes.kt",
      symbols,
    ),
  ];
}

function shortName(symbol: string): string {
  return symbol.slice(symbol.lastIndexOf(".") + 1);
}

/**
 * Emits the loader core contracts of the native Kotlin routes, which use realm scope and the CBOR
 * codecs the manifest names instead of Skir serializers.
 */
export function emitKotlinLoader({ routes }: ResolvedRoutes): CodeGenerator.OutputFile[] {
  const imports = [...LOADER_IMPORTS];
  const blocks: string[] = [];
  for (const route of routes) {
    const { flow } = route;
    if (flow.kind !== "scatter" && !(flow.kind === "event" && flow.binding.kind === "native_kotlin")) {
      continue;
    }
    if (route.scope !== "realm") {
      throw new Error(`native Kotlin route ${route.name} must use realm scope`);
    }
    const name = lowerCamel(route.name);
    const operation = kotlinString(route.operation);
    const slug = kotlinString(route.failureSlug);
    if (flow.kind === "scatter") {
      const { binding } = flow;
      const requestType = shortName(binding.request_type);
      const responseType = shortName(binding.response_type);
      imports.push(binding.request_type, binding.response_type);
      blocks.push(`private val ${name}RequestAddress = ${kotlinString(serviceSubject(route, "request"))}.realmTemplate()
fun RealmRouteScope.${name}(policy: ResponsePolicy<${responseType}>): ScatterContract<RealmRouteScope, ${requestType}, ${responseType}> = ScatterContract(
    name = OperationName.of(${operation}),
    requestAddress = ${name}RequestAddress.subscribedAt(this),
    requestCodec = ${binding.request_codec},
    responseCodec = ${binding.response_codec},
    responsePolicy = policy,
    failureSlug = ErrorSlug.of(${slug}),
)`);
    } else if (flow.binding.kind === "native_kotlin") {
      const { binding } = flow;
      imports.push(binding.event_type);
      blocks.push(`private val ${name}Address = ${kotlinString(serviceSubject(route, "event"))}.realmTemplate()
val RealmRouteScope.${name}: EventContract<RealmRouteScope, ${shortName(binding.event_type)}>
    get() = EventContract(
        name = OperationName.of(${operation}),
        address = ${name}Address,
        codec = ${binding.event_codec},
        failureSlug = ErrorSlug.of(${slug}),
    )`);
    }
  }
  const external = imports
    .filter((name) => !name.startsWith(`${LOADER_PACKAGE}.`))
    .map((name) => `import ${name}`);
  return [{ path: "RolloutRoutes.kt", code: kotlinFile(LOADER_PACKAGE, external, blocks) }];
}
