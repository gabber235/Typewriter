import { describe, expect, test } from "bun:test";

import { generatorFor } from "../src/routes/index.js";
import { loadSkirInput, MANIFEST_PATH } from "./support.js";

describe("generator entry points", () => {
  test("the config takes only the manifest and the Dart import prefix", () => {
    const { configType } = generatorFor("rust");
    expect(configType.safeParse({ manifest: MANIFEST_PATH }).success).toBe(true);
    expect(configType.safeParse({ manifest: MANIFEST_PATH, target: "rust" }).success).toBe(false);
    expect(configType.safeParse({ manifest: MANIFEST_PATH, executable: "generator" }).success).toBe(false);
  });

  test("the Dart target requires the import prefix", async () => {
    const input = await loadSkirInput({ dartImportUriPrefix: undefined });
    expect(() => generatorFor("dart").generateCode(input)).toThrow("importUriPrefix");
    expect(generatorFor("kotlin").generateCode(input).files.length).toBeGreaterThan(0);
  });
});
