import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/src/drivers/semantics.dart";

/// Drives one visible component through what its user sees: text, semantics
/// labels and roles, never keys or widget types.
///
/// A test that breaks means the visible component changed, so a driver also
/// checks that the component is reachable the way a user reaches it. Drivers
/// nest: a component driver hands out drivers for the components inside it,
/// so a new component adds one driver every test, story test and journey can
/// use.
abstract class ComponentDriver {
  ComponentDriver(this.tester, [this.scope]);

  final WidgetTester tester;

  /// What bounds this component on screen; null for the whole screen.
  final Finder? scope;

  /// [inner] inside this component.
  Finder within(Finder inner) => switch (scope) {
    null => inner,
    final scope => find.descendant(of: scope, matching: inner),
  };

  /// The widget whose semantics carry [label] inside this component.
  Finder labeled(String label) =>
      within(find.bySemanticsLabel(label, skipOffstage: true));

  /// Whether this component shows [label] as text or as a semantics label.
  bool shows(String label) =>
      within(find.text(label)).evaluate().isNotEmpty ||
      labeled(label).evaluate().isNotEmpty;

  /// Lets the panel finish what the last action started: frames, animations
  /// and replies already due.
  Future<void> settle() async {
    await tester.pump();
    await tester.pumpAndSettle(
      const Duration(milliseconds: 16),
      EnginePhase.sendSemanticsUpdate,
      const Duration(seconds: 5),
    );
  }

  /// The spoken labels of [nodes], in their order, split into the sections
  /// the user sees: a section ends wherever a separator line lies between
  /// two neighbours.
  List<List<String>> splitAtSeparators(List<SemanticsNode> nodes) {
    final separators = find.byType(Separator);
    final lines = [
      for (var index = 0; index < separators.evaluate().length; index++)
        tester.getRect(separators.at(index)),
    ];
    bool between(Rect above, Rect below) => lines.any(
      (line) =>
          line.center.dy >= above.bottom &&
          line.center.dy <= below.top &&
          line.left < below.right &&
          line.right > below.left,
    );
    final sections = <List<String>>[];
    Rect? previous;
    for (final node in nodes) {
      final rect = node.screenRect;
      if (previous == null || between(previous, rect)) sections.add([]);
      sections.last.add(node.spoken);
      previous = rect;
    }
    return sections;
  }

  /// Taps [target] and lets the panel react.
  ///
  /// Waits out the double tap timeout first: a component that also answers
  /// double taps only sees a single tap once that timeout passed.
  Future<void> tapOn(Finder target, {int buttons = kPrimaryButton}) async {
    await tester.tap(target, buttons: buttons);
    await tester.pump(kDoubleTapTimeout);
    await settle();
  }

  /// Activates the one button the user hears as [label] the way a screen
  /// reader does, through its tap action, and lets the panel react. Fails
  /// when assistive technology cannot reach the button or cannot activate it.
  ///
  /// Without [settle] the panel has not reacted yet when this returns, so
  /// the test can act again in the same frame, as a fast user does.
  ///
  /// With [repeated], the button may be heard twice because the action row
  /// repeats the focused surface's command; the first one heard is used.
  Future<void> activateWithScreenReader(
    String label, {
    bool settle = true,
    bool repeated = false,
  }) async {
    final button = switch ((repeated, semanticsButtons(label))) {
      (true, [final first, _]) => first,
      _ => semanticsButton(label),
    };
    expect(
      button.isTappable,
      isTrue,
      reason: "a screen reader can activate $label",
    );
    tester.semantics.tap(
      find.semantics.byPredicate((node) => identical(node, button)),
    );
    if (!settle) return;
    // A control that also answers double taps acts once the timeout passed.
    await tester.pump(kDoubleTapTimeout);
    await this.settle();
  }
}

/// The open context menu: the menu the keyboard focus moved into.
///
/// Entries are found by their labels in the order the user sees them.
final class ContextMenuDriver extends ComponentDriver {
  ContextMenuDriver(super.tester);

  /// The semantics node of the open menu, named for assistive technology.
  SemanticsNode? get _menu =>
      semanticsLabeled(contextMenuSemanticLabel).lastOrNull;

  /// The menu's entries; an entry merges its label into the node that holds
  /// its focus, so only the outermost node of each label counts.
  List<SemanticsNode> get _entries => [
    for (final node in _menu?.descendants ?? const <SemanticsNode>[])
      if (node.spoken.isNotEmpty && node.parent?.spoken != node.spoken) node,
  ];

  /// Whether a context menu is open.
  bool get isOpen => _entries.isNotEmpty;

  /// The labels of the menu's entries, top to bottom.
  List<String> get entries => [for (final entry in _entries) entry.spoken];

  /// The menu's entries in the sections its divider lines split them into.
  List<List<String>> get sections => splitAtSeparators(_entries);

  /// Whether the entry [label] can be chosen.
  bool isEnabled(String label) => _entry(label).isEnabled;

  SemanticsNode _entry(String label) {
    if (!isOpen) throw TestFailure("No context menu is open");
    return _entries.firstWhereOrNull((entry) => entry.spoken == label) ??
        (throw TestFailure(
          "The context menu has no entry $label; it shows $entries",
        ));
  }

  /// Where the entry [label] is on screen.
  Rect rectOf(String label) => _entry(label).screenRect;

  /// Chooses the entry [label], the way a click on it does.
  Future<void> choose(String label) async {
    final entry = _entry(label);
    await tester.tapAt(entry.screenRect.center);
    await settle();
  }

  /// Chooses the entry [label] with the keyboard alone: the arrow keys move
  /// focus down from the first entry, Enter activates it.
  Future<void> chooseWithKeyboard(String label) async {
    _entry(label);
    for (var step = 0; step < entries.indexOf(label); step++) {
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pump();
    }
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await settle();
  }

  /// Closes the menu without choosing, the way Escape does.
  Future<void> dismiss() async {
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await settle();
  }
}
