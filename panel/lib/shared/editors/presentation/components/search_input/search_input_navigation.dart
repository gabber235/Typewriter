part of "search_input.dart";

List<ActionShortcut> _searchInputTextFieldActions({
  required VoidCallback previous,
  required VoidCallback next,
  required VoidCallback first,
  required VoidCallback last,
  required VoidCallback submit,
  required void Function({required bool backwards}) traverse,
}) {
  return [
    ActionShortcut(
      id: "search_input_previous",
      label: "Previous search result",
      description: "Focus the previous search result",
      activators: [
        ...shortcutsFor(PreviousFocusIntent),
        ...shortcutsForIntent<DirectionalFocusIntent>(
          (intent) => intent.direction == TraversalDirection.up,
        ),
      ],
      priority: 1500,
      show: false,
      onInvoke: (_) => previous(),
    ),
    ActionShortcut(
      id: "search_input_next",
      label: "Next search result",
      description: "Focus the next search result",
      activators: [
        ...shortcutsFor(NextFocusIntent),
        ...shortcutsForIntent<DirectionalFocusIntent>(
          (intent) => intent.direction == TraversalDirection.down,
        ),
      ],
      priority: 1500,
      show: false,
      onInvoke: (_) => next(),
    ),
    ActionShortcut.intent(
      id: "search_input_first",
      label: "First search result",
      description: "Focus the first search result",
      intent: FirstItemIntent,
      priority: 1500,
      show: false,
      onInvoke: (_) => first(),
    ),
    ActionShortcut.intent(
      id: "search_input_last",
      label: "Last search result",
      description: "Focus the last search result",
      intent: LastItemIntent,
      priority: 1500,
      show: false,
      onInvoke: (_) => last(),
    ),
    ActionShortcut.intent(
      id: "search_input_submit",
      label: "Select search result",
      description: "Select the focused search result",
      intent: ActivateIntent,
      priority: 1500,
      show: false,
      onInvoke: (_) => submit(),
    ),
    ActionShortcut(
      id: "search_input_traverse_backwards",
      label: "Previous field",
      description: "Commit the search and focus the previous field",
      activators: const [SingleActivator(LogicalKeyboardKey.tab, shift: true)],
      priority: 1600,
      show: false,
      onInvoke: (_) => traverse(backwards: true),
    ),
    ActionShortcut(
      id: "search_input_traverse_forwards",
      label: "Next field",
      description: "Commit the search and focus the next field",
      activators: const [SingleActivator(LogicalKeyboardKey.tab)],
      priority: 1600,
      show: false,
      onInvoke: (_) => traverse(backwards: false),
    ),
  ];
}
