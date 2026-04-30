import "package:flutter/material.dart" hide SearchController;
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:typewriter_panel/hooks/input_field_controller.dart";
import "package:typewriter_panel/widgets/app/components/action_shortcuts.dart";
import "package:typewriter_panel/widgets/app/components/decorated_text_field.dart";
import "package:typewriter_panel/widgets/generic/components/input_icon_button.dart";
import "package:typewriter_panel/widgets/generic/components/query_bar.dart";
import "package:typewriter_panel/widgets/generic/components/search/search_frame.dart";
import "package:typewriter_panel/widgets/generic/components/search/search_result_renderers.dart";
import "package:typewriter_panel/widgets/generic/components/search/search_root.dart";
import "package:typewriter_panel/widgets/generic/components/search/search_tree_results.dart";

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
    return Actions(
      actions: {
        if (controller.canClose)
          DismissIntent: CallbackAction<DismissIntent>(
            onInvoke: (_) => controller.close(),
          ),
      },
      child: SearchFrame(
        queryBar: ClipRRect(
          borderRadius: BorderRadiusGeometry.only(
            topLeft: Radius.circular(12),
            topRight: Radius.circular(12),
          ),
          child: Stack(
            children: [
              QueryBar(
                inputFieldController: inputFieldController,
                query: controller.query,
                onQueryChanged: controller.updateQuery,
                selectors: controller.selectors,
                autofocus: DecoratedTextFieldAutoFocus.textField,
                inputDecoration: InputDecoration(
                  prefixIcon: Padding(
                    padding: const EdgeInsets.only(left: 4.0),
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
                LinearProgressIndicator(backgroundColor: Colors.transparent),
            ],
          ),
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
      ),
    );
  }
}
