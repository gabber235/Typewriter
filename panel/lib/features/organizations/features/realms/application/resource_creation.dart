import "package:flutter/material.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";

final resourceCreationProvider = Provider<ResourceCreationSession>(
  ResourceCreationSession.new,
);

final class ResourceRelationAttachment {
  const ResourceRelationAttachment.toMany({
    required this.owner,
    required this.path,
  });

  final skir.ResourceId owner;
  final DataPath path;
}

final class ResourceCreationRequest {
  factory ResourceCreationRequest({
    required skir.ResourceKind kind,
    required String title,
    required DataValue partial,
    ResolvedTypeRef? root,
    List<ResourceRelationAttachment> relations = const [],
    List<skir.ResourceId> referenceOrigins = const [],
  }) {
    final id = newResourceId();
    return ResourceCreationRequest._(
      id: id,
      kind: kind,
      title: title,
      root: root,
      partial: partial,
      relationAttachments: List.unmodifiable(relations),
      referenceOrigins: List.unmodifiable(referenceOrigins),
    );
  }

  const ResourceCreationRequest._({
    required this.id,
    required this.kind,
    required this.title,
    required this.root,
    required this.partial,
    required this.relationAttachments,
    required this.referenceOrigins,
  });

  final skir.ResourceId id;
  final skir.ResourceKind kind;
  final String title;
  final ResolvedTypeRef? root;
  final DataValue partial;
  final List<ResourceRelationAttachment> relationAttachments;
  final List<skir.ResourceId> referenceOrigins;
}

typedef CreatedAuthoringResource = ({
  skir.ResourceId id,
  skir.ResourceKind kind,
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
    final codec = TypedAuthoringCodec(catalog);
    final root = request.root ?? codec.requireDefaultRoot(request.kind);
    final initialized = await ref
        .read(realmEditorCatalogSourceProvider)
        .initialize(
          RealmEditorCatalogRoute(
            organizationId: organizationId,
            realmId: realmId,
          ),
          generation: catalog.generation,
          partial: TypedValueEnvelope(
            rootType: root,
            rootValue: request.partial,
          ),
          registry: codec.registry,
        );
    final materialized = switch (initialized) {
      RealmTypedValueInitialized(:final value) => value,
      RealmTypedValueInitializationGenerationMismatch() =>
        throw ApiException.conflict("The Realm catalog changed"),
      RealmTypedValueInitializationRejected(:final diagnostics) =>
        throw ApiException.badRequest(
          diagnostics.map((item) => item.message).join("; "),
        ),
    };
    if (!context.mounted) return null;
    final draft = CreationDraft.fromMaterialized(
      rootType: NamedType(materialized.rootType),
      value: materialized.rootValue,
      registry: codec.registry,
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
      final content = materialized.copyWith(rootValue: value);
      final access = ref.readAuthoringSession();
      final operations = <skir.AuthoringOperation>[
        skir.AuthoringOperation.createCreate(
          resource: codec.encodeResource(request.id, request.kind, content),
        ),
        ..._attachments(
          access.state,
          codec,
          request.id,
          request.relationAttachments,
        ),
      ];
      final response = await access.notifier.apply(operations);
      response.requireApplied(conflictMessage: "The resource already exists");
      return (id: request.id, kind: request.kind, content: content);
    } finally {
      draft.dispose();
    }
  }

  List<skir.AuthoringOperation> _attachments(
    AuthoringSessionState state,
    TypedAuthoringCodec codec,
    skir.ResourceId target,
    List<ResourceRelationAttachment> attachments,
  ) {
    final sequence = state.sequence;
    if (sequence == null) throw ApiException.notFound("Relation owner");
    final grouped = <skir.ResourceId, List<ResourceRelationAttachment>>{};
    for (final attachment in attachments) {
      grouped.putIfAbsent(attachment.owner, () => []).add(attachment);
    }
    final pathCodec = SkirEditorCodec(codec.registry);
    return [
      for (final group in grouped.entries)
        () {
          final owner = state.resources[group.key];
          if (owner == null) throw ApiException.notFound("Relation owner");
          final decoded = codec.decodeResourceOrThrow(owner);
          var rootValue = decoded.content.rootValue;
          final changedPaths = <DataPath>{};
          for (final attachment in group.value) {
            final current = attachment.path.read(rootValue).valueOrNull;
            if (current is! ListValue) {
              throw ApiException.badRequest(
                "Relation attachment must target a list",
              );
            }
            final replacement = attachment.path
                .replace(
                  rootValue,
                  ListValue([...current.values, ReferenceValue(target)]),
                )
                .valueOrNull;
            if (replacement == null) {
              throw ApiException.badRequest(
                "Relation attachment path is invalid",
              );
            }
            rootValue = replacement;
            changedPaths.add(attachment.path);
          }
          final proposed = owner.toMutable()
            ..content = codec
                .encodeEnvelope(decoded.content.copyWith(rootValue: rootValue))
                .valueOrNull!;
          return skir.AuthoringOperation.createCommit(
            id: owner.id,
            observedSequence: sequence,
            base: owner,
            proposed: proposed,
            changedPaths: [
              for (final path in changedPaths)
                pathCodec.encodePath(path).valueOrNull!,
            ],
          );
        }(),
    ];
  }
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
      presentations: widget.presentations,
      diagnostics: result.diagnostics,
    );
    return Column(
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
                onPressed: value == null ? null : () => widget.onCreate(value),
                child: const Text("Create"),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    widget.draft.removeListener(_changed);
    _scrollController.dispose();
    super.dispose();
  }
}
