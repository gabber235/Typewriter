import "dart:async";

import "package:flutter/material.dart";
import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/typewriter_panel.dart";

import "../../../support/test_utils.dart";

const _binding = BindingReference(bindingId: BindingId(7));
const _commit = PresentationNode(
  id: "commit",
  element: CommitControlsElement(binding: _binding),
);
const _other = PresentationNode(
  id: "other",
  element: TextElement(
    TypedExpression(
      resultType: StringType(),
      expression: LiteralExpression(StringValue("Other content")),
    ),
  ),
);

TransactionalEditorSource _owner({EditorCommitter? commit}) {
  final owner = TransactionalEditorSource(
    commitPolicy: EditorCommitPolicy.applyResource,
    document: const EditorDocument(
      rootType: StringType(),
      typeCatalog: TypeCatalog([]),
      confirmedValue: StringValue("original"),
      revision: 1,
    ),
    commit:
        commit ??
        (change) async => MutationSuccess(
          revision: change.expectedRevision + 1,
          value: change.rootValue,
        ),
  );
  addTearDown(owner.dispose);
  owner.update(DataPath.root, const StringValue("draft"));
  return owner;
}

Future<void> _pump(
  WidgetTester tester,
  EditorSource owner,
  PresentationNode root, {
  List<PresentationDefinition> presentations = const [],
  bool readOnly = false,
}) async {
  await tester.pumpTestApp(
    child: ComposedEditor(
      readOnly: readOnly,
      model: PresentationModel(
        catalog: const TypeCatalog([]),
        inputs: {const BindingId(7): PresentationInput.edit(owner)},
        root: root,
        presentations: presentations,
        ownerLabels: {owner: "Fallback configuration"},
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets(
    "inline Apply submits once and Cancel discards the same resource",
    (tester) async {
      final values = <DataValue>[];
      final owner = _owner(
        commit: (change) async {
          values.add(change.rootValue);
          return MutationSuccess(
            revision: change.expectedRevision + 1,
            value: change.rootValue,
          );
        },
      );
      await _pump(tester, owner, _commit);
      expect(find.text("Fallback configuration"), findsNothing);
      expect(find.byType(EditorCommitControls), findsOneWidget);
      owner.update(DataPath.root, const StringValue("changed"));

      await tester.pumpAndSettle();
      await tester.tap(find.text("Apply"));
      await tester.pumpAndSettle();
      expect(values, [const StringValue("changed")]);
      owner.update(DataPath.root, const StringValue("discard"));
      await tester.pumpAndSettle();

      await tester.tap(find.text("Cancel"));
      await tester.pumpAndSettle();
      expect(owner.hasWork, isFalse);
      expect(owner.document.confirmedValue, const StringValue("changed"));
    },
  );

  testWidgets(
    "absent and hidden elements restore fallback without duplicates",
    (tester) async {
      final owner = _owner();
      await _pump(tester, owner, _other);
      expect(find.text("Fallback configuration"), findsOneWidget);
      for (final visible in [true, false, true]) {
        await _pump(
          tester,
          owner,
          PresentationNode(
            id: "conditional",
            element: ConditionalElement(
              condition: visible.asBooleanLiteral,
              whenTrue: _commit,
            ),
          ),
        );
        expect(find.byType(EditorCommitControls), findsOneWidget);
        expect(
          find.text("Fallback configuration"),
          visible ? findsNothing : findsOneWidget,
        );
      }
    },
  );

  testWidgets("duplicate active elements leave one fallback", (tester) async {
    final owner = _owner();
    await _pump(
      tester,
      owner,
      PresentationNode(
        id: "duplicates",
        element: ColumnElement(
          children: [
            _commit,
            const PresentationNode(
              id: "second",
              element: CommitControlsElement(binding: _binding),
            ),
          ],
        ),
      ),
    );
    expect(find.text("Fallback configuration"), findsOneWidget);
    expect(find.byType(EditorCommitControls), findsOneWidget);
    expect(
      find.text(
        "Duplicate commit controls; use the controls at the editor end",
      ),
      findsNWidgets(2),
    );
  });

  testWidgets(
    "inactive retained tabs and collapsed sections cannot claim controls",
    (tester) async {
      final owner = _owner();
      await _pump(
        tester,
        owner,
        PresentationNode(
          id: "tabs",
          element: TabsElement(
            tabs: [
              TabItem(
                id: "first",
                label: "First".asStringLiteral,
                child: _other,
              ),
              TabItem(
                id: "second",
                label: "Second".asStringLiteral,
                child: _commit,
              ),
            ],
          ),
        ),
      );
      expect(find.text("Fallback configuration"), findsOneWidget);
      await tester.tap(find.text("Second"));
      await tester.pumpAndSettle();
      expect(find.text("Fallback configuration"), findsNothing);

      await tester.tap(find.text("First"));
      await tester.pumpAndSettle();
      expect(find.text("Fallback configuration"), findsOneWidget);
      await _pump(
        tester,
        owner,
        PresentationNode(
          id: "section",
          header: PresentationHeader(
            title: "Configuration".asStringLiteral.asHeaderTitle,
            initiallyExpanded: false,
          ),
          element: SectionElement(child: _commit),
        ),
      );
      expect(find.text("Fallback configuration"), findsOneWidget);
      await tester.tap(find.text("Configuration"));

      await tester.pumpAndSettle();
      expect(find.text("Fallback configuration"), findsNothing);
    },
  );

  testWidgets("invocation resolves the caller owner and rejects read inputs", (
    tester,
  ) async {
    final owner = _owner();
    const id = PresentationId(namespace: "test", name: "commit");
    const local = BindingId(0);
    for (final access in [
      PresentationInputAccess.edit,
      PresentationInputAccess.read,
    ]) {
      await _pump(
        tester,
        owner,
        PresentationNode(
          id: "call",
          element: PresentationInvocationElement(
            presentationId: id,
            arguments: {local: _binding},
          ),
        ),
        presentations: [
          PresentationDefinition(
            id: id,
            inputs: [
              PresentationInputParameter(
                id: local,
                name: "config",
                type: const StringType(),
                access: access,
              ),
            ],
            root: const PresentationNode(
              id: "local",
              element: CommitControlsElement(
                binding: BindingReference(bindingId: local),
              ),
            ),
          ),
        ],
      );
      expect(find.byType(EditorCommitControls), findsOneWidget);
      expect(
        find.text("Fallback configuration"),
        access == PresentationInputAccess.edit ? findsNothing : findsOneWidget,
      );
    }
  });

  testWidgets("read only presentation disables inline Apply and Cancel", (
    tester,
  ) async {
    final owner = (_owner())..update(DataPath.root, const StringValue("draft"));
    await _pump(tester, owner, _commit, readOnly: true);
    expect(find.text("Fallback configuration"), findsNothing);
    expect(
      tester
          .widget<TextButton>(find.widgetWithText(TextButton, "Cancel"))
          .onPressed,
      isNull,
    );
    expect(
      tester.widget<LoadingButton>(find.byType(LoadingButton)).onPressed,
      isNull,
    );
  });

  testWidgets("pending Apply keeps an edit invocation mounted", (tester) async {
    final reply = Completer<TypedMutationResult>();
    final owner = _owner(commit: (_) => reply.future);
    const id = PresentationId(namespace: "test", name: "pending");
    const local = BindingId(0);
    const content = "Configuration content";
    await _pump(
      tester,
      owner,
      PresentationNode(
        id: "call",
        element: PresentationInvocationElement(
          presentationId: id,
          arguments: {local: _binding},
        ),
      ),
      presentations: const [
        PresentationDefinition(
          id: id,
          inputs: [
            PresentationInputParameter(
              id: local,
              name: "configuration",
              type: StringType(),
              access: PresentationInputAccess.edit,
            ),
          ],
          root: PresentationNode(
            id: "content",
            element: ColumnElement(
              children: [
                PresentationNode(
                  id: "label",
                  element: TextElement(
                    TypedExpression(
                      resultType: StringType(),
                      expression: LiteralExpression(StringValue(content)),
                    ),
                  ),
                ),
                PresentationNode(
                  id: "commit",
                  element: CommitControlsElement(
                    binding: BindingReference(bindingId: local),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );

    await tester.tap(find.text("Apply"));
    await tester.pump();

    expect(find.text(content), findsOneWidget);
    expect(
      find.text("Presentation input requires editing: configuration"),
      findsNothing,
    );
    expect(
      tester
          .widget<TextButton>(find.widgetWithText(TextButton, "Cancel"))
          .onPressed,
      isNull,
    );
    expect(
      tester.widget<LoadingButton>(find.byType(LoadingButton)).onPressed,
      isNull,
    );

    reply.complete(
      const MutationSuccess(revision: 2, value: StringValue("draft")),
    );
    await tester.pumpAndSettle();
    expect(find.text(content), findsOneWidget);
  });
}
