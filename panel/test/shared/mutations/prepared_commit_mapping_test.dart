import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/typewriter_panel.dart";

void main() {
  test(
    "a mapped commit keeps its request identity, replay and release",
    () async {
      var released = 0;
      final mapped = PreparedCommit<int>(
        id: "request",
        label: "Save host",
        resources: {"host"},
        replay: SubmissionReplay.identicalRequest,
        dispose: () => released++,
        send: () async => const SubmissionResult.confirmed(2),
      ).mapResponse((value) => "revision $value");

      expect(mapped.id, "request");
      expect(mapped.label, "Save host");
      expect(mapped.resources, {"host"});
      expect(mapped.replay, SubmissionReplay.identicalRequest);
      mapped.dispose?.call();
      expect(released, 1);
      expect(
        await mapped.send(),
        const SubmissionResult<String>.confirmed("revision 2"),
      );
    },
  );

  test(
    "a mapped commit integrates the response the request received",
    () async {
      final integrated = <SubmissionResult<int>>[];
      final mapped = PreparedCommit<int>(
        id: "request",
        label: "Save host",
        send: () async =>
            const SubmissionResult.rejected(message: "Stale", response: 3),
        integrate: (result) async => integrated.add(result),
      ).mapResponse((value) => "revision $value");

      await mapped.integrate!(const SubmissionResult.confirmed("ignored"));
      expect(integrated, isEmpty, reason: "nothing was received yet");

      expect(
        await mapped.send(),
        const SubmissionResult<String>.rejected(
          message: "Stale",
          response: "revision 3",
        ),
      );
      await mapped.integrate!(const SubmissionResult.confirmed("ignored"));
      expect(integrated, [
        const SubmissionResult<int>.rejected(message: "Stale", response: 3),
      ]);
    },
  );
}
