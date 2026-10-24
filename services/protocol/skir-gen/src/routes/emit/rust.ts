import type { CodeGenerator } from "skir-internal";

import { upperCamel } from "../../text.js";
import {
  CONSUMER_NAME,
  grantText,
  REPLY_INBOX,
  type Grant,
  type GrantToken,
  type ReplyInboxValue,
} from "../grants.js";
import {
  SCOPE_KINDS,
  type RoleDeclaration,
  type ScopeKind,
  type TransportLimits,
} from "../manifest.js";
import { methodResponses } from "../../outcomes.js";
import type { ResolvedRoutes } from "../resolve.js";
import { serviceResponseLimit } from "../responses.js";
import { scopeParameters } from "../subject.js";
import { emitDispatchers } from "./rust_dispatch.js";
import { emitResponses } from "./rust_responses.js";
import { emitSkirTypes } from "./rust_skir_types.js";
import {
  emitEventRoute,
  emitRequestRoute,
  emitUpdateDelivery,
  SCOPE_FIELDS,
  scopeType,
  TRANSPORT,
} from "./rust_routes.js";

/** The scope type whose fields are exactly the identifiers a role is bound to. */
function grantScope(role: RoleDeclaration): ScopeKind {
  const bound = new Set<string>([...role.tenant, ...(role.personal ? [role.personal] : [])]);
  const scope = SCOPE_KINDS.find((candidate) => {
    const fields = scopeParameters(candidate);
    return fields.length === bound.size && fields.every((field) => bound.has(field));
  });
  if (!scope) {
    throw new Error(`role ${role.name} binds [${[...bound].join(", ")}], which no scope type holds`);
  }
  return scope;
}

/**
 * Renders one grant insertion in the layout rustfmt keeps for an insertion that exceeds the line
 * width; rustfmt rewrites the insertions it can fit. The subject is a `String` expression over the
 * scope fields and consumer names.
 */
function grantInsert(grant: Grant): string[] {
  const [call, subject] = grantExpression(grant.tokens);
  return [
    "grants",
    `    .${grant.direction}`,
    "    .insert(",
    `        ${call}`,
    `            ${subject}`,
    `        ),`,
    "    );",
  ];
}

function grantExpression(tokens: readonly GrantToken[]): [string, string] {
  let captures = false;
  const value = tokens
    .map((token) => {
      switch (token.kind) {
        case "literal":
          return token.value;
        case "wildcard":
          return "*";
        case "parameter":
          captures = true;
          return `{${token.parameter}}`;
        case "consumer":
          captures = true;
          return `{${token.projection}}`;
      }
    })
    .join(".");
  return [captures ? "format!(" : "String::from(", JSON.stringify(value)];
}

/** Rust expressions of the consumer identity tuple values, by {@link CONSUMER_NAME} entry. */
const CONSUMER_VALUES: Record<(typeof CONSUMER_NAME.tuple)[number], string> = {
  actor: "actor.as_str()",
  organization: `organization.map(${TRANSPORT}::SubjectToken::as_str)`,
  session: "session.as_str()",
  projection: "projection",
};

const CONSUMER_PARAMETERS: Record<(typeof CONSUMER_NAME.tuple)[number], string> = {
  actor: `actor: &${TRANSPORT}::SubjectToken`,
  organization: `organization: Option<&${TRANSPORT}::SubjectToken>`,
  session: `session: &${TRANSPORT}::ConnectionSession`,
  projection: "projection: &str",
};

/** The consumer naming rule of {@link CONSUMER_NAME}; the panel emitter writes the same rule. */
function emitConsumerName(): string[] {
  const { prefix, tuple } = CONSUMER_NAME;
  return [
    `/// Names a connection's persistent projection consumer: \`${prefix}\` followed by the unpadded`,
    `/// URL safe Base64 of the compact JSON array \`[${tuple.join(", ")}]\`.`,
    "/// The panel derives the same name when it opens the consumer.",
    "pub fn consumer_name(",
    ...tuple.map((name) => `    ${CONSUMER_PARAMETERS[name]},`),
    ") -> String {",
    "    use base64::Engine as _;",
    `    let identity = serde_json::json!([${tuple.map((name) => CONSUMER_VALUES[name]).join(", ")}]);`,
    "    format!(",
    `        ${JSON.stringify(`${prefix}{}`)},`,
    "        base64::engine::general_purpose::URL_SAFE_NO_PAD.encode(identity.to_string())",
    "    )",
    "}",
  ];
}

/** The `consumer_name` call naming one projection consumer of a role's connection. */
function consumerBinding(role: RoleDeclaration, projection: string): string {
  const organization = role.tenant.includes("organization") ? "Some(organization)" : "None";
  return `let ${projection} = consumer_name(${role.personal}, ${organization}, session, ${JSON.stringify(projection)});`;
}

/**
 * Emits one role enum and grant function per scope type that grantee roles bind. A role's grant
 * inserts every subject its routes derive for it; the function takes the connection session when
 * one of its roles receives persistent projections, whose consumer names depend on it.
 */
function emitGrants({ roles, routes }: ResolvedRoutes): string[] {
  const grouped = new Map<ScopeKind, Map<string, Grant[]>>();
  for (const role of roles.values()) {
    const grants = routes.flatMap((route) => route.grants.filter((grant) => grant.role === role.name));
    if (grants.length === 0) {
      continue;
    }
    const scope = grantScope(role);
    const byRole = grouped.get(scope) ?? new Map<string, Grant[]>();
    grouped.set(scope, byRole);
    byRole.set(role.name, grants);
  }
  return SCOPE_KINDS.flatMap((scope) => {
    const byRole = grouped.get(scope);
    if (!byRole) {
      return [];
    }
    const roleType = `${upperCamel(scope)}Role`;
    const consumers = [...byRole.values()].some((grants) =>
      grants.some((grant) => grant.tokens.some((token) => token.kind === "consumer")),
    );
    const arms = [...byRole].flatMap(([name, grants]) => {
      const role = roles.get(name)!;
      const projections = [
        ...new Set(
          grants.flatMap((grant) =>
            grant.tokens.flatMap((token) => (token.kind === "consumer" ? [token.projection] : [])),
          ),
        ),
      ];
      const inserts = new Map(grants.map((grant) => [`${grant.direction} ${grantText(grant.tokens)}`, grant]));
      return [
        `            ${roleType}::${upperCamel(name)} => {`,
        ...projections.map((projection) => `                ${consumerBinding(role, projection)}`),
        ...[...inserts.values()].flatMap(grantInsert).map((line) => `                ${line}`),
        "            }",
      ];
    });
    const fields = SCOPE_FIELDS[scope];
    return [
      "#[derive(Clone, Copy, Debug, PartialEq, Eq)]",
      `pub enum ${roleType} {`,
      ...[...byRole.keys()].map((name) => `    ${upperCamel(name)},`),
      "}",
      `impl ${scopeType(scope)} {`,
      "    /// Inserts every subject the role may publish to or subscribe to within this scope.",
      "    pub fn grant(",
      "        &self,",
      `        role: ${roleType},`,
      ...(consumers ? [`        session: &${TRANSPORT}::ConnectionSession,`] : []),
      `        grants: &mut ${TRANSPORT}::GrantSet,`,
      "    ) {",
      ...(fields.length === 0 ? [] : [`        let Self { ${fields.join(", ")} } = self;`]),
      "        match role {",
      ...arms,
      "        }",
      "    }",
      "}",
    ];
  });
}

/**
 * The manifest payload framing limits, which bound component replies, and the response limit of
 * service connections, which the backend grants. Panel connections get no response permission.
 */
function emitLimits({ limits, roles, routes }: ResolvedRoutes): string[] {
  const { chunkBytes, windowFrames, replyMaxBytes, frameInactivityMs, replyTtlMs } = limits;
  const option = (value: number | null) => (value === null ? "None" : `Some(${value})`);
  return [
    "/// The most bytes of an encoded payload that one frame carries.",
    `pub const CHUNK_BYTES: usize = ${chunkBytes};`,
    "/// How many frames a sender may send before the receiver grants the next window.",
    `pub const WINDOW_FRAMES: usize = ${windowFrames};`,
    "/// The largest encoded reply a backend component sends; components serve no route that raises it.",
    `pub const REPLY_MAX_BYTES: usize = ${replyMaxBytes};`,
    "/// How long in milliseconds a sender waits for a credit and a receiver for the next frame.",
    `pub const FRAME_INACTIVITY_MS: u32 = ${frameInactivityMs};`,
    "/// How long in milliseconds a responder may send replies after it received a request.",
    `pub const REPLY_TTL_MS: i64 = ${replyTtlMs};`,
    "/// How many messages a service connection may send in answer to one received request: the frames",
    "/// of the largest reply any service role serves. None when no service role answers.",
    `pub const SERVICE_RESPONSE_LIMIT: Option<u32> = ${option(serviceResponseLimit(roles, routes))};`,
  ];
}

const REPLY_INBOX_PARAMETERS: Record<ReplyInboxValue, string> = {
  user: `user: &${TRANSPORT}::SubjectToken`,
  session: `session: &${TRANSPORT}::ConnectionSession`,
  service: `service: &${TRANSPORT}::SubjectToken`,
};

/** The reply inbox prefix rule of {@link REPLY_INBOX}, which the backend grants per connection. */
function emitReplyInboxes(): string[] {
  return (["panel", "service"] as const).flatMap((side) => {
    const values = REPLY_INBOX[side];
    const pattern = [REPLY_INBOX.root, ...values.map((value) => `{${value}}`)].join(".");
    const parameters = values.map((value) => REPLY_INBOX_PARAMETERS[value]).join(", ");
    const format = JSON.stringify([REPLY_INBOX.root, ...values.map(() => "{}")].join("."));
    return [
      `/// The reply inbox prefix of a ${side} connection, \`${pattern}\`. Its reply inboxes are`,
      "/// single tokens below it.",
      `pub fn ${side}_reply_inbox_prefix(${parameters}) -> String {`,
      `    format!(${format}, ${values.map((value) => `${value}.as_str()`).join(", ")})`,
      "}",
    ];
  });
}

/**
 * Emits the backend transport module: the payload framing and response limits, the role grants of each scope, the
 * consumer naming rule, the reply inbox prefixes, one route type per route a component serves or publishes on, one
 * dispatcher per component that receives messages and the `SkirResponse` implementation of every
 * method response. Its `skir_types` child module implements `SkirType` for every Skir record. The
 * route independent runtime they build on is hand written in `crate::transport`. generate.ts
 * formats both files with rustfmt.
 */
export function emitRust(
  resolved: ResolvedRoutes,
  symbols: CodeGenerator.SymbolProvider,
  input: CodeGenerator.Input<unknown>,
): CodeGenerator.OutputFile[] {
  const { routes } = resolved;
  const lines = [
    "//! Generated transport routes. Do not edit; regenerate with `bun run generate:protocol`.",
    "mod skir_types;",
    ...emitLimits(resolved),
    ...emitGrants(resolved),
    ...emitConsumerName(),
    ...emitReplyInboxes(),
    ...routes.flatMap((route) => emitRequestRoute(route, symbols)),
    ...routes.flatMap((route) => emitEventRoute(route, symbols)),
    ...routes.flatMap((route) => emitUpdateDelivery(route, symbols)),
    ...emitDispatchers(resolved, symbols),
    ...emitResponses(methodResponses(input), symbols),
  ];
  return [
    { path: "mod.rs", code: `${lines.join("\n")}\n` },
    { path: "skir_types.rs", code: `${emitSkirTypes(input, symbols).join("\n")}\n` },
  ];
}
