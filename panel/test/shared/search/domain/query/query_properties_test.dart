import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/testing.dart";

/// Properties of the search query over generated input.
///
/// Each property runs a fixed number of iterations from a fixed seed, so a
/// failure names the seed and the input that reproduces it.
void main() {
  const selectors = <QuerySelectorDefinition>[
    KeyValueSelectorDefinition(id: "tag", key: "#"),
    KeyValueSelectorDefinition(id: "title", key: "title:"),
    KeyValueSelectorDefinition(
      id: "status",
      key: "status:",
      value: QuerySelectorValue.enumValue(["open", "closed", "draft"]),
    ),
    KeyValueSelectorDefinition(id: "exact", key: "exact:", caseSensitive: true),
    KeyValueSelectorDefinition(
      id: "id",
      key: "id:",
      multiplicity: QueryMultiplicity.single,
    ),
    KeyValueSelectorDefinition(
      id: "source",
      key: "src:",
      value: QuerySelectorValue.sourceBacked(),
    ),
  ];
  final engine = QueryEngine(selectors);
  final suggestions = QuerySuggestionEngine(selectors);

  test("any typed query parses, suggests and searches without failing", () {
    final generator = Generator(20261027);
    for (var iteration = 0; iteration < 1500; iteration++) {
      final input = queryNoise(generator);
      final reason = "seed ${generator.seed}, iteration $iteration: '$input'";

      final search = sourceQueryContext(input, selectors);
      expect(search, isNotNull, reason: reason);

      for (final cursor in {
        0,
        input.length,
        generator.integer(input.length + 3),
      }) {
        final result = engine.parse(input, cursorOffset: cursor);
        final offered = suggestions.suggest(
          result,
          dynamicValues: const ["main quest", "side quest"],
        );
        result.completionRequest(selectors);

        final ranges = [
          for (final token in result.tokens) token.range,
          for (final issue in result.issues) ?issue.range,
          ?result.cursorContext?.activeRange,
          for (final suggestion in offered) suggestion.replaceRange,
        ];
        for (final range in ranges) {
          expect(
            range.start >= 0 &&
                range.start <= range.end &&
                range.end <= input.length,
            isTrue,
            reason: "$reason at cursor $cursor: $range",
          );
        }
      }
    }
  });

  test(
    "redundant whitespace and parentheses never change what is searched",
    () {
      final generator = Generator(73);
      for (var iteration = 0; iteration < 600; iteration++) {
        final query = WellFormedQuery.generate(generator);
        final canonical = query.render(generator, spacing: QuerySpacing.single);
        final expected = sourceQueryContext(canonical, selectors);
        final expectedIssues = issueKinds(engine.parse(canonical));

        final variants = [
          query.render(generator, spacing: QuerySpacing.none),
          query.render(generator, spacing: QuerySpacing.wide),
          query.render(
            generator,
            spacing: QuerySpacing.single,
            parentheses: 0.4,
          ),
          query.render(generator, spacing: QuerySpacing.wide, parentheses: 0.4),
        ];
        for (final variant in variants) {
          final reason =
              "seed ${generator.seed}, iteration $iteration: "
              "'$variant' against '$canonical'";
          expect(
            sourceQueryContext(variant, selectors),
            expected,
            reason: reason,
          );
          expect(
            issueKinds(engine.parse(variant)),
            expectedIssues,
            reason: reason,
          );
        }
      }
    },
  );
}
