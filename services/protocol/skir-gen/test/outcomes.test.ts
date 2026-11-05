import { describe, expect, test } from "bun:test";

import type { CodeGenerator, Field } from "skir-internal";
import { ModuleSet } from "skir/dist/module_set.js";

import {
  classifyVariant,
  methodResponses,
  variantMessage,
  variantSlug,
} from "../src/outcomes.js";
import { parseManifest } from "../src/routes/manifest.js";
import { resolveRoutes } from "../src/routes/resolve.js";
import { committedRoutes, DART_PREFIX, manifestSource } from "./support.js";

const ERRORS = `struct InternalError {}
`;

const IMPORT = `import { InternalError } from "kernel/v1/errors.skir";\n`;

/** Compiles `test.skir` beside the kernel error module every response imports. */
function skirInput(source: string): CodeGenerator.Input<{ dartImportUriPrefix: string }> {
  const modules = ModuleSet.compile(
    new Map([
      ["kernel/v1/errors.skir", ERRORS],
      ["test.skir", source.includes("InternalError") ? `${IMPORT}${source}` : source],
    ]),
    "no-cache",
    "strict",
  );
  expect(modules.errors).toEqual([]);
  return {
    modules: [...modules.modules.values()].map((module) => module.result!),
    recordMap: modules.recordMap,
    config: { dartImportUriPrefix: DART_PREFIX },
  };
}

/** One request route of the given flow kind served by a realm coordinator. */
function route(name: string, method: string, kind: "unary" | "watch" = "unary"): string {
  const updates =
    kind === "watch"
      ? `
      updates:
        payload: "test.skir:Pong"
        address: test.${name}.changed
        delivery: { kind: transient }`
      : "";
  return `  - name: ${name}
    scope: realm
    callers: [{ role: organization_member }]
    server: { role: realm_coordinator }
    flow:
      kind: ${kind}
      method: "test.skir:${method}"
      operation: test.${name}
      request: test.${name}${updates}
`;
}

function resolve(routes: string, input: CodeGenerator.Input<unknown>) {
  return resolveRoutes(parseManifest(manifestSource(routes), "routes.yaml"), input);
}

const variant = (name: string, doc = "") => ({ name: { text: name }, doc: { text: doc } }) as Field;

describe("outcome rule", () => {
  test("variant names decide outcomes", () => {
    expect(classifyVariant(variant("state"))).toBe("success");
    expect(classifyVariant(variant("absent"))).toBe("success");
    expect(classifyVariant(variant("needs_input"))).toBe("success");
    expect(classifyVariant(variant("catalog_changed_error"))).toBe("domain_error");
    expect(classifyVariant(variant("not_found_error"))).toBe("domain_error");
    expect(classifyVariant(variant("internal_error"))).toBe("internal_error");
    expect(classifyVariant(variant("error"))).toBe("success");
  });

  test("slugs are the Skir name in kebab case and messages come from docs", () => {
    expect(variantSlug(variant("service_not_found_error"))).toBe("service-not-found-error");
    expect(variantMessage(variant("service_not_found_error"))).toBe("service-not-found-error");
    expect(variantMessage(variant("service_not_found_error", " Service\n not found. "))).toBe(
      "Service not found.",
    );
  });
});

describe("outcome admission", () => {
  test("a request route without internal_error fails with the route and Skir position", () => {
    const input = skirInput(`struct Pong {}
method Ping(struct {}): enum { ok: Pong = 1; } = 1;
`);
    expect(() => resolve(route("ping", "Ping"), input)).toThrow(
      "route ping at routes[0].flow.method: PingResponse lacks internal_error: InternalError (Skir test.skir:2:8)",
    );
  });

  test("a struct response fails as not being an enum", () => {
    const input = skirInput(`struct Pong {}
method Ping(struct {}): Pong = 1;
`);
    expect(() => resolve(route("ping", "Ping", "watch"), input)).toThrow(
      "route ping at routes[0].flow.method: Pong must be an enum with internal_error: InternalError (Skir test.skir:1:8)",
    );
  });

  test("internal_error must carry the kernel InternalError", () => {
    const input = skirInput(`struct Pong {}
method Ping(struct {}): enum { ok: Pong = 1; internal_error: Pong = 2; } = 1;
`);
    expect(() => resolve(route("ping", "Ping"), input)).toThrow(
      "route ping at routes[0].flow.method: PingResponse lacks internal_error: InternalError",
    );
  });

  test("every method response enum is admitted, served by a route or not", () => {
    const input = skirInput(`struct Pong {}
method Ping(struct {}): enum { ok: Pong = 1; } = 1;
`);
    expect(() => methodResponses(input)).toThrow(
      "method test.skir:Ping: PingResponse lacks internal_error: InternalError (Skir test.skir:2:8)",
    );
  });

  test("method responses classify every declared variant", () => {
    const input = skirInput(`struct Pong {}
method Ping(struct {}): enum {
  ok: Pong = 1;
  /// The pong was refused.
  refused_error: Pong = 2;
  internal_error: InternalError = 3;
} = 1;
method Plain(struct {}): Pong = 2;
`);
    const [ping, ...others] = methodResponses(input);
    expect(others).toEqual([]);
    expect(ping!.method.name.text).toBe("Ping");
    expect(ping!.response.variants.map(({ slug, outcome, message }) => [slug, outcome, message])).toEqual([
      ["ok", "success", "ok"],
      ["refused-error", "domain_error", "The pong was refused."],
      ["internal-error", "internal_error", "internal-error"],
    ]);
  });
});

describe("scatter admission", () => {
  test("a scatter route is admitted through its response outcomes", () => {
    const input = skirInput(`struct Pong {}
method Apply(struct {}): enum {
  accepted: Pong = 1;
  stale_attempt_error: Pong = 2;
  internal_error: InternalError = 3;
} = 1;
`);
    const [scatter] = resolve(
      `  - name: apply
    scope: realm
    callers: [{ role: realm_coordinator }]
    server: { role: realm_participant }
    flow:
      kind: scatter
      method: "test.skir:Apply"
      operation: test.apply
      request: test.apply
`,
      input,
    ).routes;
    if (scatter!.flow.kind !== "scatter") throw new Error("apply must resolve as a scatter route");
    expect(scatter!.flow.method.outcomes.variants.map(({ slug, outcome }) => [slug, outcome])).toEqual([
      ["accepted", "success"],
      ["stale-attempt-error", "domain_error"],
      ["internal-error", "internal_error"],
    ]);
  });

  test("a scatter method without internal_error is refused", () => {
    const input = skirInput(`struct Pong {}
method Apply(struct {}): enum { accepted: Pong = 1; } = 1;
`);
    expect(() =>
      resolve(
        `  - name: apply
    scope: realm
    callers: [{ role: realm_coordinator }]
    server: { role: realm_participant }
    flow:
      kind: scatter
      method: "test.skir:Apply"
      operation: test.apply
      request: test.apply
`,
        input,
      ),
    ).toThrow("ApplyResponse lacks internal_error: InternalError");
  });
});

describe("committed outcomes", () => {
  test("the committed contracts admit every route and method response", async () => {
    const { input } = await committedRoutes();
    const responses = methodResponses(input).map(({ method }) => method.name.text);
    expect(responses).toContain("IssueServiceIdentity");
    expect(responses).toContain("GetEntityPermission");
    expect(responses).toContain("WatchEditorCatalog");
  });
});
