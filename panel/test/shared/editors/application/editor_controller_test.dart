import "package:flutter/foundation.dart";
import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/typewriter_panel.dart";

class _EditorSource extends ChangeNotifier implements EditorSource {
  _EditorSource({this.current = const EditorValue.none()});

  EditorValue current;
  String? updatedPath;
  dynamic updatedValue;
  bool disposed = false;

  @override
  ObjectBlueprint? get blueprint => null;

  @override
  EditorValue value(String path) => current;

  @override
  void update(String path, dynamic value) {
    updatedPath = path;
    updatedValue = value;
  }

  void replace(EditorValue value) {
    current = value;
    notifyListeners();
  }

  @override
  void dispose() {
    disposed = true;
    super.dispose();
  }
}

void main() {
  test("forwards source values and updates", () {
    final source = _EditorSource(current: const EditorValue.value("before"));
    final controller = EditorController(source: source);

    expect((controller.value("name") as Value).value, "before");

    controller.update("name", "after");

    expect(source.updatedPath, "name");
    expect(source.updatedValue, "after");
  });

  test("forwards source notifications", () {
    final source = _EditorSource();
    final controller = EditorController(source: source);
    var notifications = 0;
    controller.addListener(() => notifications++);

    source.replace(const EditorValue.value("updated"));

    expect(notifications, 1);
    expect((controller.value("name") as Value).value, "updated");
  });

  test("disposes its source", () {
    final source = _EditorSource();
    EditorController(source: source).dispose();

    expect(source.disposed, isTrue);
  });
}
