part of "search_input.dart";

class _SearchInputResults extends StatelessWidget {
  const _SearchInputResults({
    required this.visible,
    required this.searchController,
    required this.scope,
    required this.maximumExtent,
    required this.controller,
    required this.isSelected,
    required this.onSelect,
    required this.onSelectionPointerDown,
    required this.onSelectionPointerEnd,
  });

  final bool visible;
  final SearchController searchController;
  final PresentationRenderScope scope;
  final double maximumExtent;
  final ScrollController controller;
  final bool Function(SearchResult result) isSelected;
  final ValueChanged<SearchResult> onSelect;
  final VoidCallback onSelectionPointerDown;
  final VoidCallback onSelectionPointerEnd;

  @override
  Widget build(BuildContext context) {
    final snapshot = searchController.snapshot;
    final viewModel = buildSearchTreeViewModel(
      nodes: snapshot.nodes,
      isCollapsed: searchController.isCollapsed,
    );
    final rows = viewModel.groups
        .expand((group) {
          return [if (group.section != null) group.section!, ...group.rows];
        })
        .toList(growable: false);
    final disableAnimations = MediaQuery.disableAnimationsOf(context);

    return Semantics(
      liveRegion: true,
      label: visible
          ? "${snapshot.nodes.walk().whereType<SearchResultNode>().length} search results"
          : null,
      child: AnimatedSize(
        duration: disableAnimations ? Duration.zero : 420.ms,
        curve: Curves.easeInOutCubic,
        alignment: Alignment.topCenter,
        child: !visible
            ? const SizedBox.shrink()
            : ConstrainedBox(
                constraints: BoxConstraints(maxHeight: maximumExtent),
                child: ClipRRect(
                  borderRadius: BorderRadius.vertical(
                    bottom: context.shapes.mediumRadius,
                  ),
                  child: CustomScrollView(
                    controller: controller,
                    shrinkWrap: true,
                    slivers: [
                      if (snapshot.errorSummaries case [final error, ...])
                        SliverToBoxAdapter(
                          child: _SearchInputMessage(
                            message: error.message,
                            error: error.severity == SearchErrorSeverity.error,
                            onRetry: searchController.refresh,
                          ),
                        )
                      else if (snapshot.guidance case [final guidance, ...])
                        SliverToBoxAdapter(
                          child: _SearchInputMessage(message: guidance.title),
                        )
                      else if (rows.isEmpty)
                        const SliverToBoxAdapter(
                          child: _SearchInputMessage(
                            message: "No matching results",
                          ),
                        ),
                      SearchTreeAnimatedBody(
                        rows: rows,
                        rowRenderers: {
                          presentationSearchResultType.rowRendererId: (row) =>
                              _PresentationSearchResultRow(
                                context: row,
                                scope: scope,
                                selected: isSelected(row.result),
                                onSelect: () => onSelect(row.result),
                                onPointerDown: onSelectionPointerDown,
                                onPointerEnd: onSelectionPointerEnd,
                              ),
                        },
                      ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }
}

class _SearchInputMessage extends StatelessWidget {
  const _SearchInputMessage({
    required this.message,
    this.error = false,
    this.onRetry,
  });

  final String message;
  final bool error;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final spacing = context.spacing;
    return Padding(
      padding: EdgeInsets.only(
        top: spacing.space1,
        left: spacing.space3,
        right: spacing.space3,
        bottom: spacing.space4,
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              message,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: error
                    ? Theme.of(context).colorScheme.error
                    : Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          if (onRetry != null)
            IconButton(
              tooltip: "Retry search",
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
            ),
        ],
      ),
    );
  }
}

class _SearchInputStatus extends StatelessWidget {
  const _SearchInputStatus({required this.controller});

  final SearchController controller;

  @override
  Widget build(BuildContext context) => switch (controller.snapshot.status) {
    SearchSourceStatus.error => InputIconButton(
      icon: const Icon(Icons.refresh_rounded),
      tooltip: "Retry search",
      onPressed: controller.refresh,
    ),
    _ => const SizedBox.shrink(),
  };
}
