import "package:flutter/material.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:riverpod_annotation/riverpod_annotation.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";

part "resource_creation.g.dart";

@Riverpod(keepAlive: true)
ResourceCreationSession resourceCreation(Ref ref) =>
    ResourceCreationSession(ref);

final class ResourceCreationRequest {
  factory ResourceCreationRequest({
    required ResourceDefinitionId definition,
    required String title,
    required ResolvedTypeRef concreteRoot,
    skir.CreationAttachment? attachment,
    List<skir.CreationAttachment> links = const [],
    DataValue? partial,
    List<skir.ResourceId> referenceOrigins = const [],
  }) {
    final id = newResourceId();
    return ResourceCreationRequest._(
      id: id,
      definition: definition,
      attachment: attachment,
      links: List.unmodifiable(links),
      title: title,
      concreteRoot: concreteRoot,
      partial: partial,
      referenceOrigins: List.unmodifiable(referenceOrigins),
    );
  }

  const ResourceCreationRequest._({
    required this.id,
    required this.definition,
    required this.attachment,
    required this.links,
    required this.title,
    required this.concreteRoot,
    required this.partial,
    required this.referenceOrigins,
  });

  final skir.ResourceId id;
  final ResourceDefinitionId definition;
  final skir.CreationAttachment? attachment;
  final List<skir.CreationAttachment> links;
  final String title;
  final ResolvedTypeRef concreteRoot;
  final DataValue? partial;
  final List<skir.ResourceId> referenceOrigins;
}

typedef CreatedAuthoringResource = ({
  skir.ResourceId id,
  ResourceDefinitionId definition,
  TypedValueEnvelope content,
});

final class ResourceCreationSession {
  const ResourceCreationSession(this.ref);

  final Ref ref;

  Future<CreatedAuthoringResource?> create({
    required BuildContext context,
    required ResourceCreationRequest request,
  }) async {
    final organizationId = ref.read(organizationIdProvider);
    final realmId = ref.read(realmIdProvider);
    if (organizationId == null || realmId == null) {
      throw StateError("No Realm is selected");
    }
    final catalog = ref.read(realmEditorCatalogProvider).value?.snapshot;
    if (catalog == null) throw StateError("The editor catalog is unavailable");
    final definition = catalog.resourceDefinitions[request.definition];
    if (definition == null ||
        !NamedType(request.concreteRoot).isStructurallyAssignableTo(
          definition.acceptedRoot,
          TypeRegistry(catalog.catalog),
        )) {
      throw ApiException.badRequest("Concrete root is unavailable");
    }
    final codec = TypedAuthoringCodec(catalog);
    final route = RealmEditorCatalogRoute(
      organizationId: organizationId,
      realmId: realmId,
    );
    final source = ref.read(realmEditorCatalogSourceProvider);
    final initializeConcreteType = source.concreteTypeInitializer(
      route: route,
      generation: catalog.generation,
      registry: codec.registry,
    );
    final basePartial = (await source.initialize(
      route,
      generation: catalog.generation,
      root: request.concreteRoot,
      supplied: request.partial,
      registry: codec.registry,
    )).creationDraftValue;
    final suppliedPartial = _bindAttachment(catalog, request, basePartial);
    final supplied = (await source.initialize(
      route,
      generation: catalog.generation,
      root: request.concreteRoot,
      supplied: suppliedPartial,
      registry: codec.registry,
    )).creationDraftValue;
    if (!context.mounted) return null;
    final draft = supplied == null
        ? CreationDraft(
            rootType: NamedType(request.concreteRoot),
            registry: codec.registry,
            concreteTypeInitializer: initializeConcreteType,
          )
        : CreationDraft.fromMaterialized(
            rootType: NamedType(request.concreteRoot),
            value: supplied,
            registry: codec.registry,
            concreteTypeInitializer: initializeConcreteType,
          );
    try {
      final value = await promptResourceCreationEditor(
        context: context,
        title: request.title,
        draft: draft,
        presentations: catalog.presentations.values.toList(),
        origins: request.referenceOrigins,
      );
      if (value == null || !ref.mounted) return null;
      final completed = await source.initialize(
        route,
        generation: catalog.generation,
        root: request.concreteRoot,
        supplied: value,
        registry: codec.registry,
      );
      final content = switch (completed) {
        RealmTypedValueInitialized(:final value) => value,
        RealmTypedValueInitializationNeedsInput(:final draft) =>
          throw ApiException.badRequest(
            draft.requirements
                .map((requirement) => requirement.path.toString())
                .join("; "),
          ),
        RealmTypedValueInitializationGenerationMismatch() =>
          throw ApiException.conflict("The Realm catalog changed"),
        RealmTypedValueInitializationRejected(:final diagnostics) =>
          throw ApiException.badRequest(
            diagnostics.map((item) => item.message).join("; "),
          ),
      };
      final access = ref.readAuthoringSession();
      final operations = <skir.AuthoringOperation>[
        skir.AuthoringOperation.createCreate(
          resource: codec.encodeResource(
            request.id,
            request.definition,
            content,
          ),
          attachment: request.attachment,
        ),
        for (final link in request.links)
          skir.AuthoringOperation.createDeclareRelation(
            relation: link.relation,
            source: link.hostSide == skir.RelationEndpointSide.source
                ? link.host
                : request.id,
            target: link.hostSide == skir.RelationEndpointSide.source
                ? request.id
                : link.host,
            sourceBefore: null,
            targetBefore: null,
          ),
      ];
      final response = await access.notifier.apply(operations);
      response.requireApplied(conflictMessage: "The resource already exists");
      return (id: request.id, definition: request.definition, content: content);
    } finally {
      draft.dispose();
    }
  }

  DataValue? _bindAttachment(
    RealmEditorCatalogSnapshot catalog,
    ResourceCreationRequest request,
    DataValue? partial,
  ) {
    final registry = TypeRegistry(catalog.catalog);
    var supplied = partial;
    for (final attachment in [?request.attachment, ...request.links]) {
      final relation = catalog.relations[attachment.relation.value];
      if (relation == null) {
        throw ApiException.badRequest("Relation is unavailable");
      }
      final inverse = attachment.hostSide == skir.RelationEndpointSide.source
          ? relation.targetEndpoint
          : relation.sourceEndpoint;
      if (inverse == null ||
          !NamedType(request.concreteRoot)
              .isStructurallyAssignableTo(NamedType(inverse.owner), registry)) {
        continue;
      }
      final current = supplied ?? RecordValue({});
      final value = inverse.cardinality == RealmRelationCardinality.one
          ? ReferenceValue(attachment.host)
          : ListValue([
              if (inverse.path.read(current).valueOrNull case ListValue(
                :final values,
              ))
                ...values,
              ReferenceValue(attachment.host),
            ]);
      supplied =
          inverse.path.replace(current, value).valueOrNull ??
          (throw ApiException.badRequest("Creation relation path is invalid"));
    }
    return supplied;
  }
}

extension on RealmTypedValueInitializationResult {
  DataValue? get creationDraftValue => switch (this) {
    RealmTypedValueInitialized(:final value) => value.rootValue,
    RealmTypedValueInitializationNeedsInput(:final draft) =>
      draft.suppliedValue,
    RealmTypedValueInitializationGenerationMismatch() =>
      throw ApiException.conflict("The Realm catalog changed"),
    RealmTypedValueInitializationRejected(:final diagnostics) =>
      throw ApiException.badRequest(
        diagnostics.map((item) => item.message).join("; "),
      ),
  };
}

Future<DataValue?> promptResourceCreationEditor({
  required BuildContext context,
  required String title,
  required CreationDraft draft,
  required List<PresentationDefinition> presentations,
  required List<skir.ResourceId> origins,
}) => showAdvancedDialog<DataValue>(
  context: context,
  fullscreenDialog: context.isMobile,
  builder: (dialogContext) => ResourceCreationDialog(
    title: title,
    draft: draft,
    presentations: presentations,
    origins: origins,
    onCancel: () => Navigator.of(dialogContext).pop(),
    onCreate: (value) => Navigator.of(dialogContext).pop(value),
  ),
);

final class ResourceCreationDialog extends StatelessWidget {
  const ResourceCreationDialog({
    required this.title,
    required this.draft,
    required this.presentations,
    required this.origins,
    required this.onCancel,
    required this.onCreate,
    super.key,
  });

  final String title;
  final CreationDraft draft;
  final List<PresentationDefinition> presentations;
  final List<skir.ResourceId> origins;
  final VoidCallback onCancel;
  final ValueChanged<DataValue> onCreate;

  @override
  Widget build(BuildContext context) {
    final editor = _ResourceCreationEditor(
      title: title,
      draft: draft,
      presentations: presentations,
      origins: origins,
      onCancel: onCancel,
      onCreate: onCreate,
    );
    if (context.isMobile) {
      return Dialog.fullscreen(child: SafeArea(child: editor));
    }
    return Dialog(
      insetPadding: const EdgeInsets.all(24),
      constraints: const BoxConstraints(maxWidth: 840, maxHeight: 900),
      clipBehavior: Clip.antiAlias,
      child: SizedBox.expand(child: editor),
    );
  }
}

final class _ResourceCreationEditor extends ConsumerStatefulWidget {
  const _ResourceCreationEditor({
    required this.title,
    required this.draft,
    required this.presentations,
    required this.origins,
    required this.onCancel,
    required this.onCreate,
  });

  final String title;
  final CreationDraft draft;
  final List<PresentationDefinition> presentations;
  final List<skir.ResourceId> origins;
  final VoidCallback onCancel;
  final ValueChanged<DataValue> onCreate;

  @override
  ConsumerState<_ResourceCreationEditor> createState() =>
      _ResourceCreationEditorState();
}

final class _ResourceCreationEditorState
    extends ConsumerState<_ResourceCreationEditor> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    widget.draft.addListener(_changed);
  }

  @override
  void didUpdateWidget(_ResourceCreationEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.draft == widget.draft) return;
    oldWidget.draft.removeListener(_changed);
    widget.draft.addListener(_changed);
  }

  void _changed() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final runtime = ref.watch(editorRealmRuntimeProvider);
    final result = widget.draft.finalize();
    final value = result.valueOrNull;
    final model = PresentationModel.editor(
      owner: widget.draft,
      preferredRole: PresentationRole.creation,
      presentations: widget.presentations,
      diagnostics: result.diagnostics,
    );

    return Surface(
      color: DialogTheme.of(context).backgroundColor!,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
            child: Text(
              widget.title,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
          ),
          Expanded(
            child: Scrollbar(
              controller: _scrollController,
              child: SingleChildScrollView(
                controller: _scrollController,
                padding: const EdgeInsets.all(24),
                child: ComposedEditor(
                  model: model,
                  host: runtime?.host() ?? const EditorHostCapabilities(),
                  referenceOrigins: widget.origins,
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 16),
            child: OverflowBar(
              alignment: MainAxisAlignment.end,
              spacing: 8,
              overflowAlignment: OverflowBarAlignment.end,
              children: [
                TextButton(
                  onPressed: widget.onCancel,
                  child: const Text("Cancel"),
                ),
                FilledButton(
                  onPressed: value == null
                      ? null
                      : () => widget.onCreate(value),
                  child: const Text("Create"),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    widget.draft.removeListener(_changed);
    _scrollController.dispose();
    super.dispose();
  }
}
