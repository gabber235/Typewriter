import type { CodeGenerator } from "skir-internal";

import { upperCamel } from "../../text.js";
import { servedSubjects, subscriptionSubject, type ServedSubject } from "../dispatch.js";
import type { ResolvedRoute, ResolvedRoutes } from "../resolve.js";
import {
  literal,
  requestMethod,
  routeTypeName,
  SCOPE_FIELDS,
  scopeType,
  TRANSPORT,
} from "./rust_routes.js";

/** The Rust module of a component's dispatcher, e.g. `organization_members`. */
function componentModule(component: string): string {
  return component.replaceAll("-", "_");
}

/**
 * The `use` declarations of one dispatcher module. Paths are imported under their last segment
 * unless that name is reserved or already imports another path; those stay fully qualified.
 */
class RustUses {
  private readonly names = new Map<string, string | undefined>();

  constructor(reserved: Iterable<string>) {
    for (const name of reserved) {
      this.names.set(name, undefined);
    }
  }

  /** Returns how the module spells `path`, importing it when its name is free. */
  name(path: string): string {
    const simple = path.slice(path.lastIndexOf("::") + 2);
    if (!this.names.has(simple)) {
      this.names.set(simple, path);
    }
    return this.names.get(simple) === path ? simple : path;
  }

  lines(): string[] {
    return [...this.names.values()]
      .filter((path): path is string => path !== undefined)
      .sort()
      .map((path) => `use ${path};`);
  }
}

/** One route a component handles: its handler field, type parameter and handler signature. */
interface HandledRoute {
  readonly route: ResolvedRoute;
  readonly field: string;
  readonly parameter: string;
  readonly bound: string;
  readonly serve: "serve_request" | "serve_event";
}

function handledRoute(
  route: ResolvedRoute,
  symbols: CodeGenerator.SymbolProvider,
  uses: RustUses,
): HandledRoute {
  const scope = uses.name(scopeType(route.scope));
  const method = requestMethod(route);
  const { flow } = route;
  let bound: string;
  let serve: HandledRoute["serve"];
  if (method) {
    const request = uses.name(symbols.record(method.request).reference);
    const response = uses.name(symbols.record(method.response).reference);
    bound = `AsyncFnOnce(${scope}, ${request}) -> Result<${response}, Error>`;
    serve = "serve_request";
  } else if (flow.kind === "event" && flow.binding.kind === "skir") {
    const event = uses.name(symbols.record(flow.binding.payload).reference);
    bound = `AsyncFnOnce(${scope}, ${event}) -> Result<(), Error>`;
    serve = "serve_event";
  } else {
    throw new Error(`route ${route.name} received by a component must be a Skir request or event`);
  }
  return { route, field: route.name, parameter: upperCamel(route.name), bound, serve };
}

/** The match arm serving one received subject on its route. */
function dispatchArm(served: ServedSubject, handled: HandledRoute, uses: RustUses): string[] {
  const { route } = handled;
  const pattern = served.subject.tokens.map((token) =>
    token.kind === "literal" ? literal(token.value) : token.parameter,
  );
  const fields = SCOPE_FIELDS[route.scope];
  const missing = fields.find((field) => !served.subject.has(field));
  if (missing) {
    throw new Error(`subject ${served.subject} of route ${route.name} does not capture {${missing}}`);
  }
  return [
    `        [${pattern.join(", ")}] => {`,
    `            let scope = ${uses.name(scopeType(route.scope))}::from_tokens(${fields.join(", ")});`,
    `            ${uses.name(`${TRANSPORT}::${handled.serve}`)}::<super::${routeTypeName(route)}>(msg, scope, handlers.${handled.field}).await`,
    "        }",
  ];
}

function emitComponent(
  component: string,
  served: readonly ServedSubject[],
  routes: ReadonlyMap<string, ResolvedRoute>,
  symbols: CodeGenerator.SymbolProvider,
): string[] {
  const names = [...new Set(served.map((entry) => entry.route))];
  const uses = new RustUses([...names.map(upperCamel), "Handlers", "SUBSCRIPTIONS", "dispatch"]);
  uses.name("crate::otel_wasi::Error");
  uses.name("crate::wasmcloud::messaging::types::NatsMessage");
  const handled = new Map(
    names.map((name) => [name, handledRoute(routes.get(name)!, symbols, uses)] as const),
  );
  const all = [...handled.values()];
  const parameters = all.map((entry) => entry.parameter).join(", ");
  const arms = served.flatMap((entry) => dispatchArm(entry, handled.get(entry.route)!, uses));
  const unmatched = uses.name(`${TRANSPORT}::unmatched`);
  return [
    `/// Typed dispatch of every message the \`${component}\` component receives.`,
    `pub mod ${componentModule(component)} {`,
    ...uses.lines().map((line) => `    ${line}`),
    "",
    "    /// The subjects the component subscribes to, one per subject the dispatcher matches.",
    "    pub const SUBSCRIPTIONS: &[&str] = &[",
    ...served.map((entry) => `        ${literal(subscriptionSubject(entry.subject))},`),
    "    ];",
    "",
    "    /// One handler per route the component serves, named after the route.",
    `    pub struct Handlers<${parameters}> {`,
    ...all.map((entry) => `        pub ${entry.field}: ${entry.parameter},`),
    "    }",
    "",
    "    /// Serves one received message on the route its subject matches. Any other subject fails",
    "    /// with `transport-unmatched-subject`.",
    '    #[allow(clippy::type_complexity, reason = "one type parameter per served route")]',
    `    pub async fn dispatch<${parameters}>(`,
    "        msg: NatsMessage,",
    `        handlers: Handlers<${parameters}>,`,
    "    ) -> Result<(), Error>",
    "    where",
    ...all.map((entry) => `        ${entry.parameter}: ${entry.bound},`),
    "    {",
    "        let subject = msg.subject.clone();",
    "        match subject.split('.').collect::<Vec<_>>().as_slice() {",
    ...arms.map((line) => `    ${line}`),
    `            _ => Err(${unmatched}(&msg)),`,
    "        }",
    "    }",
    "}",
  ];
}

/**
 * Emits one dispatcher module per component that receives messages, in manifest component order:
 * its exact subscriptions, a handler struct with one field per served route and a dispatch
 * function that splits the subject once and serves the matching route.
 */
export function emitDispatchers(
  resolved: ResolvedRoutes,
  symbols: CodeGenerator.SymbolProvider,
): string[] {
  const served = servedSubjects(resolved.routes);
  const routes = new Map(resolved.routes.map((route) => [route.name, route]));
  return [...resolved.components.keys()].flatMap((component) => {
    const subjects = served.get(component);
    return subjects ? emitComponent(component, subjects, routes, symbols) : [];
  });
}
