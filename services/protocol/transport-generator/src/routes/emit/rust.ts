import type { CodeGenerator } from "skir-internal";

import { upperCamel } from "../../text.js";
import { routeGrants } from "../grants.js";
import { ROLES, SCOPE_KINDS, type Direction, type Role, type ScopeKind } from "../manifest.js";
import type { ResolvedRoute } from "../resolve.js";
import type { Parameter, SubjectTemplate } from "../subject.js";
import {
  emitEventRoute,
  emitRequestRoute,
  emitUpdateDelivery,
  scopeTypeName,
} from "./rust_dispatch.js";
import { RUST_DISPATCH, RUST_SCOPES } from "./rust_runtime.js";

const ROLE_NAMES: Record<Role, string> = {
  authenticated_user: "AuthenticatedUser",
  organization_member: "OrganizationMember",
  realm_coordinator: "Coordinator",
  realm_participant: "Participant",
  registered_service: "RegisteredService",
  native_client: "NativeClient",
};

const ADMITTED_ROLES: Record<ScopeKind, readonly Role[]> = {
  realm: ["organization_member", "realm_coordinator", "realm_participant"],
  service: ["registered_service"],
  bound_service: ["registered_service"],
  organization_actor: ["organization_member"],
  organization: ["organization_member"],
  user: ["authenticated_user"],
  native: ["native_client"],
  internal_component: [],
};

/** Scope struct fields in the order the generated scope types declare them. */
const SCOPE_FIELDS: Record<ScopeKind, readonly string[]> = {
  realm: ["organization", "realm"],
  service: ["service"],
  bound_service: ["service", "organization"],
  organization_actor: ["user", "organization"],
  organization: ["organization"],
  user: ["user"],
  native: [],
  internal_component: [],
};

/** Renders a grant subject; wildcard identities and bounded transfer captures become `*`. */
function grantSubject(
  template: SubjectTemplate,
  transfer: boolean,
  wildcards: readonly Parameter[],
): string {
  const value = template.tokens
    .map((token) => {
      if (token.kind === "literal") {
        return token.value;
      }
      if (wildcards.includes(token.parameter) || (token.parameter === "transfer_id" && transfer)) {
        return "*";
      }
      if (token.parameter === "transfer_id") {
        throw new Error("transfer token requires a bounded update grant");
      }
      return `{${token.parameter}}`;
    })
    .join(".");
  return `format!(${JSON.stringify(value)})`;
}

/**
 * Writes one grant insertion in the layout prettyplease gives an insertion that exceeds the line
 * width. rustfmt rewrites the insertions it can fit and keeps this layout for the ones it cannot.
 */
function grantInsert(direction: Direction, expression: string): string[] {
  const subject = expression.slice("format!(".length, -1);
  return [
    "grants",
    `    .${direction}`,
    "    .insert(",
    "        format!(",
    `            ${subject}`,
    "        ),",
    "    );",
  ];
}

interface GrantInsert {
  readonly direction: Direction;
  readonly expression: string;
}

function emitGrants(routes: readonly ResolvedRoute[]): string[] {
  const grouped = new Map<ScopeKind, Map<Role, GrantInsert[]>>();
  for (const route of routes) {
    for (const spec of routeGrants(route)) {
      if (!ADMITTED_ROLES[route.scope].includes(spec.role)) {
        throw new Error(`role ${spec.role} is invalid for scope ${route.scope}`);
      }
      const roles = grouped.get(route.scope) ?? new Map();
      grouped.set(route.scope, roles);
      const grants = roles.get(spec.role) ?? [];
      roles.set(spec.role, grants);
      grants.push({
        direction: spec.direction,
        expression: grantSubject(spec.endpoint, spec.transferToken, spec.wildcardParameters),
      });
    }
  }
  return SCOPE_KINDS.flatMap((scope) => {
    const roles = grouped.get(scope);
    if (!roles) {
      return [];
    }
    const roleType = `${upperCamel(scope)}Role`;
    const present = ROLES.filter((role) => roles.has(role));
    const fields = SCOPE_FIELDS[scope];
    return [
      "#[derive(Clone, Copy, Debug, PartialEq, Eq)]",
      `pub enum ${roleType} {`,
      ...present.map((role) => `    ${ROLE_NAMES[role]},`),
      "}",
      `impl GrantScope for ${scopeTypeName(scope)} {`,
      `    type Role = ${roleType};`,
      "    fn grant(&self, role: Self::Role, grants: &mut GrantSet) {",
      ...(fields.length === 0 ? [] : [`        let Self { ${fields.join(", ")} } = self;`]),
      "        match role {",
      ...present.flatMap((role) => [
        `            ${roleType}::${ROLE_NAMES[role]} => {`,
        ...roles
          .get(role)!
          .flatMap(({ direction, expression }) => grantInsert(direction, expression))
          .map((line) => `                ${line}`),
        "            }",
      ]),
      "        }",
      "    }",
      "}",
    ];
  });
}

function emitMembershipProjections(routes: readonly ResolvedRoute[]): string[] {
  const projections = routes.flatMap((route) => {
    const { flow } = route;
    if (flow.kind !== "watch" || flow.updates.delivery.kind !== "persistent") {
      return [];
    }
    const address = flow.updates.addresses.get("panel");
    if (!address) {
      return [];
    }
    const { stream, projection } = flow.updates.delivery;
    return [{ scope: route.scope, stream, projection, address, variant: upperCamel(projection) }];
  });
  const subjectArms = projections.flatMap(({ scope, address, variant }) => {
    const expression = grantSubject(address, false, []);
    switch (scope) {
      case "user":
        return [
          `            Self::${variant} if organization.is_none() => {`,
          "                let user = actor;",
          `                Ok(${expression})`,
          "            }",
        ];
      case "organization_actor":
      case "organization":
        return [
          `            Self::${variant} => {`,
          "                let organization = organization.ok_or_else(|| {",
          "                    crate::otel_wasi::Error::new(",
          '                        "permissions-consumer-organization-required",',
          '                        "organization scope is not admitted",',
          "                    )",
          "                })?;",
          `                Ok(${expression})`,
          "            }",
        ];
      default:
        throw new Error(`persistent projection has unsupported scope ${scope}`);
    }
  });
  return [
    "#[derive(Clone, Copy, Debug, PartialEq, Eq)]",
    "pub enum MembershipProjection {",
    ...projections.map(({ variant }) => `    ${variant},`),
    "}",
    "impl MembershipProjection {",
    "    pub fn id(self) -> &'static str {",
    "        match self {",
    ...projections.map(
      ({ variant, projection }) => `            Self::${variant} => ${JSON.stringify(projection)},`,
    ),
    "        }",
    "    }",
    "    pub fn stream(self) -> &'static str {",
    "        match self {",
    ...projections.map(
      ({ variant, stream }) => `            Self::${variant} => ${JSON.stringify(stream)},`,
    ),
    "        }",
    "    }",
    "    pub fn event_subject(",
    "        self,",
    "        actor: &SubjectToken,",
    "        organization: Option<&SubjectToken>,",
    "    ) -> Result<String, crate::otel_wasi::Error> {",
    "        match self {",
    ...subjectArms,
    "            _ => Err(crate::otel_wasi::Error::new(",
    '                "permissions-consumer-projection-scope-invalid",',
    '                "projection does not belong to the admitted scope",',
    "            )),",
    "        }",
    "    }",
    "}",
  ];
}

/**
 * Emits the backend transport module: scope and grant types, membership projections, the dispatch
 * runtime and one route type per backend endpoint. generate.ts formats the module with rustfmt.
 */
export function emitRust(
  routes: readonly ResolvedRoute[],
  symbols: CodeGenerator.SymbolProvider,
): CodeGenerator.OutputFile[] {
  const lines = [
    RUST_SCOPES,
    ...emitGrants(routes),
    ...emitMembershipProjections(routes),
    RUST_DISPATCH,
    ...routes.flatMap((route) => emitRequestRoute(route, symbols)),
    ...routes.flatMap((route) => emitEventRoute(route, symbols)),
    ...routes.flatMap((route) => emitUpdateDelivery(route, symbols)),
  ];
  return [{ path: "mod.rs", code: `${lines.join("\n")}\n` }];
}
