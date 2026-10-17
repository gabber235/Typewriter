import "package:typewriter_panel/typewriter_panel.dart";

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
    super.key,
  });

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
    void submit() {
      final result =
          controller.currentPreview ??
          controller.selectedResults.firstOrNull ??
          controller.snapshot.nodes.firstResult;
      if (result != null) unawaited(controller.activate(result));
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
              ClipRRect(
                borderRadius: BorderRadiusGeometry.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
                child: Stack(
                  clipBehavior: .none,
                  children: [
                    QueryBar(
                      inputFieldController: inputFieldController,
                      query: controller.query,
                      onDismiss: onQueryDismiss,
                      onCancel: onQueryDismiss,
                      textFieldActions: [
                        ...?textFieldActions,
                        ActionShortcut(
                          id: "submit_search_result",
                          label: "Select result",
                          description: "Apply the highlighted search result",
                          activators: [
                            const SingleActivator(LogicalKeyboardKey.enter),
                            const SingleActivator(
                              LogicalKeyboardKey.numpadEnter,
                            ),
                          ],
                          priority: 1500,
                          show: false,
                          onInvoke: (_) => submit(),
                        ),
                      ],
                      selectAllOnFocus: selectAllOnFocus,
                      onQueryChanged: controller.updateQuery,
                      selectors: controller.selectors,
                      completeSelector: controller.completeSelector,
                      validationIssues: controller.validationIssues,
                      autofocus: EditorTextFieldAutoFocus.textField,
                      style: queryStyle,
                      textAlign: queryAlignment,
                      inputDecoration:
                          (queryDecoration ?? const InputDecoration()).copyWith(
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
                    ),
                    if (controller.snapshot.status == .loading &&
                        controller.snapshot.nodes.isEmpty)
                      LinearProgressIndicator(
                        backgroundColor: Colors.transparent,
                      ),
                  ],
                ),
              ),
              const SearchCommandInfo(),
            ],
          ),
          searchResults: Actions(
            actions: {
              DismissIntent: CallbackAction<DismissIntent>(
                onInvoke: (_) => inputFieldController.requestSurroundingFocus(),
              ),
            },
            child: SearchTreeResults(
              rowRenderers: rowRenderers,
              shrinkWrap: shrinkWrap,
              empty: empty,
              loading: loading,
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
