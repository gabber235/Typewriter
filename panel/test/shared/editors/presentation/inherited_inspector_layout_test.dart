import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";

import "../../../support/test_utils.dart";

void main() {
  testWidgets(
    "two record instances reuse the same inspector and part independently",
    (tester) async {
      final fixture = InheritedInspectorLayoutScenario();
      addTearDown(fixture.dispose);
      final records = [fixture.value, fixture.value];
      final ids = [
        skir.ExpressionBindingId(value: "first"),
        skir.ExpressionBindingId(value: "second"),
      ];
      final root = inheritedFieldColumn([
        for (final id in ids)
          presentationNode(
            id.value,
            skir.PresentationElement.createDefaultPresentation(
              control:
                  (skir.BoundControl.mutable()
                        ..binding = skir.BindingRef(
                          bindingId: id,
                          path: editorRootPath,
                        ))
                      .toFrozen(),
              presentationId: null,
            ),
          ),
      ], id: "records");
      final host = BoundPresentationHost(
        catalog: fixture.catalog,
        root: () => root,
        role: skir.PresentationRole.inspector,
        bindings: [
          for (final entry in ids.indexed)
            BoundPresentationBinding(
              id: entry.$2,
              use: skir.TypeUse.wrapNamed(inspectorMessageType),
              read: (path) => records[entry.$1].editorValueAt(path),
              write: (path, value) {
                final changed = records[entry.$1].replaceAt(path, value);
                if (changed case PortablePathValue<skir.DataValue>(
                  value: final next,
                )) {
                  records[entry.$1] = next;
                  return const PortablePresentationWriteResult.applied();
                }
                return PortablePresentationWriteResult.rejected(const []);
              },
            ),
        ],
        budget: skir.EvaluationBudget(maxSteps: 1000, maxCollectionItems: 1000),
      );
      addTearDown(host.dispose);
      await tester.pumpTestApp(
        child: Scaffold(
          body: SingleChildScrollView(
            child: PortablePresentationRenderer(host: host),
          ),
        ),
      );
      expect(_values(tester), [
        "Welcome",
        "Hello player",
        "Cooldown",
        "10, 20",
        "Welcome",
        "Hello player",
        "Cooldown",
        "10, 20",
      ]);
      expect(find.text("Entry heading"), findsNWidgets(2));
      await tester.enterText(
        find.byType(TextFormField).first,
        "  First only  ",
      );
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();
      expect(records.first.authoredField("name")?.authoredString, "First only");
      expect(records.last.authoredField("name")?.authoredString, "Welcome");
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets("inherited parts import their own context dependencies", (
    tester,
  ) async {
    final contextId = skir.ExpressionBindingId(value: "context:test.heading");
    final textType = skir.TypeUse.wrapScalar(skir.ScalarKind.text);
    final fixture = InheritedInspectorLayoutScenario(
      sourceLayout: inheritedFieldColumn([
        inspectorLayoutPart(
          "source.heading",
          inspectorHeadingPart,
          body: presentationNode(
            "source.body",
            skir.PresentationElement.wrapText(
              (skir.TextContent.mutable()
                    ..value = skir.ExpressionNode.createInput(
                      binding: contextId,
                      path: editorRootPath,
                    ))
                  .toFrozen(),
            ),
          ),
        ),
        inspectorLayoutRemainder("source.remaining"),
      ], id: "source"),
      sourceInheritableNodes: ["source", "source.heading", "source.remaining"],
      sourceDependencies:
          (skir.PresentationDependencies.mutable()
                ..contextInputs = [
                  skir.PresentationContextInput(
                    bindingId: contextId,
                    valueType: textType,
                  ),
                ])
              .toFrozen(),
    );
    addTearDown(fixture.dispose);
    await tester.pumpTestApp(
      child: Scaffold(
        body: PortablePresentationRenderer(
          host: fixture.host,
          contextBindings: {
            contextId: PortableExpressionBinding(
              value: skir.DataValue.wrapStringValue("Imported heading"),
              schema: CompletePortablePresentationBinding(textType),
            ),
          },
        ),
      ),
    );
    expect(find.text("Imported heading"), findsOneWidget);
    expect(_values(tester), ["Welcome", "Hello player", "Cooldown", "10, 20"]);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    "child order survives three inspector layers and a persisted edit",
    (tester) async {
      final fixture = InheritedInspectorLayoutScenario();
      addTearDown(fixture.dispose);
      await _pump(tester, fixture);
      expect(_values(tester), [
        "Welcome",
        "Hello player",
        "Cooldown",
        "10, 20",
      ]);
      expect(find.text("Entry heading"), findsOneWidget);
      expect(
        tester.getTopLeft(find.text("Entry heading")).dy,
        greaterThan(tester.getTopLeft(find.byType(TextFormField).first).dy),
      );
      expect(
        tester.getTopLeft(find.text("Entry heading")).dy,
        lessThan(tester.getTopLeft(find.byType(TextFormField).at(1)).dy),
      );
      await tester.enterText(find.byType(TextFormField).first, "  Renamed  ");
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();
      expect(fixture.name, "Renamed");
      expect(fixture.writes.last.$1, editorRootPath.field("name"));
      await tester.pumpWidget(const SizedBox.shrink());
      await _pump(tester, fixture);
      expect(_values(tester).first, "Renamed");
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    "a child message precedes the inherited name and trailing placement",
    (tester) async {
      final fixture = InheritedInspectorLayoutScenario(
        childLayout: inheritedFieldColumn([
          _input("child.message", "message"),
          inspectorLayoutRemainder("child.remaining"),
        ], id: "child"),
      );
      addTearDown(fixture.dispose);
      await _pump(tester, fixture);
      expect(_values(tester), [
        "Hello player",
        "Welcome",
        "Cooldown",
        "10, 20",
      ]);
      expect(find.text("Entry heading"), findsOneWidget);
    },
  );

  testWidgets("a remainder alone inherits the field layout", (tester) async {
    final fixture = InheritedInspectorLayoutScenario(
      childLayout: inspectorLayoutRemainder("child.remaining"),
    );
    addTearDown(fixture.dispose);
    await _pump(tester, fixture);
    expect(_values(tester), ["Welcome", "Hello player", "Cooldown", "10, 20"]);
    expect(find.text("Entry heading"), findsOneWidget);
  });

  testWidgets(
    "an explicit field after the remainder is reserved before expansion",
    (tester) async {
      final fixture = InheritedInspectorLayoutScenario(
        childLayout: inheritedFieldColumn([
          inspectorLayoutRemainder("child.remaining"),
          _input("child.placement", "placement"),
        ], id: "child"),
      );
      addTearDown(fixture.dispose);
      await _pump(tester, fixture);
      expect(_values(tester), [
        "Welcome",
        "Hello player",
        "Cooldown",
        "10, 20",
      ]);
    },
  );

  testWidgets(
    "field exclusion removes inherited placement without removing a local editor",
    (tester) async {
      for (final explicit in [false, true]) {
        final fixture = InheritedInspectorLayoutScenario(
          childLayout: inheritedFieldColumn([
            inspectorLayoutRemainder(
              "child.remaining",
              excludedFields: ["placement"],
            ),
            if (explicit) _input("child.placement", "placement"),
          ], id: "child"),
        );
        await _pump(tester, fixture);
        expect(_values(tester), [
          "Welcome",
          "Hello player",
          "Cooldown",
          if (explicit) "10, 20",
        ]);
        await tester.pumpWidget(const SizedBox.shrink());
        fixture.dispose();
      }
    },
  );

  testWidgets(
    "excluded parts reserve their fields but allow an explicit local name",
    (tester) async {
      final fixture = _detailsFixture(
        child: inheritedFieldColumn([
          inheritedFieldRequest(
            control: inheritedFieldControl(field: "name"),
            id: "child.name",
          ),
          inspectorLayoutRemainder(
            "child.remaining",
            excludedParts: [inspectorDetailsPart],
          ),
        ], id: "child"),
      );
      addTearDown(fixture.dispose);
      await _pump(tester, fixture);
      expect(_values(tester), ["Welcome", "Hello player", "Cooldown"]);
      expect(find.text("Details"), findsNothing);
    },
  );

  testWidgets(
    "replacing a whole part retains its inherited fallback reservations",
    (tester) async {
      final fixture = InheritedInspectorLayoutScenario(
        variant: InheritedInspectorLayoutVariant.replacedDetails,
      );
      addTearDown(fixture.dispose);
      await _pump(tester, fixture);
      expect(_values(tester), ["Welcome", "Hello player", "Cooldown"]);
      expect(find.text("Details replaced"), findsOneWidget);
    },
  );

  testWidgets("a retained atomic part reports an overlapping child field", (
    tester,
  ) async {
    final fixture = _detailsFixture(
      child: inheritedFieldColumn([
        inheritedFieldRequest(
          control: inheritedFieldControl(field: "name"),
          id: "child.name",
        ),
        inspectorLayoutRemainder("child.remaining"),
      ], id: "child"),
    );
    addTearDown(fixture.dispose);
    await _pump(tester, fixture);
    expect(
      find.textContaining("Replace or exclude the whole part"),
      findsWidgets,
    );
    expect(_values(tester), ["Welcome"]);
  });

  testWidgets("field exclusion cannot partially remove an atomic part", (
    tester,
  ) async {
    final fixture = _detailsFixture(
      child: inspectorLayoutRemainder(
        "child.remaining",
        excludedFields: ["name"],
      ),
    );
    addTearDown(fixture.dispose);
    await _pump(tester, fixture);
    expect(
      find.textContaining("Replace or exclude the whole part"),
      findsWidgets,
    );
    expect(_values(tester), isEmpty);
  });

  testWidgets("a hidden explicit part reserves its key and its fields", (
    tester,
  ) async {
    final fixture = _detailsFixture(
      child: inheritedFieldColumn([
        presentationNode(
          "hidden",
          skir.PresentationElement.createConditional(
            condition: skir.ExpressionNode.wrapLiteral(
              skir.DataValue.wrapBoolean(false),
            ),
            whenTrue: inspectorLayoutPart(
              "child.details",
              inspectorDetailsPart,
            ),
            whenFalse: null,
          ),
        ),
        inspectorLayoutRemainder("child.remaining"),
      ], id: "child"),
    );
    addTearDown(fixture.dispose);
    await _pump(tester, fixture);
    expect(_values(tester), ["Hello player", "Cooldown"]);
    expect(find.text("Details"), findsNothing);
  });

  testWidgets("a part after the remainder is rendered once", (tester) async {
    final fixture = _detailsFixture(
      child: inheritedFieldColumn([
        inspectorLayoutRemainder("child.remaining"),
        inspectorLayoutPart("child.details", inspectorDetailsPart),
      ], id: "child"),
    );
    addTearDown(fixture.dispose);
    await _pump(tester, fixture);
    expect(_values(tester), ["Hello player", "Cooldown", "Welcome", "10, 20"]);
    expect(find.text("Details"), findsOneWidget);
  });

  testWidgets("a scoped alias preserves the inspector continuation", (
    tester,
  ) async {
    final fixture = InheritedInspectorLayoutScenario(
      childLayout: presentationNode(
        "child.alias",
        skir.PresentationElement.createScopedBinding(
          binding: skir.BindingRef(
            bindingId: inheritedConfiguredValue,
            path: editorRootPath,
          ),
          scopeBindingId: inheritedConfiguredValue,
          child: inspectorLayoutRemainder("child.remaining"),
        ),
      ),
    );
    addTearDown(fixture.dispose);
    await _pump(tester, fixture);
    expect(_values(tester), ["Welcome", "Hello player", "Cooldown", "10, 20"]);
  });

  testWidgets("unmarked source headings stay local", (tester) async {
    final fixture = InheritedInspectorLayoutScenario(
      childLayout: inspectorLayoutRemainder("child.remaining"),
      familyLayout: inheritedFieldColumn([
        presentationText("family.local", textLiteral("Local family title")),
        inheritedFieldRequest(
          control: inheritedFieldControl(field: "name"),
          id: "family.name",
        ),
        inspectorLayoutRemainder("family.remaining"),
        _input("family.placement", "placement"),
      ], id: "family"),
      familyInheritableNodes: [
        "family",
        "family.name",
        "family.remaining",
        "family.placement",
      ],
    );
    addTearDown(fixture.dispose);
    await _pump(tester, fixture);
    expect(find.text("Local family title"), findsNothing);
    expect(find.text("Entry heading"), findsOneWidget);
    expect(_values(tester).last, "10, 20");
  });
}

InheritedInspectorLayoutScenario _detailsFixture({
  required skir.PresentationNode child,
}) => InheritedInspectorLayoutScenario(
  childLayout: child,
  familyLayout: inheritedFieldColumn([
    inspectorLayoutPart(
      "family.details",
      inspectorDetailsPart,
      body: inheritedFieldColumn([
        presentationText("details.title", textLiteral("Details")),
        inheritedFieldRequest(
          control: inheritedFieldControl(field: "name"),
          id: "details.name",
        ),
        inheritedFieldRequest(
          control: inheritedFieldControl(field: "placement"),
          id: "details.placement",
        ),
      ], id: "details"),
    ),
    inspectorLayoutRemainder("family.remaining"),
  ], id: "family"),
  familyInheritableNodes: ["family", "family.details", "family.remaining"],
);

Future<void> _pump(
  WidgetTester tester,
  InheritedInspectorLayoutScenario fixture,
) => tester.pumpTestApp(
  child: Scaffold(
    body: SingleChildScrollView(
      child: PortablePresentationRenderer(host: fixture.host),
    ),
  ),
);

List<String> _values(WidgetTester tester) => tester
    .widgetList<EditableText>(find.byType(EditableText))
    .map((entry) => entry.controller.text)
    .toList();

skir.PresentationNode _input(String id, String field) =>
    inheritedFieldTextInput(id, control: inheritedFieldControl(field: field));
