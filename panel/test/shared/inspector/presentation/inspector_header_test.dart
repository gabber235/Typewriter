import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/typewriter_panel.dart";

import "../../../support/test_utils.dart";

void main() {
  testWidgets("managed header follows the local editor draft", (tester) async {
    final owner = TransactionalEditorSource(
      document: EditorDocument(
        rootType: RecordType(
          fields: const {
            "name": TypeField(name: "name", type: StringType()),
            "color": TypeField(
              name: "color",
              type: IntegerType(width: IntegerWidth.unsigned32),
            ),
          },
        ),
        typeCatalog: const TypeCatalog([]),
        confirmedValue: RecordValue({
          "name": "Before".asValue,
          "color": const Color(0xFF112233).asValue,
        }),
        revision: 1,
      ),
      validation: (path, value) => EditorMutationResult.applied(value),
      commitPolicy: EditorCommitPolicy.applyResource,
    );
    addTearDown(owner.dispose);

    await tester.pumpTestApp(
      child: ManagedInspectorHeader(
        id: "header-id",
        owner: owner,
        fallbackName: "Fallback",
        fallbackColor: const Color(0xFF000000),
      ),
    );

    expect(find.text("Before"), findsOneWidget);
    expect(
      tester.widget<Title>(find.byType(Title)).color,
      const Color(0xFF112233),
    );

    owner
      ..update(DataPath.root.field("name"), "After".asValue)
      ..update(DataPath.root.field("color"), const Color(0xFF445566).asValue);
    await tester.pump();

    expect(find.text("After"), findsOneWidget);
    expect(
      tester.widget<Title>(find.byType(Title)).color,
      const Color(0xFF445566),
    );
  });
}
