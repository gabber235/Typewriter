import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";

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
    expect(portableTitle("ﬂour　ﬁx"), "Flour　Fix");
    expect(portableTitle("a-b c"), "A-b C");
  });

  test("case folding applies the full C and F foldings", () {
    expect(portableFoldCase("Straße"), "strasse");
    expect(portableFoldCase("ΣΑΣ"), "σασ");
    expect(portableFoldCase("İ"), "i̇");
    expect(portableFoldCase("ẞ"), "ss");
  });

  test("normalization produces the four UAX 15 forms", () {
    expect(_nfc("Å"), "Å");
    expect(_nfd("Å"), "Å");
    expect(_nfkc("ﬁ"), "fi");
    expect(_nfc("ﬁ"), "ﬁ");
    expect(_nfd("가"), "가");
    expect(_nfc("각"), "각");
    expect(_nfc(""), "");
  });

  test("white space is the pinned White_Space property plus U+FEFF", () {
    expect(portableTrimStart("　﻿x"), "x");
    expect(portableTrimEnd("x\u0085"), "x");
    expect(portableTrimStart(" \tx "), "x ");
    expect(portableTrimEnd(" x  "), " x");
    expect(portableTrimEnd("x​"), "x​");
    expect(portableTrimStart(" \u{10400}"), "\u{10400}");
    expect(portableTrimEnd("\u{10400} "), "\u{10400}");
    expect(portableTrimEnd("　"), "");
    expect(portableIsWhiteSpace(0x180E), isFalse);
    expect(portableIsWhiteSpace(0x1680), isTrue);
  });

  test(
    "every code point maps and folds as the pinned UnicodeData, SpecialCasing "
    "and CaseFolding files say",
    () async {
      final simple = <int, List<String>>{};
      for (final line in await _unicodeLines("UnicodeData.txt")) {
        final fields = line.split(";");
        simple[int.parse(fields[0], radix: 16)] = [
          fields[12],
          fields[13],
          if (fields[14].isEmpty) fields[12] else fields[14],
        ];
      }
      final special = {
        for (final fields in await _unicodeRecords("SpecialCasing.txt"))
          if (fields[4].isEmpty) int.parse(fields[0], radix: 16): fields,
      };
      final folding = {
        for (final fields in await _unicodeRecords("CaseFolding.txt"))
          if (fields[1] == "C" || fields[1] == "F")
            int.parse(fields[0], radix: 16): fields[2],
      };

      final failures = <String>[];
      for (var codePoint = 0; codePoint <= 0x10FFFF; codePoint++) {
        if (codePoint >= 0xD800 && codePoint <= 0xDFFF) continue;
        final value = String.fromCharCode(codePoint);
        final self = _hex(codePoint);
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
          final want = _codePoints(
            mapping == null || mapping.isEmpty ? self : mapping,
          );
          if (actual[operation] != want) {
            failures.add(
              "$operation($self) was ${_hexString(actual[operation]!)}",
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
      expect(skir.PortableUnicodeTables.release, "17.0.0");
      final failures = <String>[];
      final listed = <int>{};
      var part = "";
      var lines = 0;
      for (final line in await _unicodeLines("NormalizationTest.txt")) {
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
            .map(_codePoints)
            .toList();
        if (part == "@Part1") listed.add(source.runes.first);
        _checkForms(line, [source, nfc, nfd], nfc, nfd, nfkc, nfkd, failures);
        _checkForms(line, [nfkc, nfkd], nfkc, nfkd, nfkc, nfkd, failures);
      }
      for (var codePoint = 0; codePoint <= 0x10FFFF; codePoint++) {
        if (codePoint >= 0xD800 && codePoint <= 0xDFFF) continue;
        if (listed.contains(codePoint)) continue;
        final value = String.fromCharCode(codePoint);
        _checkForms(
          "unlisted U+${_hex(codePoint)}",
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

String _nfc(String value) =>
    portableNormalize(value, compatibility: false, compose: true);

String _nfd(String value) =>
    portableNormalize(value, compatibility: false, compose: false);

String _nfkc(String value) =>
    portableNormalize(value, compatibility: true, compose: true);

String _nfkd(String value) =>
    portableNormalize(value, compatibility: true, compose: false);

void _checkForms(
  String label,
  List<String> sources,
  String nfc,
  String nfd,
  String nfkc,
  String nfkd,
  List<String> failures,
) {
  for (final source in sources) {
    final forms = {
      "NFC": (_nfc(source), nfc),
      "NFD": (_nfd(source), nfd),
      "NFKC": (_nfkc(source), nfkc),
      "NFKD": (_nfkd(source), nfkd),
    };
    for (final MapEntry(key: form, value: (actual, expected))
        in forms.entries) {
      if (actual != expected) {
        failures.add(
          "$label: $form(${_hexString(source)}) was ${_hexString(actual)}",
        );
      }
    }
  }
}

/// The lines of a file in the pinned Unicode release directory.
Future<List<String>> _unicodeLines(String name) => File(
  "../services/protocol/unicode/${skir.PortableUnicodeTables.release}/$name",
).readAsLines();

/// The data lines of a semicolon separated Unicode data file, with comments
/// removed and fields trimmed.
Future<List<List<String>>> _unicodeRecords(String name) async => [
  for (final line in await _unicodeLines(name))
    if (line.split("#").first.trim() case final data when data.isNotEmpty)
      data.split(";").map((field) => field.trim()).toList(),
];

String _codePoints(String field) => String.fromCharCodes(
  field.trim().split(" ").map((code) => int.parse(code, radix: 16)),
);

String _hex(int codePoint) =>
    codePoint.toRadixString(16).toUpperCase().padLeft(4, "0");

String _hexString(String value) => value.runes.map(_hex).join(" ");
