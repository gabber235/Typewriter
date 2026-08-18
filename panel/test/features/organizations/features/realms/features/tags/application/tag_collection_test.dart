import "dart:async";

import "package:flutter/material.dart";
import "package:flutter_test/flutter_test.dart" hide Tags;
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:iconify_flutter_plus/icons/heroicons_solid.dart";
import "package:typewriter_panel/typewriter_panel.dart";

import "../../../../../../../support/test_utils.dart";

class _Tags extends Tags {
  _Tags(this.tags);

  final List<Tag> tags;

  @override
  Stream<List<Tag>> build() => Stream.value(tags);
}

final _refProvider = Provider<Ref>((ref) => ref);

Tag _tag(String id, {List<String> parents = const []}) => Tag(
  tagId: recordId("tag:$id"),
  revision: 1,
  name: id,
  color: Colors.blue,
  parentIds: parents.map((parent) => recordId("tag:$parent")).toList(),
  placement: const Placement(x: 0, y: 0, width: 4, height: 1),
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    "parent candidates exclude self and descendants while retaining parents",
    () async {
      final current = _tag("current", parents: ["parent"]);
      final parent = _tag("parent");
      final descendant = _tag("descendant", parents: ["current"]);
      final source = tagPresentationCollection(
        [current, parent, descendant],
        editingTagId: current.tagId,
        existingParentIds: current.parentIds,
      );

      final snapshot = await source
          .watch(const PresentationCollectionQuery.all())
          .first;

      expect(snapshot.diagnostics, isEmpty);
      expect(_selectable(snapshot, "current"), isFalse);
      expect(_reason(snapshot, "current"), contains("itself"));
      expect(_selectable(snapshot, "descendant"), isFalse);
      expect(_reason(snapshot, "descendant"), contains("descendant"));
      expect(_selectable(snapshot, "parent"), isTrue);
      expect(_reason(snapshot, "parent"), isNull);
    },
  );

  test(
    "effective inheritance deduplicates ancestors and retains every path",
    () async {
      final source = tagPresentationCollection([
        _tag("story", parents: ["shared"]),
        _tag("combat", parents: ["shared"]),
        _tag("shared"),
      ]);

      final snapshot = await source
          .watch(
            const PresentationCollectionQuery.graph(
              roots: [StringValue("story"), StringValue("combat")],
              relation: tagInheritsRelationId,
              direction: CollectionGraphDirection.forward,
            ),
          )
          .first;

      expect(snapshot.diagnostics, isEmpty);
      expect(snapshot.rows.map((row) => row.key), const [
        StringValue("shared"),
      ]);
      expect(
        snapshot.paths.map((path) => path.keys),
        containsAll([
          const [StringValue("story"), StringValue("shared")],
          const [StringValue("combat"), StringValue("shared")],
        ]),
      );
    },
  );

  test(
    "Tag inspector exposes parent collection and collapsed layout",
    () async {
      final tag = _tag("current", parents: ["parent"]);
      final container = ProviderContainer.test(
        overrides: [
          tagsProvider.overrideWith(() => _Tags([tag, _tag("parent")])),
        ],
      );
      final subscription = container.listen(
        tagsProvider,
        (_, _) {},
        fireImmediately: true,
      );
      addTearDown(subscription.close);
      await container.read(tagsProvider.future);
      container
          .read(selectionProvider.notifier)
          .select(TagIdentifier(tag.tagId));

      final selected = await _selected(container);
      final document = (selected as TagSelectable).document;
      final resolved = TypeRegistry(
        document.typeCatalog,
      ).resolve(document.rootType as NamedType);
      final root = document.presentations.single.root.element as ColumnElement;
      final layoutNode = root.children.singleWhere(
        (node) => node.id == "tag.layout",
      );
      final layout = layoutNode.element as SectionElement;
      final layoutGrid = layout.child.element as GridElement;
      final directParents =
          root.children
                  .singleWhere((node) => node.id == "tag.parents.search")
                  .element
              as SearchInputElement;
      final summary = directParents.summary!.element as RepeatedElement;
      final summaryLookup =
          summary.presentation.item.element as CollectionLookupElement;
      final inheritance =
          root.children
                  .singleWhere(
                    (node) => node.id == "tag.inheritance.visibility",
                  )
                  .element
              as ConditionalElement;
      final inheritanceSection = inheritance.whenTrue.element as SectionElement;
      final graph = inheritanceSection.child.element as CollectionGraphElement;

      expect(document.collections.single.id, tagCollectionSourceId);
      expect(resolved.diagnostics, isEmpty);
      expect(resolved.valueOrNull, isNotNull);
      expect(document.mergePolicies, {
        DataPath.root.field("parents"): EditorMergePolicy.set,
      });
      expect(
        root.children.map((node) => node.id),
        contains("tag.inheritance.visibility"),
      );
      final summaryLayout =
          summary.presentation.layout as PresentationStandardSequenceLayout;
      expect(summaryLayout.layout, isA<PresentationWrapLayout>());
      expect(summary.presentation.empty, isNotNull);
      _expectTagChip(summaryLookup.found.element as ChipElement);
      expect(graph.childrenBindingId, const BindingId(45));
      expect(graph.childBindingId, const BindingId(46));
      final rootSequence =
          graph.rootSequence.layout as PresentationStandardSequenceLayout;
      final rootColumn = rootSequence.layout as PresentationColumnLayout;
      expect(rootColumn.spacing, 12);
      expect(graph.node.presentationSlotIds, {"tag.inheritance.children"});
      final hierarchy =
          graph.children.layout as PresentationHierarchySequenceLayout;
      expect(hierarchy.layout.itemAnchor, isA<CenterConnectorAnchor>());
      expect(
        hierarchy.layout.crossAxisAlignment,
        PresentationCrossAxisAlignment.stretch,
      );
      final branching = graph.node.element as ConditionalElement;
      final branchNode = branching.whenTrue;
      final branch = branchNode.element as SectionElement;
      expect(branch.border, isA<PresentationBorderSides>());
      final branchBorder = branch.border! as PresentationBorderSides;
      expect(branchBorder.top, isNull);
      expect(branchBorder.start?.width, 4);
      expect(branchBorder.end, isNull);
      expect(branchBorder.bottom, isNull);
      expect(branch.child.element, isA<PresentationSlotElement>());
      final branchTitle = branchNode.header!.title;
      expect(branchTitle, isA<PresentationHeaderNodeTitle>());
      final containerNode = (branchTitle! as PresentationHeaderNodeTitle).node;
      expect(containerNode.element, isA<ContainerElement>());

      expect(layoutNode.header!.initiallyExpanded, isFalse);
      expect(layoutGrid.columns, 2);
      expect(layoutGrid.horizontalSpacing, 12);
      expect(layoutGrid.verticalSpacing, 12);
      _expectPositionControl(layoutGrid, "x", "X", "X position");
      _expectPositionControl(layoutGrid, "y", "Y", "Y position");
      _expectDimensionControl(layoutGrid, "width", "Width");
      _expectDimensionControl(layoutGrid, "height", "Height");
    },
  );

  testWidgets(
    "empty parents stay editable while inheritance hides and layout uses a grid",
    (tester) async {
      final tag = _tag("current");
      final container = ProviderContainer.test();
      final selected = TagSelectable(
        ref: container.read(_refProvider),
        id: TagIdentifier(tag.tagId),
        tag: tag,
        tagCollection: tagPresentationCollection([
          tag,
        ], editingTagId: tag.tagId),
      );

      await tester.pumpTestApp(
        child: SizedBox(width: 400, child: _render(selected.document)),
        settle: false,
      );
      await tester.pump();

      expect(find.text("Direct Parents"), findsOneWidget);
      expect(find.text("None selected"), findsOneWidget);
      expect(find.text("Inheritance"), findsNothing);

      await tester.tap(find.text("Layout"));
      await tester.pumpAndSettle();

      expect(find.text("X"), findsOneWidget);
      expect(find.text("Y"), findsOneWidget);
      expect(find.text("X position"), findsNothing);
      expect(find.text("Y position"), findsNothing);
      expect(find.text("Width"), findsOneWidget);
      expect(find.text("Height"), findsOneWidget);
      expect(find.bySemanticsLabel("X position"), findsWidgets);
      expect(find.bySemanticsLabel("Y position"), findsWidgets);

      final fields = tester
          .widgetList<ValidatedTextField<DataValue>>(
            find.byType(ValidatedTextField<DataValue>),
          )
          .toList();
      expect(fields, hasLength(4));
      expect(fields[0].decoration?.prefixIcon, isNotNull);
      expect(fields[1].decoration?.prefixIcon, isNotNull);
      expect(fields[2].decoration?.prefixIcon, isNull);
      expect(fields[2].icon, HeroiconsSolid.hashtag);
      expect(fields[3].decoration?.prefixIcon, isNull);
      expect(fields[3].icon, HeroiconsSolid.hashtag);

      final positions = find
          .byType(ValidatedTextField<DataValue>)
          .evaluate()
          .map((element) => tester.getTopLeft(find.byWidget(element.widget)))
          .toList();
      expect(positions[0].dy, positions[1].dy);
      expect(positions[0].dx, lessThan(positions[1].dx));
      expect(positions[2].dy, positions[3].dy);
      expect(positions[2].dx, lessThan(positions[3].dx));
      expect(positions[2].dy, greaterThan(positions[0].dy));
      expect(tester.takeException(), isNull);
    },
  );
}

void _expectTagChip(ChipElement chip) {
  expect(chip.color, isNotNull);
  final color = chip.color!.expression as BindingExpression;
  expect(color.binding.bindingId, tagCollectionRowBindingId);
  expect(color.binding.path, DataPath.root.field("color"));
}

void _expectPositionControl(
  GridElement grid,
  String field,
  String prefix,
  String semanticLabel,
) {
  final control =
      (grid.children
                  .singleWhere((node) => node.id == "tag.layout.$field")
                  .element
              as NumericInputElement)
          .control;
  expect(control.label, isNull);
  expect(
    (control.prefix!.element as TextElement).value,
    prefix.asStringLiteral,
  );
  expect(control.semanticLabel, semanticLabel.asStringLiteral);
}

void _expectDimensionControl(GridElement grid, String field, String label) {
  final control =
      (grid.children
                  .singleWhere((node) => node.id == "tag.layout.$field")
                  .element
              as NumericInputElement)
          .control;
  expect(control.label, label.asStringLiteral);
  expect(control.prefix, isNull);
  expect(control.semanticLabel, isNull);
}

bool _selectable(PresentationCollectionSnapshot snapshot, String id) {
  final value = _field(snapshot, id, "selectable");
  return (value as BooleanValue).value;
}

String? _reason(PresentationCollectionSnapshot snapshot, String id) {
  final value = _field(snapshot, id, "unavailableReason");
  return switch (value) {
    PolymorphicValue(value: UnitValue()) => null,
    PolymorphicValue(
      value: RecordValue(fields: {"value": StringValue(:final value)}),
    ) =>
      value,
    _ => throw StateError("Unexpected unavailable reason: $value"),
  };
}

DataValue _field(
  PresentationCollectionSnapshot snapshot,
  String id,
  String name,
) {
  final row = snapshot.row(StringValue(id));
  if (row == null) throw StateError("Missing Tag row: $id");
  return (row.value as RecordValue).fields[name]!;
}

Future<Selectable> _selected(ProviderContainer container) async {
  final completer = Completer<Selectable>();
  final subscription = container.listen(selectedProvider, (_, next) {
    if (!completer.isCompleted &&
        next.hasValue &&
        next.requireValue.isNotEmpty) {
      completer.complete(next.requireValue.single);
    } else if (!completer.isCompleted && next.hasError) {
      completer.completeError(next.error!, next.stackTrace);
    }
  }, fireImmediately: true);
  try {
    return await completer.future;
  } finally {
    subscription.close();
  }
}

EditorProtocolRenderer _render(EditorDocument document) =>
    EditorProtocolRenderer(
      envelope: TypedValueEnvelope(
        rootType: (document.rootType as NamedType).reference,
        rootValue: document.confirmedValue,
      ),
      typeCatalog: document.typeCatalog,
      collections: document.collections,
      presentations: document.presentations,
      presentation: document.presentations.single.root,
    );
