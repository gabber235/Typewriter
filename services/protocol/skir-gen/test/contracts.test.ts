import { describe, expect, test } from "bun:test";
import { cpSync, globSync, mkdirSync, mkdtempSync, readFileSync, writeFileSync } from "node:fs";
import { tmpdir } from "node:os";
import { dirname, join } from "node:path";

import { normalizeContracts } from "../src/contracts/index.js";
import { repository } from "./support.js";

/** Writes `files` (module path to source) into a fresh directory and returns it. */
function skirTree(files: Record<string, string>): string {
  const directory = mkdtempSync(join(tmpdir(), "skir-contracts-"));
  for (const [path, source] of Object.entries(files)) {
    mkdirSync(dirname(join(directory, path)), { recursive: true });
    writeFileSync(join(directory, path), source);
  }
  return directory;
}

const read = (directory: string, path: string) => readFileSync(join(directory, path), "utf8");

/** A temporary copy of a repository directory, so normalization never touches committed files. */
function copyOf(path: string): string {
  const directory = mkdtempSync(join(tmpdir(), "skir-contracts-"));
  cpSync(repository(path), directory, { recursive: true });
  return directory;
}

/** The Skir files whose content differs between `directory` and the repository directory `path`. */
function changedFiles(directory: string, path: string): string[] {
  return globSync("**/*.skir", { cwd: directory })
    .filter((file) => read(directory, file) !== readFileSync(join(repository(path), file), "utf8"))
    .sort();
}

describe("normalizeContracts numbers every declaration and method from where it is declared", () => {
  test("assigns derived numbers to `?`, missing and stale numbers", async () => {
    const directory = skirTree({
      "editor/v1/catalog.skir": "struct EditorCatalog {}\nstruct Entry(?) {}\nmethod FetchEditorCatalog(EditorCatalog): Entry = 4962;",
      "editor/v1/action.skir": "struct Action(810700001) {}",
    });
    expect(await normalizeContracts(directory)).toEqual([]);
    expect(read(directory, "editor/v1/action.skir")).toBe("struct Action(84010001) {}");
    expect(read(directory, "editor/v1/catalog.skir")).toBe(
      "struct EditorCatalog(84020001) {}\nstruct Entry(84020002) {}\nmethod FetchEditorCatalog(EditorCatalog): Entry = 940201;",
    );
  });

  test("a method written with `= ?` gets its number", async () => {
    const directory = skirTree({
      "service/v1/topology.skir": "struct Host {}\nmethod DescribeHost(Host): Host = 930901;\nmethod DrainHost(Host): Host = ?;",
    });
    expect(await normalizeContracts(directory)).toEqual([]);
    expect(read(directory, "service/v1/topology.skir")).toBe(
      "struct Host(83010001) {}\nmethod DescribeHost(Host): Host = 930101;\nmethod DrainHost(Host): Host = 930102;",
    );
  });

  test("a method's inline request fields keep their own numbers", async () => {
    const directory = skirTree({
      "service/v1/status.skir": "method QueryServiceBinding(struct { id: string = 0; }): string = ?;",
    });
    await normalizeContracts(directory);
    expect(read(directory, "service/v1/status.skir")).toBe(
      "method QueryServiceBinding(struct { id: string = 0; }): string = 930101;",
    );
  });

  test("comments that look like numbers are left alone", async () => {
    const source = "// struct Old(1) = 2;\nstruct Kept(80010001) {\n  value: string = 0; // = 7\n}\n";
    const directory = skirTree({ "kernel/v1/kept.skir": source });
    expect(await normalizeContracts(directory)).toEqual([]);
    expect(read(directory, "kernel/v1/kept.skir")).toBe(source);
  });

  test("files are counted per context in code unit order of their names", async () => {
    const directory = skirTree({
      "editor/v1/catalog_presentation.skir": "struct Presentation {}",
      "editor/v1/catalog.skir": "struct Catalog {}",
      "kernel/v1/color.skir": "struct Color {}",
    });
    expect(await normalizeContracts(directory)).toEqual([]);
    expect(read(directory, "editor/v1/catalog.skir")).toBe("struct Catalog(84010001) {}");
    expect(read(directory, "editor/v1/catalog_presentation.skir")).toBe("struct Presentation(84020001) {}");
    expect(read(directory, "kernel/v1/color.skir")).toBe("struct Color(80010001) {}");
  });

  test("duplicate numbers are renumbered instead of rejected", async () => {
    const directory = skirTree({
      "access/v1/permission.skir": "struct Grant(5) {}\nstruct Denial(5) {}",
    });
    expect(await normalizeContracts(directory)).toEqual([]);
    expect(read(directory, "access/v1/permission.skir")).toBe("struct Grant(81010001) {}\nstruct Denial(81010002) {}");
  });

  test("files that already hold their derived numbers are not rewritten", async () => {
    const directory = skirTree({ "kernel/v1/color.skir": "struct Color(80010001) {}" });
    const before = Bun.file(join(directory, "kernel/v1/color.skir")).lastModified;
    await Bun.sleep(5);
    await normalizeContracts(directory);
    expect(Bun.file(join(directory, "kernel/v1/color.skir")).lastModified).toBe(before);
  });
});

describe("normalizeContracts rejects what no rewrite can fix", () => {
  test("rejects an import of another context", async () => {
    const directory = skirTree({
      "editor/v1/type_catalog.skir": "struct TypeUse(84010001) {}",
      "organization/v1/presence.skir": "import { TypeUse } from \"editor/v1/type_catalog.skir\";\nstruct P(82010001) { t: TypeUse = 0; }",
    });
    expect(await normalizeContracts(directory)).toEqual([{
      path: "organization/v1/presence.skir",
      message: "organization may not import editor/v1/type_catalog.skir; refer to editor entities through a kernel identity",
    }]);
  });

  test("every context may import kernel", async () => {
    const directory = skirTree({
      "kernel/v1/record_id.skir": "struct RecordId(80010001) { table: string = 0; }",
      "organization/v1/member.skir": "import { RecordId } from \"kernel/v1/record_id.skir\";\nstruct Member(82010001) { id: RecordId = 0; }",
    });
    expect(await normalizeContracts(directory)).toEqual([]);
  });

  test("rejects enum variants that do not run 1, 2, 3", async () => {
    const directory = skirTree({
      "service/v1/status.skir": "enum Health(83010001) {\n  ready = 1;\n  degraded = 3;\n}",
    });
    expect(await normalizeContracts(directory)).toEqual([{
      path: "service/v1/status.skir",
      message: "enum Health variants 1, 3 are not 1, 2, 3, ...",
    }]);
  });

  test("rejects removed numbers", async () => {
    const directory = skirTree({
      "service/v1/status.skir": "struct Probe(83010001) {\n  removed 0;\n  name: string = 1;\n}",
    });
    expect(await normalizeContracts(directory)).toEqual([{
      path: "service/v1/status.skir",
      message: "Probe uses removed; renumber instead",
    }]);
  });

  test("rejects files outside <context>/v1", async () => {
    const directory = skirTree({ "billing/v1/invoice.skir": "struct Invoice {}" });
    await expect(normalizeContracts(directory)).rejects.toThrow("billing/v1/invoice.skir must live in <context>/v1/");
  });
});

test("the committed contracts are normalized", async () => {
  const directory = copyOf("skir-src");
  expect(await normalizeContracts(directory)).toEqual([]);
  expect(changedFiles(directory, "skir-src")).toEqual([]);
});
