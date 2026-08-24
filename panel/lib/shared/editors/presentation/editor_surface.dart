import "dart:async";

import "package:flutter/material.dart";
import "package:flutter_animate/flutter_animate.dart";
import "package:flutter_hooks/flutter_hooks.dart";
import "package:freezed_annotation/freezed_annotation.dart";
import "package:typewriter_panel/typewriter_panel.dart";

part "editor_surface.freezed.dart";
part "editor_surface_states.dart";
part "editor_surface_types.dart";

class EditorSurface extends StatefulWidget {
  const EditorSurface({
    required this.source,
    this.path = DataPath.root,
    this.registry,
    this.conversions = const [],
    this.realmSearchSourceBuilder,
    this.executePanelInstruction,
    this.headerShortcuts = const {},
    this.historyNamespace = "local",
    this.readOnly = false,
    super.key,
  });

  final EditorSource source;
  final DataPath path;
  final TypeRegistry? registry;
  final List<ConversionDefinition> conversions;
  final RealmPresentationSearchSourceBuilder? realmSearchSourceBuilder;
  final FutureOr<void> Function(PanelInstruction instruction)?
  executePanelInstruction;
  final Map<HeaderItemCommandId, List<ShortcutActivator>> headerShortcuts;
  final String historyNamespace;
  final bool readOnly;

  @override
  State<EditorSurface> createState() => _EditorSurfaceState();
}

class _EditorSurfaceState extends State<EditorSurface> {
  static const _budget = ExpressionBudget();

  final HeaderExpansionStore _expansionStore = HeaderExpansionStore();
  _EditorSurfaceDefinitionResolution? _definitionResolution;
  List<TypeDiagnostic> _mutationDiagnostics = const [];

  @override
  void initState() {
    super.initState();
    widget.source.addListener(_handleSourceChanged);
  }

  @override
  void didUpdateWidget(EditorSurface oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.source != widget.source) {
      oldWidget.source.removeListener(_handleSourceChanged);
      widget.source.addListener(_handleSourceChanged);
    }
    final oldType = oldWidget.source.document?.rootType;
    final nextType = widget.source.document?.rootType;
    if (oldType != null &&
        nextType != null &&
        !typeExpressionsEqual(oldType, nextType)) {
      _expansionStore.clear();
    }
  }

  void _handleSourceChanged() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final document = widget.source.document;
    if (document == null) return const SizedBox.shrink();

    final definitionResult = _resolveDefinition(document);
    if (definitionResult case TypeFailure(:final diagnostics)) {
      return presentationDiagnostic(context, diagnostics);
    }
    final definition = definitionResult.valueOrNull!;
    final content = switch (widget.source.value(widget.path)) {
      LoadingEditorValue() => const _LoadingEditor(),
      ConflictEditorValue() => _SelectionConflictEditor(
        source: widget.source,
        path: widget.path,
        type: definition.type,
        registry: definition.registry,
        readOnly: widget.readOnly,
      ),
      InvalidEditorValue(:final diagnostics) => presentationDiagnostic(
        context,
        diagnostics,
      ),
      ReadyEditorValue(:final value) => _buildReady(definition, value),
    };
    return _withSaveStatus(content);
  }

  TypeResult<_EditorSurfaceDefinition> _resolveDefinition(
    EditorDocument document,
  ) {
    final cached = _definitionResolution;
    if (cached != null &&
        cached.matches(document, widget.path, widget.registry)) {
      return cached.result;
    }

    final resolution = _EditorSurfaceDefinitionResolution.resolve(
      document: document,
      path: widget.path,
      registryOverride: widget.registry,
    );
    _definitionResolution = resolution;
    return resolution.result;
  }

  Widget _buildReady(_EditorSurfaceDefinition definition, DataValue value) {
    final document = definition.document;
    final bindings = BindingEnvironment({
      const BindingId(0): BindingSnapshot(
        type: definition.bindingType,
        value: value,
        revision: document.revision,
        writable: !widget.readOnly && !document.readOnly,
      ),
    });
    final expressions = ExpressionContext(
      bindings: bindings,
      conversions: {
        for (final conversion in widget.conversions) conversion.id: conversion,
      },
    );
    final scope = PresentationRenderScope(
      expressions: expressions,
      registry: definition.registry,
      budget: _budget,
      readOnly: widget.readOnly || document.readOnly,
      historyNamespace: widget.historyNamespace,
      realmSearchSourceBuilder: widget.realmSearchSourceBuilder,
      collections: {
        for (final source in document.collections) source.id: source,
      },
      expansionStore: _expansionStore,
      startInteraction: (reference) {
        if (reference.bindingId != const BindingId(0)) return null;
        return widget.source.beginInteraction(
          widget.path.followedBy(reference.path),
        );
      },
      setBinding: (reference, next, context, aliases) {
        final canonical = reference.canonicalizedWith(aliases);
        if (canonical.bindingId != const BindingId(0)) {
          setState(
            () => _mutationDiagnostics = [
              const TypeDiagnostic(
                code: TypeDiagnosticCode.invalidPresentation,
                message: "Presentation updates require a canonical binding",
              ),
            ],
          );
          return;
        }
        _applyAt(widget.path.followedBy(canonical.path), next);
      },
      executeAction: _executeAction,
      resolvePresentation: definition.resolvePresentation,
      headerShortcuts: widget.headerShortcuts,
      activePresentations: {
        if (definition.selectedPresentation case final selected?) selected.id,
      },
    );
    final localized = definition.presentation.localizeFailures(
      expressions,
      registry: definition.registry,
      budget: _budget,
    );
    final state = widget.source.saveState(widget.path);
    return PresentationSurface(
      presentation: localized,
      scope: scope,
      diagnostics: [
        ...document.diagnostics,
        ..._mutationDiagnostics,
        ...state.diagnostics,
      ],
    );
  }

  Widget _withSaveStatus(Widget content) {
    final state = widget.source.saveState(widget.path);
    final statePath = state.path ?? widget.path;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        EditorSaveStatus(
          state: state,
          onRetry: () => widget.source.flush(paths: {statePath}),
          onUseRemote: () async => widget.source.useRemote(statePath),
          onKeepLocal: () => widget.source.keepLocal(statePath),
        ),
        content,
      ],
    );
  }

  Future<void> _executeAction(
    EditorAction action,
    ExpressionContext context,
    Map<BindingId, BindingReference> aliases,
  ) async {
    final result = await widget.source.executeAction(action, context, aliases);
    if (!mounted) return;
    switch (result) {
      case LocalEditorActionResult(:final mutation):
        _handleMutationResult(action, aliases, mutation);
      case RealmEditorActionResult(:final command):
        await _handleCommandResult(command);
    }
  }

  void _handleMutationResult(
    EditorAction action,
    Map<BindingId, BindingReference> aliases,
    TypedMutationResult result,
  ) {
    switch (result) {
      case MutationSuccess(:final value):
        final localPath = _localActionMutationPath(action, aliases);
        final localValue = localPath?.read(value).valueOrNull;
        if (localPath != null && localValue != null) {
          _applyAt(widget.path.followedBy(localPath), localValue);
        } else {
          _applyAt(widget.path, value);
        }
      case MutationInvalid(:final diagnostics) ||
          MutationUnavailable(:final diagnostics):
        setState(() => _mutationDiagnostics = diagnostics);
      case MutationConflict(:final actualValue):
        widget.source.acceptRemote(
          revision: result.actualRevision,
          value: actualValue,
        );
      case MutationPermissionDenied(:final message):
        setState(
          () => _mutationDiagnostics = [
            TypeDiagnostic(
              code: TypeDiagnosticCode.invalidValue,
              message: message,
            ),
          ],
        );
    }
  }

  Future<void> _handleCommandResult(RealmCommandResult result) async {
    switch (result) {
      case RealmCommandSuccess(:final instructions):
        final executor = widget.executePanelInstruction;
        if (executor == null && instructions.isNotEmpty) {
          setState(
            () => _mutationDiagnostics = [
              const TypeDiagnostic(
                code: TypeDiagnosticCode.invalidPresentation,
                message: "Panel instruction executor is unavailable",
              ),
            ],
          );
          return;
        }
        for (final instruction in instructions) {
          await executor!(instruction);
        }
      case RealmCommandInvalid(:final diagnostics) ||
          RealmCommandUnavailable(:final diagnostics):
        setState(() => _mutationDiagnostics = diagnostics);
      case RealmCommandPermissionDenied(:final message):
        setState(
          () => _mutationDiagnostics = [
            TypeDiagnostic(
              code: TypeDiagnosticCode.invalidPresentation,
              message: message,
            ),
          ],
        );
      case RealmCommandStaleGeneration():
        setState(
          () => _mutationDiagnostics = [
            const TypeDiagnostic(
              code: TypeDiagnosticCode.invalidPresentation,
              message: "Realm catalog generation is stale",
            ),
          ],
        );
    }
  }

  void _applyAt(DataPath path, DataValue value) {
    final result = widget.source.update(path, value);
    setState(() {
      _mutationDiagnostics = switch (result) {
        InvalidEditorMutation(:final diagnostics) => diagnostics,
        _ => const [],
      };
    });
  }

  @override
  void dispose() {
    widget.source.removeListener(_handleSourceChanged);
    super.dispose();
  }
}
