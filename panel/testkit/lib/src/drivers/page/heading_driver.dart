import "package:flutter_test/flutter_test.dart";
import "package:typewriter_testkit/src/drivers/panel_driver.dart";
import "package:typewriter_testkit/src/drivers/semantics.dart";

/// The headings of the open page, as assistive technology lists them.
extension PageHeadings on PanelDriver {
  /// The labels of every heading on screen, in reading order.
  List<String> get headings => [
    for (final node
        in find.semantics
            .byPredicate(
              (node) => node.getSemanticsData().flagsCollection.isHeader,
            )
            .evaluate())
      node.spoken,
  ];
}
