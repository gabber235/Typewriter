import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/testing.dart";

/// The Book item presentation the Kotlin catalog compiled, rendered from its
/// wire material with the appearance the panel binds.
final compiledSdkBookValue = skir.DataValue.serializer.fromBytes(
  base64Decode(
    "c2tpcvgO+Pf4+/fzIGJiYjY0NmIzMDBjZjRkZDJiN2FhYjA1MTg1NGU0ZGQxAfgN9/oG+PMFY29sb3L4Dvj3+Pv38yBjMTVmZTk0"
    "ZDEzZmI0MzE3OTI0YTBhZDIwNzJkZWZlNAH4BfMKNDI4MjMzOTc2NfjzBGljb274Dvj3+Pv38yAzODQ1OTUyYTRkNzE0ZTIzYWQ1"
    "NWYwNzA1MTY2OTkzMAH4Dff3+PMFdmFsdWX4CPMVbWF0ZXJpYWwtc3ltYm9sczpib29r+PMHbGlicmFyefgO+Pj4/PjzCHJlbGF0"
    "aW9u8ypjb20udHlwZXdyaXRlcm1jLmxpYnJhcnkuTGlicmFyeUJvb2tzLkJvb2sB9/v3+Pv38yBjNTI4NTBjMTc1NTg0ZjI4OWUw"
    "YjcwOGI5MGE5NmVhMwH4Evj38ydlZTJhNDg2ZDA5NTA0YWRkYTBiMmFkOTg0OGEwMzFhNTpzZWNvbmT39/MHbGlicmFyefjzBXBh"
    "Z2Vz+A74+Pj8+PMKdHlwZXdyaXRlcvMETGlzdAH3+/j4/PjzCHJlbGF0aW9u8ydjb20udHlwZXdyaXRlcm1jLmxpYnJhcnkuQm9v"
    "a1BhZ2VzLkJvb2sB9/v3+Pz48wZrb3RsaW7zHWNvbS50eXBld3JpdGVybWMubGlicmFyeS5QYWdlAfgP9vjzBHRhZ3P4Dvj4+Pz4"
    "8wp0eXBld3JpdGVy8wNTZXQB9/v4+Pz48whyZWxhdGlvbvMmY29tLnR5cGV3cml0ZXJtYy5saWJyYXJ5LkJvb2tUYWdzLkJvb2sB"
    "9/v3+Pv38yBjZTFhZTI1M2E0MmQ0NTA5OTM1YzQ4YjhlY2JhNjY0YQH4EPb48wV0aXRsZfgI8g==",
  ),
);

void main() {
  final catalog = CheckedEditorCatalog(compiledSdkControlCatalog);
  final book = skir.ResourceId(value: "book:compiled");
  final record = skir.AuthoringRecord(
    configuration: compiledSdkBookRecord.configuration,
    fields: [
      for (final field in compiledSdkBookRecord.fields)
        if (field.name == "title")
          skir.FieldValue(
            name: "title",
            value: skir.DataValue.wrapStringValue("Main story"),
          )
        else
          field,
    ],
  );
  final selected = catalog.selectPresentation(
    record.configuration,
    skir.PresentationRole.item,
  ) as SelectedEditorPresentation;

  testWidgets("a book item shows its title on a cover in its accent color", (
    tester,
  ) async {
    final appearance = catalog.appearanceOf(record);
    final scope = PortablePresentationScope(
      operations: testPortableOperations(),
      bindings: {
        configuredValueBindingId: PortableExpressionBinding(
          value: compiledSdkBookValue,
          location: skir.ValueLocation(resource: book, path: editorRootPath),
          schema: CompletePortablePresentationBinding(
            skir.TypeUse.wrapNamed(
              (record.configuration as skir.TypeSelection_completeWrapper)
                  .value,
            ),
          ),
        ),
        presentationSubjectIdentifierBindingId: book.toExpressionBinding(),
        presentationSubjectAppearanceBindingId: appearance
            .toExpressionBinding(),
      },
      budget: skir.EvaluationBudget(maxSteps: 10000, maxCollectionItems: 1000),
      catalog: catalog,
      queries: PortableExpressionQueries(
        catalog: catalog,
        authored: AuthoringDocument(
          catalog: catalog,
          entries: {book: skir.AuthoringResource(id: book, content: record)},
          links: const [],
        ),
      ),
      resource: book,
      role: skir.PresentationRole.item,
    ).withMaterial(selected.material);
    await tester.pumpPanel(
      const [],
      at: PanelLocation.component(
        SizedBox(
          width: 240,
          height: 333,
          child: PortablePresentationNodeRenderer(
            node: selected.material.layout,
            scope: scope,
            fillAvailableSpace: true,
          ),
        ),
      ),
    );
    expect(find.text("Main story"), findsOneWidget);
    final cover = find.ancestor(
      of: find.text("Main story"),
      matching: find.byType(SurfaceContainer),
    );
    expect(
      tester.widget<SurfaceContainer>(cover.first).decoration.color,
      appearance.accentColor,
    );
    expect(tester.takeException(), isNull);
  });
}
