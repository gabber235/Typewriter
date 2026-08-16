import "package:flutter/material.dart";
import "package:flutter_animate/flutter_animate.dart";
import "package:flutter_hooks/flutter_hooks.dart";
import "package:typewriter_panel/typewriter_panel.dart";

part "editor_surface_states.dart";
part "editor_surface_types.dart";

class EditorSurface extends StatefulWidget {
  const EditorSurface({
    required this.controller,
    this.path = DataPath.root,
    this.registry,
    this.conversions = const [],
    this.realmSearchSourceBuilder,
    this.headerShortcuts = const {},
    this.historyNamespace = "local",
    this.readOnly = false,
    super.key,
  });

  final EditorController controller;
  final DataPath path;
  final TypeRegistry? registry;
  final List<ConversionDefinition> conversions;
  final RealmPresentationSearchSourceBuilder? realmSearchSourceBuilder;
  final Map<HeaderItemCommandId, List<ShortcutActivator>> headerShortcuts;
  final String historyNamespace;
  final bool readOnly;

  @override
  State<EditorSurface> createState() => _EditorSurfaceState();
}

class _EditorSurfaceState extends State<EditorSurface> {
  static const _budget = ExpressionBudget();

  final HeaderExpansionStore _expansionStore = HeaderExpansionStore();
  List<TypeDiagnostic> _mutationDiagnostics = const [];

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_handleControllerChanged);
  }

  @override
  void didUpdateWidget(EditorSurface oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_handleControllerChanged);
      widget.controller.addListener(_handleControllerChanged);
    }
    final oldType = oldWidget.controller.document?.rootType;
    final nextType = widget.controller.document?.rootType;
    if (oldType != null &&
        nextType != null &&
        !typeExpressionsEqual(oldType, nextType)) {
      _expansionStore.clear();
    }
  }

  void _handleControllerChanged() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final document = widget.controller.document;
    if (document == null) return const SizedBox.shrink();
    final registry = widget.registry ?? TypeRegistry(document.typeCatalog);
    final typeResult = document.rootType.resolvePath(
      widget.path,
      registry: registry,
    );
    if (typeResult case TypeFailure(:final diagnostics)) {
      return presentationDiagnostic(context, diagnostics);
    }
    final declaredType = typeResult.valueOrNull!;
    final type = _representation(registry, declaredType);
    final content = switch (widget.controller.value(widget.path)) {
      LoadingEditorValue() => const _LoadingEditor(),
      ConflictEditorValue() => _SelectionConflictEditor(
        controller: widget.controller,
        path: widget.path,
        type: type,
        registry: registry,
        readOnly: widget.readOnly,
      ),
      InvalidEditorValue(:final diagnostics) => presentationDiagnostic(
        context,
        diagnostics,
      ),
      ReadyEditorValue(:final value) => _buildReady(
        document,
        registry,
        declaredType,
        type,
        value,
      ),
    };
    return _withSaveStatus(content);
  }

  Widget _buildReady(
    EditorDocument document,
    TypeRegistry registry,
    TypeExpression declaredType,
    TypeExpression type,
    DataValue value,
  ) {
    final selected = _resolvePresentation(
      document,
      registry,
      declaredType,
      null,
    );
    final rootPresentation = widget.path == DataPath.root
        ? document.rootPresentation
        : null;
    final bindingType = _bindingType(
      registry,
      declaredType,
      type,
      rootPresentation ?? selected?.root,
    );
    final bindings = BindingEnvironment({
      const BindingId(0): BindingSnapshot(
        type: bindingType,
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
    final presentation =
        rootPresentation ??
        selected?.root ??
        bindingType.generateDefaultPresentation();
    final scope = PresentationRenderScope(
      expressions: expressions,
      registry: registry,
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
        return widget.controller.beginInteraction(
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
      resolvePresentation: (requestedType, requested) =>
          _resolvePresentation(document, registry, requestedType, requested),
      headerShortcuts: widget.headerShortcuts,
      activePresentations: {if (selected != null) selected.id},
    );
    final localized = presentation.localizeFailures(
      expressions,
      registry: registry,
      budget: _budget,
    );
    final state = widget.controller.saveState(widget.path);
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
    final state = widget.controller.saveState(widget.path);
    final statePath = state.path ?? widget.path;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        EditorSaveStatus(
          state: state,
          onRetry: () => widget.controller.flush(paths: {statePath}),
          onUseRemote: () async => widget.controller.useRemote(statePath),
          onKeepLocal: () => widget.controller.keepLocal(statePath),
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
    final result = await widget.controller.executeAction(
      action,
      context,
      aliases,
    );
    if (!mounted) return;
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
        widget.controller.acceptRemote(
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

  void _applyAt(DataPath path, DataValue value) {
    final result = widget.controller.update(path, value);
    setState(() {
      _mutationDiagnostics = switch (result) {
        InvalidEditorMutation(:final diagnostics) => diagnostics,
        _ => const [],
      };
    });
  }

  @override
  void dispose() {
    widget.controller.removeListener(_handleControllerChanged);
    super.dispose();
  }
}
