import "package:typewriter_panel/typewriter_panel.dart";

// Written by cargo xtask generate.
part "typewriter_motion.freezed.dart";

/// What a token keeps when the platform asks for reduced motion.
enum ReducedKind {
  /// Lands at once: the result appears with no travel.
  jump,

  /// The travel never starts. A control shows the state as a fill instead:
  /// hover brightens one step, press darkens while down, jam keeps its red
  /// flash without the shake, a key cap appears in place.
  still,

  /// Keeps its time and drops travel: a hold fills in place, drain empties
  /// in place, text types.
  paced,
}

/// The landing values a primitive reads beside a token's motion. A Freezed
/// union (the part file is `typewriter_motion.freezed.dart`), so each case
/// is its own type for `MotionToken<L>` and has value equality.
@freezed
sealed class Landing with _$Landing {
  /// A token whose motion is all there is.
  const factory Landing.none() = NoLanding;

  /// Rises [rise] px and grows to [scale] at the top.
  const factory Landing.rise({required double rise, @Default(1) double scale}) =
      RiseLanding;

  /// A surface grows from its opener, starting at [originScale]; the page
  /// behind scales to [behindScale].
  const factory Landing.surface({
    @Default(1) double originScale,
    @Default(1) double behindScale,
  }) = SurfaceLanding;

  /// The focused pane scales to [active] and brightens by [wash] (an
  /// opacity of contentPrimary); the others scale to [inactive].
  const factory Landing.pane({
    required double active,
    required double inactive,
    required double wash,
  }) = PaneLanding;

  /// Arrives from [from] px away. In a group, [stagger] spaces the starts.
  const factory Landing.enter({required Offset from, Stagger? stagger}) =
      EnterLanding;

  /// Sinks [sink] px and shrinks to [scale] while down.
  const factory Landing.press({required double sink, required double scale}) =
      PressLanding;

  /// Each letter rises [rise] px, [letterGap] after the one before; [tint]
  /// turns it brand blue while it passes.
  const factory Landing.letter({
    required double rise,
    required Duration letterGap,
    @Default(false) bool tint,
  }) = LetterLanding;

  /// Ink fades with the token's motion, or over [byOthers] for a change
  /// someone else made.
  const factory Landing.ink({required Duration byOthers}) = InkLanding;

  /// A held button sinks from [sinkFrom] px to [sink] px and shrinks to
  /// [scale] as the hold fills. Between [trembleFrom] and [trembleTo] of the
  /// hold's time it trembles once, [tremble] px to each side.
  const factory Landing.hold({
    required double sinkFrom,
    required double sink,
    required double scale,
    required double trembleFrom,
    required double trembleTo,
    required double tremble,
  }) = HoldLanding;

  /// The jam swings [amplitude] px; its red flash fades over [flash].
  const factory Landing.jam({
    required double amplitude,
    required Duration flash,
  }) = JamLanding;
}

/// When each member of a group starts: every [interval], or spread evenly
/// when no interval is given, and never later than [within].
@freezed
abstract class Stagger with _$Stagger {
  const factory Stagger({required Duration within, Duration? interval}) =
      _Stagger;

  const Stagger._();

  /// The start delay of the member at [index] of [count].
  Duration delayOf(int index, int count) {
    if (count <= 1 || index <= 0) return Duration.zero;
    final each = interval ?? within ~/ (count - 1);
    final delay = each * index;
    return delay > within ? within : delay;
  }
}

/// A named move from the token table. Its type argument names the
/// landing its primitive reads.
@immutable
final class MotionToken<L extends Landing> {
  const MotionToken._(this.name);

  /// The name used in the skill, the lab and the service contract.
  final String name;

  static const panelIn = MotionToken<SurfaceLanding>._("panelIn");
  static const surfaceIn = MotionToken<SurfaceLanding>._("surfaceIn");
  static const paneFocus = MotionToken<PaneLanding>._("paneFocus");
  static const dialogIn = MotionToken<SurfaceLanding>._("dialogIn");
  static const focusMove = MotionToken<NoLanding>._("focusMove");
  static const hoverIn = MotionToken<RiseLanding>._("hoverIn");
  static const capIn = MotionToken<RiseLanding>._("capIn");
  static const loadIn = MotionToken<EnterLanding>._("loadIn");
  static const rowIn = MotionToken<EnterLanding>._("rowIn");
  static const press = MotionToken<PressLanding>._("press");
  static const splash = MotionToken<NoLanding>._("splash");
  static const hoverOut = MotionToken<NoLanding>._("hoverOut");
  static const panelOut = MotionToken<NoLanding>._("panelOut");
  static const dialogOut = MotionToken<NoLanding>._("dialogOut");
  static const listOut = MotionToken<NoLanding>._("listOut");

  /// A hold that loses only the user's own unsent work: Discard.
  static const holdLight = MotionToken<HoldLanding>._("holdLight");

  /// A hold that makes someone else act again: Remove member, Revoke.
  static const holdHeavy = MotionToken<HoldLanding>._("holdHeavy");

  /// A hold nothing can recover from: deleting a Realm resource.
  static const holdPermanent = MotionToken<HoldLanding>._("holdPermanent");
  static const ripple = MotionToken<LetterLanding>._("ripple");
  static const skeleton = MotionToken<NoLanding>._("skeleton");
  static const wave = MotionToken<LetterLanding>._("wave");
  static const waveSlow = MotionToken<LetterLanding>._("waveSlow");
  static const drain = MotionToken<NoLanding>._("drain");
  static const type = MotionToken<NoLanding>._("type");
  static const ink = MotionToken<InkLanding>._("ink");
  static const jam = MotionToken<JamLanding>._("jam");

  /// Every token, in the skill's table order.
  static const List<MotionToken<Landing>> values = [
    panelIn,
    surfaceIn,
    paneFocus,
    dialogIn,
    focusMove,
    hoverIn,
    capIn,
    loadIn,
    rowIn,
    press,
    splash,
    hoverOut,
    panelOut,
    dialogOut,
    listOut,
    holdLight,
    holdHeavy,
    holdPermanent,
    ripple,
    skeleton,
    wave,
    waveSlow,
    drain,
    type,
    ink,
    jam,
  ];

  @override
  String toString() => name;
}

/// One row of the token table.
@immutable
final class MotionSpec<L extends Landing> {
  const MotionSpec(this.motion, this.landing, {required this.reduced});

  final Motion motion;
  final L landing;
  final ReducedKind reduced;

  MotionSpec<L> copyWith({Motion? motion, L? landing}) => MotionSpec(
    motion ?? this.motion,
    landing ?? this.landing,
    reduced: reduced,
  );
}

MapEntry<MotionToken<Landing>, MotionSpec<Landing>> _row<L extends Landing>(
  MotionToken<L> token,
  MotionSpec<L> spec,
) => MapEntry(token, spec);

/// A hold row: the fill springs over the whole hold and leads the clock;
/// the clock decides. Every weight shares the look and differs in time.
MapEntry<MotionToken<Landing>, MotionSpec<Landing>> _holdRow(
  MotionToken<HoldLanding> token,
  Duration duration,
) => _row(
  token,
  MotionSpec(
    HoldMotion(
      // candidate ratio: the skill gives only the settle time.
      fill: SpringMotion.settling(duration, dampingRatio: 0.8),
      duration: duration,
    ),
    // candidate tremble: the skill names its window, not its size.
    const HoldLanding(
      sinkFrom: 1,
      sink: 4,
      scale: 0.95,
      trembleFrom: 0.86,
      trembleTo: 0.96,
      tremble: 2,
    ),
    reduced: ReducedKind.paced,
  ),
);

/// The panel's motion tokens, installed by `buildTheme`.
@immutable
class TypewriterMotion extends ThemeExtension<TypewriterMotion> {
  TypewriterMotion._(this._specs, {required this.repeatFloor})
    : assert(
        MotionToken.values.every(_specs.containsKey),
        "every motion token has a row",
      ),
      // Readers rely on these shapes without a reduced motion check.
      assert(_specs[MotionToken.ripple]!.motion is LoopMotion),
      assert(_specs[MotionToken.skeleton]!.motion is LoopMotion),
      assert(_specs[MotionToken.type]!.motion is StepMotion),
      assert(_specs[MotionToken.jam]!.motion is JudderMotion);

  /// The token table of the panel-design skill. Each value is a starting
  /// candidate until a maintainer picks it in the motion lab.
  factory TypewriterMotion.standard() => TypewriterMotion._(
    Map.fromEntries([
      _row(
        MotionToken.panelIn,
        const MotionSpec(
          CurveMotion(
            StrikeCurve(overshoot: 0.10),
            Duration(milliseconds: 420),
          ),
          // candidate start scale for popovers and the search overlay.
          SurfaceLanding(originScale: 0.92),
          reduced: ReducedKind.jump,
        ),
      ),
      _row(
        MotionToken.surfaceIn,
        const MotionSpec(
          SpringMotion(stiffness: 280, damping: 17),
          SurfaceLanding(),
          reduced: ReducedKind.jump,
        ),
      ),
      _row(
        MotionToken.paneFocus,
        const MotionSpec(
          SpringMotion(stiffness: 300, damping: 13),
          // candidate wash: contentPrimary at 4%.
          PaneLanding(active: 1.03, inactive: 0.985, wash: 0.04),
          reduced: ReducedKind.jump,
        ),
      ),
      _row(
        MotionToken.dialogIn,
        const MotionSpec(
          CurveMotion(
            StrikeCurve(overshoot: 0.14),
            Duration(milliseconds: 340),
          ),
          // candidate start scale; the page behind is the skill's 0.98.
          SurfaceLanding(originScale: 0.94, behindScale: 0.98),
          reduced: ReducedKind.jump,
        ),
      ),
      _row(
        MotionToken.focusMove,
        const MotionSpec(
          CurveMotion(
            StrikeCurve(overshoot: 0.05),
            Duration(milliseconds: 170),
          ),
          NoLanding(),
          reduced: ReducedKind.jump,
        ),
      ),
      _row(
        MotionToken.hoverIn,
        const MotionSpec(
          // candidate: the skill says one overshoot without an amount.
          CurveMotion(
            StrikeCurve(overshoot: 0.10),
            Duration(milliseconds: 220),
          ),
          RiseLanding(rise: 2, scale: 1.012),
          reduced: ReducedKind.still,
        ),
      ),
      _row(
        MotionToken.capIn,
        const MotionSpec(
          // candidate: the skill says one overshoot without an amount.
          CurveMotion(
            StrikeCurve(overshoot: 0.10),
            Duration(milliseconds: 240),
          ),
          RiseLanding(rise: 9),
          reduced: ReducedKind.still,
        ),
      ),
      _row(
        MotionToken.loadIn,
        const MotionSpec(
          // candidate overshoot; the starts spread evenly within 150 ms.
          CurveMotion(
            StrikeCurve(overshoot: 0.10),
            Duration(milliseconds: 190),
          ),
          EnterLanding(
            from: Offset(0, 14),
            stagger: Stagger(within: Duration(milliseconds: 150)),
          ),
          reduced: ReducedKind.jump,
        ),
      ),
      _row(
        MotionToken.rowIn,
        const MotionSpec(
          CurveMotion(
            CarriageCurve(hit: 0.42, recoil: 0.06),
            Duration(milliseconds: 280),
          ),
          // candidate: the skill names no travel distance.
          EnterLanding(from: Offset(-24, 0)),
          reduced: ReducedKind.jump,
        ),
      ),
      _row(
        MotionToken.press,
        const MotionSpec(
          SpringMotion(stiffness: 300, damping: 12),
          PressLanding(sink: 4, scale: 0.93),
          reduced: ReducedKind.still,
        ),
      ),
      _row(
        MotionToken.splash,
        const MotionSpec(
          CurveMotion(Cubic(0.2, 0.9, 0.3, 1), Duration(milliseconds: 450)),
          NoLanding(),
          reduced: ReducedKind.still,
        ),
      ),
      _row(
        MotionToken.hoverOut,
        const MotionSpec(
          CurveMotion(exitCurve, Duration(milliseconds: 90)),
          NoLanding(),
          reduced: ReducedKind.still,
        ),
      ),
      _row(
        MotionToken.panelOut,
        const MotionSpec(
          CurveMotion(exitCurve, Duration(milliseconds: 200)),
          NoLanding(),
          reduced: ReducedKind.jump,
        ),
      ),
      _row(
        MotionToken.dialogOut,
        const MotionSpec(
          CurveMotion(exitCurve, Duration(milliseconds: 150)),
          NoLanding(),
          reduced: ReducedKind.jump,
        ),
      ),
      _row(
        MotionToken.listOut,
        const MotionSpec(
          SpringMotion(stiffness: 380, damping: 30),
          NoLanding(),
          reduced: ReducedKind.jump,
        ),
      ),
      _holdRow(MotionToken.holdLight, const Duration(milliseconds: 1200)),
      _holdRow(MotionToken.holdHeavy, const Duration(milliseconds: 1800)),
      _holdRow(MotionToken.holdPermanent, const Duration(milliseconds: 2600)),
      _row(
        MotionToken.ripple,
        const MotionSpec(
          LoopMotion(
            curve: Curves.easeInOut,
            period: Duration(milliseconds: 620),
          ),
          LetterLanding(rise: 3, letterGap: Duration(milliseconds: 42)),
          reduced: ReducedKind.still,
        ),
      ),
      _row(
        MotionToken.skeleton,
        // candidate: today's shimmer sweep, shimmer.dart:109. A decorative
        // loop, so a test world's table caps it like ripple.
        const MotionSpec(
          LoopMotion(
            curve: Curves.linear,
            period: Duration(milliseconds: 1000),
          ),
          NoLanding(),
          reduced: ReducedKind.still,
        ),
      ),
      _row(
        MotionToken.wave,
        MotionSpec(
          // candidate ratio: the skill gives only the 420 ms.
          SpringMotion.settling(Duration(milliseconds: 420), dampingRatio: 0.5),
          const LetterLanding(
            rise: 4,
            letterGap: Duration(milliseconds: 34),
            tint: true,
          ),
          reduced: ReducedKind.jump,
        ),
      ),
      _row(
        MotionToken.waveSlow,
        const MotionSpec(
          CurveMotion(Curves.easeInOut, Duration(milliseconds: 1000)),
          LetterLanding(
            rise: 2,
            letterGap: Duration(milliseconds: 60),
            tint: true,
          ),
          reduced: ReducedKind.jump,
        ),
      ),
      _row(
        MotionToken.drain,
        const MotionSpec(
          CurveMotion(Curves.linear, Duration(seconds: 6)),
          NoLanding(),
          reduced: ReducedKind.paced,
        ),
      ),
      _row(
        MotionToken.type,
        const MotionSpec(
          StepMotion(Duration(milliseconds: 36)),
          NoLanding(),
          reduced: ReducedKind.paced,
        ),
      ),
      _row(
        MotionToken.ink,
        const MotionSpec(
          CurveMotion(Curves.easeOut, Duration(milliseconds: 900)),
          InkLanding(byOthers: Duration(seconds: 2)),
          reduced: ReducedKind.paced,
        ),
      ),
      _row(
        MotionToken.jam,
        const MotionSpec(
          JudderMotion(duration: Duration(milliseconds: 400), cycles: 4),
          JamLanding(amplitude: 9, flash: Duration(milliseconds: 1500)),
          reduced: ReducedKind.still,
        ),
      ),
    ]),
    // candidate: a repeat sooner than a quarter of its move jumps.
    repeatFloor: 0.25,
  );

  final Map<MotionToken<Landing>, MotionSpec<Landing>> _specs;

  /// A move that repeats sooner than this share of its duration jumps;
  /// a slower repeat shortens in proportion.
  final double repeatFloor;

  /// The row for [token].
  MotionSpec<L> spec<L extends Landing>(MotionToken<L> token) =>
      _specs[token]! as MotionSpec<L>;

  /// This table with [token]'s row replaced, as the motion lab shows it.
  TypewriterMotion withSpec<L extends Landing>(
    MotionToken<L> token,
    MotionSpec<L> spec,
  ) => TypewriterMotion._({..._specs, token: spec}, repeatFloor: repeatFloor);

  @override
  TypewriterMotion copyWith({double? repeatFloor}) =>
      TypewriterMotion._(_specs, repeatFloor: repeatFloor ?? this.repeatFloor);

  /// Motion is not interpolated between themes; it switches halfway.
  @override
  TypewriterMotion lerp(covariant TypewriterMotion? other, double t) =>
      other == null || t < 0.5 ? this : other;
}

/// A curve a service sends in place of the token's own.
@freezed
sealed class MotionShape with _$MotionShape {
  /// A curve that runs over a duration.
  const factory MotionShape.timed(Curve curve) = TimedShape;

  /// A spring that settles by itself; a duration beside it is ignored.
  const factory MotionShape.spring({
    required double stiffness,
    required double damping,
  }) = SpringShape;

  /// The named curves a service may send besides strike and carriage.
  static const MotionShape linear = TimedShape(Curves.linear);
  static const MotionShape exit = TimedShape(exitCurve);
  static const MotionShape easeOut = TimedShape(Curves.easeOut);
}

/// What a service sends beside a named move. Missing values fall back to
/// the token.
@freezed
abstract class MotionOverride with _$MotionOverride {
  const factory MotionOverride({Duration? duration, MotionShape? curve}) =
      _MotionOverride;

  const MotionOverride._();

  /// The token's [token] motion with this override applied.
  Motion applyTo(Motion token) {
    if (duration == Duration.zero && curve is! SpringShape) {
      return Motion.instant;
    }
    return switch ((curve, duration)) {
      // A sent spring plays as sent; its settle time is its own.
      (SpringShape(:final stiffness, :final damping), _) => SpringMotion(
        stiffness: stiffness,
        damping: damping,
      ),
      // A timed curve runs for the sent duration, or the token's own time.
      (TimedShape(:final curve), final duration) => CurveMotion(
        curve,
        duration ?? token.duration,
      ),
      (null, null) => token,
      // A duration alone keeps the token's character and damping ratio.
      (null, final Duration duration) => token.withDuration(duration),
    };
  }
}

/// A token's motion after the override and reduced motion.
@immutable
final class ResolvedMotion<L extends Landing> {
  const ResolvedMotion({
    required this.motion,
    required this.landing,
    required this.repeatFloor,
    this.reduced,
  });

  /// A change that applies at once, with no token behind it.
  static const ResolvedMotion<NoLanding> immediate = ResolvedMotion(
    motion: Motion.instant,
    landing: NoLanding(),
    repeatFloor: 0,
    reduced: ReducedKind.jump,
  );

  final Motion motion;
  final L landing;
  final double repeatFloor;

  /// Set when reduced motion replaced the travel.
  final ReducedKind? reduced;

  /// The move plays in full.
  bool get travels => reduced == null;

  /// The travel never starts; a control shows its state as a fill.
  bool get still => reduced == ReducedKind.still;

  /// The travel from [from] to [to], for code that drives its own
  /// controller. A landed motion is done at time 0.
  Simulation simulate({
    required double from,
    required double to,
    double velocity = 0,
  }) => motion.simulate(from: from, to: to, velocity: velocity);

  /// The same result with no motion, for a change the user did not cause.
  ResolvedMotion<L> get instant => ResolvedMotion(
    motion: Motion.instant,
    landing: landing,
    repeatFloor: repeatFloor,
    reduced: reduced,
  );
}

/// Resolves [token] for [context]. This is the only place reduced motion
/// and overrides are applied: the [override] first, then the token's
/// reduced kind when the platform asks for reduced motion.
ResolvedMotion<L> resolveMotion<L extends Landing>(
  BuildContext context,
  MotionToken<L> token, {
  MotionOverride? override,
}) {
  final table = context.motion;
  final spec = table.spec(token);
  final motion = override?.applyTo(spec.motion) ?? spec.motion;
  final reduce = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
  if (!reduce) {
    return ResolvedMotion(
      motion: motion,
      landing: spec.landing,
      repeatFloor: table.repeatFloor,
    );
  }
  return ResolvedMotion(
    motion: switch (spec.reduced) {
      ReducedKind.paced => motion.paced,
      ReducedKind.jump || ReducedKind.still => Motion.instant,
    },
    landing: spec.landing,
    repeatFloor: table.repeatFloor,
    reduced: spec.reduced,
  );
}

/// The move one interaction state change plays.
extension StateMove on Set<WidgetState> {
  /// The token for the change from this set to [next], or null when no
  /// state with a move changed. Ranked press, focus, selection, hover.
  MotionToken<Landing>? moveTo(Set<WidgetState> next) {
    bool changed(WidgetState state) => contains(state) != next.contains(state);
    if (changed(WidgetState.pressed)) return MotionToken.press;
    if (changed(WidgetState.focused)) return MotionToken.focusMove;
    if (changed(WidgetState.selected)) return MotionToken.ink;
    if (changed(WidgetState.hovered)) {
      return next.contains(WidgetState.hovered)
          ? MotionToken.hoverIn
          : MotionToken.hoverOut;
    }
    return null;
  }
}
