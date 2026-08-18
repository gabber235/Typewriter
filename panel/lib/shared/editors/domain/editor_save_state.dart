import "package:typewriter_panel/typewriter_panel.dart";

enum EditorSavePhase {
  idle,
  pending,
  saving,
  saved,
  sessionOnly,
  failed,
  conflict,
  repeatedContention,
  deletedElsewhere,
}

final class EditorPathConflict {
  const EditorPathConflict({
    required this.base,
    required this.local,
    required this.remote,
  });

  final DataValue base;
  final DataValue local;
  final DataValue remote;
}

final class EditorSaveState {
  const EditorSaveState({
    required this.phase,
    this.path,
    this.conflict,
    this.diagnostics = const [],
  });

  const EditorSaveState.idle() : this(phase: EditorSavePhase.idle);

  final EditorSavePhase phase;
  final DataPath? path;
  final EditorPathConflict? conflict;
  final List<TypeDiagnostic> diagnostics;

  bool get canRetry =>
      phase == EditorSavePhase.failed ||
      phase == EditorSavePhase.repeatedContention;
}

abstract interface class EditorInteractionSession {
  DataPath get path;

  bool get active;

  Future<TypedMutationResult> commit();

  void cancel();
}
