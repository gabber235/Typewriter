import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/src/core/pump_panel.dart";
import "package:typewriter_testkit/src/core/stage.dart";
import "package:typewriter_testkit/src/drivers/component_driver.dart";
import "package:typewriter_testkit/src/drivers/search/search_driver.dart";
import "package:typewriter_testkit/src/drivers/semantics.dart";
import "package:typewriter_testkit/src/shared/search/query.dart";

/// Showing a query bar on its own.
extension ShowQueryBar on WidgetTester {
  /// Shows a [width] wide query bar holding [query] over [selectors], the
  /// mock selectors when absent, wired to the given callbacks.
  Future<QueryBarDriver> showQueryBar({
    String query = "",
    List<QuerySelectorDefinition>? selectors,
    ValueChanged<String>? onQueryChanged,
    Future<SearchSelectorCompletionResult> Function(
      SearchSelectorCompletionRequest request,
    )?
    completeSelector,
    ValueChanged<String>? onSubmitted,
    VoidCallback? onDismiss,
    List<ActionShortcut>? textFieldActions,
    double width = 500,
  }) async {
    final panel = await pumpPanel(
      const [],
      at: PanelLocation.component(
        SizedBox(
          width: width,
          child: QueryBar(
            query: query,
            selectors: selectors ?? mockQuerySelectors,
            completeSelector: completeSelector,
            onQueryChanged: onQueryChanged ?? (_) {},
            onSubmitted: onSubmitted,
            onDismiss: onDismiss,
            textFieldActions: textFieldActions,
          ),
        ),
      ),
    );
    return panel.queryBar;
  }
}

/// The query bar: a text field with selector suggestions below it and a
/// helper line naming the selectors the user can filter with.
final class QueryBarDriver extends ComponentDriver {
  QueryBarDriver(super.tester);

  SemanticsNode get _field =>
      find.semantics
          .byPredicate(
            (node) => node.getSemanticsData().flagsCollection.isTextField,
          )
          .evaluate()
          .lastOrNull ??
      (throw TestFailure("No query bar is shown"));

  /// The text in the field.
  String get text => _field.getSemanticsData().value;

  /// The selected stretch of the text, or the cursor when collapsed.
  TextSelection? get selection => _field.getSemanticsData().textSelection;

  /// Where the field is on screen.
  Rect get rect => _field.screenRect;

  /// Whether the field holds the keyboard focus.
  bool get isFocused => _field.isFocused;

  /// Clicks into the field.
  Future<void> focus() async {
    await tester.tapAt(_field.screenRect.center);
    await tester.pump(kDoubleTapTimeout);
    await tester.pump();
  }

  /// Replaces the text in the field with [query], the way typing does, with
  /// the cursor at [cursor] or at the end, and lets the bar react without
  /// waiting for slower completions.
  Future<void> type(String query, {int? cursor}) async {
    if (!isFocused) await focus();
    tester.testTextInput.updateEditingValue(
      TextEditingValue(
        text: query,
        selection: TextSelection.collapsed(offset: cursor ?? query.length),
      ),
    );
    await tester.pump();
  }

  /// Presses the keyboard's done action, the way Enter submits a field.
  Future<void> submit() async {
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();
  }

  SemanticsNode? get _suggestions =>
      semanticsLabeled(querySuggestionsSemanticLabel).lastOrNull;

  /// Whether the suggestion list is open.
  bool get showsSuggestions => _suggestions != null;

  /// Where the suggestion list is on screen.
  Rect get suggestionsRect =>
      (_suggestions ?? (throw TestFailure("No suggestions are shown")))
          .screenRect;

  /// The entries of the suggestion list; an entry reads its value, then its
  /// kind, and only its outermost node counts.
  List<SemanticsNode> get _entries => [
    for (final node in _suggestions?.descendants ?? const <SemanticsNode>[])
      if (node.isTappable && node.parent?.spoken != node.spoken) node,
  ];

  /// The suggestions offered, top to bottom.
  List<String> get suggestions => [
    for (final entry in _entries) entry.spoken.split("\n").first,
  ];

  /// Chooses the suggestion [label] with a click.
  Future<void> chooseSuggestion(String label) async {
    final node =
        _entries.firstWhereOrNull(
          (node) => node.spoken.split("\n").first == label,
        ) ??
        (throw TestFailure("No suggestion $label; there are $suggestions"));
    await tester.tapAt(node.screenRect.center);
    await settle();
  }

  /// Whether the helper line naming the available selectors is shown.
  bool get showsHelper =>
      this.within(find.textContaining("You can use:")).evaluate().isNotEmpty;

  /// How often the helper line names the selector [label].
  int helperMentions(String label) =>
      showsHelper ? this.within(find.text(label)).evaluate().length : 0;

  /// The styles the field draws each stretch of its text containing [text]
  /// in, such as a selector's color or an issue's underline.
  ///
  /// Only the rendered text span carries this, so it is read from the field's
  /// editable text rather than from semantics.
  List<TextStyle?> stylesOf(String text) {
    final editable = this.within(
      find.byWidgetPredicate((widget) => widget is EditableText),
    );
    final widget = tester.widget<EditableText>(editable.last);
    final span = widget.controller.buildTextSpan(
      context: tester.element(editable.last),
      withComposing: false,
      style: widget.style,
    );
    final styles = <TextStyle?>[];
    void visit(InlineSpan span) {
      if (span is! TextSpan) return;
      final children = span.children;
      if (children == null || children.isEmpty) {
        if ((span.text ?? "").contains(text)) styles.add(span.style);
        return;
      }
      children.forEach(visit);
    }

    visit(span);
    return styles;
  }
}
