import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";

final class AuthoredResourceEditor extends StatefulWidget {
  const AuthoredResourceEditor({
    required this.resource,
    required this.document,
    required this.role,
    required this.budget,
    this.edit,
    this.openResource,
    this.prepareCreation,
    this.invokeCommand,
    this.watchSearch,
    this.reload,
    this.onStatus,
    this.commit,
    this.enabled = true,
    this.fillAvailableSpace = false,
    super.key,
  });

  final skir.ResourceId resource;
  final AuthoringDocument document;
  final AuthoringBinding? edit;
  final skir.PresentationRole role;
  final skir.EvaluationBudget budget;
  final ValueChanged<skir.ResourceId>? openResource;
  final Future<skir.PreparedCreation> Function(
    skir.InitializationRequest request,
  )?
  prepareCreation;
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
  final Future<void> Function()? commit;
  final bool enabled;
  final bool fillAvailableSpace;

  @override
  State<AuthoredResourceEditor> createState() => _AuthoredResourceEditorState();
}

final class _AuthoredResourceEditorState extends State<AuthoredResourceEditor> {
  AuthoredPresentationHost? _host;
  AuthoringDocument get _document => widget.edit?.document ?? widget.document;
  void _updated() {
    if (mounted) setState(() {});
  }

  @override
  void initState() {
    super.initState();
    widget.edit?.addListener(_updated);
  }

  @override
  void didUpdateWidget(covariant AuthoredResourceEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.edit != widget.edit) {
      oldWidget.edit?.removeListener(_updated);
      widget.edit?.addListener(_updated);
    }
  }

  @override
  void dispose() {
    widget.edit?.removeListener(_updated);
    _host?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final record = _document.resource(widget.resource);
    if (record == null) {
      return _diagnostic(context, "The authored resource is absent");
    }
    final catalog = _document.catalog;
    final localRules = AuthoredRuleProjection.evaluate(
      draft: _document,
      catalog: catalog,
      resource: widget.resource,
      budget: widget.budget,
    );
    final selected = catalog.selectPresentation(
      record.configuration,
      widget.role,
    );
    return switch (selected) {
      SelectedEditorPresentation(:final material) => _renderSelected(
        selected,
        material,
        localRules,
      ),
      MissingEditorPresentation() => _diagnostic(
        context,
        "No presentation is available for this authored resource",
      ),
      ConflictingEditorPresentation(:final candidates) => _diagnostic(
        context,
        "The authored resource has ${candidates.length} conflicting presentations",
      ),
      UnavailableEditorPresentation(:final presentation) => _diagnostic(
        context,
        "Presentation ${presentation.namespace}:${presentation.name} is unavailable",
      ),
    };
  }

  Widget _renderSelected(
    SelectedEditorPresentation selected,
    skir.PresentationMaterial material,
    AuthoredRuleProjection localRules,
  ) {
    final capabilities = PortablePresentationCapabilities(
      invokeCommand: widget.invokeCommand,
      watchSearch: widget.watchSearch,
      reload: widget.reload,
      commit: widget.commit,
      openResource: widget.openResource,
      prepareCreation: widget.prepareCreation,
    );
    final showsFullDiagnostics =
        widget.role == skir.PresentationRole.editor ||
        widget.role == skir.PresentationRole.inspector;
    var authoredHost = _host;
    if (authoredHost == null ||
        authoredHost.resource != widget.resource ||
        authoredHost.edit != widget.edit ||
        authoredHost.material != material ||
        authoredHost.role != selected.resolvedRole ||
        authoredHost.budget != widget.budget) {
      authoredHost?.dispose();
      authoredHost = _host = AuthoredPresentationHost(
        resource: widget.resource,
        source: _document,
        edit: widget.edit,
        material: material,
        role: selected.resolvedRole,
        budget: widget.budget,
        capabilities: capabilities,
        available: widget.enabled,
        readOnly: widget.edit == null,
        prepareCreation: widget.prepareCreation,
        reportStatus: widget.onStatus,
      );
    } else {
      authoredHost.update(
        source: _document,
        capabilities: capabilities,
        available: widget.enabled,
        readOnly: widget.edit == null,
        prepareCreation: widget.prepareCreation,
        reportStatus: widget.onStatus,
      );
    }
    final installedHost = authoredHost;
    final renderer = PortablePresentationRenderer(
      host: installedHost,
      fillAvailableSpace: widget.fillAvailableSpace,
      onStatus: widget.onStatus,
      compactDiagnostics: showsFullDiagnostics
          ? const []
          : [
              for (final diagnostic in localRules.diagnostics)
                skir.DiagnosticTemplate(
                  code: diagnostic.code,
                  message: diagnostic.message,
                  severity: diagnostic.severity,
                  targets: const [],
                ),
            ],
      scopeBuilder:
          ({
            required host,
            required document,
            required bindings,
            required setBinding,
            required reportStatus,
          }) => PortablePresentationScope(
            bindings: bindings,
            budget: document.budget,
            setBinding: setBinding,
            enabled: host.enabled,
            readOnly: host.readOnly,
            invokeCommand: capabilities.invokeCommand,
            watchSearch: capabilities.watchSearch,
            reload: capabilities.reload,
            commit: capabilities.commit,
            openResource: capabilities.openResource,
            prepareCreation: capabilities.prepareCreation,
            reportStatus: reportStatus,
            authoring: installedHost.authored,
            catalog: document.catalog,
            resource: widget.resource,
            role: document.role,
            material: document.material,
            activePresentations: document.activePresentations,
            slots: document.slots,
            host: host,
          ),
    );
    if (!showsFullDiagnostics) return renderer;
    if (widget.role == skir.PresentationRole.inspector &&
        localRules.diagnostics.isEmpty) {
      return renderer;
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final diagnostic in localRules.diagnostics)
          _localDiagnostic(diagnostic),
        if (widget.role == skir.PresentationRole.editor)
          Expanded(child: renderer)
        else
          renderer,
      ],
    );
  }
}

Widget _diagnostic(BuildContext context, String message) => Text(
  message,
  style: context.theme.textTheme.bodyMedium?.copyWith(
    color: context.colors.danger,
  ),
);

Widget _localDiagnostic(AuthoredLocalDiagnostic diagnostic) => Builder(
  builder: (context) => Semantics(
    liveRegion: true,
    child: Text(
      diagnostic.message,
      style: context.theme.textTheme.bodyMedium?.copyWith(
        color: diagnostic.severity == skir.DiagnosticSeverity.warning
            ? context.colors.warning
            : context.colors.danger,
      ),
    ),
  ),
);
