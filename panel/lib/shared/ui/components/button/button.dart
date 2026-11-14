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

/// Where a press of a [Button] comes from.
enum PressSource { pointer, key }

/// One step of a press of a [Button]. A press starts, then ends once: it is
/// released inside, and the button acts, or it is cancelled and nothing
/// happens. Escape, the pointer leaving or being cancelled, focus leaving
/// and the button becoming unavailable cancel it.
enum PressStep { start, release, cancel }

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
    this.onPress,
    this.doneShow,
    this.splashes = true,
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

  /// How long [doneLabel] stays before the label returns: a held button's
  /// done word stays `holdDoneShow`. Long enough to read by default.
  final Duration? doneShow;

  /// Sync or async. While a returned Future runs the button is busy and
  /// refuses another press; an Exception jams it and is reported. Null makes
  /// the button unavailable.
  final FutureOr<void> Function()? onPressed;

  /// Follows every press through its steps, for a caller that drives its
  /// own action from the press, as a hold does: it starts with
  /// [PressStep.start] and ends with [PressStep.release] or
  /// [PressStep.cancel]. A button with [onPress] and no [onPressed] is
  /// available and acts on nothing itself.
  final void Function(PressStep step, PressSource source)? onPress;
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

  /// Whether a press splashes. A hold button passes false, so its hold fill
  /// is its only press feedback.
  final bool splashes;

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
      final timer = Timer(
        doneShow ?? _doneReadTimeout,
        () => done.value = false,
      );
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
    final acts = onPressed != null || onPress != null;
    final enabled = bound
        ? acts && !busy
        : run.canTrigger || (onPressed == null && onPress != null);
    final unavailable = !enabled && !busy;
    final pressed =
        busy || unavailable || current.contains(WidgetState.pressed);
    final hovered = !pressed && current.contains(WidgetState.hovered);

    void activate() {
      final press = onPressed;
      if (!enabled || press == null) return;
      if (bound) {
        press();
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
      if (!splashes || !splash.travels || face == ButtonFace.bare) return;
      inkAt.value = at;
      drain.jumpTo(0);
      grow
        ..jumpTo(0)
        ..to(1, splash);
    }

    void splashEnds() => drain.to(1, drainMotion);

    // The one press lifecycle, for pointer and key alike: a press starts,
    // then is released inside, which acts, or is cancelled, which does not.
    // [onPress] follows every step.
    final pressing = useRef<PressSource?>(null);
    void pressStarts(PressSource source, Offset at) {
      if (pressing.value != null) return;
      pressing.value = source;
      states.update(WidgetState.pressed, true);
      splashFrom(at);
      onPress?.call(PressStep.start, source);
    }

    void pressEnds(PressStep step, {PressSource? only}) {
      final source = pressing.value;
      if (source == null || (only != null && source != only)) return;
      pressing.value = null;
      states.update(WidgetState.pressed, false);
      splashEnds();
      onPress?.call(step, source);
      if (step == PressStep.release) activate();
    }

    // A press held while the button stops taking presses is cancelled.
    useEffect(() {
      if (!enabled) pressEnds(PressStep.cancel);
      return null;
    }, [enabled]);

    // Keys: Space or Enter down starts a press and splashes from the middle;
    // key up releases it; Escape cancels it. With a modifier held the key
    // belongs to a shortcut, such as Ctrl+Enter publishing.
    KeyEventResult keys(FocusNode node, KeyEvent event) {
      final key = event.logicalKey;
      final activator =
          key == LogicalKeyboardKey.space ||
          key == LogicalKeyboardKey.enter ||
          key == LogicalKeyboardKey.numpadEnter;
      final keyPress = pressing.value == PressSource.key;
      if (key == LogicalKeyboardKey.escape && keyPress) {
        if (event is KeyDownEvent) pressEnds(PressStep.cancel);
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
          final box = context.findRenderObject();
          pressStarts(
            PressSource.key,
            box is RenderBox ? box.size.center(Offset.zero) : Offset.zero,
          );
        case KeyUpEvent() when keyPress:
          pressEnds(PressStep.release);
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
        onFocusChange: (on) {
          states.update(WidgetState.focused, on);
          // A key press ends when focus leaves, since its key up goes
          // elsewhere.
          if (!on) pressEnds(PressStep.cancel, only: PressSource.key);
        },
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
                ? (details) =>
                      pressStarts(PressSource.pointer, details.localPosition)
                : null,
            // The tap gesture cancels when the pointer drifts past the slop
            // or another gesture wins it.
            onTapCancel: enabled
                ? () => pressEnds(PressStep.cancel, only: PressSource.pointer)
                : null,
            onTapUp: enabled
                ? (_) => pressEnds(PressStep.release, only: PressSource.pointer)
                : null,
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
    if (face == ButtonFace.bare && !acts) {
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
