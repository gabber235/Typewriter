import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";

import "../../../support/editor_fixture.dart";

final _position = editorRootPath.field("position");
final _title = editorRootPath.field("title");
skir.DataValue _value(String title, int position) => recordEditorValue({
  "title": skir.DataValue.wrapStringValue(title),
  "position": skir.DataValue.wrapInteger("$position"),
});
TransactionalEditorSource _source() => TransactionalEditorSource(
  document: recordEditorDocument(
    {
      "title": skir.DataValue.wrapStringValue("Original"),
      "position": skir.DataValue.wrapInteger("0"),
    },
    _fieldTypes,
    1,
  ),
  validation: (path, value) => EditorMutationResult.applied(value),
  debounce: const Duration(days: 1),
  commit: (commit) async =>
      MutationSuccess(revision: 3, value: commit.rootValue),
);

void main() {
  test(
    "batch captures only intended paths and preserves later edits",
    () async {
      final first = _source();
      final second = _source();
      addTearDown(first.dispose);
      addTearDown(second.dispose);
      first.update(_title, skir.DataValue.wrapStringValue("Draft"));
      final response = Completer<void>();

      final batch = EditorBatch.submit(
        changes: {
          first: {_position: skir.DataValue.wrapInteger("1")},
          second: {_position: skir.DataValue.wrapInteger("2")},
        },
        send: (commits) async {
          expect(commits.length, 2);
          expect(commits[first]!.rootValue, _value("Original", 1));
          await response.future;
          return {
            for (final entry in commits.entries)
              entry.key: MutationSuccess(
                revision: 2,
                value: entry.value.rootValue,
              ),
          };
        },
      );
      first.update(_position, skir.DataValue.wrapInteger("3"));
      response.complete();
      await batch;
      expect(first.document.confirmedValue, _value("Original", 1));
      expect(first.value(editorRootPath).valueOrNull, _value("Draft", 3));

      expect(second.hasWork, isFalse);
    },
  );

  test("one replay settles every member without sending a new batch", () async {
    final first = _source();
    final second = _source();
    addTearDown(first.dispose);
    addTearDown(second.dispose);
    var sends = 0;
    await EditorBatch.submit(
      changes: {
        first: {_position: skir.DataValue.wrapInteger("1")},
        second: {_position: skir.DataValue.wrapInteger("2")},
      },
      send: (commits) async {
        final submission = MutationSubmission<int>(
          id: "batch",
          label: "Move",
          replay: SubmissionReplay.identicalRequest,
          send: () async => ++sends == 1
              ? SubmissionResult.uncertain(
                  message: "Lost",
                  cause: TimeoutException("Lost"),
                  stackTrace: StackTrace.current,
                )
              : const SubmissionResult.confirmed(2),
        );
        await submission.run();
        final error = SubmissionException(submission);
        return {
          for (final entry in commits.entries)
            entry.key: error.toMutation(
              (revision) async => MutationSuccess(
                revision: revision,
                value: entry.value.rootValue,
              ),
            ),
        };
      },
    );

    expect(first.saveState(editorRootPath).phase, EditorSavePhase.uncertain);
    expect(second.saveState(editorRootPath).phase, EditorSavePhase.uncertain);
    await first.flush();
    expect(sends, 2);
    expect(first.hasWork, isFalse);
    expect(second.hasWork, isFalse);
  });

  test("retrying one rejected member resubmits the complete batch", () async {
    final first = _source();
    final second = _source();
    addTearDown(first.dispose);
    addTearDown(second.dispose);
    var sends = 0;
    await EditorBatch.submit(
      changes: {
        first: {_position: skir.DataValue.wrapInteger("1")},
        second: {_position: skir.DataValue.wrapInteger("2")},
      },
      send: (commits) async {
        sends++;
        expect(commits.length, 2);
        return {
          for (final entry in commits.entries)
            entry.key: sends == 1
                ? invalidMutation("Rejected batch")
                : MutationSuccess(revision: 2, value: entry.value.rootValue),
        };
      },
    );

    expect(first.hasWork, isTrue);
    expect(second.hasWork, isTrue);
    await first.flush();
    expect(sends, 2);
    expect(first.hasWork, isFalse);
    expect(second.hasWork, isFalse);
  });

  test("superseded interaction cannot cancel a later edit", () async {
    final source = _source();
    addTearDown(source.dispose);
    final earlier = source.beginInteraction(_title);
    source.update(_title, skir.DataValue.wrapStringValue("Earlier"));
    final later = source.beginInteraction(_title);
    source.update(_title, skir.DataValue.wrapStringValue("Later"));

    await later.commit();
    earlier.cancel();
    expect(
      source.value(_title).valueOrNull,
      skir.DataValue.wrapStringValue("Later"),
    );
  });
}

final _fieldTypes = {
  "title": skir.TypeTemplate.wrapScalar(skir.ScalarKind.text),
  "position": skir.TypeTemplate.wrapScalar(
    skir.ScalarKind.createInteger(width: skir.IntegerWidth.signedThirtyTwo),
  ),
};
