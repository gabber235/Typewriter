import "package:flutter/material.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:typewriter_panel/typewriter_panel.dart";

abstract class SelectableIdentifier {
  const SelectableIdentifier();
  String get id;

  AsyncValue<Selectable> create(Ref ref);
}

abstract class Selectable<I extends SelectableIdentifier> {
  const Selectable();

  I get id;
  String get name;

  ObjectBlueprint get objectBlueprint;
  List<SelectableOperation> get operations;
  Widget? header();

  dynamic fieldValue(String path);
  void setFieldValue(String path, dynamic value);
}
