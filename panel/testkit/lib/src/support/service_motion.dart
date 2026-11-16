import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/src/shared/editors/presentation_builders.dart";
import "package:typewriter_testkit/src/support/portable_operations.dart";
import "package:typewriter_testkit/src/support/shown_component.dart";
import "package:typewriter_testkit/src/support/ui/probes.dart";

/// A transition policy that overrides only the given states' moves.
skir.PresentationTransitionPolicy transitionOverrides({
  skir.PresentationTransition? hovered,
  skir.PresentationTransition? focused,
  skir.PresentationTransition? pressed,
  skir.PresentationTransition? selected,
}) => skir.PresentationTransitionPolicy(
  hovered: hovered,
  focused: focused,
  pressed: pressed,
  selected: selected,
);

/// A timed override that replaces [milliseconds], [curve], or both.
skir.PresentationTransition timedTransition({
  int? milliseconds,
  skir.PresentationTimedCurve? curve,
}) => skir.PresentationTransition.wrapTimed(
  skir.PresentationTimedTransition(milliseconds: milliseconds, curve: curve),
);

/// A collection appearance that sets only the item [arrival] and [leave]
/// overrides.
skir.CollectionAppearance itemMotionAppearance({
  skir.PresentationTransition? arrival,
  skir.PresentationTransition? leave,
}) => skir.CollectionAppearance(
  itemSpacing: null,
  itemPadding: null,
  itemBackground: null,
  itemForeground: null,
  itemBorder: null,
  itemRadius: null,
  itemTransition: null,
  itemShadows: const [],
  itemArrival: arrival,
  itemLeave: leave,
);

/// The panel's own [Rise] on a plain box, shown beside a service transform
/// so a test can compare the two.
final class PanelRiser {
  PanelRiser._(this._tester, this._raised);

  final WidgetTester _tester;
  final ValueNotifier<bool>? _raised;

  static const _label = "panel riser";

  /// Points at the box, the way the pointer entering it does.
  void hover() {
    final raised = _raised;
    if (raised == null) {
      throw StateError("The stage was shown without the panel riser.");
    }
    raised.value = true;
  }

  /// How far the box has risen along its move: 0 at rest, 1 on its target.
  double progress() {
    final lift = find
        .ancestor(
          of: find.byWidgetPredicate(
            (widget) => widget is LabeledBox && widget.label == _label,
          ),
          matching: find.byType(Transform),
        )
        .first;
    final scale = _tester.widget<Transform>(lift).transform.entry(0, 0);
    final landing = resolveMotion(
      _tester.element(lift),
      MotionToken.hoverIn,
    ).landing;
    return (scale - 1) / (landing.scale - 1);
  }
}

/// A service transform whose scale follows interaction state.
typedef StateTransform = ({
  void Function(PresentationInteraction next) interact,
  double Function() scale,
  PanelRiser riser,
});

/// A service transform whose idle scale comes from data.
typedef DataTransform = ({
  double Function() scale,
  void Function(double value) setIdleScale,
});

const _card = "Card";

/// Showing service transforms and reading how they move.
extension ServiceMotionStage on WidgetTester {
  /// Shows a fresh service transform over the text "Card" whose scale is
  /// [pressed] while pressed, else [focused] while focused, else [hovered]
  /// while hovered, and 1 otherwise, with the overrides of [policy]. With
  /// [withPanelRiser] the panel's own [Rise] stands beside it.
  Future<StateTransform> stateTransform({
    required skir.PresentationTransitionPolicy? policy,
    double? hovered,
    double? focused,
    double? pressed,
    bool withPanelRiser = false,
  }) async {
    skir.PresentationStateNumberRule rule(
      skir.PresentationInteractionState state,
      double value,
    ) => skir.PresentationStateNumberRule(
      match: skir.PresentationStateMatch(
        required_: [state],
        excluded: const [],
      ),
      value: numberLiteral(value),
    );
    final root = _transform(
      scale: skir.PresentationNumber.createStates(
        rules: [
          if (pressed != null)
            rule(skir.PresentationInteractionState.pressed, pressed),
          if (focused != null)
            rule(skir.PresentationInteractionState.focused, focused),
          if (hovered != null)
            rule(skir.PresentationInteractionState.hovered, hovered),
        ],
        fallback: numberLiteral(1),
      ),
      policy: policy,
    );
    final interaction = ValueNotifier(const PresentationInteraction());
    final raised = withPanelRiser ? ValueNotifier(false) : null;
    addTearDown(() {
      interaction.dispose();
      raised?.dispose();
    });
    await showComponent(
      _Stage(
        key: UniqueKey(),
        presentation: ValueListenableBuilder(
          valueListenable: interaction,
          builder: (context, value, _) => PresentationInteractionScope(
            value: value,
            child: PortablePresentationNodeRenderer(
              node: root,
              scope: unboundPresentationScope(),
              fillAvailableSpace: true,
            ),
          ),
        ),
        riser: raised == null
            ? null
            : ValueListenableBuilder(
                valueListenable: raised,
                builder: (context, up, _) => Rise(
                  raised: up,
                  child: const LabeledBox(
                    PanelRiser._label,
                    width: 40,
                    height: 20,
                  ),
                ),
              ),
      ),
    );
    return (
      interact: (PresentationInteraction next) => interaction.value = next,
      scale: _scale,
      riser: PanelRiser._(this, raised),
    );
  }

  /// Shows a fresh service transform over the text "Card" whose scale is
  /// [idle] in every state, and returns the function that sends new data
  /// for it.
  Future<DataTransform> stateTransformWithData({required double idle}) async {
    final data = ValueNotifier(idle);
    addTearDown(data.dispose);
    await showComponent(
      _Stage(
        key: UniqueKey(),
        presentation: ValueListenableBuilder(
          valueListenable: data,
          builder: (context, value, _) => PortablePresentationNodeRenderer(
            node: _transform(scale: presentationNumber(value), policy: null),
            scope: unboundPresentationScope(),
            fillAvailableSpace: true,
          ),
        ),
      ),
    );
    return (scale: _scale, setIdleScale: (double value) => data.value = value);
  }

  /// The time [token] takes as the panel tunes it, read under the shown
  /// presentation.
  Duration tokenTime(MotionToken<Landing> token) => resolveMotion(
    element(find.byType(PortablePresentationNodeRenderer).first),
    token,
  ).motion.duration;

  /// Renders the move the last interaction started until it stops, and
  /// returns the value [read] reached farthest past [target], and the time
  /// after which it stayed within 1% of its travel from [target].
  Future<(double peak, Duration settled)> peakAndSettle(
    double Function() read, {
    required double target,
  }) async {
    const frame = Duration(milliseconds: 4);
    final start = read();
    final travel = target - start;
    await pump();
    var peak = read();
    var elapsed = Duration.zero;
    var settled = Duration.zero;
    while (hasRunningAnimations && elapsed < const Duration(seconds: 10)) {
      await pump(frame);
      elapsed += frame;
      final value = read();
      if ((value - start) / travel > (peak - start) / travel) peak = value;
      if ((value - target).abs() > travel.abs() * 0.01) settled = elapsed;
    }
    return (peak, settled);
  }

  double _scale() => widget<Transform>(
    find.ancestor(of: find.text(_card), matching: find.byType(Transform)).first,
  ).transform.entry(0, 0);
}

skir.PresentationNode _transform({
  required skir.PresentationNumber scale,
  required skir.PresentationTransitionPolicy? policy,
}) => presentationNode(
  "transform",
  skir.PresentationElement.createTransform(
    child: presentationText("card", textLiteral(_card)),
    origin: skir.PresentationAlignment.center,
    perspective: 0,
    scale: scale,
    rotateX: null,
    rotateY: null,
    rotateZ: null,
    translateX: null,
    translateY: null,
    transition: policy,
  ),
);

/// A service presentation in a 160 by 80 box, with an optional [riser]
/// beside it.
final class _Stage extends StatelessWidget {
  const _Stage({required this.presentation, this.riser, super.key});

  final Widget presentation;
  final Widget? riser;

  @override
  Widget build(BuildContext context) => Center(
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(width: 160, height: 80, child: presentation),
        ?riser,
      ],
    ),
  );
}
