import "package:flutter/material.dart" hide SearchController;
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:typewriter_panel/typewriter_panel.dart";

class SearchModalBody extends HookConsumerWidget {
  const SearchModalBody({
    required this.searchHint,
    this.rowRenderers = const {},
    this.previewRenderers = const {},
    super.key,
  });

  final String searchHint;
  final Map<String, SearchResultRowBuilder> rowRenderers;
  final Map<String, SearchResultPreviewBuilder> previewRenderers;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final inputFieldController = useInputFieldController(
      inputDebugLabel: "Search QueryBar",
      surroundingDebugLabel: "Surrounding Search QueryBar",
    );
    final controller = ref.watch(searchProvider)!;
    final currentPreview = controller.currentPreview;

    return Actions(
      actions: {
        if (controller.canClose)
          DismissIntent: CallbackAction<DismissIntent>(
            onInvoke: (_) => controller.close(),
          ),
      },
      child: SearchShortcuts(
        child: SearchFrame(
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
                      onQueryChanged: controller.updateQuery,
                      selectors: controller.selectors,
                      autofocus: DecoratedTextFieldAutoFocus.textField,
                      inputDecoration: InputDecoration(
                        prefixIcon: Padding(
                          padding: EdgeInsets.only(
                            left: context.spacing.space1,
                          ),
                          child: const Icon(Icons.search_rounded),
                        ),
                        hintText: searchHint,
                        suffixIcon: controller.canClose
                            ? InputIconButton(
                                icon: const Icon(Icons.close_rounded),
                                tooltip: "Close",
                                onPressed: controller.close,
                              )
                            : null,
                      ),
                    ),
                    if (controller.snapshot.status == .loading)
                      LinearProgressIndicator(
                        backgroundColor: Colors.transparent,
                      ),
                  ],
                ),
              ),
              const SearchActionInfo(),
            ],
          ),
          searchResults: Actions(
            actions: {
              DismissIntent: CallbackAction<DismissIntent>(
                onInvoke: (_) => inputFieldController.requestSurroundingFocus(),
              ),
            },
            child: SearchTreeResults(rowRenderers: rowRenderers),
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
  }
}
