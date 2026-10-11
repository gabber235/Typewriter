import { describe, expect, test } from "bun:test";

import {
  GENERATOR as dartGenerator,
  exportBindings as dartBindings,
} from "skir-dart-gen";
import {
  GENERATOR as kotlinGenerator,
  exportBindings as kotlinBindings,
} from "skir-kotlin-gen";
import {
  GENERATOR as rustGenerator,
  exportBindings as rustBindings,
} from "skir-rust-gen";

const emptyDoc = { text: "", pieces: [] };

function token(modulePath: string, text: string) {
  return {
    text,
    originalText: text,
    position: 0,
    colNumber: 0,
    line: { lineNumber: 0, line: text, position: 0, modulePath },
  };
}

function field(
  modulePath: string,
  name: string,
  number: number,
  type: unknown,
) {
  return {
    kind: "field",
    name: token(modulePath, name),
    number,
    doc: emptyDoc,
    unresolvedType: type,
    inlineRecord: undefined,
    type,
    isRecursive: false,
  };
}

function record(
  modulePath: string,
  name: string,
  recordType: "struct" | "enum",
  fields: ReturnType<typeof field>[],
) {
  const definition = {
    kind: "record",
    key: `${modulePath}:${name}`,
    name: token(modulePath, name),
    recordType,
    doc: emptyDoc,
    nameToDeclaration: Object.fromEntries(
      fields.map((item) => [item.name.text, item]),
    ),
    declarations: fields,
    fields,
    nestedRecords: [],
    removedNumbers: [],
    recordNumber: null,
    numSlots: recordType === "struct" ? fields.length : 0,
    numSlotsInclRemovedNumbers: recordType === "struct" ? fields.length : 0,
  };
  return {
    kind: "record-location",
    record: definition,
    recordAncestors: [definition],
    modulePath,
  };
}

function recordType(key: string, recordType: "struct" | "enum") {
  return {
    kind: "record",
    key,
    recordType,
    nameParts: [],
    refToken: token(key.split(":")[0]!, key.split(":")[1]!),
  };
}

function fixture() {
  const stringType = { kind: "primitive", primitive: "string" };
  const request = record("alpha/v1/input.skir", "Request", "struct", [
    field("alpha/v1/input.skir", "class", 0, stringType),
    field("alpha/v1/input.skir", "type", 1, stringType),
  ]);
  const collision = record("alpha/v1/input.skir", "Collision", "enum", [
    field("alpha/v1/input.skir", "foo_bar", 0, undefined),
    field("alpha/v1/input.skir", "fooBar", 1, stringType),
  ]);
  const response = record("beta/v1/output.skir", "Response", "struct", [
    field("beta/v1/output.skir", "value", 0, stringType),
  ]);
  const method = {
    kind: "method",
    name: token("alpha/v1/input.skir", "ReadAcrossModules"),
    doc: emptyDoc,
    unresolvedRequestType: recordType(request.record.key, "struct"),
    inlineRequestRecord: undefined,
    requestType: recordType(request.record.key, "struct"),
    unresolvedResponseType: recordType(response.record.key, "struct"),
    inlineResponseRecord: undefined,
    responseType: recordType(response.record.key, "struct"),
    number: 91,
  };
  const module = (
    path: string,
    records: unknown[],
    methods: unknown[],
  ) => ({
    kind: "module",
    path,
    sourceCode: "",
    nameToDeclaration: {},
    declarations: [...records, ...methods],
    pathToImportedNames: {},
    importBlockRange: null,
    records,
    methods,
    brokenMethods: [],
    constants: [],
    brokenConstants: [],
  });
  const modules = [
    module("alpha/v1/input.skir", [request, collision], [method]),
    module("beta/v1/output.skir", [response], []),
  ];
  const recordMap = new Map(
    [request, collision, response].map((location) => [
      location.record.key,
      location,
    ]),
  );
  return { modules, recordMap };
}

describe("public binding metadata", () => {
  test("matches generated method and struct symbols", () => {
    const input = fixture();
    const rust = rustBindings({ ...input, config: {} });
    const kotlin = kotlinBindings({ ...input, config: {} });
    const dart = dartBindings({
      ...input,
      config: { importUriPrefix: "package:typewriter/skirout/" },
    });

    const rustSource = rustGenerator
      .generateCode({ ...input, config: {} } as never)
      .files.map((file) => file.code)
      .join("\n");
    const kotlinSource = kotlinGenerator
      .generateCode({ ...input, config: {} } as never)
      .files.map((file) => file.code)
      .join("\n");
    const dartSource = dartGenerator
      .generateCode({ ...input, config: {} } as never)
      .files.map((file) => file.code)
      .join("\n");

    expect(rust.methods[0]!.method).toEqual({
      language: "rust",
      absolutePath:
        "crate::skirout::base::alpha::v1::input::read_across_modules_method",
    });
    expect(rustSource).toContain("pub fn read_across_modules_method()");
    expect(kotlin.methods[0]!.method).toEqual({
      language: "kotlin",
      packageName: "skirout.alpha.v1.input",
      symbol: "ReadAcrossModules",
    });
    expect(kotlinSource).toContain("val ReadAcrossModules:");
    expect(dart.methods[0]!.method).toEqual({
      language: "dart",
      importUri: "package:typewriter/skirout/alpha/v1/input.dart",
      symbol: "readAcrossModulesMethod",
      alias: "_lib_alpha_v1_input",
    });
    expect(dartSource).toContain("> readAcrossModulesMethod =");

    expect(rust.records.find((item) => item.key.endsWith(":Request"))!.fields)
      .toEqual([
        { sourceName: "class", targetName: "class" },
        { sourceName: "type", targetName: "type_" },
      ]);
    expect(
      kotlin.records.find((item) => item.key.endsWith(":Request"))!.fields,
    ).toEqual([
      { sourceName: "class", targetName: "class_" },
      { sourceName: "type", targetName: "type" },
    ]);
    expect(dart.records.find((item) => item.key.endsWith(":Request"))!.fields)
      .toEqual([
        { sourceName: "class", targetName: "class_" },
        { sourceName: "type", targetName: "type" },
      ]);
    expect(dart.records.find((item) => item.key.endsWith(":Request"))).toMatchObject({
      type: "_lib_alpha_v1_input.Request",
      binding: {
        language: "dart",
        importUri: "package:typewriter/skirout/alpha/v1/input.dart",
        symbol: "Request",
        alias: "_lib_alpha_v1_input",
      },
    });
    expect(dartSource).toContain("final class Request");

    expect(rust.methods[0]!.responseType).toContain(
      "crate::skirout::base::beta::v1::output::Response",
    );
    expect(kotlin.methods[0]!.responseType).toBe(
      "skirout.beta.v1.output.Response",
    );
    expect(dart.methods[0]!.responseType).toBe(
      "_lib_beta_v1_output.Response",
    );
    expect(dart.methods[0]!.imports).toContainEqual({
      importUri: "package:typewriter/skirout/alpha/v1/input.dart",
      alias: "_lib_alpha_v1_input",
    });
    expect(dart.methods[0]!.imports).toContainEqual({
      importUri: "package:typewriter/skirout/beta/v1/output.dart",
      alias: "_lib_beta_v1_output",
    });
  });

  test("does not claim enum fields and preserves generated collision suffixes", () => {
    const input = fixture();
    const bindings = rustBindings({ ...input, config: {} });
    const generated = rustGenerator
      .generateCode({ ...input, config: {} } as never)
      .files.map((file) => file.code)
      .join("\n");
    expect(
      bindings.records.find((item) => item.key.endsWith(":Collision"))!
        .fields,
    ).toEqual([]);
    expect(generated).toContain("FooBarConst");
    expect(generated).toContain("FooBarWrapper");
  });
});
