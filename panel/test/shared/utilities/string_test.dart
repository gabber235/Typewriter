import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/typewriter_panel.dart";

void main() {
  group("StringX", () {
    group("titleCase", () {
      test("converts normal string to title case", () {
        expect("hello world".titleCase(), "Hello World");
      });

      test("returns empty string unchanged", () {
        expect("".titleCase(), "");
      });

      test("handles single word", () {
        expect("hello".titleCase(), "Hello");
      });

      test("handles already title case", () {
        expect("Hello World".titleCase(), "Hello World");
      });
    });

    group("snakeCase", () {
      test("converts camelCase to snake_case", () {
        expect("helloWorld".snakeCase(), "hello_world");
      });

      test("converts PascalCase to snake_case", () {
        expect("HelloWorld".snakeCase(), "hello_world");
      });

      test("returns empty string unchanged", () {
        expect("".snakeCase(), "");
      });

      test("handles already snake_case", () {
        expect("hello_world".snakeCase(), "hello_world");
      });
    });

    group("formatted", () {
      test("splits on dots, title cases, and joins with pipe", () {
        expect("hello.world".formatted, "Hello | World");
      });

      test("returns empty string unchanged", () {
        expect("".formatted, "");
      });

      test("handles single segment", () {
        expect("hello".formatted, "Hello");
      });

      test("handles multiple segments", () {
        expect("one.two.three".formatted, "One | Two | Three");
      });
    });

    group("asInt", () {
      test("parses valid integer string", () {
        expect("42".asInt, 42);
      });

      test("parses negative integer", () {
        expect("-10".asInt, -10);
      });

      test("returns null for invalid string", () {
        expect("abc".asInt, isNull);
      });

      test("returns null for empty string", () {
        expect("".asInt, isNull);
      });

      test("returns null for floating point", () {
        expect("3.14".asInt, isNull);
      });
    });

    group("nullIfEmpty", () {
      test("returns null for empty string", () {
        expect("".nullIfEmpty, isNull);
      });

      test("returns string for non-empty", () {
        expect("hello".nullIfEmpty, "hello");
      });

      test("returns whitespace string unchanged", () {
        expect(" ".nullIfEmpty, " ");
      });
    });

    group("join", () {
      test("returns other when base is empty", () {
        expect("".join("world"), "world");
      });

      test("joins with dot separator", () {
        expect("hello".join("world"), "hello.world");
      });

      test("handles empty other", () {
        expect("hello".join(""), "hello.");
      });
    });
  });
}
