import "package:typewriter_panel/typewriter_panel.dart";

/// How a button paints its face. One filled button per pane at most.
enum ButtonFace {
  /// No fill until hovered or pressed: most actions.
  quiet,

  /// Brand fill: the pane's main action.
  filled,

  /// A soft fill of its colour: a secondary action that must stand out.
  outlined,

  /// An icon alone, round.
  icon,

  /// A large filled action floating over content at the lower right. Its
  /// caller places it, with a [Positioned] in a [Stack].
  floating,

  /// No face: a row, card or chip that paints its own content and is
  /// activated as a whole. It rises; it never tints, since a row fill means
  /// selected.
  bare;

  /// The outline this face fills, tints and flashes.
  ShapeBorder shapeIn(BuildContext context) => switch (this) {
    ButtonFace.icon => const CircleBorder(),
    ButtonFace.floating => context.shapes.largeShape,
    _ => context.shapes.mediumShape,
  };
}

/// The one button of the panel, built on the widgets layer.
///
/// It rises on hover with `hoverIn` and `hoverOut`, sinks with `press` while
/// pressed by pointer or key, stays pressed in while busy or unavailable,
/// types and ripples its [busyLabel] while an async [onPressed] runs, and
/// jams once per failure. Under reduced motion nothing travels: a faced
/// button tints its fill on hover and darkens it while pressed.
class Button extends HookWidget {
  const Button({
    required this.label,
    required this.onPressed,
    this.face = ButtonFace.quiet,
    this.icon,
    this.busyLabel,
    this.doneLabel,
    this.tooltip,
    this.hint,
    this.color,
    this.focusNode,
    this.autofocus = false,
    this.controller,
    this.statesController,
    this.child,
    this.dense = false,
    this.onKeyPressStart,
    super.key,
  });

  /// What the button does, read aloud and shown unless [child] or the icon
  /// face replaces it: Publish. A bare button whose content already names
  /// it passes an empty label, so the name is not read twice; its content's
  /// own semantics then say what it is, and it is not read as a button.
  final String label;

  /// The word it types while an async [onPressed] runs: Publishing. A button
  /// without one has a synchronous action or shows only an icon.
  final String? busyLabel;

  /// The word it types once [onPressed] finished, such as Copied; it stays
  /// long enough to read, then the label returns. Feedback stays at the
  /// button instead of a toast.
  final String? doneLabel;

  /// Sync or async. While a returned Future runs the button is busy and
  /// refuses another press; an Exception jams it and is reported. Null makes
  /// the button unavailable.
  final FutureOr<void> Function()? onPressed;

  /// Runs when Space or Enter goes down on the focused button, before
  /// [onPressed] runs on key up; a hold starts here.
  final VoidCallback? onKeyPressStart;
  final ButtonFace face;
  final Widget? icon;
  final String? tooltip;

  /// Read after the label, for what its colour alone says: Destructive.
  final String? hint;

  /// Overrides the face colour: danger for Decline, an identity colour.
  final Color? color;
  final FocusNode? focusNode;
  final bool autofocus;

  /// Run state owned elsewhere; its owner binds it, and [onPressed] asks
  /// the owner for a run. The button owns and binds one otherwise.
  final ButtonController? controller;

  /// Receives the hovered, pressed and focused states, for a caller that
  /// publishes them; the button owns one otherwise.
  final WidgetStatesController? statesController;

  /// Content for the bare face, or content another face paints in place of
  /// its icon and label, as an app bar control does. A bare button with no
  /// action shows this content alone.
  final Widget? child;

  /// A compact face, 8 px smaller each way, for authored compact density.
  final bool dense;

  @override
  Widget build(BuildContext context) {
    assert(
      face != ButtonFace.bare || child != null,
      "A bare button needs a child to show.",
    );
    final owned = useButtonController();
    // A supplied controller is owned elsewhere (CommandRuns for a command):
    // its owner binds and runs it, and this button only reads its state.
    final bound = controller != null;
    final run = controller ?? owned;
    useListenable(run);
    // A finished run shows the done word until it has been read; a run by a
    // shortcut that shares this controller shows it too.
    final done = useState(false);
    final successes = run.successes;
    final seen = useRef(successes);
    useEffect(() {
      if (successes == seen.value) return null;
      seen.value = successes;
      if (doneLabel == null) return null;
      done.value = true;
      final timer = Timer(_doneReadTimeout, () => done.value = false);
      return timer.cancel;
    }, [successes]);
    useEffect(() {
      if (bound) return null;
      owned.bind(
        onPressed: onPressed,
        onError: (error) {
          final press = onPressed;
          if (!context.mounted) return;
          context.reportFailure(
            "$label failed",
            detail: error,
            retry: press == null ? null : () async => press(),
          );
        },
      );
      return null;
    }, [bound, owned, onPressed]);

    final ownedStates = useMemoized(WidgetStatesController.new);
    useEffect(() => ownedStates.dispose, [ownedStates]);
    final states = statesController ?? ownedStates;
    final current = useValueListenable(states);

    final busy = run.isLoading;
    final enabled = bound ? onPressed != null && !busy : run.canTrigger;
    final unavailable = !enabled && !busy;
    // A press held while the button stops taking presses ends with it.
    useEffect(() {
      if (!enabled) states.update(WidgetState.pressed, false);
      return null;
    }, [enabled]);
    final pressed =
        busy || unavailable || current.contains(WidgetState.pressed);
    final hovered = !pressed && current.contains(WidgetState.hovered);

    void activate() {
      if (!enabled) return;
      if (bound) {
        onPressed!();
      } else {
        run.handlePress();
      }
    }

    // The press splash grows from the press point while held and drains
    // when the press ends, whether it acted or was cancelled.
    final splash = resolveMotion(context, MotionToken.splash);
    final drainMotion = resolveMotion(context, MotionToken.panelOut);
    final grow = useMotionController();
    final drain = useMotionController(initial: 1);
    final inkAt = useRef(Offset.zero);
    void splashFrom(Offset at) {
      if (!splash.travels || face == ButtonFace.bare) return;
      inkAt.value = at;
      drain.jumpTo(0);
      grow
        ..jumpTo(0)
        ..to(1, splash);
    }

    void splashEnds() => drain.to(1, drainMotion);

    // Keys: Space or Enter down presses and splashes from the middle; key up
    // acts; Escape while held cancels. With a modifier held the key belongs
    // to a shortcut, such as Ctrl+Enter publishing.
    final keyHeld = useRef(false);
    KeyEventResult keys(FocusNode node, KeyEvent event) {
      final key = event.logicalKey;
      final activator =
          key == LogicalKeyboardKey.space ||
          key == LogicalKeyboardKey.enter ||
          key == LogicalKeyboardKey.numpadEnter;
      if (key == LogicalKeyboardKey.escape && keyHeld.value) {
        if (event is KeyDownEvent) {
          keyHeld.value = false;
          states.update(WidgetState.pressed, false);
          splashEnds();
        }
        return KeyEventResult.handled;
      }
      if (!activator || !enabled) return KeyEventResult.ignored;
      final keyboard = HardwareKeyboard.instance;
      final modified =
          keyboard.isControlPressed ||
          keyboard.isMetaPressed ||
          keyboard.isAltPressed ||
          keyboard.isShiftPressed;
      switch (event) {
        case KeyDownEvent() when modified:
          return KeyEventResult.ignored;
        case KeyDownEvent():
          keyHeld.value = true;
          onKeyPressStart?.call();
          states.update(WidgetState.pressed, true);
          final box = context.findRenderObject();
          splashFrom(
            box is RenderBox ? box.size.center(Offset.zero) : Offset.zero,
          );
        case KeyUpEvent() when keyHeld.value:
          keyHeld.value = false;
          states.update(WidgetState.pressed, false);
          splashEnds();
          activate();
        case _:
      }
      return KeyEventResult.handled;
    }

    final press = resolveMotion(context, MotionToken.press);
    final sink = useMotion(MotionToken.press, pressed ? 1 : 0);
    final landing = press.landing;
    final shape = face.shapeIn(context);

    // Reduced motion: press is still and nothing travels; a faced button
    // tints its own fill on hover and darkens it while pressed. A bare row
    // shows nothing, since a row fill means selected.
    final tint =
        press.travels || face == ButtonFace.bare || !(pressed || hovered)
        ? context.colors.clear
        : context.colors.contentPrimary.withValues(
            alpha: pressed
                ? context.stateTokens.pressedOpacity
                : context.stateTokens.hoverOpacity,
          );

    // The tint changes with the move the engine's table picks for this state
    // change (pressed: press, hovered: hoverIn or hoverOut).
    final tintMotion = useStateMotion({
      if (hovered) WidgetState.hovered,
      if (pressed) WidgetState.pressed,
      if (current.contains(WidgetState.focused)) WidgetState.focused,
      if (unavailable) WidgetState.disabled,
    }, target: tint);
    final shownTint = useMotionValue(
      tintMotion,
      tint,
      lerp: (a, b, t) => Color.lerp(a, b, t)!,
    );

    final kept = useMemoized(GlobalKey.new);
    final shownLabel = switch (doneLabel) {
      _ when busy && busyLabel != null => busyLabel!,
      final word? when done.value => word,
      _ => label,
    };
    final content = face == ButtonFace.bare
        ? child!
        : ButtonContent(
            face: face,
            dense: dense,
            color: color,
            unavailable: unavailable,
            ink: PressInk(
              center: inkAt.value,
              color: switch (face) {
                // The label colour on a strong fill, the accent on a soft
                // or clear one.
                ButtonFace.filled || ButtonFace.floating =>
                  (color ?? context.colors.brand)
                      .on(context)
                      .withValues(
                        alpha: context.stateTokens.splashOnFillOpacity,
                      ),
                _ => (color ?? context.colors.brand).withValues(
                  alpha: context.stateTokens.splashOpacity,
                ),
              },
              grow: grow,
              drain: drain,
            ),
            content: child,
            icon: icon == null
                ? null
                : RippleGlyph(
                    rippling:
                        busy && (busyLabel == null || face == ButtonFace.icon),
                    child: icon!,
                  ),
            // An icon button speaks only its done word, beside the icon.
            label: switch (face) {
              ButtonFace.icon when done.value && doneLabel != null =>
                MotionLabel(doneLabel!),
              ButtonFace.icon => null,
              _ => MotionLabel(shownLabel, rippling: busy),
            },
          );

    Widget result = Focus(
      canRequestFocus: false,
      skipTraversal: true,
      onKeyEvent: keys,
      child: FocusableActionDetector(
        focusNode: focusNode,
        autofocus: autofocus,
        mouseCursor: enabled
            ? SystemMouseCursors.click
            : SystemMouseCursors.basic,
        onFocusChange: (on) => states.update(WidgetState.focused, on),
        actions: {
          ActivateIntent: CallbackAction<ActivateIntent>(
            onInvoke: (_) => activate(),
          ),
          ButtonActivateIntent: CallbackAction<ButtonActivateIntent>(
            onInvoke: (_) => activate(),
          ),
        },
        child: MouseRegion(
          onEnter: (_) => states.update(WidgetState.hovered, true),
          onExit: (_) => states.update(WidgetState.hovered, false),
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            excludeFromSemantics: true,
            onTapDown: enabled
                ? (details) {
                    states.update(WidgetState.pressed, true);
                    splashFrom(details.localPosition);
                  }
                : null,
            onTapCancel: enabled
                ? () {
                    states.update(WidgetState.pressed, false);
                    splashEnds();
                  }
                : null,
            onTapUp: enabled
                ? (_) {
                    states.update(WidgetState.pressed, false);
                    splashEnds();
                  }
                : null,
            onTap: enabled ? activate : null,
            child: Semantics(
              button: label.isNotEmpty,
              enabled: enabled,
              hint: hint,
              label: switch (busy ? (busyLabel ?? label) : shownLabel) {
                "" => null,
                final read => read,
              },
              excludeSemantics: face != ButtonFace.bare,
              onTap: enabled ? activate : null,
              child: content,
            ),
          ),
        ),
      ),
    );

    if (press.travels) {
      result = Transform.translate(
        offset: Offset(0, landing.sink * sink.value),
        child: Transform.scale(
          scale: 1 - (1 - landing.scale) * sink.value,
          child: result,
        ),
      );
    }
    result = Rise(
      raised: hovered,
      child: DecoratedBox(
        position: DecorationPosition.foreground,
        decoration: ShapeDecoration(shape: shape, color: shownTint),
        child: result,
      ),
    );
    result = Jam(failures: run.failures, shape: shape, child: result);
    // A bare row or card with nothing to do shows its content alone, not
    // pressed in; a named one is still read as an unavailable button.
    if (face == ButtonFace.bare && onPressed == null) {
      result = label.isEmpty
          ? child!
          : Semantics(button: true, enabled: false, label: label, child: child);
    }

    // The content keeps its state when a tooltip comes or goes around it.
    result = KeyedSubtree(key: kept, child: result);

    // A failure's message stays until the next try.
    final message = run.lastError ?? tooltip;
    if (message != null) {
      result = RawTooltip(
        semanticsTooltip: message,
        tooltipBuilder: (context, animation) =>
            ButtonTooltip(message: message, animation: animation),
        child: result,
      );
    }

    // The button, with its tooltip, is one node for assistive technology. A
    // bare button its content names joins the node of its surroundings.
    if (label.isEmpty) return result;
    return Semantics(container: true, child: result);
  }
}

/// The note a [Button] shows on hover or long press: its tooltip, or the
/// failure of its last run.
class ButtonTooltip extends StatelessWidget {
  const ButtonTooltip({
    required this.message,
    required this.animation,
    super.key,
  });

  final String message;
  final Animation<double> animation;

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: animation,
      child: DecoratedBox(
        decoration: ShapeDecoration(
          shape: context.shapes.smallShape,
          color: context.colors.contentPrimary,
        ),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: context.spacing.space2,
            vertical: context.spacing.space1,
          ),
          child: Text(
            message,
            style: context.theme.textTheme.bodySmall?.copyWith(
              color: context.colors.contentInverse,
            ),
          ),
        ),
      ),
    );
  }
}

/// How long a done word such as Copied stays before the label returns.
const _doneReadTimeout = Duration(milliseconds: 1600);
