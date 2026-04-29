import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:flutter_hooks/flutter_hooks.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:typewriter_panel/logic/interaction_mode/current_interaction_mode.dart";
import "package:typewriter_panel/logic/interaction_mode/modes/insert_mode.dart";
import "package:typewriter_panel/main.dart";
import "package:typewriter_panel/widgets/app/components/action_shortcuts.dart";
import "package:typewriter_panel/widgets/generic/components/focus_highlight.dart";

typedef KeyEventBlocker = bool Function(BuildContext context, KeyEvent event);

/// Container that unifies focus highlighting, surrounding focus behavior,
/// action shortcuts, and key-event blocking for input-like widgets.
/// Supply the inner input via [child] and its [inputFocusNode].
class InputFieldContainer extends HookConsumerWidget {
  const InputFieldContainer({
    required this.inputFocusNode,
    required this.child,
    this.actions,
    this.inputActions,
    this.surroundingActions,
    this.borderRadius,
    this.surroundingFocusNode,
    this.onInputFocus,
    this.onDismiss,
    this.autofocus = false,
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

  /// Called when the input is focused.
  final VoidCallback? onInputFocus;

  /// Called when a dismiss intent is handled while the input is focused.
  final VoidCallback? onDismiss;

  /// Whether the surrounding focus should request focus automatically.
  final bool autofocus;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final surroundingNode =
        surroundingFocusNode ??
        useFocusNode(
          debugLabel: "SurroundingInputFieldContainer",
          descendantsAreTraversable: false,
        );

    useListenable(surroundingNode);
    useListenable(inputFocusNode);

    final focusType = useState(FocusType.none);

    final id = useMemoized(() => uuid.v4());
    final currentMode = ref.watch(currentInteractionModeProvider);

    useEffect(() {
      if (currentMode is InsertMode && surroundingNode.hasPrimaryFocus) {
        if (currentMode.id != id) {
          ref
              .read(currentInteractionModeProvider.notifier)
              .setMode(InsertMode(id));
        }
        inputFocusNode.requestFocus();
      }

      if (currentMode is! InsertMode && inputFocusNode.hasPrimaryFocus) {
        surroundingNode.requestFocus();
      }
      return null;
    }, [currentMode]);

    useEffect(() {
      if (inputFocusNode.hasPrimaryFocus) onInputFocus?.call();
      return null;
    }, [inputFocusNode.hasPrimaryFocus]);

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
          if (inputFocusNode.hasPrimaryFocus) ...[...?inputActions],
          if (surroundingNode.hasFocus) ...?actions,
        ],
        child: Actions(
          actions: {
            ActivateIntent: CallbackAction<ActivateIntent>(
              onInvoke: (intent) {
                if (surroundingNode.hasPrimaryFocus) {
                  ref
                      .read(currentInteractionModeProvider.notifier)
                      .setMode(InsertMode(id));
                }
                return null;
              },
            ),
          },
          child: Focus(
            focusNode: surroundingNode,
            autofocus: autofocus,
            debugLabel: "SurroundingInputFieldContainer",
            descendantsAreTraversable: false,
            onFocusChange: (_) {
              focusType.value = FocusHighlighting.onlyPrimary(surroundingNode);

              if (inputFocusNode.hasPrimaryFocus &&
                  currentMode is! InsertMode) {
                ref
                    .read(currentInteractionModeProvider.notifier)
                    .setMode(InsertMode(id));
              }

              if (currentMode is InsertMode &&
                  currentMode.id == id &&
                  !inputFocusNode.hasFocus) {
                ref.read(currentInteractionModeProvider.notifier).normal();
              }
            },
            child: Actions(
              actions: {
                if (inputFocusNode.hasPrimaryFocus)
                  DismissIntent: CallbackAction<DismissIntent>(
                    onInvoke: (intent) {
                      ref
                          .read(currentInteractionModeProvider.notifier)
                          .normal();
                      return null;
                    },
                  ),
              },
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}
