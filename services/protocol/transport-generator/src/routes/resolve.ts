import type {
  CodeGenerator,
  Method,
  Module,
  RecordLocation,
  ResolvedType,
  Token,
} from "skir-internal";

import { routeGrants, type Grant } from "./grants.js";
import {
  routeParties,
  symbolRefText,
  type Channel,
  type Delivery,
  type Manifest,
  type NativeKotlinEventBinding,
  type NativeKotlinRequestResponseBinding,
  type Party,
  type RoleDeclarations,
  type Route,
  type ScopeKind,
  type SymbolRef,
  type TransportLimits,
} from "./manifest.js";
import {
  failureSlug,
  routeChannels,
  scopeParameters,
  type RouteChannel,
  type SubjectTemplate,
} from "./subject.js";

/** A route's Skir method with its request and response records. */
export interface ResolvedMethod {
  readonly module: Module;
  readonly method: Method;
  readonly request: RecordLocation;
  readonly response: RecordLocation;
}

export type ResolvedEventBinding =
  | { readonly kind: "skir"; readonly payload: RecordLocation }
  | NativeKotlinEventBinding;

export type ResolvedFlow =
  | { readonly kind: "unary"; readonly method: ResolvedMethod }
  | {
      readonly kind: "watch";
      readonly method: ResolvedMethod;
      readonly updates: { readonly payload: RecordLocation; readonly delivery: Delivery };
    }
  | { readonly kind: "scatter"; readonly binding: NativeKotlinRequestResponseBinding }
  | {
      readonly kind: "event";
      readonly binding: ResolvedEventBinding;
      readonly delivery: Delivery;
    };

/** A manifest route admitted against the role declarations and the Skir model. */
export interface ResolvedRoute {
  readonly name: string;
  readonly scope: ScopeKind;
  /** Every party of the route, in declaration order. */
  readonly parties: readonly Party[];
  readonly operation: string;
  readonly failureSlug: string;
  readonly flow: ResolvedFlow;
  /** The request, updates and event channels with their derived subjects. */
  readonly channels: readonly RouteChannel[];
  /** The derived broker permissions of every role party. */
  readonly grants: readonly Grant[];
}

/** The admitted manifest: transport limits, role and component declarations and every route. */
export interface ResolvedRoutes {
  readonly limits: TransportLimits;
  readonly roles: RoleDeclarations;
  readonly components: ReadonlyMap<string, string>;
  readonly routes: readonly ResolvedRoute[];
}

/** The channel of a route of the given kind, if the route has one. */
export function routeChannel(route: ResolvedRoute, kind: Channel): RouteChannel | undefined {
  return route.channels.find((channel) => channel.kind === kind);
}

/** The panel or service subject of a channel, which every channel with a role party has. */
export function clientSubject(route: ResolvedRoute, kind: Channel): SubjectTemplate | undefined {
  return routeChannel(route, kind)?.subjects.client;
}

/** Whether a route has a role party whose code runs on the given side. */
export function hasSide(
  route: ResolvedRoute,
  roles: RoleDeclarations,
  side: "panel" | "service",
): boolean {
  return route.parties.some((party) => "role" in party && roles.get(party.role)?.side === side);
}

/** A route that the manifest or the Skir model does not admit. */
export class RouteError extends Error {
  override readonly name = "RouteError";
}

/** Names a manifest route in errors by its name and YAML path. */
interface RouteAt {
  readonly name: string;
  readonly path: string;
}

function routeError(at: RouteAt, message: string, source?: Token): RouteError {
  const position = source
    ? ` (Skir ${source.line.modulePath}:${source.line.lineNumber + 1}:${source.colNumber + 1})`
    : "";
  return new RouteError(`route ${at.name} at ${at.path}: ${message}${position}`);
}

function within(at: RouteAt, suffix: string): RouteAt {
  return { name: at.name, path: `${at.path}.${suffix}` };
}

/**
 * Derives the route channels and admits their subjects: every request subject captures each
 * identity of the route scope, so the server can rebuild the scope from the subject.
 */
function admitChannels(route: Route, roles: RoleDeclarations, at: RouteAt): RouteChannel[] {
  let channels;
  try {
    channels = routeChannels(route, roles);
  } catch (error) {
    throw routeError(at, (error as Error).message);
  }
  const request = channels.find((channel) => channel.kind === "request");
  for (const subject of Object.values(request?.subjects ?? {})) {
    const missing = scopeParameters(route.scope).find((parameter) => !subject.has(parameter));
    if (missing) {
      throw routeError(
        within(at, "flow.request"),
        `request subject ${subject} does not capture {${missing}} of ${route.scope} scope`,
      );
    }
  }
  return channels;
}

function findModule(input: CodeGenerator.Input<unknown>, path: string): Module | undefined {
  return input.modules.find((candidate) => candidate.path === path);
}

function resolveMethod(
  input: CodeGenerator.Input<unknown>,
  reference: SymbolRef,
  at: RouteAt,
): ResolvedMethod {
  if (reference.path.length !== 1) {
    throw routeError(at, `method reference must be top level: ${symbolRefText(reference)}`);
  }
  const module = findModule(input, reference.module);
  const method = module?.methods.find((candidate) => candidate.name.text === reference.path[0]);
  if (!module || !method) {
    throw routeError(at, `unknown Skir method ${symbolRefText(reference)}`);
  }
  const recordOf = (type: ResolvedType | undefined): RecordLocation => {
    const location = type?.kind === "record" ? input.recordMap.get(type.key) : undefined;
    if (!location) {
      throw routeError(
        at,
        "transport methods must use record request and response types",
        method.name,
      );
    }
    return location;
  };
  return {
    module,
    method,
    request: recordOf(method.requestType),
    response: recordOf(method.responseType),
  };
}

function resolveRecord(
  input: CodeGenerator.Input<unknown>,
  reference: SymbolRef,
  at: RouteAt,
): RecordLocation {
  const path = reference.path.join(".");
  const matches =
    findModule(input, reference.module)?.records.filter(
      (location) => location.recordAncestors.map((record) => record.name.text).join(".") === path,
    ) ?? [];
  if (matches.length !== 1) {
    throw routeError(at, `unknown Skir record ${symbolRefText(reference)}`);
  }
  return matches[0]!;
}

function resolveFlow(
  input: CodeGenerator.Input<unknown>,
  route: Route,
  at: RouteAt,
): ResolvedFlow {
  const { flow } = route;
  const flowAt = within(at, "flow");
  switch (flow.kind) {
    case "unary":
      return { kind: "unary", method: resolveMethod(input, flow.method, within(flowAt, "method")) };
    case "watch":
      return {
        kind: "watch",
        method: resolveMethod(input, flow.method, within(flowAt, "method")),
        updates: {
          payload: resolveRecord(input, flow.updates.payload, within(flowAt, "updates.payload")),
          delivery: flow.updates.delivery,
        },
      };
    case "scatter":
      if (flow.binding.kind !== "native_kotlin") {
        throw routeError(
          within(flowAt, "binding"),
          "scatter routes require a native Kotlin binding",
        );
      }
      return { kind: "scatter", binding: flow.binding };
    case "event": {
      const binding: ResolvedEventBinding =
        flow.binding.kind === "skir"
          ? {
              kind: "skir",
              payload: resolveRecord(
                input,
                flow.binding.payload,
                within(flowAt, "binding.payload"),
              ),
            }
          : flow.binding;
      return { kind: "event", binding, delivery: flow.delivery };
    }
  }
}

/**
 * Derives each route's channel subjects and role grants and resolves the referenced Skir
 * declarations. Fails the whole generation on the first invalid route; every route's subjects are
 * admitted before any Skir lookup.
 */
export function resolveRoutes(
  manifest: Manifest,
  input: CodeGenerator.Input<unknown>,
): ResolvedRoutes {
  const { roles } = manifest;
  const names = new Set<string>();
  const located = manifest.routes.map((route, index) => {
    const at = { name: route.name, path: `routes[${index}]` };
    if (names.has(route.name)) {
      throw routeError(at, "duplicate logical route");
    }
    names.add(route.name);
    const channels = admitChannels(route, roles, at);
    let grants;
    try {
      grants = routeGrants(channels, roles);
    } catch (error) {
      throw routeError(at, (error as Error).message);
    }
    return { route, at, channels, grants };
  });
  const routes = located.map(
    ({ route, at, channels, grants }): ResolvedRoute => ({
      name: route.name,
      scope: route.scope,
      parties: routeParties(route),
      operation: route.flow.operation,
      failureSlug: failureSlug(route.flow.operation),
      flow: resolveFlow(input, route, at),
      channels,
      grants,
    }),
  );
  return { limits: manifest.limits, roles, components: manifest.components, routes };
}
