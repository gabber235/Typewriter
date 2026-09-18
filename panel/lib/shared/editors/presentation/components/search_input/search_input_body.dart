part of "search_input.dart";

/// Connects the search controller's snapshot and focus actions to the two
/// visual states of the input.
///
/// The summary is the inactive state. The query bar and bounded result tree
/// are mounted only while editing, but the controller remains in the
/// [SearchRoot] scope so source state survives rebuilds of this view. Preview
/// changes are forwarded after the frame that displays them, keeping result
/// presentations synchronized with keyboard navigation.
class _PresentationSearchInputBody extends HookConsumerWidget {
  const _PresentationSearchInputBody({
    required this.element,
    required this.binding,
    required this.scope,
    required this.maximumExtent,
    required this.editing,
    required this.inputController,
    required this.validationMessage,
    required this.selectionMatcher,
    required this.summaryBuilder,
    required this.onStartEditing,
    required this.onPreview,
    required this.onSelectionPointerDown,
    required this.onSelectionPointerEnd,
    required this.onSubmit,
    required this.onDismiss,
    required this.onCancel,
    required this.onDone,
    required this.onAcceptTraversal,
  });

  final SearchInputElement element;
  final InspectedBinding binding;
  final PresentationRenderScope scope;
  final double maximumExtent;
  final bool editing;
  final InputFieldController inputController;
  final String? validationMessage;
  final PresentationSearchSelectionMatcher? selectionMatcher;
  final PresentationSearchSummaryBuilder? summaryBuilder;
  final ValueChanged<SearchController<dynamic>> onStartEditing;
  final ValueChanged<SearchResult> onPreview;
  final VoidCallback onSelectionPointerDown;
  final VoidCallback onSelectionPointerEnd;
  final ValueChanged<SearchController<dynamic>> onSubmit;
  final VoidCallback onDismiss;
  final VoidCallback onCancel;
  final ValueChanged<SearchController<dynamic>> onDone;
  final void Function(
    SearchController<dynamic> controller, {
    required bool backwards,
  })
  onAcceptTraversal;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.watch(searchProvider)!;
    final scrollController = useScrollController();
    final results = controller.snapshot.nodes
        .walk()
        .whereType<SearchResultNode>()
        .map((node) => node.result)
        .toList(growable: false);

    void navigate(int Function(int current, int length) destination) {
      if (results.isEmpty) return;
      final current = results.indexWhere(
        (result) => result.id == controller.currentPreview?.id,
      );
      final index = destination(
        current,
        results.length,
      ).clamp(0, results.length - 1);
      final result = results[index];
      controller.preview(result);
      onPreview(result);
    }

    final textFieldActions = _searchInputTextFieldActions(
      previous: () =>
          navigate((current, length) => current < 0 ? length - 1 : current - 1),
      next: () => navigate((current, length) => current < 0 ? 0 : current + 1),
      first: () => navigate((current, length) => 0),
      last: () => navigate((current, length) => length - 1),
      submit: () => onSubmit(controller),
      traverse: ({required backwards}) =>
          onAcceptTraversal(controller, backwards: backwards),
    );

    useEffect(() {
      final result = controller.currentPreview;
      if (!editing || result == null) return null;
      var active = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (active && context.mounted && controller.currentPreview == result) {
          onPreview(result);
        }
      });
      return () => active = false;
    }, [editing, controller.currentPreview]);

    final placeholder = element.placeholder == null
        ? "Search"
        : scope.expressionText(element.placeholder!);
    return PrimaryScrollController(
      controller: scrollController,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (!editing)
            _SearchInputSummary(
              element: element,
              binding: binding,
              scope: scope,
              inputController: inputController,
              onStartEditing: () => onStartEditing(controller),
              summaryBuilder: summaryBuilder,
            )
          else
            ClipRRect(
              borderRadius: BorderRadiusGeometry.only(
                topLeft: context.shapes.largeRadius,
                topRight: context.shapes.largeRadius,
              ),
              child: Stack(
                children: [
                  QueryBar(
                    key: const ValueKey("presentation_search_query"),
                    inputFieldController: inputController,
                    query: controller.query,
                    selectors: controller.selectors,
                    onQueryChanged: controller.updateQuery,
                    onSubmitted: (_) => onSubmit(controller),
                    onEditingComplete: () {},
                    onDone: (_) => onDone(controller),
                    onDismiss: onDismiss,
                    onCancel: onCancel,
                    textFieldActions: textFieldActions,
                    onInputFocus: controller.refresh,
                    selectAllOnFocus: true,
                    inputDecoration: InputDecoration(
                      hintText: placeholder,
                      errorText: validationMessage,
                      suffixIcon: _SearchInputStatus(controller: controller),
                    ),
                  ),
                  if (controller.snapshot.status == SearchSourceStatus.loading)
                    const LinearProgressIndicator(minHeight: 2),
                ],
              ),
            ),
          _SearchInputResults(
            visible: editing,
            searchController: controller,
            scope: scope,
            maximumExtent: maximumExtent,
            controller: scrollController,
            isSelected: (result) =>
                _isSelected(binding.value, result, selectionMatcher),
            onSelectionPointerDown: onSelectionPointerDown,
            onSelectionPointerEnd: onSelectionPointerEnd,
          ),
        ],
      ),
    );
  }
}

/// Matches a search result against the value owned by the enclosing binding.
///
/// Result payloads from other search types are deliberately not considered
/// selected. A list binding uses value equality for each member, which keeps
/// row highlighting derived from the canonical editor value rather than a
/// second selection store.
bool _isSelected(
  EditorValue value,
  SearchResult result,
  PresentationSearchSelectionMatcher? matcher,
) {
  final payload = result.payload;
  if (payload is! PresentationSearchResultPayload) return false;
  if (matcher != null) return matcher(value, payload.selectedValue);
  final current = value.valueOrNull;
  if (current is ListValue) {
    return current.values.contains(payload.selectedValue);
  }
  return current == payload.selectedValue;
}
