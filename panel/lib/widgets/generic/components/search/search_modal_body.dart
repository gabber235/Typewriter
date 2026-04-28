import "package:flutter/material.dart" hide SearchController;
import "package:flutter_hooks/flutter_hooks.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:typewriter_panel/logic/search/search.dart";
import "package:typewriter_panel/widgets/generic/components/query_bar.dart";
import "package:typewriter_panel/widgets/generic/components/search/search_root.dart";

class SearchModalBody extends HookConsumerWidget {
  const SearchModalBody({required this.initialQuery, super.key});

  final String initialQuery;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.watch(searchProvider)!;
    return Container();
  }
}
