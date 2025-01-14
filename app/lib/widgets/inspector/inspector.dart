import "package:flutter/material.dart" hide Title;
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:indent/indent.dart";
import "package:riverpod_annotation/riverpod_annotation.dart";
import "package:typewriter/app_router.dart";
import "package:typewriter/models/entry.dart";
import "package:typewriter/models/page.dart";
import "package:typewriter/utils/extensions.dart";
import "package:typewriter/utils/passing_reference.dart";
import "package:typewriter/widgets/components/app/cinematic_view.dart";
import "package:typewriter/widgets/components/general/context_menu_region.dart";
import "package:typewriter/widgets/components/general/identifier.dart";
import "package:typewriter/widgets/inspector/editors/name.dart";
import "package:typewriter/widgets/inspector/editors/object.dart";
import "package:typewriter/widgets/inspector/heading.dart";
import "package:typewriter/widgets/inspector/operations.dart";

part "inspector.g.dart";

class InspectingEntryNotifier extends StateNotifier<String?> {
  InspectingEntryNotifier(this.ref) : super(null);
  final Ref ref;

  void selectEntry(String id, {bool unSelectSegment = true}) {
    if (unSelectSegment) {
      ref.read(inspectingSegmentIdProvider.notifier).clear();
    }
    state = id;
  }

  void clearSelection() {
    state = null;
  }

  Future<void> navigateAndSelectEntry(PassingRef ref, String entryId) async {
    await ref.read(appRouter).navigateToEntry(ref, entryId);
    selectEntry(entryId);
  }
}

final inspectingEntryIdProvider =
    StateNotifierProvider<InspectingEntryNotifier, String?>(
  InspectingEntryNotifier.new,
  name: "inspectingEntryIdProvider",
);

@riverpod
Entry? inspectingEntry(Ref ref) {
  final selectedEntryId = ref.watch(inspectingEntryIdProvider);
  if (selectedEntryId == null) return null;
  return ref.watch(globalEntryProvider(selectedEntryId));
}

class GenericInspector extends HookConsumerWidget {
  const GenericInspector({
    super.key,
  }) : super();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final inspectingEntry = ref.watch(inspectingEntryProvider);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400),
        child: inspectingEntry != null
            ? EntryInspector(key: ValueKey(inspectingEntry.id))
            : const EmptyInspector(),
      ),
    );
  }
}

/// The content of the inspector when no entry is selected.
class EmptyInspector extends HookConsumerWidget {
  const EmptyInspector({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Inspector"),
        const SizedBox(height: 12),
        Text(
          "Click on an entry to inspect its properties.",
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 40),
      ],
    );
  }
}

@riverpod
EntryDefinition? inspectingEntryDefinition(Ref ref) {
  final entryId = ref.watch(inspectingEntryIdProvider);

  if (entryId.isNullOrEmpty) {
    return null;
  }

  return ref.watch(entryDefinitionProvider(entryId!));
}

/// The content of the inspector when an dynamic entry is selected.
class EntryInspector extends HookConsumerWidget {
  const EntryInspector({
    this.ignoreFields = const [],
    this.actions = const [],
    this.sections = const [],
    super.key,
  }) : super();

  final List<String> ignoreFields;
  final List<ContextMenuTile> actions;

  /// Additional sections to display in the inspector.
  final List<Widget> sections;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final objectBlueprint = ref.watch(
      inspectingEntryDefinitionProvider.select(
        (def) => def?.blueprint.dataBlueprint,
      ),
    );

    if (objectBlueprint == null) {
      return const NoBlueprintEntryInspector();
    }

    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Heading(),
          const Divider(),
          const NameField(),
          const Divider(),
          ObjectEditor(
            path: "",
            objectBlueprint: objectBlueprint,
            ignoreFields: ["id", "name", ...ignoreFields],
            defaultExpanded: true,
          ),
          for (final section in sections) ...[
            const Divider(),
            section,
          ],
          const Divider(),
          Operations(actions: actions),
          const SizedBox(height: 30),
        ],
      ),
    );
  }
}

class NoBlueprintEntryInspector extends HookConsumerWidget {
  const NoBlueprintEntryInspector({
    super.key,
  }) : super();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entry = ref.watch(inspectingEntryProvider);

    if (entry == null) return const SizedBox();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Title(
          color: Colors.redAccent,
          title: entry.formattedName,
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 2,
          direction: Axis.horizontal,
          alignment: WrapAlignment.start,
          children: [
            EntryBlueprintDisplay(
              blueprintId: entry.blueprintId,
              url: "",
              color: Colors.redAccent,
            ),
            Identifier(id: entry.id),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          """
          |The blueprint for this entry does not exist.
          |
          |This can happen if the extension for this entry is no longer installed.
          |Or if the extension removed the entry type.
          |
          |To fix this, you can either:
          | - Install the extension again.
          | - Remove the entry.
        """
              .trimMargin(),
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(),
        ),
        const SizedBox(height: 12),
        const DeleteEntry(),
      ],
    );
  }
}
