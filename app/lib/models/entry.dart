import "dart:convert";

import "package:collection/collection.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:riverpod_annotation/riverpod_annotation.dart";
import "package:typewriter/models/entry_blueprint.dart";
import "package:typewriter/models/page.dart";
import "package:typewriter/utils/extensions.dart";
import "package:typewriter/utils/passing_reference.dart";

part "entry.g.dart";

@riverpod
EntryDefinition? entryDefinition(
  Ref ref,
  String entryId,
) {
  final page = ref.watch(entryPageProvider(entryId));
  if (page == null) {
    return null;
  }
  final entry = ref.watch(entryProvider(page.id, entryId));
  final blueprint = ref.watch(entryBlueprintProvider(entry?.blueprintId ?? ""));
  if (entry == null || blueprint == null) {
    return null;
  }
  return EntryDefinition(
    pageId: page.id,
    pageName: page.pageName,
    entry: entry,
    blueprint: blueprint,
  );
}

@riverpod
String? entryName(Ref ref, String entryId) {
  final entry = ref.watch(globalEntryProvider(entryId));
  return entry?.formattedName;
}

@riverpod
String? entryBlueprintId(Ref ref, String entryId) {
  final entry = ref.watch(globalEntryProvider(entryId));
  return entry?.blueprintId;
}

@riverpod
DeprecatedModifier? entryDeprecated(Ref ref, String entryId) {
  final blueprintId = ref.watch(entryBlueprintIdProvider(entryId));
  if (blueprintId == null) return null;
  final blueprint = ref.watch(entryBlueprintProvider(blueprintId));
  if (blueprint == null) return null;
  return blueprint.modifiers.whereType<DeprecatedModifier>().firstOrNull;
}

@riverpod
bool isEntryDeprecated(Ref ref, String entryId) {
  final deprecated = ref.watch(entryDeprecatedProvider(entryId));
  return deprecated != null;
}

class EntryDefinition {
  EntryDefinition({
    required this.pageId,
    required this.pageName,
    required this.entry,
    required this.blueprint,
  });
  final String pageId;
  final String pageName;
  final Entry entry;
  final EntryBlueprint blueprint;

  Future<void> updateField(PassingRef ref, String path, dynamic value) async {
    final page = ref.read(pageProvider(pageId));
    if (page == null) return;
    await page.updateEntryValue(ref, entry, path, value);
  }
}

class Entry {
  Entry(this.data);

  Entry.fromBlueprint({
    required String id,
    required EntryBlueprint blueprint,
    DataBlueprint? genericBlueprint,
  })  : assert(
          blueprint.isGeneric == (genericBlueprint != null),
          blueprint.isGeneric
              ? "Blueprint is generic but no generic blueprint was provided"
              : "Blueprint is not generic but a generic blueprint was provided",
        ),
        assert(
          blueprint.allowsGeneric(genericBlueprint),
          "Generic blueprint given is not allowed for this blueprint, blueprint: ${blueprint.id}, allowed: ${blueprint.genericConstraints}, genericBlueprint: $genericBlueprint",
        ),
        data = {
          ...blueprint.dataBlueprint.defaultValue(),
          "id": id,
          "name": "new_${blueprint.name}",
          "type": blueprint.id,
          "_genericBlueprint": genericBlueprint?.toJson(),
        };

  factory Entry.fromJson(Map<String, dynamic> json) => Entry(json);
  final Map<String, dynamic> data;
  DataBlueprint? _genericBlueprint;

  Map<String, dynamic> toJson() => data;

  String get id => data["id"] as String;

  String get name => data["name"] as String;

  String get formattedName => name.formatted;

  /// Returns the blueprint id of the entry.
  /// TODO: Remove the old `type` field.
  String get blueprintId {
    final blueprintId = data["blueprintId"];
    if (blueprintId is String) return blueprintId;
    final type = data["type"];
    if (type is String) return type;
    throw Exception("Could not find blueprint id or type in entry data");
  }

  /// Returns the generic blueprint of the entry.
  DataBlueprint? get genericBlueprint {
    if (_genericBlueprint != null) return _genericBlueprint;
    final genericBlueprint = data["_genericBlueprint"];
    if (genericBlueprint == null) return null;

    if (genericBlueprint is! Map<String, dynamic>) {
      throw Exception("Generic blueprint is not a map");
    }

    final blueprint = DataBlueprint.fromJson(genericBlueprint);
    _genericBlueprint = blueprint;
    return blueprint;
  }

  /// Returns the values in [map] that match [path].
  ///
  /// The path is a string representation of keys and indices to access the values in [map].
  /// ".*" can be used in [path] to match any key in a map, and "[0-9]+" can be used to match
  /// any index in a list.
  ///
  /// # Example
  ///
  /// Given the following map:
  ///
  /// ```
  /// Map<String, dynamic> map = {
  ///   "foo": [{"bar": 42}, {"baz": 56}],
  ///   "qux": {"quux": [1, 2, 3]}
  /// };
  /// ```
  ///
  /// The following paths and their returned values are:
  ///
  /// | Path                  | Returned value |
  /// |----------------------|----------------|
  /// | "foo.*.bar"          | [42]           |
  /// | "foo.0.bar"          | [42]           |
  /// | "qux.quux.*"         | [1, 2, 3]      |
  /// | "qux.quux.2"         | [3]            |
  ///
  List<dynamic> _crawl(String path, [Map<String, dynamic>? map]) {
    final data = map ?? this.data;
    if (path.isEmpty) {
      return [data];
    }
    final parts = path.split(".");
    return parts.fold(<dynamic>[data], (current, part) {
      return current.expand((item) {
        if (item is Map) {
          return _crawlInMap(item, part);
        } else if (item is List) {
          return _crawlInList(item, part);
        }
        return [];
      }).toList();
    });
  }

  /// Crawls [map] using [part] of [path].
  List<dynamic> _crawlInMap(Map<dynamic, dynamic> map, String part) {
    if (part == "*") {
      return map.values.toList();
    } else if (map.containsKey(part)) {
      return [map[part]];
    }
    return [];
  }

  /// Crawls [list] using [part] of [path].
  List<dynamic> _crawlInList(List<dynamic> list, String part) {
    if (part == "*") {
      return list;
    } else if (int.tryParse(part) != null && list.length > int.parse(part)) {
      return [list[int.parse(part)]];
    }
    return [];
  }

  /// Returns a inner field of this entry.
  /// These fields can be nested using dot notation, like "data.value", "data.1.value", etc.
  /// If the field is not found, a given default value is returned.
  dynamic get(String path, [dynamic defaultValue]) {
    return _crawl(path).firstOrNull ?? defaultValue;
  }

  /// Returns all values of a given path.
  /// This may look similar to [get], but it returns all values of a given path.
  /// Hence wildcards are supported, like "data.*.value", "data.*.1.value", etc.
  List<dynamic> getAll(String path) => _crawl(path);

  /// Returns a new copy of this entry with the given field updated.
  /// You can update nested fields by using dot notation, such as "data.value", "data.1.value", etc.
  ///
  /// For example:
  ///   - if you want to update the field "bar" in the first item of a list at the key "foo",
  ///     use the field "foo.0.bar".
  ///
  /// Returns the original entry if the field is not found.
  Entry copyWith(String field, dynamic value) {
    final parts = field.split(".");
    final last = parts.removeLast();
    // Make a deep copy of the data. To avoid modifying the original data.
    final data = jsonDecode(jsonEncode(this.data));

    var current = _crawl(parts.join("."), data).firstOrNull;
    if (current == null) {
      // The field does not exist. Try to create the path.
      _createPath(field, data);
      current = _crawl(parts.join("."), data).firstOrNull;
    }
    if (current == null) {
      // The field still does not exist. Return the original entry.
      return this;
    }

    // Update the field.
    if (current is Map) {
      current[last] = value;
    }
    if (current is List && int.tryParse(last) != null) {
      current[int.parse(last)] = value;
    }

    return Entry(data);
  }

  void _createPath(String path, Map<String, dynamic> data) {
    if (path.contains("*")) return;
    final parts = path.split(".");

    dynamic putIfAbsent(dynamic current, String path, dynamic value) {
      if (current is List && int.tryParse(path) != null) {
        final index = int.parse(path);
        if (current.length > index) {
          final cur = current[index];
          // If the current value is null, we see it as an absent value.
          if (cur == null) {
            current[index] = value;
            return value;
          }
          return cur;
        } else {
          current.addAll(List.filled(index - current.length + 1, null));
          current[index] = value;
          return value;
        }
      } else {
        if (current[path] != null) {
          return current[path];
        } else {
          return current[path] = value;
        }
      }
    }

    dynamic current = data;

    for (var i = 0; i < parts.length - 1; i++) {
      final part = parts[i];
      final next = parts[i + 1];
      if (int.tryParse(next) != null) {
        current = putIfAbsent(current, part, []);
      } else {
        current = putIfAbsent(current, part, {});
      }
    }
  }

  /// Returns a new copy of this entry with all values of a given path updated.
  /// All possible fields are checked and mapped to a new value. If the new value is null, the field is removed from the map or list.
  /// If the new value is a map or list, the old value is replaced with the new one.
  /// If the new value is a primitive, the old value is replaced with the new one.
  /// This may look similar to [copyWith], but it updates all values of a given path.
  /// Hence wildcards are supported, like "data.*.value", "data.*.1.value", etc.
  Entry copyMapped(String path, dynamic Function(dynamic) mapper) {
    final parts = path.split(".");
    final last = parts.removeLast();
    // Make a deep copy of the data. To avoid modifying the original data.
    final data = jsonDecode(jsonEncode(this.data));

    final subFields = _crawl(parts.join("."), data);

    if (last == "*") {
      for (final item in subFields) {
        _updateAllValues(item, mapper);
      }
    } else {
      for (final item in subFields) {
        _updateSingleValue(item, last, mapper);
      }
    }

    return Entry(data);
  }

  void _updateAllValues(dynamic item, dynamic Function(dynamic) mapper) {
    if (item is Map) {
      for (final key in item.keys.toList()) {
        _updateSingleValue(item, key, mapper);
      }
    }
    if (item is List) {
      item.replaceRange(0, item.length, item.map(mapper).nonNulls);
    }
  }

  void _updateSingleValue(
    dynamic item,
    String last,
    dynamic Function(dynamic) mapper,
  ) {
    if (item is Map && item.containsKey(last)) {
      final value = mapper(item[last]);
      if (value == null) {
        item.remove(last);
      } else {
        item[last] = value;
      }
    }
    if (item is List) {
      final index = last.asInt;
      if (index == null || index < 0 || index >= item.length) {
        return;
      }
      final value = mapper(item[index]);
      if (value == null) {
        item.removeAt(index);
      } else {
        item[index] = value;
      }
    }
  }

  /// Find paths for the entry that can be set.
  /// When the ending path is a list, a path with a new index is returned.
  List<String> newPaths(String path) {
    return _newPaths(path, data);
  }

  List<String> _newPaths(String path, dynamic data) {
    if (data is Map) {
      return _newPathsInMap(path, data.cast<String, dynamic>());
    }
    if (data is List) {
      return _newPathsInList(path, data);
    }
    return [];
  }

  List<String> _newPathsInMap(String path, Map<String, dynamic> map) {
    final parts = path.split(".");
    final first = parts.removeAt(0);
    final newPath = parts.join(".");

    if (first == "*") {
      final keys = map.keys.toList();

      if (parts.isEmpty) return keys;

      return keys.expand((key) {
        return _newPaths(newPath, map[key]).map((p) => "$key.$p");
      }).toList();
    } else if (map.containsKey(first)) {
      if (parts.isEmpty) return [first];
      return _newPaths(newPath, map[first]).map((p) => "$first.$p").toList();
    } else if (parts.isEmpty) {
      return [first];
    }
    return [];
  }

  List<String> _newPathsInList(String path, List<dynamic> list) {
    final parts = path.split(".");
    final first = parts.removeAt(0);
    final newPath = parts.join(".");

    if (first == "*") {
      if (parts.isEmpty) return ["${list.length}"];

      return list.indices.expand((index) {
        return _newPaths(newPath, list[index]).map((p) => "$index.$p");
      }).toList();
    } else if (int.tryParse(first) != null) {
      final index = int.parse(first);
      if (index < list.length) {
        if (parts.isEmpty) return ["$index"];
        return _newPaths(newPath, list[index]).map((p) => "$index.$p").toList();
      }
    }

    return [];
  }

  @override
  String toString() => "Entry{data: $data}";

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is Entry && data == other.data;

  @override
  int get hashCode => data.hashCode;
}
