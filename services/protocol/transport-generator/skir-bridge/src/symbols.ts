import type {
  CodeGenerator,
  Method,
  RecordLocation,
  ResolvedType,
  Token,
} from "skir-internal";

type Source = { module: string; line: number; column: number };
type TypeDto =
  | { kind: "primitive"; primitive: string }
  | { kind: "record"; key: string }
  | { kind: "array"; item: TypeDto }
  | { kind: "optional"; other: TypeDto };

export type RequestedSymbols = {
  methods: ReadonlyArray<{ module: string; name: string }>;
  records: ReadonlyArray<{
    module: string;
    path: ReadonlyArray<string>;
  }>;
};

const source = (token: Token): Source => ({
  module: token.line.modulePath,
  line: token.line.lineNumber + 1,
  column: token.colNumber + 1,
});

export function exportCanonicalSymbols(
  input: CodeGenerator.Input<unknown>,
  requested: RequestedSymbols,
) {
  const selectedMethods: Array<{ module: string; method: Method }> = [];
  const selectedRecords = new Map<string, RecordLocation>();
  const pending: string[] = [];

  function exportType(resolvedType: ResolvedType): TypeDto {
    switch (resolvedType.kind) {
      case "primitive":
        return { kind: "primitive", primitive: resolvedType.primitive };
      case "record":
        pending.push(resolvedType.key);
        return { kind: "record", key: resolvedType.key };
      case "array":
        return { kind: "array", item: exportType(resolvedType.item) };
      case "optional":
        return { kind: "optional", other: exportType(resolvedType.other) };
    }
  }

  for (const reference of requested.methods) {
    const module = input.modules.find(
      (candidate) => candidate.path === reference.module,
    );
    const method = module?.methods.find(
      (candidate) => candidate.name.text === reference.name,
    );
    if (!method?.requestType || !method.responseType) {
      throw new Error(
        `Unresolved requested method ${reference.module}:${reference.name}`,
      );
    }
    selectedMethods.push({ module: reference.module, method });
  }

  for (const reference of requested.records) {
    const module = input.modules.find(
      (candidate) => candidate.path === reference.module,
    );
    const matches =
      module?.records.filter(
        (location) =>
          location.recordAncestors
            .map((record) => record.name.text)
            .join(".") === reference.path.join("."),
      ) ?? [];
    if (matches.length !== 1) {
      throw new Error(
        `Unknown or ambiguous requested record ${reference.module}:${reference.path.join(".")}`,
      );
    }
    pending.push(matches[0]!.record.key);
  }

  const methods = selectedMethods.map(({ module, method }) => ({
    module,
    name: method.name.text,
    number: method.number,
    request: exportType(method.requestType!),
    response: exportType(method.responseType!),
    source: source(method.name),
  }));
  const records = [];
  while (pending.length > 0) {
    const key = pending.pop()!;
    if (selectedRecords.has(key)) {
      continue;
    }
    const location = input.recordMap.get(key);
    if (!location) {
      throw new Error(`Compiler record map lacks ${key}`);
    }
    selectedRecords.set(key, location);
    records.push({
      key,
      module: location.modulePath,
      path: location.recordAncestors.map((record) => record.name.text),
      kind: location.record.recordType,
      declarationNumber: location.record.recordNumber,
      source: source(location.record.name),
      fields: location.record.fields.map((field) => ({
        name: field.name.text,
        number: field.number,
        type: field.type ? exportType(field.type) : null,
        source: source(field.name),
      })),
    });
  }

  return {
    methods: methods.sort((left, right) =>
      (left.module + ":" + left.name).localeCompare(
        right.module + ":" + right.name,
      ),
    ),
    records: records.sort((left, right) => left.key.localeCompare(right.key)),
  };
}
