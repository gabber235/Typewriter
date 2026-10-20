import type { Channel, Delivery, Party, RoleDeclarations, Route, ScopeKind } from "./manifest.js";

/** Identity captures a subject may name, in the order generated code lists them. */
export const PARAMETERS = ["organization", "realm", "service", "user", "transfer_id"] as const;
export type Parameter = (typeof PARAMETERS)[number];

export type SubjectToken =
  | { readonly kind: "literal"; readonly value: string }
  | { readonly kind: "parameter"; readonly parameter: Parameter };

/** Sorts parameters into their canonical order and removes duplicates. */
export function sortedParameters(parameters: Iterable<Parameter>): Parameter[] {
  const present = new Set(parameters);
  return PARAMETERS.filter((parameter) => present.has(parameter));
}

/** The identities each scope binds, in the order generated scope types declare them. */
export function scopeParameters(scope: ScopeKind): readonly Parameter[] {
  switch (scope) {
    case "realm":
      return ["organization", "realm"];
    case "service":
      return ["service"];
    case "organization_actor":
      return ["organization", "user"];
    case "organization":
      return ["organization"];
    case "user":
      return ["user"];
    case "internal_component":
      return [];
  }
}

/**
 * A concrete subject shape with named identity captures, never authored broker wildcards. Parsing
 * validates tokens and capture uniqueness; scope admission happens in route resolution.
 */
export class SubjectTemplate {
  private constructor(readonly tokens: readonly SubjectToken[]) {}

  /** Parses a dotted subject such as `user.{user}.organization.create`; throws if invalid. */
  static parse(value: string): SubjectTemplate {
    const seen = new Set<Parameter>();
    const tokens = value.split(".").map((part): SubjectToken => {
      const parameter = PARAMETERS.find((candidate) => part === `{${candidate}}`);
      if (parameter) {
        if (seen.has(parameter)) {
          throw new Error(`repeated subject parameter ${part}`);
        }
        seen.add(parameter);
        return { kind: "parameter", parameter };
      }
      if (part.length === 0 || /[\s*>{}]/u.test(part)) {
        throw new Error(`invalid subject token ${JSON.stringify(part)}`);
      }
      return { kind: "literal", value: part };
    });
    return new SubjectTemplate(tokens);
  }

  /** Prepends the tokens of a subject family prefix such as `cloud.to`. */
  prefixed(prefix: string): SubjectTemplate {
    return SubjectTemplate.parse(`${prefix}.${this}`);
  }

  /** Whether the subject captures the given identity. */
  has(parameter: Parameter): boolean {
    return this.tokens.some((token) => token.kind === "parameter" && token.parameter === parameter);
  }

  /** The captured identities in canonical order. */
  parameters(): Parameter[] {
    return sortedParameters(
      this.tokens.flatMap((token) => (token.kind === "parameter" ? [token.parameter] : [])),
    );
  }

  toString(): string {
    return this.tokens
      .map((token) => (token.kind === "literal" ? token.value : `{${token.parameter}}`))
      .join(".");
  }
}

/**
 * The subjects of one channel, by where the code that uses them runs. A channel has at least one.
 * `client` is used by panel and service code, `backend` by a wasmCloud component behind the
 * bridge, and `internal` by a wasmCloud component talking to another component directly.
 */
export interface ChannelSubjects {
  readonly client?: SubjectTemplate;
  readonly backend?: SubjectTemplate;
  readonly internal?: SubjectTemplate;
}

/** One message flow of a route with the parties on each end and its derived subjects. */
export interface RouteChannel {
  readonly kind: Channel;
  readonly address: SubjectTemplate;
  readonly publishers: readonly Party[];
  readonly receivers: readonly Party[];
  readonly subjects: ChannelSubjects;
  /** How updates and events reach their receivers; requests have none. */
  readonly delivery?: Delivery;
}

/** The role that owns a realm and answers for it on the realm mesh. */
const REALM_COORDINATOR = "realm_coordinator";

const isRole = (party: Party): party is { readonly role: string } => "role" in party;
const isComponent = (party: Party): party is { readonly component: string } => "component" in party;

/**
 * Derives the subjects of one channel from the route scope and its publishing and receiving
 * parties. This is the only place subject family prefixes exist:
 *
 * - realm scope uses the realm mesh, `service.to` toward the realm coordinator and `service.from`
 *   when the coordinator publishes;
 * - a role talking to a component crosses the bridge, where `cloud.to` and `typewriter.from` are
 *   one flow seen from each side (`cloud.from` and `typewriter.to` back); component callers of a
 *   bridged request also get the bare address;
 * - component to component uses the bare address;
 * - events between panel roles only use the `typewriter` prefix.
 *
 * Throws for party combinations that have no subject family.
 */
export function channelSubjects(
  scope: ScopeKind,
  kind: Channel,
  address: SubjectTemplate,
  publishers: readonly Party[],
  receivers: readonly Party[],
  roles: RoleDeclarations,
): ChannelSubjects {
  const parties = [...publishers, ...receivers];
  const external = parties.some(isRole);
  const internal = parties.some(isComponent);
  if (scope === "realm") {
    if (internal) {
      throw new Error("realm routes connect roles only");
    }
    const direction = publishers.some(
      (party) => isRole(party) && party.role === REALM_COORDINATOR,
    )
      ? "from"
      : "to";
    const mesh = `service.${direction}.{realm}.organization.{organization}.realm`;
    return { client: address.prefixed(mesh) };
  }
  if (external && internal) {
    const subjects: ChannelSubjects = publishers.some(isRole)
      ? { client: address.prefixed("cloud.to"), backend: address.prefixed("typewriter.from") }
      : { client: address.prefixed("cloud.from"), backend: address.prefixed("typewriter.to") };
    return kind === "request" && publishers.some(isComponent)
      ? { ...subjects, internal: address }
      : subjects;
  }
  if (internal) {
    return { internal: address };
  }
  const panelOnly = parties.every(
    (party) => isRole(party) && roles.get(party.role)?.side === "panel",
  );
  if (kind === "event" && panelOnly) {
    return { client: address.prefixed("typewriter") };
  }
  throw new Error(
    `${kind} channel between service roles outside realm scope has no subject family`,
  );
}

/**
 * Lists the channels of a route in request, updates, event order with their derived subjects.
 * Requests flow from callers to the server and updates back; events from publishers to
 * subscribers.
 */
export function routeChannels(route: Route, roles: RoleDeclarations): RouteChannel[] {
  const channel = (
    kind: Channel,
    address: SubjectTemplate,
    publishers: readonly Party[],
    receivers: readonly Party[],
    delivery?: Delivery,
  ): RouteChannel => ({
    kind,
    address,
    publishers,
    receivers,
    subjects: channelSubjects(route.scope, kind, address, publishers, receivers, roles),
    ...(delivery ? { delivery } : {}),
  });
  if ("publishers" in route) {
    const { flow } = route;
    return [channel("event", flow.address, route.publishers, route.subscribers, flow.delivery)];
  }
  const { flow, callers, server } = route;
  const channels = [channel("request", flow.request, callers, [server])];
  if (flow.kind === "watch") {
    channels.push(
      channel("updates", flow.updates.address, [server], callers, flow.updates.delivery),
    );
  } else if (flow.kind === "bounded_watch") {
    channels.push(channel("updates", flow.updates, [server], callers, { kind: "transient" }));
  }
  return channels;
}

/** The telemetry slug of a route's failures, derived from its operation name. */
export function failureSlug(operation: string): string {
  return `${operation.replace(/[._]/gu, "-")}-failed`;
}
