import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";

void main() {
  final configured = skir.ExpressionBindingId(value: "configured_value");
  final origin = AuthoredBindingAddress(
    root: AuthoredBindingRoot.local(configured),
    path: const [],
  );
  test(
    "all authored controls reserve fields including both hidden branches",
    () {
      final conditional =
          (skir.ConditionalElement.defaultInstance.toMutable()
                ..condition = skir.ExpressionNode.wrapLiteral(
                  skir.DataValue.wrapBoolean(false),
                )
                ..whenTrue = _field("width", configured)
                ..whenFalse = _field("height", configured))
              .toFrozen();
      final layout = _column([
        _field("X", configured),
        _field("Y", configured),
        _node(skir.PresentationElement.wrapConditional(conditional)),
      ]);
      final index = AuthoredPresentationIndex.build(layout, {
        configured: origin,
      });
      expect(index.fieldsOf(origin), {"X", "Y", "width", "height"});
    },
  );

  test("default providers reserve through their BoundControl without provider discovery", () {
    final reference = _reference(configured, "X");
    final control =
        (skir.BoundControl.defaultInstance.toMutable()..binding = reference)
            .toFrozen();
    final provider =
        (skir.DefaultPresentationElement.defaultInstance.toMutable()
              ..control = control
              ..presentationId = skir.PresentationId(
                namespace: "test",
                name: "number",
              ))
            .toFrozen();
    final index = AuthoredPresentationIndex.build(
      _node(skir.PresentationElement.wrapDefaultPresentation(provider)),
      {configured: origin},
    );
    expect(index.fieldsOf(origin), {"X"});
    expect(index.uses.single.selectedPresentation, provider.presentationId);
  });

  test("nested configured aliases reserve only their own record", () {
    final nested = origin.append([
      skir.PathSegment.createField(name: "position"),
    ]);
    final record =
        (skir.RecordControl.defaultInstance.toMutable()
              ..control = (skir.BoundControl.defaultInstance.toMutable()
                ..binding = _reference(configured, "position"))
              ..fieldPresentation = _node(
                skir.PresentationElement.wrapScopedBinding(
                  skir.ScopedBindingElement(
                    binding: _reference(configured, "position"),
                    scopeBindingId: configured,
                    child: _field("X", configured),
                  ),
                ),
              ))
            .toFrozen();
    final index = AuthoredPresentationIndex.build(
      _column([
        _field("Y", configured),
        _node(skir.PresentationElement.wrapRecordInput(record)),
      ]),
      {configured: origin},
    );
    expect(index.fieldsOf(origin), {"Y", "position"});
    expect(index.fieldsOf(nested), {"X"});
  });

  test("collection templates reserve every item while explicit item paths stay specific", () {
    final item = skir.ExpressionBindingId(value: "item");
    final list =
        (skir.ListControl.defaultInstance.toMutable()
              ..control = (skir.BoundControl.defaultInstance.toMutable()
                ..binding = _reference(configured, "items"))
              ..itemBindingId = item
              ..itemPresentation = _field("width", item))
            .toFrozen();
    final explicit =
        (skir.BoundControl.defaultInstance.toMutable()
              ..binding = skir.BindingRef(
                bindingId: configured,
                path: skir.ValuePath(
                  segments: [
                    skir.PathSegment.createField(name: "items"),
                    skir.PathSegment.createItem(
                      id: skir.ItemId(value: "first"),
                    ),
                    skir.PathSegment.createField(name: "height"),
                  ],
                ),
              ))
            .toFrozen();
    final index = AuthoredPresentationIndex.build(
      _column([
        _node(skir.PresentationElement.wrapListInput(list)),
        _node(
          skir.PresentationElement.wrapNumericInput(
            (skir.NumericControl.defaultInstance.toMutable()
                  ..control = explicit)
                .toFrozen(),
          ),
        ),
      ]),
      {configured: origin},
    );
    AuthoredBindingAddress record(String id) => origin.append([
      skir.PathSegment.createField(name: "items"),
      skir.PathSegment.createItem(id: skir.ItemId(value: id)),
    ]);
    expect(index.fieldsOf(record("first")), {"width", "height"});
    expect(index.fieldsOf(record("second")), {"width"});
  });

  test("unlocated computed scopes retain explicit declaration identity", () {
    final alias = skir.ExpressionBindingId(value: "item");
    final first = AuthoredBindingAddress(
      root: AuthoredBindingRoot.local(alias, origin: "first"),
      path: const [],
    );
    final second = AuthoredBindingAddress(
      root: AuthoredBindingRoot.local(alias, origin: "second"),
      path: const [],
    );
    final index = AuthoredPresentationIndex.build(_field("X", alias), {
      alias: first,
    });
    expect(index.fieldsOf(first), {"X"});
    expect(index.fieldsOf(second), isEmpty);
  });
}

skir.BindingRef _reference(skir.ExpressionBindingId id, String field) =>
    skir.BindingRef(
      bindingId: id,
      path: skir.ValuePath(
        segments: [skir.PathSegment.createField(name: field)],
      ),
    );
skir.PresentationNode _field(String name, skir.ExpressionBindingId id) => _node(
  skir.PresentationElement.wrapNumericInput(
    (skir.NumericControl.defaultInstance.toMutable()
          ..control = (skir.BoundControl.defaultInstance.toMutable()
            ..binding = _reference(id, name)))
        .toFrozen(),
  ),
);
skir.PresentationNode _node(skir.PresentationElement element) =>
    (skir.PresentationNode.defaultInstance.toMutable()
          ..nodeId = element.kind.name
          ..element = element)
        .toFrozen();
skir.PresentationNode _column(List<skir.PresentationNode> nodes) => _node(
  skir.PresentationElement.wrapChildren(
    skir.ChildrenElement.wrapColumn(
      (skir.AxisChildrenElement.defaultInstance.toMutable()
            ..children = nodes.map(skir.AxisChild.wrapFixed))
          .toFrozen(),
    ),
  ),
);
