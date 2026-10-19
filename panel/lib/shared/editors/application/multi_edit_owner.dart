import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";

/// Presents several owners as one editor for multi selection editing.
///
/// A read returns loading or invalid state if any owner has that state, mixed
/// when owners disagree, and a ready value only when all owners agree. An
/// update is sent to every owner, but the aggregate is applied only when all
/// owners accept the same value. [SelectionInteractionCommit] prepares the
/// corresponding sessions together while each request retains its persistence
/// boundary. This class observes owners but never disposes them.
final class MultiEditOwner extends ChangeNotifier
    implements EditOwner, EditingControlOwner {
  MultiEditOwner({
    required List<EditOwner> owners,
    required this.rootType,
    required this.catalog,
  }) : owners = List.unmodifiable(owners) {
    if (this.owners.isEmpty) {
      throw ArgumentError.value(owners, "owners", "Must not be empty");
    }
    if ((Set<EditOwner>.identity()..addAll(this.owners)).length !=
        this.owners.length) {
      throw ArgumentError.value(
        owners,
        "owners",
        "Must contain identity unique owners",
      );
    }
    for (final owner in this.owners) {
      owner.addListener(notifyListeners);
    }
  }
  final List<EditOwner> owners;
  @override
  EditControl bindControl() => EditSelectionControl([
    for (final owner in owners)
      if (owner case final EditingControlOwner editing) editing.bindControl(),
  ]);
  @override
  final skir.TypeUse rootType;
  @override
  final CheckedEditorCatalog catalog;
  @override
  bool get readOnly => owners.any((owner) => owner.readOnly);
  @override
  EditorValue value(skir.ValuePath path) {
    final values = owners.map((owner) => owner.value(path)).toList();
    if (values.any((value) => value is LoadingEditorValue)) {
      return const EditorValue.loading();
    }
    final invalid = values.whereType<InvalidEditorValue>().firstOrNull;
    if (invalid != null) return invalid;

    final first = values.firstOrNull?.valueOrNull;
    if (first == null || values.any((value) => value.valueOrNull != first)) {
      return const EditorValue.mixed();
    }
    return EditorValue.ready(first);
  }

  @override
  EditorMutationResult update(skir.ValuePath path, skir.DataValue value) {
    return const SelectionEditingCoordinator().update(owners, path, value);
  }

  @override
  EditorMutationResult validate(skir.ValuePath path, skir.DataValue value) {
    if (readOnly) return const EditorMutationResult.conflict();
    return owners
        .map((owner) => owner.validate(path, value))
        .aggregateEditorMutationsFor(path);
  }

  @override
  EditorInteractionSession beginInteraction(skir.ValuePath path) =>
      _MultiInteraction(
        path,
        owners
            .map((owner) => owner.beginInteraction(path))
            .toList(growable: false),
      );
  @override
  void dispose() {
    for (final owner in owners) {
      owner.removeListener(notifyListeners);
    }
    super.dispose();
  }
}

final class _MultiInteraction implements EditorInteractionSession {
  _MultiInteraction(this.path, this.sessions);

  @override
  final skir.ValuePath path;
  final List<EditorInteractionSession> sessions;

  @override
  bool get active =>
      sessions.isNotEmpty && sessions.every((session) => session.active);

  @override
  Future<void> commit() => sessions.commitSelection();

  @override
  void cancel() {
    for (final session in sessions) {
      session.cancel();
    }
  }
}

extension IndependentInteractionCommit on Iterable<EditorInteractionSession> {
  /// Commits unrelated interactions without claiming atomic persistence.
  ///
  /// Use only for local editors and isolated examples. Resource selection editing uses [SelectionInteractionCommit].
  Future<void> commitIndependently() async {
    await Future.wait(map((session) => session.commit()));
  }
}

/// Combines per owner validation or update results without hiding disagreement.
/// Invalid diagnostics take precedence over conflicts. An applied result is
/// valid only when at least one owner accepts the path and every applied owner
/// returns the same value.
extension SelectionEditorMutationAggregation on Iterable<EditorMutationResult> {
  EditorMutationResult aggregateEditorMutationsFor(skir.ValuePath path) {
    final results = toList();
    final diagnostics = results
        .whereType<InvalidEditorMutation>()
        .expand((result) => result.diagnostics)
        .toList();
    if (diagnostics.isNotEmpty) {
      return EditorMutationResult.invalid(diagnostics);
    }
    if (results.any((result) => result is ConflictingEditorMutation)) {
      return const EditorMutationResult.conflict();
    }

    final applied = results.whereType<AppliedEditorMutation>().toList();
    if (applied.isEmpty) {
      return EditorMutationResult.invalid([
        EditorDiagnostic(
          code: EditorDiagnosticCode.invalidPath,
          message: "No inspected selection can accept the mutation",
          path: path,
        ),
      ]);
    }

    final accepted = applied.first.value;
    if (applied.skip(1).any((result) => result.value != accepted)) {
      return const EditorMutationResult.conflict();
    }
    return EditorMutationResult.applied(accepted);
  }
}
