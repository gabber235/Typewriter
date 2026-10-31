import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";

/// Matches an edit that saves against the content it was read from and is
/// refused once [remoteChange] changed what it read: an [AuthoringEdit] the
/// panel prepares, or a [skir.PreparedEdit] it sent to the Realm.
///
/// [saved] is that content: an [AuthoringDocument], or a function opening a
/// fresh [AuthoringEdit] of it each time it is called, for model tests whose
/// content has no catalog to form a document.
///
/// States what an edit's expectations are for, instead of listing them: a
/// save is refused when content it depends on changed since it was read.
Matcher refusedAfter(
  void Function(AuthoringEdit remote) remoteChange, {
  required Object saved,
}) => _RefusedAfter(remoteChange, switch (saved) {
  final AuthoringDocument document => () => AuthoringEdit.fromDocument(
    document,
  ),
  final AuthoringEdit Function() open => open,
  _ => throw ArgumentError.value(saved, "saved", "is no saved content"),
});

final class _RefusedAfter extends Matcher {
  const _RefusedAfter(this._remoteChange, this._saved);

  final void Function(AuthoringEdit remote) _remoteChange;
  final AuthoringEdit Function() _saved;

  List<skir.EditExpectation> _expectations(Object? edit) => switch (edit) {
    final AuthoringEdit edit => edit.prepare().expectations.toList(),
    final skir.PreparedEdit edit => edit.expectations.toList(),
    _ => throw ArgumentError.value(edit, "edit", "is no edit"),
  };

  @override
  bool matches(Object? item, Map<Object?, Object?> matchState) {
    final expectations = _expectations(item);
    if (_saved().currentFacts.conflicts(expectations).isNotEmpty) {
      matchState["reason"] =
          "it does not save against the content it was "
          "read from";
      return false;
    }
    final remote = _saved();
    _remoteChange(remote);
    if (remote.currentFacts.conflicts(expectations).isEmpty) {
      matchState["reason"] =
          "it still saves once the remote change saved "
          "first";
      return false;
    }
    return true;
  }

  @override
  Description describe(Description description) => description.add(
    "an edit that saves against the content it was read from and is "
    "refused once the remote change saved first",
  );

  @override
  Description describeMismatch(
    Object? item,
    Description mismatchDescription,
    Map<Object?, Object?> matchState,
    bool verbose,
  ) => mismatchDescription.add("${matchState["reason"]}");
}

/// Documents as another author's save leaves them.
extension RemoteChange on AuthoringDocument {
  /// This document after another author saved [change].
  AuthoringDocument changedRemotely(void Function(AuthoringEdit edit) change) {
    final edit = AuthoringEdit.fromDocument(this);
    change(edit);
    return edit.toDocument();
  }
}

/// An edit expectation that the text at [at] still reads [value].
skir.EditExpectation textExpectation(skir.ValueLocation at, String value) =>
    skir.EditExpectation.createValue(
      at: at,
      expected: skir.DataValue.wrapStringValue(value),
    );

/// An edit intent that sets the text at [at] to [value].
skir.EditIntent setTextIntent(skir.ValueLocation at, String value) =>
    skir.EditIntent.createSetValue(
      at: at,
      value: skir.DataValue.wrapStringValue(value),
    );

/// A prepared edit read from [saved], stating what it [expects] and the
/// [intents] it applies.
skir.PreparedEdit preparedEdit(
  AuthoringDocument saved, {
  required List<skir.EditExpectation> expects,
  required List<skir.EditIntent> intents,
}) => skir.PreparedEdit(
  catalog: saved.generation,
  expectations: expects,
  intents: intents,
);
