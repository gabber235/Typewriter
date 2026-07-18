import "package:collection/collection.dart";
import "package:flutter/material.dart";
import "package:freezed_annotation/freezed_annotation.dart";
import "package:typewriter_panel/features/organizations/features/realms/features/books/features/pages/domain/page_type_extensions.dart";
import "package:typewriter_panel/features/organizations/features/realms/features/books/features/pages/features/editor/domain/data_blueprint.dart";
import "package:typewriter_panel/infrastructure/protocols/protobuf/generated/models/book.pb.dart";
import "package:typewriter_panel/shared/utilities/color_converter.dart";
import "package:typewriter_panel/shared/utilities/string.dart";

part "element_blueprint.freezed.dart";
part "element_blueprint.g.dart";

@freezed
abstract class ElementBlueprint with _$ElementBlueprint {
  @Assert("id != \"\"", "ID must not be empty.")
  @Assert("name != \"\"", "Name must not be empty.")
  @Assert("extension != \"\"", "Extension must not be empty.")
  const factory ElementBlueprint({
    required String id,
    required String name,
    required String description,
    required String extension,
    required ObjectBlueprint dataBlueprint,
    @ColorConverter() @Default(Colors.grey) Color color,
    @Default("fa-solid:question-circle") String icon,
    @Default(<String>[]) List<String> tags,
    @Default(null) List<DataBlueprint>? genericConstraints,
    @Default(null) DataBlueprint? variableDataBlueprint,
    @Default([]) List<ContextKey> contextKeys,
    @Default([]) List<ElementModifier> modifiers,
  }) = _ElementBlueprint;

  factory ElementBlueprint.fromJson(Map<String, dynamic> json) =>
      _$ElementBlueprintFromJson(json);
}

@freezed
abstract class ContextKey with _$ContextKey {
  @Assert("name != \"\"", "Name must not be empty.")
  @Assert("klassName != \"\"", "Class name must not be empty.")
  const factory ContextKey({
    required String name,
    required String klassName,
    required DataBlueprint blueprint,
  }) = _ContextKey;

  factory ContextKey.fromJson(Map<String, dynamic> json) =>
      _$ContextKeyFromJson(json);
}

@Freezed(unionKey: "kind")
abstract class ElementModifier with _$ElementModifier {
  const factory ElementModifier() = _EmptyModifier;

  const factory ElementModifier.deprecated({@Default("") String reason}) =
      DeprecatedModifier;

  factory ElementModifier.fromJson(Map<String, dynamic> json) =>
      _$ElementModifierFromJson(json);
}

extension ElementBlueprintExt on ElementBlueprint {
  bool get isGeneric => genericConstraints != null;

  bool allowsGeneric(DataBlueprint? genericBlueprint) {
    final blueprints = genericConstraints;
    if (blueprints == null) return true;
    if (genericBlueprint == null) return false;
    if (blueprints.isEmpty) return true;
    for (final blueprint in blueprints) {
      if (blueprint.matches(genericBlueprint)) return true;
    }
    return blueprints.any((e) => e.matches(genericBlueprint));
  }

  List<M> getModifiers<M extends ElementModifier>() {
    return modifiers.whereType<M>().toList();
  }

  bool hasModifier<M extends ElementModifier>() {
    return modifiers.any((modifier) => modifier is M);
  }

  Map<String, List<M>> fieldsWithModifier<M extends Modifier>() =>
      _fieldsWithModifier<M>("", dataBlueprint);

  Map<String, List<M>> _fieldsWithModifier<M extends Modifier>(
    String path,
    DataBlueprint blueprint,
  ) {
    final fields = <String, List<M>>{
      if (blueprint.hasModifier<M>())
        path: blueprint.getModifiers<M>().toList(),
    };

    if (blueprint is ObjectBlueprint) {
      for (final field in blueprint.fields.entries) {
        fields.addAll(_fieldsWithModifier(path.join(field.key), field.value));
      }
    } else if (blueprint is ListBlueprint) {
      fields.addAll(_fieldsWithModifier(path.join("*"), blueprint.type));
    } else if (blueprint is MapBlueprint) {
      fields
        ..addAll(_fieldsWithModifier(path, blueprint.key))
        ..addAll(_fieldsWithModifier(path.join("*"), blueprint.value));
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

  PageType get pageType {
    final pageType = PageType.values.firstWhereOrNull(
      (type) => tags.contains(type.tag),
    );
    if (pageType == null) {
      throw Exception(
        "No page type found for blueprint $name, make sure it has one of the following tags: ${PageType.values.map((type) => type.tag).join(", ")}",
      );
    }
    return pageType;
  }
}
