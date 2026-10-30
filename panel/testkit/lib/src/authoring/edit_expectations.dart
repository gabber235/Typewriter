import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";

/// Expects [edit] to save against the [saved] document it was read from and
/// to be refused once [remoteChange] changed what it read.
///
/// States what an edit's expectations are for, instead of listing them: a
/// save is refused when content it depends on changed since it was read.
void expectRefusedAfterRemoteChange(
  AuthoringEdit edit, {
  required AuthoringDocument saved,
  required void Function(AuthoringEdit remote) remoteChange,
}) {
  final expectations = edit.prepare().expectations;
  expect(
    saved.facts.conflicts(expectations),
    isEmpty,
    reason: "The edit saves against the document it was read from",
  );
  expect(
    saved.changedRemotely(remoteChange).facts.conflicts(expectations),
    isNotEmpty,
    reason: "The edit is refused once the remote change saved first",
  );
}

/// Expects the save [sent] to the Realm to apply to the [saved] document it
/// was read from and to be refused once [remoteChange] changed what it read;
/// [expectRefusedAfterRemoteChange] for an edit the panel sent.
void expectSaveRefusedAfterRemoteChange(
  skir.PreparedEdit sent, {
  required AuthoringDocument saved,
  required void Function(AuthoringEdit remote) remoteChange,
}) {
  expect(
    saved.facts.conflicts(sent.expectations),
    isEmpty,
    reason: "The save applies to the document it was read from",
  );
  expect(
    saved.changedRemotely(remoteChange).facts.conflicts(sent.expectations),
    isNotEmpty,
    reason: "The save is refused once the remote change saved first",
  );
}

/// [expectRefusedAfterRemoteChange] for model tests whose saved content has
/// no catalog to form a document: [saved] opens a fresh edit of the saved
/// content each time it is called.
void expectEditRefusedAfterRemoteChange(
  AuthoringEdit edit, {
  required AuthoringEdit Function() saved,
  required void Function(AuthoringEdit remote) remoteChange,
}) {
  final expectations = edit.prepare().expectations;
  expect(
    saved().currentFacts.conflicts(expectations),
    isEmpty,
    reason: "The edit saves against the content it was read from",
  );
  final remote = saved();
  remoteChange(remote);
  expect(
    remote.currentFacts.conflicts(expectations),
    isNotEmpty,
    reason: "The edit is refused once the remote change saved first",
  );
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
