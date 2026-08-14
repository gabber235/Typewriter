part of "icon_selector.dart";

const _iconResultExtent = 48.0;

class _IconSelectorResults extends StatelessWidget {
  const _IconSelectorResults({
    required this.visible,
    required this.controller,
    required this.results,
  });

  final bool visible;
  final ScrollController controller;
  final List<SearchResult> results;

  @override
  Widget build(BuildContext context) {
    final disableAnimations = MediaQuery.disableAnimationsOf(context);
    final rowCount = visible ? results.length.clamp(0, 5) : 0;
    final height = rowCount * _iconResultExtent;
    final rows = buildSearchTreeViewModel(
      nodes: results
          .map((result) => SearchNode.result(result: result))
          .toList(growable: false),
      isCollapsed: (_) => false,
    ).groups.expand((group) => group.rows).toList(growable: false);

    return Semantics(
      liveRegion: true,
      label: visible ? "${results.length} icon results" : null,
      child: AnimatedSize(
        duration: disableAnimations ? Duration.zero : 500.ms,
        curve: Curves.easeInOutCubic,
        alignment: Alignment.topCenter,
        child: SizedBox(
          height: height,
          child: ClipRRect(
            borderRadius: BorderRadius.vertical(
              bottom: context.shapes.mediumRadius,
            ),
            child: CustomScrollView(
              controller: controller,
              slivers: [
                SearchTreeAnimatedBody(
                  rows: rows,
                  rowRenderers: const {
                    "iconifyIcon": _buildIconSearchResultRow,
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
