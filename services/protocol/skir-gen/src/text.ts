/**
 * Source text helpers shared by the emitters. They spell manifest identifiers, never Skir generated
 * names: those come from the generator symbol providers in symbols.ts.
 */

/** Joins `snake_case` parts as `lowerCamel`, keeping the first part unchanged. */
export function lowerCamel(value: string): string {
  const [first = "", ...rest] = value.split("_");
  return first + rest.map(capitalize).join("");
}

/** Joins the non empty `snake_case` parts as `UpperCamel`. */
export function upperCamel(value: string): string {
  return value
    .split("_")
    .filter((part) => part.length > 0)
    .map(capitalize)
    .join("");
}

function capitalize(value: string): string {
  return value.charAt(0).toUpperCase() + value.slice(1);
}

/** Quotes a string as a double quoted literal that Kotlin, Dart and Rust read back unchanged. */
export function quoted(value: string, dollar: "plain" | "escaped" = "plain"): string {
  let output = '"';
  for (const character of value) {
    switch (character) {
      case "\\":
        output += "\\\\";
        break;
      case '"':
        output += '\\"';
        break;
      case "\n":
        output += "\\n";
        break;
      case "$":
        output += dollar === "escaped" ? "\\$" : "$";
        break;
      default:
        output += character;
    }
  }
  return output + '"';
}

/** Marks a requested empty line in a {@link Lines} sequence. */
export const BLANK: unique symbol = Symbol("blank");

/** Source lines with their indentation; {@link BLANK} requests an empty line. */
export type Lines = ReadonlyArray<string | typeof BLANK>;

/** Indents every line by `depth` levels of four spaces. */
export function indent(lines: Lines, depth = 1): Lines {
  const prefix = "    ".repeat(depth);
  return lines.map((line) => (line === BLANK || line === "" ? line : prefix + line));
}

/** Splits template text into lines; empty lines become {@link BLANK} requests. */
export function lines(text: string): Lines {
  return text.split("\n").map((line) => (line === "" ? BLANK : line));
}

/** Separates groups of lines with one requested empty line each. */
export function separated(groups: ReadonlyArray<Lines>): Lines {
  return groups.flatMap((group, index) => (index === 0 ? group : [BLANK, ...group]));
}

/**
 * Renders lines with a trailing newline. A requested empty line survives only between two lines of
 * equal indentation, so it never opens or closes a block and repeated requests collapse to one.
 */
export function render(source: Lines): string {
  const output: string[] = [];
  let pending = false;
  for (const line of source) {
    if (line === BLANK || line === "") {
      pending = output.length > 0;
      continue;
    }
    if (pending && indentation(line) === indentation(output.at(-1)!)) {
      output.push("");
    }
    pending = false;
    output.push(line);
  }
  return output.map((line) => line + "\n").join("");
}

function indentation(line: string): number {
  return line.length - line.trimStart().length;
}
