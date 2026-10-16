import "package:typewriter_panel/typewriter_panel.dart";

/// Opens a themed, keyboard accessible search route.
///
/// The supplied [source] is initialized when the route creates its controller
/// and disposed when that controller is disposed. Renderer maps translate
/// source result and preview type identifiers into widgets. The returned
/// future completes when the route is removed. [onBack] enables a previous
/// question button that closes this route before invoking the callback.
/// [cancelled] removes this exact route when its owning operation ends.
Future<T?> showSearchModal<T>(
  BuildContext context,
  SearchContributionBuilder<T> contributionBuilder, {
  String searchHint = "Search",
  SearchSurfaceStyle? surfaceStyle,
  InputDecoration? queryDecoration,
  TextStyle? queryStyle,
  TextAlign queryAlignment = TextAlign.start,
  bool useDefaultQueryIcon = true,
  VoidCallback? onBack,
  ValueChanged<String>? onQueryChanged,
  Future<void>? cancelled,
  Map<String, SearchResultRowBuilder> rowRenderers = const {},
  Map<String, SearchResultPreviewBuilder> previewRenderers = const {},
}) {
  final navigator = Navigator.of(context);
  final route = _PopupRoute<T>(
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
              onBack: onBack,
              onQueryChanged: onQueryChanged,
              searchHint: searchHint,
              surfaceStyle: surfaceStyle,
              queryDecoration: queryDecoration,
              queryStyle: queryStyle,
              queryAlignment: queryAlignment,
              useDefaultQueryIcon: useDefaultQueryIcon,
              rowRenderers: rowRenderers,
              previewRenderers: previewRenderers,
            ),
          ),
        ),
      ),
    ),
  );
  final completed = navigator.push(route);
  if (cancelled != null) {
    unawaited(
      cancelled.then((_) {
        if (route.isActive) navigator.removeRoute(route);
      }),
    );
  }
  return completed;
}

/// Connects modal configuration to a route local [SearchController].
///
/// [SearchBody] and its descendants read that controller through
/// [searchProvider]. The controller owns query, selection, preview, section,
/// and command state for this modal instance.
class SearchModal<T> extends HookWidget {
  const SearchModal({
    required this.contributionBuilder,
    this.searchHint = "Search",
    this.onBack,
    this.onQueryChanged,
    this.surfaceStyle,
    this.queryDecoration,
    this.queryStyle,
    this.queryAlignment = TextAlign.start,
    this.useDefaultQueryIcon = true,
    this.rowRenderers = const {},
    this.previewRenderers = const {},
    super.key,
  });

  final SearchContributionBuilder<T> contributionBuilder;
  final VoidCallback? onBack;
  final ValueChanged<String>? onQueryChanged;
  final SearchSurfaceStyle? surfaceStyle;
  final InputDecoration? queryDecoration;
  final TextStyle? queryStyle;
  final TextAlign queryAlignment;
  final bool useDefaultQueryIcon;
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
        final controller = SearchController(
          session: session,
          baseSelectors: baseSelectors,
          prompts: _BuildContextSearchPromptHost(context),
          hostEffectExecutors: hostEffectExecutors,
          onCloseRequested: () => Navigator.of(context).maybePop(),
          onCompleted: (value) => Navigator.of(context).pop(value),
        );
        if (onQueryChanged != null) {
          controller.addListener(() => onQueryChanged!(controller.query));
        }
        return controller;
      },
      child: SearchBody(
        searchHint: searchHint,
        surfaceStyle: surfaceStyle,
        queryDecoration: queryDecoration,
        frameBuilder: onBack == null
            ? SearchFrame.new
            : ({
                required queryBar,
                required searchResults,
                actionBar,
                preview,
              }) => SearchFrame(
                queryBar: Row(
                  children: [
                    Builder(
                      builder: (context) => BackButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                          onBack!();
                        },
                      ),
                    ),
                    Expanded(child: queryBar),
                  ],
                ),
                searchResults: searchResults,
                actionBar: actionBar,
                preview: preview,
              ),
        queryStyle: queryStyle,
        queryAlignment: queryAlignment,
        useDefaultQueryIcon: useDefaultQueryIcon,
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
