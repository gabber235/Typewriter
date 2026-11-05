import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/unicode.dart";

void main() {
  test("case mapping applies full untailored mappings with Final_Sigma", () {
    expect(portableUpper("Straße"), "STRASSE");
    expect(portableLower("ΟΔΟΣ"), "οδος");
    expect(portableLower("ΣΑ"), "σα");
    expect(portableLower("ΆΣ."), "άς.");
    expect(portableLower("ΑΣ́Β"), "ασ́β");
    expect(portableLower("İ"), "i̇");
    expect(portableUpper("i"), "I");
    expect(portableUpper("ŉ"), "ʼN");
    expect(portableLower("\u{10400}"), "\u{10428}");
    expect(portableUpper("\uD800x"), "\uD800X");
  });

  test("title case starts each white space separated word with its titlecase "
      "mapping", () {
    expect(portableTitle("ǆemal"), "ǅemal");
    expect(portableTitle("hello wORLD"), "Hello World");
    expect(portableTitle("ΟΔΟΣ ΑΒ"), "Οδος Αβ");
    expect(portableTitle("ﬂour\u3000ﬁx"), "Flour\u3000Fix");
    expect(portableTitle("a-b c"), "A-b C");
  });

  test("case folding applies the full C and F foldings", () {
    expect(portableFoldCase("Straße"), "strasse");
    expect(portableFoldCase("ΣΑΣ"), "σασ");
    expect(portableFoldCase("İ"), "i̇");
    expect(portableFoldCase("ẞ"), "ss");
  });

  test("normalization produces the four UAX 15 forms", () {
    expect(portableNormalize("Å", compatibility: false, compose: true), "Å");
    expect(portableNormalize("Å", compatibility: false, compose: false), "Å");
    expect(portableNormalize("ﬁ", compatibility: true, compose: true), "fi");
    expect(portableNormalize("ﬁ", compatibility: false, compose: true), "ﬁ");
    expect(portableNormalize("가", compatibility: false, compose: false), "가");
    expect(portableNormalize("각", compatibility: false, compose: true), "각");
    expect(portableNormalize("", compatibility: false, compose: true), "");
  });

  test("white space is the pinned White_Space property plus U+FEFF", () {
    expect(portableTrimStart("\u3000\uFEFFx"), "x");
    expect(portableTrimEnd("x\u0085"), "x");
    expect(portableTrimStart(" \tx "), "x ");
    expect(portableTrimEnd(" x\u2028\u00A0"), " x");
    expect(portableTrimEnd("x\u200B"), "x\u200B");
    expect(portableTrimStart(" \u{10400}"), "\u{10400}");
    expect(portableTrimEnd("\u{10400} "), "\u{10400}");
    expect(portableTrimEnd("\u3000"), "");
    expect(portableIsWhiteSpace(0x180E), isFalse);
    expect(portableIsWhiteSpace(0x1680), isTrue);
  });

  test(
    "every code point maps and folds as the pinned UnicodeData, SpecialCasing "
    "and CaseFolding files say",
    () async {
      final simple = <int, List<String>>{};
      for (final line in await unicodeLines("UnicodeData.txt")) {
        final fields = line.split(";");
        simple[int.parse(fields[0], radix: 16)] = [
          fields[12],
          fields[13],
          if (fields[14].isEmpty) fields[12] else fields[14],
        ];
      }
      final special = {
        for (final fields in await unicodeRecords("SpecialCasing.txt"))
          if (fields[4].isEmpty) int.parse(fields[0], radix: 16): fields,
      };
      final folding = {
        for (final fields in await unicodeRecords("CaseFolding.txt"))
          if (fields[1] == "C" || fields[1] == "F")
            int.parse(fields[0], radix: 16): fields[2],
      };

      final failures = <String>[];
      for (var codePoint = 0; codePoint <= 0x10FFFF; codePoint++) {
        if (codePoint >= 0xD800 && codePoint <= 0xDFFF) continue;
        final value = String.fromCharCode(codePoint);
        final self = unicodeHex(codePoint);
        final expected = {
          "upper": special[codePoint]?[3] ?? simple[codePoint]?[0],
          "lower": special[codePoint]?[1] ?? simple[codePoint]?[1],
          "title": special[codePoint]?[2] ?? simple[codePoint]?[2],
          "fold": folding[codePoint],
        };
        final actual = {
          "upper": portableUpper(value),
          "lower": portableLower(value),
          "title": portableTitle(value),
          "fold": portableFoldCase(value),
        };
        for (final MapEntry(key: operation, value: mapping)
            in expected.entries) {
          final want = unicodeCodePoints(
            mapping == null || mapping.isEmpty ? self : mapping,
          );
          if (actual[operation] != want) {
            failures.add(
              "$operation($self) was ${unicodeHexString(actual[operation]!)}",
            );
          }
        }
      }
      expect(failures.take(20), isEmpty);
    },
  );

  test(
    "normalization conforms to every line of the pinned NormalizationTest.txt",
    () async {
      final failures = <String>[];
      final listed = <int>{};
      var part = "";
      var lines = 0;
      for (final line in await unicodeLines("NormalizationTest.txt")) {
        final data = line.split("#").first.trim();
        if (data.isEmpty) continue;
        if (data.startsWith("@")) {
          part = data;
          continue;
        }
        lines++;
        final [source, nfc, nfd, nfkc, nfkd] = data
            .split(";")
            .take(5)
            .map(unicodeCodePoints)
            .toList();
        if (part == "@Part1") listed.add(source.runes.first);
        checkNormalizationForms(
          line,
          [source, nfc, nfd],
          nfc,
          nfd,
          nfkc,
          nfkd,
          failures,
        );
        checkNormalizationForms(
          line,
          [nfkc, nfkd],
          nfkc,
          nfkd,
          nfkc,
          nfkd,
          failures,
        );
      }
      for (var codePoint = 0; codePoint <= 0x10FFFF; codePoint++) {
        if (codePoint >= 0xD800 && codePoint <= 0xDFFF) continue;
        if (listed.contains(codePoint)) continue;
        final value = String.fromCharCode(codePoint);
        checkNormalizationForms(
          "unlisted U+${unicodeHex(codePoint)}",
          [value],
          value,
          value,
          value,
          value,
          failures,
        );
      }
      expect(lines, greaterThan(20000));
      expect(failures.take(20), isEmpty);
    },
  );
}
