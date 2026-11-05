import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/src/drivers/component_driver.dart";
import "package:typewriter_testkit/src/drivers/panel_driver.dart";
import "package:typewriter_testkit/src/drivers/search/query_bar_driver.dart";
import "package:typewriter_testkit/src/core/pump_panel.dart";
import "package:typewriter_testkit/src/core/stage.dart";
import "package:typewriter_testkit/src/drivers/semantics.dart";
import "package:typewriter_testkit/src/shared/search/search_source.dart";

/// The search surfaces of the panel.
extension SearchDrivers on PanelDriver {
  /// The search results the panel shows.
  SearchResultsDriver get search => SearchResultsDriver(tester);

  /// The query bar the user types a search into.
  QueryBarDriver get queryBar => QueryBarDriver(tester);
}

/// Showing a search over a [FakeSearchSource] on its own.
extension ShowSearch on WidgetTester {
  /// Shows [results], the result tree when absent, in a [size] box under a
  /// search root over [source] that knows the tag selector `#` and records
  /// activated result ids in [activated] when given.
  Future<PanelDriver> showSearch(
    FakeSearchSource source, {
    Widget? results,
    List<String>? activated,
    Size size = const Size(600, 500),
  }) => pumpPanel(
    const [],
    at: PanelLocation.component(
      SizedBox(
        width: size.width,
        height: size.height,
        child: SearchRoot(
          create: (ref) => SearchController(
            session: searchSession(source, activated: activated),
            baseSelectors: const [
              KeyValueSelectorDefinition(id: "tag", key: "#"),
            ],
          ),
          child: results ?? SearchTreeResults(rowRenderers: searchRows()),
        ),
      ),
    ),
  );
}

/// Row renderers for [testResultType] results whose rows read
/// `Result <id>` at [density], naming the kind [kindLabel].
Map<String, SearchResultRowBuilder> searchRows({
  SearchResultDensity density = SearchResultDensity.compact,
  String kindLabel = "",
}) => {
  testResultType.rowRendererId: (row) => SearchResultRow(
    row: row,
    density: density,
    title: "Result ${row.result.id}",
    kindLabel: kindLabel,
  ),
};

/// The result tree of a search: sections, result rows and the states shown
/// instead of results.
final class SearchResultsDriver extends ComponentDriver {
  SearchResultsDriver(super.tester);

  /// Has [source] answer with [nodes] and lets the results settle; with
  /// [settle] false it pumps one frame and the rows' deferred setup only, so
  /// rows still move.
  Future<void> show(
    FakeSearchSource source,
    List<SearchNode> nodes, {
    bool settle = true,
  }) async {
    source.emitSnapshot(SearchSourceSnapshot.ready(nodes: nodes));
    if (settle) return this.settle();
    await tester.pump();
    await tester.pump(Duration.zero);
  }

  /// The result row the user reads as [label].
  SearchResultDriver result(String label) => SearchResultDriver(tester, label);

  /// Opens or closes the section titled [title] with a click and lets its
  /// rows finish moving.
  Future<void> toggleSection(String title) =>
      tapOn(this.within(find.text(title)).first);

  /// Activates the result with shortcut [number], the way the user presses
  /// the primary modifier with a digit.
  Future<void> activateByShortcut(int number) async {
    final modifier = switch (defaultTargetPlatform) {
      TargetPlatform.macOS || TargetPlatform.iOS => LogicalKeyboardKey.metaLeft,
      _ => LogicalKeyboardKey.controlLeft,
    };
    await tester.sendKeyDownEvent(modifier);
    await tester.sendKeyEvent(
      LogicalKeyboardKey(LogicalKeyboardKey.digit1.keyId + number - 1),
    );
    await tester.sendKeyUpEvent(modifier);
    await settle();
  }
}

/// One search result row, found by a line of the label the user reads on it.
///
/// A row merges its title, kind and shortcut into one tappable node, so the
/// row is the innermost tappable node with a line reading [label].
final class SearchResultDriver extends ComponentDriver {
  SearchResultDriver(super.tester, this.label);

  final String label;

  SemanticsNode? get _row => find.semantics
      .byPredicate(
        (node) =>
            node.isTappable &&
            node.spoken.split("\n").any((line) => line.trim() == label),
      )
      .evaluate()
      .lastOrNull;

  SemanticsNode get _node =>
      _row ?? (throw TestFailure("No search result reads $label"));

  /// Whether the row is on screen.
  bool get isShown => _row != null;

  /// Everything the row reads, line by line.
  List<String> get lines => _node.spoken.split("\n");

  /// Where the row is on screen.
  Rect get rect => _node.screenRect;

  /// Whether the row shows as selected.
  bool get isSelected =>
      _node.getSemanticsData().flagsCollection.isSelected == Tristate.isTrue;

  /// Whether the row holds the keyboard focus.
  bool get isFocused => _node.isFocused;

  /// Clicks the row.
  Future<void> tap() async {
    await tester.tapAt(_node.screenRect.center);
    await tester.pump(kDoubleTapTimeout);
    await settle();
  }

  /// Drags the row by [offset], the way a pointer scrolls the list it sits in.
  Future<void> drag(Offset offset) async {
    await tester.dragFrom(_node.screenRect.center, offset);
    await settle();
  }

  /// Moves the keyboard focus to the row, the way Tab reaches it.
  Future<void> focus() async {
    _node.owner!.performAction(_node.id, SemanticsAction.focus);
    await settle();
  }
}
