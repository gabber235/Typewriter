import "package:flutter_test/flutter_test.dart";
import "package:typewriter_testkit/testing.dart";

void main() {
  const path = "lib/x/presentation/a.dart";

  test("motion literals are reported with the token to use", () {
    for (final snippet in [
      "AnimatedSize(duration: 800.ms, curve: ElasticOutCurve(0.9))", // member_list.dart:91
      "AnimatedContainer(duration: const Duration(milliseconds: 120))", // collection_editor.dart:483
      "final typingDelay = 50.ms;", // secret_field_displays.dart:93
      "reverseCurve: const Interval(0, 0.9, curve: Cubic(.89, -0.01, .51, 1.11))", // elastic_transition.dart:22
      "_shimmerController.repeat(min: -0.5, max: 1.5, period: 1000.ms)", // shimmer.dart:109
    ]) {
      final found = motionLiteralViolations(path, snippet, const []);
      expect(found, isNotEmpty, reason: snippet);
      expect(found.first, contains("Motion token"));
    }
  });

  // Every Duration or curve literal in the panel that is not motion, with the
  // rule that skips it.
  test("durations that keep time or carry a value are not motion", () {
    for (final (snippet, rule) in [
      // Clock call: the literal is an argument of Timer, useTimer, add or subtract.
      (
        "_hoverExit = Timer(const Duration(milliseconds: 180), () {})",
        "clock call",
      ), // anchored_popup.dart:180
      (
        "useTimer(1.seconds, (timer) {})",
        "clock call",
      ), // countdown_badge.dart:29
      ("useTimer(1.seconds, (timer) {", "clock call"), // popups.dart:88
      (
        "useTimer(1.seconds, (_) {",
        "clock call",
      ), // secret_field_controller.dart:21
      (
        "now.add(const Duration(seconds: 10))",
        "clock call",
      ), // status_indicator.dart:39
      (
        "_focusedDate.subtract(const Duration(days: 7))",
        "clock call",
      ), // date_time_calendar.dart:118
      // Clock name: the literal is given to interval, urgentThreshold or longPressDelay.
      (
        "RotatingShortcuts(shortcuts: s, interval: 5.seconds)",
        "clock name",
      ), // action_row.dart:225
      (
        "this.urgentThreshold = const Duration(seconds: 60),",
        "clock name",
      ), // countdown_badge.dart:11
      (
        "longPressDelay: const Duration(milliseconds: 180),",
        "clock name",
      ), // color_swatches.dart:145
      (
        "const _heartbeatInterval = Duration(seconds: 15);",
        "clock name",
      ), // organization_presence.dart:8
      (
        "const _presenceExpiry = Duration(seconds: 45);",
        "clock name",
      ), // organization_presence.dart:9
      (
        "this.debounceDuration = const Duration(milliseconds: 150),",
        "clock name",
      ), // query_suggestion_session.dart:11
      (
        "const _requestTimeout = Duration(seconds: 10);",
        "clock name",
      ), // skir_nats.dart:5
      // Clock call by last segment: delayed, debounced and periodic on any receiver.
      (
        "Future<void>.delayed(const Duration(milliseconds: 250))",
        "clock call",
      ), // skir_nats.dart:575
      (
        ").debounced(100.ms).cached(),",
        "clock call",
      ), // primary_search_sources.dart:93
      // A ternary is not a named argument; the enclosing call decides.
      (
        "Future<void>.delayed(_state is SearchCommandFailed ? 10.seconds : 3.seconds)",
        "clock call",
      ), // command_controller.dart:122-123
      // Unit: days, hours and minutes are calendar values, never matched.
      (
        "const presets = [Duration(hours: 1), Duration(days: 1), Duration(days: 7), Duration(days: 30)];",
        "unit",
      ), // join_code_duration_input.dart:19-22
      // Not a numeric literal: a computed or protocol value.
      (
        "return Duration(milliseconds: milliseconds);",
        "computed value",
      ), // content.dart:618
      (
        "value: skir.Duration(milliseconds: milliseconds),",
        "qualified type",
      ), // temporal_inputs.dart:205
      (
        "value: skir.Duration(milliseconds: next),",
        "qualified type",
      ), // temporal_inputs.dart:285
      // Identifier: Duration inside a longer name is not the constructor.
      (
        "return prettyDuration(duration, abbreviated: true);",
        "identifier",
      ), // join_code_duration_input.dart:41
      (
        "serialize: (value) => parseDuration(value, separator: \" \"),",
        "identifier",
      ), // join_code_duration_input.dart:91
      (
        "_formatDuration(remaining.value),",
        "identifier",
      ), // countdown_badge.dart:66
    ]) {
      expect(
        motionLiteralViolations(path, snippet, const []),
        isEmpty,
        reason: "$snippet is skipped by the $rule rule",
      );
    }
  });

  test("every banned API is reported outside its owner and allowed in it", () {
    for (final (snippet, owner) in [
      (
        "_reducedMotion = MediaQuery.maybeDisableAnimationsOf(context) ?? false;",
        "lib/shared/hooks/motion.dart",
      ), // shimmer.dart:90
      (
        "transitionAnimationStyle: AnimationStyle(duration: 500.ms),",
        null,
      ), // member_card.dart
      ("return MenuAnchor(", null), // context_menu.dart:46
      ("PopupMenuButton<String>(", null), // resources.dart:299
      ("return Tooltip(", null), // resource_operations.dart:317
      ("final confirmed = await showDialog<bool>(", null), // header.dart:671
      (
        "showModalBottomSheet<void>(",
        "lib/shared/ui/components/popups.dart",
      ), // custom_appbar.dart:99
      ("ListTile(title: Text(name))", null), // organizations.dart
      (
        'export "package:flutter_animate/flutter_animate.dart";',
        null,
      ), // dependencies.dart
      (
        "final spring = SpringDescription.withDampingRatio(mass: 1, stiffness: 400);",
        null,
      ),
      (
        "curve: const Interval(0, 0.5, curve: Curves.easeOut),",
        null,
      ), // elastic_switcher.dart:32
      (
        "_controller = AnimationController(vsync: this);",
        null,
      ), // graph_viewport_controller.dart:15
    ]) {
      expect(
        bannedApiViolations(path, snippet, bannedPatterns, const []),
        isNotEmpty,
        reason: snippet,
      );
      if (owner != null) {
        expect(
          bannedApiViolations(owner, snippet, bannedPatterns, const []),
          isEmpty,
          reason: "$owner owns it",
        );
      }
    }
  });

  test("names that only contain a banned API are not banned", () {
    for (final snippet in [
      "PanelTooltip(message: label, child: button)",
      "DropdownMenuEntry(value: value, label: label)",
      "MotionDialogRoute<T>(builder: builder)",
      "skir.Interval(start: 0, end: 1)",
    ]) {
      expect(
        bannedApiViolations(path, snippet, bannedPatterns, const []),
        isEmpty,
        reason: snippet,
      );
    }
  });
}
