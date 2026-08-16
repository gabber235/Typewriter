// ignore_for_file: cascade_invocations

import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/typewriter_panel.dart";

void main() {
  test("virtual bindings preserve the canonical interaction path", () {
    BindingReference? started;
    final scope = PresentationRenderScope(
      expressions: const ExpressionContext(bindings: BindingEnvironment({})),
      registry: TypeRegistry(const TypeCatalog([])),
      budget: const ExpressionBudget(),
      setBinding: (_, _, _, _) {},
      executeAction: (_, _, _) {},
      resolvePresentation: (_, _) => null,
      expansionStore: HeaderExpansionStore(),
      startInteraction: (reference) {
        started = reference;
        return _Interaction(reference.path);
      },
    );
    final outer = scope.withVirtualBinding(
      VirtualBindingHost(
        id: const BindingId(1),
        snapshot: const BindingSnapshot(
          type: StringType(),
          value: StringValue("outer"),
          revision: 1,
          writable: true,
        ),
        onChanged: (_) {},
        interactionTarget: BindingReference(
          bindingId: const BindingId(0),
          path: DataPath.root.field("payload"),
        ),
      ),
    );
    final inner = outer.withVirtualBinding(
      VirtualBindingHost(
        id: const BindingId(2),
        snapshot: const BindingSnapshot(
          type: StringType(),
          value: StringValue("inner"),
          revision: 1,
          writable: true,
        ),
        onChanged: (_) {},
        interactionTarget: BindingReference(
          bindingId: const BindingId(1),
          path: DataPath.root.field("nested"),
        ),
      ),
    );

    inner.beginInteraction(
      BindingReference(
        bindingId: const BindingId(2),
        path: DataPath.root.field("value"),
      ),
    );

    expect(started?.bindingId, const BindingId(0));
    expect(
      started?.path,
      DataPath.root.field("payload").field("nested").field("value"),
    );
  });

  test("virtual binding actions use the latest hosted value", () {
    const id = BindingId(1);
    final changed = <DataValue>[];
    final scope =
        PresentationRenderScope(
          expressions: const ExpressionContext(
            bindings: BindingEnvironment({}),
          ),
          registry: TypeRegistry(const TypeCatalog([])),
          budget: const ExpressionBudget(),
          setBinding: (_, _, _, _) {},
          executeAction: (_, _, _) {},
          resolvePresentation: (_, _) => null,
          expansionStore: HeaderExpansionStore(),
        ).withVirtualBinding(
          VirtualBindingHost(
            id: id,
            snapshot: const BindingSnapshot(
              type: ListType(element: StringType()),
              value: ListValue([]),
              revision: 1,
              writable: true,
            ),
            onChanged: changed.add,
          ),
        );

    LocalEditorAction append(String value) {
      return LocalEditorAction(
        AppendListItemAction(
          target: const BindingReference(bindingId: id),
          value: value.asStringLiteral,
        ),
      );
    }

    scope.invoke(append("first"));
    scope.invoke(append("second"));

    expect(changed, const [
      ListValue([StringValue("first")]),
      ListValue([StringValue("first"), StringValue("second")]),
    ]);
  });
}

final class _Interaction implements EditorInteractionSession {
  _Interaction(this.path);

  @override
  final DataPath path;

  @override
  bool active = true;

  @override
  void cancel() => active = false;

  @override
  Future<TypedMutationResult> commit() async {
    active = false;
    return TypedMutationResult.success(
      revision: 1,
      value: const StringValue("saved"),
    );
  }
}
