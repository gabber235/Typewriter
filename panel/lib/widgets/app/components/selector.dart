import "package:flutter/material.dart";
import "package:flutter_hooks/flutter_hooks.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:typewriter_panel/logic/selectable/selectable.dart";
import "package:typewriter_panel/logic/selectable/selection.dart";

class Selector extends HookConsumerWidget {
  const Selector({
    required this.selectableId,
    required this.builder,
    this.focusNode,
    this.onFocusChange,
    super.key,
  });

  final SelectableIdentifier selectableId;
  // ignore: avoid_positional_boolean_parameters
  final Widget Function(bool isSelected, bool isFocused, bool isHovered)
      builder;

  /// {@macro flutter.widgets.Focus.focusNode}
  final FocusNode? focusNode;

  /// A function that will be called when the focus changes.
  ///
  /// Called with true if the [focusNode] has primary focus.
  final ValueChanged<bool>? onFocusChange;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isSelected = ref.watch(isSelectedProvider(selectableId));
    final isFocused = useState(false);
    final isHovered = useState(false);

    return GestureDetector(
      onTap: () {
        ref.read(selectionProvider.notifier).select(selectableId);
        focusNode?.requestFocus();
      },
      child: FocusableActionDetector(
        focusNode: focusNode,
        onShowFocusHighlight: (focus) => isFocused.value = focus,
        onShowHoverHighlight: (hover) => isHovered.value = hover,
        onFocusChange: onFocusChange,
        mouseCursor: SystemMouseCursors.click,
        actions: {
          ActivateIntent: CallbackAction(
            onInvoke: (_) => ref.read(selectionProvider.notifier).select(
                  selectableId,
                ),
          ),
        },
        child: builder(isSelected, isFocused.value, isHovered.value),
      ),
    );
  }
}
