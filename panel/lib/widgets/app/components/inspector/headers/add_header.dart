import "package:flutter/material.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:iconify_flutter_plus/icons/fa6_solid.dart";
import "package:typewriter_panel/utils/string.dart";
import "package:typewriter_panel/widgets/app/components/inspector/editors.dart";
import "package:typewriter_panel/widgets/app/components/inspector/header.dart";
import "package:typewriter_panel/widgets/generic/components/icones.dart";

class AddHeaderAction extends HookConsumerWidget {
  const AddHeaderAction({
    required this.path,
    required this.onAdd,
    super.key,
  }) : super();

  final String path;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return IconButton(
      icon: const Icones(Fa6Solid.plus),
      tooltip: "Add new ${ref.watch(pathDisplayNameProvider(path)).singular}",
      iconSize: 16,
      onPressed: () {
        onAdd();
        // If we add a new item, we probably want to edit it.
        Header.maybeOf(context)?.expanded.value = true;
      },
    );
  }
}
