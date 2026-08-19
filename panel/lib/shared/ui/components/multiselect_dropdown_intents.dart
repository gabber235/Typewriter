part of "multiselect_dropdown.dart";

class _PreviousIntent extends Intent {
  const _PreviousIntent();
}

class _NextIntent extends Intent {
  const _NextIntent();
}

class _EnterIntent extends Intent {
  const _EnterIntent();
}

typedef ChangeTags = void Function(List<String> tags);
typedef LabelWidgetBuilder =
    Widget Function(BuildContext context, String label);
