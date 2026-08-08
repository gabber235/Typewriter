import "package:flutter/foundation.dart";
import "package:typewriter_panel/typewriter_panel.dart";

class EditorController extends ChangeNotifier {
  EditorController({required EditorSource source}) : _source = source {
    _source.addListener(notifyListeners);
  }

  final EditorSource _source;

  ObjectBlueprint? get blueprint => _source.blueprint;

  EditorValue value(String path) => _source.value(path);

  void update(String path, dynamic value) => _source.update(path, value);

  @override
  void dispose() {
    _source
      ..removeListener(notifyListeners)
      ..dispose();
    super.dispose();
  }
}
