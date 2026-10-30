import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/src/generators/generator.dart";

/// Arbitrary text built from the pieces of query syntax and the characters
/// most likely to confuse it.
String queryNoise(Generator generator) {
  const pieces = [
    "#", "title:", "status:", "exact:", "EXACT:", "src:", "id:", //
    "AND", "and", "OR", "or", "&&", "||", "&", "|", "NOT", "not", "!", //
    "(", ")", "\"", "'", ":", " ", "  ", "\t", "\n", //
    "a", "b", "open", "quest", "é", "\u{1F600}", "-", "1",
  ];
  return generator
      .list(generator.integer(14), (generator) => generator.pick(pieces))
      .join();
}

/// How the separators of a rendered query are spaced.
enum QuerySpacing {
  /// No whitespace where the grammar allows none, one space elsewhere.
  none,

  /// One space at every separator.
  single,

  /// Several spaces at every separator and around the whole query.
  wide,
}

/// A query whose structure is known: free words [before] and [after] one
/// generated selector expression. It renders in equivalent ways, with other spacing
/// and with redundant parentheses.
final class WellFormedQuery {
  WellFormedQuery._(this.before, this._expression, this.after);

  factory WellFormedQuery.generate(Generator generator) {
    List<String> words() => generator.list(generator.integer(3), (generator) {
      while (true) {
        final word = generator.word();
        if (!_operatorWords.contains(word)) return word;
      }
    });
    return WellFormedQuery._(words(), _Node.generate(generator, 3), words());
  }

  static const _operatorWords = {"and", "not"};

  final List<String> before;
  final _Node _expression;
  final List<String> after;

  /// Renders the query; [parentheses] is the chance that any expression node
  /// gets an extra pair of parentheses around it.
  String render(
    Generator generator, {
    required QuerySpacing spacing,
    double parentheses = 0,
  }) {
    String gap({required bool required}) => switch (spacing) {
      QuerySpacing.none => required ? " " : "",
      QuerySpacing.single => " ",
      QuerySpacing.wide => " " * generator.integer(5, min: 1),
    };
    final edge = spacing == QuerySpacing.wide ? " " * generator.integer(4) : "";
    final parts = [
      ...before,
      _expression.render(generator, gap, parentheses),
      ...after,
    ];
    return "$edge${parts.join(gap(required: true))}$edge";
  }
}

typedef _Gap = String Function({required bool required});

sealed class _Node {
  static _Node generate(Generator generator, int depth) {
    if (depth == 0 || generator.chance(0.35)) {
      return _Leaf(
        generator.pick([
          "#${generator.word()}",
          "title:${generator.word()}",
          "title:\"${generator.word()} ${generator.word()}\"",
          "title:'${generator.word()}'",
          "status:${generator.pick(["open", "closed", "draft"])}",
          "exact:${generator.word().titleCase()}",
          "src:${generator.word()}",
        ]),
      );
    }
    if (generator.chance(0.25)) {
      return _Not(
        generator.pick(["NOT", "not", "!"]),
        generate(generator, depth - 1),
      );
    }
    return _Binary(
      generator.pick(["AND", "and", "&&", "OR", "or", "||", ""]),
      generate(generator, depth - 1),
      generate(generator, depth - 1),
    );
  }

  /// Renders the node so the parser rebuilds exactly this tree: binary
  /// operands that are themselves binary always get parentheses.
  String render(Generator generator, _Gap gap, double parentheses) {
    final text = _render(generator, gap, parentheses);
    if (!generator.chance(parentheses)) return text;
    return "(${gap(required: false)}$text${gap(required: false)})";
  }

  String _render(Generator generator, _Gap gap, double parentheses);

  String _operand(Generator generator, _Gap gap, double parentheses) {
    final text = render(generator, gap, parentheses);
    if (this is! _Binary) return text;
    return "(${gap(required: false)}$text${gap(required: false)})";
  }
}

final class _Leaf extends _Node {
  _Leaf(this.text);

  final String text;

  @override
  String _render(Generator generator, _Gap gap, double parentheses) => text;
}

final class _Not extends _Node {
  _Not(this.operator, this.operand);

  final String operator;
  final _Node operand;

  @override
  String _render(Generator generator, _Gap gap, double parentheses) {
    final symbolic = operator == "!";
    return "$operator${gap(required: !symbolic)}"
        "${operand._operand(generator, gap, parentheses)}";
  }
}

final class _Binary extends _Node {
  _Binary(this.operator, this.left, this.right);

  final String operator;
  final _Node left;
  final _Node right;

  @override
  String _render(Generator generator, _Gap gap, double parentheses) {
    final leftText = left._operand(generator, gap, parentheses);
    final rightText = right._operand(generator, gap, parentheses);
    if (operator.isEmpty) return "$leftText${gap(required: true)}$rightText";
    final symbolic = !operator.contains(RegExp("[a-zA-Z]"));
    return "$leftText${gap(required: !symbolic)}$operator"
        "${gap(required: !symbolic)}$rightText";
  }
}
