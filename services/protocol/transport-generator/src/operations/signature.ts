/**
 * The closed signature vocabulary of operations.yaml. Each word parses into one {@link Signature}
 * node; resolve.ts then checks where each node may appear and what it names.
 */

/** Catalog scalar words. A parameter accepts any width of its numeric family. */
export const SCALARS = [
  "text",
  "boolean",
  "int32",
  "integer",
  "float",
  "decimal",
  "bytes",
  "duration",
  "timestamp",
  "resource_id",
] as const;
export type Scalar = (typeof SCALARS)[number];

/** A parsed signature word. */
export type Signature =
  | { readonly kind: "scalar"; readonly scalar: Scalar }
  /** An enum, record or read model of the manifest, told apart during resolution. */
  | { readonly kind: "named"; readonly name: string }
  | { readonly kind: "variable"; readonly name: string }
  | { readonly kind: "nullable"; readonly value: Signature }
  | {
      readonly kind:
        | "list"
        | "set"
        | "items"
        | "link"
        | "partial"
        | "located"
        | "maybe"
        | "comparator"
        | "field_of"
        | "representation";
      readonly value: Signature;
    }
  | { readonly kind: "map" | "entry"; readonly key: Signature; readonly value: Signature }
  | { readonly kind: "each" | "apply"; readonly input: Signature; readonly output: Signature }
  | { readonly kind: "step"; readonly accumulator: Signature; readonly item: Signature }
  | { readonly kind: "field_type"; readonly record: Signature; readonly field: string };

/** A parameter after parsing: `name: word`, `name: word...` or `name: enum = case`. */
export interface ParsedParameter {
  readonly name: string;
  readonly type: Signature;
  readonly variadic: boolean;
  readonly defaultCase?: string;
}

const UNARY = new Set([
  "list",
  "set",
  "items",
  "link",
  "partial",
  "located",
  "maybe",
  "comparator",
  "field_of",
  "representation",
]);
const BINARY = new Set(["map", "entry", "each", "apply", "step", "field_type"]);

/** Parses one parameter slot value such as `N...` or `rounding_mode = nearest_ties_to_even`. */
export function parseParameter(name: string, word: string): ParsedParameter {
  const [type, defaultCase, ...extra] = word.split("=").map((part) => part.trim());
  if (extra.length > 0 || type === undefined || type === "") {
    throw new Error(`invalid parameter ${JSON.stringify(word)}`);
  }
  if (defaultCase !== undefined && !/^[a-z][a-z0-9_]*$/u.test(defaultCase)) {
    throw new Error(`invalid default case ${JSON.stringify(defaultCase)}`);
  }
  const variadic = type.endsWith("...");
  return {
    name,
    type: parseSignature(variadic ? type.slice(0, -3) : type),
    variadic,
    ...(defaultCase === undefined ? {} : { defaultCase }),
  };
}

/** Parses a signature word such as `map<K, list<T>>` or `regex_match?`. */
export function parseSignature(word: string): Signature {
  const parser = new Parser(word);
  const signature = parser.signature();
  parser.end();
  return signature;
}

class Parser {
  private position = 0;

  constructor(private readonly source: string) {}

  signature(): Signature {
    const name = this.identifier();
    let signature: Signature;
    if (this.peek() === "<") {
      this.position++;
      const first = this.signatureOrField();
      if (UNARY.has(name)) {
        signature = { kind: name, value: first } as Signature;
      } else if (BINARY.has(name)) {
        this.expect(",");
        if (name === "field_type") {
          signature = { kind: "field_type", record: first, field: this.identifier() };
        } else {
          const second = this.signature();
          signature =
            name === "step"
              ? { kind: "step", accumulator: first, item: second }
              : name === "each" || name === "apply"
                ? { kind: name, input: first, output: second }
                : { kind: name as "map" | "entry", key: first, value: second };
        }
      } else {
        throw new Error(`unknown signature constructor ${name}`);
      }
      this.expect(">");
    } else if (/^[A-Z]$/u.test(name)) {
      signature = { kind: "variable", name };
    } else if ((SCALARS as readonly string[]).includes(name)) {
      signature = { kind: "scalar", scalar: name as Scalar };
    } else if (UNARY.has(name) || BINARY.has(name)) {
      throw new Error(`${name} needs type arguments`);
    } else {
      signature = { kind: "named", name };
    }
    if (this.peek() === "?") {
      this.position++;
      signature = { kind: "nullable", value: signature };
    }
    return signature;
  }

  end(): void {
    this.skipSpace();
    if (this.position !== this.source.length) {
      throw new Error(`unexpected ${JSON.stringify(this.source.slice(this.position))}`);
    }
  }

  private signatureOrField(): Signature {
    return this.signature();
  }

  private identifier(): string {
    this.skipSpace();
    const match = /^[A-Za-z][A-Za-z0-9_]*/u.exec(this.source.slice(this.position));
    if (!match) {
      throw new Error(`expected a signature word at ${JSON.stringify(this.source.slice(this.position))}`);
    }
    this.position += match[0].length;
    return match[0];
  }

  private expect(token: string): void {
    this.skipSpace();
    if (!this.source.startsWith(token, this.position)) {
      throw new Error(`expected ${token} in ${JSON.stringify(this.source)}`);
    }
    this.position += token.length;
  }

  private peek(): string | undefined {
    this.skipSpace();
    return this.source[this.position];
  }

  private skipSpace(): void {
    while (this.source[this.position] === " ") this.position++;
  }
}

/** Formats a signature the way the manifest spells it, for messages and generated docs. */
export function signatureText(signature: Signature): string {
  switch (signature.kind) {
    case "scalar":
      return signature.scalar;
    case "named":
    case "variable":
      return signature.name;
    case "nullable":
      return `${signatureText(signature.value)}?`;
    case "map":
    case "entry":
      return `${signature.kind}<${signatureText(signature.key)}, ${signatureText(signature.value)}>`;
    case "each":
    case "apply":
      return `${signature.kind}<${signatureText(signature.input)}, ${signatureText(signature.output)}>`;
    case "step":
      return `step<${signatureText(signature.accumulator)}, ${signatureText(signature.item)}>`;
    case "field_type":
      return `field_type<${signatureText(signature.record)}, ${signature.field}>`;
    default:
      return `${signature.kind}<${signatureText(signature.value)}>`;
  }
}
