import "package:typewriter_panel/utils/collection.dart";

extension MapX on Map<dynamic, dynamic> {
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
