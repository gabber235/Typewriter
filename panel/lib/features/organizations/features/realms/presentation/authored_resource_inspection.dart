import "package:flutter/material.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skirout/editor/v1/authoring.dart"
    as authoring;
import "package:typewriter_panel/infrastructure/protocols/skir/skirout/editor/v1/capability.dart"
    as capability;
import "package:typewriter_panel/infrastructure/protocols/skir/skirout/editor/v1/catalog.dart"
    as catalog_wire;
import "package:typewriter_panel/infrastructure/protocols/skir/skirout/editor/v1/expression.dart"
    as expression;
import "package:typewriter_panel/infrastructure/protocols/skir/skirout/editor/v1/search.dart"
    as search;
import "package:typewriter_panel/infrastructure/protocols/skir/skirout/editor/v1/type_catalog.dart"
    as types;
import "package:typewriter_panel/typewriter_panel.dart";

final class AuthoredResourceInspection extends StatefulWidget
    implements InspectorBodyOwnsHeader {
  const AuthoredResourceInspection({
    required this.resource,
    required this.draft,
    required this.catalog,
    required this.commands,
    this.role = catalog_wire.PresentationRole.inspector,
    this.commitPolicy = EditorCommitPolicy.autosaveChanges,
    this.openResource,
    super.key,
  });

  final types.ResourceId resource;
  final AuthoredDraft draft;
  final CheckedEditorCatalog catalog;
  final AuthoredResourceCommands commands;
  final catalog_wire.PresentationRole role;
  final EditorCommitPolicy commitPolicy;
  final ValueChanged<types.ResourceId>? openResource;

  @override
  bool get ownsInspectorHeader {
    if (role != catalog_wire.PresentationRole.inspector) return false;
    final record = draft.resource(resource);
    if (record == null) return false;
    return catalog.selectPresentation(
      record.configuration,
      catalog_wire.PresentationRole.inspectorHeader,
    ) is SelectedEditorPresentation;
  }

  @override
  State<AuthoredResourceInspection> createState() =>
      _AuthoredResourceInspectionState();
}

final class _AuthoredResourceInspectionState
    extends State<AuthoredResourceInspection> {
  late final AuthoredDraftAutosave _autosave;

  @override
  void initState() {
    super.initState();
    _autosave = widget.commands.openAutosave(
      resource: widget.resource,
      baseline: widget.draft,
      policy: widget.commitPolicy,
    )..addListener(_updated);
  }

  void _updated() {
    if (mounted) setState(() {});
  }

  @override
  void didUpdateWidget(covariant AuthoredResourceInspection oldWidget) {
    super.didUpdateWidget(oldWidget);
    final changed =
        !identical(widget.draft, oldWidget.draft) ||
        widget.draft.generation != oldWidget.draft.generation;
    if (!changed) return;
    _autosave.acceptBaseline(widget.draft);
  }

  @override
  void dispose() {
    _autosave
      ..removeListener(_updated)
      ..detach();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dirty = _autosave.dirty;
    final configuration = _autosave.draft
        .resource(widget.resource)
        ?.configuration;
    final ownsInspectorHeader =
        widget.role == catalog_wire.PresentationRole.inspector &&
        configuration != null &&
        widget.catalog.selectPresentation(
          configuration,
          catalog_wire.PresentationRole.inspectorHeader,
        ) is SelectedEditorPresentation;
    final editor = _editor(widget.role, enabled: true, onChanged: _changed);
    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: context.spacing.space2,
      children: [
        if (configuration != null)
          AuthoredTypeArgumentEditor(
            selection: configuration,
            catalog: widget.catalog,
            preview: (requested) => widget.commands.previewTypeArguments(
              resource: widget.resource,
              requested: requested,
            ),
            commit: widget.commands.commitTypeArguments,
            enabled: !dirty && !_autosave.saving,
            disabledMessage: dirty
                ? "Save or discard local edits before changing type arguments"
                : null,
            onStatus: (message) {
              _autosave.reportStatus(message);
            },
          ),
        if (widget.role == catalog_wire.PresentationRole.editor)
          Expanded(child: editor)
        else
          editor,
        if (_autosave.status case final status?)
          Semantics(
            liveRegion: true,
            child: Row(
              children: [
                Expanded(child: Text(status)),
                if (_autosave.canRetry)
                  TextButton(
                    onPressed: _autosave.retry,
                    child: const Text("Retry"),
                  ),
                if (_autosave.canUseLatest)
                  TextButton(
                    onPressed: _useLatest,
                    child: const Text("Use latest"),
                  ),
              ],
            ),
          ),
        if (dirty && widget.commitPolicy == EditorCommitPolicy.applyResource)
          Align(
            alignment: AlignmentDirectional.centerEnd,
            child: Wrap(
              spacing: context.spacing.space2,
              children: [
                TextButton(
                  onPressed: _autosave.saving ? null : _discard,
                  child: const Text("Cancel"),
                ),
                LoadingButton.filled(
                  onPressed: !_autosave.saving && !_autosave.blocked
                      ? _save
                      : null,
                  child: Text(_autosave.saving ? "Saving" : "Apply"),
                ),
              ],
            ),
          ),
      ],
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: context.spacing.space3,
      children: [
        if (ownsInspectorHeader)
          IgnorePointer(
            child: ExcludeFocus(
              child: _editor(
                catalog_wire.PresentationRole.inspectorHeader,
                enabled: true,
              ),
            ),
          ),
        if (widget.role == catalog_wire.PresentationRole.editor)
          Expanded(child: content)
        else
          content,
      ],
    );
  }

  AuthoredResourceEditor _editor(
    catalog_wire.PresentationRole role, {
    required bool enabled,
    ValueChanged<AuthoredDraft>? onChanged,
  }) => AuthoredResourceEditor(
    key: ValueKey(role),
    resource: widget.resource,
    draft: _autosave.draft,
    catalog: widget.catalog,
    role: role,
    budget: expression.EvaluationBudget(
      maxSteps: 10000,
      maxCollectionItems: 10000,
    ),
    commit: _save,
    invokeCommand: _invokeCommand,
    watchSearch: widget.commands.watchSearch,
    reload: widget.commands.reload,
    onStatus: (message) {
      _autosave.reportStatus(message);
    },
    openResource: widget.openResource,
    prepareCreation: widget.commands.prepareCreation,
    enabled: enabled,
    onChanged: onChanged,
  );

  void _changed(AuthoredDraft next) {
    _autosave.stage(next);
  }

  Future<void> _save() => _autosave.flush();

  Future<void> _useLatest() async {
    FocusScope.of(context).unfocus();
    await _autosave.useLatest();
  }

  Future<void> _invokeCommand(
    types.CapabilityId capabilityId,
    types.DataValue payload,
  ) async {
    final result = await widget.commands.invokeCommand(
      capabilityId: capabilityId,
      payload: payload,
    );
    if (!mounted) return;
    switch (result) {
      case capability.CommandResult_successWrapper(:final value):
        for (final instruction in value.instructions) {
          switch (instruction) {
            case capability.PanelInstruction_invalidateResourceWrapper():
              await widget.commands.reload();
              if (!mounted) return;
            case capability.PanelInstruction_openResourceWrapper(:final value):
              final id = value.resource.identity.authoredString;
              if (id != null) {
                widget.openResource?.call(types.ResourceId(value: id));
              } else {
                _autosave.reportStatus(
                  "The command returned an invalid resource identity",
                );
              }
            case capability.PanelInstruction_notifyWrapper(:final value):
              _autosave.reportStatus(value.message);
            case capability.PanelInstruction_unknown():
              _autosave.reportStatus(
                "The command returned an unknown instruction",
              );
          }
        }
      case capability.CommandResult_invalidWrapper(:final value):
        _autosave.reportStatus(
          value.diagnostics.map((item) => item.message).join("\n"),
        );
      case capability.CommandResult_unavailableWrapper(:final value):
        _autosave.reportStatus(
          value.diagnostics.map((item) => item.message).join("\n"),
        );
      case capability.CommandResult_permissionDeniedWrapper(:final value):
        _autosave.reportStatus(value.message);
      case capability.CommandResult_staleGenerationWrapper():
        await widget.commands.reload();
        if (mounted) {
          _autosave.reportStatus(
            "The editor catalog changed. Review the refreshed form",
          );
        }
      case capability.CommandResult_unknown():
        _autosave.reportStatus("The command result is unavailable");
    }
  }

  void _discard() {
    _autosave.discard(widget.draft);
  }
}

final class AuthoredResourceCommands {
  const AuthoredResourceCommands({
    required this.commit,
    required this.previewTypeArguments,
    required this.commitTypeArguments,
    required this.prepareCreation,
    required this.invokeCommand,
    required this.watchSearch,
    required this.reload,
    required this.openAutosave,
  });

  final Future<authoring.CommitPreparedEditResponse> Function(
    authoring.PreparedEdit edit,
  )
  commit;
  final Future<authoring.TypePreviewResult> Function({
    required types.ResourceId resource,
    required types.TypeSelection requested,
  })
  previewTypeArguments;
  final Future<authoring.CommitTypeArgumentChangeResponse> Function(
    authoring.TypeArgumentChangePreview preview,
  )
  commitTypeArguments;
  final Future<catalog_wire.PreparedCreation> Function(
    catalog_wire.InitializationRequest request,
  )
  prepareCreation;
  final Future<capability.CommandResult> Function({
    required types.CapabilityId capabilityId,
    required types.DataValue payload,
  })
  invokeCommand;
  final Stream<search.RealmPresentationSearchUpdate> Function(
    search.RealmPresentationSearchRequest request,
  )
  watchSearch;
  final Future<void> Function() reload;
  final AuthoredDraftAutosave Function({
    required types.ResourceId resource,
    required AuthoredDraft baseline,
    EditorCommitPolicy policy,
  })
  openAutosave;
}
