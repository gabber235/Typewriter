part of "portable_expression.dart";

/// The authoring observation resource operations read, pinned to the catalog
/// generation of the expression bindings.
@Freezed(
  copyWith: false,
  map: FreezedMapOptions.none,
  when: FreezedWhenOptions.none,
)
abstract class PortableExpressionQueries with _$PortableExpressionQueries {
  factory PortableExpressionQueries({
    required CheckedEditorCatalog catalog,
    PortableAuthoringView? authored,
  }) {
    if (authored is PortableAuthoringEdit) {
      throw ArgumentError.value(
        authored,
        "authored",
        "Capture an immutable document before rendering",
      );
    }
    if (authored != null &&
        authored.generation != catalog.snapshot.generation) {
      throw StateError("Query document and catalog generations differ");
    }
    return PortableExpressionQueries._value(
      catalog: catalog,
      authored: authored,
    );
  }
  const PortableExpressionQueries._();
  const factory PortableExpressionQueries._value({
    required CheckedEditorCatalog catalog,
    required PortableAuthoringView? authored,
  }) = _PortableExpressionQueries;
}

/// The group a tree layout binds while rendering each group header: its path,
/// last path segment as name, and direct members.
final hierarchyGroupUse = skir.NamedTypeUse(
  definition: skir.TypeDefinitionId(
    typeId: skir.TypeId.createDeclared(
      value: "c9ef8108a30f4e43805d8ee137e001dc",
    ),
    revision: 1,
  ),
  arguments: const [],
);

extension ResourceIdentityExpression on skir.ResourceId {
  skir.DataValue toExpressionValue() => skir.resourceIdValue(this);
  PortableExpressionBinding toExpressionBinding() => PortableExpressionBinding(
    value: toExpressionValue(),
    schema: CompletePortablePresentationBinding(
      skir.TypeUse.wrapNamed(skir.resourceIdType),
    ),
  );
}

final expressionColorUse = skir.NamedTypeUse(
  definition: skir.TypeDefinitionId(
    typeId: skir.TypeId.createDeclared(
      value: "c15fe94d13fb4317924a0ad2072defe4",
    ),
    revision: 1,
  ),
  arguments: const [],
);

/// Builds the declared Color data value for an unsigned ARGB [argb].
///
/// Expression evaluation and canonical read projection share this shape so
/// a projected protocol color equals the color the Kotlin evaluator produces.
skir.DataValue colorValue(int argb) => skir.DataValue.createNamed(
  actualType: expressionColorUse,
  payload: skir.DataValue.wrapInteger(argb.toString()),
);

skir.NamedTypeUse _declaredUse(String id) => skir.NamedTypeUse(
  definition: skir.TypeDefinitionId(
    typeId: skir.TypeId.createDeclared(value: id),
    revision: 1,
  ),
  arguments: const [],
);

/// The declared Icon type and its Iconify and SVG variants.
final expressionIconUse = _declaredUse("6fffa4398c0b4611bbf3517e047e6a52");
final _iconifyUse = _declaredUse("3845952a4d714e23ad55f07051669930");
final _svgIconUse = _declaredUse("67ed1a5b0e534c05b8d233ef9783971b");

/// Builds the declared Icon data value of [icon], the shape the Kotlin
/// evaluator produces, so a projected type display icon equals an authored one.
skir.DataValue iconValue(skir.Icon icon) => switch (icon) {
  skir.Icon_svgWrapper(:final value) => skir.DataValue.createNamed(
    actualType: _svgIconUse,
    payload: skir.DataValue.createRecord(
      fields: [
        skir.FieldValue(
          name: "source",
          value: skir.DataValue.wrapStringValue(value),
        ),
      ],
    ),
  ),
  skir.Icon_iconifyWrapper(:final value) => _iconifyValue(value),
  _ => _iconifyValue(""),
};

skir.DataValue _iconifyValue(String value) => skir.DataValue.createNamed(
  actualType: _iconifyUse,
  payload: skir.DataValue.createRecord(
    fields: [
      skir.FieldValue(
        name: "value",
        value: skir.DataValue.wrapStringValue(value),
      ),
    ],
  ),
);

/// Reads a declared Icon data value back into its wire form; null when
/// [value] is not an Iconify or SVG icon.
skir.Icon? decodeIconValue(skir.DataValue value) {
  if (value is! skir.DataValue_namedWrapper) return null;
  final payload = value.value.payload;
  if (payload is! skir.DataValue_recordWrapper) return null;
  String? field(String name) => payload.value.fields
      .where((field) => field.name == name)
      .firstOrNull
      ?.value
      .authoredString;
  final type = value.value.actualType;
  if (type == _iconifyUse) {
    return switch (field("value")) {
      final name? => skir.Icon.wrapIconify(name),
      null => null,
    };
  }
  if (type == _svgIconUse) {
    return switch (field("source")) {
      final source? => skir.Icon.wrapSvg(source),
      null => null,
    };
  }
  return null;
}
