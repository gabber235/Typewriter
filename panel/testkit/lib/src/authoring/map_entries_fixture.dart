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
    final resource = skir.ResourceId(value: "map:owner");
    final map = typedValue(
      "Entries",
      skir.DataValue.createMapValue(rows: const []),
    );
    final document = authoredDoc(
      [
        authoredRecord(resource, {"entries": map}, type: typeUse("Owner")),
      ],
      catalog: authoredCatalog([
        declaredRecord(
          "Owner",
          fields: {"entries": "Entries"},
          defaulted: {"entries"},
        ),
        declaredRecord(
          "Entry",
          fields: {"name": skir.ScalarKind.text},
          defaulted: {"name"},
        ),
        declaredMap("Entries", key: "Entry", value: "Entry"),
      ], generation: "map:creation"),
    ).document;
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
