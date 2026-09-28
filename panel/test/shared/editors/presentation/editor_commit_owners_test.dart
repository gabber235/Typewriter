import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";

import "../../../support/test_utils.dart";

Future<void> _invokePrimaryAction(WidgetTester tester) async {
  final modifier = isApple
      ? LogicalKeyboardKey.metaLeft
      : LogicalKeyboardKey.controlLeft;
  await tester.sendKeyDownEvent(modifier);
  await tester.sendKeyEvent(LogicalKeyboardKey.enter);
  await tester.sendKeyUpEvent(modifier);
}

void main() {
  testWidgets("contract change exposes explicit draft reconciliation", (
    tester,
  ) async {
    final workspace = LocalWorkSession();
    addTearDown(workspace.dispose);
    final owner = workspace.editor(
      _contractTarget("one", 1),
    ) as TransactionalEditorSource;
    workspace.retain(_contractKey);
    owner.update(DataPath.root, const StringValue("draft"));
    workspace.editor(_contractTarget("two", 2));

    await tester.pumpTestApp(
      child: ComposedEditor(model: PresentationModel.editor(owner: owner)),
    );

    expect(find.text("Editor contract changed"), findsOneWidget);
    expect(find.text("Reconcile draft"), findsOneWidget);
    expect(find.text("Discard and reload"), findsOneWidget);
    await tester.tap(find.text("Reconcile draft"));
    await tester.pump();

    expect(find.text("Editor contract changed"), findsNothing);
    expect(owner.value(DataPath.root).valueOrNull, const StringValue("draft"));
  });

  testWidgets("commit controls appear for work and disappear after discard", (
    tester,
  ) async {
    final owner = TransactionalEditorSource(
      document: const EditorDocument(
        rootType: StringType(),
        typeCatalog: TypeCatalog([]),
        confirmedValue: StringValue("original"),
        revision: 1,
      ),
      commitPolicy: EditorCommitPolicy.applyResource,
      commit: (change) async =>
          MutationSuccess(revision: 2, value: change.rootValue),
    );
    addTearDown(owner.dispose);
    await tester.pumpTestApp(
      child: ComposedEditor(model: PresentationModel.editor(owner: owner)),
    );
    expect(find.text("Apply"), findsNothing);
    owner.update(DataPath.root, const StringValue("draft"));
    await tester.pumpAndSettle();

    expect(find.text("Apply"), findsOneWidget);
    await tester.tap(find.text("Cancel"));
    await tester.pumpAndSettle();
    expect(find.text("Apply"), findsNothing);
  });

  testWidgets("primary action applies the focused single resource", (
    tester,
  ) async {
    final submitted = <DataValue>[];
    final owner = TransactionalEditorSource(
      document: const EditorDocument(
        rootType: StringType(),
        typeCatalog: TypeCatalog([]),
        confirmedValue: StringValue("original"),
        revision: 1,
      ),
      commitPolicy: EditorCommitPolicy.applyResource,
      commit: (change) async {
        submitted.add(change.rootValue);
        return MutationSuccess(revision: 2, value: change.rootValue);
      },
    );
    addTearDown(owner.dispose);
    owner.update(DataPath.root, const StringValue("draft"));

    await tester.pumpTestApp(
      child: ComposedEditor(model: PresentationModel.editor(owner: owner)),
    );
    await tester.tap(find.byType(EditableText));
    await tester.pump();
    await _invokePrimaryAction(tester);
    await tester.pumpAndSettle();

    expect(submitted, [const StringValue("draft")]);
    expect(owner.hasWork, isFalse);
  });

  testWidgets(
    "projected inputs deduplicate by transaction and submit complete values",
    (tester) async {
      final submitted = <DataValue>[];
      final owner = TransactionalEditorSource(
        document: EditorDocument(
          rootType: RecordType(
            fields: const {
              "name": TypeField(name: "name", type: StringType()),
              "target": TypeField(name: "target", type: StringType()),
            },
          ),
          typeCatalog: const TypeCatalog([]),
          confirmedValue: RecordValue({
            "name": const StringValue("host"),
            "target": const StringValue("paper@*"),
          }),
          revision: 1,
        ),
        commitPolicy: EditorCommitPolicy.applyResource,
        commit: (change) async {
          submitted.add(change.rootValue);
          return MutationSuccess(
            revision: change.expectedRevision + 1,
            value: change.rootValue,
          );
        },
      );
      addTearDown(owner.dispose);
      final projected = ProjectedEditOwner(
        owner,
        DataPath.root.field("target"),
      );
      await tester.pumpTestApp(
        child: ComposedEditor(
          model: PresentationModel(
            catalog: const TypeCatalog([]),
            inputs: {
              const BindingId(7): PresentationInput.edit(owner),
              const BindingId(9): PresentationInput.edit(projected),
            },
            root: const PresentationNode(
              id: "commit",
              element: CommitControlsElement(
                binding: BindingReference(bindingId: BindingId(9)),
              ),
            ),
          ),
        ),
      );
      owner.update(DataPath.root.field("name"), const StringValue("renamed"));

      projected.update(DataPath.root, const StringValue("paper@1.23"));
      await tester.pumpAndSettle();
      expect(find.byType(EditorCommitControls), findsOneWidget);
      await tester.tap(find.text("Apply"));
      await tester.pumpAndSettle();
      expect(submitted, [
        RecordValue({
          "name": const StringValue("renamed"),
          "target": const StringValue("paper@1.23"),
        }),
      ]);
    },
  );

  testWidgets("placed and fallback resources keep independent outcomes", (
    tester,
  ) async {
    final attempts = <String>[];
    TransactionalEditorSource resource(String name) {
      final owner = TransactionalEditorSource(
        document: EditorDocument(
          rootType: const StringType(),
          typeCatalog: const TypeCatalog([]),
          confirmedValue: StringValue(name),
          revision: 1,
        ),
        commitPolicy: EditorCommitPolicy.applyResource,
        commit: (change) async {
          attempts.add(name);
          return name == "failed"
              ? MutationInvalid(const [
                  TypeDiagnostic(
                    code: TypeDiagnosticCode.invalidValue,
                    message: "Rejected configuration",
                  ),
                ])
              : MutationSuccess(
                  revision: change.expectedRevision + 1,
                  value: change.rootValue,
                );
        },
      );
      addTearDown(owner.dispose);
      return owner;
    }

    final first = resource("saved");
    final second = resource("failed");
    await tester.pumpTestApp(
      child: ComposedEditor(
        model: PresentationModel(
          catalog: const TypeCatalog([]),
          inputs: {
            const BindingId(1): PresentationInput.edit(first),
            const BindingId(2): PresentationInput.edit(second),
          },
          root: const PresentationNode(
            id: "commit",
            element: CommitControlsElement(
              binding: BindingReference(bindingId: BindingId(1)),
            ),
          ),
          ownerLabels: {second: "Second resource"},
        ),
      ),
    );
    first.update(DataPath.root, const StringValue("first draft"));
    second.update(DataPath.root, const StringValue("second draft"));
    await tester.pumpAndSettle();

    expect(find.byType(EditorCommitControls), findsNWidgets(2));
    expect(find.text("Second resource"), findsOneWidget);
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await _invokePrimaryAction(tester);
    await tester.pumpAndSettle();
    expect(attempts, isEmpty);

    await tester.tap(find.text("Apply").first);
    await tester.pumpAndSettle();
    expect(attempts, ["saved"]);
    expect(first.hasWork, isFalse);
    expect(second.hasWork, isTrue);
    await tester.tap(find.text("Apply").last);

    await tester.pumpAndSettle();
    expect(attempts, ["saved", "failed"]);
    expect(second.hasWork, isTrue);
  });
}

const _contractKey = EditorResourceKey(scope: "contract", identity: "resource");

ResourceEditorTarget _contractTarget(String contract, int revision) {
  final snapshot = _ContractSnapshot(
    contract,
    EditorDocument(
      rootType: const StringType(),
      typeCatalog: const TypeCatalog([]),
      confirmedValue: const StringValue("remote"),
      revision: revision,
    ),
  );
  return ResourceEditorTarget(
    targetId: _contractKey.identity,
    label: "Resource",
    resource: FakeEditableResource(
      key: _contractKey,
      current: snapshot,
      commit: (commit) async => MutationSuccess(
        revision: commit.expectedRevision + 1,
        value: commit.rootValue,
      ),
    ),
    snapshot: snapshot,
    commitPolicy: EditorCommitPolicy.applyResource,
  );
}

final class _ContractSnapshot extends EditorSnapshot
    implements EditorContractSnapshot {
  const _ContractSnapshot(this.contract, this.document);

  final String contract;
  @override
  final EditorDocument document;

  @override
  bool contractCompatibleWith(EditorSnapshot candidate) =>
      candidate is _ContractSnapshot && candidate.contract == contract;
}
