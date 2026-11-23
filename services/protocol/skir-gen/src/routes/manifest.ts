import { z } from "zod";

import { parseYamlManifest } from "../yaml.js";

import { SubjectTemplate, scopeParameters, type Parameter } from "./subject.js";

/** Scope kinds in the order generated code groups them. */
export const SCOPE_KINDS = [
  "realm",
  "realm_actor",
  "service",
  "organization_actor",
  "organization",
  "user",
  "internal_component",
] as const;
export type ScopeKind = (typeof SCOPE_KINDS)[number];

export const CHANNELS = ["request", "updates", "event"] as const;
export type Channel = (typeof CHANNELS)[number];

export const DIRECTIONS = ["publish", "subscribe"] as const;
export type Direction = (typeof DIRECTIONS)[number];

/** Identity placeholders a role declaration may bind. */
const IDENTITIES = [
  "organization",
  "realm",
  "service",
  "user",
] as const satisfies readonly Parameter[];
export type Identity = (typeof IDENTITIES)[number];

/** The identifiers that name one grantee rather than a tenant it belongs to. */
const PERSONAL_IDENTITIES: readonly Identity[] = ["service", "user"];

/**
 * Identities whose values live inside another identity, so a role bound to the outer one may
 * address any inner value: every realm belongs to one organization.
 */
const NESTED_IN: Partial<Record<Identity, Identity>> = { realm: "organization" };

/** A Skir declaration named as `module.skir:Declaration` or `module.skir:Outer.Inner`. */
export interface SymbolRef {
  readonly module: string;
  readonly path: readonly string[];
}

/** Formats a symbol reference the way the manifest spells it. */
export function symbolRefText(reference: SymbolRef): string {
  return `${reference.module}:${reference.path.join(".")}`;
}

function checked<T>(parse: (value: string) => T) {
  return (value: string, context: z.RefinementCtx): T => {
    try {
      return parse(value);
    } catch (error) {
      context.addIssue({ code: "custom", message: (error as Error).message });
      return z.NEVER;
    }
  };
}

const RouteName = z.string().regex(/^[a-z_][a-z0-9_]*$/, {
  error: (issue) => `invalid route identifier ${JSON.stringify(issue.input)}`,
});

const RoleName = z.string().regex(/^[a-z][a-z0-9_]*$/, {
  error: (issue) => `invalid role name ${JSON.stringify(issue.input)}`,
});

const ComponentName = z.string().regex(/^[a-z][a-z0-9-]*$/, {
  error: (issue) => `invalid component name ${JSON.stringify(issue.input)}`,
});

/** Leading tokens that only the subject rule writes; an address never spells a family itself. */
const FAMILY_PREFIXES = ["cloud", "typewriter", "service.to", "service.from"];

/**
 * A logical address: the route path of one channel without its subject family prefix, such as
 * `user.{user}.organization.create`.
 */
const Address = z.string().transform(
  checked((value) => {
    // Every placeholder name parses here; admission then checks each free value is declared.
    const address = SubjectTemplate.parse(value, () => true);
    const prefix = FAMILY_PREFIXES.find(
      (family) => value === family || value.startsWith(`${family}.`),
    );
    if (prefix) {
      throw new Error(`address ${JSON.stringify(value)} spells the ${prefix} subject family`);
    }
    return address;
  }),
);

const Reference = z.string().transform(
  checked((value): SymbolRef => {
    const separator = value.indexOf(":");
    if (separator < 0) {
      throw new Error("expected module.skir:Declaration");
    }
    const module = value.slice(0, separator);
    if (
      !module.endsWith(".skir") ||
      module.startsWith("/") ||
      module.split("/").some((part) => part === "" || part === "..")
    ) {
      throw new Error(`invalid canonical module path ${JSON.stringify(module)}`);
    }
    const path = value.slice(separator + 1).split(".");
    if (path.some((part) => part === "" || /\s/u.test(part))) {
      throw new Error("invalid canonical declaration path");
    }
    return { module, path };
  }),
);

/**
 * Where a role's code runs and which identifiers it is bound to. Tenant identifiers are fixed by
 * admission; the personal identifier is the grantee's own identity.
 */
const RoleDeclaration = z.strictObject({
  side: z.enum(["panel", "service"]),
  tenant: z.array(z.enum(IDENTITIES)).default([]),
  personal: z.enum(IDENTITIES).optional(),
});

/** A route party: a declared role or a declared backend component. */
const Party = z.union([
  z.strictObject({ role: RoleName }),
  z.strictObject({ component: ComponentName }),
]);

const Delivery = z.discriminatedUnion("kind", [
  z.strictObject({ kind: z.literal("transient") }),
  z.strictObject({
    kind: z.literal("persistent"),
    stream: z.string(),
    projection: RouteName,
  }),
]);

const Updates = z.strictObject({ payload: Reference, address: Address, delivery: Delivery });

const Operation = z.string().regex(/^[a-z][a-z0-9_]*(\.[a-z][a-z0-9_]*)*$/, {
  error: (issue) => `invalid operation name ${JSON.stringify(issue.input)}`,
});

/**
 * A payload ceiling in bytes; a route raises the manifest default only when it moves larger values. Only unary
 * routes may raise one: a scatter request is published to every listener and a watch request opens a stream, so
 * neither may be framed, and their clients collect replies by the manifest reply ceiling.
 */
const MaxBytes = z.int().positive();

const Flow = z.discriminatedUnion("kind", [
  z.strictObject({
    kind: z.literal("unary"),
    method: Reference,
    operation: Operation,
    request: Address,
    request_max_bytes: MaxBytes.optional(),
    reply_max_bytes: MaxBytes.optional(),
  }),
  z.strictObject({
    kind: z.literal("watch"),
    method: Reference,
    operation: Operation,
    request: Address,
    updates: Updates,
  }),
  z.strictObject({
    kind: z.literal("scatter"),
    method: Reference,
    operation: Operation,
    request: Address,
  }),
  z.strictObject({
    kind: z.literal("event"),
    payload: Reference,
    operation: Operation,
    address: Address,
    delivery: Delivery,
  }),
]);

const Parties = z.array(Party).min(1);

const PARTY_FIELDS = ["callers", "server", "publishers", "subscribers"] as const;

const RouteShape = z.strictObject({
  name: RouteName,
  scope: z.enum(SCOPE_KINDS),
  callers: Parties.optional(),
  server: Party.optional(),
  publishers: Parties.optional(),
  subscribers: Parties.optional(),
  flow: Flow,
});

type Flow = z.output<typeof Flow>;
export type Party = z.output<typeof Party>;
export type Delivery = z.output<typeof Delivery>;
export type RoleDeclaration = Readonly<z.output<typeof RoleDeclaration>> & {
  readonly name: string;
};
export type RoleDeclarations = ReadonlyMap<string, RoleDeclaration>;
export type RequestFlow = Exclude<Flow, { kind: "event" }>;
export type EventFlow = Extract<Flow, { kind: "event" }>;

interface RouteCommon {
  readonly name: string;
  readonly scope: ScopeKind;
}

/** A request flow: callers publish requests the server answers, and receive its updates. */
export interface RequestRoute extends RouteCommon {
  readonly callers: readonly Party[];
  readonly server: Party;
  readonly flow: RequestFlow;
}

/** An event flow from its publishers to its subscribers. */
export interface EventRoute extends RouteCommon {
  readonly publishers: readonly Party[];
  readonly subscribers: readonly Party[];
  readonly flow: EventFlow;
}

export type Route = RequestRoute | EventRoute;

/** Every party of a route, in declaration order. */
export function routeParties(route: Route): readonly Party[] {
  return "publishers" in route
    ? [...route.publishers, ...route.subscribers]
    : [...route.callers, route.server];
}

/**
 * How the transports split a large request or reply; see transport-routes.yaml. A payload above
 * `chunkBytes` travels as frames of at most `chunkBytes`. Framed requests flow in credit windows of
 * `windowFrames`; framed replies do too when `replyCredit` holds, and otherwise stream without
 * waiting. Requests are bounded by `requestMaxBytes` and replies by `replyMaxBytes`; the manifest
 * declares the defaults and a unary route may raise either for itself. A sender waits at most
 * `frameInactivityMs` for a credit and a receiver as long for the next frame. A service may answer
 * a request for `replyTtlMs` after receiving it, so a requester never needs to wait longer.
 */
export interface TransportLimits {
  readonly chunkBytes: number;
  readonly windowFrames: number;
  readonly requestMaxBytes: number;
  readonly replyMaxBytes: number;
  readonly frameInactivityMs: number;
  readonly replyTtlMs: number;
  /**
   * Whether a framed reply waits for the requester's credit at each window end. Granting a credit
   * is a NATS response, and panel connections hold no response permission: one would let a panel
   * user answer its own message on a subject it both publishes and subscribes to, and so publish
   * once to any reply subject it names. Replies stream without credit by default; the resolver
   * enables credit for a route only when none of its callers runs on the panel.
   */
  readonly replyCredit: boolean;
}

/**
 * Bytes a raised payload ceiling reserves for the Skir record around the `bytes` content it moves:
 * the other fields, their keys and the length prefixes. A route that raises a ceiling to move
 * content carries at most its ceiling less this headroom, so content that passes a size check
 * always fits the encoded payload.
 */
export const ENVELOPE_HEADROOM_BYTES = 64 * 1024;

/**
 * A JetStream key value bucket, one per realm, named `<name>_<realm id>`. Its owner creates it;
 * its writers read, write and list keys of exactly the declared tokens. Every key carries its own
 * time to live, and an expired key leaves a marker for `markerTtlSeconds`, so a watcher sees it.
 */
export interface BucketDeclaration {
  readonly name: string;
  readonly key: readonly string[];
  readonly owner: string;
  readonly writers: readonly string[];
  readonly markerTtlSeconds: number;
}

/** The admitted route manifest. */
export interface Manifest {
  readonly limits: TransportLimits;
  /** The declared free values an address may carry; see {@link SubjectTemplate.parse}. */
  readonly parameters: readonly string[];
  readonly roles: RoleDeclarations;
  /** Backend component name to its deploy/base directory, relative to the repository root. */
  readonly components: ReadonlyMap<string, string>;
  readonly routes: readonly Route[];
  readonly buckets: readonly BucketDeclaration[];
}

const Limits = z.strictObject({
  chunk_bytes: z.int().positive(),
  window_frames: z.int().positive(),
  request_max_bytes: MaxBytes,
  reply_max_bytes: MaxBytes,
  frame_inactivity_ms: z.int().positive(),
  reply_ttl_ms: z.int().positive(),
});

const KeyToken = z.string().regex(/^[a-z][a-z0-9_]*$/, {
  error: (issue) => `invalid key token ${JSON.stringify(issue.input)}`,
});

const BucketShape = z.strictObject({
  name: KeyToken,
  scope: z.literal("realm"),
  key: z.array(KeyToken).min(1),
  owner: z.strictObject({ role: RoleName }),
  writers: z.array(z.strictObject({ role: RoleName })).min(1),
  marker_ttl_seconds: z.int().positive(),
});

const RawManifest = z
  .strictObject({
    limits: Limits,
    parameters: z.array(KeyToken).default([]),
    roles: z.record(RoleName, RoleDeclaration),
    components: z.record(ComponentName, z.string().min(1)),
    routes: z.array(RouteShape),
    buckets: z.array(BucketShape).default([]),
  })
  .superRefine((manifest, context) => {
    const issue = (path: Array<string | number>, message: string) =>
      context.addIssue({ code: "custom", path, message });
    const used = new Set<string>();
    manifest.parameters.forEach((parameter, index) => {
      if ((IDENTITIES as readonly string[]).includes(parameter)) {
        issue(["parameters", index], `free parameter {${parameter}} is an identity`);
      }
    });
    const chunk = manifest.limits.chunk_bytes;
    for (const field of ["request_max_bytes", "reply_max_bytes"] as const) {
      if (manifest.limits[field] < chunk) {
        issue(["limits", field], `${field} must hold at least one chunk of ${chunk} bytes`);
      }
    }
    manifest.routes.forEach((route, index) => {
      const at = ["routes", index];
      if (route.flow.kind !== "event") {
        for (const field of ["request_max_bytes", "reply_max_bytes"] as const) {
          const value = field in route.flow ? (route.flow as Partial<Record<typeof field, number>>)[field] : undefined;
          if (value !== undefined && value < chunk) {
            issue([...at, "flow", field], `${field} must hold at least one chunk of ${chunk} bytes`);
          }
        }
      }
      const event = route.flow.kind === "event";
      for (const field of PARTY_FIELDS) {
        const expected = event === (field === "publishers" || field === "subscribers");
        if (expected && route[field] === undefined) {
          issue(at, `${route.flow.kind} routes declare ${field}`);
        } else if (!expected && route[field] !== undefined) {
          issue([...at, field], `${route.flow.kind} routes do not declare ${field}`);
        }
      }
      const parties = PARTY_FIELDS.flatMap((field): Array<[Array<string | number>, Party]> => {
        const value = route[field];
        if (value === undefined) {
          return [];
        }
        return Array.isArray(value)
          ? value.map((party, position) => [[field, position], party])
          : [[[field], value]];
      });
      for (const [path, party] of parties) {
        if ("component" in party) {
          used.add(party.component);
          if (!(party.component in manifest.components)) {
            const message = `unknown component ${JSON.stringify(party.component)}`;
            issue([...at, ...path, "component"], message);
          }
          continue;
        }
        const role = manifest.roles[party.role];
        if (!role) {
          issue([...at, ...path, "role"], `unknown role ${JSON.stringify(party.role)}`);
          continue;
        }
        const bound = new Set<Identity>(role.tenant);
        if (role.personal) {
          bound.add(role.personal);
        }
        // An event subscriber receives every publisher of its tenant, and a request server every caller,
        // so the sender's own identifier stays unbound in its grant.
        const receivesOthers = (event && path[0] === "subscribers") || path[0] === "server";
        for (const parameter of scopeParameters(route.scope) as readonly Identity[]) {
          const outer = NESTED_IN[parameter];
          if (receivesOthers && PERSONAL_IDENTITIES.includes(parameter)) {
            continue;
          }
          if (!bound.has(parameter) && !(outer && role.tenant.includes(outer))) {
            issue(
              [...at, ...path, "role"],
              `role ${party.role} does not bind {${parameter}} of ${route.scope} scope`,
            );
          }
        }
      }
      admitAddresses(route.scope, route.flow, manifest.parameters, (path, message) =>
        issue([...at, "flow", ...path], message),
      );
    });
    manifest.buckets.forEach((bucket, index) => {
      const parties: Array<[Array<string | number>, string]> = [
        [["owner"], bucket.owner.role],
        ...bucket.writers.map((writer, position): [Array<string | number>, string] => [["writers", position], writer.role]),
      ];
      for (const [path, name] of parties) {
        const role = manifest.roles[name];
        if (!role) {
          issue(["buckets", index, ...path, "role"], `unknown role ${JSON.stringify(name)}`);
        } else if (role.side !== "service" || !role.tenant.includes("realm")) {
          issue(["buckets", index, ...path, "role"], `role ${name} is not bound to one realm, so it cannot reach a realm bucket`);
        }
      }
    });
    for (const component of Object.keys(manifest.components)) {
      if (!used.has(component)) {
        const message = `component ${JSON.stringify(component)} takes part in no route`;
        issue(["components", component], message);
      }
    }
  });

/**
 * Admits the placeholders of each flow address: every identity is bound by the route scope, and
 * every other placeholder is a declared free value.
 */
function admitAddresses(
  scope: ScopeKind,
  flow: Flow,
  parameters: readonly string[],
  issue: (path: string[], message: string) => void,
): void {
  const allowed = scopeParameters(scope);
  const admit = (path: string[], address: SubjectTemplate) => {
    for (const token of address.tokens) {
      if (token.kind === "parameter" && !allowed.includes(token.parameter)) {
        issue(path, `placeholder {${token.parameter}} is not bound by ${scope} scope`);
      }
      if (token.kind === "free" && !parameters.includes(token.name)) {
        issue(path, `placeholder {${token.name}} is neither an identity nor a declared free parameter`);
      }
    }
  };
  switch (flow.kind) {
    case "event":
      admit(["address"], flow.address);
      return;
    case "watch":
      admit(["request"], flow.request);
      admit(["updates", "address"], flow.updates.address);
      return;
    case "unary":
    case "scatter":
      admit(["request"], flow.request);
  }
}

/**
 * Parses and admits the transport route manifest. Duplicate YAML keys and unknown fields fail, as
 * do parties that name undeclared roles or components, components that take part in no route,
 * roles whose bound identifiers do not cover the route scope, and address placeholders the route
 * scope does not bind. Errors carry the source file, the YAML path such as
 * `routes[3].flow.request` and the line.
 */
export function parseManifest(source: string, file: string): Manifest {
  const { limits, parameters, roles, components, routes, buckets } = parseYamlManifest(source, file, RawManifest).data;
  return {
    parameters,
    limits: {
      chunkBytes: limits.chunk_bytes,
      windowFrames: limits.window_frames,
      requestMaxBytes: limits.request_max_bytes,
      replyMaxBytes: limits.reply_max_bytes,
      frameInactivityMs: limits.frame_inactivity_ms,
      replyTtlMs: limits.reply_ttl_ms,
      replyCredit: false,
    },
    roles: new Map(Object.entries(roles).map(([name, role]) => [name, { name, ...role }])),
    components: new Map(Object.entries(components)),
    routes: routes.map(({ name, scope, callers, server, publishers, subscribers, flow }): Route =>
      flow.kind === "event"
        ? { name, scope, publishers: publishers!, subscribers: subscribers!, flow }
        : { name, scope, callers: callers!, server: server!, flow },
    ),
    buckets: buckets.map((bucket) => ({
      name: bucket.name,
      key: bucket.key,
      owner: bucket.owner.role,
      writers: bucket.writers.map((writer) => writer.role),
      markerTtlSeconds: bucket.marker_ttl_seconds,
    })),
  };
}
