import "package:flutter/material.dart";
import "package:flutter_animate/flutter_animate.dart";
import "package:flutter_hooks/flutter_hooks.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:typewriter_panel/typewriter_panel.dart";

/// Associates a widget subtree with its selectable identifier.
///
/// The scope is a focus lookup boundary, not selection state. It lets graph
/// navigation and other consumers map Flutter's primary focus back to an item
/// without making focus imply that the item is selected.
class SelectableScope extends InheritedWidget {
  const SelectableScope({required this.id, required super.child, super.key});

  final SelectableIdentifier id;

  static SelectableIdentifier? maybeOf(BuildContext? context) {
    if (context == null) return null;
    final scope = context.getInheritedWidgetOfExactType<SelectableScope>();
    return scope?.id;
  }

  /// Returns the identifier under Flutter's primary focus, if any.
  ///
  /// This reads the focused node's build context. It returns null when focus
  /// is outside a [SelectableScope].
  static SelectableIdentifier? primaryFocusedId() {
    final node = FocusManager.instance.primaryFocus;
    return maybeOf(node?.context);
  }

  @override
  bool updateShouldNotify(SelectableScope oldWidget) => id != oldWidget.id;
}

/// Combines selection gestures, focus handling, context actions, and item UI.
///
/// [selectableId] participates in provider selection. [focusNode] tracks
/// keyboard focus independently, and [builder] receives both states so callers
/// can render their distinction. Activation dispatches the shared selector
/// intent before updating the canonical selection.
class Selector extends HookConsumerWidget {
  const Selector({
    required this.selectableId,
    required this.builder,
    required this.focusNode,
    this.onFocusChange,
    this.onDoubleTap,
    super.key,
  });

  /// Identifier changed by taps and keyboard activation.
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

  /// Optional callback for a double tap without changing selection semantics.
  final VoidCallback? onDoubleTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isSelected = ref.watch(isSelectedProvider(selectableId));
    final isFocused = useState(false);
    final isHovered = useState(false);
    final controller = useMenuController();
    final anchorKey = useGlobalKey();
    final pendingContextPosition = useState<Offset?>(null);
    final selection = ref.watch(selectionProvider);
    final selected = ref.watch(selectedProvider);

    final registeredOperations = SelectionOperationsRoot.of(context);
    final operations = availableSelectionOperations(
      registeredOperations,
      selected.value,
    );

    useFocusedChange(focusNode, ({required hasFocus}) {
      isFocused.value = hasFocus;
      if (!hasFocus) pendingContextPosition.value = null;
      onFocusChange?.call(hasFocus);
      return null;
    }, [focusNode, onFocusChange]);

    void activateContext(Offset globalPosition) {
      if (!ref.read(selectionProvider).contains(selectableId)) {
        ref.read(selectionProvider.notifier).selectAll([selectableId]);
      }
      focusNode.requestFocus();
      pendingContextPosition.value = globalPosition;
    }

    useEffect(
      () {
        final position = pendingContextPosition.value;
        if (position == null) return null;
        var active = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!active || !context.mounted) return;
          if (!ref.read(selectionProvider).contains(selectableId) ||
              !focusNode.hasFocus) {
            pendingContextPosition.value = null;
            return;
          }
          if (selected.isLoading) return;
          pendingContextPosition.value = null;
          if (selected.hasError || operations.isEmpty) return;
          final anchor = anchorKey.currentContext?.findRenderObject();
          if (anchor is! RenderBox || !anchor.attached) return;
          controller.open(position: anchor.globalToLocal(position));
        });
        return () => active = false;
      },
      [pendingContextPosition.value, selection, selected, registeredOperations],
    );

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
        key: anchorKey,
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
          onSecondaryTapUp: (details) =>
              activateContext(details.globalPosition),
          onLongPressStart: (details) =>
              activateContext(details.globalPosition),
          onDoubleTap: onDoubleTap,
          onTapUp: ContextMenuRegion.onTapUp(
            controller,
            onContextTap: (details) => activateContext(details.globalPosition),
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
                ActivateAllIntent: CallbackAction(
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
                        .select(selectableId, isMultiSelect: true);
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

/// Describes how a selector activation entered the shared action pipeline.
class SelectedSelectorIntent extends Intent {
  const SelectedSelectorIntent({
    required this.selectableId,
    required this.focusNode,
    required this.throughTap,
    required this.throughActivateIntent,
  });

  final SelectableIdentifier selectableId;
  final FocusNode focusNode;

  /// Whether the activation originated from a pointer tap.
  final bool throughTap;

  /// Whether the activation originated from Flutter's activate intent.
  final bool throughActivateIntent;
}
