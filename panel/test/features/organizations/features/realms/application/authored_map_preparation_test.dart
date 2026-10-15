import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";

void main() {
  test(
    "map record branches are prepared and findings keep their branch",
    () async {
      final fixture = _fixture();
      var evaluations = 0;
      final host = fixture.host((request) async {
        evaluations++;
        return _prepared(request, "$evaluations", finding: true);
      });
      final result = await host.addMapRow(
        fixture.reference,
        context: fixture.context,
      );
      expect(result, isA<PortablePresentationWriteApplied>());
      expect(evaluations, 2);
      final rows = fixture.rows;
      expect(rows, hasLength(1));
      expect(
        rows.single.key.authoredField("name"),
        skir.DataValue.wrapStringValue("1"),
      );
      expect(
        rows.single.value.authoredField("name"),
        skir.DataValue.wrapStringValue("2"),
      );
      final findings = fixture.workspace.document.initializationFindings;
      expect(findings, hasLength(2));
      expect(
        findings.map((finding) => finding.location.path.segments.toList()[2]),
        [skir.PathSegment.mapKey, skir.PathSegment.mapValue],
      );
      expect(
        findings.every(
          (finding) =>
              finding.location.resource == fixture.resource &&
              finding.evidence.appliesTo(fixture.workspace.document),
        ),
        isTrue,
      );
      fixture.workspace
          .edit(
            label: "Edit map value",
            policy: EditorCommitPolicy.applyResource,
            apply: (operation) => operation.set(
              skir.ValueLocation(
                resource: fixture.resource,
                path: skir.ValuePath(
                  segments: [
                    skir.PathSegment.createField(name: "entries"),
                    skir.PathSegment.createItem(id: rows.single.id),
                    skir.PathSegment.mapValue,
                    skir.PathSegment.createField(name: "name"),
                  ],
                ),
              ),
              skir.DataValue.wrapStringValue("changed"),
            ),
          )
          .requireAccepted();
      expect(
        findings.first.evidence.appliesTo(fixture.workspace.document),
        isTrue,
      );
      expect(
        findings.last.evidence.appliesTo(fixture.workspace.document),
        isFalse,
      );
    },
  );

  test("second map preparation failure leaves no row or findings", () async {
    final fixture = _fixture();
    var evaluations = 0;
    final host = fixture.host((request) async {
      if (++evaluations == 2) throw StateError("value preparation unavailable");
      return _prepared(request, "key", finding: true);
    });
    final result = await host.addMapRow(
      fixture.reference,
      context: fixture.context,
    );
    expect(result, isA<PortablePresentationWriteRejected>());
    expect(evaluations, 2);
    expect(fixture.rows, isEmpty);
    expect(fixture.workspace.document.initializationFindings, isEmpty);
    expect(fixture.workspace.hasPendingWork, isFalse);
  });

  test(
    "closing the map presentation during preparation discards the row",
    () async {
      final fixture = _fixture();
      final pending = Completer<skir.PreparedValue>();
      skir.ValuePreparationRequest? observed;
      final host = fixture.host((request) {
        observed = request;
        return pending.future;
      });
      final result = host.addMapRow(
        fixture.reference,
        context: fixture.context,
      );
      expect(observed, isNotNull);
      host.dispose();
      pending.complete(_prepared(observed!, "key"));
      expect(await result, isA<PortablePresentationWriteRejected>());
      expect(fixture.rows, isEmpty);
      expect(fixture.workspace.hasPendingWork, isFalse);
    },
  );
}

skir.PreparedValue _prepared(
  skir.ValuePreparationRequest request,
  String name, {
  bool finding = false,
}) => skir.PreparedValue(
  content: skir.PreparedContent.wrapRecord(
    skir.AuthoringRecord(
      configuration: request.recordSelection,
      fields: [
        skir.FieldValue(
          name: "name",
          value: skir.DataValue.wrapStringValue(name),
        ),
      ],
    ),
  ),
  findings: [
    if (finding)
      skir.InitializationDiagnostic(
        field: null,
        code: "preparation_detail",
        message: "Prepared branch detail",
        relativePath: editorRootPath.field("name"),
      ),
  ],
);

final class _MapFixture {
  _MapFixture(this.document, this.resource, this.reference, this.context) {
    final transport = ScriptedAuthoringTransport(AsyncData(document));
    final submissions = ScopedWorkSession();
    workspace = RealmEditing(
      persistence: transport.persistence,
      submissions: submissions,
      initial: document,
    );
    binding = workspace.attach(
      resource,
      policy: EditorCommitPolicy.applyResource,
    );
    addTearDown(binding.detach);
    addTearDown(workspace.dispose);
    addTearDown(submissions.dispose);
    addTearDown(transport.dispose);
  }
  final AuthoringDocument document;
  final skir.ResourceId resource;
  final skir.BindingRef reference;
  final PortableInvocationContext context;
  late final RealmEditing workspace;
  late final RealmEditingBinding binding;
  List<skir.MapRow> get rows =>
      (workspace.document
                  .resource(resource)!
                  .authoredField("entries")!
                  .authoredPayload
              as skir.DataValue_mapValueWrapper)
          .value
          .rows
          .toList();

  AuthoredPresentationHost host(
    Future<skir.PreparedValue> Function(skir.ValuePreparationRequest) prepare,
  ) {
    final host = AuthoredPresentationHost(
      resource: resource,
      source: document,
      material: skir.PresentationMaterial.defaultInstance,
      role: skir.PresentationRole.editor,
      budget: skir.EvaluationBudget(maxSteps: 100, maxCollectionItems: 100),
      capabilities: const PortablePresentationCapabilities(),
      edit: binding,
      prepareValue: prepare,
    );
    // The closed presentation test owns its explicit disposal.
    addTearDown(() {
      if (host.enabled) host.dispose();
    });
    return host;
  }
}

_MapFixture _fixture() {
  skir.TypeDefinitionId id(String name) => skir.TypeDefinitionId(
    typeId: skir.TypeId.createQualified(namespace: "test", name: name),
    revision: 1,
  );
  skir.NamedTypeUse use(String name) =>
      skir.NamedTypeUse(definition: id(name), arguments: const []);
  skir.TypeTemplate named(String name) => skir.TypeTemplate.wrapNamed(
    skir.NamedTypeTemplate(definition: id(name), arguments: const []),
  );
  skir.PublishedType record(
    String name,
    String fieldName,
    skir.TypeTemplate fieldType,
  ) {
    final owner = skir.FieldOwner(definition: id(name), name: fieldName);
    return skir.PublishedType(
      definition: skir.TypeDefinition(
        id: id(name),
        parameters: const [],
        parents: const [],
        representation: skir.RepresentationTemplate.createRecord(
          fields: [
            skir.FieldDeclaration(
              owner: owner,
              type: fieldType,
              overrides: const [],
              hasConstructorDefault: true,
            ),
          ],
          abstract_: false,
        ),
      ),
      status: skir.DeclarationStatus.ready,
      display: null,
      ancestorTemplates: const [],
      effectiveFields: [
        skir.EffectiveFieldTemplate(
          key: fieldName,
          owner: owner,
          type: fieldType,
          rules: const [],
        ),
      ],
    );
  }

  final snapshot = skir.EditorCatalogWireSnapshot.defaultInstance.toMutable()
    ..generation = skir.CatalogGeneration(value: "map:creation")
    ..types = [
      record("Owner", "entries", named("Entries")),
      record(
        "Entry",
        "name",
        skir.TypeTemplate.wrapScalar(skir.ScalarKind.text),
      ),
      skir.PublishedType(
        definition: skir.TypeDefinition(
          id: id("Entries"),
          parameters: const [],
          parents: const [],
          representation: skir.RepresentationTemplate.createMapping(
            key: named("Entry"),
            value: named("Entry"),
          ),
        ),
        status: skir.DeclarationStatus.ready,
        display: null,
        effectiveFields: const [],
        ancestorTemplates: const [],
      ),
    ];
  final resource = skir.ResourceId(value: "map:owner");
  final map = skir.DataValue.createNamed(
    actualType: use("Entries"),
    payload: skir.DataValue.createMapValue(rows: const []),
  );
  final document = AuthoringDocument(
    catalog: CheckedEditorCatalog(snapshot.toFrozen()),
    entries: {
      resource: skir.AuthoringResource(
        id: resource,
        definition: skir.ResourceDefinitionId(value: "test.owner"),
        content: skir.AuthoringRecord(
          configuration: skir.TypeSelection.wrapComplete(use("Owner")),
          fields: [skir.FieldValue(name: "entries", value: map)],
        ),
      ),
    },
    links: const [],
  );
  final binding = skir.ExpressionBindingId(value: "map");
  return _MapFixture(
    document,
    resource,
    skir.BindingRef(bindingId: binding, path: editorRootPath),
    PortableInvocationContext(
      catalogGeneration: document.generation,
      bindings: {
        binding: PortableExpressionBinding(
          value: map,
          location: skir.ValueLocation(
            resource: resource,
            path: editorRootPath.field("entries"),
          ),
        ),
      },
    ),
  );
}
