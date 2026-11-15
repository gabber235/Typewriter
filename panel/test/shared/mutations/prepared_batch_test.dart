import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/typewriter_panel.dart";

void main() {
  test("items prepared in one turn travel as one request that every member "
      "reads its reply from", () async {
    final sent = <List<String>>[];
    final batches = PreparedBatches<String, String>(
      (items) => PreparedCommit(
        id: "batch",
        label: "Rename",
        send: () async {
          sent.add(items);
          return SubmissionResult.confirmed(items.join(","));
        },
      ),
    );

    final lobby = batches.join("lobby", label: "Rename lobby");
    final arena = batches.join("arena", label: "Rename arena");

    expect(await lobby.send(), const SubmissionResult.confirmed("lobby,arena"));
    expect(await arena.send(), const SubmissionResult.confirmed("lobby,arena"));
    expect(sent, [
      ["lobby", "arena"],
    ]);
  });

  test("an item prepared in a later turn starts its own request", () async {
    final sent = <List<String>>[];
    final batches = PreparedBatches<String, int>(
      (items) => PreparedCommit(
        id: "batch",
        label: "Rename",
        send: () async {
          sent.add(items);
          return SubmissionResult.confirmed(items.length);
        },
      ),
    );

    final first = batches.join("lobby", label: "Rename lobby");
    await Future<void>.value();
    final later = batches.join("arena", label: "Rename arena");

    await Future.wait([first.send(), later.send()]);
    expect(sent, [
      ["lobby"],
      ["arena"],
    ]);
  });

  test("members that send again together share one resend of the whole "
      "request, and a reply integrates once per attempt", () async {
    final sent = <List<String>>[];
    final integrated = <SubmissionResult<int>>[];
    final batches = PreparedBatches<String, int>(
      (items) => PreparedCommit(
        id: "batch",
        label: "Rename",
        replay: SubmissionReplay.identicalRequest,
        send: () async {
          sent.add(items);
          return SubmissionResult.confirmed(sent.length);
        },
        integrate: (result) async => integrated.add(result),
      ),
    );
    final lobby = batches.join("lobby", label: "Rename lobby");
    final arena = batches.join("arena", label: "Rename arena");

    for (final member in [lobby, arena]) {
      await member.integrate!(await member.send());
    }
    expect(await lobby.send(), const SubmissionResult.confirmed(2));
    expect(await arena.send(), const SubmissionResult.confirmed(2));
    await lobby.integrate!(const SubmissionResult.confirmed(2));
    await arena.integrate!(const SubmissionResult.confirmed(2));

    expect(sent, [
      ["lobby", "arena"],
      ["lobby", "arena"],
    ]);
    expect(integrated, [
      const SubmissionResult.confirmed(1),
      const SubmissionResult.confirmed(2),
    ]);
  });
}
