import "package:flutter_test/flutter_test.dart";
import "package:petitparser/petitparser.dart";
import "package:typewriter_panel/typewriter_panel.dart";

void main() {
  for (final key in ["#", "tag:"]) {
    group("key '$key' selector", () {
      final selector = KeyValueSelectorDefinition(id: "tag", key: key);
      final parser = selector.parser();

      final keySize = key.length;

      final selectors = [
        _Selector(raw: key),
        _Selector(
          raw: "${key}hello",
          value: "hello",
          valueRange: QueryRange(keySize, keySize + 5),
        ),
        for (final quote in quotes)
          _Selector(
            raw: "$key${quote}hello there$quote",
            value: "hello there",
            valueRange: QueryRange(keySize, keySize + 13),
          ),
      ];

      test("parses only key", () {
        final result = parser.parse(key);
        expect(result, isA<Success>());
        expect(result, parsedFull());
        expect(result.value.issues, isNotEmpty);
        expect(result.value.value, isNull);
        expect(result.value.valueRange, isNull);
      });
      test("parses key value pair", () {
        final result = parser.parse("${key}hello");
        expect(result, isA<Success>());
        expect(result, parsedFull());
        expect(result.value.issues, isEmpty);
        expect(result.value.value, "hello");
        expect(
          result.value.valueRange,
          equals(QueryRange(keySize, keySize + 5)),
        );
      });
      test("parses key with quoted value", () {
        for (final quote in quotes) {
          final result = parser.parse("$key${quote}hello$quote");
          expect(result, isA<Success>());
          expect(result, parsedFull());
          expect(result.value.issues, isEmpty);
          expect(result.value.value, "hello");
          expect(
            result.value.valueRange,
            equals(QueryRange(keySize, keySize + 7)),
          );
        }
      });
      test("parses symbol with half quoted label", () {
        final result = parser.parse("$key'hello there");
        expect(result, isA<Success>());
        expect(result, parsedFull());
        expect(result.value.issues, isNotEmpty);
        expect(result.value.value, "hello there");
        expect(
          result.value.valueRange,
          equals(QueryRange(keySize, keySize + 12)),
        );
      });
      test("parses symbol with only open quote", () {
        for (final quote in quotes) {
          final result = parser.parse("$key$quote");
          expect(result, isA<Success>());
          expect(result, parsedFull());
          expect(result.value.issues, isNotEmpty);
          expect(result.value.value, isNull);
          expect(
            result.value.valueRange,
            equals(QueryRange(keySize, keySize + 1)),
          );
        }
      });

      test("parses symbol when space between", () {
        final result = parser.parse("$key hello");
        expect(result, isA<Success>());
        expect(result, parsesUntil(keySize));
        expect(result.value.issues, isNotEmpty);
        expect(result.value.value, isNull);
        expect(result.value.valueRange, isNull);
      });

      test("fails parsing when any other char than symbol starts", () {
        for (final char
            in r"abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ\/_-$%&*@~"
                .split("")) {
          for (final selector in selectors) {
            final result = parser.parse("$char$selector");
            expect(result, isA<Failure>());
            expect(result, parsesUntil(0));
          }
        }
      });

      test("parses only selector even when things come after", () {
        for (final after in ["", "hello"]) {
          for (final selector in selectors) {
            final result = parser.parse("$selector $after");
            expect(result, isA<Success>());
            expect(result, parsesUntil(selector.raw.length));
            expect(result.value.value, selector.value);
            expect(result.value.valueRange, selector.valueRange);
          }
        }
      });

      test("only parses first selector", () {
        for (final selector in selectors) {
          final result = parser.parse("$selector $selector");
          expect(result, isA<Success>());
          expect(result, parsesUntil(selector.raw.length));
          expect(result.value.value, selector.value);
          expect(result.value.valueRange, selector.valueRange);
        }
      });

      test("parses selector from cursor position", () {
        for (final selector in selectors) {
          final result = parser.parse("hello $selector", start: 6);
          expect(result, isA<Success>());
          expect(result, parsesUntil(6 + selector.raw.length));
          expect(result.value.value, selector.value);
          expect(
            result.value.valueRange,
            selector.valueRange != null ? selector.valueRange! + 6 : null,
          );
        }
      });
    });
  }
}

class _Selector {
  const _Selector({required this.raw, this.value, this.valueRange});
  final String raw;
  final String? value;
  final QueryRange? valueRange;

  @override
  String toString() => raw;
}

Matcher parsedFull() => _ParsesFull();

class _ParsesFull extends Matcher {
  @override
  Description describe(Description description) {
    return description.add("parses full input");
  }

  @override
  bool matches(dynamic item, Map<dynamic, dynamic> matchState) {
    if (item is! Result) {
      return false;
    }

    return item.buffer.length == item.position;
  }

  @override
  Description describeMismatch(
    dynamic item,
    Description mismatchDescription,
    Map<dynamic, dynamic> matchState,
    bool verbose,
  ) {
    if (item is! Result) {
      return mismatchDescription.add(" is not a Result");
    }

    return mismatchDescription
        .add(item.buffer.substring(0, item.position))
        .add("|")
        .add(item.buffer.substring(item.position))
        .add(" [${item.position}]");
  }
}

Matcher parsesUntil(int position) => _ParsesUntil(position);

class _ParsesUntil extends Matcher {
  _ParsesUntil(this.position);

  final int position;

  @override
  Description describe(Description description) {
    return description.add("parses until position $position");
  }

  @override
  bool matches(dynamic item, Map<dynamic, dynamic> matchState) {
    if (item is! Result) {
      return false;
    }

    return item.position == position;
  }

  @override
  Description describeMismatch(
    dynamic item,
    Description mismatchDescription,
    Map<dynamic, dynamic> matchState,
    bool verbose,
  ) {
    if (item is! Result) {
      return mismatchDescription.add(" is not a Result");
    }

    return mismatchDescription
        .add(item.buffer.substring(0, item.position))
        .add("|")
        .add(item.buffer.substring(item.position))
        .add(" [${item.position}]")
        .add(" != $position");
  }
}
