import "dart:async";

import "package:flutter/foundation.dart";
import "package:flutter/scheduler.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:typewriter_panel/typewriter_panel.dart";

class SelectionEditorSource extends ChangeNotifier implements EditorSource {
  SelectionEditorSource(this._ref, {this.realmRuntime}) {
    _ref.listen(inspectedSelectionProvider, (_, next) {
      final error = next.asError?.error;
      if (error is SelectableNotFoundException) {
        _targets[error.id]?.source.acceptRemoteDeletion();
        return;
      }
      _synchronize();
    });
    _synchronize();
  }

  final Ref _ref;
  final EditorRealmRuntime? realmRuntime;
  final Map<SelectableIdentifier, _TargetEditorState> _targets = {};
  List<InspectableSelectable> _selection = const [];

  @override
  EditorDocument? get document {
    if (_selection.isEmpty) return null;
    if (_selection.length == 1) {
      return _targets[_selection.single.id]?.source.document;
    }
    final rootType = _ref.read(inspectedRootTypeProvider);
    if (rootType == null) return null;
    final first = _targets[_selection.first.id]!.source.document;
    return first.copyWith(
      rootType: rootType,
      typeCatalog: _selection.mergedTypeCatalog,
      clearRootPresentation: true,
      presentations: const [],
      collections: const [],
      revision: _targets.values
          .map((target) => target.source.document.revision)
          .fold<int>(
            0,
            (maximum, revision) => revision > maximum ? revision : maximum,
          ),
    );
  }

  @override
  EditorValue value(DataPath path) {
    final inspected = _ref.read(inspectedSelectionProvider);
    if (inspected.isLoading && !inspected.hasValue) {
      return const EditorValue.loading();
    }
    if (_selection.isEmpty) {
      return EditorValue.invalid([
        const TypeDiagnostic(
          code: TypeDiagnosticCode.invalidValue,
          message: "No values are selected",
        ),
      ]);
    }
    final values = _selection
        .map((target) => _targets[target.id]!.source.value(path))
        .toList();
    final diagnostics = values
        .whereType<InvalidEditorValue>()
        .expand((value) => value.diagnostics)
        .toList();
    if (diagnostics.isNotEmpty) return EditorValue.invalid(diagnostics);
    if (values.any((value) => value is LoadingEditorValue)) {
      return const EditorValue.loading();
    }
    if (values.any((value) => value is! ReadyEditorValue)) {
      return const EditorValue.conflict();
    }
    final ready = values.cast<ReadyEditorValue>();
    final first = ready.first.value;
    if (ready.skip(1).any((value) => value.value != first)) {
      return const EditorValue.conflict();
    }
    return EditorValue.ready(first);
  }

  @override
  EditorMutationResult update(
    DataPath path,
    DataValue value, {
    EditorStructuralMutation? structuralMutation,
  }) {
    _synchronize(notify: false);
    final validation = _selection
        .map((target) => target.validate(path, value))
        .aggregateEditorMutationsFor(path);
    if (validation is! AppliedEditorMutation) return validation;
    for (final target in _selection) {
      _targets[target.id]!.source.update(
        path,
        value,
        structuralMutation: structuralMutation,
      );
    }
    return validation;
  }

  @override
  EditorInteractionSession beginInteraction(DataPath path) {
    _synchronize(notify: false);
    return _SelectionInteractionSession(
      path,
      _selection
          .map((target) => _targets[target.id]!.source.beginInteraction(path))
          .toList(),
    );
  }

  @override
  EditorSaveState saveState(DataPath path) {
    final states = _selection
        .map((target) => _targets[target.id]!.source.saveState(path))
        .toList();
    if (states.isEmpty) return const EditorSaveState.idle();
    states.sort(
      (left, right) => selectionSavePriority(
        right.phase,
      ).compareTo(selectionSavePriority(left.phase)),
    );
    return states.first;
  }

  @override
  Future<TypedMutationResult> flush({Set<DataPath>? paths}) async {
    _synchronize(notify: false);
    return aggregateSelectionResults(
      await Future.wait(
        _selection.map(
          (target) => _targets[target.id]!.source.flush(paths: paths),
        ),
      ),
    );
  }

  @override
  Future<EditorActionResult> executeAction(
    EditorAction action,
    ExpressionContext context,
    Map<BindingId, BindingReference> aliases,
  ) async {
    _synchronize(notify: false);
    if (action case RealmEditorAction(:final action)) {
      final runtime = realmRuntime;
      if (runtime == null) {
        return RealmEditorActionResult(
          RealmCommandResult.unavailable([
            const TypeDiagnostic(
              code: TypeDiagnosticCode.invalidPresentation,
              message: "Realm capability runtime is unavailable",
            ),
          ]),
        );
      }
      return RealmEditorActionResult(
        await runtime.executeAction(action, context),
      );
    }
    final entries = _selection.map((target) => _targets[target.id]!).toList();
    final results = await Future.wait(
      entries.map((entry) async {
        final result = await entry.source.executeAction(
          action,
          context,
          aliases,
        );
        if (result case LocalEditorActionResult(
          mutation: MutationConflict(:final actualRevision, :final actualValue),
        )) {
          entry.source.acceptRemote(
            revision: actualRevision,
            value: actualValue,
          );
        }
        return result;
      }),
    );
    final local = results.whereType<LocalEditorActionResult>().toList();
    if (local.length != results.length) {
      return RealmEditorActionResult(
        RealmCommandResult.unavailable([
          const TypeDiagnostic(
            code: TypeDiagnosticCode.invalidValue,
            message: "Selection returned incompatible action results",
          ),
        ]),
      );
    }
    return LocalEditorActionResult(
      aggregateSelectionResults(local.map((item) => item.mutation).toList()),
    );
  }

  @override
  void acceptRemote({required int revision, required DataValue value}) {
    if (_selection.length != 1) return;
    _targets[_selection.single.id]?.source.acceptRemote(
      revision: revision,
      value: value,
    );
  }

  @override
  void refreshDocument(EditorDocument document) {
    if (_selection.length != 1) return;
    _targets[_selection.single.id]?.source.refreshDocument(document);
  }

  @override
  void acceptRemoteDeletion() {
    if (_selection.length != 1) return;
    _targets[_selection.single.id]?.source.acceptRemoteDeletion();
  }

  @override
  void useRemote(DataPath path) {
    _synchronize(notify: false);
    for (final target in _selection) {
      _targets[target.id]!.source.useRemote(path);
    }
  }

  @override
  Future<TypedMutationResult> keepLocal(DataPath path) async {
    _synchronize(notify: false);
    return aggregateSelectionResults(
      await Future.wait(
        _selection.map((target) => _targets[target.id]!.source.keepLocal(path)),
      ),
    );
  }

  void _synchronize({bool notify = true}) {
    final selected = _ref.read(inspectedSelectionProvider).value;
    if (selected == null) return;
    final selectionChanged = !listEquals(
      _selection.map((target) => target.id).toList(),
      selected.map((target) => target.id).toList(),
    );
    final selectedIds = selected.map((target) => target.id).toSet();
    final removed = _targets.keys
        .where((id) => !selectedIds.contains(id))
        .toList();
    for (final id in removed) {
      _targets.remove(id)?.source.dispose();
    }
    for (final target in selected) {
      final existing = _targets[target.id];
      if (existing == null) {
        late final _TargetEditorState state;
        final source = TransactionalEditorSource(
          document: target.document,
          validate: (path, value) => state.target.validate(path, value),
          commit: (commit) => state.target.commit(commit),
          onDeleted: () {
            SchedulerBinding.instance.addPostFrameCallback((_) {
              _ref.read(selectionProvider.notifier).unselect(target.id);
            });
            SchedulerBinding.instance.ensureVisualUpdate();
          },
        );
        state = _TargetEditorState(target: target, source: source);
        source.addListener(notifyListeners);
        _targets[target.id] = state;
        continue;
      }
      existing.target = target;
      final document = target.document;
      if (!existing.source.document.hasSameContent(document)) {
        existing.source.refreshDocument(document);
      }
    }
    _selection = selected;
    if (notify && selectionChanged) notifyListeners();
  }

  @override
  void dispose() {
    for (final target in _targets.values) {
      target.source
        ..removeListener(notifyListeners)
        ..dispose();
    }
    _targets.clear();
    super.dispose();
  }
}

final class _TargetEditorState {
  _TargetEditorState({required this.target, required this.source});

  InspectableSelectable target;
  final TransactionalEditorSource source;
}

final class _SelectionInteractionSession implements EditorInteractionSession {
  _SelectionInteractionSession(this.path, this.sessions);

  @override
  final DataPath path;
  final List<EditorInteractionSession> sessions;

  @override
  bool get active => sessions.any((session) => session.active);

  @override
  Future<TypedMutationResult> commit() async => aggregateSelectionResults(
    await Future.wait(sessions.map((session) => session.commit())),
  );

  @override
  void cancel() {
    for (final session in sessions) {
      session.cancel();
    }
  }
}
