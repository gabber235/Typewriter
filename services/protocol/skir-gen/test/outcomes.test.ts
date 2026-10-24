import { describe, expect, test } from "bun:test";

import type { CodeGenerator, Field } from "skir-internal";
import { ModuleSet } from "skir/dist/module_set.js";

import {
  classifyVariant,
  methodResponses,
  variantMessage,
  variantSlug,
} from "../src/outcomes.js";
import { emitDart } from "../src/routes/emit/dart.js";
import { emitKotlin } from "../src/routes/emit/kotlin.js";
import { emitRust } from "../src/routes/emit/rust.js";
import { parseManifest } from "../src/routes/manifest.js";
import { resolveRoutes } from "../src/routes/resolve.js";
import { symbolProviders } from "../src/symbols.js";
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

describe("generated outcomes", () => {
  const source = `struct Pong {}
method Ping(struct {}): enum {
  ok: Pong = 1;
  /// The pong was refused.
  refused_error: Pong = 2;
  internal_error: InternalError = 3;
} = 1;
`;

  test("Kotlin policies classify by kind and fall back to the internal_error wrapper", () => {
    const input = skirInput(source);
    const [realm] = emitKotlin(resolve(route("ping", "Ping"), input), symbolProviders(input).kotlin);
    expect(realm!.code).toContain(`private val pingResponsePolicy = ResponsePolicy<skirout.test.PingResponse>(
    skirout.test.PingResponse.InternalErrorWrapper(skirout.kernel.v1.errors.InternalError.partial()),
) { response ->
    when (response.kind) {
        skirout.test.PingResponse.Kind.OK_WRAPPER -> ResponseClassification.success("ok")
        skirout.test.PingResponse.Kind.REFUSED_ERROR_WRAPPER -> ResponseClassification.domainError("refused-error")
        skirout.test.PingResponse.Kind.INTERNAL_ERROR_WRAPPER -> ResponseClassification.internalError("internal-error")
        else -> ResponseClassification.internalError("unknown")
    }
}`);
    expect(realm!.code).toContain(`val RealmRouteScope.ping get() = skirUnaryContract(
    method = Ping, name = OperationName.of("test.ping"),
    address = pingRequestAddress.subscribedAt(this), responsePolicy = pingResponsePolicy,
    // Answers _INBOX.*.*.*.
    replyAddresses = ReplyAddressRule { _, reply -> isPanelReplyInbox(reply) },
)`);
  });

  test("Rust implements SkirResponse from the variant names and docs", () => {
    const input = skirInput(source);
    const [rust] = emitRust(resolve("", input), symbolProviders(input).rust, input);
    const response = "crate::skirout::base::test::PingResponse";
    expect(rust!.code).toContain(`impl crate::SkirResponse for ${response} {\n    fn outcome(&self)`);
    expect(rust!.code).toContain(
      `            ${response}::Ok(_) => crate::SkirResponseOutcome::Success,\n` +
        `            ${response}::RefusedError(_) => crate::SkirResponseOutcome::DomainError,\n` +
        "            // internal_error and the generated unknown variant\n" +
        "            _ => crate::SkirResponseOutcome::InternalError,",
    );
    expect(rust!.code).toContain(`            ${response}::RefusedError(_) => "refused-error",`);
    expect(rust!.code).toContain('            _ => "unknown",');
    expect(rust!.code).toContain(`            ${response}::RefusedError(_) => "The pong was refused.".to_owned(),`);
    expect(rust!.code).toContain(`        ${response}::InternalError(::std::default::Default::default())`);
    expect(rust!.code).toContain(
      `            "refused-error" => Some(${response}::RefusedError(::std::default::Default::default())),`,
    );
  });

  test("Dart operations pass the generated outcome function", () => {
    const input = skirInput(source);
    const [dart] = emitDart(resolve(route("ping", "Ping"), input), symbolProviders(input).dart);
    expect(dart!.code).toContain("outcome: _pingOutcome,");
    expect(dart!.code).toContain(`ResponseOutcome _pingOutcome(_lib_test.PingResponse response) => switch (response.kind) {
    _lib_test.PingResponse_kind.okWrapper => ResponseOutcome.success,
    _lib_test.PingResponse_kind.refusedErrorWrapper => ResponseOutcome.domainError,
    // internal_error and the generated unknown variant
    _ => ResponseOutcome.internalError,
};`);
  });

  test("the committed contracts admit every route and method response", async () => {
    const { input } = await committedRoutes();
    const responses = methodResponses(input).map(({ method }) => method.name.text);
    expect(responses).toContain("IssueServiceIdentity");
    expect(responses).toContain("GetEntityPermission");
    expect(responses).toContain("WatchEditorCatalog");
  });
});
