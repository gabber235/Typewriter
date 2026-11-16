import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/src/drivers/panel_driver.dart";
import "package:typewriter_testkit/src/drivers/semantics.dart";

const _frame = Duration(milliseconds: 16);

/// Holding keys and buttons the way a user does, in frames.
///
/// Durations come from the hold token of the running hold's weight as the
/// mounted panel resolves it, so a token change needs no test edit.
extension HoldDriver on PanelDriver {
  /// How long the hold in progress takes to fill, reduced motion included.
  /// With nothing held, the longest weight's time, so a hold that never
  /// starts is waited out in full.
  Duration get holdDuration => switch (_runs.session.value) {
    final session? => holdDurationOf(session.attempt.weight),
    null => holdDurationOf(HoldWeight.permanent),
  };

  /// How long a hold of [weight] takes to fill in the mounted panel.
  Duration holdDurationOf(HoldWeight weight) => resolveMotion(
    tester.element(find.byType(CommandRunsScope)),
    weight.token,
  ).motion.duration;

  /// The weight of the hold in progress, or null when nothing is held.
  HoldWeight? get holdWeight => _runs.session.value?.attempt.weight;

  /// The panel's one owner of holds, found the way the panel installs it.
  CommandRuns get _runs =>
      tester
              .widget<CommandRunnerScope>(find.byType(CommandRunnerScope).first)
              .runner
          as CommandRuns;

  /// Lets [time] pass in frames while whatever is down stays down.
  Future<void> holdForTime(Duration time) async {
    for (var elapsed = Duration.zero; elapsed < time; elapsed += _frame) {
      await tester.pump(_frame);
    }
  }

  /// Holds [key] for [share] of the hold (a full hold plus a frame when
  /// [share] is 1), then releases it and lets the panel settle.
  Future<void> holdKey(LogicalKeyboardKey key, {double share = 1}) async {
    await tester.sendKeyDownEvent(key);
    await tester.pump();
    await holdFor(share);
    await tester.sendKeyUpEvent(key);
    await settle();
  }

  /// Presses [key] down and returns without releasing it.
  Future<void> keyDown(LogicalKeyboardKey key) async {
    await tester.sendKeyDownEvent(key);
    await tester.pump();
  }

  /// Releases [key] and lets the panel settle.
  Future<void> keyUp(LogicalKeyboardKey key) async {
    await tester.sendKeyUpEvent(key);
    await settle();
  }

  /// Lets [share] of the hold pass in frames while whatever is down stays
  /// down.
  Future<void> holdFor(double share) async {
    final duration = share >= 1 ? holdDuration + _frame : holdDuration * share;
    await holdForTime(duration);
  }

  /// Puts the pointer down on the button [label] and returns the gesture
  /// still down, for a test that times the hold itself.
  Future<TestGesture> pressButton(
    String label, {
    PointerDeviceKind kind = PointerDeviceKind.mouse,
  }) async {
    final gesture = await tester.startGesture(
      // The last one a pointer can reach: a toast may cover another.
      tester.getCenter(
        find
            .bySemanticsLabel(RegExp("^${RegExp.escape(label)}"))
            .hitTestable()
            .last,
      ),
      kind: kind,
    );
    await tester.pump();
    return gesture;
  }

  /// Holds the pointer on the button [label] for [share] of the hold, then
  /// lifts it, or drags it [drift] away first when given.
  Future<void> holdButton(
    String label, {
    double share = 1,
    PointerDeviceKind kind = PointerDeviceKind.mouse,
    Offset? drift,
  }) async {
    final gesture = await pressButton(label, kind: kind);
    if (drift != null) {
      await gesture.moveBy(drift);
      await tester.pump();
    }
    await holdFor(share);
    await gesture.up();
    await settle();
  }

  /// The outcome line a screen reader hears during a hold, if any.
  String? get holdLine {
    final line = find.byType(HoldLine);
    if (line.evaluate().isEmpty) return null;
    return tester.getSemantics(line.first).label;
  }

  /// The refusal message shown under the row that shows [row], if any.
  String? messageUnder(String row) {
    final holds = find.ancestor(
      of: find.text(row).first,
      matching: find.byType(HoldRow),
    );
    if (holds.evaluate().isEmpty) return null;
    final message = find.descendant(
      of: holds.first,
      matching: find.byType(LabeledMessage),
    );
    if (message.evaluate().isEmpty) return null;
    return tester.widget<LabeledMessage>(message.first).message;
  }

  /// The letters of the outcome line's verb typed so far.
  String get holdLineTyped {
    final root = _holdLineText.text as TextSpan;
    final line = root.children!.first as TextSpan;
    return (line.children!.first as TextSpan).text ?? "";
  }

  /// Whether the rest of the outcome line, after its verb, shows.
  bool get holdLineRestShown {
    final rest = find.descendant(
      of: find.byType(HoldLine),
      matching: find.byType(Text),
    );
    return rest.evaluate().any((element) {
      final text = element.widget as Text;
      return (text.style?.color?.a ?? 1) > 0;
    });
  }

  RichText get _holdLineText => tester.widget<RichText>(
    find
        .descendant(of: find.byType(HoldLine), matching: find.byType(RichText))
        .first,
  );

  /// The hint a screen reader reads after the hold button heard as [label].
  String holdHint(String label) => _holdButton(label).getSemanticsData().hint;

  /// Confirms the hold button heard as [label] the way a screen reader
  /// does: its long press action.
  Future<void> longPressWithScreenReader(String label) async {
    final button = _holdButton(label);
    tester.semantics.longPress(
      find.semantics.byPredicate((node) => identical(node, button)),
    );
    await settle();
  }

  // The action row repeats the focused surface's commands, so a hold
  // command can be heard twice; both run the same command.
  SemanticsNode _holdButton(String label) => switch (semanticsButtons(label)) {
    [final button, ...] => button,
    [] => throw TestFailure("No button $label on screen"),
  };

  /// The refusal the button heard as [label] reports after a failed run, if
  /// any.
  String? refusalOn(String label) {
    for (final node
        in find.semantics
            .byPredicate((node) => node.spoken.startsWith(label))
            .evaluate()) {
      final tooltip = node.getSemanticsData().tooltip;
      if (tooltip.isNotEmpty) return tooltip;
      for (final below in node.descendants) {
        final inner = below.getSemanticsData().tooltip;
        if (inner.isNotEmpty) return inner;
      }
    }
    return null;
  }

  /// The commands the panel keeps a run for.
  CommandRuns get commandRuns => CommandRunsScope.of(
    tester.element(find.byType(GlobalOperationShortcuts)),
  );
}
