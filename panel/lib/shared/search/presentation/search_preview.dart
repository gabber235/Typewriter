import "package:typewriter_panel/typewriter_panel.dart";

// Kept manual because the installed generator only accepts generated
// declarations as dependency annotations. Keep the scoped search dependency.
final _previewData = FutureProvider<SearchPreviewRequestResult>(
  dependencies: [searchProvider],
  (ref) async {
    final controller = ref.watch(searchProvider)!;
    final currentPreview = controller.currentPreview;
    assert(
      currentPreview != null,
      "SearchPreview can only be built when a preview is available",
    );
    return controller.requestPreview(
      SearchPreviewRequest(
        resultId: currentPreview!.id,
        queryContext: controller.queryContext,
      ),
    );
  },
);

/// Requests and renders the preview for the controller's current result.
///
/// Preview data is keyed by the active result and query context through
/// [_previewData]. A renderer receives an explicit loading, data, or error
/// context, so source failures remain visible without changing controller
/// ownership.
class SearchPreview extends HookConsumerWidget {
  const SearchPreview({required this.previewRenderers, super.key});

  final Map<String, SearchResultPreviewBuilder> previewRenderers;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.watch(searchProvider)!;
    final currentPreview = controller.currentPreview;
    if (currentPreview == null) {
      return const SizedBox.shrink();
    }
    final previewRenderer =
        previewRenderers[currentPreview.type.previewRendererId];

    if (previewRenderer == null) {
      return ErrorScreen.small(
        title: "",
        message:
            "No preview renderer found for type ${currentPreview.type.label ?? currentPreview.type.id}",
        withIcon: true,
      );
    }

    final previewData = ref.watch(_previewData);

    return previewData(
      name: "Preview Data",
      shrink: true,
      loading: (name) => previewRenderer(
        SearchResultPreviewContext.loading(result: currentPreview),
      ),
      error: (title, message) => previewRenderer(
        SearchResultPreviewContext.error(
          result: currentPreview,
          message: message,
        ),
      ),
      builder: (data) {
        return switch (data) {
          SearchPreviewRequestResultData(:final data) => previewRenderer(
            SearchResultPreviewContext.data(result: currentPreview, data: data),
          ),
          SearchPreviewRequestResultError(:final message) => previewRenderer(
            SearchResultPreviewContext.error(
              result: currentPreview,
              message: message,
            ),
          ),
        };
      },
    );
  }
}
