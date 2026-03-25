import "package:flutter/material.dart";
import "package:flutter_animate/flutter_animate.dart";
import "package:flutter_hooks/flutter_hooks.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:typewriter_panel/hooks/focused_change.dart";
import "package:typewriter_panel/hooks/menu_controller.dart";
import "package:typewriter_panel/logic/selectable/selectable.dart";
import "package:typewriter_panel/logic/selectable/selection.dart";
import "package:typewriter_panel/utils/animation.dart";
import "package:typewriter_panel/widgets/app/components/inspector/operations.dart";
import "package:typewriter_panel/widgets/generic/components/context_menu.dart";
import "package:typewriter_panel/widgets/generic/components/pixel_scale_transition.dart";

/// Provides SelectableIdentifier to descendants and exposes primary focus lookup.
class SelectableScope extends InheritedWidget {
  const SelectableScope({required this.id, required super.child, super.key});

  final SelectableIdentifier id;

  static SelectableIdentifier? maybeOf(BuildContext? context) {
    if (context == null) return null;
    final element = context
        .getElementForInheritedWidgetOfExactType<SelectableScope>();
    final scope = element?.widget as SelectableScope?;
    return scope?.id;
  }

  /// Returns the SelectableIdentifier for FocusManager.primaryFocus, if any.
  static SelectableIdentifier? primaryFocusedId() {
    final node = FocusManager.instance.primaryFocus;
    return maybeOf(node?.context);
  }

  @override
  bool updateShouldNotify(SelectableScope oldWidget) => id != oldWidget.id;
}

class Selector extends HookConsumerWidget {
  const Selector({
    required this.selectableId,
    required this.builder,
    required this.focusNode,
    this.onFocusChange,
    this.onDoubleTap,
    super.key,
  });

  final SelectableIdentifier selectableId;
  // ignore: avoid_positional_boolean_parameters
  final Widget Function(bool isSelected, bool isFocused, bool isHovered)
  builder;

  /// {@macro flutter.widgets.Focus.focusNode}
  final FocusNode focusNode;

  /// A function that will be called when the focus changes.
  ///
  /// Called with true if the [focusNode] has primary focus.
  final ValueChanged<bool>? onFocusChange;

  final VoidCallback? onDoubleTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isSelected = ref.watch(isSelectedProvider(selectableId));
    final isFocused = useState(false);
    final isHovered = useState(false);
    final controller = useMenuController();

    final operations = ref.watch(availableOperationsProvider);

    useFocusedChange(focusNode, ({required hasFocus}) {
      isFocused.value = hasFocus;
      onFocusChange?.call(hasFocus);
      return null;
    }, [focusNode, onFocusChange]);

    final focusAnimation = useAnimationController(
      duration: 200.ms,
      initialValue: 0.0,
    );

    useEffect(() {
      if (!isFocused.value) return null;
      if (focusAnimation.isAnimating) return null;
      focusAnimation.forward(from: 0.0);
      return null;
    }, [isFocused.value]);

    return KeyedSubtree(
      key: Key(selectableId.id),
      child: ContextMenuRegion(
        childFocusNode: focusNode,
        items: [
          if (operations.isNotEmpty)
            MenuItem.section(
              label: "Operations",
              items: [
                for (final operation in operations) operation.menuItem(ref),
              ],
            ),
        ],
        enableGestures: false,
        controller: controller,
        child: GestureDetector(
          onSecondaryTapUp: ContextMenuRegion.onSecondaryTapUp(controller),
          onLongPressStart: ContextMenuRegion.onLongPressStart(controller),
          onDoubleTap: onDoubleTap,
          onTapUp: ContextMenuRegion.onTapUp(
            controller,
            orElse: (_) {
              Actions.maybeInvoke(
                context,
                SelectedSelectorIntent(
                  selectableId: selectableId,
                  focusNode: focusNode,
                  throughTap: true,
                  throughActivateIntent: false,
                ),
              );
              ref.read(selectionProvider.notifier).select(selectableId);
              focusNode.requestFocus();
            },
          ),
          child: SelectableScope(
            id: selectableId,
            child: FocusableActionDetector(
              focusNode: focusNode,
              onShowHoverHighlight: (hover) => isHovered.value = hover,
              mouseCursor: SystemMouseCursors.click,
              actions: {
                ActivateIntent: CallbackAction(
                  onInvoke: (_) {
                    Actions.maybeInvoke(
                      context,
                      SelectedSelectorIntent(
                        selectableId: selectableId,
                        focusNode: focusNode,
                        throughTap: false,
                        throughActivateIntent: true,
                      ),
                    );
                    return ref
                        .read(selectionProvider.notifier)
                        .select(selectableId);
                  },
                ),
              },
              child: PixelScaleTransition(
                pixelScale: TweenSequence<double>([
                  TweenSequenceItem<double>(
                    tween: Tween<double>(
                      begin: 0,
                      end: 15,
                    ).curved(Curves.easeInOutCubicEmphasized),
                    weight: .5,
                  ),
                  TweenSequenceItem<double>(
                    tween: Tween<double>(
                      begin: 15,
                      end: 0,
                    ).curved(Curves.easeInOut),
                    weight: .5,
                  ),
                ]).animate(focusAnimation),
                child: HookBuilder(
                  builder: (context) {
                    return builder(
                      isSelected,
                      isFocused.value,
                      isHovered.value,
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class SelectedSelectorIntent extends Intent {
  const SelectedSelectorIntent({
    required this.selectableId,
    required this.focusNode,
    required this.throughTap,
    required this.throughActivateIntent,
  });

  final SelectableIdentifier selectableId;
  final FocusNode focusNode;

  final bool throughTap;
  final bool throughActivateIntent;
}
