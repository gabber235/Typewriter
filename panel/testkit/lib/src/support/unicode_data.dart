/// Readers for the pinned Unicode data files under
/// `services/protocol/unicode/<release>`, which the portable text kernels
/// conform to.
library;

import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";

/// The lines of a file in the pinned Unicode release directory, read from
/// the panel package.
Future<List<String>> unicodeLines(String name) => File(
  "../services/protocol/unicode/${skir.PortableUnicodeTables.release}/$name",
).readAsLines();

/// The data lines of a semicolon separated Unicode data file, with comments
/// removed and fields trimmed.
Future<List<List<String>>> unicodeRecords(String name) async => [
  for (final line in await unicodeLines(name))
    if (line.split("#").first.trim() case final data when data.isNotEmpty)
      data.split(";").map((field) => field.trim()).toList(),
];

/// The text a data file field of space separated hex code points spells.
String unicodeCodePoints(String field) => String.fromCharCodes(
  field.trim().split(" ").map((code) => int.parse(code, radix: 16)),
);

/// [codePoint] as the data files write it: upper case hex, at least four
/// digits.
String unicodeHex(int codePoint) =>
    codePoint.toRadixString(16).toUpperCase().padLeft(4, "0");

/// The code points of [value] as space separated [unicodeHex].
String unicodeHexString(String value) => value.runes.map(unicodeHex).join(" ");

/// Normalizes each of [sources] to the four UAX 15 forms and adds a line to
/// [failures], named by [label], for every form that differs from [nfc],
/// [nfd], [nfkc] or [nfkd].
void checkNormalizationForms(
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
      "NFC": (
        portableNormalize(source, compatibility: false, compose: true),
        nfc,
      ),
      "NFD": (
        portableNormalize(source, compatibility: false, compose: false),
        nfd,
      ),
      "NFKC": (
        portableNormalize(source, compatibility: true, compose: true),
        nfkc,
      ),
      "NFKD": (
        portableNormalize(source, compatibility: true, compose: false),
        nfkd,
      ),
    };
    for (final MapEntry(key: form, value: (actual, expected))
        in forms.entries) {
      if (actual != expected) {
        failures.add(
          "$label: $form(${unicodeHexString(source)}) was "
          "${unicodeHexString(actual)}",
        );
      }
    }
  }
}
