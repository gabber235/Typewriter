import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";

import "../../../../../support/test_utils.dart";

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
        await _pumpControl(
          tester,
          skir.PresentationElement.wrapNumericInput(_control(_rootReference)),
          scenario.initial,
          written.add,
          rebindWrites: true,
        );
        await tester.tap(find.byType(TextFormField));
        await tester.pumpAndSettle();
        await tester.enterText(find.byType(TextFormField), scenario.partial);
        await tester.pumpAndSettle();
        expect(
          tester
              .widget<TextFormField>(find.byType(TextFormField))
              .controller!
              .text,
          scenario.partial,
        );
        expect(written, isEmpty);
        tester.binding.focusManager.primaryFocus?.unfocus();
        await tester.pumpAndSettle();
        expect(written, isEmpty);
        expect(find.text("Enter a valid number"), findsOneWidget);
        await tester.enterText(find.byType(TextFormField), scenario.complete);
        await tester.pumpAndSettle();
        expect(written, [scenario.expected]);
        await tester.enterText(find.byType(TextFormField), "");
        await tester.pumpAndSettle();
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
      path: _fieldPath("placement"),
    );
    final host = _ControlHost(
      onWrite: (reference, value) {
        written = (reference, value);
      },
    );
    addTearDown(host.dispose);

    await tester.pumpTestApp(
      child: Builder(
        builder: (_) => Scaffold(
          body: PortablePresentationNodeRenderer(
            node: skir.PresentationNode(
              nodeId: "placement",
              properties: skir.PresentationProperties.defaultInstance,
              element: skir.PresentationElement.wrapRecordInput(
                skir.RecordControl(
                  control: _control(placementReference),
                  fieldPresentation: skir.PresentationNode(
                    nodeId: "placement.x",
                    properties: skir.PresentationProperties.defaultInstance,
                    element: skir.PresentationElement.wrapNumericInput(
                      _control(
                        skir.BindingRef(
                          bindingId: _configuredBinding,
                          path: _fieldPath("x"),
                        ),
                      ),
                    ),
                    header: null,
                  ),
                ),
              ),
              header: null,
            ),
            scope: PortablePresentationScope(
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
              setBinding: (reference, value) {
                expect(reference, placementReference);
                written = (reference, value);
              },
              host: host,
            ),
          ),
        ),
      ),
    );

    await tester.enterText(find.byType(TextFormField), "7");
    await tester.pumpAndSettle();

    expect(written?.$1.path, _fieldPath("x"));
    expect(written?.$2, skir.DataValue.wrapInteger("7"));
  });

  testWidgets("toggle controls preserve a named scalar identity", (
    tester,
  ) async {
    skir.DataValue? written;
    final enabledReference = skir.BindingRef(
      bindingId: _rootBinding,
      path: _fieldPath("enabled"),
    );
    final host = _ControlHost(onWrite: (_, value) => written = value);
    addTearDown(host.dispose);
    await tester.pumpTestApp(
      child: Builder(
        builder: (_) => Scaffold(
          body: PortablePresentationNodeRenderer(
            node: skir.PresentationNode(
              nodeId: "enabled",
              properties: skir.PresentationProperties.defaultInstance,
              element: skir.PresentationElement.wrapToggleInput(
                _control(enabledReference),
              ),
              header: null,
            ),
            scope: PortablePresentationScope(
              bindings: {
                _rootBinding: PortableExpressionBinding(
                  value: skir.DataValue.createRecord(
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
                ),
              },
              budget: _budget,
              setBinding: (reference, value) {
                expect(reference, enabledReference);
                written = value;
              },
              host: host,
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.byType(Switch));
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
    final enabledReference = skir.BindingRef(
      bindingId: _rootBinding,
      path: _fieldPath("enabled"),
    );
    final host = _ControlHost(onWrite: (_, value) => written = value);
    addTearDown(host.dispose);
    await tester.pumpTestApp(
      child: Builder(
        builder: (_) => Scaffold(
          body: PortablePresentationNodeRenderer(
            node: skir.PresentationNode(
              nodeId: "enabled",
              properties: skir.PresentationProperties.defaultInstance,
              element: skir.PresentationElement.wrapToggleInput(
                _control(enabledReference),
              ),
              header: null,
            ),
            scope: PortablePresentationScope(
              bindings: {
                _rootBinding: PortableExpressionBinding(
                  value: skir.DataValue.createRecord(
                    fields: [
                      skir.FieldValue(
                        name: "enabled",
                        value: skir.DataValue.unfilled,
                      ),
                    ],
                  ),
                ),
              },
              budget: _budget,
              setBinding: (reference, value) {
                expect(reference, enabledReference);
                written = value;
              },
              host: host,
            ),
          ),
        ),
      ),
    );

    expect(written, isNull);
    await tester.tap(find.text("On"));
    await tester.pump();

    expect(written, skir.DataValue.wrapBoolean(true));
  });

  test(
    "an Unfilled named scalar is admitted and written with its identity",
    () {
      final alias = _definition("Byte");
      final root = _definition("Root");
      final actual = skir.NamedTypeUse(definition: alias, arguments: const []);
      final location = skir.ValueLocation(
        resource: skir.ResourceId(value: "resource:named"),
        path: _fieldPath("count"),
      );
      final generation = skir.CatalogGeneration(value: "catalog:named");
      final checked = CheckedEditorCatalog(
        skir.EditorCatalogWireSnapshot(
          generation: generation,
          types: [
            skir.PublishedType(
              display: null,
              definition: skir.TypeDefinition(
                id: alias,
                parameters: const [],
                representation: skir.RepresentationTemplate.createScalar(
                  kind: skir.ScalarKind.createInteger(
                    width: skir.IntegerWidth.unsignedEight,
                  ),
                ),
                parents: const [],
              ),
              status: skir.DeclarationStatus.ready,
              effectiveFields: const [],
              ancestorTemplates: const [],
            ),
            skir.PublishedType(
              display: null,
              definition: skir.TypeDefinition(
                id: root,
                parameters: const [],
                representation: skir.RepresentationTemplate.createRecord(
                  fields: [
                    skir.FieldDeclaration(
                      owner: skir.FieldOwner(definition: root, name: "count"),
                      type: skir.TypeTemplate.createNamed(
                        definition: alias,
                        arguments: const [],
                      ),
                      overrides: const [],
                      hasConstructorDefault: false,
                    ),
                  ],
                  abstract_: false,
                ),
                parents: const [],
              ),
              status: skir.DeclarationStatus.ready,
              effectiveFields: [
                skir.EffectiveFieldTemplate(
                  key: "count",
                  owner: skir.FieldOwner(definition: root, name: "count"),
                  type: skir.TypeTemplate.createNamed(
                    definition: alias,
                    arguments: const [],
                  ),
                  rules: const [],
                ),
              ],
              ancestorTemplates: const [],
            ),
          ],
          relations: const [],
          resourceDefinitions: const [],
          presentations: const [],
          presentationMaterials: const [],
          configuration: const [],
          diagnostics: const [],
          initialization: const [],
          endpointBindings: const [],
          capabilities: const [],
          recommendations: const [],
          roleFallbacks: const [],
        ),
      );
      final snapshot = skir.AuthoringState(
        generation: generation,
        resources: [
          skir.AuthoringResource(
            id: location.resource,
            definition: skir.ResourceDefinitionId(value: "test.root"),
            content: skir.AuthoringRecord(
              configuration: skir.TypeSelection.createComplete(
                definition: root,
                arguments: const [],
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
      final host = EditorSourcePresentationHost(
        catalog: checked,
        root: () => skir.PresentationNode.defaultInstance,
        bindings: [
          EditorSourcePresentationBinding(
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
        setBinding: (_, value) => written = value,
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
    await _pumpControl(
      tester,
      skir.PresentationElement.wrapDurationInput(_control(_rootReference)),
      skir.DataValue.unfilled,
      written.add,
    );

    final input = find.byType(TextFormField);
    await tester.enterText(input, "1250ms");
    expect(
      written.last,
      skir.DataValue.createDuration(value: skir.Duration(milliseconds: 1250)),
    );
    await tester.enterText(input, "");
    expect(written.last, skir.DataValue.unfilled);
    await tester.enterText(input, "12x");
    expect(written, [
      skir.DataValue.createDuration(value: skir.Duration(milliseconds: 1250)),
      skir.DataValue.unfilled,
    ]);
  });

  testWidgets("an Unfilled byte sequence distinguishes empty from missing", (
    tester,
  ) async {
    final written = <skir.DataValue>[];
    await _pumpControl(
      tester,
      skir.PresentationElement.wrapBytesInput(_control(_rootReference)),
      skir.DataValue.unfilled,
      written.add,
    );

    expect(find.text("This value is Unfilled"), findsOneWidget);
    await tester.tap(find.text("Use empty bytes"));
    expect(written.last, skir.DataValue.wrapBytes(skir.ByteString.empty));

    await tester.enterText(find.byType(TextFormField), "0a");
    expect(
      written.last,
      skir.DataValue.wrapBytes(skir.ByteString.fromBase16("0a")),
    );
    await tester.enterText(find.byType(TextFormField), "");
    expect(written.last, skir.DataValue.unfilled);
  });

  testWidgets("an Unfilled color accepts a complete hexadecimal value", (
    tester,
  ) async {
    final written = <skir.DataValue>[];
    await _pumpControl(
      tester,
      skir.PresentationElement.wrapColorInput(
        skir.ColorControl(
          control: _control(_rootReference),
          includeAlpha: false,
        ),
      ),
      skir.DataValue.unfilled,
      written.add,
      rebindWrites: true,
    );

    expect(find.text(mixedValueReplacementMessage), findsNothing);
    expect(find.text("This value is Unfilled"), findsOneWidget);
    await tester.enterText(find.byType(TextFormField), "#AABBCC");
    expect(written.last, skir.DataValue.wrapInteger(0xFFAABBCC.toString()));
    await tester.enterText(find.byType(TextFormField), "");
    await tester.pumpAndSettle();
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
        await _pumpControl(
          tester,
          skir.PresentationElement.wrapDateTimeInput(
            skir.DateTimeControl(
              control: _control(_rootReference),
              includeDate: parts.$1,
              includeTime: parts.$2,
            ),
          ),
          skir.DataValue.wrapTimestamp(DateTime.utc(2024, 8, 12, 18, 30, 45)),
          written.add,
          rebindWrites: true,
        );
        final input = find.byType(TextFormField);
        await tester.enterText(input, "2028");
        await tester.pump();
        expect(written, isEmpty);
        final valid = parts.$1 && parts.$2
            ? "2028-02-29 07:06:05"
            : parts.$1
            ? "2028-02-29"
            : "07:06:05";
        await tester.enterText(input, valid);
        await tester.pumpAndSettle();
        final expected = parts.$1 && parts.$2
            ? DateTime.utc(2028, 2, 29, 7, 6, 5)
            : parts.$1
            ? DateTime.utc(2028, 2, 29, 18, 30, 45)
            : DateTime.utc(2024, 8, 12, 7, 6, 5);
        final filled = skir.DataValue.wrapTimestamp(expected);
        expect(written, [filled]);

        await tester.enterText(input, "");
        await tester.pumpAndSettle();
        expect(find.text(mixedValueReplacementMessage), findsNothing);
        expect(find.text("This value is Unfilled"), findsOneWidget);
        expect(written, [filled, skir.DataValue.unfilled]);
        expect(
          tester
              .widget<DateTimePickerField>(find.byType(DateTimePickerField))
              .value,
          isNull,
        );
        await tester.testTextInput.receiveAction(TextInputAction.done);
        await tester.pumpAndSettle();
        expect(written, [filled, skir.DataValue.unfilled]);

        await tester.tap(find.byTooltip("Open picker"));
        await tester.pumpAndSettle();
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
        await tester.tap(find.byTooltip("Close picker"));
        await tester.pumpAndSettle();
        expect(written, [filled, skir.DataValue.unfilled]);

        await tester.enterText(input, valid);
        await tester.pumpAndSettle();
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
        skir.PresentationElement.wrapColorInput(
          skir.ColorControl(
            control: _control(_rootReference),
            includeAlpha: false,
          ),
        ),
        skir.DataValue.wrapInteger(0xFFAABBCC.toString()),
      ),
      (
        skir.PresentationElement.wrapDateTimeInput(
          skir.DateTimeControl(
            control: _control(_rootReference),
            includeDate: true,
            includeTime: true,
          ),
        ),
        skir.DataValue.wrapTimestamp(DateTime.utc(2024, 8, 12)),
      ),
    ];
    for (final field in fields) {
      for (final protected in [(true, true), (false, false)]) {
        final written = <skir.DataValue>[];
        await _pumpControl(
          tester,
          field.$1,
          field.$2,
          written.add,
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
    await _pumpControl(
      tester,
      skir.PresentationElement.wrapSliderInput(
        skir.SliderControl(
          control: _control(_rootReference),
          minimum: skir.ExpressionNode.wrapLiteral(skir.DataValue.wrapFloat(2)),
          maximum: skir.ExpressionNode.wrapLiteral(skir.DataValue.wrapFloat(8)),
          divisions: null,
        ),
      ),
      skir.DataValue.unfilled,
      written.add,
    );

    expect(written, isEmpty);
    expect(find.text("Set to 2"), findsOneWidget);
    await tester.tap(find.text("Set to 2"));
    expect(written.last, skir.DataValue.wrapFloat(2));
  });

  testWidgets("an Unfilled time requires a choice before it writes", (
    tester,
  ) async {
    final written = <skir.DataValue>[];
    await _pumpControl(
      tester,
      skir.PresentationElement.wrapDateTimeInput(
        skir.DateTimeControl(
          control: _control(_rootReference),
          includeDate: false,
          includeTime: true,
        ),
      ),
      skir.DataValue.unfilled,
      written.add,
    );

    expect(written, isEmpty);
    await tester.tap(find.byTooltip("Open picker"));
    await tester.pumpAndSettle();
    expect(written, isEmpty);
    await tester.tap(find.byTooltip("Close picker"));
    await tester.pumpAndSettle();
    expect(written, isEmpty);
    await tester.enterText(find.byType(TextFormField), "01:02:03");
    await tester.pumpAndSettle();
    final timestamp = (written.single as skir.DataValue_timestampWrapper).value;
    expect([timestamp.hour, timestamp.minute, timestamp.second], [1, 2, 3]);
  });

  testWidgets("a date before 1970 remains editable", (tester) async {
    final written = <skir.DataValue>[];
    await _pumpControl(
      tester,
      skir.PresentationElement.wrapDateTimeInput(
        skir.DateTimeControl(
          control: _control(_rootReference),
          includeDate: true,
          includeTime: false,
        ),
      ),
      skir.DataValue.wrapTimestamp(DateTime.utc(1900, 6, 15)),
      written.add,
    );

    await tester.tap(find.byTooltip("Open picker"));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(written, isEmpty);
    await tester.tap(find.byTooltip("Close picker"));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField), "1900-06-16");
    await tester.pumpAndSettle();
    expect(
      written.single,
      skir.DataValue.wrapTimestamp(DateTime.utc(1900, 6, 16)),
    );
  });

  testWidgets("connection layers report unresolved declared anchors", (
    tester,
  ) async {
    await tester.pumpTestApp(
      child: Builder(
        builder: (_) => Scaffold(
          body: PortablePresentationNodeRenderer(
            node: skir.PresentationNode(
              nodeId: "connection.layer",
              properties: skir.PresentationProperties.defaultInstance,
              element: skir.PresentationElement.createConnectionLayer(
                child: skir.PresentationNode(
                  nodeId: "connection.content",
                  properties: skir.PresentationProperties.defaultInstance,
                  element: skir.PresentationElement.divider,
                  header: null,
                ),
                connections: [
                  skir.PresentationConnection.createConnection(
                    source: skir.PresentationAnchorSelector.wrapLocal("source"),
                    target: skir.PresentationAnchorSelector.wrapLocal("target"),
                    path: skir.ConnectionPath.straight,
                    style: skir.ConnectorStyle(
                      stroke: skir.ConnectorStroke(
                        color: skir.PresentationColor.wrapValue(
                          skir.ExpressionNode.wrapLiteral(
                            skir.DataValue.wrapInteger("4278190335"),
                          ),
                        ),
                        width: skir.ExpressionNode.wrapLiteral(
                          skir.DataValue.wrapInteger("2"),
                        ),
                      ),
                      cornerRadius: skir.ExpressionNode.wrapLiteral(
                        skir.DataValue.wrapInteger("0"),
                      ),
                      startMarker: null,
                      endMarker: null,
                    ),
                    markers: const [],
                    visibleIf: null,
                  ),
                ],
              ),
              header: null,
            ),
            scope: PortablePresentationScope(
              bindings: const {},
              budget: _budget,
              setBinding: (_, _) {},
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(
      find.textContaining("Connection source anchor is missing"),
      findsOneWidget,
    );
  });
}

final _rootBinding = skir.ExpressionBindingId(value: "root");
final _configuredBinding = skir.ExpressionBindingId(value: "configured_value");
final _rootReference = skir.BindingRef(
  bindingId: _rootBinding,
  path: skir.ValuePath(segments: const []),
);
final _budget = skir.EvaluationBudget(maxSteps: 100, maxCollectionItems: 100);
final _placementType = _namedType("Placement");
final _toggleType = _namedType("FeatureFlag");

skir.NamedTypeUse _namedType(String name) => skir.NamedTypeUse(
  definition: skir.TypeDefinitionId(
    typeId: skir.TypeId.wrapQualified(
      skir.QualifiedTypeId(namespace: "test", name: name),
    ),
    revision: 1,
  ),
  arguments: const [],
);

skir.TypeDefinitionId _definition(String name) => _namedType(name).definition;

skir.BoundControl _control(skir.BindingRef reference) => skir.BoundControl(
  binding: reference,
  label: null,
  description: null,
  prefix: null,
  semanticLabel: null,
);

skir.ValuePath _fieldPath(String name) =>
    skir.ValuePath(segments: [skir.PathSegment.createField(name: name)]);

Future<void> _pumpControl(
  WidgetTester tester,
  skir.PresentationElement element,
  skir.DataValue value,
  ValueChanged<skir.DataValue> onWrite, {
  bool readOnly = false,
  bool enabled = true,
  bool rebindWrites = false,
}) {
  var current = value;
  late StateSetter rebuild;
  final host = _ControlHost(
    expected: switch (element) {
      skir.PresentationElement_sliderInputWrapper() => skir.TypeUse.wrapScalar(
        skir.ScalarKind.createFloat(width: skir.FloatWidth.sixtyFour),
      ),
      _ => skir.TypeUse.wrapScalar(skir.ScalarKind.text),
    },
    onWrite: (_, replacement) {
      onWrite(replacement);
      if (rebindWrites) rebuild(() => current = replacement);
    },
  );
  addTearDown(host.dispose);
  return tester.pumpTestApp(
    child: StatefulBuilder(
      builder: (_, setState) {
        rebuild = setState;
        return Scaffold(
          body: PortablePresentationNodeRenderer(
            node: skir.PresentationNode(
              nodeId: "scalar",
              properties: skir.PresentationProperties.defaultInstance,
              element: element,
              header: null,
            ),
            scope: PortablePresentationScope(
              bindings: {
                _rootBinding: PortableExpressionBinding(value: current),
              },
              budget: _budget,
              setBinding: (_, replacement) {
                onWrite(replacement);
                if (rebindWrites) setState(() => current = replacement);
              },
              readOnly: readOnly,
              enabled: enabled,
              host: host,
            ),
          ),
        );
      },
    ),
  );
}

final class _ControlHost extends ChangeNotifier
    implements PortablePresentationHost {
  _ControlHost({required this.onWrite, this.expected});

  final void Function(skir.BindingRef reference, skir.DataValue value) onWrite;
  final skir.TypeUse? expected;

  @override
  PortablePresentationCapabilities get capabilities =>
      const PortablePresentationCapabilities();

  @override
  PortablePresentationDocument get document => PortablePresentationDocument(
    catalog: skir.EditorCatalogWireSnapshot.defaultInstance
        .asTrustedLocalCatalog(),
    root: skir.PresentationNode.defaultInstance,
    bindings: const {},
    budget: _budget,
  );

  @override
  bool get enabled => true;

  @override
  bool get readOnly => false;

  @override
  Future<PortablePresentationWriteResult> execute(
    skir.EditorAction editorAction, {
    required PortableInvocationContext context,
  }) async => const PortablePresentationWriteApplied();

  @override
  skir.TypeUse? expectedType(
    skir.BindingRef reference, {
    required PortableInvocationContext context,
  }) => expected ?? skir.TypeUse.wrapScalar(skir.ScalarKind.text);

  @override
  skir.ValueLocation? location(
    skir.BindingRef reference, {
    required PortableInvocationContext context,
  }) => null;

  @override
  skir.DataValue? read(
    skir.BindingRef reference, {
    required PortableInvocationContext context,
  }) {
    final root = context.bindings[reference.bindingId]?.value;
    if (root == null || reference.path.segments.isEmpty) return root;
    return switch (root.readAt(reference.path)) {
      PortablePathValue(:final value) => value,
      PortablePathUnavailable() => null,
    };
  }

  @override
  Future<PortablePresentationWriteResult> write(
    skir.BindingRef reference,
    skir.DataValue value, {
    required PortableInvocationContext context,
  }) async {
    onWrite(reference, value);
    notifyListeners();
    return const PortablePresentationWriteApplied();
  }
}
