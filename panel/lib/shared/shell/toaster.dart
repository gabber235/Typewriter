import "package:typewriter_panel/typewriter_panel.dart";

/// Floats the panel's toasts over [child], bottom right, newest at the
/// bottom.
///
/// A toast drains with `drain` and holds while pointed at or focused. Left
/// alone, a failure flies into the Activity button and waits there unread;
/// a success clears. T moves the focus to the newest toast, where R retries
/// and Escape dismisses and gives the focus back. A toast never takes the
/// focus by itself; it is heard as it shows.
class Toaster extends HookConsumerWidget {
  const Toaster({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notices = ref.watch(noticesProvider);
    final landing = ref.watch(toastLandingProvider);
    final focus = useMemoized(_ToastFocus.new);
    useEffect(() => focus.dispose, [focus]);

    // A toast that stops floating stays on screen while it leaves.
    final floating = [
      for (final notice in notices)
        if (notice.toasting) notice,
    ];
    final leaving = useRef(<int, (Notice, _Exit)>{});
    final departed = useState(0);
    final shown = useRef(<int, Notice>{});
    final gone = {
      for (final MapEntry(:key, :value) in shown.value.entries)
        if (!floating.any((notice) => notice.id == key))
          key: (
            value,
            notices.any((notice) => notice.id == key && notice.unread)
                ? _Exit.lands
                : _Exit.clears,
          ),
    };
    shown.value = {for (final notice in floating) notice.id: notice};
    leaving.value.addAll(gone);

    final slots = [
      for (final MapEntry(key: id, value: (notice, exit))
          in leaving.value.entries)
        (notice: notice, exit: exit, id: id),
      for (final notice in floating)
        (notice: notice, exit: null, id: notice.id),
    ]..sort((a, b) => a.id.compareTo(b.id));

    // T is a Normal mode key; in a field it types.
    final canFocus =
        floating.isNotEmpty &&
        !ref.watch(interactionSuspendedProvider) &&
        ref.watch(currentInteractionModeProvider) is NormalMode;
    return ManagedActionSet(
      shortcuts: [
        if (canFocus)
          ActionShortcut(
            id: "focus_toast",
            label: "Toast",
            description: "Move to the newest toast",
            activators: const [
              SingleActivator(LogicalKeyboardKey.keyT, includeRepeats: false),
            ],
            priority: 0,
            run: ActionRun.press((ref) => focus.enter(floating.last.id)),
          ),
      ],
      child: Stack(
        children: [
          Positioned.fill(child: child),
          Positioned(
            right: context.spacing.space4,
            bottom: context.spacing.space4,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: min(
                  _toastWidth,
                  MediaQuery.sizeOf(context).width - context.spacing.space4 * 2,
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                spacing: context.spacing.space2,
                children: [
                  for (final slot in slots)
                    _ToastSlot(
                      key: ValueKey(slot.id),
                      notice: slot.notice,
                      exit: slot.exit,
                      focus: focus,
                      landing: landing,
                      onGone: () {
                        leaving.value.remove(slot.id);
                        departed.value++;
                      },
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

const double _toastWidth = 380;

enum _Exit { lands, clears }

/// Moves the focus into a toast and back to where it was.
final class _ToastFocus {
  final nodes = <int, FocusNode>{};
  FocusNode? _returnTo;

  FocusNode nodeOf(int id) =>
      nodes.putIfAbsent(id, () => FocusNode(debugLabel: "Toast $id"));

  void enter(int id) {
    final current = FocusManager.instance.primaryFocus;
    if (!nodes.values.contains(current)) _returnTo = current;
    nodeOf(id).requestFocus();
  }

  /// The toast of [id] leaves: if it held the focus, the focus goes back.
  void leave(int id) {
    final node = nodes.remove(id);
    if (node == null) return;
    if (node.hasFocus) {
      final back = _returnTo;
      _returnTo = null;
      if (back != null && back.context != null) back.requestFocus();
    }
    // Disposed after the frame, once the toast no longer builds with it.
    WidgetsBinding.instance.addPostFrameCallback((_) => node.dispose());
  }

  void dispose() {
    for (final node in nodes.values) {
      node.dispose();
    }
    nodes.clear();
  }
}

class _ToastSlot extends HookConsumerWidget {
  const _ToastSlot({
    required this.notice,
    required this.exit,
    required this.focus,
    required this.landing,
    required this.onGone,
    super.key,
  });

  final Notice notice;
  final _Exit? exit;
  final _ToastFocus focus;
  final ToastLanding landing;
  final VoidCallback onGone;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notices = ref.read(noticesProvider.notifier);
    final node = useMemoized(() => focus.nodeOf(notice.id));
    final arrive = resolveMotion(context, MotionToken.surfaceIn);
    final leave = resolveMotion(context, MotionToken.panelOut);
    final arrival = useMotionController(initial: arrive.travels ? 0 : 1);
    final departure = useMotionController();
    final flight = useRef<Offset?>(null);
    useEffect(() {
      arrival.to(1, arrive);
      return null;
    }, const []);
    useEffect(() {
      if (exit == null) return null;
      focus.leave(notice.id);
      if (exit == _Exit.lands) {
        final box = context.findRenderObject();
        if (box is RenderBox) flight.value = landing.towards(box);
      }
      departure.to(1, leave).then((_) => onGone());
      if (!leave.travels) {
        WidgetsBinding.instance.addPostFrameCallback((_) => onGone());
      }
      return null;
    }, [exit]);

    // A retry that worked shows done for a moment, then the toast clears.
    final resolved = notice.progress == NoticeProgress.resolved;
    final doneShow = context.timing.doneShow;
    useEffect(() {
      if (!resolved || exit != null) return null;
      final timer = Timer(doneShow, () => notices.remove(notice.id));
      return timer.cancel;
    }, [resolved, exit]);

    return AnimatedBuilder(
      animation: Listenable.merge([arrival, departure]),
      builder: (context, child) {
        final arrived = arrival.value;
        final left = departure.value.clamp(0.0, 1.0);
        final towards = flight.value;
        final offset = towards != null
            ? towards * left
            : Offset(0, context.spacing.space6 * left);
        final scale = towards != null ? 1 - .8 * left : 1.0;
        return IgnorePointer(
          ignoring: exit != null,
          child: Opacity(
            // Heard from its first frame, while it still fades in.
            alwaysIncludeSemantics: exit == null,
            opacity: (arrived.clamp(0.0, 1.0) * (1 - left)).clamp(0.0, 1.0),
            child: Transform.translate(
              offset:
                  Offset(0, context.spacing.space6 * (1 - arrived)) + offset,
              child: Transform.scale(scale: scale, child: child),
            ),
          ),
        );
      },
      child: _Toast(
        notice: notice,
        node: node,
        holding: exit == null,
        onRetry: () => notices.retry(notice.id),
        onDismiss: () => notice.tone == NoticeTone.success || resolved
            ? notices.remove(notice.id)
            : notices.dismiss(notice.id),
        onDrained: () => notices.land(notice.id),
      ),
    );
  }
}

class _Toast extends HookWidget {
  const _Toast({
    required this.notice,
    required this.node,
    required this.holding,
    required this.onRetry,
    required this.onDismiss,
    required this.onDrained,
  });

  final Notice notice;
  final FocusNode node;

  /// Whether the toast still floats; a leaving toast stops draining.
  final bool holding;
  final Future<void> Function() onRetry;
  final VoidCallback onDismiss;
  final VoidCallback onDrained;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final spacing = context.spacing;
    final text = Theme.of(context).textTheme;
    final drainMotion = resolveMotion(context, MotionToken.drain);
    final drain = useMotionController(initial: 1);
    final hovered = useState(false);
    final focused = useState(false);
    final resolved = notice.progress == NoticeProgress.resolved;
    final paused =
        hovered.value ||
        focused.value ||
        !holding ||
        notice.progress != NoticeProgress.open;

    useEffect(() {
      if (paused) {
        drain.jumpTo(drain.value);
        return null;
      }
      var live = true;
      drain.to(0, drainMotion).then((_) {
        if (live && drain.value <= 0) onDrained();
      });
      return () => live = false;
    }, [paused]);

    final tone = resolved || notice.tone == NoticeTone.success
        ? colors.success
        : colors.danger;
    final title = resolved ? "Done" : notice.title;
    final detail = resolved ? notice.title : notice.detail;
    final heard = [title, ?detail].join(". ");

    // R has no panel intent; Escape dismisses through DismissIntent below.
    KeyEventResult onKey(FocusNode _, KeyEvent event) {
      if (event is! KeyDownEvent) return KeyEventResult.ignored;
      if (event.logicalKey == LogicalKeyboardKey.keyR &&
          notice.retry != null &&
          !resolved) {
        unawaited(onRetry());
        return KeyEventResult.handled;
      }
      return KeyEventResult.ignored;
    }

    return MouseRegion(
      onEnter: (_) => hovered.value = true,
      onExit: (_) => hovered.value = false,
      child: Semantics(
        container: true,
        liveRegion: true,
        label: heard,
        child: Actions(
          actions: {
            DismissIntent: CallbackAction<DismissIntent>(
              onInvoke: (_) => onDismiss(),
            ),
          },
          child: Focus(
            focusNode: node,
            onKeyEvent: onKey,
            onFocusChange: (inside) => focused.value = inside,
            child: Jam(
              failures: notice.attempts,
              shape: context.shapes.largeShape,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: colors.surfaceRaised,
                  borderRadius: context.shapes.largeBorderRadius,
                  boxShadow: context.menuShadow,
                ),
                child: ClipRRect(
                  borderRadius: context.shapes.largeBorderRadius,
                  child: Surface(
                    color: colors.surfaceRaised,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Padding(
                          padding: EdgeInsets.fromLTRB(
                            spacing.space3,
                            spacing.space3,
                            spacing.space2,
                            spacing.space3,
                          ),
                          child: Row(
                            spacing: spacing.space3,
                            children: [
                              _ToneTile(
                                color: tone,
                                icon:
                                    resolved ||
                                        notice.tone == NoticeTone.success
                                    ? Icons.check_rounded
                                    : Icons.error_outline_rounded,
                              ),
                              Expanded(
                                child: ExcludeSemantics(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      MotionLabel(
                                        title,
                                        typesIn: resolved,
                                        style: text.titleSmall?.copyWith(
                                          color: colors.contentPrimary,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      if (detail != null)
                                        Text(
                                          detail,
                                          style: text.bodySmall?.copyWith(
                                            color: colors.contentSecondary,
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                              if (notice.retry != null && !resolved)
                                Button(
                                  label: "Retry",
                                  busyLabel: "Retrying",
                                  icon: const Icon(
                                    Icons.refresh_rounded,
                                    size: 16,
                                  ),
                                  onPressed: onRetry,
                                ),
                              Button(
                                face: ButtonFace.icon,
                                label: "Dismiss",
                                icon: const Icon(Icons.close_rounded, size: 18),
                                onPressed: onDismiss,
                              ),
                            ],
                          ),
                        ),
                        AnimatedBuilder(
                          animation: drain,
                          builder: (context, _) => Align(
                            alignment: Alignment.centerLeft,
                            child: FractionallySizedBox(
                              widthFactor: drain.value.clamp(0.0, 1.0),
                              child: SizedBox(
                                height: 2,
                                child: ColoredBox(color: tone),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ToneTile extends StatelessWidget {
  const _ToneTile({required this.color, required this.icon});

  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: 36,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: color.withValues(alpha: .14),
          borderRadius: context.shapes.mediumBorderRadius,
        ),
        child: Icon(icon, size: 20, color: color),
      ),
    );
  }
}
