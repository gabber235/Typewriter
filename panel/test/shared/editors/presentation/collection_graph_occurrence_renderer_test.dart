import "package:flutter/material.dart";
import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/typewriter_panel.dart";

import "../../../support/test_utils.dart";

const _rowBinding = BindingId(8);
const _childrenBinding = BindingId(9);
const _childBinding = BindingId(10);
const _relation = PresentationCollectionRelationId("links");

void main() {
  testWidgets("stops cyclic roots at their returned occurrence paths", (
    tester,
  ) async {
    final fixture = _fixture([
      _row("a", "Alpha", ["b"]),
      _row("b", "Beta", ["a"]),
    ]);

    await _pumpGraph(
      tester,
      fixture,
      roots: const [StringValue("a"), StringValue("b")],
      maximumDepth: 1,
    );

    expect(find.text("Alpha"), findsNWidgets(2));
    expect(find.text("Beta"), findsNWidgets(2));
    expect(tester.takeException(), isNull);
  });

  testWidgets("keeps depth limits separate for shared row occurrences", (
    tester,
  ) async {
    final fixture = _fixture([
      _row("a", "Alpha", ["b"]),
      _row("b", "Beta", ["shared"]),
      _row("x", "Xray", ["shared"]),
      _row("shared", "Shared", ["tail"]),
      _row("tail", "Tail", []),
    ]);

    await _pumpGraph(
      tester,
      fixture,
      roots: const [StringValue("a"), StringValue("x")],
      maximumDepth: 2,
    );

    expect(find.text("Alpha"), findsOneWidget);
    expect(find.text("Beta"), findsOneWidget);
    expect(find.text("Xray"), findsOneWidget);
    expect(find.text("Shared"), findsNWidgets(2));
    expect(find.text("Tail"), findsOneWidget);
  });

  testWidgets("spaces separate roots without changing recursive chains", (
    tester,
  ) async {
    final fixture = _fixture([
      _row("a", "Alpha", ["b"]),
      _row("b", "Beta", []),
      _row("x", "Xray", ["y"]),
      _row("y", "Yankee", []),
    ]);

    await _pumpGraph(
      tester,
      fixture,
      roots: const [StringValue("a"), StringValue("x")],
      maximumDepth: 2,
      rootSpacing: 12,
    );

    final firstRootBottom = tester.getBottomLeft(find.text("Beta")).dy;
    final secondRootTop = tester.getTopLeft(find.text("Xray")).dy;
    expect(secondRootTop - firstRootBottom, 12);
  });

  testWidgets("keeps sibling child expansion identities independent", (
    tester,
  ) async {
    final fixture = _fixture([
      _row("a", "Alpha", ["b", "c"]),
      _row("b", "Beta", []),
      _row("c", "Charlie", []),
    ]);

    Future<void> pump() => _pumpGraph(
      tester,
      fixture,
      roots: const [StringValue("a")],
      maximumDepth: 2,
      childHeaders: true,
    );

    await pump();
    expect(find.byIcon(Icons.expand_less), findsNWidgets(2));

    await tester.tap(find.text("Child").first);
    await tester.pumpAndSettle();
    await pump();
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.expand_less), findsOneWidget);
    expect(find.byIcon(Icons.expand_more), findsOneWidget);
  });
}

Future<void> _pumpGraph(
  WidgetTester tester,
  _Fixture fixture, {
  required List<DataValue> roots,
  required int maximumDepth,
  double rootSpacing = 0,
  bool childHeaders = false,
}) async {
  final presentation = PresentationNode(
    id: "graph",
    element: CollectionGraphElement(
      sourceId: fixture.source.id,
      roots: const BindingReference(bindingId: BindingId(0)),
      rootSequence: SequencePresentation(
        item: const PresentationNode(
          id: "root",
          element: PresentationSlotElement(slotId: "root"),
        ),
        layout: PresentationSequenceLayout.children(
          PresentationChildrenLayout.column(spacing: rootSpacing),
        ),
      ),
      relation: _relation,
      direction: CollectionGraphDirection.forward,
      node: PresentationNode(
        id: "node",
        element: ColumnElement(
          children: [
            fixture.rowName,
            const PresentationNode(
              id: "children",
              element: PresentationSlotElement(slotId: "children"),
            ),
          ],
        ),
      ),
      childrenBindingId: _childrenBinding,
      childBindingId: _childBinding,
      children: SequencePresentation(
        item: childHeaders
            ? PresentationNode(
                id: "child",
                header: PresentationHeader(
                  title: "Child".asStringLiteral.asHeaderTitle,
                  initiallyExpanded: true,
                ),
                element: const SectionElement(
                  child: PresentationNode(
                    id: "child.content",
                    element: PresentationSlotElement(slotId: "children"),
                  ),
                ),
              )
            : const PresentationNode(
                id: "child",
                element: PresentationSlotElement(slotId: "children"),
              ),
      ),
      maximumDepth: maximumDepth,
    ),
  );
  const root = ResolvedTypeRef(
    id: QualifiedTypeId(namespace: "test", name: "GraphOccurrenceRoot"),
    revision: 1,
  );
  await tester.pumpTestApp(
    child: EditorProtocolRenderer(
      envelope: TypedValueEnvelope(rootType: root, rootValue: ListValue(roots)),
      typeCatalog: const TypeCatalog([
        TypeDefinition(
          id: root,
          kind: NominalTypeKind.concrete,
          representation: ListType(element: StringType()),
        ),
      ]),
      collections: [fixture.source],
      presentation: presentation,
    ),
    settle: false,
  );
  await tester.pump();
}

_Fixture _fixture(List<RecordValue> rows) {
  final rowType = RecordType(
    fields: const {
      "key": TypeField(name: "key", type: StringType()),
      "name": TypeField(name: "name", type: StringType()),
      "links": TypeField(
        name: "links",
        type: ListType(element: StringType()),
      ),
    },
  );
  TypedExpression field(String name, TypeExpression type) => TypedExpression(
    resultType: type,
    expression: FieldAccessExpression(
      target: TypedExpression(
        resultType: rowType,
        expression: const BindingExpression(
          BindingReference(bindingId: _rowBinding),
        ),
      ),
      fieldName: name,
    ),
  );
  return _Fixture(
    source: LocalPresentationCollectionSource(
      id: const PresentationCollectionSourceId("occurrence.nodes"),
      schema: PresentationCollectionSchema(
        rowType: rowType,
        keyType: const StringType(),
        rowBindingId: _rowBinding,
        key: field("key", const StringType()),
        relations: [
          PresentationCollectionRelation(
            id: _relation,
            targets: field("links", const ListType(element: StringType())),
          ),
        ],
      ),
      rows: rows,
      registry: TypeRegistry(const TypeCatalog([])),
    ),
    rowName: PresentationNode(
      id: "name",
      element: TextElement(field("name", const StringType())),
    ),
  );
}

RecordValue _row(String key, String name, List<String> links) => RecordValue({
  "key": StringValue(key),
  "name": StringValue(name),
  "links": ListValue(links.map(StringValue.new).toList()),
});

final class _Fixture {
  const _Fixture({required this.source, required this.rowName});

  final LocalPresentationCollectionSource source;
  final PresentationNode rowName;
}
