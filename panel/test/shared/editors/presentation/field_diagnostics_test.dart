import "package:flutter/material.dart";
import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/typewriter_panel.dart";

import "../../../support/test_utils.dart";

void main() {
  testWidgets("rebases owner diagnostics onto a projected input", (
    tester,
  ) async {
    final sourcePath = DataPath.root.field("entry");
    final fieldPath = sourcePath.field("name");

    await tester.pumpTestApp(
      child: PresentationFieldDiagnostics(
        bindingId: const BindingId(7),
        sourcePath: sourcePath,
        diagnostics: [
          TypeDiagnostic(
            code: TypeDiagnosticCode.invalidValue,
            message: "Name is required",
            path: fieldPath,
          ),
          TypeDiagnostic(
            code: TypeDiagnosticCode.invalidValue,
            message: "Outside projection",
            path: DataPath.root.field("other"),
          ),
        ],
        child: Builder(
          builder: (context) {
            final diagnostics = PresentationFieldDiagnostics.maybeOf(context)!
                .exact(
                  BindingReference(
                    bindingId: const BindingId(7),
                    path: DataPath.root.field("name"),
                  ),
                );
            return Text(diagnostics.map((value) => value.message).join(","));
          },
        ),
      ),
    );

    expect(find.text("Name is required"), findsOneWidget);
    expect(find.textContaining("Outside projection"), findsNothing);
  });

  testWidgets("descendant only diagnostics affect subtrees but not fields", (
    tester,
  ) async {
    const binding = BindingReference(bindingId: BindingId(7));
    const diagnostic = TypeDiagnostic(
      code: TypeDiagnosticCode.missingField,
      message: "Nested value is required",
    );

    await tester.pumpTestApp(
      child: PresentationFieldDiagnostics(
        bindingId: binding.bindingId,
        sourcePath: DataPath.root,
        diagnostics: const [],
        descendantDiagnostics: const [diagnostic],
        child: Builder(
          builder: (context) {
            final scope = PresentationFieldDiagnostics.maybeOf(context)!;
            return Text(
              "exact:${scope.exact(binding).length},"
              "subtree:${scope.atOrBelow(binding).length}",
            );
          },
        ),
      ),
    );

    expect(find.text("exact:0,subtree:1"), findsOneWidget);
  });

  testWidgets("changing diagnostic validity preserves field focus", (
    tester,
  ) async {
    final owner = LocalEditor(
      rootType: const StringType(),
      typeCatalog: const TypeCatalog([]),
      value: const StringValue("draft"),
    );
    final diagnostics = ValueNotifier<List<TypeDiagnostic>>([
      const TypeDiagnostic(
        code: TypeDiagnosticCode.invalidValue,
        message: "Value is invalid",
      ),
    ]);
    addTearDown(owner.dispose);
    addTearDown(diagnostics.dispose);

    await tester.pumpTestApp(
      child: ValueListenableBuilder(
        valueListenable: diagnostics,
        builder: (context, value, _) => ComposedEditor(
          model: PresentationModel.editor(
            owner: owner,
            diagnostics: value,
            presentation: PresentationNode(
              id: "focus",
              element: TextInputElement(
                control: BoundControl(
                  binding: const BindingReference(bindingId: BindingId(0)),
                  label: "Value".asStringLiteral,
                ),
              ),
            ),
          ),
        ),
      ),
    );

    final input = find.byType(EditableText);
    await tester.tap(input);
    await tester.pump();
    final focusNode = tester.widget<EditableText>(input).focusNode;
    expect(focusNode.hasFocus, isTrue);

    diagnostics.value = const [];
    await tester.pump();
    expect(tester.widget<EditableText>(input).focusNode, same(focusNode));
    expect(focusNode.hasFocus, isTrue);

    diagnostics.value = [
      const TypeDiagnostic(
        code: TypeDiagnosticCode.invalidValue,
        message: "Value is invalid",
      ),
    ];
    await tester.pump();
    expect(tester.widget<EditableText>(input).focusNode, same(focusNode));
    expect(focusNode.hasFocus, isTrue);
  });
}
