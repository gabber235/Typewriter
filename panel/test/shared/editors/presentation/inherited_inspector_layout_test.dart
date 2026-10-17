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
      final root = _column("records", [
        for (final id in ids)
          inheritedFieldNode(
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
      ]);
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
      sourceLayout: _column("source", [
        inspectorLayoutPart(
          "source.heading",
          inspectorHeadingPart,
          body: inheritedFieldNode(
            "source.body",
            skir.PresentationElement.wrapText(
              (skir.TextContent.mutable()
                    ..value = skir.ExpressionNode.createRead(
                      binding: contextId,
                      path: editorRootPath,
                    ))
                  .toFrozen(),
            ),
          ),
        ),
        inspectorLayoutRemainder("source.remaining"),
      ]),
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
        childLayout: _column("child", [
          _input("child.message", "message"),
          inspectorLayoutRemainder("child.remaining"),
        ]),
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
        childLayout: _column("child", [
          inspectorLayoutRemainder("child.remaining"),
          _input("child.placement", "placement"),
        ]),
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
          childLayout: _column("child", [
            inspectorLayoutRemainder(
              "child.remaining",
              excludedFields: ["placement"],
            ),
            if (explicit) _input("child.placement", "placement"),
          ]),
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
        child: _column("child", [
          _request("child.name", "name"),
          inspectorLayoutRemainder(
            "child.remaining",
            excludedParts: [inspectorDetailsPart],
          ),
        ]),
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
      child: _column("child", [
        _request("child.name", "name"),
        inspectorLayoutRemainder("child.remaining"),
      ]),
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
      child: _column("child", [
        inheritedFieldNode(
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
      ]),
    );
    addTearDown(fixture.dispose);
    await _pump(tester, fixture);
    expect(_values(tester), ["Hello player", "Cooldown"]);
    expect(find.text("Details"), findsNothing);
  });

  testWidgets("a part after the remainder is rendered once", (tester) async {
    final fixture = _detailsFixture(
      child: _column("child", [
        inspectorLayoutRemainder("child.remaining"),
        inspectorLayoutPart("child.details", inspectorDetailsPart),
      ]),
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
      childLayout: inheritedFieldNode(
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
      familyLayout: _column("family", [
        _text("family.local", "Local family title"),
        _request("family.name", "name"),
        inspectorLayoutRemainder("family.remaining"),
        _input("family.placement", "placement"),
      ]),
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
  familyLayout: _column("family", [
    inspectorLayoutPart(
      "family.details",
      inspectorDetailsPart,
      body: _column("details", [
        _text("details.title", "Details"),
        _request("details.name", "name"),
        _request("details.placement", "placement"),
      ]),
    ),
    inspectorLayoutRemainder("family.remaining"),
  ]),
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

skir.PresentationNode _column(
  String id,
  List<skir.PresentationNode> children,
) => (inheritedFieldColumn(children).toMutable()..nodeId = id).toFrozen();

skir.PresentationNode _request(String id, String field) =>
    (inheritedFieldRequest(
      control: inheritedFieldControl(field: field),
    ).toMutable()..nodeId = id).toFrozen();

skir.PresentationNode _input(String id, String field) =>
    inheritedFieldTextInput(id, control: inheritedFieldControl(field: field));

skir.PresentationNode _text(String id, String value) => inheritedFieldNode(
  id,
  skir.PresentationElement.wrapText(
    (skir.TextContent.mutable()..value = inheritedFieldText(value)).toFrozen(),
  ),
);
