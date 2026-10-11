import "package:typewriter_panel/typewriter_panel.dart";

final class StorySelectableIdentifier extends SelectableIdentifier {
  const StorySelectableIdentifier({required this.id, required this.color});

  @override
  final String id;
  final Color color;

  @override
  AsyncValue<Selectable> create(Ref ref) =>
      AsyncData(StorySelectable(id: this, name: id.formatted));

  @override
  bool operator ==(Object other) =>
      other is StorySelectableIdentifier && other.id == id;

  @override
  int get hashCode => id.hashCode;
}

final class StorySelectable extends Selectable<StorySelectableIdentifier> {
  const StorySelectable({required this.id, required this.name});

  @override
  final StorySelectableIdentifier id;

  @override
  final String name;

  @override
  List<SelectionCapability> get capabilities => const [];
}
