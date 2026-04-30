import "package:collection/collection.dart";
import "package:flutter/material.dart" hide SearchController;
import "package:flutter_animate/flutter_animate.dart";
import "package:flutter_hooks/flutter_hooks.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:typewriter_panel/logic/search/search.dart";
import "package:typewriter_panel/widgets/generic/components/admonition.dart";
import "package:typewriter_panel/widgets/generic/components/labeled_message.dart";
import "package:typewriter_panel/widgets/generic/components/search/search_result_empty_state.dart";
import "package:typewriter_panel/widgets/generic/components/search/search_result_renderers.dart";
import "package:typewriter_panel/widgets/generic/components/search/search_root.dart";
import "package:typewriter_panel/widgets/generic/components/search/search_tree_animated_body.dart";
import "package:typewriter_panel/widgets/generic/components/search/search_tree_model.dart";
import "package:typewriter_panel/widgets/generic/components/search/search_tree_section_header.dart";

class SearchTreeResults extends HookConsumerWidget {
  const SearchTreeResults({required this.rowRenderers, super.key});

  final Map<String, SearchResultRowBuilder> rowRenderers;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.watch(searchProvider)!;
    final collapsedIds = controller.collapsedSectionIds.sorted();
    final collapsedKey = Object.hashAll(collapsedIds);
    final snapshot = controller.snapshot;
    final viewModel = useMemoized(
      () => buildSearchTreeViewModel(
        nodes: snapshot.nodes,
        isCollapsed: controller.isCollapsed,
      ),
      [snapshot.nodes, collapsedKey],
    );

    if (viewModel.rowCount == 0) {
      return SearchResultEmptyState(snapshot: snapshot);
    }

    return CustomScrollView(
      slivers: [
        for (final error in snapshot.errorSummaries)
          SearchErrorSummarySliver(error: error),
        for (final guidance in snapshot.guidance)
          SearchGuidanceSliver(guidance: guidance),
        const SliverToBoxAdapter(child: SizedBox(height: 8)),
        for (var i = 0; i < viewModel.groups.length; i++)
          SearchTreeSectionSliver(
            key: ValueKey(viewModel.groups[i].section?.key ?? "root_group:$i"),
            group: viewModel.groups[i],
            rowRenderers: rowRenderers,
          ),
        const SliverToBoxAdapter(child: SizedBox(height: 8)),
      ],
    );
  }
}

class SearchErrorSummarySliver extends StatelessWidget {
  const SearchErrorSummarySliver({required this.error, super.key});

  final SearchErrorSummary error;

  @override
  Widget build(BuildContext context) {
    Padding childBuilder() => Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: LabeledMessage(
        label: error.sourceLabel,
        message: error.message,
        messageStyle: Theme.of(context).textTheme.bodySmall,
      ),
    );
    final Widget admition = switch (error.severity) {
      SearchErrorSeverity.warning => Admonition.warning(child: childBuilder()),
      SearchErrorSeverity.error => Admonition.danger(child: childBuilder()),
    };

    return SliverPadding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      sliver: SliverResizingHeader(
        minExtentPrototype: Admonition.danger(
          child: LabeledMessage(label: error.sourceLabel),
        ),
        maxExtentPrototype: Admonition.danger(child: childBuilder()),
        child: admition,
      ),
    );
  }
}

class SearchGuidanceSliver extends StatelessWidget {
  const SearchGuidanceSliver({required this.guidance, super.key});

  final SearchGuidance guidance;

  @override
  Widget build(BuildContext context) {
    Widget childBuilder() => LabeledMessage(
      label: guidance.title,
      message: guidance.description,
      messageStyle: Theme.of(context).textTheme.bodySmall,
    );
    final Widget admition = Admonition.info(child: childBuilder());
    return SliverPadding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      sliver: SliverResizingHeader(
        minExtentPrototype: Admonition.danger(
          child: LabeledMessage(label: guidance.title),
        ),
        maxExtentPrototype: Admonition.danger(child: childBuilder()),
        child: admition,
      ),
    );
  }
}

class SearchTreeRowWidget extends ConsumerWidget {
  const SearchTreeRowWidget({
    required this.row,
    required this.rowRenderers,
    super.key,
  });

  final SearchTreeRow row;
  final Map<String, SearchResultRowBuilder> rowRenderers;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return switch (row) {
      final SearchTreeSectionRow section => SearchTreeSectionHeader(
        row: section,
        onToggle: () => ref.read(searchProvider)!.toggleSection(section.id),
      ),
      final SearchTreeResultRow resultRow => _SearchTreeResultRow(
        row: resultRow,
        rowRenderers: rowRenderers,
      ),
    };
  }
}

class _SearchTreeResultRow extends HookConsumerWidget {
  const _SearchTreeResultRow({required this.row, required this.rowRenderers});

  final SearchTreeResultRow row;
  final Map<String, SearchResultRowBuilder> rowRenderers;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final focused = useState(false);
    final controller = ref.watch(searchProvider)!;
    final result = row.result;
    final activator = searchResultShortcutActivator(row.shortcutNumber);
    final rowContext = SearchResultRowContext(
      result: result,
      selected: controller.isSelected(result.id),
      focused: focused.value,
      onTap: () => controller.toggleSelected(result.id),
      onLongPress: () => controller.toggleSelected(result.id),
      shortcutActivator: activator,
    );

    final child =
        rowRenderers[result.type.rowRendererId]?.call(rowContext) ??
        MissingSearchResultRendererRow(result: result);

    return Padding(
      padding: EdgeInsets.only(left: 12.0 + row.depth * 16),
      child: Focus(
        skipTraversal: true,
        descendantsAreTraversable: true,
        onFocusChange: (hasFocus) {
          focused.value = hasFocus;
          if (!hasFocus) return;
          Scrollable.ensureVisible(
            context,
            alignment: 0.5,
            alignmentPolicy: .explicit,
            duration: 300.ms,
            curve: Curves.easeOutCubic,
          );
        },
        child: child,
      ),
    );
  }
}

class SearchTreeSectionSliver extends ConsumerWidget {
  const SearchTreeSectionSliver({
    required this.group,
    required this.rowRenderers,
    super.key,
  });

  final SearchTreeTopLevelGroup group;
  final Map<String, SearchResultRowBuilder> rowRenderers;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final section = group.section;
    return SliverPadding(
      padding: const EdgeInsets.only(bottom: 8.0),
      sliver: SliverMainAxisGroup(
        slivers: [
          if (section != null)
            PinnedHeaderSliver(
              child: SearchTreeSectionHeader(
                row: section,
                onToggle: () =>
                    ref.read(searchProvider)!.toggleSection(section.id),
              ),
            ),
          SearchTreeAnimatedBody(rows: group.rows, rowRenderers: rowRenderers),
        ],
      ),
    );
  }
}
