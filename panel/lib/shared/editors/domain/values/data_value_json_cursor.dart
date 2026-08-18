part of "data_value_json_converter.dart";

final class _JsonValue {
  const _JsonValue(this.value, {this.path = r"$"});

  static const _missing = Object();

  final Object? value;
  final String path;

  Map<String, Object?> object() {
    final source = value;
    if (source is! Map<Object?, Object?>) {
      throw invalid("an object");
    }

    final result = <String, Object?>{};
    var index = 0;
    for (final entry in source.entries) {
      final key = entry.key;
      if (key is! String) {
        throw _JsonValue(
          key,
          path: "$path.keys[$index]",
        ).invalid("a string object key");
      }
      result[key] = entry.value;
      index++;
    }
    return result;
  }

  List<Object?> list() {
    final source = value;
    if (source is! List<Object?>) {
      throw invalid("a list");
    }
    return source;
  }

  String string() {
    final source = value;
    if (source is! String) {
      throw invalid("a string");
    }
    return source;
  }

  bool boolean() {
    final source = value;
    if (source is! bool) {
      throw invalid("a boolean");
    }
    return source;
  }

  int integer() {
    final source = value;
    if (source is! int) {
      throw invalid("an integer");
    }
    return source;
  }

  num number() {
    final source = value;
    if (source is! num) {
      throw invalid("a number");
    }
    return source;
  }

  _JsonValue required(String key) {
    final source = object();
    return _JsonValue(
      source.containsKey(key) ? source[key] : _missing,
      path: _propertyPath(key),
    );
  }

  _JsonValue property(String key, Object? propertyValue) =>
      _JsonValue(propertyValue, path: _propertyPath(key));

  _JsonValue item(int index, Object? itemValue) =>
      _JsonValue(itemValue, path: "$path[$index]");

  FormatException invalid(String expected) => FormatException(
    "Expected $expected at $path, got ${_actualShape(value)}",
  );

  String _propertyPath(String key) {
    if (RegExp(r"^[A-Za-z_][A-Za-z0-9_]*$").hasMatch(key)) {
      return "$path.$key";
    }
    return "$path[${jsonEncode(key)}]";
  }

  static String _actualShape(Object? value) => switch (value) {
    _ when identical(value, _missing) => "missing",
    null => "null",
    String() => "a string",
    bool() => "a boolean",
    int() => "an integer",
    double() => "a number",
    List<Object?>() => "a list",
    Map<Object?, Object?>() => "an object",
    _ => "${value.runtimeType}",
  };
}
