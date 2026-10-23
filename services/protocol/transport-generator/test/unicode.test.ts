import { describe, expect, test } from "bun:test";
import { readFileSync } from "node:fs";

import {
  ALPHABET,
  emitDartUnicodeTables,
  emitKotlinUnicodeTables,
  unicodeTables,
} from "../src/operations/unicode.js";
import { repository } from "./support.js";
import { generatedUnicodeFiles, UNICODE_RELEASE, UNICODE_ROOT } from "./unicode_tables.js";

const TABLES = unicodeTables(UNICODE_RELEASE, UNICODE_ROOT);

describe("pinned Unicode tables", () => {
  test("case mappings are the untailored default ones with only the Final_Sigma condition", () => {
    expect([...TABLES.finalSigmaLower]).toEqual([[0x03a3, [0x03c2]]]);
    expect(TABLES.specialUpper.get(0x00df)).toEqual([0x0053, 0x0053]);
    expect(TABLES.specialTitle.get(0x00df)).toEqual([0x0053, 0x0073]);
    expect(TABLES.specialLower.get(0x0130)).toEqual([0x0069, 0x0307]);
    // Turkish, Azeri and Lithuanian tailorings leave I, J and i alone.
    for (const codePoint of [0x0049, 0x004a, 0x0069, 0x00cc]) {
      expect(TABLES.specialLower.has(codePoint) || TABLES.specialUpper.has(codePoint)).toBe(false);
    }
    expect(TABLES.simpleTitle.get(0x01c6)).toBe(0x01c5);
    expect(TABLES.simpleUpper.get(0x01c6)).toBe(0x01c4);
  });

  test("full case folding combines the C and F statuses only", () => {
    expect(TABLES.fullFold.get(0x00df)).toEqual([0x0073, 0x0073]);
    expect(TABLES.simpleFold.get(0x03a3)).toBe(0x03c3);
    expect(TABLES.simpleFold.get(0x03c2)).toBe(0x03c3);
    // Status T (Turkic) and S (simple alternative to F) are not part of full folding.
    expect(TABLES.simpleFold.get(0x0049)).toBe(0x0069);
    expect(TABLES.simpleFold.has(0x1e9e)).toBe(false);
    expect(TABLES.fullFold.get(0x1e9e)).toEqual([0x0073, 0x0073]);
  });

  test("white space is White_Space plus U+FEFF", () => {
    const contains = (codePoint: number) =>
      TABLES.whiteSpace.some((range) => range.start <= codePoint && codePoint <= range.end);
    for (const codePoint of [0x0009, 0x0020, 0x0085, 0x00a0, 0x1680, 0x2028, 0x3000, 0xfeff]) {
      expect(contains(codePoint)).toBe(true);
    }
    for (const codePoint of [0x180e, 0x200b, 0x0041]) expect(contains(codePoint)).toBe(false);
  });

  test("decompositions keep their tag and leave Hangul syllables to the algorithm", () => {
    expect(TABLES.decompositions.get(0x00c5)).toEqual({ compatibility: false, mapping: [0x0041, 0x030a] });
    expect(TABLES.decompositions.get(0x212b)).toEqual({ compatibility: false, mapping: [0x00c5] });
    expect(TABLES.decompositions.get(0xfb01)).toEqual({ compatibility: true, mapping: [0x0066, 0x0069] });
    expect(TABLES.decompositions.has(0xac00)).toBe(false);
    expect(TABLES.combiningClasses.get(0x0301)).toBe(230);
    expect(TABLES.combiningClasses.has(0x0041)).toBe(false);
  });

  test("primary composites apply every full composition exclusion", () => {
    const composites = new Set(TABLES.primaryComposites);
    expect(composites.has(0x00c5)).toBe(true);
    expect(composites.has(0x1e0a)).toBe(true);
    expect(composites.has(0x212b)).toBe(false); // singleton
    expect(composites.has(0x0958)).toBe(false); // CompositionExclusions.txt
    expect(composites.has(0x0344)).toBe(false); // non-starter decomposition
    expect(composites.has(0x0f73)).toBe(false); // non-starter decomposition
  });
});

describe("emitted Unicode tables", () => {
  test("are deterministic", () => {
    const again = unicodeTables(UNICODE_RELEASE, UNICODE_ROOT);
    expect(emitKotlinUnicodeTables(again)).toBe(emitKotlinUnicodeTables(TABLES));
    expect(emitDartUnicodeTables(again)).toBe(emitDartUnicodeTables(TABLES));
  });

  test("spell their data only in characters both languages read unescaped", () => {
    expect(ALPHABET).toHaveLength(91);
    expect(ALPHABET).not.toMatch(/["$\\]/);
    for (const content of [emitKotlinUnicodeTables(TABLES), emitDartUnicodeTables(TABLES)]) {
      expect(content).toStartWith(`// Generated from operations.yaml's pinned Unicode ${UNICODE_RELEASE} release`);
      expect(content).toContain("Do not edit.");
      for (const [, literal] of content.matchAll(/"([^"]*)"/g)) {
        for (const character of literal!) expect(ALPHABET.includes(character) || /[\w. ]/.test(character)).toBe(true);
        // A Kotlin class file constant holds at most 65535 bytes.
        expect(Buffer.byteLength(literal!, "utf8")).toBeLessThan(65535);
      }
    }
  });

  test("match the committed generated files", () => {
    for (const [path, content] of generatedUnicodeFiles()) {
      // Rewrite with `bun services/protocol/transport-generator/test/unicode_tables.ts`.
      expect(readFileSync(repository(path), "utf8")).toBe(content);
    }
  });
});
