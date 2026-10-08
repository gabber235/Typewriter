import "package:typewriter_panel/typewriter_panel.dart";

/// Named predicates for resolving Flutter widget state sets.
///
/// These helpers keep state property resolution readable while preserving the
/// set's normal semantics.
extension WidgetStates on Set<WidgetState> {
  bool get isHovered => contains(WidgetState.hovered);
  bool get isFocused => contains(WidgetState.focused);
  bool get isPressed => contains(WidgetState.pressed);
  bool get isDragged => contains(WidgetState.dragged);
  bool get isSelected => contains(WidgetState.selected);
  bool get isScrolledUnder => contains(WidgetState.scrolledUnder);
  bool get isDisabled => contains(WidgetState.disabled);
  bool get hasError => contains(WidgetState.error);
}
