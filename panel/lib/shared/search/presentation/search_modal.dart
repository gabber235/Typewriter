import "package:flutter/material.dart" hide SearchController;
import "package:flutter_animate/flutter_animate.dart";
import "package:flutter_hooks/flutter_hooks.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:typewriter_panel/typewriter_panel.dart";

/// Opens a themed, keyboard accessible search route.
///
/// The supplied [source] is initialized when the route creates its controller
/// and disposed when that controller is disposed. Renderer maps translate
/// source result and preview type identifiers into widgets. The returned
/// future completes when the route is removed.
Future<T?> showSearchModal<T>(
  BuildContext context,
  SearchContributionBuilder<T> contributionBuilder, {
  String searchHint = "Search",
  Map<String, SearchResultRowBuilder> rowRenderers = const {},
  Map<String, SearchResultPreviewBuilder> previewRenderers = const {},
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
          context.colors.scrim,
      traversalEdgeBehavior: TraversalEdgeBehavior.closedLoop,
      child: UncontrolledProviderScope(
        container: ProviderScope.containerOf(context),
        child: SelectionOperationsRoot(
          operations: SelectionOperationsRoot.of(context),
          child: GlobalModeShortcut(
            child: GlobalOperationShortcuts(
              child: SearchModal(
                contributionBuilder: contributionBuilder,
                searchHint: searchHint,
                rowRenderers: rowRenderers,
                previewRenderers: previewRenderers,
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

/// Connects modal configuration to a route local [SearchController].
///
/// [SearchModalBody] and its descendants read that controller through
/// [searchProvider]. The controller owns query, selection, preview, section,
/// and command state for this modal instance.
class SearchModal<T> extends HookWidget {
  const SearchModal({
    required this.contributionBuilder,
    this.searchHint = "Search",
    this.rowRenderers = const {},
    this.previewRenderers = const {},
    super.key,
  });

  final SearchContributionBuilder<T> contributionBuilder;
  final String searchHint;
  final Map<String, SearchResultRowBuilder> rowRenderers;
  final Map<String, SearchResultPreviewBuilder> previewRenderers;

  @override
  Widget build(BuildContext context) {
    return SearchRoot(
      create: (ref) {
        final SearchContribution(
          :session,
          :baseSelectors,
          :hostEffectExecutors,
        ) = contributionBuilder(
          ref,
          context,
        );
        return SearchController(
          session: session,
          baseSelectors: baseSelectors,
          prompts: _BuildContextSearchPromptHost(context),
          hostEffectExecutors: hostEffectExecutors,
          onCloseRequested: () => Navigator.of(context).maybePop(),
          onCompleted: (value) => Navigator.of(context).pop(value),
        );
      },
      child: SearchModalBody(
        searchHint: searchHint,
        rowRenderers: rowRenderers,
        previewRenderers: previewRenderers,
      ),
    );
  }
}

final class _BuildContextSearchPromptHost implements SearchPromptHost {
  const _BuildContextSearchPromptHost(this.context);

  final BuildContext context;

  @override
  Future<R?> show<R>(SearchPrompt<R> prompt) {
    if (!context.mounted) return Future.value();
    return prompt(context);
  }
}

class _PopupRoute<T> extends PopupRoute<T> {
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
              child: Padding(
                padding: EdgeInsets.all(context.spacing.space6),
                child: child,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
