import "package:typewriter_panel/typewriter_panel.dart";

class MockSelectableIdentifier extends SelectableIdentifier {
  const MockSelectableIdentifier(this.id);

  @override
  final String id;

  @override
  AsyncValue<Selectable<MockSelectableIdentifier>> create(Ref ref) =>
      AsyncData(MockSelectable(this));

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MockSelectableIdentifier && other.id == id;

  @override
  int get hashCode => id.hashCode;
}

final class MockSelectable extends Selectable<MockSelectableIdentifier> {
  const MockSelectable(this.id);

  @override
  final MockSelectableIdentifier id;

  @override
  String get name => id.id;

  @override
  List<SelectionCapability> get capabilities => const [];
}
