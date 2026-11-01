import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/typewriter_panel.dart";

/// A replay safe save of a name whose sends answer the scripted replies in
/// order: a [SubmissionResult] is the answer, any other entry is thrown, as
/// when the reply is lost. A send past the script is confirmed with "Saved".
/// With [redelivery], the submission resends an unanswered save on its own.
/// The submission ends with the test.
final class ScriptedSave {
  ScriptedSave(List<Object> replies, {EditorDelayScheduler? redelivery})
    : _replies = [...replies] {
    submission = MutationSubmission<String>(
      id: "save",
      label: "Save name",
      replay: SubmissionReplay.identicalRequest,
      redelivery: redelivery,
      send: _send,
    );
    addTearDown(submission.dispose);
  }

  final List<Object> _replies;

  /// The submission that sends the save.
  late final MutationSubmission<String> submission;

  /// How many times the save was sent.
  int sends = 0;

  Future<SubmissionResult<String>> _send() async {
    sends++;
    if (_replies.isEmpty) return const SubmissionResult.confirmed("Saved");
    return switch (_replies.removeAt(0)) {
      final SubmissionResult<String> answer => answer,
      final lost => throw lost,
    };
  }
}
