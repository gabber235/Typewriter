import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";

const _key = EditorResourceKey(scope: "realm", identity: "resource");
final _name = editorRootPath.field("name");
final _color = editorRootPath.field("color");

skir.DataValue _value(String name, int color) => skir.DataValue.createRecord(
  fields: [
    skir.FieldValue(name: "name", value: skir.DataValue.wrapStringValue(name)),
    skir.FieldValue(name: "color", value: skir.DataValue.wrapInteger("$color")),
  ],
);

ResourceEditorTarget _target() => fakeEditorTarget(
  targetId: _key.identity,
  scope: _key.scope,
  label: "Resource",
  document: EditorDocument(
    rootType: _recordTypeUse,
    catalog: _recordCatalog,
    confirmedValue: _value("Canonical", 1),
    revision: 1,
  ),
  validation: acceptTestEditorMutation,
  commitPolicy: EditorCommitPolicy.applyResource,
  commit: (_) async => throw StateError("No save expected"),
);

final _recordType = skir.TypeDefinitionId(
  typeId: skir.TypeId.createQualified(namespace: "test", name: "Resource"),
  revision: 1,
);
final _recordTypeUse = skir.TypeUse.wrapNamed(
  skir.NamedTypeUse(definition: _recordType, arguments: const []),
);
final _nameField = _effectiveField(
  "name",
  skir.TypeTemplate.wrapScalar(skir.ScalarKind.text),
);
final _colorField = _effectiveField(
  "color",
  skir.TypeTemplate.wrapScalar(
    skir.ScalarKind.createInteger(width: skir.IntegerWidth.signedThirtyTwo),
  ),
);
final _recordCatalog = CheckedEditorCatalog(
  skir.EditorCatalogWireSnapshot(
    generation: skir.CatalogGeneration(value: "test"),
    types: [
      skir.PublishedType(
        display: null,
        definition: skir.TypeDefinition(
          id: _recordType,
          parameters: const [],
          representation: skir.RepresentationTemplate.createRecord(
            fields: [
              for (final field in [_nameField, _colorField])
                skir.FieldDeclaration(
                  owner: field.owner,
                  type: field.type,
                  overrides: const [],
                  hasConstructorDefault: false,
                ),
            ],
            abstract_: false,
          ),
          parents: const [],
        ),
        status: skir.DeclarationStatus.ready,
        effectiveFields: [_nameField, _colorField],
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
skir.EffectiveFieldTemplate _effectiveField(
  String name,
  skir.TypeTemplate type,
) => skir.EffectiveFieldTemplate(
  key: name,
  owner: skir.FieldOwner(definition: _recordType, name: name),
  type: type,
  rules: const [],
);

void main() {
  test("projects only edited paths and tracks resource removal", () {
    final workspace = ScopedWorkSession();
    addTearDown(workspace.dispose);

    expect(workspace.state.editorValues, isEmpty);

    final source = workspace.editor(_target())
      ..update(_name, skir.DataValue.wrapStringValue("Draft"));

    final local = workspace.state.editorValues[_key];
    expect(local, isNotNull);
    expect(local!.editedPaths, {_name});
    expect(local.projectOnto(_value("Remote", 2)), _value("Draft", 2));

    source.discardDraft();
    expect(workspace.state.editorValues, isEmpty);
  });

  test("different resources retain structural identity", () {
    final first = LocalEditorValue(
      value: _value("First", 1),
      editedPaths: {_name},
    );
    final same = LocalEditorValue(
      value: _value("First", 1),
      editedPaths: {_name},
    );
    final different = LocalEditorValue(
      value: _value("First", 1),
      editedPaths: {_color},
    );

    expect(first, same);
    expect(first, isNot(different));
  });
}
