import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";

final class AuthoredResourceInspection extends StatefulWidget {
  const AuthoredResourceInspection({
    required this.resource,
    required this.workspace,
    required this.commands,
    this.role = skir.PresentationRole.inspector,
    this.commitPolicy = EditorCommitPolicy.autosaveChanges,
    this.openResource,
    super.key,
  });

  final skir.ResourceId resource;
  final RealmEditing workspace;
  final AuthoredResourceCommands commands;
  final skir.PresentationRole role;
  final EditorCommitPolicy commitPolicy;
  final ValueChanged<skir.ResourceId>? openResource;

  @override
  State<AuthoredResourceInspection> createState() =>
      _AuthoredResourceInspectionState();
}

final class _AuthoredResourceInspectionState
    extends State<AuthoredResourceInspection> {
  late RealmEditingBinding _binding;

  @override
  void initState() {
    super.initState();
    _binding = widget.workspace.attach(
      widget.resource,
      policy: widget.commitPolicy,
    )..addListener(_updated);
  }

  void _updated() {
    if (mounted) setState(() {});
  }

  @override
  void didUpdateWidget(covariant AuthoredResourceInspection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.workspace != oldWidget.workspace ||
        widget.resource != oldWidget.resource ||
        widget.commitPolicy != oldWidget.commitPolicy) {
      _binding
        ..removeListener(_updated)
        ..detach();
      _binding = widget.workspace.attach(
        widget.resource,
        policy: widget.commitPolicy,
      )..addListener(_updated);
    }
  }

  @override
  void dispose() {
    _binding
      ..removeListener(_updated)
      ..detach();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final relatedWork = widget.workspace.hasWorkFor(widget.resource);
    final configuration = _binding.document
        .resource(widget.resource)
        ?.configuration;
    final editor = _editor(widget.role, enabled: !_binding.blocked);
    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: context.spacing.space2,
      children: [
        if (configuration != null)
          AuthoredTypeArgumentEditor(
            selection: configuration,
            catalog: _binding.document.catalog,
            preview: (requested) => widget.commands.previewTypeArguments(
              resource: widget.resource,
              requested: requested,
            ),
            commit: (preview) async {
              final prepared = await widget.commands.prepareTypeArguments(
                preview,
              );
              return switch (prepared) {
                skir.PreparedEditResult_preparedWrapper(:final value) =>
                  _binding.stagePrepared(
                    label: "Change type arguments",
                    edit: value.edit,
                  ),
                skir.PreparedEditResult_needsInputWrapper() =>
                  const EditStageResult.rejected(
                    "The type change needs more input",
                    null,
                  ),
                skir.PreparedEditResult_rejectedWrapper() =>
                  const EditStageResult.rejected(
                    "The Realm rejected the type change",
                    null,
                  ),
                _ => const EditStageResult.rejected(
                  "The type change result is unavailable",
                  null,
                ),
              };
            },
            enabled: !relatedWork && !_binding.saving,
            disabledMessage: relatedWork
                ? "Save or discard local edits before changing type arguments"
                : null,
            onStatus: (message) {
              _binding.reportStatus(message);
            },
          ),
        if (widget.role == skir.PresentationRole.editor)
          Expanded(child: editor)
        else
          editor,
        if (_binding.status case final message?) Text(message),
        ApplyControls(control: _binding.control),
        for (final group in _binding.relatedGroups)
          EditingGroupPanel(
            workspace: widget.workspace.workspace,
            id: group.id,
            review: () =>
                RealmEditingReview(workspace: widget.workspace, id: group.id),
          ),
      ],
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: context.spacing.space3,
      children: [
        if (widget.role == skir.PresentationRole.editor)
          Expanded(child: content)
        else
          content,
      ],
    );
  }

  AuthoredResourceEditor _editor(
    skir.PresentationRole role, {
    required bool enabled,
  }) => AuthoredResourceEditor(
    key: ValueKey(role),
    resource: widget.resource,
    document: _binding.document,
    edit: _binding,
    role: role,
    budget: skir.EvaluationBudget(maxSteps: 10000, maxCollectionItems: 10000),
    invokeCommand: _invokeCommand,
    watchSearch: widget.commands.watchSearch,
    reload: widget.commands.reload,
    onStatus: (message) {
      _binding.reportStatus(message);
    },
    openResource: widget.openResource,
    prepareValue: widget.commands.prepareValue,
    enabled: enabled,
  );

  Future<void> _invokeCommand(
    skir.CapabilityId capabilityId,
    skir.DataValue payload,
  ) async {
    final result = await widget.commands.invokeCommand(
      capabilityId: capabilityId,
      payload: payload,
    );
    if (!mounted) return;
    switch (result) {
      case skir.CommandResult_successWrapper(:final value):
        for (final instruction in value.instructions) {
          switch (instruction) {
            case skir.PanelInstruction_invalidateResourceWrapper():
              await widget.commands.reload();
              if (!mounted) return;
            case skir.PanelInstruction_openResourceWrapper(:final value):
              final id = value.resource.identity.authoredString;
              if (id != null) {
                widget.openResource?.call(skir.ResourceId(value: id));
              } else {
                _binding.reportStatus(
                  "The command returned an invalid resource identity",
                );
              }
            case skir.PanelInstruction_notifyWrapper(:final value):
              _binding.reportStatus(value.message);
            case skir.PanelInstruction_unknown():
              _binding.reportStatus(
                "The command returned an unknown instruction",
              );
          }
        }
      case skir.CommandResult_invalidWrapper(:final value):
        _binding.reportStatus(
          value.diagnostics.map((item) => item.message).join("\n"),
        );
      case skir.CommandResult_unavailableWrapper(:final value):
        _binding.reportStatus(
          value.diagnostics.map((item) => item.message).join("\n"),
        );
      case skir.CommandResult_permissionDeniedWrapper(:final value):
        _binding.reportStatus(value.message);
      case skir.CommandResult_staleGenerationWrapper():
        await widget.commands.reload();
        if (mounted) {
          _binding.reportStatus(
            "The editor catalog changed. Review the refreshed form",
          );
        }
      case skir.CommandResult_unknown():
        _binding.reportStatus("The command result is unavailable");
    }
  }
}
