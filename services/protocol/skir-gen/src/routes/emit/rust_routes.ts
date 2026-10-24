import type { CodeGenerator } from "skir-internal";

import { upperCamel } from "../../text.js";
import type { ScopeKind } from "../manifest.js";
import { routeChannel, type ResolvedMethod, type ResolvedRoute } from "../resolve.js";
import type { Parameter, SubjectTemplate } from "../subject.js";

/** The hand written runtime module the generated routes implement and call. */
export const TRANSPORT = "crate::transport";

/** Scope struct fields in the order the runtime declares them and `from_tokens` takes them. */
export const SCOPE_FIELDS: Record<ScopeKind, readonly Parameter[]> = {
  realm: ["organization", "realm"],
  service: ["service"],
  organization_actor: ["user", "organization"],
  organization: ["organization"],
  user: ["user"],
  internal_component: [],
};

/** The generated Rust type of a route, e.g. `UserOrganizationCreateRoute`. */
export function routeTypeName(route: ResolvedRoute): string {
  return `${upperCamel(route.name)}Route`;
}

/** The runtime scope type of a scope kind, e.g. `crate::transport::OrganizationActorScope`. */
export function scopeType(scope: ScopeKind): string {
  return `${TRANSPORT}::${upperCamel(scope)}Scope`;
}

/** The scope kind whose identities are exactly the captures of a delivery subject. */
function endpointScope(template: SubjectTemplate): ScopeKind {
  const captures = template.parameters().join(",");
  const scopes: Record<string, ScopeKind> = {
    user: "user",
    organization: "organization",
    service: "service",
    "organization,user": "organization_actor",
    "organization,realm": "realm",
  };
  const scope = scopes[captures];
  if (!scope) {
    throw new Error(`unsupported delivery subject captures [${captures}]`);
  }
  return scope;
}

/** A Rust string literal; subjects never contain quotes or backslashes, so none need escaping. */
export function literal(value: string): string {
  return JSON.stringify(value);
}

/**
 * Renders a subject as a `format!` call capturing the scope fields of the same name, or as a
 * `String::from` call when it captures none.
 */
function renderSubject(template: SubjectTemplate): string {
  const value = template.tokens
    .map((token) => (token.kind === "literal" ? token.value : `{${token.parameter}}`))
    .join(".");
  return template.parameters().length === 0
    ? `String::from(${literal(value)})`
    : `format!(${literal(value)})`;
}

/**
 * Emits `fn subject`, rendering a subject that captures exactly the fields of the scope; a scope
 * without fields leaves the parameter unused.
 */
function subjectFunction(scope: ScopeKind, template: SubjectTemplate): string[] {
  const fields = SCOPE_FIELDS[scope];
  if (template.parameters().length !== fields.length || !fields.every((field) => template.has(field))) {
    throw new Error(`subject ${template} does not capture exactly the ${scope} scope fields`);
  }
  return fields.length === 0
    ? ["    fn subject(_scope: &Self::Scope) -> String {", `        ${renderSubject(template)}`, "    }"]
    : [
        "    fn subject(scope: &Self::Scope) -> String {",
        `        let ${scopeType(scope)} { ${fields.join(", ")} } = scope;`,
        `        ${renderSubject(template)}`,
        "    }",
      ];
}

/** The Skir method of a unary or watch route, the request flows a component serves. */
export function requestMethod(route: ResolvedRoute): ResolvedMethod | undefined {
  const { flow } = route;
  return flow.kind === "unary" || flow.kind === "watch" ? flow.method : undefined;
}

/** Whether a component receives the route's request or event subject. */
function servedByComponent(route: ResolvedRoute): boolean {
  return route.channels.some(
    (channel) =>
      channel.kind !== "updates" && (channel.subjects.backend ?? channel.subjects.internal) !== undefined,
  );
}

/**
 * Emits the route type of a request route a component serves, plus its outbound subject when a
 * component calls it. Its response implements the generated `SkirResponse`, so a handler error
 * replies with the response's internal_error variant. Routes no component serves emit nothing.
 */
export function emitRequestRoute(
  route: ResolvedRoute,
  symbols: CodeGenerator.SymbolProvider,
): string[] {
  const method = requestMethod(route);
  if (!method || !servedByComponent(route)) {
    return [];
  }
  const name = routeTypeName(route);
  const lines = [
    `pub struct ${name};`,
    `impl ${TRANSPORT}::RequestRoute for ${name} {`,
    `    type Scope = ${scopeType(route.scope)};`,
    `    type Request = ${symbols.record(method.request).reference};`,
    `    type Response = ${symbols.record(method.response).reference};`,
    `    const REPLY_CREDIT: bool = ${route.limits.replyCredit};`,
    "    fn method() -> &'static crate::skir_client::Method<Self::Request, Self::Response> {",
    `        ${symbols.method(method.module, method.method).reference}`,
    "    }",
    "}",
  ];
  const subject = routeChannel(route, "request")?.subjects.internal;
  if (subject) {
    lines.push(
      `impl ${TRANSPORT}::OutboundRequestRoute for ${name} {`,
      ...subjectFunction(route.scope, subject),
      "}",
    );
  }
  return lines;
}

/** Emits the route type of a Skir event a component subscribes to. */
export function emitEventRoute(
  route: ResolvedRoute,
  symbols: CodeGenerator.SymbolProvider,
): string[] {
  const { flow } = route;
  if (flow.kind !== "event" || !servedByComponent(route)) {
    return [];
  }
  const name = routeTypeName(route);
  return [
    `pub struct ${name};`,
    `impl ${TRANSPORT}::EventRoute for ${name} {`,
    `    type Scope = ${scopeType(route.scope)};`,
    `    type Event = ${symbols.record(flow.payload).reference};`,
    "    fn serializer() -> crate::skir_client::Serializer<Self::Event> {",
    "        <Self::Event>::serializer()",
    "    }",
    "}",
  ];
}

/** Emits the outbound update delivery of a watch route whose component server publishes updates. */
export function emitUpdateDelivery(
  route: ResolvedRoute,
  symbols: CodeGenerator.SymbolProvider,
): string[] {
  const { flow } = route;
  const address = routeChannel(route, "updates")?.subjects.backend;
  if (flow.kind !== "watch" || !address) {
    return [];
  }
  const name = routeTypeName(route);
  const scopeKind = endpointScope(address);
  const scope = scopeType(scopeKind);
  const { delivery } = flow.updates;
  return [
    `impl ${TRANSPORT}::OutboundEventRoute for ${name} {`,
    `    type Scope = ${scope};`,
    `    type Event = ${symbols.record(flow.updates.payload).reference};`,
    "    fn serializer() -> crate::skir_client::Serializer<Self::Event> {",
    "        <Self::Event>::serializer()",
    "    }",
    ...subjectFunction(scopeKind, address),
    "}",
    `impl ${name} {`,
    `    pub fn delivery(scope: &${scope}) -> ${TRANSPORT}::EventDelivery<Self> {`,
    `        ${TRANSPORT}::EventDelivery::new(scope)`,
    "    }",
    "}",
    ...(delivery.kind === "transient"
      ? [`impl ${TRANSPORT}::TransientEventRoute for ${name} {}`]
      : [
          `impl ${TRANSPORT}::PersistentEventRoute for ${name} {`,
          "    fn stream() -> &'static str {",
          `        ${literal(delivery.stream)}`,
          "    }",
          "}",
        ]),
  ];
}
