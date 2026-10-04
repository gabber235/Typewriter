import "package:flutter/material.dart";
import "package:typewriter_panel/app/presentation/theme/typewriter_theme_access.dart";
import "package:typewriter_panel/features/organizations/features/realms/application/authored_draft.dart";
import "package:typewriter_panel/features/organizations/features/realms/application/authored_draft_presentation_host.dart";
import "package:typewriter_panel/features/organizations/features/realms/application/authored_local_rules.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skirout/editor/v1/catalog.dart"
    as catalog_wire;
import "package:typewriter_panel/infrastructure/protocols/skir/skirout/editor/v1/diagnostic.dart"
    as diagnostic_wire;
import "package:typewriter_panel/infrastructure/protocols/skir/skirout/editor/v1/expression.dart"
    as expression;
import "package:typewriter_panel/infrastructure/protocols/skir/skirout/editor/v1/search.dart"
    as search;
import "package:typewriter_panel/infrastructure/protocols/skir/skirout/editor/v1/type_catalog.dart"
    as types;
import "package:typewriter_panel/shared/editors/application/checked_editor_catalog.dart";
import "package:typewriter_panel/shared/editors/application/portable_presentation_host.dart";
import "package:typewriter_panel/shared/editors/presentation/portable_presentation_renderer.dart";

final class AuthoredResourceEditor extends StatefulWidget {
  const AuthoredResourceEditor({
    required this.resource,
    required this.draft,
    required this.catalog,
    required this.role,
    required this.budget,
    this.onChanged,
    this.openResource,
    this.prepareCreation,
    this.invokeCommand,
    this.watchSearch,
    this.reload,
    this.onStatus,
    this.commit,
    this.enabled = true,
    super.key,
  });

  final types.ResourceId resource;
  final AuthoredDraft draft;
  final CheckedEditorCatalog catalog;
  final catalog_wire.PresentationRole role;
  final expression.EvaluationBudget budget;
  final ValueChanged<AuthoredDraft>? onChanged;
  final ValueChanged<types.ResourceId>? openResource;
  final Future<catalog_wire.PreparedCreation> Function(
    catalog_wire.InitializationRequest request,
  )?
  prepareCreation;
  final Future<void> Function(
    types.CapabilityId capabilityId,
    types.DataValue payload,
  )?
  invokeCommand;
  final Stream<search.RealmPresentationSearchUpdate> Function(
    search.RealmPresentationSearchRequest request,
  )?
  watchSearch;
  final Future<void> Function()? reload;
  final ValueChanged<String>? onStatus;
  final Future<void> Function()? commit;
  final bool enabled;

  @override
  State<AuthoredResourceEditor> createState() => _AuthoredResourceEditorState();
}

final class _AuthoredResourceEditorState extends State<AuthoredResourceEditor> {
  late AuthoredDraft _draft = widget.draft;

  @override
  void didUpdateWidget(covariant AuthoredResourceEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(widget.draft, oldWidget.draft)) {
      _draft = widget.draft;
    }
  }

  @override
  Widget build(BuildContext context) {
    final record = _draft.resource(widget.resource);
    if (record == null) {
      return _diagnostic(context, "The authored resource is absent");
    }
    final catalog = _draft.catalog;
    if (catalog == null || catalog.snapshot.generation != _draft.generation) {
      return _diagnostic(context, "The authored draft catalog is unavailable");
    }
    if (catalog.snapshot.generation != widget.catalog.snapshot.generation) {
      return _diagnostic(
        context,
        "The authored draft must be rebased before rendering",
      );
    }
    final localRules = AuthoredRuleProjection.evaluate(
      draft: _draft,
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
    catalog_wire.PresentationMaterial material,
    AuthoredRuleProjection localRules,
  ) {
    void changed() {
      if (mounted) setState(() {});
      widget.onChanged?.call(_draft);
    }

    final capabilities = PortablePresentationCapabilities(
      invokeCommand: widget.invokeCommand,
      watchSearch: widget.watchSearch,
      reload: widget.reload,
      commit: widget.commit,
      openResource: widget.openResource,
      prepareCreation: widget.prepareCreation,
    );
    final showsFullDiagnostics =
        widget.role == catalog_wire.PresentationRole.editor ||
        widget.role == catalog_wire.PresentationRole.inspector;
    final authoredHost = AuthoredDraftPresentationHost(
      resource: widget.resource,
      draft: _draft,
      material: material,
      role: selected.resolvedRole,
      budget: widget.budget,
      capabilities: capabilities,
      available: widget.enabled,
      prepareCreation: widget.prepareCreation,
      onDraftChanged: changed,
      reportStatus: widget.onStatus,
    );
    final renderer = PortablePresentationRenderer(
      host: authoredHost,
      onStatus: widget.onStatus,
      compactDiagnostics: showsFullDiagnostics
          ? const []
          : [
              for (final diagnostic in localRules.diagnostics)
                diagnostic_wire.DiagnosticTemplate(
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
            authoring: authoredHost.authored,
            catalog: document.catalog,
            resource: widget.resource,
            onDraftChanged: changed,
            role: document.role,
            material: document.material,
            activePresentations: document.activePresentations,
            slots: document.slots,
            host: host,
          ),
    );
    if (!showsFullDiagnostics) return renderer;
    if (widget.role == catalog_wire.PresentationRole.inspector &&
        localRules.diagnostics.isEmpty) {
      return renderer;
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final diagnostic in localRules.diagnostics)
          _localDiagnostic(diagnostic),
        if (widget.role == catalog_wire.PresentationRole.editor)
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
        color: diagnostic.severity == diagnostic_wire.DiagnosticSeverity.warning
            ? context.colors.warning
            : context.colors.danger,
      ),
    ),
  ),
);
