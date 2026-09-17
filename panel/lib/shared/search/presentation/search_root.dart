import "package:flutter/material.dart" hide SearchController;
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:hooks_riverpod/legacy.dart";
import "package:typewriter_panel/typewriter_panel.dart";

/// Controller scoped to one search surface.
///
/// The nullable default allows the provider to exist as a dependency anchor;
/// [SearchRoot] supplies the actual controller for its subtree.
final searchProvider = ChangeNotifierProvider<SearchController<dynamic>?>(
  (ref) => null,
  dependencies: [],
);

/// Creates and owns the controller visible to [child].
///
/// The [create] callback remains current without forcing provider recreation on
/// every rebuild. The provider owns the controller for this scope, and
/// Riverpod disposes the controller and its source when the scope is removed.
class SearchRoot extends StatelessWidget {
  const SearchRoot({required this.create, required this.child, super.key});

  final Widget child;
  final SearchController<dynamic> Function(Ref ref) create;

  @override
  Widget build(BuildContext context) {
    return ProviderScope(
      overrides: [searchProvider.overrideWith(create)],
      child: child,
    );
  }
}
