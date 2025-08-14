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
import "package:typewriter_panel/widgets/generic/components/decorated_text_field.dart";
import "package:typewriter_panel/widgets/generic/components/focus_highlight.dart";
import "package:typewriter_panel/widgets/generic/components/icones.dart";
import "package:typewriter_panel/widgets/generic/components/popups.dart";

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

/// Represents a structured, immutable filter over versions
/// (epoch → major → minor → patch).
class _ModuleVersionFilter {
  const _ModuleVersionFilter({
    this.epoch = const _Any(),
    this.semanticMajor = const _Any(),
    this.minor = const _Any(),
    this.patch = const _Any(),
  });

  final _ModuleVersionPartFilter epoch;
  final _ModuleVersionPartFilter semanticMajor;
  final _ModuleVersionPartFilter minor;
  final _ModuleVersionPartFilter patch;

  _ModuleVersionFilter copyWith({
    _ModuleVersionPartFilter? epoch,
    _ModuleVersionPartFilter? semanticMajor,
    _ModuleVersionPartFilter? minor,
    _ModuleVersionPartFilter? patch,
  }) {
    return _ModuleVersionFilter(
      epoch: epoch ?? this.epoch,
      semanticMajor: semanticMajor ?? this.semanticMajor,
      minor: minor ?? this.minor,
      patch: patch ?? this.patch,
    );
  }

  bool matches(ModuleVersion v) {
    if (!epoch.matches(v.epoch)) return false;
    if (!semanticMajor.matches(v.semanticMajor)) return false;
    if (!minor.matches(v.minor)) return false;
    if (!patch.matches(v.patch)) return false;

    return true;
  }

  bool get isEmpty =>
      epoch is _Any && semanticMajor is _Any && minor is _Any && patch is _Any;

  bool get isNotEmpty => !isEmpty;

  String display(bool hasEpoch) {
    var string = "";
    if (hasEpoch) string += "$epoch.";
    return string += "$semanticMajor.$minor.$patch";
  }

  _ModuleVersionFilter unwind() {
    if (patch is! _Any) return copyWith(patch: _Any());
    if (minor is! _Any) return copyWith(minor: _Any());
    if (semanticMajor is! _Any) return copyWith(semanticMajor: _Any());
    return copyWith(epoch: _Any());
  }
}

/// Version number segment filter abstraction used by the query parser and UI.
sealed class _ModuleVersionPartFilter {
  const _ModuleVersionPartFilter();
  bool matches(int value);
}

class _Any extends _ModuleVersionPartFilter {
  const _Any();
  @override
  bool matches(int value) => true;
  @override
  String toString() => "*";
}

/// Matches when a value equals the fixed integer.
class _Fixed extends _ModuleVersionPartFilter {
  const _Fixed(this.value);

  final int value;

  @override
  bool matches(int value) => value == this.value;
  @override
  String toString() => value.toString();
}

/// Matches when a value is within [from, to] inclusive.
class _Range extends _ModuleVersionPartFilter {
  const _Range(this.from, this.to);
  final int? from;
  final int? to;

  @override
  bool matches(int value) {
    if (from != null && value < from!) return false;
    if (to != null && value > to!) return false;
    return true;
  }

  @override
  String toString() {
    final fromStr = from?.toString() ?? "";
    final toStr = to?.toString() ?? "";
    return "$fromStr-$toStr";
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
    final filter = useState<_ModuleVersionFilter>(const _ModuleVersionFilter());

    final indexed = indexedModuleVersions(ref);
    final itemBlueprint = listBlueprint.type;

    final hasEpoch =
        useMemoized(() => indexed.any((v) => v.$2.epoch != 0), [indexed]);

    final filtered = indexed
        .where((e) => filter.value.matches(e.$2))
        .sorted((a, b) => b.$2.compareTo(a.$2));

    return FieldHeader(
      path: path,
      dataBlueprint: listBlueprint,
      canExpand: true,
      editorMode: editorMode,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _VersionFilterBar(
            filtered: filtered.map((e) => e.$2).toList(),
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

// ignore: avoid_classes_with_only_static_members
/// Parser utilities for ModuleVersionFilter.
/// Converts a freeform query into a structured filter.
/// Supported:
/// - With epochs in data: epoch.major.minor.patch
/// - Without epochs:      major.minor.patch
/// - Wildcards:           *
/// - Ranges:              a-b
class _ModuleVersionFilterParser {
  static _ModuleVersionFilter parse({
    required String query,
    required bool hasEpoch,
  }) {
    final q = query.trim();
    if (q.isEmpty) return const _ModuleVersionFilter();

    final parts =
        q.split(".").map(_ModuleVersionFilterParser.parsePart).toList();

    if (!hasEpoch && parts.length < 4) {
      parts.insert(0, _Any());
    }

    while (parts.length < 4) {
      parts.add(_Any());
    }

    final [epoch, major, minor, patch] = parts;
    return _ModuleVersionFilter(
      epoch: epoch,
      semanticMajor: major,
      minor: minor,
      patch: patch,
    );
  }

  static _ModuleVersionPartFilter parsePart(String part) {
    final trimmed = part.trim();
    if (trimmed.isEmpty) return _Any();

    if (trimmed.contains("-")) {
      final parts = trimmed.split("-").map((e) => e.trim().asInt).toList();
      if (parts.length != 2) return _Any();
      final [low, high] = parts;
      return _Range(low, high);
    }

    final v = trimmed.asInt;
    if (v != null) return _Fixed(v);
    return _Any();
  }

  static List<String> suggestionStrings(
    _ModuleVersionFilter filter,
    List<ModuleVersion> filtered,
    bool hasEpoch, {
    int max = 10,
  }) {
    if (hasEpoch && filter.epoch is _Any) {
      return _suggestions(
        filtered,
        (mv) => mv.epoch,
        (f) => filter.copyWith(epoch: f),
        hasEpoch,
        max,
      );
    } else if (filter.semanticMajor is _Any) {
      return _suggestions(
        filtered,
        (mv) => mv.semanticMajor,
        (f) => filter.copyWith(semanticMajor: f),
        hasEpoch,
        max,
      );
    } else if (filter.minor is _Any) {
      return _suggestions(
        filtered,
        (mv) => mv.minor,
        (f) => filter.copyWith(minor: f),
        hasEpoch,
        max,
      );
    } else if (filter.patch is _Any) {
      return _suggestions(
        filtered,
        (mv) => mv.patch,
        (f) => filter.copyWith(patch: f),
        hasEpoch,
        max,
      );
    }
    return [];
  }

  static List<String> _suggestions(
    List<ModuleVersion> filtered,
    int Function(ModuleVersion mv) toValue,
    _ModuleVersionFilter Function(_ModuleVersionPartFilter part) toFilter,
    bool hasEpoch,
    int max,
  ) {
    final values = filtered
        .map(toValue)
        .toSet()
        .sorted((a, b) => b.compareTo(a))
        .take(max)
        .map(_Fixed.new)
        .map((f) => toFilter(f))
        .map((f) => f.display(hasEpoch))
        .toList();
    return values;
  }
}

/// Query-based version filter input with contextual suggestions.
/// When epochs exist, it prioritizes epoch selection, then major,
/// then minor and patch. Suggestions always update the input directly.
class _VersionFilterBar extends HookWidget {
  const _VersionFilterBar({
    required this.filtered,
    required this.filter,
    required this.hasEpoch,
  });

  final List<ModuleVersion> filtered;
  final ValueNotifier<_ModuleVersionFilter> filter;
  final bool hasEpoch;

  @override
  Widget build(BuildContext context) {
    final focusNode = useFocusNode();
    final queryController = useTextEditingController(text: "");

    final suggestionLabels = useMemoized(
      () {
        return _ModuleVersionFilterParser.suggestionStrings(
          filter.value,
          filtered,
          hasEpoch,
          max: 9,
        );
      },
      [filtered],
    );

    void applyQuery(String q) {
      final parsed = _ModuleVersionFilterParser.parse(
        query: q.trim(),
        hasEpoch: hasEpoch,
      );

      filter.value = parsed;
    }

    void unwind() {
      final next = filter.value.unwind();
      filter.value = next;
      final text = next.isEmpty ? "" : next.display(hasEpoch);
      queryController.text = text;
    }

    void clear() {
      filter.value = _ModuleVersionFilter();
      queryController.text = "";
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          hasEpoch
              ? "Pattern: epoch.major.minor.patch • Supports * and ranges (a-b)"
              : "Pattern: major.minor.patch • Supports * and ranges (a-b)",
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 6),
        DecoratedTextField(
          focusNode: focusNode,
          controller: queryController,
          decoration: InputDecoration(
            hintText: "Filter versions",
            prefixIcon: const Icon(Icons.filter_alt),
            suffixIcon: filter.value.isEmpty
                ? null
                : IconButton(
                    icon: const Icon(Icons.undo),
                    tooltip: "Unwind",
                    onPressed: unwind,
                  ),
            isDense: true,
          ),
          onChanged: applyQuery,
          surroundingActions: [
            if (filter.value.isNotEmpty) ...[
              ActionShortcut(
                id: "module_version_filter_unwind",
                label: "Unwind",
                description: "Unwind the filter",
                activators: [
                  SingleActivator(LogicalKeyboardKey.delete),
                  SingleActivator(LogicalKeyboardKey.backspace),
                ],
                priority: 1001,
                onInvoke: (_) => unwind(),
              ),
              ActionShortcut(
                id: "module_version_filter_clear",
                label: "Clear",
                description: "Clear the filter",
                activators: [
                  SingleActivator(LogicalKeyboardKey.delete, control: true),
                  SingleActivator(LogicalKeyboardKey.backspace, control: true),
                  SingleActivator(LogicalKeyboardKey.delete, meta: true),
                  SingleActivator(LogicalKeyboardKey.backspace, meta: true),
                ],
                priority: 1000,
                onInvoke: (_) => clear(),
              ),
            ],
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            ...suggestionLabels.take(8).map((label) {
              return ChoiceChip(
                label: Text(label),
                selected: false,
                onSelected: (_) {
                  queryController.text = label;
                  applyQuery(label);
                },
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: VisualDensity.compact,
              );
            }),
          ],
        ),
      ],
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
