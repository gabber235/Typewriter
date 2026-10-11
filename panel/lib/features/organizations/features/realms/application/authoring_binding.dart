part of "authoring_workspace.dart";

/// A view lease into shared form work. Detach never saves or discards edits.
final class AuthoringBinding extends ChangeNotifier {
  AuthoringBinding._(this.workspace, this.resource, this.editingGroup) {
    workspace.addListener(_updated);
  }
  final AuthoringWorkspace workspace;
  final skir.ResourceId resource;
  final AuthoringGroupId editingGroup;
  var _detached = false;
  String? _message;
  AuthoringDocument get document => workspace.document;
  AuthoringGroupPhase? get phase => workspace.state.groups[editingGroup]?.phase;
  String? get status => _message ?? phase?.message;
  bool get dirty => workspace.state.groups.containsKey(editingGroup);
  bool get saving => phase is AuthoringGroupSaving;
  bool get blocked =>
      workspace.state.confirmed?.generation !=
          workspace.state.working?.generation ||
      (phase?.blocked ?? false);
  bool get canDiscard => workspace.canDiscard(editingGroup);
  bool get hasSubmittedWork =>
      phase is AuthoringGroupSaving ||
      phase is AuthoringGroupCommittedAwaitingRefresh ||
      phase is AuthoringGroupUncertain;
  List<AuthoringGroup> get relatedGroups => workspace.state.groups.values
      .where(
        (group) =>
            group.resources.contains(resource) && group.id != editingGroup,
      )
      .toList(growable: false);

  AuthoringEditResult edit({
    required String label,
    required void Function(AuthoringEdit edit) apply,
    AuthoringDocument? from,
  }) {
    if (_detached) {
      return const AuthoringEditResult.rejected("This editor is closed", null);
    }
    final result = workspace.edit(
      label: label,
      group: editingGroup,
      apply: apply,
      from: from,
    );
    _message = result is AuthoringEditRejected ? result.message : null;
    _updated();
    return result;
  }

  /// Prepares initialization privately, then validates its observations at publish.
  Future<AuthoringEditResult> prepare({
    required String label,
    required Future<void> Function(AuthoringEdit edit) apply,
    AuthoringDocument? from,
  }) async {
    if (_detached || blocked) {
      return const AuthoringEditResult.rejected(
        "The editor is unavailable",
        null,
      );
    }
    final result = await workspace.prepare(
      label: label,
      group: editingGroup,
      from: from,
      apply: (operation) async {
        await apply(operation);
        if (_detached) throw StateError("This editor is closed");
      },
    );
    _message = result is AuthoringEditRejected ? result.message : null;
    _updated();
    return result;
  }

  AuthoringEditResult stagePrepared({
    required String label,
    required skir.PreparedEdit edit,
  }) {
    if (_detached || blocked) {
      return const AuthoringEditResult.rejected(
        "The editor is unavailable",
        null,
      );
    }
    final result = workspace.stagePrepared(
      group: editingGroup,
      label: label,
      edit: edit,
    );
    _message = result is AuthoringEditRejected ? result.message : null;
    _updated();
    return result;
  }

  Future<void> save() => workspace.save(editingGroup);
  bool discard() {
    _message = null;
    return workspace.discard(editingGroup);
  }

  void reportStatus(String message) {
    _message = message;
    _updated();
  }

  void _updated() {
    if (!_detached) notifyListeners();
  }

  void detach() => dispose();
  @override
  void dispose() {
    if (_detached) return;
    _detached = true;
    workspace.removeListener(_updated);
    super.dispose();
  }
}
