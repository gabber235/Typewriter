part of "multiselect_dropdown.dart";

// The dropdown view maps navigation keys to private intents so the menu can
// move its highlight while EditableText retains keyboard focus.
class _PreviousIntent extends Intent {
  const _PreviousIntent();
}

class _NextIntent extends Intent {
  const _NextIntent();
}

class _EnterIntent extends Intent {
  const _EnterIntent();
}

/// Receives the labels parsed from the editable multiselect input.
typedef ChangeTags = void Function(List<String> tags);

/// Builds the inline widget used to display one selected label.
typedef LabelWidgetBuilder = Widget Function(
  BuildContext context,
  String label,
);
