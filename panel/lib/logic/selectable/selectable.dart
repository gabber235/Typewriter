import "dart:async";

import "package:flutter/material.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:typewriter_panel/logic/selectable/data_blueprint.dart";

abstract class SelectableIdentifier {
  String get id;

  FutureOr<Selectable> create(Ref ref);
}

abstract class Selectable<I extends SelectableIdentifier> {
  I get id;
  String get name;

  ObjectBlueprint get objectBlueprint;
  Widget? header();

  dynamic fieldValue(String path);
  void setFieldValue(String path, dynamic value);
}
