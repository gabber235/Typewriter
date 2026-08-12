import "package:flutter/material.dart";
import "package:flutter_animate/flutter_animate.dart";
import "package:flutter_hooks/flutter_hooks.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:typewriter_panel/typewriter_panel.dart";

class TypedEditor extends ConsumerWidget {
  const TypedEditor({
    this.path = DataPath.root,
    this.registry,
    this.readOnly = false,
    super.key,
  });

  final DataPath path;
  final TypeRegistry? registry;
  final bool readOnly;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.watch(editorProvider);
    final rootType = controller?.rootType;
    if (controller == null || rootType == null) return const SizedBox.shrink();
    final effectiveRegistry = registry ?? controller.registry;
    final typeResult = rootType.resolvePath(path, registry: effectiveRegistry);
    if (typeResult case TypeFailure(:final diagnostics)) {
      return Admonition.danger(
        child: Text(diagnostics.map((item) => item.message).join("\n")),
      );
    }
    final type = typeResult.valueOrNull!;
    return switch (controller.value(path)) {
      LoadingEditorValue() => const _LoadingValueEditor(),
      ConflictEditorValue() => _ConflictValueEditor(
        controller: controller,
        path: path,
        type: type,
        registry: effectiveRegistry,
        readOnly: readOnly,
      ),
      InvalidEditorValue(:final diagnostics) => Admonition.danger(
        child: Text(diagnostics.map((item) => item.message).join("\n")),
      ),
      ReadyEditorValue(:final value) => _LocalPresentationSurface(
        controller: controller,
        path: path,
        type: type,
        value: value,
        registry: effectiveRegistry,
        readOnly: readOnly,
      ),
    };
  }
}

class _ConflictValueEditor extends StatelessWidget {
  const _ConflictValueEditor({
    required this.controller,
    required this.path,
    required this.type,
    required this.registry,
    required this.readOnly,
  });

  final EditorController controller;
  final DataPath path;
  final TypeExpression type;
  final TypeRegistry? registry;
  final bool readOnly;

  @override
  Widget build(BuildContext context) {
    final errorColor = Theme.of(context).colorScheme.error;
    return Material(
      color: Theme.of(context).inputDecorationTheme.fillColor,
      borderRadius: context.shapes.mediumBorderRadius,
      child: InkWell(
        onTap: readOnly ? null : _reset,
        borderRadius: context.shapes.mediumBorderRadius,
        splashColor: errorColor.withValues(alpha: 0.2),
        highlightColor: errorColor.withValues(alpha: 0.1),
        child: Tooltip(
          message: "Click to reset field to its initial value",
          child: Padding(
            padding: EdgeInsets.all(context.spacing.space3),
            child: Row(
              children: [
                Icones("mdi:close", size: 18, color: errorColor),
                SizedBox(width: context.spacing.space3),
                Expanded(
                  child: Text(
                    "The selected values are different",
                    style: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.copyWith(color: errorColor),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _reset() {
    final initial = type.createInitialValue(registry: registry).valueOrNull;
    if (initial != null) controller.update(path, initial);
  }
}

class _LoadingValueEditor extends HookWidget {
  const _LoadingValueEditor();

  @override
  Widget build(BuildContext context) {
    final controller = useAnimationController()..repeat(period: 2200.ms);
    return Container(
      decoration: BoxDecoration(
        borderRadius: context.shapes.mediumBorderRadius,
        color: Theme.of(context).inputDecorationTheme.fillColor,
      ),
      height: 48,
    ).animate(controller: controller).shimmer(delay: 500.ms, duration: 1200.ms);
  }
}

class _LocalPresentationSurface extends StatefulWidget {
  const _LocalPresentationSurface({
    required this.controller,
    required this.path,
    required this.type,
    required this.value,
    required this.registry,
    required this.readOnly,
  });

  final EditorController controller;
  final DataPath path;
  final TypeExpression type;
  final DataValue value;
  final TypeRegistry? registry;
  final bool readOnly;

  @override
  State<_LocalPresentationSurface> createState() =>
      _LocalPresentationSurfaceState();
}

class _LocalPresentationSurfaceState extends State<_LocalPresentationSurface> {
  final HeaderExpansionStore _expansionStore = HeaderExpansionStore();
  List<TypeDiagnostic> _diagnostics = const [];

  @override
  void didUpdateWidget(_LocalPresentationSurface oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!typeExpressionsEqual(oldWidget.type, widget.type)) {
      _expansionStore.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    final registry = widget.registry ?? TypeRegistry(const TypeCatalog([]));
    final bindings = BindingEnvironment({
      const BindingId(0): BindingSnapshot(
        type: widget.type,
        value: widget.value,
        revision: 0,
        writable: !widget.readOnly,
      ),
    });
    final expressions = ExpressionContext(bindings: bindings);
    late final PresentationRenderScope scope;
    scope = PresentationRenderScope(
      expressions: expressions,
      registry: registry,
      budget: const ExpressionBudget(),
      readOnly: widget.readOnly,
      expansionStore: _expansionStore,
      setBinding: (reference, value, context, aliases) {
        final canonical = reference.canonicalizedWith(aliases);
        final replaced = bindings.replace(canonical, value);
        _apply(replaced.valueOrNull?.bindings[const BindingId(0)]?.value);
      },
      executeAction: (action, context, aliases) {
        if (action is! LocalEditorAction) {
          setState(() => _diagnostics = [_unavailableDiagnostic()]);
          return;
        }
        final result = action
            .canonicalizedWith(aliases)
            .execute(context, registry: widget.registry);
        switch (result) {
          case MutationSuccess(:final value):
            _apply(value);
          case MutationInvalid(:final diagnostics) ||
              MutationUnavailable(:final diagnostics):
            setState(() => _diagnostics = diagnostics);
          case MutationConflict(:final actualValue):
            setState(
              () => _diagnostics = [
                TypeDiagnostic(
                  code: TypeDiagnosticCode.invalidValue,
                  message: "The value changed before the edit was applied",
                  details: [
                    TypeDiagnosticDetail(
                      key: "actualValue",
                      value: actualValue.toString(),
                    ),
                  ],
                ),
              ],
            );
          case MutationPermissionDenied(:final message):
            setState(
              () => _diagnostics = [
                TypeDiagnostic(
                  code: TypeDiagnosticCode.invalidValue,
                  message: message,
                ),
              ],
            );
        }
      },
      resolvePresentation: (type, requested) => null,
    );
    final presentation = widget.type.generateDefaultPresentation();
    return PresentationSurface(
      presentation: presentation.localizeFailures(
        expressions,
        registry: widget.registry,
      ),
      scope: scope,
      diagnostics: _diagnostics,
    );
  }

  void _apply(DataValue? value) {
    if (value == null) return;
    final result = widget.controller.update(widget.path, value);
    if (result case InvalidEditorMutation(:final diagnostics)) {
      setState(() => _diagnostics = diagnostics);
      return;
    }
    setState(() => _diagnostics = const []);
  }
}

TypeDiagnostic _unavailableDiagnostic() => const TypeDiagnostic(
  code: TypeDiagnosticCode.invalidValue,
  message: "Realm actions are unavailable in the local inspector",
);
