import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/testing.dart";

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
      final panel = await tester.showComponent(
        Scaffold(
          body: SingleChildScrollView(
            child: PortablePresentationRenderer(host: host),
          ),
        ),
      );
      expect(visibleFieldValues(), [
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
      await panel.fieldAt(0).submit("  First only  ");
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
                    source: skir.PresentationContextSource.caller,
                    binding: declareBinding(
                      contextId,
                      textType.portableTemplate,
                    ),
                  ),
                ])
              .toFrozen(),
    );
    addTearDown(fixture.dispose);
    await tester.showComponent(
      Scaffold(
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
    expect(visibleFieldValues(), [
      "Welcome",
      "Hello player",
      "Cooldown",
      "10, 20",
    ]);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    "child order survives three inspector layers and a persisted edit",
    (tester) async {
      final fixture = InheritedInspectorLayoutScenario();
      addTearDown(fixture.dispose);
      final panel = await tester.showPresentationHost(
        fixture.host,
        scrolls: true,
      );
      expect(visibleFieldValues(), [
        "Welcome",
        "Hello player",
        "Cooldown",
        "10, 20",
      ]);
      expect(find.text("Entry heading"), findsOneWidget);
      expect(
        tester.getTopLeft(find.text("Entry heading")).dy,
        greaterThan(panel.fieldAt(0).rect.top),
      );
      expect(
        tester.getTopLeft(find.text("Entry heading")).dy,
        lessThan(panel.fieldAt(1).rect.top),
      );
      await panel.fieldAt(0).submit("  Renamed  ");
      expect(fixture.name, "Renamed");
      expect(fixture.writes.last.$1, editorRootPath.field("name"));
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.showPresentationHost(fixture.host, scrolls: true);
      expect(visibleFieldValues().first, "Renamed");
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    "a child message precedes the inherited name and trailing placement",
    (tester) async {
      final fixture = InheritedInspectorLayoutScenario(
        childLayout: inheritedFieldColumn([
          inheritedFieldTextInput(
            "child.message",
            control: inheritedFieldControl(field: "message"),
          ),
          inspectorLayoutRemainder("child.remaining"),
        ], id: "child"),
      );
      addTearDown(fixture.dispose);
      await tester.showPresentationHost(fixture.host, scrolls: true);
      expect(visibleFieldValues(), [
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
    await tester.showPresentationHost(fixture.host, scrolls: true);
    expect(visibleFieldValues(), [
      "Welcome",
      "Hello player",
      "Cooldown",
      "10, 20",
    ]);
    expect(find.text("Entry heading"), findsOneWidget);
  });

  testWidgets(
    "an explicit field after the remainder is reserved before expansion",
    (tester) async {
      final fixture = InheritedInspectorLayoutScenario(
        childLayout: inheritedFieldColumn([
          inspectorLayoutRemainder("child.remaining"),
          inheritedFieldTextInput(
            "child.placement",
            control: inheritedFieldControl(
              field: "placement",
              label: "Child placement",
            ),
          ),
        ], id: "child"),
      );
      addTearDown(fixture.dispose);
      await tester.showPresentationHost(fixture.host, scrolls: true);
      // The remainder leaves placement to the explicit editor after it: the
      // placement shows once, last, under the explicit editor's label.
      expect(visibleFieldValues(), [
        "Welcome",
        "Hello player",
        "Cooldown",
        "10, 20",
      ]);
      expect(visibleTextFields().last.spoken, startsWith("Child placement"));
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
            if (explicit)
              inheritedFieldTextInput(
                "child.placement",
                control: inheritedFieldControl(field: "placement"),
              ),
          ], id: "child"),
        );
        await tester.showPresentationHost(fixture.host, scrolls: true);
        expect(visibleFieldValues(), [
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
      final fixture = InheritedInspectorLayoutScenario(
        childLayout: inheritedFieldColumn([
          inheritedFieldRequest(
            control: inheritedFieldControl(field: "name"),
            id: "child.name",
          ),
          inspectorLayoutRemainder(
            "child.remaining",
            excludedParts: [inspectorDetailsPart],
          ),
        ], id: "child"),
        familyLayout: _detailsFamily,
        familyInheritableNodes: const [
          "family",
          "family.details",
          "family.remaining",
        ],
      );
      addTearDown(fixture.dispose);
      await tester.showPresentationHost(fixture.host, scrolls: true);
      expect(visibleFieldValues(), ["Welcome", "Hello player", "Cooldown"]);
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
      await tester.showPresentationHost(fixture.host, scrolls: true);
      expect(visibleFieldValues(), ["Welcome", "Hello player", "Cooldown"]);
      expect(find.text("Details replaced"), findsOneWidget);
    },
  );

  testWidgets("a retained atomic part reports an overlapping child field", (
    tester,
  ) async {
    final fixture = InheritedInspectorLayoutScenario(
      childLayout: inheritedFieldColumn([
        inheritedFieldRequest(
          control: inheritedFieldControl(field: "name"),
          id: "child.name",
        ),
        inspectorLayoutRemainder("child.remaining"),
      ], id: "child"),
      familyLayout: _detailsFamily,
      familyInheritableNodes: const [
        "family",
        "family.details",
        "family.remaining",
      ],
    );
    addTearDown(fixture.dispose);
    await tester.showPresentationHost(fixture.host, scrolls: true);
    expect(
      find.textContaining("Replace or exclude the whole part"),
      findsWidgets,
    );
    expect(visibleFieldValues(), ["Welcome"]);
  });

  testWidgets("field exclusion cannot partially remove an atomic part", (
    tester,
  ) async {
    final fixture = InheritedInspectorLayoutScenario(
      childLayout: inspectorLayoutRemainder(
        "child.remaining",
        excludedFields: ["name"],
      ),
      familyLayout: _detailsFamily,
      familyInheritableNodes: const [
        "family",
        "family.details",
        "family.remaining",
      ],
    );
    addTearDown(fixture.dispose);
    await tester.showPresentationHost(fixture.host, scrolls: true);
    expect(
      find.textContaining("Replace or exclude the whole part"),
      findsWidgets,
    );
    expect(visibleFieldValues(), isEmpty);
  });

  testWidgets("a hidden explicit part reserves its key and its fields", (
    tester,
  ) async {
    final fixture = InheritedInspectorLayoutScenario(
      childLayout: inheritedFieldColumn([
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
      familyLayout: _detailsFamily,
      familyInheritableNodes: const [
        "family",
        "family.details",
        "family.remaining",
      ],
    );
    addTearDown(fixture.dispose);
    await tester.showPresentationHost(fixture.host, scrolls: true);
    expect(visibleFieldValues(), ["Hello player", "Cooldown"]);
    expect(find.text("Details"), findsNothing);
  });

  testWidgets("a part after the remainder is rendered once", (tester) async {
    final fixture = InheritedInspectorLayoutScenario(
      childLayout: inheritedFieldColumn([
        inspectorLayoutRemainder("child.remaining"),
        inspectorLayoutPart("child.details", inspectorDetailsPart),
      ], id: "child"),
      familyLayout: _detailsFamily,
      familyInheritableNodes: const [
        "family",
        "family.details",
        "family.remaining",
      ],
    );
    addTearDown(fixture.dispose);
    await tester.showPresentationHost(fixture.host, scrolls: true);
    expect(visibleFieldValues(), [
      "Hello player",
      "Cooldown",
      "Welcome",
      "10, 20",
    ]);
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
          scopeBinding: declareBinding(
            inheritedConfiguredValue,
            skir.TypeUse.wrapNamed(inspectorMessageType).portableTemplate,
          ),
          child: inspectorLayoutRemainder("child.remaining"),
        ),
      ),
    );
    addTearDown(fixture.dispose);
    await tester.showPresentationHost(fixture.host, scrolls: true);
    expect(visibleFieldValues(), [
      "Welcome",
      "Hello player",
      "Cooldown",
      "10, 20",
    ]);
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
        inheritedFieldTextInput(
          "family.placement",
          control: inheritedFieldControl(field: "placement"),
        ),
      ], id: "family"),
      familyInheritableNodes: [
        "family",
        "family.name",
        "family.remaining",
        "family.placement",
      ],
    );
    addTearDown(fixture.dispose);
    await tester.showPresentationHost(fixture.host, scrolls: true);
    expect(find.text("Local family title"), findsNothing);
    expect(find.text("Entry heading"), findsOneWidget);
    expect(visibleFieldValues().last, "10, 20");
  });
}

final _detailsFamily = inheritedFieldColumn([
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
], id: "family");
