import "dart:async";

import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/typewriter_panel.dart";

final _position = DataPath.root.field("position");
final _title = DataPath.root.field("title");
RecordValue _value(String title, int position) => RecordValue({
  "title": StringValue(title),
  "position": IntegerValue(BigInt.from(position)),
});
TransactionalEditorSource _source() => TransactionalEditorSource(
  document: EditorDocument(
    rootType: RecordType(
      fields: const {
        "title": TypeField(name: "title", type: StringType()),
        "position": TypeField(
          name: "position",
          type: IntegerType(width: IntegerWidth.signed32),
        ),
      },
    ),
    typeCatalog: const TypeCatalog([]),
    confirmedValue: _value("Original", 0),
    revision: 1,
  ),
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
      first.update(_title, const StringValue("Draft"));
      final response = Completer<void>();

      final batch = EditorBatch.submit(
        changes: {
          first: {_position: IntegerValue(BigInt.one)},
          second: {_position: IntegerValue(BigInt.two)},
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
      first.update(_position, IntegerValue(BigInt.from(3)));
      response.complete();
      await batch;
      expect(first.document.confirmedValue, _value("Original", 1));
      expect(first.value(DataPath.root).valueOrNull, _value("Draft", 3));

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
        first: {_position: IntegerValue(BigInt.one)},
        second: {_position: IntegerValue(BigInt.two)},
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

    expect(first.saveState(DataPath.root).phase, EditorSavePhase.uncertain);
    expect(second.saveState(DataPath.root).phase, EditorSavePhase.uncertain);
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
        first: {_position: IntegerValue(BigInt.one)},
        second: {_position: IntegerValue(BigInt.two)},
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
    source.update(_title, const StringValue("Earlier"));
    final later = source.beginInteraction(_title);
    source.update(_title, const StringValue("Later"));

    await later.commit();
    earlier.cancel();
    expect(source.value(_title).valueOrNull, const StringValue("Later"));
  });
}
