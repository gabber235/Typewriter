import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:flutter_hooks/flutter_hooks.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:typewriter_panel/typewriter_panel.dart";

typedef KeyEventBlocker = bool Function(BuildContext context, KeyEvent event);

class InputFieldController {
  InputFieldController({String? inputDebugLabel, String? surroundingDebugLabel})
    : this._(
        inputFocusNode: FocusNode(debugLabel: inputDebugLabel),
        surroundingFocusNode: FocusNode(
          debugLabel: surroundingDebugLabel ?? "SurroundingInputFieldContainer",
          descendantsAreTraversable: false,
        ),
        ownsInputFocusNode: true,
        ownsSurroundingFocusNode: true,
      );

  InputFieldController.fromInputFocusNode(
    FocusNode inputFocusNode, {
    String? surroundingDebugLabel,
  }) : this._(
         inputFocusNode: inputFocusNode,
         surroundingFocusNode: FocusNode(
           debugLabel:
               surroundingDebugLabel ?? "SurroundingInputFieldContainer",
           descendantsAreTraversable: false,
         ),
         ownsInputFocusNode: false,
         ownsSurroundingFocusNode: true,
       );

  InputFieldController._({
    required this.inputFocusNode,
    required this.surroundingFocusNode,
    required bool ownsInputFocusNode,
    required bool ownsSurroundingFocusNode,
  }) : _ownsInputFocusNode = ownsInputFocusNode,
       _ownsSurroundingFocusNode = ownsSurroundingFocusNode;

  /// Focus node of the inner input widget.
  final FocusNode inputFocusNode;

  /// Focus node of the surrounding input container.
  final FocusNode surroundingFocusNode;

  VoidCallback? _endInteraction;
  VoidCallback? _beginInteraction;

  final bool _ownsInputFocusNode;
  final bool _ownsSurroundingFocusNode;

  void requestInputFocus() => inputFocusNode.requestFocus();

  void requestSurroundingFocus() => surroundingFocusNode.requestFocus();

  void beginInteraction() => _beginInteraction?.call();

  void endInteraction() => _endInteraction?.call();

  void dispose() {
    if (_ownsInputFocusNode) inputFocusNode.dispose();
    if (_ownsSurroundingFocusNode) surroundingFocusNode.dispose();
  }
}

/// Container that unifies focus highlighting, surrounding focus behavior,
/// action shortcuts, and key-event blocking for input-like widgets.
/// Supply the inner input via [child] and its [controller].
class InputFieldContainer extends HookConsumerWidget {
  const InputFieldContainer({
    required this.controller,
    required this.child,
    this.actions,
    this.inputActions,
    this.surroundingActions,
    this.borderRadius,
    this.onInputFocus,
    this.onDismiss,
    this.onCancel,
    this.autofocus = false,
    super.key,
  });

  /// Controller that owns the input and surrounding focus nodes.
  final InputFieldController controller;

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

  /// Called when the input is focused.
  final VoidCallback? onInputFocus;

  /// Called when a dismiss intent is handled while the input is focused.
  /// Dismissing leaves the field but keeps what was typed.
  final VoidCallback? onDismiss;

  /// Called when a cancel intent is handled while the input is focused.
  /// Cancelling leaves the field and discards what was typed.
  final VoidCallback? onCancel;

  /// Whether the surrounding focus should request focus automatically.
  final bool autofocus;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final inputFocusNode = controller.inputFocusNode;
    final surroundingNode = controller.surroundingFocusNode;

    useListenable(surroundingNode);
    useListenable(inputFocusNode);

    final focusType = useState(FocusType.none);
    final id = useMemoized(() => uuid.v4());
    final modeCoordinator = ref.read(inputFieldModeCoordinatorProvider);

    useEffect(() {
      void beginInteraction() {
        modeCoordinator.begin(id);
      }

      void endInteraction() {
        modeCoordinator.end(id);
      }

      final unregister = modeCoordinator.register(
        id: id,
        inputFocusNode: inputFocusNode,
        surroundingFocusNode: surroundingNode,
        onInputFocus: onInputFocus,
      );
      controller._beginInteraction = beginInteraction;
      controller._endInteraction = endInteraction;

      return () {
        if (controller._beginInteraction == beginInteraction) {
          controller._beginInteraction = null;
        }
        if (controller._endInteraction == endInteraction) {
          controller._endInteraction = null;
        }
        unregister();
      };
    }, [controller, id, modeCoordinator, onInputFocus]);

    return FocusHighlight(
      type: focusType.value,
      borderRadius: borderRadius ?? context.shapes.largeBorderRadius,
      child: Actions(
        actions: {
          ActivateIntent: CallbackAction<ActivateIntent>(
            onInvoke: (intent) {
              if (surroundingNode.hasPrimaryFocus) {
                modeCoordinator.begin(id);
              }
              return null;
            },
          ),
        },
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
              ...?actions,
            ],
          ],
          child: Focus(
            focusNode: surroundingNode,
            autofocus: autofocus,
            debugLabel: "SurroundingInputFieldContainer",
            descendantsAreTraversable: false,
            onFocusChange: (_) {
              focusType.value = FocusHighlighting.onlyPrimary(surroundingNode);
            },
            child: Actions(
              actions: {
                if (inputFocusNode.hasPrimaryFocus) ...{
                  DismissIntent: CallbackAction<DismissIntent>(
                    onInvoke: (intent) {
                      onDismiss?.call();
                      modeCoordinator.end(id);
                      return null;
                    },
                  ),
                  CancelIntent: CallbackAction<CancelIntent>(
                    onInvoke: (intent) {
                      onCancel?.call();
                      modeCoordinator.end(id);
                      return null;
                    },
                  ),
                },
              },
              child: ManagedActionSet(
                shortcuts: [
                  if (inputFocusNode.hasPrimaryFocus) ...[
                    ...?inputActions,
                    ...?actions,
                  ],
                ],
                child: child,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
