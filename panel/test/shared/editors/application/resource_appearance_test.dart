import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";

/// Appearances evaluate the displays the real Kotlin catalog assembly
/// published for the framework types.
void main() {
  final catalog = CheckedEditorCatalog(compiledSdkControlCatalog);

  test("a Book with a blank title is named Book", () {
    final blank = _withField(
      compiledSdkBookRecord,
      "title",
      skir.DataValue.wrapStringValue(""),
    );
    final titled = _withField(
      compiledSdkBookRecord,
      "title",
      skir.DataValue.wrapStringValue("Main story"),
    );

    expect(catalog.appearanceOf(blank).label, "Book");
    expect(catalog.appearanceOf(titled).label, "Main story");
  });

  test("the most specific declared display names the resource", () {
    final entry = _entry();

    final formulas = catalog.displayFormulasFor(entry.configuration);
    final target = formulas?.target;

    expect(target, isA<skir.ResourceTarget_typeWrapper>());
    expect(
      ((target! as skir.ResourceTarget_typeWrapper).value
              as skir.TypeTemplate_namedWrapper)
          .value
          .definition,
      _elementDefinition,
    );
    expect(catalog.appearanceOf(entry).label, "Welcome to the village");
  });

  test("parts a display does not override read the type display", () {
    final appearance = catalog.appearanceOf(_entry());

    // The element display overrides only the label; accent and icon are the
    // defaults, which read the entry type's own display.
    expect(appearance.accentColor.toARGB32(), 0xFFE74C3C);
    expect(appearance.icon, skir.Icon.wrapIconify("fa6-solid:message"));
  });

  test("a resource without a typed display uses the default display", () {
    final cue = skir.AuthoringRecord(
      configuration: skir.TypeSelection.wrapComplete(
        skir.NamedTypeUse(definition: _cueDefinition, arguments: const []),
      ),
      fields: const [],
    );

    expect(
      catalog.displayFormulasFor(cue.configuration)?.target,
      skir.ResourceTarget.anyResource,
    );
    expect(catalog.appearanceOf(cue).label, "Cue");
  });

  test("a missing resource has no appearance", () {
    final document = _Document(catalog, {
      skir.ResourceId(value: "book"): compiledSdkBookRecord,
    });

    expect(
      resourceAppearanceIn(
        catalog,
        document,
        skir.ResourceId(value: "book"),
      )?.label,
      "Book",
    );
    expect(
      resourceAppearanceIn(
        catalog,
        document,
        skir.ResourceId(value: "removed"),
      ),
      isNull,
    );
  });
}

final _elementDefinition = skir.TypeDefinitionId(
  typeId: skir.TypeId.createQualified(
    namespace: "kotlin",
    name: "com.typewritermc.elements.Element",
  ),
  revision: 1,
);

final _cueDefinition = skir.TypeDefinitionId(
  typeId: skir.TypeId.createQualified(
    namespace: "kotlin",
    name: "com.typewritermc.elements.Cue",
  ),
  revision: 1,
);

skir.AuthoringRecord _entry() => skir.AuthoringRecord(
  configuration: skir.TypeSelection.wrapComplete(
    compiledSdkElementValue.authoredActualType!,
  ),
  fields: compiledSdkElementValue.authoredRecord!.fields,
);

skir.AuthoringRecord _withField(
  skir.AuthoringRecord record,
  String name,
  skir.DataValue value,
) => skir.AuthoringRecord(
  configuration: record.configuration,
  fields: [
    for (final field in record.fields)
      if (field.name == name)
        skir.FieldValue(name: name, value: value)
      else
        field,
  ],
);

final class _Document implements PortableAuthoringView {
  _Document(this.catalog, this.resources);

  final CheckedEditorCatalog catalog;

  @override
  final Map<skir.ResourceId, skir.AuthoringRecord> resources;

  @override
  skir.CatalogGeneration get generation => catalog.snapshot.generation;

  @override
  List<skir.LinkProjection> get links => const [];

  @override
  skir.AuthoringRecord? resource(skir.ResourceId id) => resources[id];

  @override
  PortablePathResult<skir.DataValue> read(skir.ValueLocation location) =>
      const PortablePathUnavailable("Not read by appearances");

  @override
  skir.DataValue defaultValue(skir.TypeUse? type) => skir.DataValue.unfilled;
}
