import type {
  CodeGenerator,
  Method,
  Module,
  RecordLocation,
  ResolvedType,
  Token,
} from "skir-internal";

import { OutcomeAdmissionError, outcomeResponse, skirPosition, type OutcomeResponse } from "../outcomes.js";
import { routeGrants, type Grant } from "./grants.js";
import {
  routeParties,
  symbolRefText,
  type Channel,
  type Delivery,
  type Manifest,
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
  /** The classified variants of the response, which every request route requires. */
  readonly outcomes: OutcomeResponse;
}

export type ResolvedFlow =
  | { readonly kind: "unary"; readonly method: ResolvedMethod }
  | {
      readonly kind: "watch";
      readonly method: ResolvedMethod;
      readonly updates: { readonly payload: RecordLocation; readonly delivery: Delivery };
    }
  | { readonly kind: "scatter"; readonly method: ResolvedMethod }
  | { readonly kind: "event"; readonly payload: RecordLocation; readonly delivery: Delivery };

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
  /** The manifest limits with this route's own request and reply ceilings. */
  readonly limits: TransportLimits;
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
  const position = source ? ` (Skir ${skirPosition(source)})` : "";
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
  const response = recordOf(method.responseType);
  let outcomes;
  try {
    outcomes = outcomeResponse(response, input.recordMap);
  } catch (error) {
    if (error instanceof OutcomeAdmissionError) {
      throw routeError(at, error.message, error.token);
    }
    throw error;
  }
  return { module, method, request: recordOf(method.requestType), response, outcomes };
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
    case "scatter":
      return { kind: flow.kind, method: resolveMethod(input, flow.method, within(flowAt, "method")) };
    case "watch":
      return {
        kind: "watch",
        method: resolveMethod(input, flow.method, within(flowAt, "method")),
        updates: {
          payload: resolveRecord(input, flow.updates.payload, within(flowAt, "updates.payload")),
          delivery: flow.updates.delivery,
        },
      };
    case "event":
      return {
        kind: "event",
        payload: resolveRecord(input, flow.payload, within(flowAt, "payload")),
        delivery: flow.delivery,
      };
  }
}

/**
 * The manifest limits with the ceilings a request route raises. Backend components cannot assemble a
 * framed request: each invocation is stateless and its subscriptions are static ConfigMaps. Their
 * replies are framed by one shared ceiling, so a route they serve keeps the manifest defaults.
 */
function routeLimits(route: Route, defaults: TransportLimits, at: RouteAt): TransportLimits {
  if (route.flow.kind === "event") return defaults;
  const limits = {
    ...defaults,
    requestMaxBytes: (route.flow.kind === "unary" ? route.flow.request_max_bytes : undefined) ?? defaults.requestMaxBytes,
    replyMaxBytes: route.flow.reply_max_bytes ?? defaults.replyMaxBytes,
  };
  if ("server" in route && "component" in route.server) {
    if (limits.requestMaxBytes > limits.chunkBytes) {
      throw routeError(
        within(at, "flow.request_max_bytes"),
        "a backend component cannot receive framed requests; remove request_max_bytes",
      );
    }
    if (route.flow.reply_max_bytes !== undefined) {
      throw routeError(
        within(at, "flow.reply_max_bytes"),
        "a backend component frames every reply by the manifest reply_max_bytes; remove the route ceiling",
      );
    }
  }
  return limits;
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
    return { route, at, channels, grants, limits: routeLimits(route, manifest.limits, at) };
  });
  const routes = located.map(
    ({ route, at, channels, grants, limits }): ResolvedRoute => ({
      name: route.name,
      scope: route.scope,
      parties: routeParties(route),
      operation: route.flow.operation,
      failureSlug: failureSlug(route.flow.operation),
      flow: resolveFlow(input, route, at),
      channels,
      grants,
      limits,
    }),
  );
  return { limits: manifest.limits, roles, components: manifest.components, routes };
}
