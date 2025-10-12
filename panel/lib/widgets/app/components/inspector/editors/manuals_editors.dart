import "package:collection/collection.dart";
import "package:flutter/material.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:pub_semver/pub_semver.dart";
import "package:typewriter_panel/generated/models/module.pb.dart";
import "package:typewriter_panel/logic/manuals/manuals.dart";
import "package:typewriter_panel/logic/modules/module_type_extensions.dart";
import "package:typewriter_panel/logic/selectable/data_blueprint.dart";
import "package:typewriter_panel/logic/selectable/selection.dart";
import "package:typewriter_panel/utils/map.dart";
import "package:typewriter_panel/utils/string.dart";
import "package:typewriter_panel/widgets/app/components/inspector/editors.dart";
import "package:typewriter_panel/widgets/app/components/inspector/editors/field_editor.dart";
import "package:typewriter_panel/widgets/app/components/inspector/editors/list_editor.dart";
import "package:typewriter_panel/widgets/app/components/inspector/header.dart";
import "package:typewriter_panel/widgets/generic/components/depth_box.dart";
import "package:typewriter_panel/widgets/generic/components/section_title.dart";

class ManualPlatformTargetEditor extends Editor {
  @override
  bool canEdit(DataBlueprint dataBlueprint) =>
      dataBlueprint.matches(DataBlueprint.manualPlatformTarget());

  @override
  Widget build(String path, DataBlueprint dataBlueprint, EditorMode mode) {
    return _ManualPlatformTargetEditorWidget(
      path: path,
      blueprint: dataBlueprint as CustomBlueprint,
      editorMode: mode,
    );
  }
}

class _ManualPlatformTargetEditorWidget extends HookConsumerWidget {
  const _ManualPlatformTargetEditorWidget({
    required this.path,
    required this.blueprint,
    required this.editorMode,
  });

  final String path;
  final CustomBlueprint blueprint;
  final EditorMode editorMode;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FieldValueEditor(
      path: path,
      dataBlueprint: blueprint,
      editorMode: EditorMode.readOnlyInspector,
      builder: (value) {
        final target = PlatformTarget.fromJson(stringMap(value));

        return FieldHeader(
          path: path,
          dataBlueprint: blueprint,
          canExpand: true,
          editorMode: editorMode,
          title: target.platform.displayName,
          child: Column(
            spacing: 8,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final MapEntry(key: name, value: constraint)
                  in target.constraints.entries)
                _PlatformConstraintEditor(name: name, constraint: constraint),
            ],
          ),
        );
      },
    );
  }
}

class _PlatformConstraintEditor extends HookConsumerWidget {
  const _PlatformConstraintEditor({
    required this.name,
    required this.constraint,
  });

  final String name;
  final PlatformConstraint constraint;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      spacing: 8,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionTitle(title: name.formatted),
        switch (constraint) {
          PlatformVersionConstraint(versions: final vs) =>
            _PlatformVersionConstraintEditor(
              versions: vs.map(Version.parse).toList(),
            ),
        },
      ],
    );
  }
}

class _PlatformVersionConstraintEditor extends HookConsumerWidget {
  const _PlatformVersionConstraintEditor({required this.versions});

  final List<Version> versions;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    return DepthBox(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: SizedBox(
          width: double.infinity,
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            direction: Axis.horizontal,
            alignment: WrapAlignment.start,
            runAlignment: WrapAlignment.start,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              for (final version in versions)
                _Badge(
                  label: version.canonicalizedVersion,
                  color: theme.colorScheme.primary,
                  onColor: theme.colorScheme.onPrimary,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class ManualModuleReferenceEditor extends Editor {
  @override
  bool canEdit(DataBlueprint dataBlueprint) =>
      dataBlueprint.matches(DataBlueprint.manualModuleReference());

  @override
  Widget build(String path, DataBlueprint dataBlueprint, EditorMode mode) {
    return _ManualModuleReferenceEditorWidget(
      path: path,
      blueprint: dataBlueprint as CustomBlueprint,
      editorMode: mode,
    );
  }
}

class _ManualModuleReferenceEditorWidget extends HookConsumerWidget {
  const _ManualModuleReferenceEditorWidget({
    required this.path,
    required this.blueprint,
    required this.editorMode,
  });

  final String path;
  final CustomBlueprint blueprint;
  final EditorMode editorMode;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FieldValueEditor(
      path: path,
      dataBlueprint: blueprint,
      editorMode: EditorMode.readOnlyInspector,
      builder: (value) {
        final reference = ManualModuleReference.fromJson(stringMap(value));
        final theme = Theme.of(context);

        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(6),
            color: theme.colorScheme.surfaceContainerLowest,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            children: [
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  "${reference.name} ${reference.type.displayName}",
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 12),
              _Badge(
                label: reference.version.canonicalizedVersion,
                color: theme.colorScheme.primary,
                onColor: theme.colorScheme.onPrimary,
              ),
            ],
          ),
        );
      },
    );
  }
}

class ManualModulesListEditor extends Editor {
  @override
  bool canEdit(DataBlueprint dataBlueprint) => dataBlueprint.matches(
    DataBlueprint.list(type: DataBlueprint.manualModuleReference()),
  );

  @override
  Widget build(String path, DataBlueprint dataBlueprint, EditorMode mode) {
    return _ManualModulesListEditorWidget(
      path: path,
      listBlueprint: dataBlueprint as ListBlueprint,
      editorMode: mode,
    );
  }

  @override
  (HeaderActions, Iterable<(String, HeaderContext, DataBlueprint)>)
  headerActions(
    Ref ref,
    String path,
    DataBlueprint dataBlueprint,
    HeaderContext context,
    EditorMode mode,
  ) {
    final actions = super.headerActions(
      ref,
      path,
      dataBlueprint,
      context,
      mode,
    );

    final listBlueprint = dataBlueprint as ListBlueprint;

    final length =
        (ref.watch(fieldValueProvider(path)).value([]) as List<dynamic>? ?? [])
            .length;

    final childContext = context.copyWith(parentBlueprint: listBlueprint);
    final children = List.generate(
      length,
      (i) => (path.join("$i"), childContext, listBlueprint.type),
    );

    return (actions.$1, actions.$2.followedBy(children));
  }
}

class _ManualModulesListEditorWidget extends HookConsumerWidget {
  const _ManualModulesListEditorWidget({
    required this.path,
    required this.listBlueprint,
    required this.editorMode,
  });

  final String path;
  final ListBlueprint listBlueprint;
  final EditorMode editorMode;

  List<(int, ManualModuleReference)> _indexed(WidgetRef ref) {
    final fieldValue = ref.watch(fieldValueProvider(path));
    final raw = fieldValue.value(<dynamic>[]) as List<dynamic>? ?? [];
    final indexed = raw.indexed.map<(int, ManualModuleReference)>((t) {
      final mmr = ManualModuleReference.fromJson(stringMap(t.$2));
      return (t.$1, mmr);
    }).toList();
    return indexed;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final indexed = _indexed(ref);

    final grouped = indexed.groupListsBy((t) => t.$2.type);

    final hasItems = indexed.isNotEmpty;

    return FieldHeader(
      path: path,
      dataBlueprint: listBlueprint,
      canExpand: true,
      editorMode: EditorMode.readOnlyInspector,
      child: hasItems
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final type in ModuleType.values)
                  if (grouped[type]?.isNotEmpty ?? false) ...[
                    Padding(
                      padding: const EdgeInsets.only(top: 8, bottom: 6),
                      child: Text(
                        type.displayName,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: type.themedColor(context),
                        ),
                      ),
                    ),
                    ...grouped[type]!.map(
                      (t) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: FieldEditor(
                          path: path.join("${t.$1}"),
                          dataBlueprint: DataBlueprint.manualModuleReference(),
                          editorMode: EditorMode.readOnlyInspector,
                        ),
                      ),
                    ),
                  ],
              ],
            )
          : NoElements(path: path, onAdd: null),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({
    required this.label,
    required this.color,
    required this.onColor,
  });

  final String label;
  final Color color;
  final Color onColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: Theme.of(
          context,
        ).textTheme.labelSmall?.copyWith(color: color, letterSpacing: 0.5),
      ),
    );
  }
}
