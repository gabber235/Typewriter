import "package:flutter/material.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:iconify_flutter_plus/icons/heroicons_solid.dart";
import "package:typewriter_panel/features/organizations/features/realms/features/books/features/pages/features/editor/features/inspector/presentation/editors.dart";
import "package:typewriter_panel/shared/ui/components/icons.dart";
import "package:typewriter_panel/shared/ui/components/popups.dart";
import "package:typewriter_panel/shared/utilities/string.dart";

class RemoveHeaderAction extends HookConsumerWidget {
  const RemoveHeaderAction({
    required this.path,
    required this.onRemove,
    super.key,
  }) : super();

  final String path;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final name = ref.watch(pathDisplayNameProvider(path)).singular;
    return IconButton(
      icon: const Icones(HeroiconsSolid.trash),
      iconSize: 16,
      color: Theme.of(context).colorScheme.error,
      tooltip: "Remove $name",
      onPressed: () => showConfirmationDialogue(
        context: context,
        title: "Remove $name?",
        content: "Are you sure you want to remove this item?",
        onConfirm: onRemove,
      ),
    );
  }
}
