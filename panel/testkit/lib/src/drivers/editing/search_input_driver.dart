import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/src/drivers/component_driver.dart";
import "package:typewriter_testkit/src/drivers/panel_driver.dart";
import "package:typewriter_testkit/src/drivers/semantics.dart";
import "package:typewriter_testkit/src/drivers/shared/field_driver.dart";

/// A search input: the closed field that summarizes the choice, the query
/// field it opens into. Its results are read through the search driver.
final class SearchInputDriver extends ComponentDriver {
  SearchInputDriver(super.tester);

  /// The closed search field, which the user activates to search.
  Finder get summaryButton =>
      find.bySemanticsLabel(RegExp("Activate search input"));

  /// The closed search field as assistive technology reads it.
  SemanticsNode get summary => find.semantics
      .byPredicate(
        (node) =>
            node.isButton && node.spoken.contains("Activate search input"),
      )
      .evaluate()
      .single;

  /// The inline query field; the first text field shown.
  FieldDriver get query => FieldDriver.at(tester, 0);

  /// Opens the search the way a click on the closed field does.
  Future<void> open() async {
    await tapOn(summaryButton);
    expect(query.exists, isTrue);
  }
}

/// The search input on the panel.
extension SearchInputOnPanel on PanelDriver {
  /// The search input the panel shows.
  SearchInputDriver get searchInput => SearchInputDriver(tester);
}
