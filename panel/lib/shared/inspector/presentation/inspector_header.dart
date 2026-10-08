import "package:typewriter_panel/typewriter_panel.dart";

/// Displays a resource title and stable identifier.
///
/// This widget is a static projection. Use [ManagedInspectorHeader] when the
/// title or color must follow an editor's local draft.
class InspectorHeader extends HookWidget {
  const InspectorHeader({
    required this.id,
    required this.name,
    required this.color,
    super.key,
  });

  final String id;
  final String name;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Title(title: name, color: color),
        SizedBox(height: context.spacing.space2),
        Identifier(id: id),
      ],
    );
  }
}

String _stringFormatted(String name) => name.formatted;

/// Displays header metadata read from an [EditOwner] local draft.
///
/// The fallback values cover loading, missing, and invalid fields. The widget
/// listens to the owner, so draft edits update the header without rebuilding
/// the inspection graph.
class ManagedInspectorHeader extends HookWidget {
  const ManagedInspectorHeader({
    required this.id,
    required this.owner,
    required this.fallbackName,
    required this.fallbackColor,
    this.nameField = "name",
    this.colorField = "color",
    this.nameFormatter = _stringFormatted,
    super.key,
  });

  final String id;
  final EditOwner owner;
  final String fallbackName;
  final Color fallbackColor;
  final String nameField;
  final String? colorField;
  final String Function(String)? nameFormatter;

  @override
  Widget build(BuildContext context) {
    useListenable(owner);

    final nameValue = owner.value(DataPath.root.field(nameField));
    final field = colorField;
    final colorValue = field == null
        ? null
        : owner.value(DataPath.root.field(field));

    final name = nameValue.valueOrNull?.asStringOrNull ?? fallbackName;
    final formattedName = nameFormatter?.call(name) ?? name;

    return InspectorHeader(
      id: id,
      name: formattedName,
      color: colorValue?.valueOrNull?.asColorOrNull ?? fallbackColor,
    );
  }
}
