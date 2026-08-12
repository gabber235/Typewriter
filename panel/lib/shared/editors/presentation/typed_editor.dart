import "package:flutter/material.dart";
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
      LoadingEditorValue() => const LinearProgressIndicator(),
      ConflictEditorValue() => const Admonition.danger(
        child: Text("The selected values are different"),
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
