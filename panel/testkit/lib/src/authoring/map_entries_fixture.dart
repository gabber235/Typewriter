import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/src/authoring/realm_world.dart";
import "package:typewriter_testkit/src/core/test_world.dart";
import "package:typewriter_testkit/typewriter_testkit.dart";

/// The panel's editing of a Realm whose one Owner record holds a map of
/// Entry records, for tests of preparing new map entries.
final class MapEntriesFixture {
  /// An Owner record whose map of entries starts empty, in a catalog where
  /// entries are Entry records keyed by Entry records.
  factory MapEntriesFixture() {
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
        searchKey: null,
        placementField: null,
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
        display: defaultTypeDisplay(""),
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

    final snapshot = skir.EditorCatalog.defaultInstance.toMutable()
      ..generation = skir.CatalogGeneration(value: "map:creation")
      ..types = [
        record("Owner", "entries", named("Entries")),
        record(
          "Entry",
          "name",
          skir.TypeTemplate.wrapScalar(skir.ScalarKind.text),
        ),
        skir.PublishedType(
          searchKey: null,
          placementField: null,
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
          display: defaultTypeDisplay(""),
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
          content: skir.AuthoringRecord(
            configuration: skir.TypeSelection.wrapComplete(use("Owner")),
            fields: [skir.FieldValue(name: "entries", value: map)],
          ),
        ),
      },
      links: const [],
    );
    final binding = skir.ExpressionBindingId(value: "map");
    return MapEntriesFixture._(
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

  MapEntriesFixture._(
    this.document,
    this.resource,
    this.reference,
    this.context,
  );

  /// Opens the panel's editing of [document] and binds [resource] to it.
  Future<MapEntriesFixture> open() async {
    workspace = await testWorld([
      signedIn(ada, organization: acme),
      realmServing(document),
    ]).openRealmEditing();
    binding = workspace.attach(
      resource,
      policy: EditorCommitPolicy.applyResource,
    );
    addTearDown(binding.detach);
    return this;
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
      role: skir.PresentationRole.workspace,
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

  /// The value the Realm prepares for [request]: an Entry named [name],
  /// with a preparation finding when [finding] is true.
  skir.PreparedValue prepared(
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
}
