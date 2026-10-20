import type {
  CodeGenerator,
  Field,
  Method,
  Module,
  RecordLocation,
  ResolvedType,
  Token,
} from "skir-internal";

import { routeGrants } from "./grants.js";
import {
  symbolRefText,
  type Channel,
  type ComponentSubscription,
  type Delivery,
  type Endpoints,
  type EventEndpoint,
  type Grant,
  type Manifest,
  type NativeKotlinEventBinding,
  type NativeKotlinRequestResponseBinding,
  type Route,
  type ScopeKind,
  type Side,
  type SymbolRef,
} from "./manifest.js";
import type { Parameter, SubjectTemplate } from "./subject.js";

/** A route's Skir method with its request and response records. */
export interface ResolvedMethod {
  readonly module: Module;
  readonly method: Method;
  readonly request: RecordLocation;
  readonly response: RecordLocation;
}

/** The update stream of a watch route. */
export interface ResolvedEvent {
  readonly payload: RecordLocation;
  readonly addresses: Endpoints;
  readonly delivery: Delivery;
}

/** An event endpoint with the identities its subscribers may wildcard. */
export interface ResolvedEventEndpoint {
  readonly subject: SubjectTemplate;
  readonly subscriptionWildcards: readonly Parameter[];
}

export type ResolvedEventBinding =
  | { readonly kind: "skir"; readonly payload: RecordLocation }
  | NativeKotlinEventBinding;

export type ResolvedFlow =
  | { readonly kind: "unary"; readonly method: ResolvedMethod; readonly requests: Endpoints }
  | {
      readonly kind: "watch";
      readonly method: ResolvedMethod;
      readonly requests: Endpoints;
      readonly updates: ResolvedEvent;
    }
  | {
      readonly kind: "bounded_watch";
      readonly method: ResolvedMethod;
      readonly requests: Endpoints;
      readonly updates: Endpoints;
      readonly transferField: Field;
    }
  | {
      readonly kind: "scatter";
      readonly binding: NativeKotlinRequestResponseBinding;
      readonly requests: Endpoints;
    }
  | {
      readonly kind: "event";
      readonly binding: ResolvedEventBinding;
      readonly addresses: ReadonlyMap<Side, ResolvedEventEndpoint>;
      readonly delivery: Delivery;
    };

/** A manifest route admitted against the Skir model. */
export interface ResolvedRoute {
  readonly name: string;
  readonly scope: ScopeKind;
  readonly grants: readonly Grant[];
  readonly subscription: ComponentSubscription | undefined;
  readonly operation: string;
  readonly failureSlug: string;
  readonly flow: ResolvedFlow;
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

function grantAddresses(route: Route, channel: Channel): ReadonlyMap<Side, unknown> | undefined {
  const { flow } = route;
  if (channel === "request" && flow.kind !== "event") {
    return flow.requests;
  }
  if (channel === "updates" && flow.kind === "watch") {
    return flow.updates.addresses;
  }
  if (channel === "updates" && flow.kind === "bounded_watch") {
    return flow.updates;
  }
  if (channel === "event" && flow.kind === "event") {
    return flow.addresses;
  }
  return undefined;
}

function admitRouteShape(route: Route, at: RouteAt): void {
  const grants = new Set<string>();
  route.grants.forEach((grant, index) => {
    const key = `${grant.role}/${grant.side}/${grant.channel}/${grant.direction}`;
    if (grants.has(key)) {
      throw routeError(within(at, `grants[${index}]`), "duplicate grant");
    }
    grants.add(key);
  });
  route.grants.forEach((grant, index) => {
    const addresses = grantAddresses(route, grant.channel);
    if (!addresses) {
      throw routeError(within(at, `grants[${index}]`), `invalid grant channel ${grant.channel}`);
    }
    if (!addresses.has(grant.side)) {
      throw routeError(within(at, `grants[${index}]`), `missing ${grant.side} endpoint`);
    }
  });
  if (route.scope === "internal_component") {
    if (route.grants.length > 0 || !route.subscription) {
      throw routeError(at, "internal component route requires a subscription and no grants");
    }
  } else if (route.subscription) {
    throw routeError(within(at, "subscription"), "subscription metadata is invalid for this scope");
  }
}

function admitEndpoints(
  at: RouteAt,
  channel: Channel,
  addresses: Endpoints,
  scope: ScopeKind,
  transfer: boolean,
): void {
  if (addresses.size === 0) {
    throw routeError(at, "endpoint set must not be empty");
  }
  for (const [side, subject] of addresses) {
    try {
      if (channel === "request") {
        subject.validateRequestScope(scope);
      } else {
        subject.validateScope(scope, transfer);
      }
    } catch (error) {
      throw routeError(
        within(at, side),
        `${channel} endpoint ${side} is invalid: ${(error as Error).message}`,
      );
    }
  }
}

function admitEventEndpoints(
  at: RouteAt,
  addresses: ReadonlyMap<Side, EventEndpoint>,
  scope: ScopeKind,
): ReadonlyMap<Side, ResolvedEventEndpoint> {
  if (addresses.size === 0) {
    throw routeError(at, "endpoint set must not be empty");
  }
  const admitted = new Map<Side, ResolvedEventEndpoint>();
  for (const [side, { subject, subscription }] of addresses) {
    try {
      subject.validateScope(scope, false);
    } catch (error) {
      throw routeError(
        within(at, side),
        `event endpoint ${side} is invalid: ${(error as Error).message}`,
      );
    }
    const subscriptionWildcards = subscription?.wildcard ?? [];
    for (const parameter of subscriptionWildcards) {
      if (!subject.has(parameter)) {
        throw routeError(within(at, side), "subscription projects an absent parameter");
      }
      if (!(scope === "organization_actor" && parameter === "user")) {
        throw routeError(within(at, side), "subscription projects an authoritative scope identity");
      }
    }
    admitted.set(side, { subject, subscriptionWildcards });
  }
  return admitted;
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

function stringField(location: RecordLocation, name: string, at: RouteAt): Field {
  const field = location.record.fields.find(
    (candidate) =>
      candidate.name.text === name &&
      candidate.type?.kind === "primitive" &&
      candidate.type.primitive === "string",
  );
  if (location.record.recordType !== "struct" || !field) {
    throw routeError(
      at,
      `expected string field ${name} on ${location.record.key}`,
      location.record.name,
    );
  }
  return field;
}

function resolveFlow(
  input: CodeGenerator.Input<unknown>,
  route: Route,
  at: RouteAt,
): ResolvedFlow {
  const { flow, scope } = route;
  const flowAt = within(at, "flow");
  switch (flow.kind) {
    case "unary":
      admitEndpoints(within(flowAt, "requests"), "request", flow.requests, scope, false);
      return {
        kind: "unary",
        method: resolveMethod(input, flow.method, within(flowAt, "method")),
        requests: flow.requests,
      };
    case "watch":
      admitEndpoints(within(flowAt, "requests"), "request", flow.requests, scope, false);
      admitEndpoints(
        within(flowAt, "updates.addresses"),
        "updates",
        flow.updates.addresses,
        scope,
        false,
      );
      return {
        kind: "watch",
        method: resolveMethod(input, flow.method, within(flowAt, "method")),
        requests: flow.requests,
        updates: {
          payload: resolveRecord(input, flow.updates.payload, within(flowAt, "updates.payload")),
          addresses: flow.updates.addresses,
          delivery: flow.updates.delivery,
        },
      };
    case "bounded_watch": {
      admitEndpoints(within(flowAt, "requests"), "request", flow.requests, scope, false);
      admitEndpoints(within(flowAt, "updates"), "updates", flow.updates, scope, true);
      const method = resolveMethod(input, flow.method, within(flowAt, "method"));
      return {
        kind: "bounded_watch",
        method,
        requests: flow.requests,
        updates: flow.updates,
        transferField: stringField(
          method.request,
          flow.transfer_field,
          within(flowAt, "transfer_field"),
        ),
      };
    }
    case "scatter":
      admitEndpoints(within(flowAt, "requests"), "request", flow.requests, scope, false);
      if (flow.binding.kind !== "native_kotlin") {
        throw routeError(
          within(flowAt, "binding"),
          "scatter routes require a native Kotlin binding",
        );
      }
      return { kind: "scatter", binding: flow.binding, requests: flow.requests };
    case "event": {
      const addresses = admitEventEndpoints(within(flowAt, "addresses"), flow.addresses, scope);
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
      return { kind: "event", binding, addresses, delivery: flow.delivery };
    }
  }
}

/**
 * Admits route identity, channel grants, endpoint captures and the referenced Skir declarations.
 * Fails the whole generation on the first invalid route; every route shape is checked before any
 * Skir lookup. Emitters perform additional target checks, including which scope and role
 * combinations their runtime supports.
 */
export function resolveRoutes(
  manifest: Manifest,
  input: CodeGenerator.Input<unknown>,
): ResolvedRoute[] {
  const names = new Set<string>();
  const located = manifest.routes.map((route, index) => {
    const at = { name: route.name, path: `routes[${index}]` };
    if (names.has(route.name)) {
      throw routeError(at, "duplicate logical route");
    }
    names.add(route.name);
    admitRouteShape(route, at);
    return { route, at };
  });
  return located.map(({ route, at }) => {
    const resolved: ResolvedRoute = {
      name: route.name,
      scope: route.scope,
      grants: route.grants,
      subscription: route.subscription,
      operation: route.flow.operation,
      failureSlug: route.flow.failure_slug,
      flow: resolveFlow(input, route, at),
    };
    try {
      routeGrants(resolved);
    } catch (error) {
      throw routeError(within(at, "grants"), (error as Error).message);
    }
    return resolved;
  });
}
