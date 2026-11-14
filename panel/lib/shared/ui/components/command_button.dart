import "package:typewriter_panel/typewriter_panel.dart";

/// A button that presses its command. Key and button share one command, so
/// pressing either presses both: a key hold fills this button too, and a
/// key press shows it busy.
///
/// A press command runs on tap through [CommandRuns]. A hold command never
/// runs on tap: a pointer, or Enter or Space on the focused button, held for
/// the hold token of its weight runs it, and a screen reader's long press
/// confirms it at once. The Button's key press drives a key hold: releasing
/// the key, Escape or focus leaving lets go. A pointer hold stays on a
/// Listener, which lets go when a mouse leaves the button or a touch drifts
/// into a scroll, finer than the tap gesture's slop. Once done it types the
/// plan's done word for `holdDoneShow`. Without a run, or when not
/// [enabled], it is unavailable. While held it gives way with [HoldPress].
class CommandButton extends HookConsumerWidget {
  const CommandButton({
    required this.command,
    required this.label,
    this.icon,
    this.face = ButtonFace.quiet,
    this.color,
    this.busyLabel,
    this.doneLabel,
    this.hint,
    this.tooltip,
    this.enabled = true,
    this.rotateShortcuts = false,
    super.key,
  });

  final ActionShortcut command;
  final String label;
  final Widget? icon;
  final ButtonFace face;
  final Color? color;

  /// The word a press run types while it runs: Publishing.
  final String? busyLabel;

  /// The word a finished press run types, such as Copied. A hold types its
  /// plan's done word instead.
  final String? doneLabel;

  /// What a screen reader hears after the label, such as "Destructive".
  final String? hint;

  /// What hovering the button explains.
  final String? tooltip;
  final bool enabled;

  /// Shows every binding of the command in turn instead of only the first,
  /// as the hint bar does.
  final bool rotateShortcuts;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final runs = CommandRunsScope.of(context);
    // Keeps this command's run while the button is mounted.
    useEffect(() => runs.retain(command.id), [runs, command.id]);
    final state = runs.of(command);
    useListenable(state);
    // Only this command's view of the hold rebuilds the button.
    final holding = useListenableSelector(
      runs.session,
      () => runs.session.value?.command == command.id,
    );
    // The button gives way only while the user holds; on completion it
    // springs back.
    final giving = useListenableSelector(
      runs.session,
      () => switch (runs.session.value) {
        final session? =>
          session.command == command.id && session.phase == HoldPhase.holding,
        null => false,
      },
    );
    final keys = command.canInvoke && command.registerShortcut
        ? command.shortcuts
        : const <ShortcutActivator>[];
    final run = enabled ? command.run : null;
    final busy = state.isLoading;
    final down = useRef<Offset?>(null);
    // The pointer holding this button, if any.
    final pointer = useRef<int?>(null);
    // Whether the Button's key press holds the command now.
    final keyHolding = useRef(false);
    // A hold button hides the Button's own semantics, so it reports focus
    // itself; Enter or Space held while focused holds the command.
    final focus = useFocusNode(debugLabel: "CommandButton ${command.id}");
    final focused = useListenableSelector(focus, () => focus.hasFocus);
    // A hold this button started ends with it; another button's or a
    // shortcut's hold of the same command goes on.
    useEffect(
      () => () {
        if (pointer.value case final held?) runs.release(held);
        if (keyHolding.value) runs.release();
      },
      [runs],
    );

    final capStyle = KeyStyle.outline(
      foregroundColor: IconTheme.of(context).color,
    );
    Widget keyCaps(ShortcutActivator first) => rotateShortcuts
        ? RotatingShortcuts(shortcuts: keys, style: capStyle)
        : ShortcutDisplay(shortcut: first, style: capStyle);

    // The key cap sits beside the icon, as the command list lists it first;
    // a round icon button shows its icon alone.
    final shownIcon = switch ((icon, keys)) {
      (_, []) => icon,
      (_, _) when face == ButtonFace.icon => icon,
      (null, [final first, ...]) => keyCaps(first),
      (final icon?, [final first, ...]) => Row(
        mainAxisSize: MainAxisSize.min,
        spacing: context.spacing.space2,
        children: [icon, keyCaps(first)],
      ),
    };

    // Bound to the command: the Button reads the command's run state from
    // CommandRuns and keeps no controller of its own.
    Widget faceWith(
      VoidCallback? onPressed, {
      void Function(PressStep step, PressSource source)? onPress,
      String? doneLabel,
      Duration? doneShow,
      bool splashes = true,
    }) => Button(
      label: label,
      busyLabel: busyLabel,
      doneLabel: doneLabel,
      doneShow: doneShow,
      icon: shownIcon,
      face: face,
      color: color,
      hint: hint,
      tooltip: tooltip,
      controller: state,
      focusNode: focus,
      onPressed: onPressed,
      onPress: onPress,
      splashes: splashes,
    );

    switch (run) {
      case null:
        return faceWith(null, doneLabel: doneLabel);
      case PressRun():
        // The same path as the key: one run, refused while it runs.
        return faceWith(() => runs.press(command, ref), doneLabel: doneLabel);
      case final HoldRun hold:
        void start(PointerDownEvent event) {
          if (busy) return;
          if (event.kind == PointerDeviceKind.mouse &&
              event.buttons != kPrimaryMouseButton) {
            return;
          }
          down.value = event.position;
          pointer.value = event.pointer;
          runs.start(command, ref, HoldInput.pointer(event.pointer));
        }

        // A key press on the Button drives the hold: it starts it, and its
        // release or cancel (key up, Escape, focus leaving) lets go.
        void keyHold(PressStep step, PressSource source) {
          if (source != PressSource.key) return;
          switch (step) {
            case PressStep.start:
              keyHolding.value = true;
              runs.start(command, ref, const HoldInput.button());
            case PressStep.release || PressStep.cancel:
              if (!keyHolding.value) return;
              keyHolding.value = false;
              runs.release();
          }
        }

        return Semantics(
          container: true,
          button: true,
          enabled: !busy,
          focusable: !busy,
          focused: focused,
          // Activating reads the outcome line plus how to confirm.
          label: hold.plan.preview(ref) ?? label,
          hint: [?hint, "Long press to confirm"].join(". "),
          tooltip: state.lastError,
          onLongPress: busy
              ? null
              : () => runs.start(command, ref, const HoldInput.assistive()),
          child: ExcludeSemantics(
            child: Listener(
              onPointerDown: start,
              onPointerMove: (event) {
                final from = down.value;
                if (from == null) return;
                final box = context.findRenderObject() as RenderBox?;
                final inside =
                    box?.paintBounds.contains(
                      box.globalToLocal(event.position),
                    ) ??
                    false;
                // A touch that drifts is a scroll, not a hold; a pressed
                // mouse that leaves the button lets go.
                if (event.kind == PointerDeviceKind.touch
                    ? (event.position - from).distance > kTouchSlop
                    : !inside) {
                  runs.release(event.pointer);
                }
              },
              onPointerUp: (event) => runs.release(event.pointer),
              onPointerCancel: (event) => runs.release(event.pointer),
              child: HoldPress(
                fill: giving ? runs.fill : null,
                share: runs.clock.share,
                motion: runs.clock.motion,
                child: HoldFill(
                  fill: holding ? runs.fill : null,
                  // Red shows on a flat or outlined face; a filled face
                  // darkens.
                  color: face == ButtonFace.filled
                      ? context.holdFillOnFilledColor
                      : null,
                  // With rows, the rows show the run; the button shows it
                  // only for a hold that paints on itself.
                  pressed: busy && hold.plan.rows == null,
                  // The Listener owns a pointer hold and the Button's key
                  // press a key hold; the face never runs work on a press.
                  // The fill is the only press feedback, so it never
                  // splashes.
                  child: faceWith(
                    null,
                    onPress: keyHold,
                    splashes: false,
                    doneLabel: hold.plan.doneWord,
                    doneShow: context.timing.holdDoneShow,
                  ),
                ),
              ),
            ),
          ),
        );
    }
  }
}
