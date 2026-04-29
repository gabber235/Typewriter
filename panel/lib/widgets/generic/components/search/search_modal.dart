import "package:flutter/material.dart" hide SearchController;
import "package:flutter_animate/flutter_animate.dart";
import "package:flutter_hooks/flutter_hooks.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:typewriter_panel/logic/search/search.dart";
import "package:typewriter_panel/widgets/app/components/inspector/operations.dart";
import "package:typewriter_panel/widgets/app/components/interaction_mode/global_mode_shortcut.dart";
import "package:typewriter_panel/widgets/generic/components/search/search_modal_body.dart";
import "package:typewriter_panel/widgets/generic/components/search/search_root.dart";

Future<void> showSearchModal(
  BuildContext context,
  SearchSource source, {
  List<QuerySelectorDefinition> baseSelectors = const [],
  String initialQuery = "",
  String searchHint = "Search",
}) {
  return Navigator.of(context).push(
    _PopupRoute(
      themes: InheritedTheme.capture(
        from: context,
        to: Navigator.of(context).context,
      ),
      barrierColor:
          DialogTheme.of(context).barrierColor ??
          Theme.of(context).dialogTheme.barrierColor ??
          Colors.black54,
      traversalEdgeBehavior: TraversalEdgeBehavior.closedLoop,
      child: UncontrolledProviderScope(
        container: ProviderScope.containerOf(context),
        child: GlobalModeShortcut(
          child: GlobalOperationShortcuts(
            child: SearchModal(
              source: source,
              baseSelectors: baseSelectors,
              initialQuery: initialQuery,
              searchHint: searchHint,
            ),
          ),
        ),
      ),
    ),
  );
}

class SearchModal extends HookWidget {
  const SearchModal({
    required this.source,
    this.baseSelectors = const [],
    this.initialQuery = "",
    this.searchHint = "Search",
    super.key,
  });

  final SearchSource source;
  final List<QuerySelectorDefinition> baseSelectors;
  final String initialQuery;

  final String searchHint;

  @override
  Widget build(BuildContext context) {
    return SearchRoot(
      create: (ref) {
        return SearchController(
          source: source,
          baseSelectors: baseSelectors,
          initialQuery: initialQuery,
          onCloseRequested: () => Navigator.of(context).maybePop(),
        );
      },
      child: SearchModalBody(searchHint: searchHint),
    );
  }
}

class _PopupRoute extends PopupRoute<void> {
  _PopupRoute({
    required this.child,
    required this.themes,
    required this.barrierColor,
    super.traversalEdgeBehavior,
  });

  final Widget child;
  final CapturedThemes themes;

  @override
  final Color barrierColor;

  @override
  bool get barrierDismissible => true;

  @override
  String? get barrierLabel => null;

  @override
  Duration get transitionDuration => 500.ms;

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) {
    final curvedAnimation = CurvedAnimation(
      parent: animation,
      curve: ElasticOutCurve(0.8),
      reverseCurve: Curves.easeInCubic,
    );

    return themes.wrap(
      SafeArea(
        child: Center(
          child: FadeTransition(
            opacity: curvedAnimation,
            child: ScaleTransition(
              scale: Tween<double>(
                begin: 0.96,
                end: 1,
              ).animate(curvedAnimation),
              child: Padding(padding: const EdgeInsets.all(24), child: child),
            ),
          ),
        ),
      ),
    );
  }
}
