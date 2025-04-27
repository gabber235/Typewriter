import "package:collection/collection.dart";
import "package:flutter/foundation.dart";
import "package:flutter/material.dart";
import "package:freezed_annotation/freezed_annotation.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:riverpod_annotation/riverpod_annotation.dart";
import "package:typewriter/models/entry.dart";
import "package:typewriter/models/extension.dart";
import "package:typewriter/models/page.dart";
import "package:typewriter/utils/color_converter.dart";
import "package:typewriter/utils/extensions.dart";
import "package:typewriter/utils/icons.dart";
import "package:url_launcher/url_launcher_string.dart";

import "../main.dart";

part "entry_blueprint.freezed.dart";
part "entry_blueprint.g.dart";

/// A generated provider to fetch and cache a list of all the [EntryBlueprint]s.
@riverpod
List<EntryBlueprint> entryBlueprints(Ref ref) =>
    ref.watch(extensionsProvider).expand((e) => e.entries).toList();

/// A generated provider to fetch and cache a specific [EntryBlueprint] by its [blueprintId].
@riverpod
EntryBlueprint? entryBlueprint(Ref ref, String blueprintId) => ref
    .watch(entryBlueprintsProvider)
    .firstWhereOrNull((e) => e.id == blueprintId);

@riverpod
List<String> entryBlueprintTags(
  Ref ref,
  String blueprintId,
) =>
    ref.watch(entryBlueprintProvider(blueprintId))?.tags ?? [];

@riverpod
List<String> entryTags(
  Ref ref,
  String entryId,
) {
  final blueprintId = ref.watch(entryBlueprintIdProvider(entryId));
  if (blueprintId == null) return [];
  return ref.watch(entryBlueprintTagsProvider(blueprintId));
}

@riverpod
PageType entryBlueprintPageType(
  Ref ref,
  String blueprintId,
) {
  final blueprint = ref.watch(entryBlueprintProvider(blueprintId));
  if (blueprint == null) return PageType.static;
  return PageType.fromBlueprint(blueprint);
}

/// Gets all the modifiers with a given name.
@riverpod
Map<String, Modifier> fieldModifiers(
  Ref ref,
  String blueprintId,
  String modifierName,
) {
  return ref
          .watch(entryBlueprintProvider(blueprintId))
          ?.fieldsWithModifier(modifierName) ??
      {};
}

/// Gets all the paths from fields with a given modifier.
@riverpod
List<String> modifierPaths(
  Ref ref,
  String blueprintId,
  String modifierName, [
  String? data,
]) {
  return ref
      .watch(fieldModifiersProvider(blueprintId, modifierName))
      .entries
      .where((e) => data == null || e.value.data == data)
      .map((e) => e.key)
      .toList();
}

/// A data model that represents an entry blueprint.
@freezed
class EntryBlueprint with _$EntryBlueprint {
  const factory EntryBlueprint({
    required String id,
    required String name,
    required String description,
    required String extension,
    required ObjectBlueprint dataBlueprint,
    @ColorConverter() @Default(Colors.grey) Color color,
    @Default(TWIcons.help) String icon,
    @Default(<String>[]) List<String> tags,
    @Default(null) List<DataBlueprint>? genericConstraints,
    @Default(null) DataBlueprint? variableDataBlueprint,
    @Default([]) List<ContextKey> contextKeys,
    @Default([]) List<EntryModifier> modifiers,
  }) = _EntryBlueprint;

  factory EntryBlueprint.fromJson(Map<String, dynamic> json) =>
      _$EntryBlueprintFromJson(json);
}

/// A data blueprint for the fields of an entry blueprint.
@Freezed(unionKey: "kind")
class DataBlueprint with _$DataBlueprint {
  /// A default constructor that should never be used.
  const factory DataBlueprint({
    @JsonKey(name: "default") dynamic internalDefaultValue,
    @Default([]) List<Modifier> modifiers,
  }) = _DataBlueprintType;

  /// Primitive field type, such as a string or a number.
  const factory DataBlueprint.primitive({
    required PrimitiveType type,
    @JsonKey(name: "default") dynamic internalDefaultValue,
    @Default([]) List<Modifier> modifiers,
  }) = PrimitiveBlueprint;

  /// Enum field type, such as a list of options.
  @FreezedUnionValue("enum")
  const factory DataBlueprint.enumBlueprint({
    required List<String> values,
    @JsonKey(name: "default") dynamic internalDefaultValue,
    @Default([]) List<Modifier> modifiers,
  }) = EnumBlueprint;

  /// List field type, such as a list of strings.
  const factory DataBlueprint.list({
    required DataBlueprint type,
    @JsonKey(name: "default") dynamic internalDefaultValue,
    @Default([]) List<Modifier> modifiers,
  }) = ListBlueprint;

  /// Map blueprint, such as a map of strings to strings.
  /// Only strings and enums, and entry references are supported as keys.
  const factory DataBlueprint.map({
    required DataBlueprint key,
    required DataBlueprint value,
    @JsonKey(name: "default") dynamic internalDefaultValue,
    @Default([]) List<Modifier> modifiers,
  }) = MapBlueprint;

  /// Object blueprint, such as a nested object.
  const factory DataBlueprint.object({
    required Map<String, DataBlueprint> fields,
    @JsonKey(name: "default") dynamic internalDefaultValue,
    @Default([]) List<Modifier> modifiers,
  }) = ObjectBlueprint;

  /// Algebraic blueprint, such as a sum type.
  const factory DataBlueprint.algebraic({
    required Map<String, DataBlueprint> cases,
    @JsonKey(name: "default") dynamic internalDefaultValue,
    @Default([]) List<Modifier> modifiers,
  }) = AlgebraicBlueprint;

  /// Custom blueprint, where a custom editor is used.
  const factory DataBlueprint.custom({
    required String editor,
    required DataBlueprint shape,
    @JsonKey(name: "default") dynamic internalDefaultValue,
    @Default([]) List<Modifier> modifiers,
  }) = CustomBlueprint;

  factory DataBlueprint.fromJson(Map<String, dynamic> json) =>
      _$DataBlueprintFromJson(json);
}

@freezed
class Modifier with _$Modifier {
  const factory Modifier({
    required String name,
    dynamic data,
  }) = _Modifier;

  factory Modifier.fromJson(Map<String, dynamic> json) =>
      _$ModifierFromJson(json);
}

@freezed
class ContextKey with _$ContextKey {
  const factory ContextKey({
    required String name,
    required String klassName,
    required DataBlueprint blueprint,
  }) = _ContextKey;

  factory ContextKey.fromJson(Map<String, dynamic> json) =>
      _$ContextKeyFromJson(json);
}

@Freezed(unionKey: "kind")
class EntryModifier with _$EntryModifier {
  const factory EntryModifier() = _EmptyModifier;

  const factory EntryModifier.deprecated({
    @Default("") String reason,
  }) = DeprecatedModifier;

  factory EntryModifier.fromJson(Map<String, dynamic> json) =>
      _$EntryModifierFromJson(json);
}

const wikiBaseUrl = kDebugMode
    ? "http://localhost:3000/TypeWriter"
    : "https://docs.typewritermc.com";

extension EntryBlueprintExt on EntryBlueprint {
  bool get isGeneric => genericConstraints != null;

  bool allowsGeneric(DataBlueprint? genericBlueprint) {
    final blueprints = genericConstraints;
    if (blueprints == null) return true;
    if (genericBlueprint == null) return false;
    // If the blueprints is empty, all blueprints are allowed.
    if (blueprints.isEmpty) return true;
    for (final blueprint in blueprints) {
      if (blueprint.matches(genericBlueprint)) return true;
    }
    return blueprints.any((e) => e.matches(genericBlueprint));
  }

  Map<String, Modifier> fieldsWithModifier(String name) =>
      _fieldsWithModifier(name, "", dataBlueprint);

  /// Parse through the fields of this entry and return a list of all the fields that have the given modifier with [name].
  Map<String, Modifier> _fieldsWithModifier(
    String name,
    String path,
    DataBlueprint blueprint,
  ) {
    final fields = {
      if (blueprint.hasModifier(name)) path: blueprint.getModifier(name)!,
    };

    if (blueprint is ObjectBlueprint) {
      for (final field in blueprint.fields.entries) {
        fields.addAll(
          _fieldsWithModifier(
            name,
            path.join(field.key),
            field.value,
          ),
        );
      }
    } else if (blueprint is ListBlueprint) {
      fields.addAll(
        _fieldsWithModifier(name, path.join("*"), blueprint.type),
      );
    } else if (blueprint is MapBlueprint) {
      fields
        ..addAll(
          _fieldsWithModifier(name, path, blueprint.key),
        )
        ..addAll(
          _fieldsWithModifier(name, path.join("*"), blueprint.value),
        );
    }

    return fields;
  }

  DataBlueprint? getField(String path) {
    final parts = path.split(".");
    DataBlueprint? info = dataBlueprint;
    for (final part in parts) {
      if (info is ObjectBlueprint) {
        info = info.fields[part];
      } else if (info is ListBlueprint) {
        info = info.type;
      } else if (info is MapBlueprint) {
        info = info.value;
      }
    }

    return info;
  }

  static const _wikiCategories = [
    "action",
    "dialogue",
    "event",
    "fact",
    "speaker",
  ];
  // TODO: Change once the module marketplace is implemented
  String get wikiUrl {
    final category =
        tags.firstWhereOrNull((tag) => _wikiCategories.contains(tag));

    if (category == null) {
      return "$wikiBaseUrl/extensions/${extension}Extension";
    }

    return "$wikiBaseUrl/extensions/${extension}Extension/entries/$category/$name";
  }

  Future<void> openWiki() async {
    final url = wikiUrl;
    if (await canLaunchUrlString(url)) {
      await launchUrlString(url);
    }
  }
}

final _customEditorCustomLayout = [
  "item",
  "skin",
  "color",
  "var",
];

/// Since freezed does not support methods on data models, we have to create a separate extension class.
extension DataBlueprintExtension on DataBlueprint {
  /// Get the default value for this data blueprint.
  dynamic defaultValue() => map(
        (_) => null,
        primitive: (data) {
          if (data.type.validate(data.internalDefaultValue)) {
            return data.internalDefaultValue;
          }
          return _defaultPrimitiveValue(data.type);
        },
        enumBlueprint: (data) {
          if (data.values.contains(data.internalDefaultValue)) {
            return data.internalDefaultValue;
          }
          return data.values.first;
        },
        list: (data) {
          if (data.type.internalDefaultValue is List) {
            return data.type.internalDefaultValue;
          }
          return [];
        },
        map: (data) {
          if (data.internalDefaultValue is Map) {
            return data.internalDefaultValue;
          }
          return {};
        },
        object: (data) {
          if (data.internalDefaultValue is Map) {
            return data.internalDefaultValue;
          }

          return data.fields
              .map((key, value) => MapEntry(key, value.defaultValue()));
        },
        algebraic: (data) {
          final first = data.cases.entries.first;
          return {
            "case": first.key,
            "value": first.value.defaultValue(),
          };
        },
        custom: (data) => data.internalDefaultValue,
      );

  dynamic _defaultPrimitiveValue(PrimitiveType type) {
    if (type == PrimitiveType.string) {
      if (hasModifier("generated")) {
        return uuid.v4();
      }
    }

    return type.defaultValue;
  }

  /// If the [ObjectEditor] needs to show a default layout or if a field declares a custom layout.
  bool get hasCustomLayout {
    if (this is CustomBlueprint) {
      final editor = (this as CustomBlueprint).editor;
      if (_customEditorCustomLayout.contains(editor)) {
        return true;
      }
    }
    if (this is ObjectBlueprint) {
      return true;
    }
    if (this is ListBlueprint) {
      return true;
    }
    if (this is MapBlueprint) {
      return true;
    }
    return false;
  }

  Modifier? getModifier(String name) {
    return modifiers.firstWhereOrNull((e) => e.name == name);
  }

  bool hasModifier(String name) {
    return getModifier(name) != null;
  }

  T? get<T>(String name) {
    final modifier = getModifier(name);
    return modifier?.data as T?;
  }

  bool matches(DataBlueprint other) {
    if (this is PrimitiveBlueprint && other is PrimitiveBlueprint) {
      return other.type == (this as PrimitiveBlueprint).type;
    }
    if (this is EnumBlueprint && other is EnumBlueprint) {
      return listEquals(other.values, (this as EnumBlueprint).values);
    }
    if (this is ListBlueprint && other is ListBlueprint) {
      return other.type.matches((this as ListBlueprint).type);
    }
    if (this is MapBlueprint && other is MapBlueprint) {
      return other.key.matches((this as MapBlueprint).key) &&
          other.value.matches((this as MapBlueprint).value);
    }
    if (this is ObjectBlueprint && other is ObjectBlueprint) {
      final obj = this as ObjectBlueprint;
      if (obj.fields.length != other.fields.length) return false;
      if (!setEquals(obj.fields.keys.toSet(), other.fields.keys.toSet())) {
        return false;
      }
      for (final key in obj.fields.keys) {
        if (!other.fields.containsKey(key)) return false;
        if (!obj.fields[key]!.matches(other.fields[key]!)) return false;
      }
      return true;
    }
    if (this is AlgebraicBlueprint && other is AlgebraicBlueprint) {
      final alg = this as AlgebraicBlueprint;
      if (alg.cases.length != other.cases.length) return false;
      if (!setEquals(alg.cases.keys.toSet(), other.cases.keys.toSet())) {
        return false;
      }
      for (final key in alg.cases.keys) {
        if (!other.cases.containsKey(key)) return false;
        if (!alg.cases[key]!.matches(other.cases[key]!)) return false;
      }
      return true;
    }
    if (this is CustomBlueprint && other is CustomBlueprint) {
      return other.editor == (this as CustomBlueprint).editor &&
          other.shape.matches((this as CustomBlueprint).shape);
    }
    return false;
  }
}

/// A data model that represents a primitive field type.
enum PrimitiveType {
  boolean(false),
  double(0.0),
  integer(0),
  string(""),
  ;

  /// A constructor that is used to create an instance of the [PrimitiveType] class.
  const PrimitiveType(this.defaultValue);

  /// The default value for this field type.
  final dynamic defaultValue;
}

extension PrimitiveTypeExtension on PrimitiveType {
  // It has to be outside of the enum since double clashes with the double type.
  bool validate(dynamic value) {
    switch (this) {
      case PrimitiveType.boolean:
        return value is bool;
      case PrimitiveType.double:
        return value is double;
      case PrimitiveType.integer:
        return value is int;
      case PrimitiveType.string:
        return value is String;
    }
  }
}
