import "package:flutter/foundation.dart";
import "package:typewriter_panel/typewriter_panel.dart";

class EditorController extends ChangeNotifier {
  EditorController({required EditorSource source}) : _source = source {
    _source.addListener(notifyListeners);
  }

  final EditorSource _source;

  EditorDocument? get document => _source.document;

  TypeExpression? get rootType => document?.rootType;

  TypeRegistry? get registry {
    final current = document;
    return current == null ? null : TypeRegistry(current.typeCatalog);
  }

  EditorValue value(DataPath path) => _source.value(path);

  EditorMutationResult update(DataPath path, DataValue value) =>
      _source.update(path, value);

  void refreshDocument(EditorDocument document) =>
      _source.refreshDocument(document);

  EditorInteractionSession beginInteraction(DataPath path) =>
      _source.beginInteraction(path);

  EditorSaveState saveState(DataPath path) => _source.saveState(path);

  Future<TypedMutationResult> flush({Set<DataPath>? paths}) =>
      _source.flush(paths: paths);

  Future<TypedMutationResult> executeAction(
    EditorAction action,
    ExpressionContext context,
    Map<BindingId, BindingReference> aliases,
  ) => _source.executeAction(action, context, aliases);

  void acceptRemote({required int revision, required DataValue value}) =>
      _source.acceptRemote(revision: revision, value: value);

  void acceptRemoteDeletion() => _source.acceptRemoteDeletion();

  void useRemote(DataPath path) => _source.useRemote(path);

  Future<TypedMutationResult> keepLocal(DataPath path) =>
      _source.keepLocal(path);

  @override
  void dispose() {
    _source
      ..removeListener(notifyListeners)
      ..dispose();
    super.dispose();
  }
}
