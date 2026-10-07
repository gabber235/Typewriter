import "package:flutter/material.dart";
import "package:flutter_test/flutter_test.dart";
import "package:skir_client/skir_client.dart" show ByteString;
import "package:typewriter_panel/infrastructure/protocols/skir/skirout/editor/v1/authoring.dart"
    as authoring;
import "package:typewriter_panel/infrastructure/protocols/skir/skirout/editor/v1/binding.dart"
    as binding;
import "package:typewriter_panel/infrastructure/protocols/skir/skirout/editor/v1/catalog.dart"
    as catalog;
import "package:typewriter_panel/infrastructure/protocols/skir/skirout/editor/v1/expression.dart"
    as expression;
import "package:typewriter_panel/infrastructure/protocols/skir/skirout/editor/v1/presentation.dart"
    as presentation;
import "package:typewriter_panel/infrastructure/protocols/skir/skirout/editor/v1/type_catalog.dart"
    as types;
import "package:typewriter_panel/infrastructure/protocols/skir/skirout/kernel/v1/duration.dart"
    as kernel;
import "package:typewriter_panel/typewriter_panel.dart";

import "../../../../../support/test_utils.dart";

void main() {
  testWidgets("record controls preserve the named record identity", (
    tester,
  ) async {
    types.DataValue? written;
    final placementReference = binding.BindingRef(
      bindingId: _rootBinding,
      path: _fieldPath("placement"),
    );

    await tester.pumpTestApp(
      child: Builder(
        builder: (_) => Scaffold(
          body: PortablePresentationNodeRenderer(
            node: presentation.PresentationNode(
              nodeId: "placement",
              properties: presentation.PresentationProperties.defaultInstance,
              element: presentation.PresentationElement.wrapRecordInput(
                presentation.RecordControl(
                  control: _control(placementReference),
                  fieldPresentation: presentation.PresentationNode(
                    nodeId: "placement.x",
                    properties:
                        presentation.PresentationProperties.defaultInstance,
                    element: presentation.PresentationElement.wrapNumericInput(
                      _control(
                        binding.BindingRef(
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
                  value: types.DataValue.createRecord(
                    fields: [
                      types.FieldValue(
                        name: "placement",
                        value: types.DataValue.createNamed(
                          actualType: _placementType,
                          payload: types.DataValue.createRecord(
                            fields: [
                              types.FieldValue(
                                name: "x",
                                value: types.DataValue.wrapInteger("2"),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  location: types.ValueLocation(
                    resource: types.ResourceId(value: "element:one"),
                    path: types.ValuePath(segments: const []),
                  ),
                ),
              },
              budget: _budget,
              setBinding: (reference, value) {
                expect(reference, placementReference);
                written = value;
              },
            ),
          ),
        ),
      ),
    );

    await tester.enterText(find.byType(TextFormField), "7");
    await tester.pump();

    final named = switch (written) {
      final types.DataValue_namedWrapper value => value,
      _ => throw TestFailure("Expected a named record value"),
    };
    expect(named.value.actualType, _placementType);
    expect(
      named.value.payload.authoredField("x")?.authoredInteger,
      BigInt.from(7),
    );
  });

  testWidgets("toggle controls preserve a named scalar identity", (
    tester,
  ) async {
    types.DataValue? written;
    final enabledReference = binding.BindingRef(
      bindingId: _rootBinding,
      path: _fieldPath("enabled"),
    );
    await tester.pumpTestApp(
      child: Builder(
        builder: (_) => Scaffold(
          body: PortablePresentationNodeRenderer(
            node: presentation.PresentationNode(
              nodeId: "enabled",
              properties: presentation.PresentationProperties.defaultInstance,
              element: presentation.PresentationElement.wrapToggleInput(
                _control(enabledReference),
              ),
              header: null,
            ),
            scope: PortablePresentationScope(
              bindings: {
                _rootBinding: PortableExpressionBinding(
                  value: types.DataValue.createRecord(
                    fields: [
                      types.FieldValue(
                        name: "enabled",
                        value: types.DataValue.createNamed(
                          actualType: _toggleType,
                          payload: types.DataValue.wrapBoolean(false),
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
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.byType(Switch));
    await tester.pump();

    final named = switch (written) {
      final types.DataValue_namedWrapper value => value,
      _ => throw TestFailure("Expected a named boolean value"),
    };
    expect(named.value.actualType, _toggleType);
    expect(
      (named.value.payload as types.DataValue_booleanWrapper).value,
      isTrue,
    );
  });

  testWidgets("an Unfilled boolean offers an explicit repair choice", (
    tester,
  ) async {
    types.DataValue? written;
    final enabledReference = binding.BindingRef(
      bindingId: _rootBinding,
      path: _fieldPath("enabled"),
    );
    await tester.pumpTestApp(
      child: Builder(
        builder: (_) => Scaffold(
          body: PortablePresentationNodeRenderer(
            node: presentation.PresentationNode(
              nodeId: "enabled",
              properties: presentation.PresentationProperties.defaultInstance,
              element: presentation.PresentationElement.wrapToggleInput(
                _control(enabledReference),
              ),
              header: null,
            ),
            scope: PortablePresentationScope(
              bindings: {
                _rootBinding: PortableExpressionBinding(
                  value: types.DataValue.createRecord(
                    fields: [
                      types.FieldValue(
                        name: "enabled",
                        value: types.DataValue.unfilled,
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
            ),
          ),
        ),
      ),
    );

    expect(find.text("Choose a value"), findsOneWidget);
    await tester.tap(find.byType(DropdownButtonFormField<bool?>));
    await tester.pumpAndSettle();
    await tester.tap(find.text("On").last);
    await tester.pump();

    expect(written, types.DataValue.wrapBoolean(true));
  });

  test(
    "an Unfilled named scalar is admitted and written with its identity",
    () {
      final alias = _definition("Byte");
      final root = _definition("Root");
      final actual = types.NamedTypeUse(definition: alias, arguments: const []);
      final location = types.ValueLocation(
        resource: types.ResourceId(value: "resource:named"),
        path: _fieldPath("count"),
      );
      final generation = types.CatalogGeneration(value: "catalog:named");
      final checked = CheckedEditorCatalog(
        catalog.EditorCatalogWireSnapshot(
          generation: generation,
          types: [
            catalog.PublishedType(
              display: null,
              definition: types.TypeDefinition(
                id: alias,
                parameters: const [],
                representation: types.RepresentationTemplate.createScalar(
                  kind: types.ScalarKind.createInteger(
                    width: types.IntegerWidth.unsignedEight,
                  ),
                ),
                parents: const [],
              ),
              status: catalog.DeclarationStatus.ready,
              effectiveFields: const [],
              ancestorTemplates: const [],
            ),
            catalog.PublishedType(
              display: null,
              definition: types.TypeDefinition(
                id: root,
                parameters: const [],
                representation: types.RepresentationTemplate.createRecord(
                  fields: [
                    types.FieldDeclaration(
                      owner: types.FieldOwner(definition: root, name: "count"),
                      type: types.TypeTemplate.createNamed(
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
              status: catalog.DeclarationStatus.ready,
              effectiveFields: [
                catalog.EffectiveFieldTemplate(
                  key: "count",
                  owner: types.FieldOwner(definition: root, name: "count"),
                  type: types.TypeTemplate.createNamed(
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
      final snapshot = authoring.AuthoringState(
        generation: generation,
        resources: [
          authoring.AuthoringResource(
            id: location.resource,
            definition: catalog.ResourceDefinitionId(value: "test.root"),
            content: types.AuthoringRecord(
              configuration: types.TypeSelection.createComplete(
                definition: root,
                arguments: const [],
              ),
              fields: [
                types.FieldValue(
                  name: "count",
                  value: types.DataValue.unfilled,
                ),
              ],
            ),
          ),
        ],
        links: const [],
        findings: const [],
      );
      final draft = AuthoredDraft.fromState(snapshot, catalog: checked);
      types.DataValue? written;
      final reference = binding.BindingRef(
        bindingId: _rootBinding,
        path: location.path,
      );
      final scope = PortablePresentationScope(
        bindings: {
          _rootBinding: PortableExpressionBinding(
            value: types.DataValue.createRecord(
              fields: [
                types.FieldValue(
                  name: "count",
                  value: types.DataValue.unfilled,
                ),
              ],
            ),
            location: types.ValueLocation(
              resource: location.resource,
              path: types.ValuePath(segments: const []),
            ),
          ),
        },
        budget: _budget,
        setBinding: (_, value) => written = value,
        authoring: AuthoredDraftAuthoringDocument(draft),
        catalog: checked,
      );

      expect(
        scope.expectedPayloadType(reference),
        types.TypeUse.wrapScalar(
          types.ScalarKind.createInteger(
            width: types.IntegerWidth.unsignedEight,
          ),
        ),
      );
      scope.writePayload(reference, types.DataValue.wrapInteger("255"));

      final named = switch (written) {
        final types.DataValue_namedWrapper value => value,
        _ => throw TestFailure("Expected a named scalar value"),
      };
      expect(named.value.actualType, actual);
      expect(named.value.payload, types.DataValue.wrapInteger("255"));
    },
  );

  testWidgets("an Unfilled duration accepts a value and blank clears it", (
    tester,
  ) async {
    final written = <types.DataValue>[];
    await _pumpControl(
      tester,
      presentation.PresentationElement.wrapDurationInput(
        _control(_rootReference),
      ),
      types.DataValue.unfilled,
      written.add,
    );

    final input = find.byType(TextFormField);
    expect(input, findsOneWidget);
    await tester.enterText(input, "1250");
    expect(
      written.last,
      types.DataValue.createDuration(
        value: kernel.Duration(milliseconds: 1250),
      ),
    );
    await tester.enterText(input, "");
    expect(written.last, types.DataValue.unfilled);
    await tester.enterText(input, "12x");
    expect(find.text("12x"), findsNothing);
  });

  testWidgets("an Unfilled byte sequence distinguishes empty from missing", (
    tester,
  ) async {
    final written = <types.DataValue>[];
    await _pumpControl(
      tester,
      presentation.PresentationElement.wrapBytesInput(_control(_rootReference)),
      types.DataValue.unfilled,
      written.add,
    );

    expect(find.text("This value is Unfilled"), findsOneWidget);
    await tester.tap(find.text("Use empty bytes"));
    expect(written.last, types.DataValue.wrapBytes(ByteString.empty));

    await tester.enterText(find.byType(TextFormField), "0a");
    expect(
      written.last,
      types.DataValue.wrapBytes(ByteString.fromBase16("0a")),
    );
    await tester.enterText(find.byType(TextFormField), "");
    expect(written.last, types.DataValue.unfilled);
  });

  testWidgets("an Unfilled color accepts a complete hexadecimal value", (
    tester,
  ) async {
    final written = <types.DataValue>[];
    await _pumpControl(
      tester,
      presentation.PresentationElement.wrapColorInput(
        presentation.ColorControl(
          control: _control(_rootReference),
          includeAlpha: false,
        ),
      ),
      types.DataValue.unfilled,
      written.add,
    );

    await tester.enterText(find.byType(TextFormField), "#AABBCC");
    expect(written.last, types.DataValue.wrapInteger(0xFFAABBCC.toString()));
    await tester.enterText(find.byType(TextFormField), "");
    expect(written.last, types.DataValue.unfilled);
  });

  testWidgets("an Unfilled slider requires an explicit choice", (tester) async {
    final written = <types.DataValue>[];
    await _pumpControl(
      tester,
      presentation.PresentationElement.wrapSliderInput(
        presentation.SliderControl(
          control: _control(_rootReference),
          minimum: expression.ExpressionNode.wrapLiteral(
            types.DataValue.wrapFloat(2),
          ),
          maximum: expression.ExpressionNode.wrapLiteral(
            types.DataValue.wrapFloat(8),
          ),
          divisions: null,
        ),
      ),
      types.DataValue.unfilled,
      written.add,
    );

    expect(written, isEmpty);
    expect(find.text("Set to 2"), findsOneWidget);
    await tester.tap(find.text("Set to 2"));
    expect(written.last, types.DataValue.wrapFloat(2));
  });

  testWidgets("an Unfilled time requires a choice before it writes", (
    tester,
  ) async {
    final written = <types.DataValue>[];
    await _pumpControl(
      tester,
      presentation.PresentationElement.wrapDateTimeInput(
        presentation.DateTimeControl(
          control: _control(_rootReference),
          includeDate: false,
          includeTime: true,
        ),
      ),
      types.DataValue.unfilled,
      written.add,
    );

    expect(find.text("Choose a date and time"), findsOneWidget);
    expect(written, isEmpty);
    await tester.tap(find.text("Choose a date and time"));
    await tester.pumpAndSettle();
    await tester.tap(find.text("OK"));
    await tester.pumpAndSettle();
    expect(written.last, isA<types.DataValue_timestampWrapper>());
  });

  testWidgets("a date before 1970 remains editable", (tester) async {
    final written = <types.DataValue>[];
    await _pumpControl(
      tester,
      presentation.PresentationElement.wrapDateTimeInput(
        presentation.DateTimeControl(
          control: _control(_rootReference),
          includeDate: true,
          includeTime: false,
        ),
      ),
      types.DataValue.wrapTimestamp(DateTime.utc(1900, 6, 15)),
      written.add,
    );

    await tester.tap(find.byType(ListTile));
    await tester.pumpAndSettle();
    expect(find.byType(DatePickerDialog), findsOneWidget);
    expect(tester.takeException(), isNull);
    expect(written, isEmpty);
  });

  testWidgets("connection layers report unresolved declared anchors", (
    tester,
  ) async {
    await tester.pumpTestApp(
      child: Builder(
        builder: (_) => Scaffold(
          body: PortablePresentationNodeRenderer(
            node: presentation.PresentationNode(
              nodeId: "connection.layer",
              properties: presentation.PresentationProperties.defaultInstance,
              element: presentation.PresentationElement.createConnectionLayer(
                child: presentation.PresentationNode(
                  nodeId: "connection.content",
                  properties:
                      presentation.PresentationProperties.defaultInstance,
                  element: presentation.PresentationElement.divider,
                  header: null,
                ),
                connections: [
                  presentation.PresentationConnection.createConnection(
                    source: presentation.PresentationAnchorSelector.wrapLocal(
                      "source",
                    ),
                    target: presentation.PresentationAnchorSelector.wrapLocal(
                      "target",
                    ),
                    path: presentation.ConnectionPath.straight,
                    style: presentation.ConnectorStyle(
                      stroke: presentation.ConnectorStroke(
                        color: expression.ExpressionNode.wrapLiteral(
                          types.DataValue.wrapInteger("4278190335"),
                        ),
                        width: expression.ExpressionNode.wrapLiteral(
                          types.DataValue.wrapInteger("2"),
                        ),
                      ),
                      cornerRadius: expression.ExpressionNode.wrapLiteral(
                        types.DataValue.wrapInteger("0"),
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

final _rootBinding = types.ExpressionBindingId(value: "root");
final _configuredBinding = types.ExpressionBindingId(value: "configured_value");
final _rootReference = binding.BindingRef(
  bindingId: _rootBinding,
  path: types.ValuePath(segments: const []),
);
final _budget = expression.EvaluationBudget(
  maxSteps: 100,
  maxCollectionItems: 100,
);
final _placementType = _namedType("Placement");
final _toggleType = _namedType("FeatureFlag");

types.NamedTypeUse _namedType(String name) => types.NamedTypeUse(
  definition: types.TypeDefinitionId(
    typeId: types.TypeId.wrapQualified(
      types.QualifiedTypeId(namespace: "test", name: name),
    ),
    revision: 1,
  ),
  arguments: const [],
);

types.TypeDefinitionId _definition(String name) => _namedType(name).definition;

presentation.BoundControl _control(binding.BindingRef reference) =>
    presentation.BoundControl(
      binding: reference,
      label: null,
      description: null,
      prefix: null,
      semanticLabel: null,
    );

types.ValuePath _fieldPath(String name) =>
    types.ValuePath(segments: [types.PathSegment.createField(name: name)]);

Future<void> _pumpControl(
  WidgetTester tester,
  presentation.PresentationElement element,
  types.DataValue value,
  ValueChanged<types.DataValue> onWrite,
) => tester.pumpTestApp(
  child: Builder(
    builder: (_) => Scaffold(
      body: PortablePresentationNodeRenderer(
        node: presentation.PresentationNode(
          nodeId: "scalar",
          properties: presentation.PresentationProperties.defaultInstance,
          element: element,
          header: null,
        ),
        scope: PortablePresentationScope(
          bindings: {_rootBinding: PortableExpressionBinding(value: value)},
          budget: _budget,
          setBinding: (_, replacement) => onWrite(replacement),
        ),
      ),
    ),
  ),
);
