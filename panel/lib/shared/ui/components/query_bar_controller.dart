part of "query_bar.dart";

class _QueryBarController {
  const _QueryBarController({
    required this.inputFieldController,
    required this.textController,
    required this.parseResult,
    required this.suggestions,
    required this.activeSuggestionIndex,
    required this.helperVisible,
    required this.helperBadges,
    required this.popupSuggestionsVisible,
    required this.popupVisible,
    required this.shortcuts,
    required this.applySuggestion,
    required this.onHoverIndex,
    required this.onQueryChanged,
    required this.onSubmitted,
  });

  final InputFieldController inputFieldController;
  final _QueryBarTextEditingController textController;
  final QueryParseResult parseResult;
  final List<QuerySuggestion> suggestions;
  final int? activeSuggestionIndex;
  final bool helperVisible;
  final _HelperBadgeData helperBadges;
  final bool popupSuggestionsVisible;
  final bool popupVisible;
  final List<ActionShortcut> shortcuts;
  final ValueChanged<QuerySuggestion> applySuggestion;
  final ValueChanged<int> onHoverIndex;
  final ValueChanged<String> onQueryChanged;
  final ValueChanged<String> onSubmitted;
}

_QueryBarController _useQueryBarController(QueryBar bar) {
  final textController = useMemoized(
    () => _QueryBarTextEditingController(
      text: bar.query,
      selectors: bar.selectors,
    ),
    [bar.selectors],
  );
  final defaultInputFieldController = useInputFieldController(
    inputDebugLabel: "QueryBar",
    surroundingDebugLabel: "Surrounding QueryBar",
  );
  final inputFieldController =
      bar.inputFieldController ?? defaultInputFieldController;
  final focusNode = inputFieldController.inputFocusNode;

  useEffect(() => textController.dispose, [textController]);
  useListenable(textController);
  useListenable(focusNode);

  useEffect(() {
    if (!focusNode.hasFocus && textController.text != bar.query) {
      textController.value = TextEditingValue(
        text: bar.query,
        selection: TextSelection.collapsed(offset: bar.query.length),
      );
    }
    return null;
  }, [textController, bar.query]);

  final queryEngine = useMemoized(() => Query(bar.selectors), [bar.selectors]);
  final suggestionEngine = useMemoized(
    () => QuerySuggestionEngine(bar.selectors),
    [bar.selectors],
  );
  final cursorOffset =
      textController.selection.isCollapsed && focusNode.hasPrimaryFocus
      ? textController.selection.extentOffset
      : null;
  final parseResult = useMemoized(
    () => queryEngine.parse(textController.text, cursorOffset: cursorOffset),
    [queryEngine, textController.text, cursorOffset],
  );
  final suggestions = useMemoized(
    () => suggestionEngine.suggest(parseResult, maxItems: 100),
    [suggestionEngine, parseResult],
  );
  final activeSuggestionIndex = useState<int?>(null);
  final dismissedSignature = useState<String?>(null);
  final currentSignature = "${textController.text}|$cursorOffset";
  final helperVisible = _shouldShowHelperRow(suggestions);
  final helperBadges = _helperBadgeData(suggestions, maxItems: 20);
  final popupSuggestionsVisible =
      suggestions.isNotEmpty &&
      !helperVisible &&
      dismissedSignature.value != currentSignature;
  final popupVisible = focusNode.hasFocus && popupSuggestionsVisible;

  useEffect(() {
    textController.updateParseResult(parseResult);
    return null;
  }, [textController, parseResult]);

  useEffect(() {
    final activeIndex = activeSuggestionIndex.value;
    if (!popupSuggestionsVisible) {
      activeSuggestionIndex.value = null;
      return null;
    }
    if (activeIndex != null && activeIndex >= suggestions.length) {
      activeSuggestionIndex.value = 0;
    }
    return null;
  }, [popupSuggestionsVisible, suggestions, activeSuggestionIndex]);

  void applySuggestion(QuerySuggestion suggestion) {
    final before = textController.text.substring(
      0,
      suggestion.replaceRange.start,
    );
    final after = textController.text.substring(suggestion.replaceRange.end);
    final nextText = "$before${suggestion.label}$after";
    final caretOffset = before.length + suggestion.label.length;
    textController.value = TextEditingValue(
      text: nextText,
      selection: TextSelection.collapsed(offset: caretOffset),
    );
    dismissedSignature.value = null;
    bar.onQueryChanged(nextText);
  }

  void acceptActiveOrFirstSuggestion() {
    if (suggestions.isEmpty) return;
    applySuggestion(suggestions[activeSuggestionIndex.value ?? 0]);
  }

  void selectNextSuggestion() {
    if (!popupSuggestionsVisible) return;
    final currentIndex = activeSuggestionIndex.value;
    activeSuggestionIndex.value = currentIndex == null
        ? 0
        : (currentIndex + 1) % suggestions.length;
  }

  void selectPreviousSuggestion() {
    if (!popupSuggestionsVisible) return;
    final currentIndex = activeSuggestionIndex.value;
    activeSuggestionIndex.value = currentIndex == null
        ? suggestions.length - 1
        : (currentIndex - 1 + suggestions.length) % suggestions.length;
  }

  void dismissSuggestions() {
    activeSuggestionIndex.value = null;
    dismissedSignature.value = currentSignature;
  }

  final shortcuts = _useQueryBarShortcuts(
    popupSuggestionsVisible: popupSuggestionsVisible,
    focusNode: focusNode,
    cursorOffset: cursorOffset,
    acceptSuggestion: acceptActiveOrFirstSuggestion,
    selectPreviousSuggestion: selectPreviousSuggestion,
    selectNextSuggestion: selectNextSuggestion,
    dismissSuggestions: dismissSuggestions,
  );

  void onQueryChanged(String value) {
    dismissedSignature.value = null;
    bar.onQueryChanged(value);
  }

  void onSubmitted(String value) {
    if (popupSuggestionsVisible) {
      acceptActiveOrFirstSuggestion();
      return;
    }
    bar.onSubmitted?.call(value);
  }

  return _QueryBarController(
    inputFieldController: inputFieldController,
    textController: textController,
    parseResult: parseResult,
    suggestions: suggestions,
    activeSuggestionIndex: activeSuggestionIndex.value,
    helperVisible: helperVisible,
    helperBadges: helperBadges,
    popupSuggestionsVisible: popupSuggestionsVisible,
    popupVisible: popupVisible,
    shortcuts: shortcuts,
    applySuggestion: applySuggestion,
    onHoverIndex: (index) => activeSuggestionIndex.value = index,
    onQueryChanged: onQueryChanged,
    onSubmitted: onSubmitted,
  );
}
