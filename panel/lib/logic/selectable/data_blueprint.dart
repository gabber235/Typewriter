// ignore_for_file: sort_constructors_first
import "package:flutter/foundation.dart";
import "package:freezed_annotation/freezed_annotation.dart";
import "package:typewriter_panel/main.dart";

part "data_blueprint.freezed.dart";
part "data_blueprint.g.dart";

/// A data blueprint for the fields of an entry blueprint.
@Freezed(unionKey: "kind")
sealed class DataBlueprint with _$DataBlueprint {
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

  static DataBlueprint string({
    String? defaultValue,
    List<Modifier> modifiers = const [],
  }) =>
      PrimitiveBlueprint(
        type: PrimitiveType.string,
        internalDefaultValue: defaultValue,
        modifiers: modifiers,
      );
  static DataBlueprint integer({
    int? defaultValue,
    List<Modifier> modifiers = const [],
  }) =>
      PrimitiveBlueprint(
        type: PrimitiveType.integer,
        internalDefaultValue: defaultValue,
        modifiers: modifiers,
      );
  static DataBlueprint decimal({
    double? defaultValue = 0.0,
    List<Modifier> modifiers = const [],
  }) =>
      PrimitiveBlueprint(
        type: PrimitiveType.double,
        internalDefaultValue: defaultValue,
        modifiers: modifiers,
      );
  static DataBlueprint boolean({
    bool? defaultValue,
    List<Modifier> modifiers = const [],
  }) =>
      PrimitiveBlueprint(
        type: PrimitiveType.boolean,
        internalDefaultValue: defaultValue,
        modifiers: modifiers,
      );

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

@Freezed(unionKey: "kind")
abstract class Modifier with _$Modifier {
  // String Based
  const factory Modifier.multiline() = MultilineModifier;
  const factory Modifier.snakeCase() = SnakeCaseModifier;

  const factory Modifier.generated() = GeneratedModifier;

  // Number Based
  const factory Modifier.min(num value) = MinModifier;
  const factory Modifier.max(num value) = MaxModifier;
  const factory Modifier.negative() = NegativeModifier;

  const factory Modifier.custom({
    required String name,
    required dynamic data,
  }) = CustomModifier;

  factory Modifier.fromJson(Map<String, dynamic> json) =>
      _$ModifierFromJson(json);
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

final _customEditorCustomLayout = [
  "item",
  "skin",
  "color",
  "var",
];

/// Since freezed does not support methods on data models, we have to create a separate extension class.
extension DataBlueprintExtension on DataBlueprint {
  dynamic defaultValue() {
    return switch (this) {
      _DataBlueprintType(:final internalDefaultValue) => internalDefaultValue,
      PrimitiveBlueprint(:final type, :final internalDefaultValue) =>
        _defaultPrimitiveValue(type, internalDefaultValue),
      EnumBlueprint(:final values, :final internalDefaultValue) =>
        _defaultEnumValue(values, internalDefaultValue),
      ListBlueprint(:final type, :final internalDefaultValue) =>
        _defaultListValue(type, internalDefaultValue),
      MapBlueprint(:final key, :final value, :final internalDefaultValue) =>
        _defaultMapValue(key, value, internalDefaultValue),
      ObjectBlueprint(:final fields, :final internalDefaultValue) =>
        _defaultObjectValue(fields, internalDefaultValue),
      AlgebraicBlueprint(:final cases) => _defaultAlgebraicValue(cases),
      CustomBlueprint(:final internalDefaultValue) =>
        _defaultCustomValue(internalDefaultValue),
    };
  }

  dynamic _defaultPrimitiveValue(
    PrimitiveType type,
    dynamic internalDefaultValue,
  ) {
    if (type.validate(internalDefaultValue)) {
      return internalDefaultValue;
    }
    if (type == PrimitiveType.string) {
      if (hasModifier<GeneratedModifier>()) {
        return uuid.v4();
      }
    }

    return type.defaultValue;
  }

  dynamic _defaultEnumValue(List<String> values, dynamic internalDefaultValue) {
    if (values.contains(internalDefaultValue)) {
      return internalDefaultValue;
    }
    return values.first;
  }

  dynamic _defaultListValue(DataBlueprint type, dynamic internalDefaultValue) {
    if (internalDefaultValue is List) {
      return internalDefaultValue;
    }
    return [];
  }

  dynamic _defaultMapValue(
    DataBlueprint key,
    DataBlueprint value,
    dynamic internalDefaultValue,
  ) {
    if (internalDefaultValue is Map) {
      return internalDefaultValue;
    }
    return {};
  }

  dynamic _defaultObjectValue(
    Map<String, DataBlueprint> fields,
    dynamic internalDefaultValue,
  ) {
    if (internalDefaultValue is Map) {
      return internalDefaultValue;
    }
    return fields.map((key, value) => MapEntry(key, value.defaultValue()));
  }

  dynamic _defaultAlgebraicValue(
    Map<String, DataBlueprint> cases,
  ) {
    final first = cases.entries.first;
    return {
      "case": first.key,
      "value": first.value.defaultValue(),
    };
  }

  dynamic _defaultCustomValue(
    dynamic internalDefaultValue,
  ) {
    return internalDefaultValue;
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

  Iterable<M> getModifiers<M extends Modifier>() {
    return modifiers.whereType<M>();
  }

  bool hasModifier<M extends Modifier>() {
    return modifiers.any((m) => m is M);
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

extension DataBlueprintList on List<DataBlueprint> {
  DataBlueprint? get overlap {
    if (isEmpty) return null;
    if (length == 1) return first;
    if (any((blueprint) => blueprint.runtimeType != first.runtimeType)) {
      return null;
    }

    switch (first) {
      case _DataBlueprintType():
        return null;
      case PrimitiveBlueprint():
        final primitives = whereType<PrimitiveBlueprint>().toList();
        if (primitives.length != length) return null;
        return primitives.overlap;
      case EnumBlueprint():
        final enums = whereType<EnumBlueprint>().toList();
        if (enums.length != length) return null;
        return enums.overlap;
      case ListBlueprint():
        final lists = whereType<ListBlueprint>().toList();
        if (lists.length != length) return null;
        return lists.overlap;
      case MapBlueprint():
        final maps = whereType<MapBlueprint>().toList();
        if (maps.length != length) return null;
        return maps.overlap;
      case ObjectBlueprint():
        final objects = whereType<ObjectBlueprint>().toList();
        if (objects.length != length) return null;
        return objects.overlap;
      case AlgebraicBlueprint():
        final algebraics = whereType<AlgebraicBlueprint>().toList();
        if (algebraics.length != length) return null;
        return algebraics.overlap;
      case CustomBlueprint():
        final customs = whereType<CustomBlueprint>().toList();
        if (customs.length != length) return null;
        return customs.overlap;
    }
  }
}

extension PrimitiveBlueprintList on List<PrimitiveBlueprint> {
  PrimitiveBlueprint? get overlap {
    if (isEmpty) return null;
    if (length == 1) return first;
    if (any((blueprint) => !blueprint.matches(first))) return null;
    return first;
  }
}

extension EnumBlueprintList on List<EnumBlueprint> {
  EnumBlueprint? get overlap {
    if (isEmpty) return null;
    if (length == 1) return first;
    if (any((blueprint) => !blueprint.matches(first))) return null;
    return first;
  }
}

extension ListBlueprintList on List<ListBlueprint> {
  ListBlueprint? get overlap {
    if (isEmpty) return null;
    if (length == 1) return first;
    final type = map((blueprint) => blueprint.type).toList().overlap;
    if (type == null) return null;

    return first.copyWith(type: type);
  }
}

extension MapBlueprintList on List<MapBlueprint> {
  MapBlueprint? get overlap {
    if (isEmpty) return null;
    if (length == 1) return first;
    final key = map((blueprint) => blueprint.key).toList().overlap;
    if (key == null) return null;
    final value = map((blueprint) => blueprint.value).toList().overlap;
    if (value == null) return null;

    return first.copyWith(key: key, value: value);
  }
}

extension ObjectBlueprintList on List<ObjectBlueprint> {
  ObjectBlueprint? get overlap {
    if (isEmpty) return null;
    if (length == 1) return first;
    final keys = map((blueprint) => blueprint.fields.keys.toSet())
        .reduce((intersection, current) => intersection.intersection(current));
    if (keys.isEmpty) return null;

    final fields = <String, DataBlueprint>{};
    for (final key in keys) {
      final blueprints =
          map((blueprint) => blueprint.fields[key]).nonNulls.toList();
      final overlap = blueprints.overlap;
      if (overlap == null) continue;
      fields[key] = overlap;
    }

    return first.copyWith(fields: fields);
  }
}

extension AlgebraicBlueprintList on List<AlgebraicBlueprint> {
  AlgebraicBlueprint? get overlap {
    if (isEmpty) return null;
    if (length == 1) return first;
    final keys = map((blueprint) => blueprint.cases.keys.toSet())
        .reduce((intersection, current) => intersection.intersection(current));
    if (keys.isEmpty) return null;

    final cases = <String, DataBlueprint>{};
    for (final key in keys) {
      final blueprints =
          map((blueprint) => blueprint.cases[key]).nonNulls.toList();
      final overlap = blueprints.overlap;
      if (overlap == null) continue;
      cases[key] = overlap;
    }

    return first.copyWith(cases: cases);
  }
}

extension CustomBlueprintList on List<CustomBlueprint> {
  CustomBlueprint? get overlap {
    if (isEmpty) return null;
    if (length == 1) return first;
    if (any((blueprint) => !blueprint.matches(first))) return null;
    return first;
  }
}
