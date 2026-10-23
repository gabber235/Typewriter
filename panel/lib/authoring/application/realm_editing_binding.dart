import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";

/// A view lease into shared form work. Detach never saves or discards edits.
final class RealmEditingBinding extends ChangeNotifier {
  RealmEditingBinding(this.workspace, this.resource, this.editingGroup) {
    control = workspace.workspace.group(editingGroup);
    control.addListener(_updated);
  }
  final RealmEditing workspace;
  late final EditGroupControl<AuthoringDocument, RealmPreparedEdit> control;
  final skir.ResourceId resource;
  final EditGroupId editingGroup;
  var _detached = false;
  String? _message;
  AuthoringDocument get document => workspace.document;
  EditGroupPhase<AuthoringDocument>? get phase =>
      workspace.state.groups[editingGroup]?.phase;
  String? get status => _message;
  bool get dirty => control.state.hasWork;
  bool get saving => phase?.active ?? false;
  bool get blocked => !control.canEdit;
  bool get hasSubmittedWork => control.state.hasSubmittedWork;
  List<EditGroup<AuthoringDocument>> get relatedGroups => workspace
      .state
      .groups
      .values
      .where(
        (group) =>
            group.resources.contains(resource) && group.id != editingGroup,
      )
      .toList(growable: false);

  EditStageResult edit({
    required String label,
    required void Function(AuthoringEdit edit) apply,
    AuthoringDocument? from,
  }) {
    if (_detached) {
      return const EditStageResult.rejected("This editor is closed", null);
    }
    final result = workspace.edit(
      label: label,
      group: editingGroup,
      apply: apply,
      from: from,
    );
    _message = result is EditStageRejected ? result.message : null;
    _updated();
    return result;
  }

  /// Prepares initialization privately, then validates its observations at publish.
  Future<EditStageResult> prepare({
    required String label,
    required Future<void> Function(AuthoringEdit edit) apply,
    AuthoringDocument? from,
  }) async {
    if (_detached || blocked) {
      return const EditStageResult.rejected("The editor is unavailable", null);
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
    _message = result is EditStageRejected ? result.message : null;
    _updated();
    return result;
  }

  EditStageResult stagePrepared({
    required String label,
    required skir.PreparedEdit edit,
  }) {
    if (_detached || blocked) {
      return const EditStageResult.rejected("The editor is unavailable", null);
    }
    final result = workspace.stagePrepared(
      group: editingGroup,
      label: label,
      edit: edit,
    );
    _message = result is EditStageRejected ? result.message : null;
    _updated();
    return result;
  }

  Future<void> save() => control.apply();
  bool discard() {
    _message = null;
    return control.discard();
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
    control
      ..removeListener(_updated)
      ..dispose();
    super.dispose();
  }
}
