import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:flutter_hooks/flutter_hooks.dart";
import "package:typewriter_panel/main.dart";
import "package:typewriter_panel/widgets/generic/components/action_shortcuts.dart";
import "package:typewriter_panel/widgets/generic/components/focus_highlight.dart";

typedef KeyEventBlocker = bool Function(BuildContext context, KeyEvent event);

/// Container that unifies focus highlighting, surrounding focus behavior,
/// action shortcuts, and key-event blocking for input-like widgets.
/// Supply the inner input via [child] and its [inputFocusNode].
class InputFieldContainer extends HookWidget {
  const InputFieldContainer({
    required this.inputFocusNode,
    required this.child,
    this.actions,
    this.inputActions,
    this.surroundingActions,
    this.borderRadius,
    this.surroundingFocusNode,
    this.onDismiss,
    this.keyEventBlocker = defaultKeyEventBlocker,
    super.key,
  });

  /// Focus node of the inner input widget.
  final FocusNode inputFocusNode;

  /// The actual input widget to render (e.g. TextField, DropdownMenu).
  final Widget child;

  /// Actions available whenever either surrounding or input has focus.
  final List<ActionShortcut>? actions;

  /// Actions available when the inner input has primary focus.
  final List<ActionShortcut>? inputActions;

  /// Actions available when the surrounding container has primary focus.
  final List<ActionShortcut>? surroundingActions;

  /// Optional border radius for the highlight.
  final BorderRadius? borderRadius;

  /// Optional external surrounding focus node. If null, one will be created.
  final FocusNode? surroundingFocusNode;

  /// Called when a dismiss intent is handled while the input is focused.
  final VoidCallback? onDismiss;

  /// Custom key event blocker. When null, [defaultKeyEventBlocker] is used.
  final KeyEventBlocker? keyEventBlocker;

  /// Default key-event blocker for text-like inputs.
  /// Returns true to block propagation for non-modifier keypresses so that
  /// typing does not trigger global shortcuts. Allows Escape through when
  /// [allowEscapeThrough] is true.
  static bool defaultKeyEventBlocker(
    BuildContext context,
    KeyEvent event,
  ) {
    final hardware = HardwareKeyboard.instance;
    final isControlDown =
        hardware.isLogicalKeyPressed(LogicalKeyboardKey.controlLeft) ||
            hardware.isLogicalKeyPressed(LogicalKeyboardKey.controlRight);
    final isMetaDown =
        hardware.isLogicalKeyPressed(LogicalKeyboardKey.metaLeft) ||
            hardware.isLogicalKeyPressed(LogicalKeyboardKey.metaRight);
    final isAltDown =
        hardware.isLogicalKeyPressed(LogicalKeyboardKey.altLeft) ||
            hardware.isLogicalKeyPressed(LogicalKeyboardKey.altRight);

    return !isControlDown && !isMetaDown && !isAltDown;
  }

  List<ShortcutActivator> get _dismissActivators => shortcutsFor(DismissIntent);

  @override
  Widget build(BuildContext context) {
    final surroundingNode = surroundingFocusNode ??
        useFocusNode(
          debugLabel: "SurroundingInputFieldContainer",
          descendantsAreTraversable: false,
        );

    useListenable(surroundingNode);

    final focusType = useState(FocusType.none);

    final dismiss = useCallback(
      () {
        if (inputFocusNode.hasPrimaryFocus) {
          surroundingNode.requestFocus();
          onDismiss?.call();
        }
      },
      [surroundingNode],
    );

    return FocusHighlight(
      type: focusType.value,
      borderRadius: borderRadius ?? BorderRadius.circular(12),
      child: ManagedActionSet(
        shortcuts: [
          if (surroundingNode.hasPrimaryFocus) ...[
            ActionShortcut(
              id: "focus_input",
              label: "Focus Input",
              description: "Focus the input field",
              activators: [
                const SingleActivator(LogicalKeyboardKey.enter),
                const SingleActivator(LogicalKeyboardKey.space),
              ],
              priority: 100,
            ),
            ...?surroundingActions,
          ],
          if (inputFocusNode.hasPrimaryFocus) ...[
            ActionShortcut(
              id: "dismiss_input",
              label: "Dismiss Input",
              description: "Dismiss the input field",
              activators: [
                const SingleActivator(LogicalKeyboardKey.escape),
              ],
              priority: 100,
            ),
            ...?inputActions,
          ],
          if (surroundingNode.hasFocus) ...?actions,
        ],
        child: Actions(
          actions: {
            ActivateIntent: CallbackAction<ActivateIntent>(
              onInvoke: (intent) {
                if (surroundingNode.hasPrimaryFocus) {
                  inputFocusNode.requestFocus();
                }
                return null;
              },
            ),

            /// Even though we have the onKeyEvent where we pre catch the dismiss intent, If somebody does `Actions.invoke(context, DismissIntent())`
            /// we need to handle it here as well.
            DismissIntent: CallbackAction<DismissIntent>(
              onInvoke: (intent) {
                dismiss();
                return null;
              },
            ),
          },
          child: Focus(
            focusNode: surroundingNode,
            debugLabel: "SurroundingInputFieldContainer",
            descendantsAreTraversable: false,
            onFocusChange: (_) {
              focusType.value = FocusHighlighting.onlyPrimary(surroundingNode);
            },
            onKeyEvent: (node, event) {
              if (!inputFocusNode.hasPrimaryFocus) {
                return KeyEventResult.ignored;
              }

              // We want to force the dismissal of the input field container when the user presses the escape key.
              // Because we don't want it to dismiss something else but this. Like in the case of the dropdown
              // where it dismisses the popup and only then it dismisses the input field container.
              if (_dismissActivators.any(
                (activator) =>
                    // We can't use the activator.accepts method because it requires a `KeyDownEvent` and `event` is only `KeyUpEvent`
                    activator.triggers?.toList().contains(event.logicalKey) ??
                    false,
              )) {
                dismiss();
                return KeyEventResult.handled;
              }

              final shouldBlock = keyEventBlocker!(context, event);
              return shouldBlock
                  ? KeyEventResult.skipRemainingHandlers
                  : KeyEventResult.ignored;
            },
            child: child,
          ),
        ),
      ),
    );
  }
}
