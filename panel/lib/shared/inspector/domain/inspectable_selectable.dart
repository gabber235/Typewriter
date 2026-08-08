import "package:flutter/widgets.dart";
import "package:typewriter_panel/typewriter_panel.dart";

abstract class InspectableSelectable<I extends SelectableIdentifier>
    extends Selectable<I> {
  const InspectableSelectable();

  ObjectBlueprint get objectBlueprint;

  Widget? buildInspectorHeader();

  dynamic fieldValue(String path);

  void setFieldValue(String path, dynamic value);
}
