import "package:typewriter_panel/typewriter_panel.dart";

/// One option of a token: a table with that row changed, and its values.
final class MotionLabOption {
  const MotionLabOption(this.name, this.table, this.values);

  final String name;
  final TypewriterMotion table;
  final String values;
}

/// Three options of [token]: the table value between a calmer and a
/// stronger one. Strength scales overshoot, recoil, bounce and travel;
/// tempo scales time.
List<MotionLabOption> motionLabOptions<L extends Landing>(
  TypewriterMotion table,
  MotionToken<L> token,
) {
  final spec = table.spec(token);
  return [
    for (final (name, strength, tempo) in const [
      ("Calmer", 0.6, 1.25),
      ("Table", 1.0, 1.0),
      ("Stronger", 1.5, 0.8),
    ])
      () {
        final varied = spec.copyWith(
          motion: _vary(spec.motion, strength, tempo),
          landing: _scaleLanding(spec.landing, strength) as L,
        );
        return MotionLabOption(
          name,
          table.withSpec(token, varied),
          describeMotion(varied),
        );
      }(),
  ];
}

Motion _vary(Motion motion, double strength, double tempo) => switch (motion) {
  CurveMotion(curve: StrikeCurve(:final overshoot), :final duration) =>
    CurveMotion(
      StrikeCurve(overshoot: (overshoot * strength).clamp(0.01, 0.5)),
      duration * tempo,
    ),
  CurveMotion(
    curve: CarriageCurve(:final hit, :final recoil),
    :final duration,
  ) =>
    CurveMotion(
      CarriageCurve(hit: hit, recoil: (recoil * strength).clamp(0.0, 0.5)),
      duration * tempo,
    ),
  CurveMotion(:final curve, :final duration) => CurveMotion(
    curve,
    duration * tempo,
  ),
  final SpringMotion spring => SpringMotion.settling(
    spring.duration * tempo,
    dampingRatio: (spring.dampingRatio / strength).clamp(0.1, 1.0),
  ),
  HoldMotion(:final fill, :final duration) => HoldMotion(
    fill: SpringMotion.settling(
      fill.duration * tempo,
      dampingRatio: (fill.dampingRatio / strength).clamp(0.1, 1.0),
    ),
    duration: duration * tempo,
  ),
  LoopMotion() ||
  StepMotion() ||
  JudderMotion() => motion.withDuration(motion.duration * tempo),
  InstantMotion() => motion,
};

Landing _scaleLanding(Landing landing, double strength) => switch (landing) {
  RiseLanding(:final rise, :final scale) => RiseLanding(
    rise: rise * strength,
    scale: 1 + (scale - 1) * strength,
  ),
  EnterLanding(:final from, :final stagger) => EnterLanding(
    from: from * strength,
    stagger: stagger,
  ),
  PressLanding(:final sink, :final scale) => PressLanding(
    sink: sink * strength,
    scale: 1 - (1 - scale) * strength,
  ),
  PaneLanding(:final active, :final inactive, :final wash) => PaneLanding(
    active: 1 + (active - 1) * strength,
    inactive: 1 - (1 - inactive) * strength,
    wash: wash * strength,
  ),
  LetterLanding(:final rise, :final letterGap, :final tint) => LetterLanding(
    rise: rise * strength,
    letterGap: letterGap,
    tint: tint,
  ),
  JamLanding(:final amplitude, :final flash) => JamLanding(
    amplitude: amplitude * strength,
    flash: flash,
  ),
  SurfaceLanding(:final originScale, :final behindScale) => SurfaceLanding(
    originScale: 1 - (1 - originScale) * strength,
    behindScale: 1 - (1 - behindScale) * strength,
  ),
  InkLanding() || NoLanding() => landing,
};

/// The row's values in the skill table's words.
String describeMotion(MotionSpec<Landing> spec) {
  final motion = switch (spec.motion) {
    CurveMotion(curve: StrikeCurve(:final overshoot), :final duration) =>
      "Strike ${duration.inMilliseconds} ms, ${(overshoot * 100).round()}% overshoot",
    CurveMotion(
      curve: CarriageCurve(:final hit, :final recoil),
      :final duration,
    ) =>
      "Carriage ${duration.inMilliseconds} ms, ${(recoil * 100).round()}% recoil at h = $hit",
    CurveMotion(:final duration) => "Curve ${duration.inMilliseconds} ms",
    SpringMotion(:final stiffness, :final damping, :final dampingRatio) =>
      "Spring stiffness ${stiffness.round()}, damping ${damping.toStringAsFixed(1)} (ratio ${dampingRatio.toStringAsFixed(2)})",
    HoldMotion(:final fill, :final duration) =>
      "Hold ${duration.inMilliseconds} ms, fill ratio ${fill.dampingRatio.toStringAsFixed(2)}",
    LoopMotion(:final period) => "Loop ${period.inMilliseconds} ms",
    StepMotion(:final step) => "Stepped ${step.inMilliseconds} ms per letter",
    JudderMotion(:final duration, :final cycles) =>
      "Judder ${duration.inMilliseconds} ms, $cycles cycles",
    InstantMotion() => "Instant",
  };
  final landing = switch (spec.landing) {
    RiseLanding(:final rise, :final scale) =>
      "rises ${rise.toStringAsFixed(1)} px, scale ${scale.toStringAsFixed(3)}",
    EnterLanding(:final from) =>
      "from ${from.dx.round()}, ${from.dy.round()} px",
    PressLanding(:final sink, :final scale) =>
      "sinks ${sink.toStringAsFixed(1)} px, scale ${scale.toStringAsFixed(3)}",
    PaneLanding(:final active, :final inactive, :final wash) =>
      "active $active, others $inactive, wash $wash",
    LetterLanding(:final rise, :final letterGap) =>
      "letters rise ${rise.toStringAsFixed(1)} px, ${letterGap.inMilliseconds} ms apart",
    JamLanding(:final amplitude) => "${amplitude.toStringAsFixed(1)} px",
    SurfaceLanding(:final originScale, :final behindScale) =>
      "starts at $originScale, page behind $behindScale",
    InkLanding() || NoLanding() => "",
  };
  return [
    motion,
    landing,
    "reduced: ${spec.reduced.name}",
  ].where((part) => part.isNotEmpty).join("; ");
}

/// Three live options of [token] side by side on real panel widgets. Replay
/// plays all three again together. Under the `reducedMotion` story trait
/// it shows what each keeps.
class MotionLab extends HookWidget {
  const MotionLab({required this.token, super.key});

  final MotionToken<Landing> token;

  @override
  Widget build(BuildContext context) {
    final base = Theme.of(context);
    final replay = useState(0);
    final options = motionLabOptions(base.motion, token);
    return SizedBox(
      width: 1200,
      height: 640,
      child: ColoredBox(
        color: context.colors.canvas,
        child: Padding(
          padding: EdgeInsets.all(context.spacing.space6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(token.name, style: base.textTheme.titleLarge),
                  const Spacer(),
                  FilledButton(
                    onPressed: () => replay.value++,
                    child: const Text("Replay"),
                  ),
                ],
              ),
              SizedBox(height: context.spacing.space4),
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (final option in options)
                      Expanded(
                        child: Theme(
                          data: base.copyWith(
                            extensions: [
                              ...base.extensions.values.where(
                                (extension) => extension is! TypewriterMotion,
                              ),
                              option.table,
                            ],
                          ),
                          child: Padding(
                            padding: EdgeInsets.all(context.spacing.space3),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  option.name,
                                  style: base.textTheme.titleMedium,
                                ),
                                Text(
                                  option.values,
                                  style: base.textTheme.bodySmall,
                                ),
                                SizedBox(height: context.spacing.space4),
                                Expanded(
                                  child: _TokenDemo(
                                    token: token,
                                    key: ValueKey((option.name, replay.value)),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The token played on the widgets it moves in the panel. A new key
/// remounts it, which replays it.
class _TokenDemo extends StatelessWidget {
  const _TokenDemo({required this.token, super.key});

  final MotionToken<Landing> token;

  @override
  Widget build(BuildContext context) {
    return switch (token) {
      MotionToken.hoverIn ||
      MotionToken.hoverOut => const _HoverDemo(token: MotionToken.hoverIn),
      MotionToken.capIn => const _HoverDemo(token: MotionToken.capIn),
      MotionToken.rowIn => const _RowsDemo(),
      MotionToken.loadIn => const _LoadDemo(),
      MotionToken.listOut => const _RemoveDemo(),
      MotionToken.focusMove => const _RingDemo(),
      MotionToken.hold => const _HoldDemo(),
      _ => _ValueDemo(token: token),
    };
  }
}

/// Real buttons that rise on hover, and rise once by themselves on replay.
class _HoverDemo extends HookWidget {
  const _HoverDemo({required this.token});

  final MotionToken<RiseLanding> token;

  @override
  Widget build(BuildContext context) {
    final hovered = useState(true);
    useEffect(() {
      final timer = Timer(
        const Duration(milliseconds: 700),
        () => hovered.value = false,
      );
      return timer.cancel;
    }, const []);
    return MouseRegion(
      onEnter: (_) => hovered.value = true,
      onExit: (_) => hovered.value = false,
      child: Rise(
        raised: hovered.value,
        token: token,
        stillFill: context.colors.surfaceRaised,
        borderRadius: BorderRadius.circular(context.shapes.medium),
        child: token == MotionToken.capIn
            ? const ShortcutDisplay(
                shortcut: SingleActivator(LogicalKeyboardKey.keyD),
              )
            : FilledButton(onPressed: () {}, child: const Text("Publish")),
      ),
    );
  }
}

/// A pane of member rows; replay loads them with loadIn.
class _LoadDemo extends StatelessWidget {
  const _LoadDemo();

  @override
  Widget build(BuildContext context) {
    const names = [
      "Ada",
      "Ben",
      "Cleo",
      "Dev",
      "Eli",
      "Fay",
      "Gus",
      "Hana",
      "Ivo",
      "Jun",
    ];
    // Pane becomes an EnterRun in PR 5; the lab places the run itself.
    return Pane(
      id: "motion-lab-members",
      child: EnterRun(
        child: Column(
          children: [
            for (final name in names)
              Enter(token: MotionToken.loadIn, child: Text(name)),
          ],
        ),
      ),
    );
  }
}

/// One member row as the panel's lists show it.
class _LabRow extends StatelessWidget {
  const _LabRow(this.text, {this.fill, this.spaced = true});

  final String text;
  final Color? fill;

  /// Leaves the gap to the next row below it.
  final bool spaced;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: spaced ? context.spacing.space1 : 0),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: fill ?? context.colors.surfaceRaised,
          borderRadius: BorderRadius.circular(context.shapes.medium),
        ),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: context.spacing.space3,
            vertical: context.spacing.space2,
          ),
          child: Align(alignment: Alignment.centerLeft, child: Text(text)),
        ),
      ),
    );
  }
}

/// Starts after [delay] once mounted, so a replay shows the move by itself.
bool _useStarted(Duration delay) {
  final started = useState(false);
  useEffect(() {
    final timer = Timer(delay, () => started.value = true);
    return timer.cancel;
  }, const []);
  return started.value;
}

/// Member rows; a join code row arrives with rowIn on replay and on Add.
class _RowsDemo extends HookWidget {
  const _RowsDemo();

  @override
  Widget build(BuildContext context) {
    final codes = useState(1);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _LabRow("Ada"),
        const _LabRow("Ben"),
        for (var code = 1; code <= codes.value; code++)
          Enter(key: ValueKey(code), child: _LabRow("Join code $code")),
        SizedBox(height: context.spacing.space2),
        OutlinedButton(
          onPressed: codes.value < 4 ? () => codes.value++ : null,
          child: const Text("Add join code"),
        ),
      ],
    );
  }
}

/// The middle member row leaves with listOut on replay, and comes back.
class _RemoveDemo extends HookWidget {
  const _RemoveDemo();

  @override
  Widget build(BuildContext context) {
    final started = _useStarted(const Duration(milliseconds: 400));
    final removed = useState<bool?>(null);
    final gone = removed.value ?? started;
    final progress = useMotion(MotionToken.listOut, gone ? 0 : 1);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _LabRow("Ada"),
        Leave(progress: progress, child: const _LabRow("Ben")),
        const _LabRow("Cleo"),
        SizedBox(height: context.spacing.space2),
        OutlinedButton(
          onPressed: () => removed.value = !gone,
          child: Text(gone ? "Restore Ben" : "Remove Ben"),
        ),
      ],
    );
  }
}

/// A ring over two panes of rows that moves down three rows and across.
/// Each option rings its own rows, so the demo moves the ring's target
/// rather than keyboard focus, which only one option could hold.
class _RingDemo extends HookWidget {
  const _RingDemo();

  static const _path = ["left 1", "left 2", "left 3", "left 4", "right 2"];

  @override
  Widget build(BuildContext context) {
    final nodes = useMemoized(
      () => {
        for (final name in [
          for (final side in ["left", "right"])
            for (var row = 1; row <= 4; row++) "$side $row",
        ])
          name: FocusNode(debugLabel: name, skipTraversal: true),
      },
    );
    useEffect(
      () => () {
        for (final node in nodes.values) {
          node.dispose();
        }
      },
      [nodes],
    );
    final step = useState(0);
    useEffect(() {
      final timer = Timer.periodic(const Duration(milliseconds: 450), (timer) {
        if (step.value + 1 >= _path.length) {
          timer.cancel();
          return;
        }
        step.value++;
      });
      return timer.cancel;
    }, const []);
    final target = useState<RingGeometry?>(null);
    useEffect(() {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final node = nodes[_path[step.value]]!;
        if (node.context != null) target.value = RingTarget.geometryOf(node);
      });
      return null;
    }, [step.value]);

    Widget pane(String side) => Expanded(
      child: Column(
        children: [
          for (var row = 1; row <= 4; row++)
            Padding(
              padding: EdgeInsets.only(bottom: context.spacing.space1),
              child: RingTarget(
                borderRadius: BorderRadius.circular(context.shapes.medium),
                child: Focus(
                  focusNode: nodes["$side $row"],
                  child: _LabRow("$side $row", spaced: false),
                ),
              ),
            ),
        ],
      ),
    );
    return Stack(
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            pane("left"),
            SizedBox(width: context.spacing.space4),
            pane("right"),
          ],
        ),
        Positioned.fill(
          child: IgnorePointer(child: Ring(target: target.value)),
        ),
      ],
    );
  }
}

/// A member row that fills while Hold to remove is held down.
class _HoldDemo extends HookWidget {
  const _HoldDemo();

  @override
  Widget build(BuildContext context) {
    final removed = useState(false);
    final vsync = useTickerProvider();
    final clock = useMemoized(
      () => HoldClock(vsync: vsync, onComplete: () => removed.value = true),
    );
    useEffect(() => clock.dispose, [clock]);
    final hold = resolveMotion(context, MotionToken.hold);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        HoldFill(
          fill: clock.fill,
          child: _LabRow(removed.value ? "Ada was removed" : "Ada"),
        ),
        SizedBox(height: context.spacing.space2),
        Listener(
          onPointerDown: (_) => clock.press(hold),
          onPointerUp: (_) => clock.release(),
          onPointerCancel: (_) => clock.release(),
          child: OutlinedButton(
            onPressed: () {},
            child: const Text("Hold to remove"),
          ),
        ),
        if (removed.value)
          TextButton(
            onPressed: () {
              clock.reset();
              removed.value = false;
            },
            child: const Text("Bring Ada back"),
          ),
      ],
    );
  }
}

/// The remaining tokens on the widgets they move.
class _ValueDemo extends StatelessWidget {
  const _ValueDemo({required this.token});

  final MotionToken<Landing> token;

  @override
  Widget build(BuildContext context) {
    return switch (token) {
      MotionToken.press => const _PressDemo(),
      MotionToken.paneFocus => const _PaneFocusDemo(),
      MotionToken.panelIn => const _SurfaceDemo(token: MotionToken.panelIn),
      MotionToken.surfaceIn => const _SurfaceDemo(token: MotionToken.surfaceIn),
      MotionToken.dialogIn => const _SurfaceDemo(token: MotionToken.dialogIn),
      MotionToken.panelOut => const _SurfaceOutDemo(
        token: MotionToken.panelOut,
        arrival: MotionToken.panelIn,
      ),
      MotionToken.dialogOut => const _SurfaceOutDemo(
        token: MotionToken.dialogOut,
        arrival: MotionToken.dialogIn,
      ),
      MotionToken.ripple => const _WordDemo(token: MotionToken.ripple),
      MotionToken.wave => const _WordDemo(token: MotionToken.wave),
      MotionToken.waveSlow => const _WordDemo(token: MotionToken.waveSlow),
      MotionToken.type => const _TypeDemo(),
      MotionToken.skeleton => const _SkeletonDemo(),
      MotionToken.ink => const _InkDemo(),
      MotionToken.drain => const _DrainDemo(),
      MotionToken.jam => const _JamDemo(),
      _ => Text("${token.name} plays in its own demo"),
    };
  }
}

/// A Publish button pressed by itself on replay, and by the pointer.
class _PressDemo extends HookWidget {
  const _PressDemo();

  @override
  Widget build(BuildContext context) {
    final started = _useStarted(const Duration(milliseconds: 300));
    final held = useState<bool?>(null);
    useEffect(() {
      if (!started) return null;
      final timer = Timer(
        const Duration(milliseconds: 160),
        () => held.value ??= false,
      );
      return timer.cancel;
    }, [started]);
    final down = held.value ?? started;
    final resolved = resolveMotion(context, MotionToken.press);
    final value = useMotion(MotionToken.press, down ? 1 : 0).value;
    final landing = resolved.landing;
    Widget button = FilledButton(
      onPressed: () {},
      child: const Text("Publish"),
    );
    if (resolved.still && down) {
      button = DecoratedBox(
        position: DecorationPosition.foreground,
        decoration: BoxDecoration(
          color: context.colors.contentInverse.withValues(
            alpha: context.stateTokens.pressedOpacity,
          ),
          borderRadius: BorderRadius.circular(context.shapes.medium),
        ),
        child: button,
      );
    }
    return Listener(
      onPointerDown: (_) => held.value = true,
      onPointerUp: (_) => held.value = false,
      child: Align(
        alignment: Alignment.topLeft,
        child: Transform.translate(
          offset: Offset(0, landing.sink * value),
          child: Transform.scale(
            scale: 1 - (1 - landing.scale) * value,
            child: button,
          ),
        ),
      ),
    );
  }
}

/// Two panes; focus moves to the right one and back.
class _PaneFocusDemo extends HookWidget {
  const _PaneFocusDemo();

  @override
  Widget build(BuildContext context) {
    final right = useState(false);
    useEffect(() {
      final timer = Timer.periodic(const Duration(milliseconds: 900), (timer) {
        right.value = !right.value;
        if (timer.tick >= 2) timer.cancel();
      });
      return timer.cancel;
    }, const []);
    Widget pane(String name, {required bool active}) => Expanded(
      child: _FocusPane(name: name, active: active),
    );
    return SizedBox(
      height: 160,
      child: Row(
        children: [
          pane("Pages", active: !right.value),
          SizedBox(width: context.spacing.space4),
          pane("Inspector", active: right.value),
        ],
      ),
    );
  }
}

class _FocusPane extends HookWidget {
  const _FocusPane({required this.name, required this.active});

  final String name;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final landing = resolveMotion(context, MotionToken.paneFocus).landing;
    final value = useMotion(MotionToken.paneFocus, active ? 1 : 0).value;
    return Transform.scale(
      scale: landing.inactive + (landing.active - landing.inactive) * value,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Color.alphaBlend(
            context.colors.contentPrimary.withValues(
              alpha: (landing.wash * value).clamp(0.0, 1.0),
            ),
            context.colors.panel,
          ),
          borderRadius: BorderRadius.circular(context.shapes.large),
        ),
        child: Center(child: Text(name)),
      ),
    );
  }
}

/// A surface that grows from the button that opens it.
class _SurfaceDemo extends HookWidget {
  const _SurfaceDemo({required this.token});

  final MotionToken<SurfaceLanding> token;

  @override
  Widget build(BuildContext context) {
    final open = _useStarted(const Duration(milliseconds: 300));
    final landing = resolveMotion(context, token).landing;
    final value = useMotion(token, open ? 1 : 0).value;
    const opener = Rect.fromLTWH(0, 0, 120, 36);
    const surface = Rect.fromLTWH(0, 48, 300, 180);
    final grows = token == MotionToken.surfaceIn;
    final rect = grows ? Rect.lerp(opener, surface, value)! : surface;
    final scale = landing.originScale + (1 - landing.originScale) * value;
    final behind = 1 - (1 - landing.behindScale) * value;
    return Stack(
      children: [
        Transform.scale(
          scale: behind,
          child: Align(
            alignment: Alignment.topLeft,
            child: OutlinedButton(onPressed: () {}, child: const Text("Open")),
          ),
        ),
        if (value > 0)
          Positioned.fromRect(
            rect: rect,
            child: Opacity(
              opacity: grows ? 1 : value.clamp(0.0, 1.0),
              child: Transform.scale(
                scale: scale,
                alignment: token == MotionToken.dialogIn
                    ? Alignment.center
                    : Alignment.topLeft,
                child: SurfaceContainer(
                  motion: ResolvedMotion.immediate,
                  decoration: BoxDecoration(
                    color: context.colors.surfaceRaised,
                    borderRadius: BorderRadius.circular(context.shapes.large),
                  ),
                  padding: EdgeInsets.all(context.spacing.space4),
                  child: const Text("Publish to the realm"),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// A surface that closes back towards where it arrived from.
class _SurfaceOutDemo extends HookWidget {
  const _SurfaceOutDemo({required this.token, required this.arrival});

  final MotionToken<NoLanding> token;
  final MotionToken<SurfaceLanding> arrival;

  @override
  Widget build(BuildContext context) {
    final closed = _useStarted(const Duration(milliseconds: 500));
    final landing = context.motion.spec(arrival).landing;
    final value = useMotion(token, closed ? 0 : 1).value;
    return Align(
      alignment: Alignment.topLeft,
      child: Opacity(
        opacity: value.clamp(0.0, 1.0),
        child: Transform.scale(
          scale: landing.originScale + (1 - landing.originScale) * value,
          child: SizedBox(
            width: 300,
            height: 180,
            child: SurfaceContainer(
              motion: ResolvedMotion.immediate,
              decoration: BoxDecoration(
                color: context.colors.surfaceRaised,
                borderRadius: BorderRadius.circular(context.shapes.large),
              ),
              padding: EdgeInsets.all(context.spacing.space4),
              child: const Text("Publish to the realm"),
            ),
          ),
        ),
      ),
    );
  }
}

/// A status word whose letters move one after another.
class _WordDemo extends StatelessWidget {
  const _WordDemo({required this.token});

  final MotionToken<LetterLanding> token;

  @override
  Widget build(BuildContext context) {
    const word = "Publishing";
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var index = 0; index < word.length; index++)
          _Letter(letter: word[index], index: index, token: token),
      ],
    );
  }
}

class _Letter extends HookWidget {
  const _Letter({
    required this.letter,
    required this.index,
    required this.token,
  });

  final String letter;
  final int index;
  final MotionToken<LetterLanding> token;

  @override
  Widget build(BuildContext context) {
    final resolved = resolveMotion(context, token);
    final landing = resolved.landing;
    final started = _useStarted(landing.letterGap * (index + 1));
    final passed = useState(false);
    final loops = resolved.motion is LoopMotion;
    useEffect(() {
      if (!started || loops) return null;
      final timer = Timer(
        resolved.motion.duration ~/ 2,
        () => passed.value = true,
      );
      return timer.cancel;
    }, [started]);
    final up = started && (loops || !passed.value);
    final value = useMotion(token, up ? 1 : 0).value;
    final lift = resolved.still ? 0.0 : value;
    final style = Theme.of(context).textTheme.titleLarge;
    return Transform.translate(
      offset: Offset(0, -landing.rise * lift),
      child: Text(
        letter,
        style: style?.copyWith(
          color: landing.tint
              ? Color.lerp(
                  context.colors.contentPrimary,
                  context.colors.brand,
                  value.clamp(0.0, 1.0),
                )
              : null,
        ),
      ),
    );
  }
}

/// A button label that types from Publish to Publishing and back.
class _TypeDemo extends HookWidget {
  const _TypeDemo();

  @override
  Widget build(BuildContext context) {
    final busy = useState(false);
    useEffect(() {
      final timer = Timer.periodic(const Duration(milliseconds: 1200), (timer) {
        busy.value = !busy.value;
        if (timer.tick >= 3) timer.cancel();
      });
      return timer.cancel;
    }, const []);
    final text = busy.value ? "Publishing" : "Publish";
    final count = useTyping(text);
    return Align(
      alignment: Alignment.topLeft,
      child: FilledButton(
        onPressed: () {},
        child: Text(text.substring(0, count)),
      ),
    );
  }
}

/// Placeholder rows with a shimmer sweeping over them.
class _SkeletonDemo extends HookWidget {
  const _SkeletonDemo();

  @override
  Widget build(BuildContext context) {
    final resolved = resolveMotion(context, MotionToken.skeleton);
    final sweep = useMotion(MotionToken.skeleton, 1, initial: 0).value;
    final base = context.colors.surfaceRaised;
    final shine = context.colors.surfaceEmphasized;
    return Column(
      children: [
        for (var row = 0; row < 4; row++)
          Padding(
            padding: EdgeInsets.only(bottom: context.spacing.space2),
            child: Container(
              height: 32,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(context.shapes.medium),
                gradient: resolved.still
                    ? null
                    : LinearGradient(
                        begin: Alignment(-1 + 3 * sweep - 1, 0),
                        end: Alignment(1 + 3 * sweep - 1, 0),
                        colors: [base, shine, base],
                      ),
                color: resolved.still ? base : null,
              ),
            ),
          ),
      ],
    );
  }
}

/// A row fill that fades for a change of yours and one by someone else.
class _InkDemo extends HookWidget {
  const _InkDemo();

  @override
  Widget build(BuildContext context) {
    final faded = _useStarted(const Duration(milliseconds: 300));
    final landing = resolveMotion(context, MotionToken.ink).landing;
    final mine = useMotion(MotionToken.ink, faded ? 0 : 1).value;
    final others = useMotion(
      MotionToken.ink,
      faded ? 0 : 1,
      override: MotionOverride(duration: landing.byOthers),
    ).value;
    Color fill(double value) => context.colors.selectionContainer.withValues(
      alpha: value.clamp(0.0, 1.0),
    );
    return Column(
      children: [
        _LabRow("You renamed Ada", fill: fill(mine)),
        _LabRow("Ben renamed Cleo", fill: fill(others)),
      ],
    );
  }
}

/// A countdown bar that empties in real time.
class _DrainDemo extends HookWidget {
  const _DrainDemo();

  @override
  Widget build(BuildContext context) {
    final left = useMotion(MotionToken.drain, 0, initial: 1).value;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Undo"),
        SizedBox(height: context.spacing.space2),
        ClipRRect(
          borderRadius: BorderRadius.circular(context.shapes.small),
          child: SizedBox(
            height: 4,
            child: Align(
              alignment: Alignment.centerLeft,
              child: FractionallySizedBox(
                widthFactor: left.clamp(0.0, 1.0),
                child: ColoredBox(color: context.colors.brand),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// A Publish button that jams: it shakes and flashes red.
class _JamDemo extends HookWidget {
  const _JamDemo();

  @override
  Widget build(BuildContext context) {
    final jam = resolveMotion(context, MotionToken.jam);
    final landing = jam.landing;
    final jammed = _useStarted(const Duration(milliseconds: 300));
    final shake = useMotionController();
    useEffect(() {
      if (jammed) shake.play(jam);
      return null;
    }, [jammed]);
    // The flash fades like ink, which reduced motion keeps.
    final flash = useMotion(
      MotionToken.ink,
      jammed ? 0 : 1,
      override: MotionOverride(duration: landing.flash),
    );
    final shown = jammed ? flash.value.clamp(0.0, 1.0) : 0.0;
    return Align(
      alignment: Alignment.topLeft,
      child: AnimatedBuilder(
        animation: shake,
        builder: (context, child) => Transform.translate(
          offset: Offset(landing.amplitude * shake.value, 0),
          child: child,
        ),
        child: DecoratedBox(
          position: DecorationPosition.foreground,
          decoration: BoxDecoration(
            color: context.colors.danger.withValues(alpha: 0.6 * shown),
            borderRadius: BorderRadius.circular(context.shapes.medium),
          ),
          child: FilledButton(onPressed: () {}, child: const Text("Publish")),
        ),
      ),
    );
  }
}
