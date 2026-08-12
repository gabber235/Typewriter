import "package:flutter/foundation.dart";
import "package:typewriter_panel/typewriter_panel.dart";

class EditorController extends ChangeNotifier {
  EditorController({required EditorSource source}) : _source = source {
    _source.addListener(notifyListeners);
  }

  final EditorSource _source;

  TypeExpression? get rootType => _source.rootType;

  TypeRegistry? get registry => _source.registry;

  EditorValue value(DataPath path) => _source.value(path);

  EditorMutationResult update(DataPath path, DataValue value) =>
      _source.update(path, value);

  @override
  void dispose() {
    _source
      ..removeListener(notifyListeners)
      ..dispose();
    super.dispose();
  }
}
