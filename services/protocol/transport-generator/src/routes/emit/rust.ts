import type { CodeGenerator } from "skir-internal";

import { upperCamel } from "../../text.js";
import { CONSUMER_NAME, grantText, type Grant, type GrantToken } from "../grants.js";
import {
  SCOPE_KINDS,
  type RoleDeclaration,
  type ScopeKind,
  type TransportLimits,
} from "../manifest.js";
import type { ResolvedRoutes } from "../resolve.js";
import { scopeParameters } from "../subject.js";
import { emitDispatchers } from "./rust_dispatch.js";
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

/** The manifest reply framing limits, which bound replies and the service response permission. */
function emitLimits({ chunkBytes, maxChunks }: TransportLimits): string[] {
  return [
    "/// The most bytes of an encoded reply that one reply frame carries.",
    `pub const RESPONSE_CHUNK_BYTES: usize = ${chunkBytes};`,
    "/// The most frames one reply may have, and so the most messages a responder may send to one",
    "/// requester inbox.",
    `pub const MAX_RESPONSE_CHUNKS: usize = ${maxChunks};`,
  ];
}

/**
 * Emits the backend transport module: the reply framing limits, the role grants of each scope, the
 * consumer naming rule, one route type per route a component serves or publishes on, and one
 * dispatcher per component that receives messages. The route independent runtime they build on is hand written in
 * `crate::transport`. generate.ts formats the module with rustfmt.
 */
export function emitRust(
  resolved: ResolvedRoutes,
  symbols: CodeGenerator.SymbolProvider,
): CodeGenerator.OutputFile[] {
  const { routes } = resolved;
  const lines = [
    "//! Generated transport routes. Do not edit; regenerate with `bun run generate:protocol`.",
    ...emitLimits(resolved.limits),
    ...emitGrants(resolved),
    ...emitConsumerName(),
    ...routes.flatMap((route) => emitRequestRoute(route, symbols)),
    ...routes.flatMap((route) => emitEventRoute(route, symbols)),
    ...routes.flatMap((route) => emitUpdateDelivery(route, symbols)),
    ...emitDispatchers(resolved, symbols),
  ];
  return [{ path: "mod.rs", code: `${lines.join("\n")}\n` }];
}
