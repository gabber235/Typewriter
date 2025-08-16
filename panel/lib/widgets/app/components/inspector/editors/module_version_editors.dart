import "dart:math";

import "package:collection/collection.dart";
import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:flutter_hooks/flutter_hooks.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:iconify_flutter_plus/icons/fa6_solid.dart";
import "package:typewriter_panel/logic/module_version/module_version.dart";
import "package:typewriter_panel/logic/modules.dart";
import "package:typewriter_panel/logic/selectable/data_blueprint.dart";
import "package:typewriter_panel/logic/selectable/selection.dart";
import "package:typewriter_panel/main.dart";
import "package:typewriter_panel/utils/map.dart";
import "package:typewriter_panel/utils/string.dart";
import "package:typewriter_panel/widgets/app/components/inspector/editors.dart";
import "package:typewriter_panel/widgets/app/components/inspector/editors/field_editor.dart";
import "package:typewriter_panel/widgets/app/components/inspector/header.dart";
import "package:typewriter_panel/widgets/generic/components/action_shortcuts.dart";

import "package:typewriter_panel/widgets/generic/components/focus_highlight.dart";
import "package:typewriter_panel/widgets/generic/components/icones.dart";
import "package:typewriter_panel/widgets/generic/components/popups.dart";
import "package:typewriter_panel/widgets/generic/components/version_filter.dart";

/// Renders a flat, chronologically sorted list of ModuleVersion items.
/// Uses a query-driven filter with contextual suggestions optimized
/// for large version sets (epoch → major → minor → patch).
class ModuleVersionListEditor extends Editor {
  @override
  bool canEdit(DataBlueprint dataBlueprint) => dataBlueprint.matches(
        DataBlueprint.list(type: DataBlueprint.moduleVersion()),
      );

  @override
  Widget build(String path, DataBlueprint dataBlueprint, EditorMode mode) {
    return _ModuleVersionListEditorWidget(
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
    final actions =
        super.headerActions(ref, path, dataBlueprint, context, mode);
    final listBlueprint = dataBlueprint as ListBlueprint;
    final raw = ref.watch(fieldValueProvider(path)).value(<dynamic>[]);
    final length = raw is List ? raw.length : 0;

    final childContext = context.copyWith(parentBlueprint: listBlueprint);
    final children = List.generate(
      length,
      (i) => (path.join("$i"), childContext, listBlueprint.type),
    );

    return (actions.$1, actions.$2.followedBy(children));
  }
}

class _ModuleVersionListEditorWidget extends HookConsumerWidget {
  const _ModuleVersionListEditorWidget({
    required this.path,
    required this.listBlueprint,
    required this.editorMode,
  });

  final String path;
  final ListBlueprint listBlueprint;
  final EditorMode editorMode;

  List<(int, ModuleVersion)> indexedModuleVersions(WidgetRef ref) {
    final fieldValue = ref.watch(fieldValueProvider(path));
    final raw = fieldValue.value(<dynamic>[]) as List<dynamic>? ?? [];
    final indexed = raw.indexed.map<(int, ModuleVersion)>((t) {
      final mv = ModuleVersion.fromJson(stringMap(t.$2));
      return (t.$1, mv);
    }).sorted((a, b) => a.$2.compareTo(b.$2));
    return indexed;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = useState<VersionFilter>(const VersionFilter());

    final indexed = indexedModuleVersions(ref);
    final itemBlueprint = listBlueprint.type;

    final hasEpoch =
        useMemoized(() => indexed.any((v) => v.$2.epoch != 0), [indexed]);

    final filtered = indexed
        .where((e) => filter.value.matches(e.$2.version))
        .sorted((a, b) => b.$2.compareTo(a.$2));

    return FieldHeader(
      path: path,
      dataBlueprint: listBlueprint,
      canExpand: true,
      editorMode: editorMode,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          VersionFilterBar(
            filtered: filtered.map((e) => e.$2.version).toList(),
            filter: filter,
            hasEpoch: hasEpoch,
          ),
          const SizedBox(height: 12),
          if (filtered.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                "No versions",
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            )
          // If we have many versions, we want to have a sub list in this because otherwise the inspector will be too large and too lagy.
          else if (filtered.length > 5)
            ConstrainedBox(
              constraints: BoxConstraints(maxHeight: 500),
              child: ListView.builder(
                itemCount: filtered.length,
                itemBuilder: (context, index) {
                  final trueIndex = filtered[index].$1;
                  return _buildVersionListItem(trueIndex, itemBlueprint);
                },
              ),
            )
          else
            for (final t in filtered)
              _buildVersionListItem(t.$1, itemBlueprint),
        ],
      ),
    );
  }

  Widget _buildVersionListItem(
    int index,
    DataBlueprint itemBlueprint,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: FieldEditor(
        path: path.join("$index"),
        editorMode: editorMode,
        dataBlueprint: itemBlueprint,
      ),
    );
  }
}

/// Editor for a single ModuleVersion row with state badge and actions.
class ModuleVersionEditor extends Editor {
  @override
  bool canEdit(DataBlueprint dataBlueprint) =>
      dataBlueprint.matches(DataBlueprint.moduleVersion());

  @override
  Widget build(String path, DataBlueprint dataBlueprint, EditorMode mode) {
    return _ModuleVersionEditorWidget(
      path: path,
      versionBlueprint: dataBlueprint as CustomBlueprint,
      editorMode: mode,
    );
  }
}

class _ModuleVersionEditorWidget extends HookConsumerWidget {
  const _ModuleVersionEditorWidget({
    required this.path,
    required this.versionBlueprint,
    required this.editorMode,
  });

  final String path;
  final CustomBlueprint versionBlueprint;
  final EditorMode editorMode;

  Future<void> _changeState(
    WidgetRef ref,
    ModuleVersion mv,
    ModuleVersionState target,
  ) async {
    final ids =
        ref.read(selectedProvider).requireValue.map((s) => s.id.id).toList();

    await ref
        .read(modulesProvider.notifier)
        .changeVersionState(ids, mv.version, target);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final focusNode = useFocusNode(descendantsAreFocusable: false);
    return FieldValueEditor(
      path: path,
      dataBlueprint: versionBlueprint,
      editorMode: editorMode,
      builder: (value) {
        final mv = ModuleVersion.fromJson(stringMap(value));
        final theme = Theme.of(context);
        final state = mv.state;
        final color = mv.state.color;
        return ManagedActionSet(
          shortcuts: [
            if (state.canPublish)
              ActionShortcut(
                id: "publish_module_version",
                label: "Publish",
                description: "Publish the module version",
                priority: 1000,
                activators: [
                  SingleActivator(LogicalKeyboardKey.keyP),
                  SingleActivator(LogicalKeyboardKey.keyP, shift: true),
                  if (!state.canYoink) ...shortcutsFor(ActivateIntent),
                ],
                onInvoke: (ref) async {
                  await _showPublishConfirmationDialogue(context, mv, ref);
                },
                icon: const Icones(Fa6Solid.rocket),
              ),
            if (state.canYoink)
              ActionShortcut(
                id: "yoink_module_version",
                label: "Yoink",
                description: "Yoink the module version",
                priority: 1001,
                activators: [
                  SingleActivator(LogicalKeyboardKey.keyY),
                  SingleActivator(LogicalKeyboardKey.keyY, shift: true),
                  if (!state.canPublish) ...shortcutsFor(ActivateIntent),
                ],
                onInvoke: (ref) async {
                  await _showYoinkConfirmationDialogue(context, mv, ref);
                },
                icon: const Icones(Fa6Solid.ban),
              ),
          ],
          child: ManagedFocusHighlight(
            focusNode: focusNode,
            descendantsAreFocusable: false,
            debugLabel: "ModuleVersionEditor",
            borderRadius: BorderRadius.circular(6),
            child: Opacity(
              opacity: state.isActive ? 1.0 : 0.5,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(6),
                  color: theme.colorScheme.surfaceContainerLowest,
                ),
                padding: EdgeInsets.only(left: 12),
                child: Row(
                  children: [
                    Text(
                      mv.display,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        decoration:
                            state.isActive ? null : TextDecoration.lineThrough,
                        decorationStyle: TextDecorationStyle.wavy,
                        decorationThickness: 2.0,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        state.name,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: color,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    const Spacer(),
                    if ((editorMode, versionBlueprint).canEdit) ...[
                      if (state.canPublish)
                        _buildPublishButton(context, ref, mv),
                      if (state.canYoink) _buildYoinkButton(context, ref, mv),
                    ],
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  static const confirmationDelay = Duration(seconds: 3);

  Widget _buildPublishButton(
    BuildContext context,
    WidgetRef ref,
    ModuleVersion mv,
  ) {
    return Tooltip(
      message: "Publish",
      child: IconButton(
        icon: const Icones(Fa6Solid.rocket, size: 16),
        color: ModuleVersionState.published.color,
        onPressed: () => _showPublishConfirmationDialogue(context, mv, ref),
      ),
    );
  }

  Future<bool> _showPublishConfirmationDialogue(
    BuildContext context,
    ModuleVersion mv,
    WidgetRef ref,
  ) {
    return showConfirmationDialogue(
      context: context,
      title: "Publish ${mv.display}?",
      titleColor: ModuleVersionState.published.color,
      body: SizedBox(
        width: min(MediaQuery.of(context).size.width * 0.8, 500),
        child: Text.rich(
          TextSpan(
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              height: 1.35,
              fontVariations: [FontVariation("wght", 200)],
            ),
            children: [
              TextSpan(text: "Are you sure you want to publish "),
              TextSpan(
                text: mv.display,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              TextSpan(text: "?\n\n"),
              TextSpan(
                text: "What publishing means:",
                style: TextStyle(fontVariations: [FontVariation("wght", 600)]),
              ),
              TextSpan(
                text:
                    "\n• Everyone who already has access to this module (managed in the marketplace) will be able to upgrade to this version.",
              ),
              TextSpan(
                text:
                    "\n• You will no longer be able to override or change any artifacts for this version, it becomes permanent.",
              ),
              TextSpan(
                text: "\n\nWhat publishing does not do:",
                style: TextStyle(fontVariations: [FontVariation("wght", 600)]),
              ),
              TextSpan(
                text:
                    "\n• It does not change who has access. Access is managed in the marketplace, and no new people will gain access because of publishing.",
              ),
            ],
          ),
        ),
      ),
      confirmText: "Publish",
      confirmIcon: Fa6Solid.rocket,
      confirmColor: ModuleVersionState.published.color,
      onConfirmColor: Colors.white,
      delayConfirm: confirmationDelay,
      onConfirm: () => _changeState(
        ref,
        mv,
        ModuleVersionState.published,
      ),
    );
  }

  Widget _buildYoinkButton(
    BuildContext context,
    WidgetRef ref,
    ModuleVersion mv,
  ) {
    return Tooltip(
      message: "Yoink",
      child: IconButton(
        icon: const Icones(Fa6Solid.ban, size: 16),
        color: ModuleVersionState.yoinked.color,
        onPressed: () => _showYoinkConfirmationDialogue(context, mv, ref),
      ),
    );
  }

  Future<bool> _showYoinkConfirmationDialogue(
    BuildContext context,
    ModuleVersion mv,
    WidgetRef ref,
  ) {
    return showConfirmationDialogue(
      context: context,
      title: "Yoink ${mv.display}?",
      titleColor: ModuleVersionState.yoinked.color,
      body: SizedBox(
        width: min(MediaQuery.of(context).size.width * 0.8, 500),
        child: Text.rich(
          TextSpan(
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              height: 1.35,
              fontVariations: [FontVariation("wght", 200)],
            ),
            children: [
              TextSpan(text: "Are you sure you want to yoink "),
              TextSpan(
                text: mv.display,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              TextSpan(text: "?\n\n"),
              TextSpan(
                text: "What yoinking means:",
                style: TextStyle(fontVariations: [FontVariation("wght", 600)]),
              ),
              TextSpan(
                text:
                    "\n• Nobody new will be able to start using this version (no new installs or upgrades will target it).",
              ),
              TextSpan(
                text:
                    "\n• Use this when a version contains bugs and should not be used anymore.",
              ),
              TextSpan(
                text: "\n\nWhat yoinking does not do:",
                style: TextStyle(fontVariations: [FontVariation("wght", 600)]),
              ),
              TextSpan(
                text:
                    "\n• It does not delete the version. Existing users who already depend on it will continue to have access so their setups do not break.",
              ),
            ],
          ),
        ),
      ),
      confirmText: "Yoink",
      confirmIcon: Fa6Solid.ban,
      confirmColor: ModuleVersionState.yoinked.color,
      onConfirmColor: Colors.white,
      delayConfirm: confirmationDelay,
      onConfirm: () => _changeState(
        ref,
        mv,
        ModuleVersionState.yoinked,
      ),
    );
  }
}
