import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/typewriter_panel.dart";
import "package:typewriter_testkit/src/drivers/component_driver.dart";
import "package:typewriter_testkit/src/drivers/semantics.dart";

/// The text fields on screen in reading order, the way assistive technology
/// lists them.
List<SemanticsNode> visibleTextFields() => [
  ...find.semantics
      .byPredicate(
        (node) =>
            node.getSemanticsData().flagsCollection.isTextField &&
            !node.isMergedIntoParent &&
            !node.isInvisible,
      )
      .evaluate(),
]..sort(_readingOrder);

/// Orders nodes the way a reader meets them: rows top to bottom, then left
/// to right within a row.
int _readingOrder(SemanticsNode a, SemanticsNode b) {
  final first = a.screenRect;
  final second = b.screenRect;
  if ((first.top - second.top).abs() > 1) {
    return first.top.compareTo(second.top);
  }
  return first.left.compareTo(second.left);
}

/// The values of the text fields on screen, in reading order.
List<String> visibleFieldValues() => [
  for (final field in visibleTextFields()) field.getSemanticsData().value,
];

/// One text field, found by the label assistive technology reads for it or
/// by its place in reading order.
///
/// A field whose label also names its hint or description still matches:
/// the label only has to start with [label]. A field without such a label
/// matches by its hint, which it reads while empty. An empty [label] finds
/// the first field, for a component that shows only one.
final class FieldDriver extends ComponentDriver {
  FieldDriver(super.tester, String this.label) : index = null;

  /// The field at [index] among the fields on screen in reading order, for
  /// fields that carry no label of their own, such as collection items.
  FieldDriver.at(super.tester, int this.index) : label = null;

  final String? label;
  final int? index;

  SemanticsNode get _node {
    final fields = visibleTextFields();
    if (index case final index?) {
      if (index < fields.length) return fields[index];
      throw TestFailure("No text field at $index; there are ${fields.length}");
    }
    final label = this.label!;
    return fields.firstWhereOrNull((node) => node.spoken.startsWith(label)) ??
        fields.firstWhereOrNull(
          (node) => node.getSemanticsData().hint.startsWith(label),
        ) ??
        (throw TestFailure(
          "No text field is labeled $label; the fields are "
          "${[for (final field in fields) field.spoken]}",
        ));
  }

  /// Whether the field is on screen.
  bool get exists {
    try {
      _node;
      return true;
    } on TestFailure {
      return false;
    }
  }

  /// The text the field shows.
  String get value => _node.getSemanticsData().value;

  /// Where the field is on screen.
  Rect get rect => _node.screenRect;

  /// Whether the field holds the keyboard focus.
  bool get isFocused => _node.isFocused;

  /// The part of the text the user selected, or null when the field reports
  /// no selection.
  TextSelection? get selection => _node.getSemanticsData().textSelection;

  /// Whether the field shows its text without accepting edits.
  bool get isReadOnly => _node.getSemanticsData().flagsCollection.isReadOnly;

  /// Whether the field accepts input.
  bool get isEnabled => _node.isEnabled;

  /// Whether the field hides its text, as a password field does.
  bool get isObscured => _node.getSemanticsData().flagsCollection.isObscured;

  /// Whether assistive technology can set the field's text now, which a
  /// field allows once it holds the focus.
  bool get acceptsText =>
      _node.getSemanticsData().hasAction(SemanticsAction.setText);

  /// Whether a click reaches the field's input now; a read only input, as an
  /// editor that is still loading shows, offers no tap until it opens.
  bool get canClickInput =>
      _clickTarget.getSemanticsData().hasAction(SemanticsAction.tap);

  /// The field's semantics and its input's flags and actions, for a failure
  /// message.
  String get describe {
    final field = _node.getSemanticsData();
    final input = _clickTarget.getSemanticsData();
    String flags(SemanticsData data) =>
        data.flagsCollection.toStrings().join(",");
    String actions(SemanticsData data) => SemanticsAction.values
        .where(data.hasAction)
        .map((action) => action.name)
        .join(",");
    return "field flags [${flags(field)}] actions [${actions(field)}], "
        "input flags [${flags(input)}] actions [${actions(input)}]";
  }

  /// Clicks the field's input the way a screen reader does, without waiting
  /// for the panel to react; the input must [canClickInput].
  ///
  /// A field rebuilt while its surface loads drops the focus a click gave
  /// it, so a step waiting for [acceptsText] clicks again, as a user does.
  void clickInput() {
    final target = _clickTarget;
    tester.semantics.tap(
      find.semantics.byPredicate((node) => identical(node, target)),
    );
  }

  /// The node a screen reader activates for the field's input: the innermost
  /// text field, since an editor field wraps its input in a focus boundary
  /// that reads as the same field, or the node that input merged into, which
  /// holds its tap.
  SemanticsNode get _clickTarget {
    final field = _node;
    var input = [
      field,
      ...field.descendants,
    ].where((node) => node.getSemanticsData().flagsCollection.isTextField).last;
    while (input.isMergedIntoParent && input.parent != null) {
      input = input.parent!;
    }
    return input;
  }

  /// Replaces the field's text with [text] the way a screen reader does,
  /// without waiting for the panel to react; the field must [acceptsText].
  void setText(String text) {
    final field = _node;
    tester.semantics.setText(
      find.semantics.byPredicate((node) => identical(node, field)),
      text,
    );
  }

  /// Focuses the field with a tap.
  Future<void> focus() async {
    await tester.tapAt(_node.screenRect.center);
    await settle();
  }

  /// Focuses the field the way a screen reader does, through the focus
  /// action of the field it announces.
  Future<void> focusFromScreenReader() async {
    final node = _node;
    node.owner!.performAction(node.id, SemanticsAction.focus);
    await settle();
  }

  /// Replaces the field's text with [text] as typing does, without
  /// committing it.
  Future<void> type(String text) async {
    await focus();
    tester.testTextInput.updateEditingValue(
      TextEditingValue(
        text: text,
        selection: TextSelection.collapsed(offset: text.length),
      ),
    );
    await settle();
  }

  /// Replaces the text of the field, which already holds focus, with [text]
  /// and selects [selection], the caret after the text by default; keeps
  /// focus where it is and commits nothing.
  Future<void> edit(String text, {TextSelection? selection}) async {
    tester.testTextInput.updateEditingValue(
      TextEditingValue(
        text: text,
        selection: selection ?? TextSelection.collapsed(offset: text.length),
      ),
    );
    await settle();
  }

  /// Replaces the text of the field, which already holds focus, with [text]
  /// in one keystroke and returns before any frame runs, so a test can look
  /// inside the waits that follow; [edit] settles through them instead.
  void keystroke(String text) {
    tester.testTextInput.updateEditingValue(
      TextEditingValue(
        text: text,
        selection: TextSelection.collapsed(offset: text.length),
      ),
    );
  }

  /// Types [text] and commits it the way leaving the field with Tab does.
  Future<void> enter(String text) async {
    await type(text);
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await settle();
  }

  /// Types [text] and commits it with the keyboard's done action.
  Future<void> submit(String text) async {
    await type(text);
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await settle();
  }
}
