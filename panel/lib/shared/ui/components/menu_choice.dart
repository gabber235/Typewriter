import "package:typewriter_panel/typewriter_panel.dart";

/// One choice of a [Dropdown] or [MultiselectDropdown]: the [value] it picks,
/// the [label] it is found and read by, and how its menu row looks.
@immutable
final class MenuChoice<T> {
  const MenuChoice({
    required this.value,
    required this.label,
    this.leading,
    this.trailing,
    this.content,
    this.enabled = true,
  });

  final T value;
  final String label;
  final Widget? leading;
  final Widget? trailing;

  /// Shown in the menu row in place of the [label] text.
  final Widget? content;
  final bool enabled;
}
