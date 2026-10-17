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
  test("atomic part observation preserves lexical aliases and can skip body editors", () {
    final part = _node(
      skir.PresentationElement.createPart(
        key: skir.PresentationPartId.defaultInstance,
        body: _field("first", configured),
      ),
    );
    final layout = _node(
      skir.PresentationElement.createScopedBinding(
        binding: _reference(configured, "name"),
        scopeBindingId: configured,
        child: part,
      ),
    );
    AuthoredBindingAddress? observed;
    final independent = AuthoredPresentationIndex.build(
      layout,
      {configured: origin},
      onPart: (node, value, aliases) {
        observed = aliases[configured];
        expect(node, part);
        return false;
      },
    );
    expect(
      observed,
      origin.append([skir.PathSegment.createField(name: "name")]),
    );
    expect(independent.uses, isEmpty);
    final full = AuthoredPresentationIndex.build(layout, {configured: origin});
    expect(full.uses.single.address.fieldBelow(origin), "name");
  });

  test("structural collection owners match concrete items and project descendant editors", () {
    final structural = origin.append([
      skir.PathSegment.createField(name: "rows"),
    ]).items;
    final actual = origin.append([
      skir.PathSegment.createField(name: "rows"),
      skir.PathSegment.createItem(id: skir.ItemId(value: "row1")),
    ]);
    expect(structural.matches(actual), isTrue);
    expect(
      structural
          .append([
            skir.PathSegment.createField(name: "name"),
            skir.PathSegment.createField(name: "first"),
          ])
          .fieldBelow(actual),
      "name",
    );
    expect(structural.matches(origin), isFalse);
    expect(
      actual
          .append([
            skir.PathSegment.createField(name: "name"),
            skir.PathSegment.createField(name: "first"),
          ])
          .fieldBelow(actual),
      "name",
    );
  });

  test("root prefix exclusion preserves prefixes on nested controls", () {
    final owned = origin.append([skir.PathSegment.createField(name: "name")]);
    skir.PresentationNode scoped(skir.PresentationNode child) => _node(
      skir.PresentationElement.createScopedBinding(
        binding: _reference(configured, "name"),
        scopeBindingId: configured,
        child: child,
      ),
    );
    final second = _field("second", configured).toMutable();
    final secondInput =
        (second.element! as skir.PresentationElement_numericInputWrapper).value
            .toMutable();
    secondInput.control =
        (secondInput.control.toFrozen().toMutable()
              ..prefix = _field("third", configured))
            .toFrozen();
    second.element = skir.PresentationElement.wrapNumericInput(
      secondInput.toFrozen(),
    );
    final root = _node(
      skir.PresentationElement.wrapRecordInput(
        (skir.RecordControl.defaultInstance.toMutable()
              ..control = (skir.BoundControl.defaultInstance.toMutable()
                ..binding = _reference(configured, "name")
                ..prefix = scoped(_field("first", configured)))
              ..fieldPresentation = scoped(second.toFrozen()))
            .toFrozen(),
      ),
    );
    final all = AuthoredPresentationIndex.build(root, {configured: origin});
    final replaced = AuthoredPresentationIndex.build(root, {
      configured: origin,
    }, includeRootPrefix: false);
    expect(all.fieldsOf(owned), {"first", "second", "third"});
    expect(replaced.fieldsOf(owned), {"second", "third"});
  });

  test("editable inspection follows invocation arguments sequentially", () {
    final first = skir.ExpressionBindingId(value: "first");
    final second = skir.ExpressionBindingId(value: "second");
    final destinations = <AuthoredBindingAddress?>[];
    AuthoredPresentationIndex.build(
      _node(
        skir.PresentationElement.wrapInvocation(
          skir.PresentationInvocation(
            presentationId: skir.PresentationId(
              namespace: "test",
              name: "callee",
            ),
            arguments: [
              skir.PresentationArgument(
                input: first,
                binding: _reference(configured, "name"),
              ),
              skir.PresentationArgument(
                input: second,
                binding: skir.BindingRef(
                  bindingId: first,
                  path: skir.ValuePath.defaultInstance,
                ),
              ),
            ],
          ),
        ),
      ),
      {configured: origin},
      onEditableBinding: (binding, address) => destinations.add(address),
    );
    final owned = origin.append([skir.PathSegment.createField(name: "name")]);
    expect(destinations, [owned, owned, origin]);
  });

  test("unknown scoped controls remain visible to editable inspection", () {
    final alias = skir.ExpressionBindingId(value: "local");
    final destinations = <AuthoredBindingAddress?>[];
    AuthoredPresentationIndex.build(
      _node(
        skir.PresentationElement.createScopedBinding(
          binding: skir.BindingRef(
            bindingId: skir.ExpressionBindingId(value: "missing"),
            path: skir.ValuePath.defaultInstance,
          ),
          scopeBindingId: alias,
          child: _field("value", alias),
        ),
      ),
      {configured: origin},
      onEditableBinding: (binding, address) => destinations.add(address),
    );
    expect(destinations, [null]);
  });

  test(
    "search summary and result aliases shadow an existing owned binding",
    () {
      final owned = origin.append([skir.PathSegment.createField(name: "name")]);
      final item = _field("value", configured);
      final provider = skir.SearchProvider.wrapStaticValues(
        (skir.StaticSearchProvider.defaultInstance.toMutable()
              ..result = (skir.SearchResultMapping.defaultInstance.toMutable()
                ..bindingId = configured
                ..presentation = item))
            .toFrozen(),
      );
      final destinations = <AuthoredBindingAddress?>[];
      final search = _node(
        skir.PresentationElement.wrapSearchInput(
          (skir.SearchControl.defaultInstance.toMutable()
                ..control = (skir.BoundControl.defaultInstance.toMutable()
                  ..binding = skir.BindingRef(
                    bindingId: configured,
                    path: skir.ValuePath.defaultInstance,
                  ))
                ..summaryBindingId = configured
                ..summary = item
                ..provider = provider)
              .toFrozen(),
        ),
      );
      AuthoredPresentationIndex.build(search, {
        configured: owned,
      }, onEditableBinding: (binding, address) => destinations.add(address));
      expect(destinations.first, owned);
      expect(destinations.length, 3);
      expect(
        destinations.skip(1).map((address) => address?.root),
        everyElement(isNot(origin.root)),
      );
    },
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
    final destinations = <AuthoredBindingAddress?>[];
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
      onEditableBinding: (binding, address) => destinations.add(address),
    );
    AuthoredBindingAddress record(String id) => origin.append([
      skir.PathSegment.createField(name: "items"),
      skir.PathSegment.createItem(id: skir.ItemId(value: id)),
    ]);
    expect(index.fieldsOf(record("first")), {"width", "height"});
    expect(index.fieldsOf(record("second")), {"width"});
    expect(destinations.length, 3);
    for (final address in destinations) {
      expect(address?.root, origin.root);
      expect(
        address?.path.first,
        AuthoredPathStep.exact(skir.PathSegment.createField(name: "items")),
      );
    }
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
