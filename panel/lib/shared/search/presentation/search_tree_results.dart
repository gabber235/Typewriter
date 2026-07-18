import "package:collection/collection.dart";
import "package:flutter/material.dart" hide SearchController;
import "package:flutter/services.dart";
import "package:flutter_animate/flutter_animate.dart";
import "package:flutter_hooks/flutter_hooks.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:typewriter_panel/app/presentation/shortcuts/action_shortcuts.dart";
import "package:typewriter_panel/shared/hooks/forward_animation.dart";
import "package:typewriter_panel/shared/search/presentation/search_result_empty_state.dart";
import "package:typewriter_panel/shared/search/presentation/search_result_renderers.dart";
import "package:typewriter_panel/shared/search/presentation/search_root.dart";
import "package:typewriter_panel/shared/search/presentation/search_tree_animated_body.dart";
import "package:typewriter_panel/shared/search/presentation/search_tree_section_header.dart";
import "package:typewriter_panel/shared/search/search_engine.dart";
import "package:typewriter_panel/shared/ui/components/admonition.dart";
import "package:typewriter_panel/shared/ui/components/context_menu.dart";
import "package:typewriter_panel/shared/ui/components/elastic_switcher.dart";
import "package:typewriter_panel/shared/ui/components/icons.dart";
import "package:typewriter_panel/shared/ui/components/labeled_message.dart";
import "package:typewriter_panel/shared/ui/components/vertical_clipper.dart";
import "package:typewriter_panel/shared/utilities/animation.dart";

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

    return ClipPath(
      clipper: VerticalClipper(additionalWidth: 500),
      child: CustomScrollView(
        clipBehavior: .none,
        slivers: [
          for (final error in snapshot.errorSummaries)
            SearchErrorSummarySliver(error: error),
          for (final guidance in snapshot.guidance)
            SearchGuidanceSliver(guidance: guidance),
          for (var i = 0; i < viewModel.groups.length; i++)
            SearchTreeSectionSliver(
              key: ValueKey(
                viewModel.groups[i].section?.key ?? "root_group:$i",
              ),
              group: viewModel.groups[i],
              rowRenderers: rowRenderers,
            ),
          const SliverToBoxAdapter(child: SizedBox(height: 8)),
        ],
      ),
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

    final actions = controller.actionsFor(result);
    final primaryAction = actions.firstOrNull;

    final actionState = controller.actionState;
    final actionsBusy = actionState is SearchActionRunning;
    final actionResults = switch (actionState) {
      SearchActionIdle() => null,
      SearchActionRunning(:final resultIds) => resultIds,
      SearchActionCompleted(:final resultIds) => resultIds,
      SearchActionFailed(:final resultIds) => resultIds,
    };
    final actionConcersThis = actionResults?.contains(result.id) ?? false;

    final rowContext = SearchResultRowContext(
      result: result,
      selected: controller.isSelected(result.id),
      focused: focused.value,
      loading: actionsBusy && actionConcersThis,
      onTap: () {
        if (controller.selectionMode == .single && actions.isNotEmpty) {
          controller.executeAction(
            actions.first.runtimeType,
            resultId: result.id,
          );
          return;
        }
        controller.toggleSelected(result.id);
      },
      shortcutActivator: activator,
    );

    final child =
        rowRenderers[result.type.rowRendererId]?.call(rowContext) ??
        MissingSearchResultRendererRow(result: result);

    void execute(Type actionType) {
      controller.executeAction(actionType, resultId: result.id);
    }

    Widget? actionIcon(SearchAction action) {
      if (actionConcersThis &&
          actionsBusy &&
          actionState.action == action.runtimeType) {
        return Builder(
          builder: (context) {
            final iconTheme = IconTheme.of(context);
            final iconSize = iconTheme.size ?? 24.0;
            final color = iconTheme.color;
            return SizedBox(
              width: iconSize,
              height: iconSize,
              child: CircularProgressIndicator(
                color: color,
                strokeWidth: 2,
                padding: const EdgeInsets.all(2),
              ),
            );
          },
        );
      }
      if (action.icon != null) {
        return Icones(action.icon!);
      }
      return null;
    }

    final resultActionIndex =
        actionResults?.indexed
            .firstWhereOrNull((element) => element.$2 == result.id)
            ?.$1 ??
        -1;

    final delay = resultActionIndex < 0
        ? 0.ms
        : 50.ms * (resultActionIndex + 1);

    final errorAnimation = useForwardAnimation(
      play: actionConcersThis && actionState is SearchActionFailed,
      delay: delay,
    );

    final runningAnimation = useForwardAnimation(
      play: actionConcersThis && actionsBusy,
      delay: delay,
    );

    final scale = TweenSequence([
      TweenSequenceItem(
        tween: Tween(begin: 1.0, end: 0.95).curved(Curves.ease),
        weight: 1.0,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 0.95, end: 1.02).curved(Curves.ease),
        weight: 2.0,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.02, end: 1.0).curved(Curves.ease),
        weight: 1.0,
      ),
    ]).animate(runningAnimation);

    return Padding(
      padding: EdgeInsets.only(left: 12.0 + row.depth * 16),
      child: ScaleTransition(
        scale: scale,
        child: ContextMenuRegion(
          items: [
            for (final (index, action) in actions.indexed)
              MenuItem(
                label: action.label,
                icon: ElasticSwitcher(child: actionIcon(action)),
                color: action.color,
                onPressed: actionsBusy
                    ? null
                    : () => execute(action.runtimeType),
                shortcuts: [
                  ?action.shortcut,
                  if (index == 0) ...[
                    SingleActivator(LogicalKeyboardKey.enter),
                    SingleActivator(LogicalKeyboardKey.numpadEnter),
                    ?activator,
                  ],
                ],
              ),
          ],
          child: ManagedActionSet(
            shortcuts: [
              if (primaryAction != null)
                ActionShortcut(
                  id: "search_tree_results_primary_action",
                  label: "",
                  description: "",
                  activators: [
                    SingleActivator(LogicalKeyboardKey.enter),
                    SingleActivator(LogicalKeyboardKey.numpadEnter),
                  ],
                  priority: 0,
                  show: false,
                  onInvoke: (_) => execute(primaryAction.runtimeType),
                ),
            ],
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
                controller.preview(result);
              },
              child: MouseRegion(
                onEnter: (_) => controller.preview(result),
                child: child,
              ),
            ),
          ),
        ),
      ),
    ).animate(controller: errorAnimation, autoPlay: false).shakeX();
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
