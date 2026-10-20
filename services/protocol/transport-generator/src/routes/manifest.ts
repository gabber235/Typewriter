import { isNode, LineCounter, parseDocument, type Document } from "yaml";
import { z } from "zod";

import { PARAMETERS, SubjectTemplate, sortedParameters, type Parameter } from "./subject.js";

/** Scope kinds in the order generated code groups them. */
export const SCOPE_KINDS = [
  "realm",
  "service",
  "bound_service",
  "organization_actor",
  "organization",
  "user",
  "native",
  "internal_component",
] as const;
export type ScopeKind = (typeof SCOPE_KINDS)[number];

/** Endpoint sides in the order generated code visits them. */
export const SIDES = ["panel", "service", "backend", "backend_internal"] as const;
export type Side = (typeof SIDES)[number];

/** Grant roles in the order generated role enums declare them. */
export const ROLES = [
  "authenticated_user",
  "organization_member",
  "realm_coordinator",
  "realm_participant",
  "registered_service",
  "native_client",
] as const;
export type Role = (typeof ROLES)[number];

export const CHANNELS = ["request", "updates", "event"] as const;
export type Channel = (typeof CHANNELS)[number];

export const DIRECTIONS = ["publish", "subscribe"] as const;
export type Direction = (typeof DIRECTIONS)[number];

/** A Skir declaration named as `module.skir:Declaration` or `module.skir:Outer.Inner`. */
export interface SymbolRef {
  readonly module: string;
  readonly path: readonly string[];
}

/** Formats a symbol reference the way the manifest spells it. */
export function symbolRefText(reference: SymbolRef): string {
  return `${reference.module}:${reference.path.join(".")}`;
}

/** Endpoint subjects per side, iterated in {@link SIDES} order. */
export type Endpoints = ReadonlyMap<Side, SubjectTemplate>;

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

function bySide<T>(value: Partial<Record<Side, T>>): ReadonlyMap<Side, T> {
  return new Map(
    SIDES.flatMap((side) => (value[side] === undefined ? [] : [[side, value[side]] as const])),
  );
}

const RouteName = z.string().regex(/^[a-z_][a-z0-9_]*$/, {
  error: (issue) => `invalid route identifier ${JSON.stringify(issue.input)}`,
});

const ClosedIdentifier = (label: string) =>
  z.string().regex(/^[a-z0-9_.-]+$/, {
    error: (issue) => `invalid ${label} ${JSON.stringify(issue.input)}`,
  });

const KotlinSymbol = z.string().regex(/^[A-Za-z_][A-Za-z0-9_]*(\.[A-Za-z_][A-Za-z0-9_]*)*$/, {
  error: (issue) => `invalid Kotlin symbol ${JSON.stringify(issue.input)}`,
});

const KotlinTarget = z.literal("loader_core", {
  error: (issue) => `unsupported Kotlin generator target ${JSON.stringify(issue.input)}`,
});

const NativeKotlinFormat = z.literal("kotlin_serialization_cbor");

const Subject = z.string().transform(checked(SubjectTemplate.parse));

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

const Endpoints = z.partialRecord(z.enum(SIDES), Subject).transform(bySide);

const Wildcards = z
  .array(z.enum(PARAMETERS))
  .transform((parameters): readonly Parameter[] => sortedParameters(parameters));

const EventEndpoint = z.union([
  Subject.transform((subject) => ({ subject, subscription: undefined })),
  z.strictObject({
    subject: Subject,
    subscription: z.strictObject({ wildcard: Wildcards }).optional(),
  }),
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

const Event = z.strictObject({ payload: Reference, addresses: Endpoints, delivery: Delivery });

const RequestResponseBinding = z.discriminatedUnion("kind", [
  z.strictObject({ kind: z.literal("skir"), method: Reference }),
  z.strictObject({
    kind: z.literal("native_kotlin"),
    format: NativeKotlinFormat,
    target: KotlinTarget,
    request_type: KotlinSymbol,
    response_type: KotlinSymbol,
    request_codec: KotlinSymbol,
    response_codec: KotlinSymbol,
  }),
]);

const EventBinding = z.discriminatedUnion("kind", [
  z.strictObject({ kind: z.literal("skir"), payload: Reference }),
  z.strictObject({
    kind: z.literal("native_kotlin"),
    format: NativeKotlinFormat,
    target: KotlinTarget,
    event_type: KotlinSymbol,
    event_codec: KotlinSymbol,
  }),
]);

const Operation = { operation: z.string(), failure_slug: z.string() };

const Flow = z.discriminatedUnion("kind", [
  z.strictObject({
    kind: z.literal("unary"),
    method: Reference,
    requests: Endpoints,
    ...Operation,
  }),
  z.strictObject({
    kind: z.literal("watch"),
    method: Reference,
    requests: Endpoints,
    updates: Event,
    ...Operation,
  }),
  z.strictObject({
    kind: z.literal("bounded_watch"),
    method: Reference,
    requests: Endpoints,
    updates: Endpoints,
    transfer_field: z.string(),
    ...Operation,
  }),
  z.strictObject({
    kind: z.literal("scatter"),
    binding: RequestResponseBinding,
    requests: Endpoints,
    ...Operation,
  }),
  z.strictObject({
    kind: z.literal("event"),
    binding: EventBinding,
    addresses: z.partialRecord(z.enum(SIDES), EventEndpoint).transform(bySide),
    delivery: Delivery,
    ...Operation,
  }),
]);

const Grant = z.strictObject({
  role: z.enum(ROLES),
  side: z.enum(SIDES),
  channel: z.enum(CHANNELS),
  direction: z.enum(DIRECTIONS),
});

const Route = z.strictObject({
  name: RouteName,
  scope: z.enum(SCOPE_KINDS),
  grants: z.array(Grant),
  subscription: z
    .strictObject({
      component: ClosedIdentifier("component name"),
      group: ClosedIdentifier("consumer group"),
    })
    .optional(),
  flow: Flow,
});

const Manifest = z.strictObject({ routes: z.array(Route) });

export type Manifest = z.output<typeof Manifest>;
export type Route = Manifest["routes"][number];
export type Flow = Route["flow"];
export type Grant = Route["grants"][number];
export type Delivery = z.output<typeof Delivery>;
export type EventEndpoint = z.output<typeof EventEndpoint>;
export type ComponentSubscription = NonNullable<Route["subscription"]>;
export type NativeKotlinRequestResponseBinding = Extract<
  z.output<typeof RequestResponseBinding>,
  { kind: "native_kotlin" }
>;
export type NativeKotlinEventBinding = Extract<
  z.output<typeof EventBinding>,
  { kind: "native_kotlin" }
>;

/** A manifest that failed YAML parsing or schema admission; the message names the YAML path. */
export class ManifestError extends Error {
  override readonly name = "ManifestError";
}

/**
 * Parses and admits the transport route manifest. Duplicate YAML keys and unknown fields fail.
 * Errors carry the source file, the YAML path such as `routes[3].flow.requests.panel` and the line.
 */
export function parseManifest(source: string, file: string): Manifest {
  const lineCounter = new LineCounter();
  const document = parseDocument(source, { lineCounter, uniqueKeys: true });
  const [syntaxError] = document.errors;
  if (syntaxError) {
    throw new ManifestError(`${file}: ${syntaxError.message}`);
  }
  const result = Manifest.safeParse(document.toJS());
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
  return result.data;
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
