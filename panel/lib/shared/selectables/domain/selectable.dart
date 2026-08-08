import "package:hooks_riverpod/hooks_riverpod.dart";

abstract class SelectionCapability {
  const SelectionCapability();
}

abstract class SelectableIdentifier {
  const SelectableIdentifier();
  String get id;

  AsyncValue<Selectable> create(Ref ref);
}

abstract class Selectable<I extends SelectableIdentifier> {
  const Selectable();

  I get id;
  String get name;
  List<SelectionCapability> get capabilities;
}
