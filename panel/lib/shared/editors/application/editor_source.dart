import "package:flutter/foundation.dart";
import "package:typewriter_panel/typewriter_panel.dart";

abstract interface class EditorSource implements Listenable {
  TypeExpression? get rootType;

  TypeRegistry? get registry;

  EditorValue value(DataPath path);

  EditorMutationResult update(DataPath path, DataValue value);

  void dispose();
}
