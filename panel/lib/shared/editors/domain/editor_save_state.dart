import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";

part "editor_save_state.freezed.dart";

/// Describes the strongest save condition currently affecting a path.
///
/// `saved` means the path is settled against canonical state. `pending` and
/// `saving` describe local work before acceptance. `failed`, `conflict`, and
/// `repeatedContention` require a caller decision or retry. `uncertain` means
/// delivery may have succeeded and must not be replayed blindly. The phase is
/// a read model for owner state, not proof that a request has or has not run.
enum EditorSavePhase {
  idle,
  pending,
  saving,
  saved,
  failed,
  uncertain,
  conflict,
  repeatedContention,
  deletedElsewhere,
}

/// Preserves the three values needed to resolve a path conflict.
///
/// `base` is the common canonical value, `local` is the draft choice, and
/// `remote` is the newer canonical choice. Keeping all three lets a caller
/// choose deliberately instead of losing the evidence that caused the
/// conflict.
@freezed
abstract class EditorPathConflict with _$EditorPathConflict {
  const factory EditorPathConflict({
    required skir.DataValue base,
    required skir.DataValue local,
    required skir.DataValue remote,
  }) = _EditorPathConflict;
}

/// Identifies why the persistence boundary repeatedly rejected a commit.
enum EditorContentionKind { versionMismatch }

/// Explains a contention outcome that exhausted the owner's retry budget.
///
/// The paths identify affected work. `expectedVersion` and `observedVersion`
/// preserve the revision evidence used by the failed attempt, while attempts
/// and retryLimit tell callers whether another automatic retry is appropriate.
final class EditorContentionDetails {
  EditorContentionDetails({
    required this.kind,
    required this.attempts,
    required this.retryLimit,
    required Iterable<skir.ValuePath> paths,
    this.expectedVersion,
    this.observedVersion,
  }) : paths = Set.unmodifiable(paths),
       assert(attempts > 0),
       assert(retryLimit >= 0),
       assert(attempts > retryLimit);

  final EditorContentionKind kind;
  final int attempts;
  final int retryLimit;
  final Set<skir.ValuePath> paths;
  final int? expectedVersion;
  final int? observedVersion;
}

/// The caller facing save read model for one path or its descendants.
///
/// Save state is deliberately separate from [EditorDocument]. The document is
/// canonical content and metadata. This value reports local draft progress,
/// persistence uncertainty, contention, conflict evidence, and diagnostics.
/// It may therefore be `saved` while another path is dirty, or `uncertain`
/// while canonical content remains unchanged. Callers use [canRetry] and the
/// typed details instead of guessing from a completed future or from content
/// equality.
@freezed
abstract class EditorSaveState with _$EditorSaveState {
  const factory EditorSaveState({
    required EditorSavePhase phase,
    skir.ValuePath? path,
    @Default(false) bool replayAvailable,
    Object? submissionId,
    EditorPathConflict? conflict,
    EditorContentionDetails? contention,
    @Default([]) List<EditorDiagnostic> diagnostics,
  }) = _EditorSaveState;
  const EditorSaveState._();

  bool get canRetry =>
      (phase == EditorSavePhase.uncertain && replayAvailable) ||
      phase == EditorSavePhase.failed ||
      phase == EditorSavePhase.repeatedContention;
}

/// Owns one reversible local interaction before it becomes persistence work.
///
/// `commit` releases the interaction gate and leaves the resulting draft for
/// the editor owner's save policy. It does not itself guarantee persistence.
/// `cancel` restores the interaction's local boundary. Overlapping sessions
/// are resolved by the owner so only one session controls a path.
abstract interface class EditorInteractionSession {
  skir.ValuePath get path;

  bool get active;

  Future<void> commit();

  void cancel();
}
