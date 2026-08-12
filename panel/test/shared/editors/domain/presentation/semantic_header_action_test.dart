import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/typewriter_panel.dart";

void main() {
  group("header composition", () {
    test("outer metadata and actions override matching inner values", () {
      final inner = PresentationHeader(
        title: "Inner".asStringLiteral,
        description: "Description".asStringLiteral,
        initiallyExpanded: false,
        actions: [_action("inner")],
      );
      final outer = PresentationHeader(
        title: "Outer".asStringLiteral,
        actions: [
          _action("outer", placement: HeaderActionPlacement.afterTitle),
        ],
      );

      final merged = outer.mergeInner(inner);

      expect(merged.title, "Outer".asStringLiteral);
      expect(merged.description, "Description".asStringLiteral);
      expect(merged.initiallyExpanded, isFalse);
      expect(merged.actions.single.label, "outer".asStringLiteral);
      expect(merged.actions.single.placement, HeaderActionPlacement.afterTitle);
    });
  });

  group("list mutations", () {
    test("reorders from a lower to a higher final position", () {
      final result = _reorder(0, 2).execute(_context(), registry: null);

      expect(result, isA<MutationSuccess>());
      expect(
        (result as MutationSuccess).value,
        _list(["second", "third", "first"]),
      );
    });

    test("reorders from a higher to a lower final position", () {
      final result = _reorder(2, 0).execute(_context(), registry: null);

      expect(
        (result as MutationSuccess).value,
        _list(["third", "first", "second"]),
      );
    });

    test("keeps the revision for a successful no operation", () {
      final result = _reorder(1, 1).execute(_context(), registry: null);

      expect(result, isA<MutationSuccess>());
      expect((result as MutationSuccess).revision, 7);
      expect(result.value, _list(["first", "second", "third"]));
    });

    test("rejects a destination at the list length", () {
      final result = _reorder(0, 3).execute(_context(), registry: null);

      expect(result, isA<MutationInvalid>());
    });

    test("rejects a source that is not an item binding", () {
      final result = LocalEditorAction(
        ReorderListItemAction(source: _root, newIndex: _integer(0)),
      ).execute(_context(), registry: null);

      expect(result, isA<MutationInvalid>());
    });

    test("appends and duplicates through dedicated actions", () {
      final appended = LocalEditorAction(
        AppendListItemAction(target: _root, value: "fourth".asStringLiteral),
      ).execute(_context(), registry: null);
      final duplicated = LocalEditorAction(
        DuplicateListItemAction(source: _root.at(DataPath.root.index(1))),
      ).execute(_context(), registry: null);

      expect(
        (appended as MutationSuccess).value,
        _list(["first", "second", "third", "fourth"]),
      );
      expect(
        (duplicated as MutationSuccess).value,
        _list(["first", "second", "second", "third"]),
      );
    });
  });
}

const _root = BindingReference(bindingId: BindingId(0));
const _listType = ListType(element: StringType());

EditorHeaderAction _action(
  String label, {
  HeaderActionPlacement placement = HeaderActionPlacement.end,
}) => EditorHeaderAction(
  id: listAddHeaderActionId,
  icon: TypedExpression(
    resultType: NamedType(standardTypeRefs.icon),
    expression: LiteralExpression(
      const IconValue.iconify("mdi:plus").typedValue,
    ),
  ),
  label: label.asStringLiteral,
  placement: placement,
  activation: InvokeHeaderAction(
    LocalEditorAction(
      SetValueAction(target: _root, value: label.asStringLiteral),
    ),
  ),
);

LocalEditorAction _reorder(int source, int destination) => LocalEditorAction(
  ReorderListItemAction(
    source: _root.at(DataPath.root.index(source)),
    newIndex: _integer(destination),
  ),
);

TypedExpression _integer(int value) => TypedExpression(
  resultType: const IntegerType(width: IntegerWidth.signed64),
  expression: LiteralExpression(IntegerValue(BigInt.from(value))),
);

ExpressionContext _context() => ExpressionContext(
  bindings: BindingEnvironment({
    const BindingId(0): BindingSnapshot(
      type: _listType,
      value: _list(["first", "second", "third"]),
      revision: 7,
    ),
  }),
);

ListValue _list(List<String> values) =>
    ListValue([for (final value in values) StringValue(value)]);
