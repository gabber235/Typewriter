import "package:flutter/foundation.dart";
import "package:typewriter_panel/typewriter_panel.dart";

abstract interface class EditorSource implements Listenable {
  ObjectBlueprint? get blueprint;

  EditorValue value(String path);

  void update(String path, dynamic value);

  void dispose();
}
