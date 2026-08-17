import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/typewriter_panel.dart";

void main() {
  group("header composition", () {
    test("outer metadata and items override matching inner variants", () {
      final inner = PresentationHeader(
        title: "Inner".asStringLiteral.asHeaderTitle,
        description: "Description".asStringLiteral,
        initiallyExpanded: false,
        contentPadding: const PresentationInsets.only(left: 6),
        items: [
          HeaderBooleanToggleItem(
            id: listAddHeaderItemId,
            label: "inner".asStringLiteral,
            checked: const TypedExpression(
              resultType: BooleanType(),
              expression: LiteralExpression(BooleanValue(true)),
            ),
            action: const RealmEditorAction(ReloadRealmAction()),
          ),
        ],
      );
      final outer = PresentationHeader(
        title: "Outer".asStringLiteral.asHeaderTitle,
        headerPadding: const PresentationInsets.only(top: 3),
        items: [_action("outer", placement: HeaderActionPlacement.afterTitle)],
      );

      final merged = outer.mergeInner(inner);

      expect(merged.title, "Outer".asStringLiteral.asHeaderTitle);
      expect(merged.description, "Description".asStringLiteral);
      expect(merged.initiallyExpanded, isFalse);
      expect(merged.headerPadding, const PresentationInsets.only(top: 3));
      expect(merged.contentPadding, const PresentationInsets.only(left: 6));
      final item = merged.items.single as HeaderButtonItem;
      expect(item.label, "outer".asStringLiteral);
      expect(item.placement, HeaderActionPlacement.afterTitle);
    });

    test("keeps stable ordering around an overridden item", () {
      const first = HeaderItemId(namespace: "test", name: "first");
      const shared = HeaderItemId(namespace: "test", name: "shared");
      const third = HeaderItemId(namespace: "test", name: "third");
      const fourth = HeaderItemId(namespace: "test", name: "fourth");
      final inner = PresentationHeader(
        items: [
          _action("first", id: first),
          _action("inner", id: shared),
          _action("third", id: third),
        ],
      );
      final outer = PresentationHeader(
        items: [
          HeaderBooleanToggleItem(
            id: shared,
            label: "outer".asStringLiteral,
            checked: const TypedExpression(
              resultType: BooleanType(),
              expression: LiteralExpression(BooleanValue(true)),
            ),
            action: const RealmEditorAction(ReloadRealmAction()),
          ),
          _action("fourth", id: fourth),
        ],
      );

      expect(outer.mergeInner(inner).items.map((item) => item.id), [
        first,
        third,
        shared,
        fourth,
      ]);
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
        ReorderListItemAction(source: _root, newIndex: 0.asSigned64Literal),
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

HeaderButtonItem _action(
  String label, {
  HeaderItemId id = listAddHeaderItemId,
  HeaderActionPlacement placement = HeaderActionPlacement.end,
}) => HeaderButtonItem(
  id: id,
  icon: TypedExpression(
    resultType: NamedType(standardTypeRefs.icon),
    expression: LiteralExpression(
      const IconValue.iconify("mdi:plus").typedValue,
    ),
  ),
  label: label.asStringLiteral,
  placement: placement,
  action: LocalEditorAction(
    SetValueAction(target: _root, value: label.asStringLiteral),
  ),
);

LocalEditorAction _reorder(int source, int destination) => LocalEditorAction(
  ReorderListItemAction(
    source: _root.at(DataPath.root.index(source)),
    newIndex: destination.asSigned64Literal,
  ),
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
