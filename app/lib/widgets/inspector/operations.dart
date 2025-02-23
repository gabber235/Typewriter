import "package:flutter/material.dart" hide FilledButton;
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:typewriter/models/page.dart";
import "package:typewriter/pages/page_editor.dart";
import "package:typewriter/utils/extensions.dart";
import "package:typewriter/utils/icons.dart";
import "package:typewriter/utils/passing_reference.dart";
import "package:typewriter/widgets/components/app/entry_node.dart";
import "package:typewriter/widgets/components/general/context_menu_region.dart";
import "package:typewriter/widgets/components/general/filled_button.dart";
import "package:typewriter/widgets/components/general/iconify.dart";
import "package:typewriter/widgets/components/general/outline_button.dart";
import "package:typewriter/widgets/inspector/inspector.dart";
import "package:typewriter/widgets/inspector/section_title.dart";

class Operations extends HookConsumerWidget {
  const Operations({
    this.actions = const [],
    super.key,
  }) : super();

  final List<ContextMenuTile> actions;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entryId = ref.read(inspectingEntryIdProvider);
    if (entryId == null) return const SizedBox();
    final linkablePaths = ref.watch(linkablePathsProvider(entryId));
    final linkableDuplicatePaths =
        ref.watch(linkableDuplicatePathsProvider(entryId));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionTitle(title: "Operations"),
        const SizedBox(height: 8),
        for (final action in actions) ...[
          if (action is ContextMenuDivider) const Divider(),
          if (action is ContextMenuButton)
            OutlineButton.icon(
              icon: Iconify(action.icon),
              label: Text(action.title),
              onPressed: action.onTap,
              color: action.color,
            ),
          const SizedBox(height: 8),
        ],
        if (linkablePaths.isNotEmpty) ...[
          _LinkWithEntry(paths: linkablePaths),
          const SizedBox(height: 8),
        ],
        if (linkableDuplicatePaths.isNotEmpty) ...[
          _LinkWithDuplicate(paths: linkableDuplicatePaths),
          const SizedBox(height: 8),
        ],
        const _DuplicateEntry(),
        const SizedBox(height: 8),
        const _MoveEntry(),
        const SizedBox(height: 8),
        const _ReplaceWithBlueprint(),
        const SizedBox(height: 8),
        const DeleteEntry(),
        const SizedBox(height: 8),
      ],
    );
  }
}

class _LinkWithEntry extends HookConsumerWidget {
  const _LinkWithEntry({
    required this.paths,
  });

  final List<String> paths;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return OutlineButton.icon(
      onPressed: () async {
        final page = ref.read(currentPageProvider);
        if (page == null) return;
        final entryId = ref.read(inspectingEntryIdProvider);
        if (entryId.isNullOrEmpty) return;
        final path = await pathSelector(context, paths);
        if (path == null) return;
        page.linkWith(ref.passing, entryId!, path);
      },
      icon: const Iconify(TWIcons.plus),
      label: const Text("Link with ..."),
      color: Colors.blue,
    );
  }
}

class _LinkWithDuplicate extends HookConsumerWidget {
  const _LinkWithDuplicate({
    required this.paths,
  });

  final List<String> paths;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return OutlineButton.icon(
      onPressed: () async {
        final page = ref.read(currentPageProvider);
        if (page == null) return;
        final entryId = ref.read(inspectingEntryIdProvider);
        if (entryId.isNullOrEmpty) return;
        final path = await pathSelector(context, paths);
        if (path == null) return;
        await page.linkWithDuplicate(ref.passing, entryId!, path);
      },
      icon: const Iconify(TWIcons.duplicate),
      label: const Text("Link with Duplicate"),
      color: Colors.blue,
    );
  }
}

class _DuplicateEntry extends HookConsumerWidget {
  const _DuplicateEntry();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FilledButton.icon(
      onPressed: () {
        final page = ref.read(currentPageProvider);
        if (page == null) return;
        final entryId = ref.read(inspectingEntryIdProvider);
        if (entryId.isNullOrEmpty) return;
        page.duplicateEntry(ref.passing, entryId!);
      },
      icon: const Iconify(TWIcons.duplicate),
      label: const Text("Duplicate"),
      color: Colors.blue,
    );
  }
}

class _MoveEntry extends HookConsumerWidget {
  const _MoveEntry();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FilledButton.icon(
      onPressed: () {
        final entryId = ref.read(inspectingEntryIdProvider);
        if (entryId.isNullOrEmpty) return;
        moveEntryToSelectingPage(
          ref.passing,
          entryId!,
        );
      },
      icon: const Iconify(TWIcons.moveEntry),
      label: const Text("Move Entry"),
      color: Theme.of(context).colorScheme.primary,
    );
  }
}

class _ReplaceWithBlueprint extends HookConsumerWidget {
  const _ReplaceWithBlueprint();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return OutlineButton.icon(
      onPressed: () {
        final page = ref.read(currentPageProvider);
        if (page == null) return;
        final entryId = ref.read(inspectingEntryIdProvider);
        if (entryId.isNullOrEmpty) return;
        page.replaceWithConfirmation(context, ref.passing, entryId!);
      },
      icon: const Iconify(TWIcons.replace),
      label: const Text("Replace with ..."),
      color: Colors.orange,
    );
  }
}

class DeleteEntry extends HookConsumerWidget {
  const DeleteEntry({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FilledButton.icon(
      onPressed: () {
        final page = ref.read(currentPageProvider);
        if (page == null) return;
        final entryId = ref.read(inspectingEntryIdProvider);
        if (entryId.isNullOrEmpty) return;
        page.deleteEntryWithConfirmation(context, ref.passing, entryId!);
      },
      icon: const Iconify(TWIcons.trash),
      label: const Text("Delete Entry"),
      color: Theme.of(context).colorScheme.error,
    );
  }
}
