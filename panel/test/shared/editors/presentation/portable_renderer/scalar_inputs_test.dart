import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/testing.dart";

void main() {
  for (final scenario in [
    (
      name: "integer minus",
      initial: skir.DataValue.wrapInteger("12"),
      partial: "-",
      complete: "-12",
      expected: skir.DataValue.wrapInteger("-12"),
    ),
    (
      name: "decimal point",
      initial: skir.DataValue.wrapDecimal("12.5"),
      partial: ".",
      complete: "-0.5",
      expected: skir.DataValue.wrapDecimal("-0.5"),
    ),
    (
      name: "decimal minus",
      initial: skir.DataValue.wrapDecimal("12.5"),
      partial: "-",
      complete: "-12.75",
      expected: skir.DataValue.wrapDecimal("-12.75"),
    ),
  ]) {
    testWidgets(
      "numeric partial input retains valid value through ${scenario.name}",
      (tester) async {
        final written = <skir.DataValue>[];
        final panel = await tester.showBoundElement(
          skir.PresentationElement.wrapNumericInput(
            (skir.NumericControl.mutable()
                  ..control = presentationControl(_rootReference))
                .toFrozen(),
          ),
          scenario.initial,
          binding: _rootBinding,
          onWrite: written.add,
          rebindWrites: true,
        );
        final field = panel.fieldAt(0);
        await field.type(scenario.partial);
        expect(field.value, scenario.partial);
        expect(written, isEmpty);
        tester.binding.focusManager.primaryFocus?.unfocus();
        await tester.pumpAndSettle();
        expect(written, isEmpty);
        expect(find.text("Enter a valid number"), findsOneWidget);
        await field.type(scenario.complete);
        expect(written, [scenario.expected]);
        await field.type("");
        expect(written, [scenario.expected, skir.DataValue.unfilled]);
      },
    );
  }

  testWidgets("record controls preserve the named record identity", (
    tester,
  ) async {
    (skir.BindingRef, skir.DataValue)? written;
    final placementReference = skir.BindingRef(
      bindingId: _rootBinding,
      path: editorRootPath.field("placement"),
    );
    final host = FakePresentationHost(
      onWrite: (reference, value) {
        written = (reference, value);
      },
      expected: skir.TypeUse.wrapScalar(skir.ScalarKind.text),
    );
    addTearDown(host.dispose);

    await tester.showComponent(
      Builder(
        builder: (_) => Scaffold(
          body: PortablePresentationNodeRenderer(
            node: skir.PresentationNode(
              nodeId: "placement",
              properties: skir.PresentationProperties.defaultInstance,
              element: skir.PresentationElement.wrapRecordInput(
                skir.RecordControl(
                  control: presentationControl(placementReference),
                  fieldPresentation: skir.PresentationNode(
                    nodeId: "placement.x",
                    properties: skir.PresentationProperties.defaultInstance,
                    element: skir.PresentationElement.wrapNumericInput(
                      (skir.NumericControl.mutable()
                            ..control = presentationControl(
                              skir.BindingRef(
                                bindingId: _rootBinding,
                                path: skir.ValuePath(
                                  segments: [
                                    skir.PathSegment.createField(
                                      name: "placement",
                                    ),
                                    skir.PathSegment.createField(name: "x"),
                                  ],
                                ),
                              ),
                            ))
                          .toFrozen(),
                    ),
                    header: null,
                  ),
                  appearance: null,
                  content: null,
                ),
              ),
              header: null,
            ),
            scope: PortablePresentationScope(
              operations: testPortableOperations(),
              bindings: {
                _rootBinding: PortableExpressionBinding(
                  value: skir.DataValue.createRecord(
                    fields: [
                      skir.FieldValue(
                        name: "placement",
                        value: skir.DataValue.createNamed(
                          actualType: _placementType,
                          payload: skir.DataValue.createRecord(
                            fields: [
                              skir.FieldValue(
                                name: "x",
                                value: skir.DataValue.wrapInteger("2"),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  location: skir.ValueLocation(
                    resource: skir.ResourceId(value: "element:one"),
                    path: skir.ValuePath(segments: const []),
                  ),
                ),
              },
              budget: _budget,
              host: host,
            ),
          ),
        ),
      ),
    );

    await FieldDriver.at(tester, 0).type("7");

    expect(written?.$1.path.segments, [
      skir.PathSegment.createField(name: "placement"),
      skir.PathSegment.createField(name: "x"),
    ]);
    expect(written?.$2, skir.DataValue.wrapInteger("7"));
  });

  testWidgets("toggle controls preserve a named scalar identity", (
    tester,
  ) async {
    skir.DataValue? written;
    await tester.showBoundElement(
      toggleInputElement(
        skir.BindingRef(
          bindingId: _rootBinding,
          path: editorRootPath.field("enabled"),
        ),
      ),
      skir.DataValue.createRecord(
        fields: [
          skir.FieldValue(
            name: "enabled",
            value: skir.DataValue.createNamed(
              actualType: _toggleType,
              payload: skir.DataValue.wrapBoolean(false),
            ),
          ),
        ],
      ),
      binding: _rootBinding,
      onWrite: (value) => written = value,
    );

    final toggle = find.semantics.byPredicate(
      (node) =>
          !node.isMergedIntoParent &&
          node.getSemanticsData().flagsCollection.isToggled != Tristate.none,
    );
    await tester.tapAt(toggle.evaluate().single.screenRect.center);
    await tester.pump();

    final named = switch (written) {
      final skir.DataValue_namedWrapper value => value,
      _ => throw TestFailure("Expected a named boolean value"),
    };
    expect(named.value.actualType, _toggleType);
    expect(
      (named.value.payload as skir.DataValue_booleanWrapper).value,
      isTrue,
    );
  });

  testWidgets("an Unfilled boolean offers an explicit repair choice", (
    tester,
  ) async {
    skir.DataValue? written;
    await tester.showBoundElement(
      toggleInputElement(
        skir.BindingRef(
          bindingId: _rootBinding,
          path: editorRootPath.field("enabled"),
        ),
      ),
      skir.DataValue.createRecord(
        fields: [
          skir.FieldValue(name: "enabled", value: skir.DataValue.unfilled),
        ],
      ),
      binding: _rootBinding,
      onWrite: (value) => written = value,
    );

    expect(written, isNull);
    await tester.tap(find.text("On"));
    await tester.pump();

    expect(written, skir.DataValue.wrapBoolean(true));
  });

  test(
    "an Unfilled named scalar is admitted and written with its identity",
    () {
      final alias = typeDefinition("Byte");
      final root = typeDefinition("Root");
      final actual = skir.NamedTypeUse(definition: alias, arguments: const []);
      final location = skir.ValueLocation(
        resource: skir.ResourceId(value: "resource:named"),
        path: editorRootPath.field("count"),
      );
      final generation = skir.CatalogGeneration(value: "catalog:named");
      final checked = CheckedEditorCatalog(
        testCatalogSnapshot(
          generation: generation,
          types: [
            publishedType(
              alias,
              representation: skir.RepresentationTemplate.createScalar(
                kind: skir.ScalarKind.createInteger(
                  width: skir.IntegerWidth.unsignedEight,
                ),
              ),
            ),
            declaredRecord(
              root,
              fields: {
                "count": skir.TypeTemplate.createNamed(
                  definition: alias,
                  arguments: const [],
                ),
              },
            ),
          ],
        ),
      );
      final snapshot = skir.AuthoringState(
        confirmedObservation: skir.AuthoringObservationId(
          value: "fixture:saved",
        ),
        generation: generation,
        resources: [
          skir.AuthoringResource(
            id: location.resource,
            content: skir.AuthoringRecord(
              types: const [],
              configuration: selectionOfUse(
                skir.NamedTypeUse(definition: root, arguments: const []),
              ),
              fields: [
                skir.FieldValue(name: "count", value: skir.DataValue.unfilled),
              ],
            ),
          ),
        ],
        links: const [],
        findings: const [],
      );
      final draft = AuthoringEdit.fromState(snapshot, catalog: checked);
      skir.DataValue? written;
      final reference = skir.BindingRef(
        bindingId: _rootBinding,
        path: location.path,
      );
      final host = BoundPresentationHost(
        catalog: checked,
        root: () => skir.PresentationNode.defaultInstance,
        bindings: [
          BoundPresentationBinding(
            id: _rootBinding,
            use: skir.TypeUse.createNamed(
              definition: root,
              arguments: const [],
            ),
            read: (_) => skir.DataValue.createNamed(
              actualType: skir.NamedTypeUse(
                definition: root,
                arguments: const [],
              ),
              payload: skir.DataValue.createRecord(
                fields: draft.resource(location.resource)!.fields,
              ),
            ),
            write: (_, value) async {
              written = value;
              return const PortablePresentationWriteApplied();
            },
          ),
        ],
        budget: _budget,
      );
      addTearDown(host.dispose);
      final scope = PortablePresentationScope(
        operations: testPortableOperations(),
        bindings: {
          _rootBinding: PortableExpressionBinding(
            value: skir.DataValue.createNamed(
              actualType: skir.NamedTypeUse(
                definition: root,
                arguments: const [],
              ),
              payload: skir.DataValue.createRecord(
                fields: [
                  skir.FieldValue(
                    name: "count",
                    value: skir.DataValue.unfilled,
                  ),
                ],
              ),
            ),
            location: skir.ValueLocation(
              resource: location.resource,
              path: skir.ValuePath(segments: const []),
            ),
            schema: PortablePresentationBindingSchema.complete(
              skir.TypeUse.createNamed(definition: root, arguments: const []),
            ),
          ),
        },
        budget: _budget,
        catalog: checked,
        host: host,
      );

      expect(
        scope.expectedPayloadType(reference),
        skir.TypeUse.wrapScalar(
          skir.ScalarKind.createInteger(width: skir.IntegerWidth.unsignedEight),
        ),
      );
      scope.writePayload(reference, skir.DataValue.wrapInteger("255"));

      final named = switch (written) {
        final skir.DataValue_namedWrapper value => value,
        _ => throw TestFailure("Expected a named scalar value"),
      };
      expect(named.value.actualType, actual);
      expect(named.value.payload, skir.DataValue.wrapInteger("255"));
    },
  );

  testWidgets("an Unfilled duration accepts a value and blank clears it", (
    tester,
  ) async {
    final written = <skir.DataValue>[];
    final panel = await tester.showBoundElement(
      skir.PresentationElement.wrapDurationInput(
        (skir.DurationControl.mutable()
              ..control = presentationControl(_rootReference))
            .toFrozen(),
      ),
      skir.DataValue.unfilled,
      binding: _rootBinding,
      onWrite: written.add,
    );

    final input = panel.fieldAt(0);
    await input.type("1250ms");
    expect(
      written.last,
      skir.DataValue.createDuration(value: skir.Duration(milliseconds: 1250)),
    );
    await input.type("");
    expect(written.last, skir.DataValue.unfilled);
    await input.type("12x");
    expect(written, [
      skir.DataValue.createDuration(value: skir.Duration(milliseconds: 1250)),
      skir.DataValue.unfilled,
    ]);
  });

  testWidgets("an Unfilled byte sequence distinguishes empty from missing", (
    tester,
  ) async {
    final written = <skir.DataValue>[];
    final panel = await tester.showBoundElement(
      skir.PresentationElement.wrapBytesInput(
        (skir.BytesControl.mutable()
              ..control = presentationControl(_rootReference))
            .toFrozen(),
      ),
      skir.DataValue.unfilled,
      binding: _rootBinding,
      onWrite: written.add,
    );

    expect(find.text("This value is Unfilled"), findsOneWidget);
    await panel.tapOn(find.text("Use empty bytes"));
    expect(written.last, skir.DataValue.wrapBytes(skir.ByteString.empty));

    await panel.fieldAt(0).type("0a");
    expect(
      written.last,
      skir.DataValue.wrapBytes(skir.ByteString.fromBase16("0a")),
    );
    await panel.fieldAt(0).type("");
    expect(written.last, skir.DataValue.unfilled);
  });

  testWidgets("an Unfilled color accepts a complete hexadecimal value", (
    tester,
  ) async {
    final written = <skir.DataValue>[];
    final panel = await tester.showBoundElement(
      colorInputElement(_rootReference),
      skir.DataValue.unfilled,
      binding: _rootBinding,
      onWrite: written.add,
      rebindWrites: true,
    );

    expect(find.text(mixedValueReplacementMessage), findsNothing);
    expect(find.text("This value is Unfilled"), findsOneWidget);
    await panel.fieldAt(0).type("#AABBCC");
    expect(written.last, skir.DataValue.wrapInteger(0xFFAABBCC.toString()));
    await panel.fieldAt(0).type("");
    expect(find.text(mixedValueReplacementMessage), findsNothing);
    expect(find.text("This value is Unfilled"), findsOneWidget);
    expect(written, [
      skir.DataValue.wrapInteger(0xFFAABBCC.toString()),
      skir.DataValue.unfilled,
    ]);
  });

  testWidgets(
    "date and time edits preserve values through invalid drafts and clear explicitly",
    (tester) async {
      for (final parts in [(true, false), (false, true), (true, true)]) {
        final written = <skir.DataValue>[];
        final panel = await tester.showBoundElement(
          skir.PresentationElement.wrapDateTimeInput(
            skir.DateTimeControl(
              control: presentationControl(_rootReference),
              includeDate: parts.$1,
              includeTime: parts.$2,
              appearance: null,
              content: null,
              entry: null,
              mappings: null,
              popup: null,
              options: null,
            ),
          ),
          skir.DataValue.wrapTimestamp(DateTime.utc(2024, 8, 12, 18, 30, 45)),
          binding: _rootBinding,
          onWrite: written.add,
          rebindWrites: true,
        );
        final input = panel.fieldAt(0);
        await input.type("2028");
        expect(written, isEmpty);
        final valid = parts.$1 && parts.$2
            ? "2028-02-29 07:06:05"
            : parts.$1
            ? "2028-02-29"
            : "07:06:05";
        await input.type(valid);
        final expected = parts.$1 && parts.$2
            ? DateTime.utc(2028, 2, 29, 7, 6, 5)
            : parts.$1
            ? DateTime.utc(2028, 2, 29, 18, 30, 45)
            : DateTime.utc(2024, 8, 12, 7, 6, 5);
        final filled = skir.DataValue.wrapTimestamp(expected);
        expect(written, [filled]);

        await input.type("");
        expect(find.text(mixedValueReplacementMessage), findsNothing);
        expect(find.text("This value is Unfilled"), findsOneWidget);
        expect(written, [filled, skir.DataValue.unfilled]);
        expect(input.value, isEmpty);
        await tester.testTextInput.receiveAction(TextInputAction.done);
        await tester.pumpAndSettle();
        expect(written, [filled, skir.DataValue.unfilled]);

        await panel.tapOn(find.tooltip("Open picker"));
        final seed = tester
            .widget<DateTimePickerSurface>(find.byType(DateTimePickerSurface))
            .value;
        expect(
          [
            seed.hour,
            seed.minute,
            seed.second,
            seed.millisecond,
            seed.microsecond,
          ],
          [0, 0, 0, 0, 0],
        );
        await panel.tapOn(find.tooltip("Close picker"));
        expect(written, [filled, skir.DataValue.unfilled]);

        await input.type(valid);
        final recovered = parts.$1 && parts.$2
            ? DateTime.utc(2028, 2, 29, 7, 6, 5)
            : parts.$1
            ? DateTime.utc(2028, 2, 29)
            : DateTime.utc(seed.year, seed.month, seed.day, 7, 6, 5);
        expect(written, [
          filled,
          skir.DataValue.unfilled,
          skir.DataValue.wrapTimestamp(recovered),
        ]);
      }
    },
  );

  testWidgets("protected color and timestamp fields reject clearing", (
    tester,
  ) async {
    final fields = [
      (
        colorInputElement(_rootReference),
        skir.DataValue.wrapInteger(0xFFAABBCC.toString()),
      ),
      (
        skir.PresentationElement.wrapDateTimeInput(
          skir.DateTimeControl(
            control: presentationControl(_rootReference),
            includeDate: true,
            includeTime: true,
            appearance: null,
            content: null,
            entry: null,
            mappings: null,
            popup: null,
            options: null,
          ),
        ),
        skir.DataValue.wrapTimestamp(DateTime.utc(2024, 8, 12)),
      ),
    ];
    for (final field in fields) {
      for (final protected in [(true, true), (false, false)]) {
        final written = <skir.DataValue>[];
        await tester.showBoundElement(
          field.$1,
          field.$2,
          binding: _rootBinding,
          onWrite: written.add,
          readOnly: protected.$1,
          enabled: protected.$2,
        );
        await tester.enterText(find.byType(TextFormField), "");
        final editor = tester.widget<ValidatedTextField<dynamic>>(
          find.byWidgetPredicate((widget) => widget is ValidatedTextField),
        );
        editor.onCleared!();
        await tester.pumpAndSettle();
        expect(written, isEmpty);
      }
    }
  });

  testWidgets("an Unfilled slider requires an explicit choice", (tester) async {
    final written = <skir.DataValue>[];
    final panel = await tester.showBoundElement(
      skir.PresentationElement.wrapSliderInput(
        skir.SliderControl(
          control: presentationControl(_rootReference),
          minimum: skir.ExpressionNode.wrapLiteral(skir.DataValue.wrapFloat(2)),
          maximum: skir.ExpressionNode.wrapLiteral(skir.DataValue.wrapFloat(8)),
          divisions: null,
          appearance: null,
          mappings: null,
          options: null,
        ),
      ),
      skir.DataValue.unfilled,
      binding: _rootBinding,
      onWrite: written.add,
      expected: skir.TypeUse.wrapScalar(
        skir.ScalarKind.createFloat(width: skir.FloatWidth.sixtyFour),
      ),
    );

    expect(written, isEmpty);
    expect(find.text("Set to 2"), findsOneWidget);
    await panel.tapOn(find.text("Set to 2"));
    expect(written.last, skir.DataValue.wrapFloat(2));
  });

  testWidgets("an Unfilled time requires a choice before it writes", (
    tester,
  ) async {
    final written = <skir.DataValue>[];
    final panel = await tester.showBoundElement(
      skir.PresentationElement.wrapDateTimeInput(
        skir.DateTimeControl(
          control: presentationControl(_rootReference),
          includeDate: false,
          includeTime: true,
          appearance: null,
          content: null,
          entry: null,
          mappings: null,
          popup: null,
          options: null,
        ),
      ),
      skir.DataValue.unfilled,
      binding: _rootBinding,
      onWrite: written.add,
    );

    expect(written, isEmpty);
    await panel.tapOn(find.tooltip("Open picker"));
    expect(written, isEmpty);
    await panel.tapOn(find.tooltip("Close picker"));
    expect(written, isEmpty);
    await panel.fieldAt(0).type("01:02:03");
    final timestamp = (written.single as skir.DataValue_timestampWrapper).value;
    expect([timestamp.hour, timestamp.minute, timestamp.second], [1, 2, 3]);
  });

  testWidgets("a date before 1970 remains editable", (tester) async {
    final written = <skir.DataValue>[];
    final panel = await tester.showBoundElement(
      skir.PresentationElement.wrapDateTimeInput(
        skir.DateTimeControl(
          control: presentationControl(_rootReference),
          includeDate: true,
          includeTime: false,
          appearance: null,
          content: null,
          entry: null,
          mappings: null,
          popup: null,
          options: null,
        ),
      ),
      skir.DataValue.wrapTimestamp(DateTime.utc(1900, 6, 15)),
      binding: _rootBinding,
      onWrite: written.add,
    );

    await panel.tapOn(find.tooltip("Open picker"));
    expect(tester.takeException(), isNull);
    expect(written, isEmpty);
    await panel.tapOn(find.tooltip("Close picker"));
    await panel.fieldAt(0).type("1900-06-16");
    expect(
      written.single,
      skir.DataValue.wrapTimestamp(DateTime.utc(1900, 6, 16)),
    );
  });
}

final _rootBinding = skir.ExpressionBindingId(value: "root");
final _rootReference = skir.BindingRef(
  bindingId: _rootBinding,
  path: skir.ValuePath(segments: const []),
);
final _budget = skir.EvaluationBudget(maxSteps: 100, maxCollectionItems: 100);
final _placementType = namedTypeUse("Placement");
final _toggleType = namedTypeUse("FeatureFlag");
