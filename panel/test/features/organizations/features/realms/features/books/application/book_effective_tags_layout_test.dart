import "package:flutter/material.dart";
import "package:flutter_test/flutter_test.dart" hide Tags;
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";

import "../../../../../../../support/test_utils.dart";

void main() {
  testWidgets(
    "effective Tags fit a narrow inspector and remain keyboard usable",
    (tester) async {
      final directTag = _tag(
        "tag:direct",
        name: "A moderately long direct Tag name",
        parents: ["tag:inherited"],
      );
      final inheritedTag = _tag(
        "tag:inherited",
        name: "A moderately long inherited Tag name",
      );

      await tester.pumpTestApp(
        child: Center(
          child: SizedBox(
            width: 400,
            child: _renderer([directTag, inheritedTag], [directTag.tagId]),
          ),
        ),
        settle: false,
      );
      await tester.pump();

      expect(tester.takeException(), isNull);
      expect(find.text(directTag.name), findsOneWidget);
      expect(find.text(inheritedTag.name), findsOneWidget);
      expect(find.byType(Chip), findsNothing);
      final directContainer = tester.getSize(
        find.byKey(const ValueKey("book.effectiveTags.unary.container")),
      );
      final inheritedContainer = tester.getSize(
        find.byKey(const ValueKey("book.effectiveTags.leaf.container")),
      );

      expect(directContainer.width, greaterThan(300));
      expect(inheritedContainer.width, directContainer.width);
      expect(directContainer.width, lessThanOrEqualTo(400));
      expect(find.text("Inheritance path"), findsNothing);
      expect(find.text(directTag.name), findsOneWidget);
      expect(find.text(inheritedTag.name), findsOneWidget);
    },
  );

  testWidgets("branching Tags use a collapsed bordered section", (
    tester,
  ) async {
    final directTag = _tag(
      "tag:direct",
      name: "Direct Tag",
      parents: ["tag:first", "tag:second"],
    );
    final first = _tag("tag:first", name: "First parent");
    final second = _tag("tag:second", name: "Second parent");

    await tester.pumpTestApp(
      child: Center(
        child: SizedBox(
          width: 400,
          child: _renderer([directTag, first, second], [directTag.tagId]),
        ),
      ),
      settle: false,
    );
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(find.text("Inheritance path"), findsNothing);
    expect(find.text(directTag.name), findsOneWidget);
    expect(find.text(first.name), findsNothing);
    expect(find.text(first.name, skipOffstage: false), findsOneWidget);
    expect(find.text(second.name, skipOffstage: false), findsOneWidget);

    await tester.tapAt(tester.getCenter(find.text(directTag.name)));
    await tester.pumpAndSettle();

    expect(find.text(first.name), findsOneWidget);
    expect(find.text(second.name), findsOneWidget);
    final leafWidth = tester
        .getSize(
          find.byKey(const ValueKey("book.effectiveTags.leaf.container")).first,
        )
        .width;
    expect(leafWidth, greaterThan(300));
    expect(leafWidth, lessThanOrEqualTo(400));
    final hierarchyLayouts = find.byWidgetPredicate(
      (widget) => widget.runtimeType.toString() == "_HierarchyRenderSurface",
    );

    final strokes = [
      for (final element in hierarchyLayouts.evaluate())
        (element.renderObject as dynamic).debugStrokes,
    ];
    expect(strokes.any((paths) => paths.length == 3), isTrue);
  });

  testWidgets("shared branching ancestors repeat with independent expansion", (
    tester,
  ) async {
    final firstRoot = _tag(
      "tag:firstRoot",
      name: "First root",
      parents: ["tag:shared"],
    );
    final secondRoot = _tag(
      "tag:secondRoot",
      name: "Second root",
      parents: ["tag:shared"],
    );
    final shared = _tag(
      "tag:shared",
      name: "Shared parent",
      parents: ["tag:firstLeaf", "tag:secondLeaf"],
    );
    final firstLeaf = _tag("tag:firstLeaf", name: "First leaf");
    final secondLeaf = _tag("tag:secondLeaf", name: "Second leaf");
    late StateSetter rebuild;

    await tester.pumpTestApp(
      child: StatefulBuilder(
        builder: (context, setState) {
          rebuild = setState;
          return Center(
            child: SizedBox(
              width: 400,
              child: _renderer(
                [firstRoot, secondRoot, shared, firstLeaf, secondLeaf],
                [firstRoot.tagId, secondRoot.tagId],
              ),
            ),
          );
        },
      ),
      settle: false,
    );
    await tester.pump();

    expect(find.text(shared.name), findsNWidgets(2));
    expect(find.text(firstLeaf.name), findsNothing);
    expect(find.text(firstLeaf.name, skipOffstage: false), findsNWidgets(2));

    await tester.tapAt(tester.getCenter(find.text(shared.name).first));
    await tester.pumpAndSettle();

    expect(find.text(firstLeaf.name), findsOneWidget);
    expect(find.text(secondLeaf.name), findsOneWidget);
    expect(find.text(firstLeaf.name, skipOffstage: false), findsNWidgets(2));

    rebuild(() {});
    await tester.pump();

    expect(find.text(firstLeaf.name), findsOneWidget);
    expect(find.text(secondLeaf.name), findsOneWidget);
  });

  testWidgets("hides Effective Tags when the Book has no direct Tags", (
    tester,
  ) async {
    await tester.pumpTestApp(
      child: Center(
        child: SizedBox(width: 400, child: _renderer(const [], const [])),
      ),
      settle: false,
    );
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(find.text("Effective Tags"), findsNothing);
    expect(find.byType(Chip), findsNothing);
  });
}

Tag _tag(String id, {required String name, List<String> parents = const []}) =>
    Tag(
      tagId: skir.ResourceId(value: id.substring(id.indexOf(":") + 1)),
      name: name,
      color: Colors.blue,
      parentIds: parents
          .map(
            (id) => skir.ResourceId(value: id.substring(id.indexOf(":") + 1)),
          )
          .toList(),
      placement: GraphPlacement(x: 0, y: 0, width: 4, height: 1),
    );

EditorProtocolRenderer _renderer(
  List<Tag> tags,
  List<skir.ResourceId> rootTagIds,
) {
  const rootBinding = BindingReference(bindingId: BindingId(0));
  final rootType = ResolvedTypeRef(
    id: const QualifiedTypeId(namespace: "test", name: "bookTags"),
    revision: 1,
  );
  return EditorProtocolRenderer(
    envelope: TypedValueEnvelope(
      rootType: rootType,
      rootValue: ListValue(rootTagIds.map(ReferenceValue.new).toList()),
    ),
    typeCatalog: receivedRealmCatalog([
      ...referenceResourceTypes.definitions,
      TypeDefinition(
        id: rootType,
        kind: NominalTypeKind.concrete,
        representation: ListType(element: _tagReferenceType),
      ),
    ]),
    collections: [_tagCollection(tags)],
    presentation: _effectiveTagGraph(rootBinding),
  );
}

const _rowBinding = BindingId(40);
const _childrenBinding = BindingId(45);
const _childBinding = BindingId(46);
const _source = PresentationCollectionSourceId("realm.tags");
const _relation = PresentationCollectionRelationId("inherits");
final _tagReferenceType = ReferenceType(target: referenceResourceTypes.tag);
final _rowType = RecordType(
  fields: {
    "key": TypeField(name: "key", type: _tagReferenceType),
    "name": const TypeField(name: "name", type: StringType()),
    "color": TypeField(name: "color", type: NamedType(standardTypeRefs.color)),
    "parents": TypeField(
      name: "parents",
      type: ListType(element: _tagReferenceType),
    ),
    "selectable": const TypeField(name: "selectable", type: BooleanType()),
  },
);

PresentationCollectionSource _tagCollection(Iterable<Tag> tags) =>
    LocalPresentationCollectionSource(
      id: _source,
      schema: PresentationCollectionSchema(
        rowType: _rowType,
        rowBindingId: _rowBinding,
        key: _rowField("key", _tagReferenceType),
        selectability: _rowField("selectable", const BooleanType()),
        relations: [
          PresentationCollectionRelation(
            id: _relation,
            targets: _rowField("parents", ListType(element: _tagReferenceType)),
          ),
        ],
      ),
      rows: [
        for (final tag in tags)
          RecordValue({
            "key": ReferenceValue(tag.tagId),
            "name": StringValue(tag.name),
            "color": tag.color.asValue,
            "parents": ListValue(
              tag.parentIds.map(ReferenceValue.new).toList(),
            ),
            "selectable": const BooleanValue(true),
          }),
      ],
      registry: TypeRegistry(
        receivedRealmCatalog([...referenceResourceTypes.definitions]),
      ),
    );

PresentationNode _effectiveTagGraph(BindingReference roots) => PresentationNode(
  id: "book.effectiveTags.graph",
  element: CollectionGraphElement(
    sourceId: _source,
    roots: roots,
    rootSequence: const SequencePresentation(
      item: PresentationNode(
        id: "book.effectiveTags.root",
        element: PresentationSlotElement(slotId: "effective.children"),
      ),
      layout: PresentationSequenceLayout.children(
        PresentationChildrenLayout.column(spacing: 12),
      ),
    ),
    relation: _relation,
    direction: CollectionGraphDirection.forward,
    node: _inheritanceNode(),
    childrenBindingId: _childrenBinding,
    childBindingId: _childBinding,
    children: SequencePresentation(
      item: const PresentationNode(
        id: "book.effectiveTags.child",
        element: PresentationSlotElement(slotId: "effective.children"),
      ),
      layout: PresentationSequenceLayout.hierarchy(_hierarchyLayout()),
    ),
  ),
);

PresentationNode _inheritanceNode() {
  final children = TypedExpression(
    resultType: ListType(element: _rowType),
    expression: const BindingExpression(
      BindingReference(bindingId: _childrenBinding),
    ),
  );
  return PresentationNode(
    id: "book.effectiveTags.node",
    element: ConditionalElement(
      condition: children.length().greaterThanOrEqual(2),
      whenTrue: PresentationNode(
        id: "book.effectiveTags.branch",
        header: PresentationHeader(
          title: PresentationHeaderTitle.presentation(
            _rowContainer("book.effectiveTags.branch.container"),
          ),
          initiallyExpanded: false,
        ),
        element: SectionElement(
          border: PresentationBorder.sides(
            start: PresentationBorderSide(
              color: _rowField("color", NamedType(standardTypeRefs.color)),
              width: 4,
            ),
          ),
          child: const PresentationNode(
            id: "book.effectiveTags.branch.children",
            element: PresentationSlotElement(slotId: "effective.children"),
          ),
        ),
      ),
      whenFalse: PresentationNode(
        id: "book.effectiveTags.flattened",
        element: ConditionalElement(
          condition: children.length().compare(
            ComparisonOperator.equal,
            1.asIntegerLiteral,
          ),
          whenTrue: PresentationNode(
            id: "book.effectiveTags.unary",
            element: ColumnElement(
              crossAxisAlignment: PresentationCrossAxisAlignment.stretch,
              children: [
                PresentationAxisChild.fixed(
                  _rowContainer("book.effectiveTags.unary.container"),
                ),
                const PresentationAxisChild.fixed(
                  PresentationNode(
                    id: "book.effectiveTags.unary.children",
                    element: PresentationSlotElement(
                      slotId: "effective.children",
                    ),
                  ),
                ),
              ],
            ),
          ),
          whenFalse: _rowContainer("book.effectiveTags.leaf.container"),
        ),
      ),
    ),
  );
}

PresentationNode _rowContainer(String id) {
  final color = _rowField("color", NamedType(standardTypeRefs.color));
  return PresentationNode(
    id: id,
    element: ContainerElement(
      border: PresentationBorder.all(PresentationBorderSide(color: color)),
      backgroundColor: color.withAlpha(46),
      radius: const PresentationRadius.small(),
      child: PresentationNode(
        id: "$id.padding",
        element: PaddingElement(
          top: 8,
          start: 12,
          end: 12,
          bottom: 8,
          child: PresentationNode(
            id: "$id.label",
            element: TextElement(
              _rowField("name", const StringType()),
              color: color,
            ),
          ),
        ),
      ),
    ),
  );
}

HierarchySequenceLayout _hierarchyLayout() {
  final rowColor = _rowField("color", NamedType(standardTypeRefs.color));
  final childColor = TypedExpression(
    resultType: NamedType(standardTypeRefs.color),
    expression: BindingExpression(
      BindingReference(
        bindingId: _childBinding,
        path: DataPath.root.field("color"),
      ),
    ),
  );
  ConnectorStyle connector(
    TypedExpression color, {
    double radius = 0,
    ConnectorEndpointMarker? marker,
  }) => ConnectorStyle(
    stroke: ConnectorStroke(color: color, width: 2.asFloatLiteral),
    cornerRadius: radius.asFloatLiteral,
    startMarker: marker,
  );
  return HierarchySequenceLayout(
    unaryConnector: connector(
      childColor,
      marker: ConnectorEndpointMarker.arrow(size: 8.asFloatLiteral),
    ),
    trunkConnector: connector(
      rowColor,
      radius: 8,
      marker: ConnectorEndpointMarker.arrow(size: 10.asFloatLiteral),
    ),
    branchConnector: connector(
      childColor,
      radius: 8,
      marker: ConnectorEndpointMarker.circle(diameter: 6.asFloatLiteral),
    ),
    itemSpacing: 24.asFloatLiteral,
    indentation: 16.asFloatLiteral,
    leadingSpacing: 16.asFloatLiteral,
    itemAnchor: const ConnectorAnchor.center(),
    flattenSingleItem: true.asBooleanLiteral,
  );
}

TypedExpression _rowField(String name, TypeExpression type) => TypedExpression(
  resultType: type,
  expression: BindingExpression(
    BindingReference(bindingId: _rowBinding, path: DataPath.root.field(name)),
  ),
);
