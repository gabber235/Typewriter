import "dart:convert";
import "dart:io";

import "package:flutter_test/flutter_test.dart";
import "package:typewriter_testkit/testing.dart";

/// The panel evaluates every generated expression as the server does.
///
/// The SDK writes the corpus from a fixed seed with its own evaluator's
/// outcome as the expected result (`cargo xtask generate`, generator
/// `sdk-fixtures`). It is build output, so it is read from the SDK build
/// directory, never committed. A disagreement found here becomes a hand
/// written case in `skir-src/editor/v1/fixtures/operations`.
void main() {
  final corpus = File(
    "../services/sdk/typewriter-api/build/fixtures/expression_corpus.json",
  );
  if (!corpus.existsSync()) {
    test("the expression corpus exists", () {
      fail("${corpus.path} is missing; run `cargo xtask generate`");
    });
    return;
  }
  final document =
      jsonDecode(corpus.readAsStringSync()) as Map<String, Object?>;
  final cases = (document["cases"]! as List<Object?>)
      .cast<Map<String, Object?>>();
  test("the corpus holds generated cases", () {
    expect(cases, isNotEmpty);
  });
  for (final fixture in cases) {
    test("the panel evaluates ${fixture["id"]} as the server does", () {
      runExpressionFixtureCase(fixture);
    });
  }
}
