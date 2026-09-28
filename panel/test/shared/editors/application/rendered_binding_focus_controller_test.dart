import "package:flutter/material.dart";
import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/typewriter_panel.dart";

void main() {
  testWidgets("focus resolves exact resource identity and projected path", (
    tester,
  ) async {
    final resource = _Resource("entry:one");
    final owner = TransactionalEditorSource(
      document: const EditorDocument(
        rootType: StringType(),
        typeCatalog: TypeCatalog([]),
        confirmedValue: StringValue("value"),
        revision: 1,
      ),
      resource: resource,
    );
    addTearDown(owner.dispose);
    final projected = ProjectedEditOwner(owner, DataPath.root.field("content"));
    final controller = RenderedBindingFocusController();
    final node = FocusNode();
    addTearDown(node.dispose);
    await tester.pumpWidget(
      MaterialApp(
        home: Focus(focusNode: node, child: const SizedBox()),
      ),
    );
    final unregister = controller.register(
      owner: projected,
      reference: BindingReference(
        bindingId: const BindingId(0),
        path: DataPath.root.field("name"),
      ),
      node: node,
    );
    addTearDown(() => unregister?.call());

    expect(
      controller.focus(
        "entry:one",
        DataPath.root.field("content").field("name"),
      ),
      isTrue,
    );
    await tester.pump();
    expect(node.hasFocus, isTrue);
    expect(controller.focus("entry:one", DataPath.root.field("name")), isFalse);
    expect(
      controller.focus(
        "entry:two",
        DataPath.root.field("content").field("name"),
      ),
      isFalse,
    );

    unregister?.call();
    expect(
      controller.focus(
        "entry:one",
        DataPath.root.field("content").field("name"),
      ),
      isFalse,
    );
  });

  testWidgets("pending focus waits for the exact rendered binding", (
    tester,
  ) async {
    final resource = _Resource("entry:source");
    final owner = TransactionalEditorSource(
      document: const EditorDocument(
        rootType: StringType(),
        typeCatalog: TypeCatalog([]),
        confirmedValue: StringValue("value"),
        revision: 1,
      ),
      resource: resource,
    );
    addTearDown(owner.dispose);
    final controller = RenderedBindingFocusController();
    final wrongNode = FocusNode();
    final targetNode = FocusNode();
    addTearDown(wrongNode.dispose);
    addTearDown(targetNode.dispose);
    await tester.pumpWidget(
      MaterialApp(
        home: Column(
          children: [
            Focus(focusNode: wrongNode, child: const SizedBox()),
            Focus(focusNode: targetNode, child: const SizedBox()),
          ],
        ),
      ),
    );

    final targetPath = DataPath.root.field("target");
    controller.requestFocus("entry:source", targetPath);
    final unregisterWrong = controller.register(
      owner: owner,
      reference: BindingReference(
        bindingId: const BindingId(0),
        path: DataPath.root.field("wrong"),
      ),
      node: wrongNode,
    );
    addTearDown(() => unregisterWrong?.call());
    await tester.pump();
    expect(wrongNode.hasFocus, isFalse);

    final unregisterTarget = controller.register(
      owner: owner,
      reference: BindingReference(
        bindingId: const BindingId(1),
        path: targetPath,
      ),
      node: targetNode,
    );
    addTearDown(() => unregisterTarget?.call());
    await tester.pump();
    await tester.pump();
    expect(targetNode.hasFocus, isTrue);
  });
}

final class _Resource implements EditableResource {
  _Resource(this.identity);

  final String identity;

  @override
  EditorResourceKey get key =>
      EditorResourceKey(scope: "test", identity: identity);

  @override
  Set<Object> get reservations => {identity};

  @override
  MutationIntent prepare(
    EditorSnapshot snapshot,
    EditorCommit commit,
    void Function(TypedMutationResult) accept,
  ) => throw UnimplementedError();

  @override
  Future<EditorSnapshot?> refresh() async => null;
}
