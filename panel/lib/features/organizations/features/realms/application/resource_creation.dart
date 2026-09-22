import "package:flutter/material.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";

final resourceCreationProvider = Provider<ResourceCreationSession>(
  ResourceCreationSession.new,
);

final class ResourceCreationRequest {
  factory ResourceCreationRequest({
    required AuthoringCreationSlotId slot,
    required String title,
    required ResolvedTypeRef concreteRoot,
    DataValue? partial,
    List<skir.ResourceId> hosts = const [],
    List<skir.ResourceId> referenceOrigins = const [],
  }) {
    final id = newResourceId();
    return ResourceCreationRequest._(
      id: id,
      slot: slot,
      title: title,
      concreteRoot: concreteRoot,
      partial: partial,
      hosts: List.unmodifiable(hosts),
      referenceOrigins: List.unmodifiable(referenceOrigins),
    );
  }

  const ResourceCreationRequest._({
    required this.id,
    required this.slot,
    required this.title,
    required this.concreteRoot,
    required this.partial,
    required this.hosts,
    required this.referenceOrigins,
  });

  final skir.ResourceId id;
  final AuthoringCreationSlotId slot;
  final String title;
  final ResolvedTypeRef concreteRoot;
  final DataValue? partial;
  final List<skir.ResourceId> hosts;
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
    final slot = catalog.creationSlots[request.slot];
    if (slot == null) {
      throw ApiException.badRequest("Creation slot is unavailable");
    }
    if (!slot.acceptsRoot(request.concreteRoot)) {
      throw ApiException.badRequest(
        "Concrete root is not accepted by the creation slot",
      );
    }
    _validateHosts(slot, request.hosts);
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
    final suppliedPartial = slot.bindHostReferences(basePartial, request.hosts);
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
          resource: codec.encodeResource(request.id, slot.creates, content),
          creationSlot: skir.AuthoringCreationSlotId(value: slot.id.value),
          hosts: request.hosts,
        ),
      ];
      final response = await access.notifier.apply(operations);
      response.requireApplied(conflictMessage: "The resource already exists");
      return (id: request.id, definition: slot.creates, content: content);
    } finally {
      draft.dispose();
    }
  }

  void _validateHosts(
    RealmAuthoringCreationSlot slot,
    List<skir.ResourceId> hosts,
  ) {
    final cardinality = switch (slot.context) {
      RealmStandaloneCreationContext() => null,
      RealmDeclaredRelationCreationContext(:final cardinality) => cardinality,
      RealmReferencePathCreationContext(:final cardinality) => cardinality,
    };
    switch (cardinality) {
      case null when hosts.isNotEmpty:
        throw ApiException.badRequest(
          "Standalone creation does not accept hosts",
        );
      case RealmCreationHostCardinality.exactlyOne when hosts.length != 1:
        throw ApiException.badRequest("Creation requires exactly one host");
      case RealmCreationHostCardinality.oneOrMore when hosts.isEmpty:
        throw ApiException.badRequest("Creation requires at least one host");
      default:
        break;
    }
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

extension RealmAuthoringCreationReferenceBinding on RealmAuthoringCreationSlot {
  DataValue? bindHostReferences(
    DataValue? partial,
    List<skir.ResourceId> hosts,
  ) {
    final context = this.context;
    if (context case RealmReferencePathCreationContext(
      :final path,
      :final cardinality,
    )) {
      final value = switch (cardinality) {
        RealmCreationHostCardinality.exactlyOne => ReferenceValue(hosts.single),
        RealmCreationHostCardinality.oneOrMore => ListValue([
          for (final host in hosts) ReferenceValue(host),
        ]),
      };
      return path.replace(partial ?? RecordValue({}), value).valueOrNull ??
          (throw ApiException.badRequest("Creation host path is invalid"));
    }
    return partial;
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
