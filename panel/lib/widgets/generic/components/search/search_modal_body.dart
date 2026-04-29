import "package:flutter/material.dart" hide SearchController;
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:typewriter_panel/widgets/app/components/action_shortcuts.dart";
import "package:typewriter_panel/widgets/app/components/decorated_text_field.dart";
import "package:typewriter_panel/widgets/generic/components/input_icon_button.dart";
import "package:typewriter_panel/widgets/generic/components/query_bar.dart";
import "package:typewriter_panel/widgets/generic/components/search/search_frame.dart";
import "package:typewriter_panel/widgets/generic/components/search/search_root.dart";

class SearchModalBody extends HookConsumerWidget {
  const SearchModalBody({required this.searchHint, super.key});

  final String searchHint;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.watch(searchProvider)!;
    return Actions(
      actions: {
        if (controller.canClose)
          DismissIntent: CallbackAction<DismissIntent>(
            onInvoke: (_) => controller.close(),
          ),
      },
      child: SearchFrame(
        queryBar: QueryBar(
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
        searchResults: const SizedBox.shrink(),
        actionBar: const ActionRow(),
      ),
    );
  }
}
