import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/testing.dart";

void main() {
  test(
    "the read schema derived from Skir matches the schema Kotlin derives",
    () async {
      final source = await File(
        "../skir-src/editor/v1/fixtures/canonical_read_models.json",
      ).readAsString();
      final expected = [
        for (final definition in jsonDecode(source) as List<Object?>)
          skir.TypeDefinition.serializer.fromJson(definition),
      ];
      expect([
        ...canonicalReadModels.definitions,
        ...canonicalReadModels.frameworkDefinitions,
      ], expected);
    },
  );

  test("an appearance reads its accent as the declared color", () {
    final value = skir.ResourceAppearance(
      label: "Book",
      accent: const Color(0xff336699).toSkirColor(),
      icon: skir.Icon.wrapIconify("lucide:book"),
    ).toExpressionValue();
    expect(value.authoredField("accent"), colorValue(0xff336699));
    expect(
      value.authoredField("icon"),
      iconValue(skir.Icon.wrapIconify("lucide:book")),
    );
    expect(value.authoredField("label")?.authoredString, "Book");
  });

  test("read values round trip through every root", () {
    final display = skir.TypeDisplay(
      name: "Book",
      description: "",
      icon: skir.Icon.wrapSvg("<svg/>"),
      color: skir.Color(argb: -1),
    );
    final published = publishedType(
      typeDefinition("example:Book", namespace: canonicalReadNamespace),
      representation: skir.RepresentationTemplate.createRecord(
        fields: const [],
        form: skir.RecordForm.concrete,
      ),
      display: display,
      searchKey: "book",
    );
    final encoded = canonicalReadModels.project(
      published,
      skir.PublishedType.serializer.typeDescriptor,
      const [],
      () {},
      (_) {},
    );
    expect(
      canonicalReadModels.decode(encoded, skir.PublishedType.serializer),
      published,
    );
  });
}
