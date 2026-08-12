import "package:flutter/material.dart";
import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/typewriter_panel.dart";

import "../../../../support/test_utils.dart";

final class TestEditorSource extends ChangeNotifier implements EditorSource {
  TestEditorSource({
    required this.rootType,
    required DataValue value,
    this.registry,
  }) : _value = value;

  @override
  final TypeExpression rootType;

  @override
  final TypeRegistry? registry;

  DataValue _value;

  DataValue get rootValue => _value;

  @override
  EditorValue value(DataPath path) => _value.readEditorValue(path);

  @override
  EditorMutationResult update(DataPath path, DataValue value) {
    final validation = rootType.validateEditorMutation(
      path,
      value,
      registry: registry,
    );
    if (validation is! AppliedEditorMutation) return validation;
    final replaced = path.replace(_value, value);
    if (replaced case TypeFailure(:final diagnostics)) {
      return EditorMutationResult.invalid(diagnostics);
    }
    _value = replaced.valueOrNull!;
    notifyListeners();
    return validation;
  }
}

extension TypedEditorTesterExtension on WidgetTester {
  Future<TestEditorSource> pumpTypedEditor({
    required TypeExpression type,
    required DataValue value,
    DataPath path = DataPath.root,
    bool readOnly = false,
    TypeRegistry? registry,
  }) async {
    final source = TestEditorSource(
      rootType: type,
      value: value,
      registry: registry,
    );
    await pumpTestApp(
      child: EditorRoot(
        create: (_) => EditorController(source: source),
        child: Material(
          child: SizedBox(
            width: 500,
            child: TypedEditor(path: path, readOnly: readOnly),
          ),
        ),
      ),
    );
    return source;
  }
}
