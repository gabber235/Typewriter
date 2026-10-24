import { describe, expect, test } from "bun:test";

import type { CodeGenerator } from "skir-internal";
import { ModuleSet } from "skir/dist/module_set.js";

import { emitSkirTypes } from "../src/routes/emit/rust_skir_types.js";
import { symbolProviders } from "../src/symbols.js";
import { DART_PREFIX, loadSkirInput } from "./support.js";

/** Compiles the given Skir modules into the input skir gen hands to generators. */
function skirInput(sources: Record<string, string>): CodeGenerator.Input<{ dartImportUriPrefix: string }> {
  const modules = ModuleSet.compile(new Map(Object.entries(sources)), "no-cache", "strict");
  expect(modules.errors).toEqual([]);
  return {
    modules: [...modules.modules.values()].map((module) => module.result!),
    recordMap: modules.recordMap,
    config: { dartImportUriPrefix: DART_PREFIX },
  };
}

function emit(input: CodeGenerator.Input<unknown>): string {
  return emitSkirTypes(input, symbolProviders(input as CodeGenerator.Input<never>).rust).join("\n");
}

describe("SkirType emission", () => {
  const source = `struct Pong {
  struct Detail {}
  detail: Detail;
}
enum Status {
  absent;
  rolled_back;
}
enum Reply {
  pong: Pong;
  closed;
}
enum Empty {}
method Ping(struct {}): Pong = 1;
`;

  test("structs keep the default and only reach their serializer", () => {
    const code = emit(skirInput({ "test.skir": source }));
    expect(code).toContain(`impl crate::SkirType for crate::skirout::base::test::Pong {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
}`);
  });

  test("an enum is unknown exactly when no declared variant matches", () => {
    const code = emit(skirInput({ "test.skir": source }));
    const status = "crate::skirout::base::test::Status";
    expect(code).toContain(`impl crate::SkirType for ${status} {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
    fn is_unknown(&self) -> bool {
        !matches!(self, ${status}::Absent | ${status}::RolledBack)
    }
}`);
    const reply = "crate::skirout::base::test::Reply";
    expect(code).toContain(`        !matches!(self, ${reply}::Pong(_) | ${reply}::Closed)`);
    expect(code).toContain(`impl crate::SkirType for crate::skirout::base::test::Empty {
    fn serializer() -> crate::skir_client::Serializer<Self> {
        Self::serializer()
    }
    fn is_unknown(&self) -> bool {
        true
    }
}`);
  });

  test("nested and inline method records are implemented too", () => {
    const code = emit(skirInput({ "test.skir": source }));
    expect(code).toContain("impl crate::SkirType for crate::skirout::base::test::Pong_Detail {");
    expect(code).toContain("impl crate::SkirType for crate::skirout::base::test::PingRequest {");
  });

  test("records follow module path order whatever order Skir collects modules in", () => {
    const input = skirInput({ "b.skir": "struct B {}\n", "a.skir": "struct A {}\n" });
    const reversed = { ...input, modules: [...input.modules].reverse() };
    const code = emit(input);
    expect(emit(reversed)).toBe(code);
    expect(code.indexOf("base::a::A {")).toBeLessThan(code.indexOf("base::b::B {"));
  });

  test("every record of the committed contracts has exactly one implementation", async () => {
    const input = await loadSkirInput();
    const code = emit(input);
    const records = input.modules.flatMap((module) => module.records);
    expect(code.match(/^impl crate::SkirType for /gmu)?.length).toBe(records.length);
    expect(new Set(records.map(({ record }) => record.key)).size).toBe(records.length);
    const status = "crate::skirout::base::service::v1::topology::ChildRuntimeStatus";
    expect(code).toContain(`impl crate::SkirType for ${status} {`);
    expect(code).toContain(`${status}::RolledBack | ${status}::Drifted)`);
  });
});
