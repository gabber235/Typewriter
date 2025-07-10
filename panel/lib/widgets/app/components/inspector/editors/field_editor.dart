import "package:collection/collection.dart";
import "package:dotted_border/dotted_border.dart";
import "package:flutter/material.dart";
import "package:flutter_animate/flutter_animate.dart";
import "package:flutter_hooks/flutter_hooks.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:iconify_flutter_plus/icons/fa6_solid.dart";
import "package:typewriter_panel/logic/selectable/data_blueprint.dart";
import "package:typewriter_panel/logic/selectable/selection.dart";
import "package:typewriter_panel/widgets/app/components/inspector/editors.dart";
import "package:typewriter_panel/widgets/generic/components/admonition.dart";
import "package:typewriter_panel/widgets/generic/components/icones.dart";

class FieldEditor extends HookConsumerWidget {
  const FieldEditor({
    required this.path,
    required this.dataBlueprint,
    required this.editorMode,
    super.key,
  }) : super();
  final String path;
  final DataBlueprint dataBlueprint;
  final EditorMode editorMode;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filters = ref.watch(editorsProvider);

    final editor =
        filters.firstWhereOrNull((filter) => filter.canEdit(dataBlueprint));

    if (editor == null) {
      return _NoEditorFound(path: path, dataBlueprint: dataBlueprint);
    }

    return editor.build(path, dataBlueprint, editorMode);
  }
}

class _NoEditorFound extends StatelessWidget {
  const _NoEditorFound({
    required this.path,
    required this.dataBlueprint,
  });

  final String path;
  final DataBlueprint dataBlueprint;

  @override
  Widget build(BuildContext context) {
    return Admonition.danger(
      child: Text(
        "Could not find a editor for '$path', with data blueprint '${dataBlueprint.runtimeType}'",
      ),
    );
  }
}

class FieldValueEditor extends HookConsumerWidget {
  const FieldValueEditor({
    required this.path,
    required this.dataBlueprint,
    required this.editorMode,
    required this.builder,
    this.forceValue,
    super.key,
  }) : super();
  final String path;
  final DataBlueprint dataBlueprint;
  final EditorMode editorMode;
  final Widget Function(dynamic value) builder;
  final dynamic forceValue;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (forceValue != null) {
      return builder(forceValue);
    }
    final value = ref.watch(fieldValueProvider(path));
    switch (value) {
      case Value(:final value):
        return builder(value);
      case ConflictValue():
        return _ConflictValueEditor(
          path: path,
          dataBlueprint: dataBlueprint,
          editorMode: editorMode,
        );
      case NoneValue():
        return _NoneValueEditor(
          path: path,
          dataBlueprint: dataBlueprint,
          editorMode: editorMode,
        );
      case LoadingValue():
        return _LoadingValueEditor();
    }
  }
}

class _ConflictValueEditor extends HookConsumerWidget {
  const _ConflictValueEditor({
    required this.path,
    required this.dataBlueprint,
    required this.editorMode,
  });

  final String path;
  final DataBlueprint dataBlueprint;
  final EditorMode editorMode;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Material(
      color: Theme.of(context).inputDecorationTheme.fillColor,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: editorMode.canEdit
            ? () {
                ref
                    .read(selectedProvider.notifier)
                    .updateFieldValue(path, dataBlueprint.defaultValue());
              }
            : null,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icones(
                Fa6Solid.xmark,
                size: 22,
                color: Theme.of(context).colorScheme.error,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  "Field has different values",
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NoneValueEditor extends HookConsumerWidget {
  const _NoneValueEditor({
    required this.path,
    required this.dataBlueprint,
    required this.editorMode,
  });

  final String path;
  final DataBlueprint dataBlueprint;
  final EditorMode editorMode;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DottedBorder(
      options: RoundedRectDottedBorderOptions(
        dashPattern: [10, 8],
        radius: Radius.circular(8),
        color: Theme.of(context).colorScheme.error,
        strokeCap: StrokeCap.round,
        strokeWidth: 2.0,
      ),
      child: Material(
        color: Theme.of(context).inputDecorationTheme.fillColor,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: editorMode.canEdit
              ? () {
                  ref
                      .read(selectedProvider.notifier)
                      .updateFieldValue(path, dataBlueprint.defaultValue());
                }
              : null,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Icones(
                  Fa6Solid.xmark,
                  size: 16,
                  color: Theme.of(context).colorScheme.error,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    "Field is missing",
                    style:
                        TextStyle(color: Theme.of(context).colorScheme.error),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LoadingValueEditor extends HookConsumerWidget {
  const _LoadingValueEditor();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = useAnimationController()..repeat(period: 2200.ms);

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: Theme.of(context).inputDecorationTheme.fillColor,
      ),
      height: 20 + 12 * 2,
    ).animate(controller: controller).shimmer(delay: 500.ms, duration: 1200.ms);
  }
}
