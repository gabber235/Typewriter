import "package:flutter/material.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:typewriter/l10n/l10n_provider.dart";
import "package:typewriter/utils/extensions.dart";
import "package:typewriter/utils/icons.dart";
import "package:typewriter/utils/popups.dart";
import "package:typewriter/widgets/components/general/iconify.dart";
import "package:typewriter/widgets/inspector/editors.dart";

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
    final l10n = ref.watch(l10nProvider);
    final name = ref.watch(pathDisplayNameProvider(path)).singular;
    return IconButton(
      icon: const Iconify(TWIcons.trash, size: 12),
      color: Theme.of(context).colorScheme.error,
      tooltip: l10n.deleteThis(name),
      onPressed: () => showConfirmationDialogue(
        context: context,
        title: l10n.deleteThis(name),
        content: l10n.areYouSure,
        onConfirm: onRemove,
      ),
    );
  }
}
