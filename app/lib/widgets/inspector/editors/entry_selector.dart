import "package:flutter/material.dart" hide Page;
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:typewriter/l10n/l10n_provider.dart";
import "package:typewriter/models/entry.dart";
import "package:typewriter/models/entry_blueprint.dart";
import "package:typewriter/models/page.dart";
import "package:typewriter/utils/extensions.dart";
import "package:typewriter/utils/icons.dart";
import "package:typewriter/utils/passing_reference.dart";
import "package:typewriter/utils/smart_single_activator.dart";
import "package:typewriter/widgets/components/app/entry_node.dart";
import "package:typewriter/widgets/components/app/entry_search.dart";
import "package:typewriter/widgets/components/app/search_bar.dart";
import "package:typewriter/widgets/components/general/context_menu_region.dart";
import "package:typewriter/widgets/components/general/iconify.dart";
import "package:typewriter/widgets/inspector/editors.dart";
import "package:typewriter/widgets/inspector/inspector.dart";

class EntrySelectorEditorFilter extends EditorFilter {
  @override
  bool canEdit(DataBlueprint dataBlueprint) =>
      dataBlueprint.hasModifier("entry");

  @override
  Widget build(String path, DataBlueprint dataBlueprint) =>
      EntrySelectorEditor(path: path, dataBlueprint: dataBlueprint);
}

class EntrySelectorEditor extends HookConsumerWidget {
  const EntrySelectorEditor({
    required this.path,
    required this.dataBlueprint,
    this.forcedValue,
    this.onChanged,
    super.key,
  }) : super();

  final String path;
  final DataBlueprint dataBlueprint;

  final String? forcedValue;
  final void Function(String)? onChanged;

  bool _update(PassingRef ref, Entry? entry) {
    if (entry == null) return false;
    if (onChanged != null) {
      onChanged!(entry.id);
      return true;
    }
    ref
        .read(inspectingEntryDefinitionProvider)
        ?.updateField(ref, path, entry.id);
    return true;
  }

  void _select(PassingRef ref, List<String> tags) {
    final selectedEntryId = ref.read(inspectingEntryIdProvider);
    ref.read(searchProvider.notifier).asBuilder()
      ..anyTag(tags, canRemove: false)
      ..excludeEntry(selectedEntryId ?? "", canRemove: false)
      ..nonGenericAddEntry()
      ..fetchEntry(onSelect: (entry) => _update(ref, entry))
      ..fetchNewEntry(onAdded: (entry) => _update(ref, entry))
      ..open();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tag = dataBlueprint.get<String>("entry") ?? "";
    final onlyTags = dataBlueprint.get<String>("only_tags")?.split(",") ?? [];
    final entryId =
        forcedValue ?? ref.watch(fieldValueProvider(path, "")) as String;

    return DragTarget<EntryDrag>(
      onWillAcceptWithDetails: (details) {
        if (details.data.entryId == entryId) return false;

        final entry = ref.read(globalEntryProvider(details.data.entryId));
        if (entry == null) return false;
        final blueprint = ref.read(entryBlueprintProvider(entry.blueprintId));
        if (blueprint == null) return false;

        return blueprint.tags.contains(tag);
      },
      onAcceptWithDetails: (details) {
        final entry = ref.read(globalEntryProvider(details.data.entryId));
        _update(ref.passing, entry);
      },
      builder: (context, candidateData, rejectedData) {
        if (rejectedData.isNotEmpty) {
          return EntrySelectorRejectWidget();
        }
        final isAccepting = candidateData.isNotEmpty;

        return EntrySelectorEditorDisplay(
          entryId: candidateData.firstOrNull?.entryId ?? entryId,
          display: tag.formatted,
          isAccepting: isAccepting,
          selectEntry: () {
            _select(ref.passing, onlyTags.isEmpty ? [tag] : onlyTags);
          },
          onRemove: () {
            ref.read(inspectingEntryDefinitionProvider)?.updateField(
                  ref.passing,
                  path,
                  dataBlueprint.defaultValue(),
                );
          },
        );
      },
    );
  }
}

class EntrySelectorEditorDisplay extends ConsumerWidget {
  const EntrySelectorEditorDisplay({
    required this.entryId,
    required this.display,
    this.isAccepting = false,
    this.selectEntry,
    this.onRemove,
    super.key,
  });

  final String entryId;
  final String display;
  final bool isAccepting;

  final VoidCallback? selectEntry;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = ref.watch(l10nProvider);
    final hasEntry = ref.watch(entryExistsProvider(entryId));
    final needsPadding = !hasEntry && !isAccepting;

    return Material(
      color: Theme.of(context).inputDecorationTheme.fillColor,
      borderRadius: BorderRadius.circular(8),
      child: ContextMenuRegion(
        builder: (context) {
          return [
            if (hasEntry) ...[
              ContextMenuTile.button(
                title: l10n.navigateToEntry,
                icon: TWIcons.pencil,
                onTap: () {
                  ref
                      .read(inspectingEntryIdProvider.notifier)
                      .navigateAndSelectEntry(ref.passing, entryId);
                },
              ),
              if (entryId.isNotEmpty)
                ContextMenuTile.button(
                  title: l10n.deleteReference,
                  icon: TWIcons.squareMinus,
                  color: Colors.redAccent,
                  onTap: onRemove,
                ),
            ],
            if (!hasEntry) ...[
              ContextMenuTile.button(
                title: l10n.selectEntry,
                icon: TWIcons.magnifyingGlass,
                onTap: selectEntry,
              ),
            ],
          ];
        },
        child: InkWell(
          onTap: () {
            if (hasOverrideDown && hasEntry) {
              ref
                  .read(inspectingEntryIdProvider.notifier)
                  .navigateAndSelectEntry(ref.passing, entryId);
              return;
            }
            selectEntry?.call();
          },
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: EdgeInsets.only(
              left: needsPadding ? 12 : 4,
              right: 16,
              top: needsPadding ? 12 : 4,
              bottom: needsPadding ? 12 : 4,
            ),
            child: Row(
              children: [
                if (!hasEntry && !isAccepting) ...[
                  Iconify(
                    TWIcons.database,
                    size: 16,
                    color:
                        Theme.of(context).inputDecorationTheme.hintStyle?.color,
                  ),
                  const SizedBox(width: 12),
                ],
                if (isAccepting)
                  Expanded(
                    child: Opacity(
                      opacity: 0.5,
                      child: FakeEntryNode(
                        entryId: entryId,
                      ),
                    ),
                  )
                else if (hasEntry)
                  Expanded(child: FakeEntryNode(entryId: entryId))
                else
                  Expanded(
                    child: Text(
                      l10n.selectAEntry(display),
                      style: Theme.of(context).inputDecorationTheme.hintStyle,
                    ),
                  ),
                const SizedBox(width: 12),
                Iconify(
                  TWIcons.caretDown,
                  size: 16,
                  color:
                      Theme.of(context).inputDecorationTheme.hintStyle?.color,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class EntrySelectorRejectWidget extends HookConsumerWidget {
  const EntrySelectorRejectWidget({
    super.key,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = ref.watch(l10nProvider);
    return Material(
      color: Theme.of(context).inputDecorationTheme.fillColor,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Row(
          children: [
            Iconify(
              TWIcons.x,
              size: 16,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                l10n.entryNotAllow,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
