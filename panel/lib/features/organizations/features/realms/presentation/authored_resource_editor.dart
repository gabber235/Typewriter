import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";

final class AuthoredResourceEditor extends HookConsumerWidget {
  const AuthoredResourceEditor({
    required this.resource,
    required this.document,
    required this.role,
    required this.budget,
    this.edit,
    this.openResource,
    this.prepareValue,
    this.invokeCommand,
    this.watchSearch,
    this.reload,
    this.onStatus,
    this.enabled = true,
    this.fillAvailableSpace = false,
    super.key,
  });

  final skir.ResourceId resource;
  final AuthoringDocument document;
  final RealmEditingBinding? edit;
  final skir.PresentationRole role;
  final skir.EvaluationBudget budget;
  final ValueChanged<skir.ResourceId>? openResource;
  final Future<skir.PreparedValue> Function(
    skir.ValuePreparationRequest request,
  )?
  prepareValue;
  final Future<void> Function(
    skir.CapabilityId capabilityId,
    skir.DataValue payload,
  )?
  invokeCommand;
  final Stream<skir.RealmPresentationSearchUpdate> Function(
    skir.RealmPresentationSearchRequest request,
  )?
  watchSearch;
  final Future<void> Function()? reload;
  final ValueChanged<String>? onStatus;
  final bool enabled;
  final bool fillAvailableSpace;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    useListenable(edit);
    final observation = edit?.document ?? document;
    final workScope = ref.watch(localWorkScopeProvider);
    final record = observation.resource(resource);
    final catalog = observation.catalog;
    final selected = record == null
        ? null
        : catalog.selectPresentation(record.configuration, role);
    final capabilities = PortablePresentationCapabilities(
      invokeCommand: invokeCommand,
      watchSearch: watchSearch,
      reload: reload,
      openResource: openResource,
      prepareValue: prepareValue,
    );
    final host = useMemoized(
      () => selected is SelectedEditorPresentation
          ? AuthoredPresentationHost(
              resource: resource,
              source: observation,
              edit: edit,
              material: selected.material,
              role: selected.resolvedRole,
              budget: budget,
              capabilities: capabilities,
              available: enabled,
              readOnly: edit == null,
              prepareValue: prepareValue,
            )
          : null,
      [
        resource,
        edit,
        switch (selected) {
          SelectedEditorPresentation(:final material) => material,
          _ => null,
        },
        if (selected is SelectedEditorPresentation)
          selected.resolvedRole
        else
          null,
        budget,
      ],
    );
    useEffect(() => host?.dispose, [host]);
    host?.update(
      source: observation,
      capabilities: capabilities,
      available: enabled,
      readOnly: edit == null,
      prepareValue: prepareValue,
    );
    final scope = ref.watch(selectedAuthoringScopeProvider);
    if (record == null) {
      return _diagnostic(context, "The authored resource is absent");
    }
    final rendered = switch (selected) {
      SelectedEditorPresentation() => _renderSelected(
        host!,
        capabilities,
        searchHistoryNamespace: workScope.searchHistoryNamespace,
      ),
      MissingEditorPresentation() => _diagnostic(
        context,
        "No presentation is available for this authored resource",
      ),
      ConflictingEditorPresentation(:final candidates) => _diagnostic(
        context,
        "The authored resource has ${candidates.length} conflicting presentations",
      ),
      null => _diagnostic(context, "The authored resource is absent"),
      UnavailableEditorPresentation(:final presentation) => _diagnostic(
        context,
        "Presentation ${presentation.namespace}:${presentation.name} is unavailable",
      ),
    };
    if (scope == null) return rendered;
    return PortableLocationRevealScope(
      controller: ref.watch(realmLocationRevealProvider(scope)),
      child: PortableLocationTarget(
        location: skir.ValueLocation(
          resource: resource,
          path: skir.ValuePath(segments: const []),
        ),
        child: rendered,
      ),
    );
  }

  Widget _renderSelected(
    AuthoredPresentationHost host,
    PortablePresentationCapabilities capabilities, {
    required String? searchHistoryNamespace,
  }) {
    final renderer = PortablePresentationRenderer(
      key: ValueKey(resource),
      host: host,
      fillAvailableSpace: fillAvailableSpace,
      onStatus: onStatus,
      scopeBuilder:
          ({
            required host,
            required document,
            required bindings,
            required reportStatus,
            required operations,
          }) => PortablePresentationScope(
            bindings: bindings,
            budget: document.budget,
            enabled: host.enabled,
            readOnly: host.readOnly,
            watchSearch: capabilities.watchSearch,
            openResource: capabilities.openResource,
            reportStatus: reportStatus,
            operations: operations,
            catalog: document.catalog,
            resource: resource,
            searchHistoryNamespace: searchHistoryNamespace,
            role: document.role,
            material: document.material,
            activePresentations: document.activePresentations,
            slots: document.slots,
            host: host,
          ),
    );
    return renderer;
  }
}

extension on LocalWorkScope {
  String? get searchHistoryNamespace => when((user, organization) {
    if (user == null || organization == null) return null;
    return "user:$user:organization:${organization.id}";
  });
}

Widget _diagnostic(BuildContext context, String message) => Text(
  message,
  style: context.theme.textTheme.bodyMedium?.copyWith(
    color: context.colors.danger,
  ),
);
