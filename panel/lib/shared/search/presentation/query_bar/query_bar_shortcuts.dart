part of "query_bar.dart";

List<ActionShortcut> _useQueryBarShortcuts({
  required bool popupSuggestionsVisible,
  required FocusNode focusNode,
  required int? cursorOffset,
  required VoidCallback acceptSuggestion,
  required VoidCallback selectPreviousSuggestion,
  required VoidCallback selectNextSuggestion,
  required VoidCallback dismissSuggestions,
}) {
  return useMemoized(
    () => [
      if (popupSuggestionsVisible) ...[
        ActionShortcut.intent(
          id: "query_bar_accept_first_suggestion",
          label: "Accept suggestion",
          description: "Accept the first suggestion",
          intent: ActivateIntent,
          priority: 2000,
          show: true,
          run: ActionRun.press((_) => acceptSuggestion()),
        ),
        ActionShortcut(
          id: "query_bar_navigate_suggestions_popup",
          label: "Switch suggestions",
          description: "Switch between the suggestions popup",
          activators: [
            ...shortcutsFor(PreviousFocusIntent),
            ...shortcutsFor(NextFocusIntent),
            ...shortcutsForIntent<DirectionalFocusIntent>(
              (intent) => intent.direction == TraversalDirection.up,
            ),
            ...shortcutsForIntent<DirectionalFocusIntent>(
              (intent) => intent.direction == TraversalDirection.down,
            ),
          ],
          show: true,
          priority: 1999,
        ),
        ActionShortcut(
          id: "query_bar_previous_suggestion",
          label: "",
          description: "",
          activators: [
            ...shortcutsFor(PreviousFocusIntent),
            ...shortcutsForIntent<DirectionalFocusIntent>(
              (intent) => intent.direction == TraversalDirection.up,
            ),
          ],
          run: ActionRun.press((_) => selectPreviousSuggestion()),
          show: false,
          priority: -1,
        ),
        ActionShortcut(
          id: "query_bar_next_suggestion",
          label: "",
          description: "",
          activators: [
            ...shortcutsFor(NextFocusIntent),
            ...shortcutsForIntent<DirectionalFocusIntent>(
              (intent) => intent.direction == TraversalDirection.down,
            ),
          ],
          run: ActionRun.press((_) => selectNextSuggestion()),
          show: false,
          priority: -1,
        ),
        ActionShortcut.intent(
          id: "query_bar_dismiss_suggestions_popup",
          label: "Dismiss suggestions",
          description: "Dismiss the suggestions popup",
          intent: DismissIntent,
          priority: 1998,
          show: true,
          run: ActionRun.press((_) => dismissSuggestions()),
        ),
      ],
    ],
    [popupSuggestionsVisible, focusNode.hasPrimaryFocus, cursorOffset],
  );
}
