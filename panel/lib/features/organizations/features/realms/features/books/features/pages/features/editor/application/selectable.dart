import "package:flutter/material.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:typewriter_panel/features/organizations/features/realms/features/books/features/pages/features/editor/domain/data_blueprint.dart";
import "package:typewriter_panel/features/organizations/features/realms/features/books/features/pages/features/editor/features/inspector/presentation/operations.dart";

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
