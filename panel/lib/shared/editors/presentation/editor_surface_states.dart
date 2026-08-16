part of "editor_surface.dart";

class _SelectionConflictEditor extends StatelessWidget {
  const _SelectionConflictEditor({
    required this.controller,
    required this.path,
    required this.type,
    required this.registry,
    required this.readOnly,
  });

  final EditorController controller;
  final DataPath path;
  final TypeExpression type;
  final TypeRegistry registry;
  final bool readOnly;

  @override
  Widget build(BuildContext context) => Admonition.warning(
    child: TextButton(
      onPressed: readOnly ? null : _reset,
      child: const Text("Selected values differ. Reset to edit them together"),
    ),
  );

  void _reset() {
    final initial = type.createInitialValue(registry: registry).valueOrNull;
    if (initial != null) controller.update(path, initial);
  }
}

class _LoadingEditor extends HookWidget {
  const _LoadingEditor();

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
