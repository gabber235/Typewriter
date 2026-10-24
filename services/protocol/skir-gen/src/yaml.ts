import { isNode, LineCounter, parseDocument, type Document } from "yaml";
import type { z } from "zod";

/** A manifest that failed YAML parsing or admission; the message names the file, YAML path and line. */
export class ManifestError extends Error {
  override readonly name = "ManifestError";
}

/** A parsed manifest document together with a way to point admission errors at its source. */
export interface YamlManifest<T> {
  readonly data: T;
  /** Formats `file:line:col: path: message` for a later admission error at `path`. */
  error(path: ReadonlyArray<string | number>, message: string): ManifestError;
}

/**
 * Parses a YAML manifest and admits it with `schema`. Duplicate keys and schema issues fail with
 * every issue's file, YAML path such as `routes[3].flow.kind` and line.
 */
export function parseYamlManifest<T>(
  source: string,
  file: string,
  schema: z.ZodType<T>,
): YamlManifest<T> {
  const lineCounter = new LineCounter();
  const document = parseDocument(source, { lineCounter, uniqueKeys: true });
  const [syntaxError] = document.errors;
  if (syntaxError) {
    throw new ManifestError(`${file}: ${syntaxError.message}`);
  }
  const error = (path: ReadonlyArray<string | number>, message: string) =>
    new ManifestError(`${file}${location(document, lineCounter, path)}: ${yamlPath(path)}: ${message}`);
  const result = schema.safeParse(document.toJS());
  if (!result.success) {
    throw new ManifestError(
      result.error.issues
        .map((issue) => error(documentPath(issue.path), issue.message).message)
        .join("\n"),
    );
  }
  return { data: result.data, error };
}

/** Formats a document path as `routes[3].flow.kind`. */
export function yamlPath(path: ReadonlyArray<string | number>): string {
  return path
    .map((key, index) => (typeof key === "number" ? `[${key}]` : index === 0 ? key : `.${key}`))
    .join("");
}

/** The document keys of a Zod issue path, which Zod types as property keys; a symbol names no document node. */
function documentPath(path: ReadonlyArray<PropertyKey>): ReadonlyArray<string | number> {
  return path.filter((key): key is string | number => typeof key !== "symbol");
}

function location(
  document: Document,
  lineCounter: LineCounter,
  path: ReadonlyArray<string | number>,
): string {
  for (let length = path.length; length >= 0; length--) {
    const node = document.getIn(path.slice(0, length), true);
    if (isNode(node) && node.range) {
      const { line, col } = lineCounter.linePos(node.range[0]);
      return `:${line}:${col}`;
    }
  }
  return "";
}
