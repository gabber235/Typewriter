import "package:typewriter_panel/shared/utilities/collection.dart";

extension MapX on Map<dynamic, dynamic> {
  /// Merges this map with [other] using "mask" semantics.
  ///
  /// Masking rules:
  /// - Keys are combined from both maps.
  /// - When a key exists in both:
  ///   - If both values are `Map`, they are recursively masked.
  ///   - If both values are `List`, they are masked element-wise using the list `mask` behavior.
  ///   - If both values have the same `runtimeType`, the value from [other] wins (override).
  ///   - If one value is `null` and the other is non-null, the non-null value wins.
  ///   - If values have incompatible types, the value from this (left/base) map is kept.
  /// - When a key exists in only one map, that value is kept as-is.
  ///
  /// When/why to use:
  /// - Apply user or environment overrides onto a default configuration without losing unspecified defaults.
  /// - Merge server-provided patches into local data while preserving the existing shape and types.
  /// - Combine nested structures (maps, lists, lists of maps) in a predictable way that prefers valid types.
  ///
  /// Examples
  /// Simple maps:
  /// ```dart
  /// final base = {'a': 1, 'b': 2};
  /// final patch = {'b': 3, 'c': 4};
  /// final merged = base.mask(patch);
  /// // { 'a': 1, 'b': 3, 'c': 4 }
  /// ```
  ///
  /// Nested maps:
  /// ```dart
  /// final base = {
  ///   'user': {'id': 1, 'name': 'base', 'flags': {'admin': false}},
  /// };
  /// final patch = {
  ///   'user': {'name': 'patch', 'flags': {'beta': true}},
  /// };
  /// final merged = base.mask(patch);
  /// // {
  /// //   'user': {'id': 1, 'name': 'patch', 'flags': {'admin': false, 'beta': true}}
  /// // }
  /// ```
  ///
  /// Lists of maps:
  /// ```dart
  /// final base = {
  ///   'items': [
  ///     {'id': 1, 'name': 'a'},
  ///     {'id': 2, 'name': 'b'},
  ///   ],
  /// };
  /// final patch = {
  ///   'items': [
  ///     {'id': 1, 'name': 'a*'}, // same position -> masked with element
  ///     {'id': 2, 'extra': true},
  ///   ],
  /// };
  /// final merged = base.mask(patch);
  /// // {
  /// //   'items': [
  /// //     {'id': 1, 'name': 'a*'},
  /// //     {'id': 2, 'name': 'b', 'extra': true},
  /// //   ]
  /// // }
  /// ```
  ///
  /// Notes:
  /// - Masking is positional for lists; the right-hand side determines how far overrides apply.
  /// - Passing `null` on the right does not delete data; it preserves the left value.
  /// - To coerce to a typed map, use `stringMap(...)` or cast as needed.
  Map<dynamic, dynamic> mask(Map<dynamic, dynamic> other) {
    final result = <dynamic, dynamic>{};
    final keys = [...this.keys, ...other.keys];
    for (final key in keys) {
      if (containsKey(key) && other.containsKey(key)) {
        result[key] = maskObjects(this[key], other[key]);
      } else if (containsKey(key)) {
        result[key] = this[key];
      } else {
        result[key] = other[key];
      }
    }
    return result;
  }
}

dynamic maskObjects(dynamic a, dynamic b) {
  if (a is List && b is List) {
    return a.mask(b);
  }
  if (a is Map && b is Map) {
    return a.mask(b);
  }
  if (a.runtimeType == b.runtimeType) {
    return b;
  }
  if (a == null && b != null) {
    return b;
  }
  if (a != null && b == null) {
    return a;
  }
  // If the types are not compatible, then the base is the correct type.
  return a;
}

Map<String, dynamic> stringMap(dynamic value) {
  if (value is Map<String, dynamic>) {
    return value;
  }
  if (value is Map) {
    return value.map((key, value) => MapEntry(key.toString(), value));
  }
  return {};
}
