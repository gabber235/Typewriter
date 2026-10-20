import type { CodeGenerator } from "skir-internal";

import { upperCamel } from "../../text.js";
import type { ScopeKind } from "../manifest.js";
import { routeChannel, type ResolvedMethod, type ResolvedRoute } from "../resolve.js";
import {
  scopeParameters,
  type ChannelSubjects,
  type Parameter,
  type SubjectTemplate,
} from "../subject.js";

/** The generated Rust type of a route, e.g. `UserOrganizationCreateRoute`. */
export function routeTypeName(route: ResolvedRoute): string {
  return `${upperCamel(route.name)}Route`;
}

/** The generated Rust scope type of a scope kind, e.g. `OrganizationActorScope`. */
export function scopeTypeName(scope: ScopeKind): string {
  return `${upperCamel(scope)}Scope`;
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

function field(parameter: Parameter): string {
  if (parameter === "transfer_id") {
    throw new Error("transfer capture is not a request scope");
  }
  return parameter;
}

/** A Rust string literal; subjects never contain quotes or backslashes, so none need escaping. */
function literal(value: string): string {
  return JSON.stringify(value);
}

/** Renders a subject as a `format!` call capturing the scope fields of the same name. */
export function renderSubject(template: SubjectTemplate): string {
  const value = template.tokens
    .map((token) => (token.kind === "literal" ? token.value : `{${field(token.parameter)}}`))
    .join(".");
  return `format!(${literal(value)})`;
}

function captureArm(template: SubjectTemplate, scope: ScopeKind): string {
  const captured = new Set<Parameter>();
  const pattern = template.tokens.map((token) => {
    if (token.kind === "literal") {
      return literal(token.value);
    }
    captured.add(token.parameter);
    return field(token.parameter);
  });
  const fields = scopeParameters(scope).map((parameter) => {
    if (!captured.has(parameter)) {
      throw new Error("required scope capture is absent");
    }
    return `${parameter}: SubjectToken::try_from(*${parameter})?`;
  });
  return `[${pattern.join(", ")}] => Ok(Some(${scopeTypeName(scope)} { ${fields.join(", ")} })),`;
}

function scopeMatch(arms: readonly string[]): string[] {
  return [
    "    fn scope(subject: &str) -> Result<Option<Self::Scope>, crate::otel_wasi::Error> {",
    "        let parts: Vec<_> = subject.split('.').collect();",
    "        match parts.as_slice() {",
    ...arms.map((arm) => `            ${arm}`),
    "            _ => Ok(None),",
    "        }",
    "    }",
  ];
}

function requestParts(
  route: ResolvedRoute,
): { method: ResolvedMethod; requests: ChannelSubjects } | undefined {
  const { flow } = route;
  const request = routeChannel(route, "request");
  return request && (flow.kind === "unary" || flow.kind === "watch" || flow.kind === "bounded_watch")
    ? { method: flow.method, requests: request.subjects }
    : undefined;
}

/** The subjects a backend component receives a channel on: bridged first, then direct. */
function backendSubjects(subjects: ChannelSubjects): SubjectTemplate[] {
  return [subjects.backend, subjects.internal].filter(
    (subject): subject is SubjectTemplate => subject !== undefined,
  );
}

/**
 * Emits the dispatch route of a request route a component serves, plus its outbound subject when
 * a component calls it. Routes without a backend subject emit nothing.
 */
export function emitRequestRoute(
  route: ResolvedRoute,
  symbols: CodeGenerator.SymbolProvider,
): string[] {
  const parts = requestParts(route);
  if (!parts) {
    return [];
  }
  const { method, requests } = parts;
  const arms = backendSubjects(requests).map((template) => captureArm(template, route.scope));
  if (arms.length === 0) {
    return [];
  }
  const name = routeTypeName(route);
  const scope = scopeTypeName(route.scope);
  const delivery =
    method.response.record.recordType === "enum"
      ? "DomainResponseDelivery"
      : "PlainResponseDelivery";
  const lines = [
    `pub struct ${name};`,
    `impl RequestRoute for ${name} {`,
    `    type Scope = ${scope};`,
    `    type Request = ${symbols.record(method.request).reference};`,
    `    type Response = ${symbols.record(method.response).reference};`,
    `    type Delivery = ${delivery};`,
    "    fn method() -> &'static crate::skir_client::Method<Self::Request, Self::Response> {",
    `        ${symbols.method(method.module, method.method).reference}`,
    "    }",
    ...scopeMatch(arms),
    "}",
  ];
  const subject = requests.internal;
  if (subject) {
    const fields = scopeParameters(route.scope).map(field);
    lines.push(
      `impl OutboundRequestRoute for ${name} {`,
      "    fn subject(scope: &Self::Scope) -> String {",
      fields.length === 0
        ? "        let _ = scope;"
        : `        let ${scope} { ${fields.join(", ")} } = scope;`,
      `        ${renderSubject(subject)}`,
      "    }",
      "}",
    );
  }
  return lines;
}

/** Emits the dispatch route of a Skir event the backend receives. */
export function emitEventRoute(
  route: ResolvedRoute,
  symbols: CodeGenerator.SymbolProvider,
): string[] {
  const { flow } = route;
  const event = routeChannel(route, "event");
  if (flow.kind !== "event" || flow.binding.kind !== "skir" || !event) {
    return [];
  }
  const arms = backendSubjects(event.subjects).map((template) =>
    captureArm(template, route.scope),
  );
  if (arms.length === 0) {
    return [];
  }
  const name = routeTypeName(route);
  return [
    `pub struct ${name};`,
    `impl EventRoute for ${name} {`,
    `    type Scope = ${scopeTypeName(route.scope)};`,
    `    type Event = ${symbols.record(flow.binding.payload).reference};`,
    "    fn serializer() -> crate::skir_client::Serializer<Self::Event> {",
    "        <Self::Event>::serializer()",
    "    }",
    ...scopeMatch(arms),
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
  const scope = scopeTypeName(endpointScope(address));
  const fields = address.tokens.flatMap((token) =>
    token.kind === "parameter" ? [field(token.parameter)] : [],
  );
  const { delivery } = flow.updates;
  return [
    `impl OutboundEventRoute for ${name} {`,
    `    type Scope = ${scope};`,
    `    type Event = ${symbols.record(flow.updates.payload).reference};`,
    "    fn serializer() -> crate::skir_client::Serializer<Self::Event> {",
    "        <Self::Event>::serializer()",
    "    }",
    "    fn subject(scope: &Self::Scope) -> String {",
    ...(fields.length === 0 ? [] : [`        let ${scope} { ${fields.join(", ")} } = scope;`]),
    `        ${renderSubject(address)}`,
    "    }",
    "}",
    `impl ${name} {`,
    `    pub fn delivery(scope: &${scope}) -> EventDelivery<Self> {`,
    "        EventDelivery::new(scope)",
    "    }",
    "}",
    ...(delivery.kind === "transient"
      ? [`impl TransientEventRoute for ${name} {}`]
      : [
          `impl PersistentEventRoute for ${name} {`,
          "    fn stream() -> &'static str {",
          `        ${literal(delivery.stream)}`,
          "    }",
          "}",
        ]),
  ];
}
