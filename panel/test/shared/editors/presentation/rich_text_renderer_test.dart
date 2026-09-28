import "package:flutter/material.dart";
import "package:flutter_test/flutter_test.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:typewriter_panel/typewriter_panel.dart";

void main() {
  testWidgets("run style retains inherited variable axes", (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: buildTheme(Brightness.light),
          home: Scaffold(
            body: EditorProtocolRenderer(
              envelope: const TypedValueEnvelope(
                rootType: _root,
                rootValue: UnitValue(),
              ),
              typeCatalog: const TypeCatalog([
                TypeDefinition(
                  id: _root,
                  kind: NominalTypeKind.concrete,
                  representation: UnitType(),
                ),
              ]),
              presentation: PresentationNode(
                id: "richText",
                element: RichTextElement(
                  style: PresentationTextStyle(fontWeight: 650.asFloatLiteral),
                  runs: [
                    PresentationTextRun(
                      text: "Emphasized".asStringLiteral,
                      style: PresentationTextStyle(
                        fontItalic: 1.asFloatLiteral,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );

    final text = tester.widget<Text>(find.byType(Text));
    final root = text.textSpan! as TextSpan;
    final run = root.children!.single as TextSpan;
    expect(run.style?.fontVariations, const [
      FontVariation.weight(650),
      FontVariation.italic(1),
    ]);
  });
}

const _root = ResolvedTypeRef(
  id: QualifiedTypeId(namespace: "test", name: "root"),
  revision: 1,
);
