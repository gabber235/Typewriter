import "package:flutter/material.dart";
import "package:flutter_markdown_plus/flutter_markdown_plus.dart";
import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/typewriter_panel.dart";

import "../../../support/test_utils.dart";

void main() {
  testWidgets("renders selectable Markdown through Flutter Markdown Plus", (
    tester,
  ) async {
    const markdown = "# Quest notes\n\nUse **clear objectives**.";

    await tester.pumpTestApp(
      child: _renderer(
        type: const UnitType(),
        value: const UnitValue(),
        presentation: PresentationNode(
          id: "markdown",
          element: MarkdownElement(markdown.asStringLiteral),
        ),
      ),
    );

    final widget = tester.widget<MarkdownBody>(find.byType(MarkdownBody));

    expect(widget.data, markdown);
    expect(widget.selectable, isTrue);
  });

  testWidgets("executes local actions and refreshes bound content", (
    tester,
  ) async {
    final presentation = PresentationNode(
      id: "root",
      element: ColumnElement(
        children: [
          PresentationNode(
            id: "value",
            element: TextElement(
              const TypedExpression(
                resultType: StringType(),
                expression: BindingExpression(_rootBinding),
              ),
            ),
          ),
          PresentationNode(
            id: "set",
            element: ButtonElement(
              label: "Set value".asStringLiteral,
              action: EditorAction.local(
                SetValueAction(
                  target: _rootBinding,
                  value: "after".asStringLiteral,
                ),
              ),
            ),
          ),
        ],
      ),
    );

    await tester.pumpTestApp(
      child: _renderer(
        type: const StringType(),
        value: const StringValue("before"),
        presentation: presentation,
      ),
    );
    expect(find.text("before"), findsOneWidget);

    await tester.tap(find.text("Set value"));
    await tester.pump();

    expect(find.text("after"), findsOneWidget);
    expect(find.text("before"), findsNothing);
  });

  testWidgets("keeps valid siblings when one control is invalid", (
    tester,
  ) async {
    final presentation = PresentationNode(
      id: "root",
      element: ColumnElement(
        children: [
          PresentationNode(
            id: "valid",
            element: TextElement("Still available".asStringLiteral),
          ),
          const PresentationNode(
            id: "invalid",
            element: NumericInputElement(BoundControl(binding: _rootBinding)),
          ),
        ],
      ),
    );

    await tester.pumpTestApp(
      child: _renderer(
        type: const StringType(),
        value: const StringValue("text"),
        presentation: presentation,
      ),
    );

    expect(find.text("Still available"), findsOneWidget);
    expect(
      find.text("Control does not accept its binding type"),
      findsOneWidget,
    );
  });

  testWidgets("renders declared repeated empty content", (tester) async {
    const source = TypedExpression(
      resultType: ListType(element: StringType()),
      expression: BindingExpression(_rootBinding),
    );
    await tester.pumpTestApp(
      child: _renderer(
        type: const ListType(element: StringType()),
        value: const ListValue([]),
        presentation: PresentationNode(
          id: "repeated",
          element: RepeatedElement(
            source: source,
            itemBindingId: const BindingId(1),
            template: PresentationNode(
              id: "item",
              element: TextElement("Item".asStringLiteral),
            ),
            empty: PresentationNode(
              id: "empty",
              element: TextElement("Custom empty content".asStringLiteral),
            ),
          ),
        ),
      ),
    );

    expect(find.text("Custom empty content"), findsOneWidget);
    expect(find.text("No items found"), findsNothing);
  });

  testWidgets("uses conditional content and read only local actions", (
    tester,
  ) async {
    final action = EditorAction.local(
      SetValueAction(target: _rootBinding, value: "changed".asStringLiteral),
    );
    final presentation = PresentationNode(
      id: "root",
      element: ColumnElement(
        children: [
          const PresentationNode(
            id: "conditional",
            element: ConditionalElement(
              condition: TypedExpression(
                resultType: BooleanType(),
                expression: LiteralExpression(BooleanValue(false)),
              ),
              whenTrue: PresentationNode(
                id: "hidden",
                element: TextElement(
                  TypedExpression(
                    resultType: StringType(),
                    expression: LiteralExpression(StringValue("Hidden")),
                  ),
                ),
              ),
            ),
          ),
          PresentationNode(
            id: "readonly",
            element: ButtonElement(
              label: "Read only".asStringLiteral,
              action: action,
            ),
          ),
        ],
      ),
    );

    await tester.pumpTestApp(
      child: _renderer(
        type: const StringType(),
        value: const StringValue("value"),
        presentation: presentation,
        readOnly: true,
      ),
    );

    expect(find.text("Hidden"), findsNothing);
    expect(
      tester
          .widget<FilledButton>(find.widgetWithText(FilledButton, "Read only"))
          .onPressed,
      isNull,
    );
  });

  testWidgets("dispatches realm reload independently of local edit state", (
    tester,
  ) async {
    var reloads = 0;
    final presentation = PresentationNode(
      id: "root",
      element: ButtonElement(
        label: "Reload realm".asStringLiteral,
        action: const EditorAction.realm(ReloadRealmAction()),
      ),
    );

    await tester.pumpTestApp(
      child: _renderer(
        type: const UnitType(),
        value: const UnitValue(),
        presentation: presentation,
        readOnly: true,
        onRealmAction: (action) {
          if (action is ReloadRealmAction) reloads++;
          return const MutationSuccess(revision: 0, value: UnitValue());
        },
      ),
    );

    await tester.tap(find.text("Reload realm"));
    await tester.pump();

    expect(reloads, 1);
  });

  testWidgets("rejects a realm callback with an invalid typed payload", (
    tester,
  ) async {
    var calls = 0;
    const actionId = RealmActionId(namespace: "test", name: "callback");
    final payloadType = ResolvedTypeRef(
      id: const QualifiedTypeId(namespace: "test", name: "Payload"),
      revision: 1,
    );
    final root = ResolvedTypeRef(
      id: const QualifiedTypeId(namespace: "test", name: "Root"),
      revision: 1,
    );

    await tester.pumpTestApp(
      child: EditorProtocolRenderer(
        envelope: TypedValueEnvelope(
          rootType: root,
          rootValue: const UnitValue(),
        ),
        typeCatalog: TypeCatalog([
          TypeDefinition(
            id: root,
            kind: NominalTypeKind.concrete,
            representation: const UnitType(),
          ),
          TypeDefinition(
            id: payloadType,
            kind: NominalTypeKind.concrete,
            representation: const BooleanType(),
          ),
        ]),
        realmActions: [
          RealmActionDefinition(id: actionId, payloadType: payloadType),
        ],
        presentation: PresentationNode(
          id: "callback",
          element: ButtonElement(
            label: "Invoke callback".asStringLiteral,
            action: EditorAction.realm(
              InvokeRealmCallbackAction(
                actionId: actionId,
                payload: "invalid".asStringLiteral,
              ),
            ),
          ),
        ),
        onRealmAction: (action) {
          calls++;
          return const MutationSuccess(revision: 0, value: UnitValue());
        },
      ),
    );

    await tester.tap(find.text("Invoke callback"));
    await tester.pump();

    expect(calls, 0);
    expect(find.textContaining("StringValue is not valid"), findsOneWidget);
  });
}

const _rootBinding = BindingReference(bindingId: BindingId(0));

EditorProtocolRenderer _renderer({
  required TypeExpression type,
  required DataValue value,
  required PresentationNode presentation,
  bool readOnly = false,
  RealmActionExecutor? onRealmAction,
}) {
  final root = ResolvedTypeRef(
    id: const QualifiedTypeId(namespace: "test", name: "root"),
    revision: 1,
  );
  return EditorProtocolRenderer(
    envelope: TypedValueEnvelope(rootType: root, rootValue: value),
    typeCatalog: TypeCatalog([
      TypeDefinition(
        id: root,
        kind: NominalTypeKind.concrete,
        representation: type,
      ),
    ]),
    presentation: presentation,
    readOnly: readOnly,
    onRealmAction: onRealmAction,
  );
}
