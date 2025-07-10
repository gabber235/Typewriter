import "package:flutter/material.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:typewriter_panel/logic/selectable/selectable.dart";
import "package:typewriter_panel/logic/selectable/selection.dart";

class Selector extends HookConsumerWidget {
  const Selector({
    required this.selectableId,
    required this.builder,
    super.key,
  });

  final SelectableIdentifier selectableId;
  // ignore: avoid_positional_boolean_parameters
  final Widget Function(bool isSelected) builder;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isSelected = ref.watch(isSelectedProvider(selectableId));

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () {
          ref.read(selectionProvider.notifier).select(selectableId);
        },
        child: builder(isSelected),
      ),
    );
  }
}
