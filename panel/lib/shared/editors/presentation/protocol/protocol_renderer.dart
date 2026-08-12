import "dart:async";

import "package:flutter/material.dart";
import "package:typewriter_panel/typewriter_panel.dart";

typedef RealmActionExecutor =
    FutureOr<TypedMutationResult> Function(RealmAction action);

class EditorProtocolRenderer extends StatefulWidget {
  const EditorProtocolRenderer({
    required this.envelope,
    required this.typeCatalog,
    this.conversions = const [],
    this.realmActions = const [],
    this.presentations = const [],
    this.presentation,
    this.diagnostics = const [],
    this.onRealmAction,
    this.headerShortcuts = const {},
    this.readOnly = false,
    super.key,
  });

  final TypedValueEnvelope envelope;
  final TypeCatalog typeCatalog;
  final List<ConversionDefinition> conversions;
  final List<RealmActionDefinition> realmActions;
  final List<PresentationDefinition> presentations;
  final PresentationNode? presentation;
  final List<TypeDiagnostic> diagnostics;
  final RealmActionExecutor? onRealmAction;
  final Map<HeaderActionId, List<ShortcutActivator>> headerShortcuts;
  final bool readOnly;

  @override
  State<EditorProtocolRenderer> createState() => _EditorProtocolRendererState();
}

class _EditorProtocolRendererState extends State<EditorProtocolRenderer> {
  static const _budget = ExpressionBudget();

  late BindingEnvironment _bindings;
  final HeaderExpansionStore _expansionStore = HeaderExpansionStore();
  List<TypeDiagnostic> _mutationDiagnostics = const [];

  TypeRegistry get _registry => TypeRegistry(widget.typeCatalog);

  @override
  void initState() {
    super.initState();
    _resetBindings();
  }

  @override
  void didUpdateWidget(EditorProtocolRenderer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.envelope.rootType != widget.envelope.rootType) {
      _expansionStore.clear();
    }
    if (oldWidget.envelope != widget.envelope ||
        oldWidget.typeCatalog != widget.typeCatalog) {
      _resetBindings();
    }
  }

  void _resetBindings() {
    final registry = _registry;
    final resolved = registry.resolve(NamedType(widget.envelope.rootType));
    final type = resolved.valueOrNull?.representation ?? const AnyType();
    _bindings = BindingEnvironment({
      const BindingId(0): BindingSnapshot(
        type: type,
        value: widget.envelope.rootValue,
        revision: 0,
        writable: !widget.readOnly,
      ),
    });
    _mutationDiagnostics = resolved.diagnostics;
  }

  @override
  Widget build(BuildContext context) {
    final registry = _registry;
    final root = registry.resolve(NamedType(widget.envelope.rootType));
    if (root case TypeFailure(:final diagnostics)) {
      return presentationDiagnostic(context, diagnostics);
    }
    final expressions = ExpressionContext(
      bindings: _bindings,
      conversions: {
        for (final conversion in widget.conversions) conversion.id: conversion,
      },
    );
    final selectedRoot = _resolvePresentation(
      NamedType(widget.envelope.rootType),
      null,
    );
    final presentation =
        widget.presentation ??
        selectedRoot?.root ??
        root.valueOrNull!.representation.generateDefaultPresentation();
    final localized = presentation.localizeFailures(
      expressions,
      registry: registry,
      budget: _budget,
    );
    final scope = PresentationRenderScope(
      expressions: expressions,
      registry: registry,
      budget: _budget,
      readOnly: widget.readOnly,
      setBinding: _setBinding,
      executeAction: _executeAction,
      resolvePresentation: _resolvePresentation,
      expansionStore: _expansionStore,
      headerShortcuts: widget.headerShortcuts,
      activePresentations: {
        if (widget.presentation == null && selectedRoot != null)
          selectedRoot.id,
      },
    );
    return PresentationSurface(
      presentation: localized,
      scope: scope,
      diagnostics: [...widget.diagnostics, ..._mutationDiagnostics],
    );
  }

  ResolvedPresentationDefinition? _resolvePresentation(
    TypeExpression type,
    PresentationId? requested,
  ) {
    final selected = requested ?? _defaultPresentationId(type);
    if (selected == null) return null;
    final definition = [
      ...builtinPresentationDefinitions(),
      ...widget.presentations,
    ].where((candidate) => candidate.id == selected).firstOrNull;
    if (definition == null) return null;
    final substitutions = definition.target.inferPresentationSubstitutions(
      type,
    );
    if (substitutions == null) return null;
    return ResolvedPresentationDefinition(
      id: selected,
      root: definition.root.substitute(substitutions),
    );
  }

  PresentationId? _defaultPresentationId(TypeExpression type) {
    if (type case NamedType(:final reference)) {
      return TypeRegistry(
        widget.typeCatalog,
      ).definition(reference)?.defaultPresentationId;
    }
    return null;
  }

  void _setBinding(
    BindingReference reference,
    DataValue value,
    ExpressionContext context,
    Map<BindingId, BindingReference> aliases,
  ) {
    final canonical = reference.canonicalizedWith(aliases);
    final resolved = _bindings.resolve(canonical);
    if (resolved case TypeFailure(:final diagnostics)) {
      setState(() => _mutationDiagnostics = diagnostics);
      return;
    }
    _executeAction(
      EditorAction.local(
        SetValueAction(
          target: canonical,
          value: TypedExpression(
            resultType: resolved.valueOrNull!.type,
            expression: LiteralExpression(value),
          ),
        ),
      ),
      context,
      aliases,
    );
  }

  Future<void> _executeAction(
    EditorAction action,
    ExpressionContext context,
    Map<BindingId, BindingReference> aliases,
  ) async {
    final result = switch (action) {
      LocalEditorAction() =>
        action
            .canonicalizedWith(aliases)
            .execute(context, registry: _registry, budget: _budget),
      RealmEditorAction() => await _executeRealm(action.action, context),
    };
    if (!mounted) return;
    _applyResult(result);
  }

  Future<TypedMutationResult> _executeRealm(
    RealmAction action,
    ExpressionContext context,
  ) async {
    final executor = widget.onRealmAction;
    if (executor == null) return _unavailable("Realm actions are unavailable");
    if (action case InvokeRealmCallbackAction(
      :final actionId,
      :final payload,
    )) {
      final definition = widget.realmActions
          .where((candidate) => candidate.id == actionId)
          .firstOrNull;
      if (definition == null) return _unavailable("Realm action is unknown");
      final evaluated = payload.evaluate(
        context,
        registry: _registry,
        budget: _budget,
      );
      if (evaluated case TypeFailure(:final diagnostics)) {
        return MutationInvalid(diagnostics);
      }
      final diagnostics = (evaluated.valueOrNull!).validateAgainst(
        NamedType(definition.payloadType),
        registry: _registry,
      );
      if (diagnostics.isNotEmpty) return MutationInvalid(diagnostics);
    }
    return executor(action);
  }

  void _applyResult(TypedMutationResult result) {
    switch (result) {
      case MutationSuccess(:final revision, :final value):
        setState(() {
          final current = _bindings.bindings[const BindingId(0)];
          if (current != null) {
            _bindings = BindingEnvironment({
              ..._bindings.bindings,
              const BindingId(0): BindingSnapshot(
                type: current.type,
                value: value,
                revision: revision,
                writable: current.writable,
              ),
            });
          }
          _mutationDiagnostics = const [];
        });
      case MutationConflict(:final expectedRevision, :final actualRevision):
        setState(() {
          _mutationDiagnostics = [
            _diagnostic(
              "Edit expected revision $expectedRevision but found $actualRevision",
            ),
          ];
        });
      case MutationInvalid(:final diagnostics) ||
          MutationUnavailable(:final diagnostics):
        setState(() => _mutationDiagnostics = diagnostics);
      case MutationPermissionDenied(:final message):
        setState(() => _mutationDiagnostics = [_diagnostic(message)]);
    }
  }
}

MutationUnavailable _unavailable(String message) =>
    MutationUnavailable([_diagnostic(message)]);

TypeDiagnostic _diagnostic(String message) =>
    TypeDiagnostic(code: TypeDiagnosticCode.invalidValue, message: message);
