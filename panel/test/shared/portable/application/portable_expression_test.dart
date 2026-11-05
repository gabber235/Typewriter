import "dart:convert";
import "dart:io";

import "package:flutter_test/flutter_test.dart";
import "package:typewriter_testkit/testing.dart";

/// Runs every case of the shared operation fixture
/// (`skir-src/editor/v1/fixtures/operations/*.json`, format in the README
/// there). The panel runs every case, rule and panel profile alike, and
/// compares the outcome and the reads of each in order; `check` belongs to
/// the Kotlin checker and is ignored here.
void main() {
  final directory = Directory("../skir-src/editor/v1/fixtures/operations");
  final files =
      directory
          .listSync()
          .whereType<File>()
          .where((file) => file.path.endsWith(".json"))
          .toList()
        ..sort((left, right) => left.path.compareTo(right.path));
  final ids = <String>{};
  for (final file in files) {
    final document =
        jsonDecode(file.readAsStringSync()) as Map<String, Object?>;
    group(file.uri.pathSegments.last, () {
      test("holds only cases", () => expect(document.keys, ["cases"]));
      for (final fixture
          in (document["cases"]! as List<Object?>)
              .cast<Map<String, Object?>>()) {
        final id = fixture["id"]! as String;
        final unique = ids.add(id);
        test(id, () {
          expect(unique, isTrue, reason: "case ids are unique across files");
          runExpressionFixtureCase(fixture);
        });
      }
    });
  }
}
