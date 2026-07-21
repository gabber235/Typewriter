import "package:flutter/material.dart" hide SearchController;
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:hooks_riverpod/legacy.dart";
import "package:typewriter_panel/typewriter_panel.dart";

final searchProvider = ChangeNotifierProvider<SearchController?>(
  (ref) => null,
  dependencies: [],
);

class SearchRoot extends HookConsumerWidget {
  const SearchRoot({required this.create, required this.child, super.key});

  final Widget child;
  final SearchController Function(Ref ref) create;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ProviderScope(
      overrides: [searchProvider.overrideWith(create)],
      child: child,
    );
  }
}
