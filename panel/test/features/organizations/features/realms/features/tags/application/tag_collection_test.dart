import "dart:async";

import "package:flutter/material.dart";
import "package:flutter_test/flutter_test.dart" hide Tags;
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:iconify_flutter_plus/icons/heroicons_solid.dart";
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";

import "../../../../../../../support/test_utils.dart";

class _Tags extends CanonicalTags {
  _Tags(this.tags);

  final List<Tag> tags;

  @override
  Future<List<Tag>> build() async => tags;
}

Tag _tag(String id, {List<String> parents = const []}) => Tag(
  tagId: recordId("tag:$id"),
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
      final source = [current, parent, descendant].presentationCollection(
        editingTagId: current.tagId,
        existingParentIds: current.parentIds,
      );

      final snapshot = await source
          .watch(const PresentationCollectionQuery.all())
          .first;

      expect(snapshot.diagnostics, isEmpty);
      expect(_selectable(snapshot, "current"), isFalse);
      expect(_selectable(snapshot, "descendant"), isFalse);
      expect(_selectable(snapshot, "parent"), isTrue);
    },
  );

  test(
    "effective inheritance deduplicates ancestors and retains every path",
    () async {
      final source = [
        _tag("story", parents: ["shared"]),
        _tag("combat", parents: ["shared"]),
        _tag("shared"),
      ].presentationCollection();

      final snapshot = await source
          .watch(
            PresentationCollectionQuery.graph(
              roots: [
                ReferenceValue(recordId("tag:story")),
                ReferenceValue(recordId("tag:combat")),
              ],
              relation: tagInheritsRelationId,
              direction: CollectionGraphDirection.forward,
            ),
          )
          .first;

      expect(snapshot.diagnostics, isEmpty);
      expect(snapshot.rows.map((row) => row.key), [
        ReferenceValue(recordId("tag:shared")),
      ]);
      expect(
        snapshot.paths.map((path) => path.keys),
        containsAll([
          [
            ReferenceValue(recordId("tag:story")),
            ReferenceValue(recordId("tag:shared")),
          ],
          [
            ReferenceValue(recordId("tag:combat")),
            ReferenceValue(recordId("tag:shared")),
          ],
        ]),
      );
    },
  );

  test("Tag multi inspection intersects candidate selectability", () async {
    final first = _tag("first");
    final second = _tag("second");
    final tags = [first, second];
    final selections = [
      _tagSelection(
        first,
        tags.presentationCollection(editingTagId: first.tagId),
      ),
      _tagSelection(
        second,
        tags.presentationCollection(editingTagId: second.tagId),
      ),
    ];

    final result = selections.sharedTagCollection;
    final source = result.valueOrNull!;
    final snapshot = await source
        .watch(const PresentationCollectionQuery.all())
        .first;

    expect(result.diagnostics, isEmpty);
    expect(_selectable(snapshot, "first"), isFalse);
    expect(_selectable(snapshot, "second"), isFalse);
  });

  test(
    "Tag inspector exposes parent collection and collapsed layout",
    () async {
      final tag = _tag("current", parents: ["parent"]);
      final container = ProviderContainer.test(
        overrides: [
          canonicalTagsProvider.overrideWith(
            () => _Tags([tag, _tag("parent")]),
          ),
          organizationIdProvider.overrideWith(
            (ref) => recordId("organization:test"),
          ),
          realmIdProvider.overrideWith((ref) => recordId("realm:test")),
          authoringSessionProvider(
            recordId("organization:test"),
            recordId("realm:test"),
          ).overrideWithValue(
            AuthoringSessionState(sequence: 1, tags: {tag.tagId: tag.toWire()}),
          ),
          userIdProvider.overrideWith((ref) async => "user"),
          natsProvider.overrideWithValue(FakeNatsClient()),
          panelTelemetryProvider.overrideWithValue(
            const AsyncData(NoopPanelTelemetry()),
          ),
        ],
      );
      final subscription = container.listen(
        canonicalTagsProvider,
        (_, _) {},
        fireImmediately: true,
      );
      addTearDown(subscription.close);
      await container.read(canonicalTagsProvider.future);
      container
          .read(selectionProvider.notifier)
          .select(TagIdentifier(tag.tagId));

      final selected = await _selected(container);
      final inspector = selected as TagSelectable;
      final document = inspector.document;
      final resolved = TypeRegistry(document.typeCatalog)
          .resolve(document.rootType as NamedType);
      final root = inspector.presentations.single.root.element as ColumnElement;
      final layoutNode = root.children.singleWhere(
        (node) => node.id == "tag.layout",
      );

      final layout = layoutNode.element as SectionElement;
      final layoutGrid = layout.child.element as GridElement;
      final directParents =
          root.children.singleWhere((node) => node.id == "tag.parents").element
              as ReferenceInputElement;
      final inheritance =
          root.children
                  .singleWhere(
                    (node) => node.id == "tag.inheritance.visibility",
                  )
                  .element
              as ConditionalElement;

      final inheritanceSection = inheritance.whenTrue.element as SectionElement;
      final graph = inheritanceSection.child.element as CollectionGraphElement;

      expect(inspector.collections.single.id, tagCollectionSourceId);
      expect(resolved.diagnostics, isEmpty);
      expect(resolved.valueOrNull, isNotNull);
      expect(document.mergePolicies, {
        DataPath.root.field("parents"): EditorMergePolicy.set,
      });
      expect(directParents.candidatePolicy, tagParentReferencePolicyId);
      expect(directParents.allowReorder, isFalse);
      expect(
        directParents.rejectionDisplay,
        ReferenceRejectionDisplay.disabled,
      );
      expect(
        root.children.map((node) => node.id),
        contains("tag.inheritance.visibility"),
      );
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
      final selected = TagSelectable(
        resource: FakeEditableResource(
          key: EditorResourceKey(scope: null, identity: tag.tagId),
          current: TagEditorSnapshot(tag, 1),
          commit: (_) async =>
              throw StateError("No save in this rendering test"),
        ),
        onDelete: () async =>
            throw StateError("No deletion in this rendering test"),
        id: TagIdentifier(tag.tagId),
        tag: tag,
        revision: 1,
        tagCollection: [tag].presentationCollection(editingTagId: tag.tagId),
      );

      await tester.pumpTestApp(
        child: SizedBox(width: 400, child: _render(selected)),
        settle: false,
      );
      await tester.pump();

      expect(find.text("Direct Parents"), findsOneWidget);
      expect(find.text("Reference search is unavailable"), findsOneWidget);
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

TagSelectable _tagSelection(
  Tag tag,
  PresentationCollectionSource tagCollection,
) => TagSelectable(
  resource: FakeEditableResource(
    key: EditorResourceKey(scope: null, identity: tag.tagId),
    current: TagEditorSnapshot(tag, 1),
    commit: (_) async => throw StateError("No save in this domain test"),
  ),
  onDelete: () async => throw StateError("No delete in this domain test"),
  id: TagIdentifier(tag.tagId),
  tag: tag,
  revision: 1,
  tagCollection: tagCollection,
);

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

DataValue _field(
  PresentationCollectionSnapshot snapshot,
  String id,
  String name,
) {
  final row = snapshot.row(ReferenceValue(recordId("tag:$id")));
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

EditorProtocolRenderer _render(EditableSelectable inspector) =>
    EditorProtocolRenderer(
      envelope: TypedValueEnvelope(
        rootType: (inspector.document.rootType as NamedType).reference,
        rootValue: inspector.document.confirmedValue,
      ),
      typeCatalog: inspector.document.typeCatalog,
      collections: inspector.collections,
      presentations: inspector.presentations,
      presentation: inspector.presentations.single.root,
    );
