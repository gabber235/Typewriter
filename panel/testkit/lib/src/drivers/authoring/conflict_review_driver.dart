import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/src/drivers/component_driver.dart";
import "package:typewriter_testkit/src/drivers/panel_driver.dart";
import "package:typewriter_testkit/src/drivers/semantics.dart";

/// The review of a conflict: for each compared value, what it was before the
/// user's changes, the user's proposal, and what is saved now, each read
/// below its column heading.
final class ConflictReviewDriver extends ComponentDriver {
  ConflictReviewDriver(super.tester);

  /// The values the review shows under [column], such as "Your proposal" or
  /// "Saved now", one per compared value in reading order.
  List<String> column(String column) => [
    for (final heading in semanticsLabeled(column)) _below(heading),
  ];

  String _below(SemanticsNode heading) {
    final above = heading.screenRect;
    final values = find.semantics
        .byPredicate(
          (node) =>
              node.getSemanticsData().value.isNotEmpty &&
              (node.screenRect.left - above.left).abs() < 1 &&
              node.screenRect.top >= above.bottom - 1,
        )
        .evaluate()
        .toList();
    if (values.isEmpty) {
      throw TestFailure("No value below ${heading.spoken}");
    }
    final value = values.reduce(
      (nearest, node) =>
          node.screenRect.top < nearest.screenRect.top ? node : nearest,
    );
    return value.getSemanticsData().value;
  }
}

/// The conflict review of the panel.
extension ConflictReviewOnPanel on PanelDriver {
  /// The conflict review the user opened.
  ConflictReviewDriver get conflictReview => ConflictReviewDriver(tester);
}
