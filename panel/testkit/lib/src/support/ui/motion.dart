import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/src/drivers/component_driver.dart";
import "package:typewriter_testkit/src/drivers/panel_driver.dart";
import "package:typewriter_testkit/src/support/shown_component.dart";
import "package:typewriter_testkit/src/support/ui/probes.dart";
import "package:typewriter_testkit/src/support/ui/reduced_motion.dart";

/// A 20 px box named [label] that sits [target] times 100 px right of its
/// start, moved there by [token]. With [loop] it plays the token once on
/// mount, from 0 to [target]. Once the value rests on its target, the text
/// "[label] settled" shows below the box.
final class MotionProbe extends HookWidget {
  const MotionProbe({
    required this.token,
    required this.target,
    this.label = "probe",
    this.loop = false,
    super.key,
  });

  final MotionToken<Landing> token;
  final double target;
  final String label;
  final bool loop;

  @override
  Widget build(BuildContext context) {
    final value = useMotion(token, target, initial: loop ? 0 : null);
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Transform.translate(
          offset: Offset(value.value * 100, 0),
          child: LabeledBox(label, width: 20, height: 20),
        ),
        if (value.settled)
          Positioned(
            top: 24,
            left: 0,
            child: Text("$label settled", softWrap: false),
          ),
      ],
    );
  }
}

/// The letters of [text] shown so far while it types with the `type` token.
final class TypingProbe extends HookWidget {
  const TypingProbe(this.text, {this.typesIn = false, super.key});

  final String text;
  final bool typesIn;

  @override
  Widget build(BuildContext context) {
    final count = useTyping(text, typesIn: typesIn);
    return Text(text.substring(0, count));
  }
}

/// A 20 px box named "probe" that sits [target] times 100 px right of its
/// start, moved there by the move [states] pick. [onMotion] hears the motion
/// each build plays.
final class StateMotionProbe extends HookWidget {
  const StateMotionProbe({
    required this.states,
    required this.target,
    required this.onMotion,
    this.overrideFor,
    super.key,
  });

  final Set<WidgetState> states;
  final double target;
  final void Function(ResolvedMotion<Landing> motion) onMotion;
  final MotionOverride? Function(MotionToken<Landing> move)? overrideFor;

  @override
  Widget build(BuildContext context) {
    final motion = useStateMotion(
      states,
      target: target,
      overrideFor: overrideFor,
    );
    onMotion(motion);
    final value = useMotionValue(
      motion,
      target,
      lerp: (from, to, t) => from + (to - from) * t,
    );
    return Transform.translate(
      offset: Offset(value * 100, 0),
      child: const LabeledBox("probe", width: 20, height: 20),
    );
  }
}

/// A box named "probe" placed at [target] in a 400 by 400 area, moved there
/// with [token].
final class RectMotionProbe extends HookWidget {
  const RectMotionProbe({required this.token, required this.target, super.key});

  final MotionToken<Landing> token;
  final Rect target;

  @override
  Widget build(BuildContext context) {
    final shown = useMotionValue(
      resolveMotion(context, token),
      target,
      lerp: (from, to, t) => Rect.lerp(from, to, t)!,
    );
    return SizedBox(
      width: 400,
      height: 400,
      child: Stack(
        children: [
          Positioned.fromRect(rect: shown, child: const LabeledBox("probe")),
        ],
      ),
    );
  }
}

/// A 120 by 36 control named "Publish" in a [Rise] that is [raised], or
/// driven to [progress]. With [filled] it shows [fill] as its still state.
final class RiseStage extends StatelessWidget {
  const RiseStage({
    this.raised = false,
    this.filled = false,
    this.progress,
    super.key,
  });

  /// The fill a [filled] stage shows under reduced motion.
  static const fill = Color(0xFF3A3F47);

  final bool raised;
  final bool filled;
  final double? progress;

  @override
  Widget build(BuildContext context) {
    final progress = this.progress;
    return Rise(
      raised: raised,
      progress: progress == null ? null : AlwaysStoppedAnimation(progress),
      stillFill: filled ? fill : null,
      child: const LabeledBox("Publish", width: 120, height: 36),
    );
  }
}

/// [rows] boxes "row 1", "row 2" and on, each 200 by 20 in an [Enter] with
/// [token], inside an [EnterRun] when [run]. With [progress] the rows are
/// driven to it.
final class EnterStage extends StatelessWidget {
  const EnterStage({
    this.rows = 1,
    this.token = MotionToken.loadIn,
    this.run = true,
    this.progress,
    super.key,
  });

  final int rows;
  final MotionToken<EnterLanding> token;
  final bool run;
  final double? progress;

  @override
  Widget build(BuildContext context) {
    final progress = this.progress;
    final column = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var row = 1; row <= rows; row++)
          Enter(
            token: token,
            progress: progress == null
                ? null
                : AlwaysStoppedAnimation(progress),
            child: LabeledBox("row $row", width: 200, height: 20),
          ),
      ],
    );
    return run ? EnterRun(child: column) : column;
  }
}

/// Two loadIn rows in one run: "high" placed above "low", although "low"
/// is built first.
final class EnterOrderStage extends StatelessWidget {
  const EnterOrderStage({super.key});

  @override
  Widget build(BuildContext context) {
    return const EnterRun(
      child: SizedBox(
        width: 200,
        height: 100,
        child: Stack(
          children: [
            Positioned(
              top: 60,
              child: Enter(
                token: MotionToken.loadIn,
                child: LabeledBox("low", width: 200, height: 20),
              ),
            ),
            Positioned(
              top: 0,
              child: Enter(
                token: MotionToken.loadIn,
                child: LabeledBox("high", width: 200, height: 20),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A table of two rows whose cells "row n name" and "row n role" load in
/// one run, each row as one group.
final class EnterGroupStage extends StatelessWidget {
  const EnterGroupStage({super.key});

  @override
  Widget build(BuildContext context) {
    return EnterRun(
      child: SizedBox(
        width: 200,
        child: Table(
          children: [
            for (final row in ["row 1", "row 2"])
              TableRow(
                children: [
                  for (final cell in ["name", "role"])
                    Enter(
                      token: MotionToken.loadIn,
                      group: row,
                      child: LabeledBox("$row $cell", height: 20),
                    ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

/// A row named "Ada" that fills while the "Remove" box is pressed and
/// shows "Removed n" after the n-th completed hold.
final class HoldStage extends HookWidget {
  const HoldStage({super.key});

  @override
  Widget build(BuildContext context) {
    final removed = useState(0);
    final vsync = useTickerProvider();
    final clock = useMemoized(
      () => HoldClock(vsync: vsync, onComplete: () => removed.value++),
    );
    useEffect(() => clock.dispose, [clock]);
    final hold = resolveMotion(context, MotionToken.hold);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        HoldFill(
          fill: clock.fill,
          child: const LabeledBox("Ada", width: 200, height: 42),
        ),
        Listener(
          behavior: HitTestBehavior.opaque,
          onPointerDown: (_) => clock.press(hold),
          onPointerUp: (_) => clock.release(),
          onPointerCancel: (_) => clock.release(),
          child: const LabeledBox("Remove", width: 80, height: 32),
        ),
        if (removed.value > 0) Text("Removed ${removed.value}"),
      ],
    );
  }
}

/// Rows "Ada" and "Ben" from the top of a fixed area; while [leaving], Ada
/// plays listOut through Leave.
final class LeaveStage extends HookWidget {
  const LeaveStage({required this.leaving, super.key});

  final bool leaving;

  @override
  Widget build(BuildContext context) {
    final progress = useMotion(MotionToken.listOut, leaving ? 0 : 1);
    return SizedBox(
      width: 200,
      height: 84,
      child: Column(
        children: [
          Leave(
            progress: progress,
            child: const LabeledBox("Ada", width: 200, height: 42),
          ),
          const LabeledBox("Ben", width: 200, height: 42),
        ],
      ),
    );
  }
}

/// [child] under one Ring that follows primary focus, the way the theme
/// PR's FocusRingLayer does. Unless [follows], the ring has no target.
final class RingStage extends HookWidget {
  const RingStage({required this.child, this.follows = true, super.key});

  final Widget child;
  final bool follows;

  @override
  Widget build(BuildContext context) {
    final target = useState<RingGeometry?>(null);
    useEffect(() {
      void follow() {
        final node = FocusManager.instance.primaryFocus;
        target.value = node == null ? null : RingTarget.geometryOf(node);
      }

      FocusManager.instance.addListener(follow);
      return () => FocusManager.instance.removeListener(follow);
    }, const []);
    return Stack(
      children: [
        child,
        Positioned.fill(
          child: IgnorePointer(
            child: Ring(target: follows ? target.value : null),
          ),
        ),
      ],
    );
  }
}

/// A focusable row named [label] that a ring wraps.
final class _RingRow extends StatelessWidget {
  const _RingRow(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return RingTarget(
      borderRadius: BorderRadius.circular(context.shapes.medium),
      child: Focus(child: LabeledBox(label, width: 160, height: 32)),
    );
  }
}

/// Two panes of focusable rows, "left 1" to "left 4" and "right 1" to
/// "right 4", and a focusable box "bare" that marks no ring target.
final class RingPanes extends StatelessWidget {
  const RingPanes({super.key});

  @override
  Widget build(BuildContext context) {
    final gap = SizedBox(height: context.spacing.space2);
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var row = 1; row <= 4; row++) ...[_RingRow("left $row"), gap],
            const Focus(child: LabeledBox("bare", width: 160, height: 32)),
          ],
        ),
        SizedBox(width: context.spacing.space10),
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var row = 1; row <= 4; row++) ...[_RingRow("right $row"), gap],
          ],
        ),
      ],
    );
  }
}

/// A table of members Ada and Ben with cells "Ada name", "Ada role" and
/// "Ada email"; each name cell rings its whole row.
final class RingTable extends StatelessWidget {
  const RingTable({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 360,
      child: Table(
        children: [
          for (final member in ["Ada", "Ben"])
            TableRow(
              children: [
                RingTarget(
                  bounds: RingBounds.tableRow,
                  child: Focus(child: LabeledBox("$member name", height: 30)),
                ),
                LabeledBox("$member role", height: 30),
                LabeledBox("$member email", height: 30),
              ],
            ),
        ],
      ),
    );
  }
}

/// A 300 px high list of focusable rows "item 1" to "item 20", each 40 px.
final class RingScrollList extends StatelessWidget {
  const RingScrollList({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 200,
      height: 300,
      child: ListView(
        children: [
          for (var item = 1; item <= 20; item++)
            RingTarget(
              child: Focus(child: LabeledBox("item $item", height: 40)),
            ),
        ],
      ),
    );
  }
}

/// 1001 evenly spaced samples of [at] from [from] to [to].
List<double> curveSamples(
  double Function(double) at, {
  double from = 0,
  double to = 1,
}) => [for (var i = 0; i <= 1000; i++) at(from + (to - from) * i / 1000)];

/// The rect the ring surrounds on screen, or null while it is hidden.
Rect? ringedRect(WidgetTester tester) {
  final ring = find.byKey(Ring.ringKey);
  if (ring.evaluate().isEmpty) return null;
  return tester.getRect(ring).deflate(tester.element(ring).shapes.ringWidth);
}

/// Reads [read] in a context under the panel theme, with reduced motion when
/// [reduced] and [table] in place of the standard one.
Future<T> readInMotionTheme<T>(
  WidgetTester tester,
  T Function(BuildContext context) read, {
  bool reduced = false,
  TypewriterMotion? table,
  Brightness brightness = Brightness.light,
}) async {
  late T result;
  final probe = Builder(
    builder: (context) {
      result = read(context);
      return const SizedBox.shrink();
    },
  );
  await tester.pumpWidget(
    MediaQuery(
      data: MediaQueryData(disableAnimations: reduced),
      child: Theme(
        data: buildTheme(brightness, motion: table),
        child: probe,
      ),
    ),
  );
  return result;
}

/// Resolves [token] the way a widget under the panel theme does, with
/// reduced motion when [reduced] and [table] in place of the standard one.
Future<ResolvedMotion<L>> resolveMotionIn<L extends Landing>(
  WidgetTester tester,
  MotionToken<L> token, {
  bool reduced = false,
  MotionOverride? override,
  TypewriterMotion? table,
  Brightness brightness = Brightness.light,
}) => readInMotionTheme(
  tester,
  (context) => resolveMotion(context, token, override: override),
  reduced: reduced,
  table: table,
  brightness: brightness,
);

/// Driving time frame by frame.
extension RunFrames on WidgetTester {
  /// Renders a frame every [frame] until [total] passed, the way a running
  /// animation sees time.
  Future<void> runFrames(
    Duration total, {
    Duration frame = const Duration(milliseconds: 16),
  }) async {
    var passed = Duration.zero;
    while (passed < total) {
      final step = total - passed < frame ? total - passed : frame;
      await pump(step);
      passed += step;
    }
  }
}

/// Starting a [MotionProbe] on its way.
extension MotionProbeDriving on WidgetTester {
  /// Mounts a [MotionProbe] for [token] at 0 and sends it to 1, rendering
  /// only the frame that starts the move. Returns the panel and where the
  /// probe started.
  Future<(PanelDriver, double)> startProbe(MotionToken<Landing> token) async {
    final panel = await mountComponent(MotionProbe(token: token, target: 0));
    final start = panel.boundsOf("probe").left;
    await showComponent(MotionProbe(token: token, target: 1), settle: false);
    return (panel, start);
  }
}

/// Holding the "Remove" box of a [HoldStage].
extension HoldDriving on WidgetTester {
  /// The hold token's time, read from the table.
  Future<Duration> holdTime() async =>
      (await resolveMotionIn(this, MotionToken.hold)).motion.duration;

  /// Mounts a [HoldStage], with reduced motion when [reduced], and presses
  /// its "Remove" box down.
  Future<(PanelDriver, TestGesture)> holdDown({bool reduced = false}) async {
    final panel = await mountComponent(
      reduced ? const ReducedMotion(child: HoldStage()) : const HoldStage(),
    );
    final gesture = await startGesture(panel.boundsOf("Remove").center);
    await pump();
    return (panel, gesture);
  }
}

/// Focus and fills a ring or a control shows.
extension MotionGeometry on ComponentDriver {
  /// Puts keyboard focus on the focusable box [label] and renders a frame.
  Future<void> focusOn(String label) async {
    Focus.of(tester.element(box(label))).requestFocus();
    FocusManager.instance.applyFocusChangesIfNeeded();
    await tester.pump();
  }

  /// The fill painted right behind the box [label], or null when none is.
  Color? fillBehind(String label) {
    final behind = find.ancestor(
      of: box(label),
      matching: find.byType(DecoratedBox),
    );
    if (behind.evaluate().isEmpty) return null;
    return switch (tester.widget<DecoratedBox>(behind.first).decoration) {
      BoxDecoration(:final color) => color,
      _ => null,
    };
  }
}

/// Motion inside the routed panel.
extension MotionOnPage on PanelDriver {
  /// Resolves [token] the way a widget on the routed page does.
  ResolvedMotion<L> resolveOnPage<L extends Landing>(MotionToken<L> token) {
    final page = find.descendant(
      of: find.byType(Navigator),
      matching: find.byType(Overlay),
    );
    return resolveMotion(tester.element(page.first), token);
  }
}

/// How long motion tokens take in the shown panel.
extension MotionTimes on WidgetTester {
  /// The time [token] takes from 0 to 1 in the shown panel, overrides and
  /// reduced motion aside: one period for a loop, otherwise until its
  /// simulation is done.
  Duration settleTimeOf(MotionToken<Landing> token) {
    final page = find.byType(Overlay).first;
    final resolved = resolveMotion(element(page), token);
    if (resolved.motion case LoopMotion(:final period)) return period;
    final simulation = resolved.simulate(from: 0, to: 1);
    const step = Duration(milliseconds: 1);
    var elapsed = Duration.zero;
    while (!simulation.isDone(elapsed.inMicroseconds / 1e6) &&
        elapsed < const Duration(seconds: 10)) {
      elapsed += step;
    }
    return elapsed;
  }
}
