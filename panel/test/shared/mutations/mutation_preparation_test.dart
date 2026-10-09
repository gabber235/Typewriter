import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/typewriter_panel.dart";

void main() {
  test(
    "queued action reads latest drafts and replay keeps captured values",
    () async {
      final work = ScopedWorkSession();
      addTearDown(work.dispose);
      final blocker = await work.coordinator.reserve({"A"});
      final drafts = {"A": "red", "B": "red"};
      final requests = <List<String>>[];
      var preparations = 0;

      final combiner = MutationCombiner<String, int>(
        prepare: (operations) {
          preparations++;
          return PreparedCommit(
            id: "bulk",
            label: "Colors",
            resources: {"A", "B"},
            replay: SubmissionReplay.identicalRequest,
            send: () async {
              requests.add(operations);
              if (requests.length == 1) {
                return SubmissionResult.uncertain(
                  message: "Lost response",
                  cause: StateError("Disconnected"),
                  stackTrace: StackTrace.current,
                );
              }
              return const SubmissionResult.confirmed(1);
            },
          );
        },
      );
      final pending = MutationPreparation.collect([
        for (final id in ["A", "B"])
          CombinedMutation(
            combiner: combiner,
            resources: {id},
            prepare: () => MutationContribution(operation: "$id:${drafts[id]}"),
          ),
      ]);
      expect(pending, hasLength(1));
      final queued = work.enqueue(pending.single);
      drafts["A"] = "blue";
      expect(preparations, 0);

      blocker.release();
      final submission = await queued;
      expect(await submission.run(), isA<SubmissionUncertain>());
      drafts["A"] = "green";
      await submission.run();
      expect(preparations, 1);

      expect(requests, [
        ["A:blue", "B:red"],
        ["A:blue", "B:red"],
      ]);
      expect(identical(requests.first, requests.last), isTrue);
      expect(() => requests.first.add("C:red"), throwsUnsupportedError);
      expect(drafts["A"], "green");
    },
  );

  test(
    "scope identity groups authoring while independent requests stay separate",
    () {
      MutationCombiner<String, int> realm(String id) => MutationCombiner(
        prepare: (_) => PreparedCommit(
          id: id,
          label: id,
          send: () async => const SubmissionResult.confirmed(1),
        ),
      );
      final firstRealm = realm("first");
      final secondRealm = realm("second");
      final pending = MutationPreparation.collect([
        for (final scope in [firstRealm, firstRealm, secondRealm])
          CombinedMutation(
            combiner: scope,
            resources: {},
            prepare: () => const MutationContribution(operation: "book"),
          ),
        for (final id in ["hostA", "hostB"])
          IndependentMutation(
            PendingCommit(
              resources: {id},
              prepare: () => PreparedCommit(
                id: id,
                label: id,
                resources: {id},
                send: () async => const SubmissionResult.confirmed(1),
              ),
            ),
          ),
      ]);
      expect(pending, hasLength(4));
    },
  );

  test(
    "failed preparation releases reservation and disposes captured request",
    () async {
      final work = ScopedWorkSession();
      addTearDown(work.dispose);
      var disposed = false;
      await expectLater(
        work.enqueue(
          PendingCommit(
            resources: {"A"},
            prepare: () => PreparedCommit<int>(
              id: "invalid",
              label: "Invalid",
              resources: {"A", "B"},
              dispose: () => disposed = true,
              send: () async => const SubmissionResult.confirmed(1),
            ),
          ),
        ),
        throwsStateError,
      );
      expect(disposed, isTrue);
      final reservation = await work.coordinator.reserve({"A"});

      reservation.release();
      expect(work.submissions, isEmpty);
    },
  );
}
