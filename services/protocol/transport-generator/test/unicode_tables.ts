import { writeFileSync } from "node:fs";

import { emitDartUnicodeTables, emitKotlinUnicodeTables, unicodeTables } from "../src/operations/unicode.js";
import { repository } from "./support.js";

/**
 * The pinned Unicode tables and the files they generate. Run this module with
 * `bun services/protocol/transport-generator/test/unicode_tables.ts` to rewrite the committed files
 * after a generator or release change.
 */

/** The pinned Unicode release. */
export const UNICODE_RELEASE = "17.0.0";

/** The directory holding one directory of character data per pinned release. */
export const UNICODE_ROOT = repository("services/protocol/unicode");

/** The generated tables, path by path from the repository root. */
export function generatedUnicodeFiles(): Map<string, string> {
  const tables = unicodeTables(UNICODE_RELEASE, UNICODE_ROOT);
  return new Map([
    [
      "services/sdk/typewriter-api/src/main/skirout/com/typewritermc/expression/operations/PortableUnicodeTables.kt",
      emitKotlinUnicodeTables(tables),
    ],
    ["panel/lib/infrastructure/protocols/skir/operations/portable_unicode_tables.dart", emitDartUnicodeTables(tables)],
  ]);
}

if (import.meta.main) {
  for (const [path, content] of generatedUnicodeFiles()) {
    writeFileSync(repository(path), content);
    console.log(`wrote ${path}`);
  }
}
