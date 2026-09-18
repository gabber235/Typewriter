import "package:flutter/material.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skirout/kernel/v1/record_id.dart";
import "package:typewriter_panel/typewriter_panel.dart";

/// Coordinates one presentation tree over its independently owned edit sources.
///
/// [model] supplies bindings, presentation nodes, and the explicit owner map.
/// This widget owns the [PresentationSession], expression registry, header
/// expansion state, and commit placement bookkeeping. It does not own drafts:
/// mutations and save decisions are routed to the [EditorSource] owners.
/// Local actions update that session immediately. Realm actions cross the
/// supplied host and surface diagnostics when execution or instruction
/// handling cannot continue.
class ComposedEditor extends StatefulWidget {
  const ComposedEditor({
    required this.model,
    this.conversions = const [],
    this.host = const EditorHostCapabilities(),
    this.referenceOrigins = const [],
    this.headerShortcuts = const {},
    this.historyNamespace = "local",
    this.readOnly = false,
    super.key,
  });

  final PresentationModel model;
  final List<ConversionDefinition> conversions;
  final EditorHostCapabilities host;
  final List<RecordId> referenceOrigins;
  final Map<HeaderItemCommandId, List<ShortcutActivator>> headerShortcuts;
  final String historyNamespace;
  final bool readOnly;

  @override
  State<ComposedEditor> createState() => _ComposedEditorState();
}

class _ComposedEditorState extends State<ComposedEditor> {
  late final PresentationSession _session;
  late TypeRegistry _registry;
  final _placements = EditorCommitPlacements();
  final HeaderExpansionStore _expansion = HeaderExpansionStore();
  List<TypeDiagnostic> _diagnostics = [];

  @override
  void initState() {
    super.initState();
    _registry = TypeRegistry(widget.model.catalog);
    _placements.addListener(_changed);
    _session = PresentationSession(widget.model)..addListener(_changed);
  }

  @override
  void didUpdateWidget(ComposedEditor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.model.catalog != widget.model.catalog) {
      _registry = TypeRegistry(widget.model.catalog);
    }
    if (oldWidget.model != widget.model) _session.refresh(widget.model);
  }

  void _changed() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final registry = _registry;
    final references = widget.host.references;
    final scope = PresentationRenderScope(
      expressions: ExpressionContext(
        bindings: _session.bindings,
        conversions: {for (final value in widget.conversions) value.id: value},
      ),
      registry: registry,
      budget: const ExpressionBudget(),
      expansionStore: _expansion,
      readOnly: widget.readOnly,
      historyNamespace: widget.historyNamespace,
      inputAccess: widget.model.inputAccess,
      ownerBindings: widget.model.ownerBindings,
      collections: widget.model.collections.byId,
      realmSearchSourceBuilder: widget.host.presentationSearch?.source,
      referenceSearchSourceBuilder: references?.search,
      resolveReferences: references?.resolve,
      referenceOrigins: [
        ...widget.referenceOrigins,
        for (final input in widget.model.inputs.values)
          if (input case PresentationEditInput(:final owner))
            for (final source in _resources(owner))
              if (source case TransactionalEditorSource(:final resource?))
                if (resource.key.identity case final RecordId identity)
                  identity,
      ],
      referencePolicies:
          references?.policies ?? const ReferenceCandidatePolicyRegistry(),
      editOwnerFor: _session.owner,
      headerShortcuts: widget.headerShortcuts,
      startInteraction: _session.beginInteraction,
      setBinding: (reference, value, context, aliases) {
        _accept(_session.update(reference.canonicalizedWith(aliases), value));
      },
      executeAction: _execute,
      resolvePresentation: (type, id) => _resolve(registry, type, id),
    );
    final owners = <EditorSource>{
      for (final input in widget.model.inputs.values)
        if (input case PresentationEditInput(:final owner))
          ..._resources(owner),
    };
    final applyOwners = owners
        .where(
          (owner) => owner.commitPolicy == EditorCommitPolicy.applyResource,
        )
        .toList();

    final candidate = applyOwners.length == 1 ? applyOwners.single : null;
    final diagnosticInput = widget.model.inputs.length == 1
        ? widget.model.inputs.entries.single
        : null;
    final diagnosticSourcePath = switch (diagnosticInput?.value) {
      PresentationEditInput(:final path) => path,
      _ => DataPath.root,
    };
    final primaryOwner =
        !widget.readOnly &&
            candidate != null &&
            candidate.hasWork &&
            !candidate.readOnly &&
            candidate.draftDiagnostics.isEmpty &&
            candidate.saveState(DataPath.root).phase != EditorSavePhase.saving
        ? candidate
        : null;
    final editor = EditorCommitPlacementScope(
      placements: _placements,
      labels: widget.model.ownerLabels,
      resolve: (reference) {
        final input = widget.model.inputs[reference.bindingId];
        if (input is! PresentationEditInput) return null;
        return _resources(input.owner)
            .where(
              (owner) => owner.commitPolicy == EditorCommitPolicy.applyResource,
            )
            .toSet();
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        spacing: context.spacing.space2,
        children: [
          for (final owner in owners)
            if ({
              EditorSavePhase.conflict,
              EditorSavePhase.failed,
              EditorSavePhase.uncertain,
              EditorSavePhase.repeatedContention,
              EditorSavePhase.deletedElsewhere,
            }.contains(owner.saveState(DataPath.root).phase)) ...[
              EditorSaveStatus(
                state: owner.saveState(DataPath.root),
                onRetry: owner.flush,
                onUseRemote: () async => owner.useRemote(
                  owner.saveState(DataPath.root).path ?? DataPath.root,
                ),
                onKeepLocal: () => owner.keepLocal(
                  owner.saveState(DataPath.root).path ?? DataPath.root,
                ),
              ),
            ],
          PresentationSurface(
            presentation: widget.model.root.localizeFailures(
              scope.expressions,
              registry: registry,
              budget: scope.budget,
            ),
            scope: scope,
            diagnostics: _diagnostics,
            inputDiagnostics: widget.model.diagnostics,
            diagnosticBindingId: diagnosticInput?.key,
            diagnosticSourcePath: diagnosticSourcePath,
          ),
          for (final owner in owners)
            if (owner.commitPolicy == EditorCommitPolicy.applyResource &&
                _placements.count(owner) != 1)
              EditorCommitControls(
                owner: owner,
                enabled: !widget.readOnly,
                label: widget.model.ownerLabels[owner],
              ),
        ],
      ),
    );
    return ManagedActionSet(
      shortcuts: [
        if (primaryOwner != null)
          ActionShortcut.intent(
            id: "editor.apply",
            label: "Apply",
            description: "Apply editor changes",
            intent: PrimaryActionIntent,
            priority: 100,
            onInvoke: (_) => primaryOwner.flush(),
          ),
      ],
      child: editor,
    );
  }

  ResolvedPresentationDefinition? _resolve(
    TypeRegistry registry,
    TypeExpression? type,
    PresentationId? id,
  ) {
    final selected =
        id ??
        (type is NamedType
            ? registry.definition(type.reference)?.defaultPresentationId
            : null);
    final candidates = [
      ...builtinPresentationDefinitions(),
      ...widget.model.presentations,
    ];
    final definition = candidates
        .where((value) => value.id == selected)
        .firstOrNull;
    if (definition == null) return null;

    if (type != null && definition.inputs.length != 1) return null;
    return ResolvedPresentationDefinition(
      id: definition.id,
      root: definition.root,
      inputs: definition.inputs,
      primaryInput: definition.primaryInput,
    );
  }

  void _accept(EditorMutationResult result) {
    if (!mounted) return;
    final diagnostics = result is InvalidEditorMutation
        ? result.diagnostics
        : const <TypeDiagnostic>[];
    setState(() {
      _diagnostics = diagnostics;
    });
  }

  Future<void> _execute(
    EditorAction action,
    ExpressionContext context,
    Map<BindingId, BindingReference> aliases,
  ) async {
    if (action case LocalEditorAction()) {
      if (!widget.readOnly) {
        _accept(_session.executeLocal(action, context, aliases));
      }
      return;
    }
    final realmActions = widget.host.realmActions;
    if (realmActions == null) {
      _failure("Realm capability runtime is unavailable");
      return;
    }
    final result = await realmActions.execute(
      (action as RealmEditorAction).action,
      context,
    );

    if (!mounted) return;
    switch (result) {
      case RealmCommandSuccess(:final instructions):
        for (final instruction in instructions) {
          final execute = realmActions.executePanelInstruction;
          if (execute == null) {
            _failure("Panel instruction executor is unavailable");
            return;
          }
          await execute(instruction);
          if (!mounted) return;
        }
      case RealmCommandInvalid(:final diagnostics) ||
          RealmCommandUnavailable(:final diagnostics):
        setState(() => _diagnostics = diagnostics);
      case RealmCommandPermissionDenied(:final message):
        _failure(message);
      case RealmCommandStaleGeneration():
        _failure("Realm catalog generation is stale");
    }
  }

  void _failure(String message) {
    setState(
      () => _diagnostics = [
        TypeDiagnostic(
          code: TypeDiagnosticCode.invalidPresentation,
          message: message,
        ),
      ],
    );
  }

  @override
  void dispose() {
    _placements.dispose();
    _session.removeListener(_changed);
    _session.dispose();
    super.dispose();
  }
}

Iterable<EditorSource> _resources(EditOwner owner) => switch (owner) {
  EditorSource() => [owner],
  ProjectedEditOwner(:final owner) => _resources(owner),
  MultiEditOwner(:final owners) => owners.expand(_resources),
  _ => const [],
};
