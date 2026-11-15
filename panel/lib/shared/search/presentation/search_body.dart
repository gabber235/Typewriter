import "package:typewriter_panel/typewriter_panel.dart";

/// What assistive technology reads while the first results load.
const searchLoadingSemanticLabel = "Loading results";

typedef SearchFrameBuilder = Widget Function({
  required Widget queryBar,
  required Widget searchResults,
  Widget? actionBar,
  Widget? preview,
});

/// Lays out one search interaction inside a [SearchRoot].
///
/// [frameBuilder] places the shared query, results, actions, and preview.
/// The default uses the modal frame; embedded fields supply their own layout.
///
/// This widget wires the controller to the query bar, tree results, action
/// shortcuts, action feedback, and preview. It does not create the controller;
/// an ancestor must provide [searchProvider].
class SearchBody extends HookConsumerWidget {
  const SearchBody({
    required this.searchHint,
    this.rowRenderers = const {},
    this.previewRenderers = const {},
    this.surfaceStyle,
    this.queryDecoration,
    this.queryStyle,
    this.queryAlignment = TextAlign.start,
    this.useDefaultQueryIcon = true,
    this.empty,
    this.loading,
    this.frameBuilder = SearchFrame.new,
    this.shrinkWrap = false,
    this.onQueryDismiss,
    this.textFieldActions,
    this.selectAllOnFocus = false,
    this.selection,
    super.key,
  });

  /// The values the results choose, for a surface that chooses several; see
  /// [SearchTreeResults.selection].
  final SurfaceSelection? selection;

  final SearchFrameBuilder frameBuilder;
  final bool shrinkWrap;
  final VoidCallback? onQueryDismiss;
  final List<ActionShortcut>? textFieldActions;
  final bool selectAllOnFocus;
  final SearchSurfaceStyle? surfaceStyle;
  final InputDecoration? queryDecoration;
  final TextStyle? queryStyle;
  final TextAlign queryAlignment;
  final bool useDefaultQueryIcon;
  final Widget? empty;
  final Widget? loading;
  final String searchHint;
  final Map<String, SearchResultRowBuilder> rowRenderers;
  final Map<String, SearchResultPreviewBuilder> previewRenderers;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final inputFieldController = useInputFieldController(
      inputDebugLabel: "Search QueryBar",
      surroundingDebugLabel: "Surrounding Search QueryBar",
    );
    useEffect(() {
      // Opening search is an explicit focus transfer. Autofocus alone yields
      // to the previously focused sibling when an inline field is reopened.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) inputFieldController.requestInputFocus();
      });
      return null;
    }, [inputFieldController]);
    final controller = ref.watch(searchProvider)!;
    final currentPreview = controller.currentPreview;
    final results = useFocusNode(
      debugLabel: "Search results",
      canRequestFocus: false,
      skipTraversal: true,
    );
    // Typing on a result moves to the query with the typed letter after the
    // text, so focusing it must not select that text.
    final typedAhead = useState(false);
    useFocusedChange(inputFieldController.inputFocusNode, ({
      required hasFocus,
    }) {
      if (!hasFocus) typedAhead.value = false;
      return null;
    }, [inputFieldController]);

    void submit() {
      final result = controller.snapshot.nodes.firstResult;
      if (result != null) unawaited(controller.activate(result));
    }

    // Whether the results sit below the query, so Down leads from the query
    // into them and Up out of them again; above it the keys swap.
    bool resultsBelow() {
      final query = inputFieldController.inputFocusNode.rect;
      final list = results.rect;
      return list.top >= query.top;
    }

    void enterResults({required bool down}) {
      final stops = searchResultStops(results);
      if (stops.isEmpty || down != resultsBelow()) return;
      (down ? stops.first : stops.last).requestFocus();
    }

    // Moves focus one result towards [down]; past the end that faces the
    // query, focus returns to the query.
    void step({required bool down}) {
      final stops = searchResultStops(results);
      final at = stops.indexWhere((stop) => stop.hasFocus);
      if (at < 0) return;
      final next = at + (down ? 1 : -1);
      if (next >= 0 && next < stops.length) {
        stops[next].requestFocus();
      } else if ((next < 0) == resultsBelow()) {
        inputFieldController.requestInputFocus();
      }
    }

    // Keys a focused result leaves unhandled: Up and Down move between the
    // results, from the first key on and whatever frame it lands in, and a
    // typed character goes to the query.
    KeyEventResult resultKeys(FocusNode node, KeyEvent event) {
      final character = event.character;
      final keyboard = HardwareKeyboard.instance;
      final plain =
          !keyboard.isControlPressed &&
          !keyboard.isMetaPressed &&
          !keyboard.isAltPressed &&
          !keyboard.isShiftPressed;
      final key = event.logicalKey;
      if (event is! KeyUpEvent &&
          plain &&
          (key == LogicalKeyboardKey.arrowDown ||
              key == LogicalKeyboardKey.arrowUp)) {
        step(down: key == LogicalKeyboardKey.arrowDown);
        return KeyEventResult.handled;
      }
      if (event is KeyUpEvent ||
          character == null ||
          character == " " ||
          character.runes.any((rune) => rune < 0x20 || rune == 0x7f) ||
          keyboard.isControlPressed ||
          keyboard.isMetaPressed ||
          keyboard.isAltPressed) {
        return KeyEventResult.ignored;
      }
      typedAhead.value = true;
      controller.updateQuery(controller.query + character);
      // The query bar takes the new text while it does not have focus, so
      // focus follows once the text is shown.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) inputFieldController.requestInputFocus();
      });
      return KeyEventResult.handled;
    }

    final surface = Actions(
      actions: {
        if (controller.canClose)
          DismissIntent: CallbackAction<DismissIntent>(
            onInvoke: (_) => controller.close(),
          ),
      },
      child: SearchShortcuts(
        child: frameBuilder(
          queryBar: Column(
            children: [
              QueryBar(
                inputFieldController: inputFieldController,
                query: controller.query,
                onDismiss: onQueryDismiss,
                onCancel: onQueryDismiss,
                textFieldActions: [
                  ...?textFieldActions,
                  for (final down in [true, false])
                    ActionShortcut(
                      id: down
                          ? "enter_search_results_down"
                          : "enter_search_results_up",
                      label: "Go to results",
                      description: "Move focus from the query to the results",
                      activators: [
                        SingleActivator(
                          down
                              ? LogicalKeyboardKey.arrowDown
                              : LogicalKeyboardKey.arrowUp,
                        ),
                      ],
                      priority: 100,
                      show: false,
                      run: ActionRun.press((_) => enterResults(down: down)),
                    ),
                  ActionShortcut(
                    id: "submit_search_result",
                    label: "Open result",
                    description: "Open the first search result",
                    activators: [
                      const SingleActivator(LogicalKeyboardKey.enter),
                      const SingleActivator(LogicalKeyboardKey.numpadEnter),
                    ],
                    priority: 1500,
                    show: false,
                    run: ActionRun.press((_) => submit()),
                  ),
                ],
                selectAllOnFocus: selectAllOnFocus && !typedAhead.value,
                onQueryChanged: controller.updateQuery,
                selectors: controller.selectors,
                completeSelector: controller.completeSelector,
                validationIssues: controller.validationIssues,
                autofocus: EditorTextFieldAutoFocus.textField,
                style: queryStyle,
                textAlign: queryAlignment,
                inputDecoration: (queryDecoration ?? const InputDecoration())
                    .copyWith(
                      prefixIcon:
                          queryDecoration?.prefixIcon ??
                          (useDefaultQueryIcon
                              ? Padding(
                                  padding: EdgeInsets.only(
                                    left: context.spacing.space1,
                                  ),
                                  child: const Icon(Icons.search_rounded),
                                )
                              : null),
                      hintText: searchHint,
                      suffixIcon:
                          queryDecoration?.suffixIcon ??
                          (controller.canClose
                              ? InputIconButton(
                                  icon: const Icon(Icons.close_rounded),
                                  tooltip: "Close",
                                  onPressed: controller.close,
                                )
                              : null),
                    ),
                onSubmitted: (_) => submit(),
                loadingLabel:
                    controller.snapshot.status == .loading &&
                        controller.snapshot.nodes.isEmpty
                    ? searchLoadingSemanticLabel
                    : null,
              ),
              const SearchCommandInfo(),
            ],
          ),
          searchResults: Focus(
            focusNode: results,
            onKeyEvent: resultKeys,
            child: Actions(
              actions: {
                DismissIntent: CallbackAction<DismissIntent>(
                  onInvoke: (_) => inputFieldController.requestInputFocus(),
                ),
              },
              child: SearchTreeResults(
                selection: selection,
                rowRenderers: rowRenderers,
                shrinkWrap: shrinkWrap,
                empty: empty,
                loading: loading,
              ),
            ),
          ),
          actionBar: const ActionRow(),
          preview:
              currentPreview != null &&
                  currentPreview.type.previewRendererId != null
              ? SearchPreview(previewRenderers: previewRenderers)
              : null,
        ),
      ),
    );
    return surfaceStyle == null
        ? surface
        : SearchSurfaceAppearance(style: surfaceStyle!, child: surface);
  }
}
