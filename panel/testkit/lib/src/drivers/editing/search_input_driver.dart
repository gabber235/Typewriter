import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/src/drivers/component_driver.dart";
import "package:typewriter_testkit/src/drivers/panel_driver.dart";
import "package:typewriter_testkit/src/drivers/semantics.dart";
import "package:typewriter_testkit/src/drivers/shared/field_driver.dart";

/// A search input: the closed field that summarizes the choice, the query
/// field it opens into, and the result the keyboard highlights.
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

  /// The label of the result the keyboard highlights, or null.
  String? get highlighted {
    final rows = find.semantics
        .byPredicate(
          (node) =>
              node.isButton &&
              node.getSemanticsData().flagsCollection.isSelected ==
                  Tristate.isTrue,
        )
        .evaluate();
    if (rows.isEmpty) return null;
    return rows.single.descendants
        .map((node) => node.spoken)
        .firstWhere((label) => label.isNotEmpty);
  }

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
