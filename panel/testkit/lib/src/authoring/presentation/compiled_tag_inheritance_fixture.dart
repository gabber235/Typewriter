import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";

import "package:typewriter_testkit/typewriter_testkit.dart";

final compiledInheritanceBookId = skir.ResourceId(value: "book:inheritance");
final compiledInheritanceTagId = skir.ResourceId(value: "tag:inheritance");

/// Builds real SDK records and relationships without reproducing their layout.
/// Both inspectors use the same roots so stories can compare their composition.
AuthoringDocument compiledTagInheritanceDocument({
  required List<Tag> tags,
  required List<skir.ResourceId> roots,
}) {
  final catalog = CheckedEditorCatalog(compiledSdkControlCatalog);
  skir.AuthoringResource resource(
    skir.ResourceId id,
    skir.AuthoringRecord template,
    Map<String, skir.DataValue> fields,
  ) => skir.AuthoringResource(
    id: id,
    content: skir.AuthoringRecord(
      configuration: template.configuration,
      fields: [
        for (final field in template.fields)
          skir.FieldValue(
            name: field.name,
            value: fields[field.name] ?? field.value,
          ),
      ],
    ),
  );

  final edit = AuthoringEdit(
    generation: catalog.snapshot.generation,
    catalog: catalog,
    resources: [
      resource(compiledInheritanceBookId, compiledSdkBookRecord, {
        "title": skir.DataValue.wrapStringValue("Inheritance example"),
      }),
      resource(compiledInheritanceTagId, compiledSdkTagRecord, {
        "name": skir.DataValue.wrapStringValue("Inheritance subject"),
      }),
      for (final tag in tags)
        resource(tag.tagId, compiledSdkTagRecord, {
          "name": skir.DataValue.wrapStringValue(tag.name),
          "color": skir.DataValue.createNamed(
            actualType: compiledSdkTagRecord
                .authoredField("color")!
                .authoredActualType!,
            payload: tag.color.asValue,
          ),
        }),
    ],
    links: const [],
  );

  void connect(
    skir.ResourceId source,
    String field,
    List<skir.ResourceId> targets,
  ) {
    for (final target in targets) {
      final path = skir.ValuePath(
        segments: [
          skir.PathSegment.createField(name: field),
          skir.PathSegment.createItem(id: skir.ItemId(value: target.value)),
        ],
      );
      final endpoint = catalog
          .endpointBindingsAt(edit.resources[source]!.configuration, path)
          .single
          .template
          .endpoint;
      edit.connect(
        skir.LinkOccurrence(
          id: skir.LinkOccurrenceId(
            endpoint: endpoint,
            location: skir.ValueLocation(resource: source, path: path),
          ),
          source: source,
          target: skir.LinkTarget(resource: target, opposite: null),
        ),
        target,
      );
    }
  }

  for (final tag in tags) {
    connect(tag.tagId, "parents", tag.parentIds);
  }
  connect(compiledInheritanceBookId, "tags", roots);
  connect(compiledInheritanceTagId, "parents", roots);
  return edit.toDocument();
}

/// Keeps the real inspector and local workspace mounted across story rebuilds.
class CompiledTagInheritanceInspector extends StatefulWidget {
  const CompiledTagInheritanceInspector({
    required this.document,
    required this.resource,
    super.key,
  });

  final AuthoringDocument document;
  final skir.ResourceId resource;

  @override
  State<CompiledTagInheritanceInspector> createState() =>
      _CompiledTagInheritanceInspectorState();
}

class _CompiledTagInheritanceInspectorState
    extends State<CompiledTagInheritanceInspector> {
  late final _transport = ScriptedAuthoringTransport(
    AsyncData(widget.document),
  );
  final _submissions = ScopedWorkSession();
  late final _workspace = RealmEditing(
    persistence: _transport.persistence,
    submissions: _submissions,
    initial: widget.document,
  );

  @override
  void dispose() {
    _workspace.dispose();
    _transport.dispose();
    _submissions.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SingleChildScrollView(
      child: AuthoredResourceInspection(
        resource: widget.resource,
        workspace: _workspace,
        commands: fixtureAuthoringCommands(_transport),
        commitPolicy: EditorCommitPolicy.applyResource,
      ),
    ),
  );
}
