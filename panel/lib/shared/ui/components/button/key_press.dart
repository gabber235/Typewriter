import "package:typewriter_panel/typewriter_panel.dart";

/// The key half of the one press lifecycle every control follows: Space or
/// Enter down presses, key up acts, and Escape, focus leaving or the control
/// turning unavailable cancels.
///
/// With [onPress], the caller follows each step and acts on
/// [PressStep.release] itself, as [Button] does. Without it, a key press
/// starts only on a focused control with an enabled [ActivateIntent], and its
/// release invokes that intent there, so a check, a row or a form toggle acts
/// on key up instead of on key down. A key with a modifier held belongs to a
/// shortcut, such as Shift+Space adding to a selection, and passes through.
class KeyPress extends HookWidget {
  const KeyPress({
    required this.child,
    this.onPress,
    this.enabled = true,
    super.key,
  });

  /// Follows every key press: [PressStep.start] on key down, then
  /// [PressStep.release] on key up or [PressStep.cancel].
  final void Function(PressStep step)? onPress;

  /// Whether the control takes key presses now. Turning false cancels a
  /// press held at the time.
  final bool enabled;
  final Widget child;

  static bool _activates(LogicalKeyboardKey key) =>
      key == LogicalKeyboardKey.space ||
      key == LogicalKeyboardKey.enter ||
      key == LogicalKeyboardKey.numpadEnter;

  @override
  Widget build(BuildContext context) {
    // The focus the held press started on; null while no key presses.
    final pressing = useRef<FocusNode?>(null);

    void ends(PressStep step) {
      final from = pressing.value;
      if (from == null) return;
      pressing.value = null;
      // A key let go on another focus than it pressed cancels.
      final outcome = from == FocusManager.instance.primaryFocus
          ? step
          : PressStep.cancel;
      if (onPress case final follow?) {
        follow(outcome);
      } else if (outcome == PressStep.release && from.context != null) {
        Actions.maybeInvoke(from.context!, const ActivateIntent());
      }
    }

    useEffect(() {
      if (!enabled) ends(PressStep.cancel);
      return null;
    }, [enabled]);

    bool canStart(FocusNode? focus) {
      if (onPress != null) return true;
      final at = focus?.context;
      if (at == null) return false;
      const intent = ActivateIntent();
      // Typed as Intent: a CallbackAction<Intent> registered for
      // ActivateIntent cannot be found as an Action<ActivateIntent>.
      final action = Actions.maybeFind<Intent>(at, intent: intent);
      return action != null && action.isEnabled(intent);
    }

    KeyEventResult keys(FocusNode node, KeyEvent event) {
      final key = event.logicalKey;
      if (key == LogicalKeyboardKey.escape && pressing.value != null) {
        if (event is KeyDownEvent) ends(PressStep.cancel);
        return KeyEventResult.handled;
      }
      if (!_activates(key) || !enabled) return KeyEventResult.ignored;
      final keyboard = HardwareKeyboard.instance;
      final modified =
          keyboard.isControlPressed ||
          keyboard.isMetaPressed ||
          keyboard.isAltPressed ||
          keyboard.isShiftPressed;
      switch (event) {
        case KeyDownEvent() when modified:
          return KeyEventResult.ignored;
        case KeyDownEvent() when pressing.value == null:
          final focus = FocusManager.instance.primaryFocus;
          if (!canStart(focus)) return KeyEventResult.ignored;
          pressing.value = focus;
          onPress?.call(PressStep.start);
        case KeyUpEvent() when pressing.value != null:
          ends(PressStep.release);
        case _ when pressing.value == null && onPress == null:
          // Another control's key, or one this control never pressed.
          return KeyEventResult.ignored;
        case _:
      }
      return KeyEventResult.handled;
    }

    return Focus(
      canRequestFocus: false,
      skipTraversal: true,
      onKeyEvent: keys,
      // A key press ends when focus leaves, since its key up goes elsewhere.
      onFocusChange: (on) {
        if (!on) ends(PressStep.cancel);
      },
      child: child,
    );
  }
}

/// Wrapping a control in a [KeyPress].
extension KeyPressedWidget on Widget {
  /// This control, acting when Space or Enter is let go instead of on key
  /// down: its focused part's [ActivateIntent] runs on key up.
  Widget get pressedByKeys => KeyPress(child: this);
}
