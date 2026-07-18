import "package:flutter/material.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:typewriter_panel/shared/search/presentation/search.dart";
import "package:typewriter_panel/shared/search/search_engine.dart";
import "package:typewriter_panel/shared/ui/screens/error_screen.dart";
import "package:typewriter_panel/shared/utilities/riverpod.dart";

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
          SearchPreviewRequestResult() => throw UnimplementedError(),
        };
      },
    );
  }
}
