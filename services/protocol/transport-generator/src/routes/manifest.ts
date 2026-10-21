import { isNode, LineCounter, parseDocument, type Document } from "yaml";
import { z } from "zod";

import { SubjectTemplate, scopeParameters, type Parameter } from "./subject.js";

/** Scope kinds in the order generated code groups them. */
export const SCOPE_KINDS = [
  "realm",
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
    const address = SubjectTemplate.parse(value);
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
    consumer: z.literal("connection_projection"),
  }),
]);

const Updates = z.strictObject({ payload: Reference, address: Address, delivery: Delivery });

const Operation = z.string().regex(/^[a-z][a-z0-9_]*(\.[a-z][a-z0-9_]*)*$/, {
  error: (issue) => `invalid operation name ${JSON.stringify(issue.input)}`,
});

const Flow = z.discriminatedUnion("kind", [
  z.strictObject({
    kind: z.literal("unary"),
    method: Reference,
    operation: Operation,
    request: Address,
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
 * How the transports split a large reply: frames carry at most `chunkBytes` of the encoded reply
 * and one reply has at most `maxChunks` frames.
 */
export interface TransportLimits {
  readonly chunkBytes: number;
  readonly maxChunks: number;
}

/** The admitted route manifest. */
export interface Manifest {
  readonly limits: TransportLimits;
  readonly roles: RoleDeclarations;
  /** Backend component name to its deploy/base directory, relative to the repository root. */
  readonly components: ReadonlyMap<string, string>;
  readonly routes: readonly Route[];
}

const Limits = z.strictObject({
  chunk_bytes: z.int().positive(),
  max_chunks: z.int().positive(),
});

const RawManifest = z
  .strictObject({
    limits: Limits,
    roles: z.record(RoleName, RoleDeclaration),
    components: z.record(ComponentName, z.string().min(1)),
    routes: z.array(RouteShape),
  })
  .superRefine((manifest, context) => {
    const issue = (path: Array<string | number>, message: string) =>
      context.addIssue({ code: "custom", path, message });
    const used = new Set<string>();
    manifest.routes.forEach((route, index) => {
      const at = ["routes", index];
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
        for (const parameter of scopeParameters(route.scope) as readonly Identity[]) {
          const outer = NESTED_IN[parameter];
          if (!bound.has(parameter) && !(outer && role.tenant.includes(outer))) {
            issue(
              [...at, ...path, "role"],
              `role ${party.role} does not bind {${parameter}} of ${route.scope} scope`,
            );
          }
        }
      }
      admitAddresses(route.scope, route.flow, (path, message) =>
        issue([...at, "flow", ...path], message),
      );
    });
    for (const component of Object.keys(manifest.components)) {
      if (!used.has(component)) {
        const message = `component ${JSON.stringify(component)} takes part in no route`;
        issue(["components", component], message);
      }
    }
  });

/** Admits the placeholders of each flow address: every one is bound by the route scope. */
function admitAddresses(
  scope: ScopeKind,
  flow: Flow,
  issue: (path: string[], message: string) => void,
): void {
  const allowed = scopeParameters(scope);
  const admit = (path: string[], address: SubjectTemplate) => {
    for (const token of address.tokens) {
      if (token.kind === "parameter" && !allowed.includes(token.parameter)) {
        issue(path, `placeholder {${token.parameter}} is not bound by ${scope} scope`);
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

/** A manifest that failed YAML parsing or schema admission; the message names the YAML path. */
export class ManifestError extends Error {
  override readonly name = "ManifestError";
}

/**
 * Parses and admits the transport route manifest. Duplicate YAML keys and unknown fields fail, as
 * do parties that name undeclared roles or components, components that take part in no route,
 * roles whose bound identifiers do not cover the route scope, and address placeholders the route
 * scope does not bind. Errors carry the source file, the YAML path such as
 * `routes[3].flow.request` and the line.
 */
export function parseManifest(source: string, file: string): Manifest {
  const lineCounter = new LineCounter();
  const document = parseDocument(source, { lineCounter, uniqueKeys: true });
  const [syntaxError] = document.errors;
  if (syntaxError) {
    throw new ManifestError(`${file}: ${syntaxError.message}`);
  }
  const result = RawManifest.safeParse(document.toJS());
  if (!result.success) {
    throw new ManifestError(
      result.error.issues
        .map((issue) => {
          const path = issue.path.filter((key) => typeof key !== "symbol");
          const at = location(document, lineCounter, path);
          return `${file}${at}: ${yamlPath(path)}: ${issue.message}`;
        })
        .join("\n"),
    );
  }
  const { limits, roles, components, routes } = result.data;
  return {
    limits: { chunkBytes: limits.chunk_bytes, maxChunks: limits.max_chunks },
    roles: new Map(Object.entries(roles).map(([name, role]) => [name, { name, ...role }])),
    components: new Map(Object.entries(components)),
    routes: routes.map(({ name, scope, callers, server, publishers, subscribers, flow }): Route =>
      flow.kind === "event"
        ? { name, scope, publishers: publishers!, subscribers: subscribers!, flow }
        : { name, scope, callers: callers!, server: server!, flow },
    ),
  };
}

/** Formats a document path as `routes[3].flow.kind`. */
export function yamlPath(path: ReadonlyArray<string | number>): string {
  return path
    .map((key, index) =>
      typeof key === "number" ? `[${key}]` : index === 0 ? key : `.${key}`,
    )
    .join("");
}

function location(
  document: Document,
  lineCounter: LineCounter,
  path: ReadonlyArray<string | number>,
): string {
  for (let length = path.length; length >= 0; length--) {
    const node = document.getIn(path.slice(0, length), true);
    if (isNode(node) && node.range) {
      const { line, col } = lineCounter.linePos(node.range[0]);
      return `:${line}:${col}`;
    }
  }
  return "";
}
