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
    this.readOnly = false,
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
  final bool readOnly;
  final bool fillAvailableSpace;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    useListenable(edit);
    final observation = edit?.document ?? document;
    final scope = ref.watch(selectedAuthoringScopeProvider);
    final projected = scope == null
        ? null
        : ref.watch(resourceIssuesProvider(scope));
    final issues =
        projected?.value ?? ResourceIssues.evaluate(document: observation);
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
      resourceAction: scope == null
          ? null
          : (action, invocation) async {
              final selected = ref
                  .read(selectionProvider)
                  .whereType<AuthoringResourceIdentifier>()
                  .where((item) => item.scope == scope)
                  .map((item) => item.resourceId)
                  .toList();
              final targets = selected.contains(resource)
                  ? selected
                  : [resource];
              final runner = ResourceOperationRunner(
                ref: ref,
                context: context,
                scope: scope,
                workspace:
                    edit?.workspace ?? ref.read(realmEditingProvider(scope)),
                commands: ref.read(authoredResourceCommandsProvider(scope)),
                invocation: captureResourceOperationInvocation(
                  document: observation,
                  targets: targets,
                ),
                label: "Resource action",
                canMutate: () =>
                    context.mounted &&
                    enabled &&
                    !readOnly &&
                    edit != null &&
                    !edit!.blocked,
              );
              try {
                await ResourceActionDispatcher(
                  catalog: catalog,
                  context: invocation.withBindings(
                    resourceActionContext(observation, targets).bindings,
                  ),
                  isCurrent: () => runner.isCurrent,
                  navigate: runner.navigate,
                  invokeCommand: runner.invokeCommand,
                  reload: runner.reload,
                  prepare: runner.prepare,
                ).dispatch(action);
                return const PortablePresentationWriteApplied();
              } on Object catch (error) {
                return PortablePresentationWriteResult.rejected([
                  PortablePresentationDiagnostic(
                    code: "resource_action_failed",
                    message: error.toString(),
                    severity: skir.DiagnosticSeverity.error,
                  ),
                ]);
              } finally {
                runner.dispose();
              }
            },
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
              readOnly: readOnly || edit == null,
              prepareValue: prepareValue,
              issues: issues,
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
      issues: issues,
      capabilities: capabilities,
      available: enabled,
      readOnly: readOnly || edit == null,
      prepareValue: prepareValue,
    );
    if (record == null) {
      return _diagnostic(context, "The authored resource is absent");
    }
    final presentation = switch (selected) {
      SelectedEditorPresentation() => _renderSelected(
        host!,
        capabilities,
        authoringScope: scope,
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
    if (scope == null) return presentation;
    return PortableLocationRevealScope(
      presentation: role,
      controller: ref.watch(realmLocationRevealProvider(scope)),
      child: PortableLocationTarget(
        focusWhenEmpty: role == skir.PresentationRole.inspector,
        location: skir.ValueLocation(
          resource: resource,
          path: skir.ValuePath(segments: const []),
        ),
        child: presentation,
      ),
    );
  }

  Widget _renderSelected(
    AuthoredPresentationHost host,
    PortablePresentationCapabilities capabilities, {
    required AuthoringScope? authoringScope,
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
            queries: document.queries,
            resourceDiagnostics: document.resourceDiagnostics,
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
    if (authoringScope == null) return renderer;
    return AuthoredPageInteractions(
      authoringScope: authoringScope,
      binding: edit,
      prepareValue: prepareValue,
      child: renderer,
    );
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
