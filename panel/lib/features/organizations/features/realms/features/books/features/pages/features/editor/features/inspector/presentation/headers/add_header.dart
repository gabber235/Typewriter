import "package:flutter/material.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:iconify_flutter_plus/icons/fa6_solid.dart";
import "package:typewriter_panel/typewriter_panel.dart";

class AddHeaderAction extends HookConsumerWidget {
  const AddHeaderAction({required this.path, required this.onAdd, super.key})
    : super();

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
