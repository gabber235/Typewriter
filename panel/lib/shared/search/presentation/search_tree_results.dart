import "package:collection/collection.dart";
import "package:flutter/material.dart" hide SearchController;
import "package:flutter/services.dart";
import "package:flutter_animate/flutter_animate.dart";
import "package:flutter_hooks/flutter_hooks.dart";
import "package:hooks_riverpod/hooks_riverpod.dart";
import "package:typewriter_panel/typewriter_panel.dart";

/// Projects the controller snapshot into an interactive, scrollable result
/// tree.
///
/// Source errors and guidance appear before grouped rows. Section expansion is
/// read from and written to [SearchController], while row rendering is
/// delegated by result type identifier through [rowRenderers]. Empty states
/// replace the scroll view only when the projected row count is zero.
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
          SliverToBoxAdapter(child: SizedBox(height: context.spacing.space2)),
        ],
      ),
    );
  }
}

/// Displays one source error summary above the result groups.
///
/// Warning and error severities select distinct admonition treatments. The
/// resizing header keeps long messages compact until the user needs their full
/// content.
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
      padding: EdgeInsets.symmetric(vertical: context.spacing.space1),
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

/// Displays non blocking guidance supplied by a search source.
///
/// Guidance is rendered as a resizing informational sliver and does not alter
/// the controller snapshot or result tree.
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
      padding: EdgeInsets.symmetric(vertical: context.spacing.space1),
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

/// Maps a projected tree row to its section header or source supplied result
/// renderer.
class SearchTreeRowWidget extends ConsumerWidget {
  const SearchTreeRowWidget({
    required this.row,
    required this.rowRenderers,
    this.vsync,
    super.key,
  });

  final SearchTreeRow row;
  final Map<String, SearchResultRowBuilder> rowRenderers;
  final TickerProvider? vsync;

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
        vsync: vsync,
      ),
    };
  }
}

class _SearchTreeResultRow extends HookConsumerWidget {
  const _SearchTreeResultRow({
    required this.row,
    required this.rowRenderers,
    this.vsync,
  });

  final SearchTreeResultRow row;
  final Map<String, SearchResultRowBuilder> rowRenderers;
  final TickerProvider? vsync;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final focused = useState(false);
    final controller = ref.watch(searchProvider)!;
    final result = row.result;
    final activator = searchResultShortcutActivator(row.shortcutNumber);

    final commands = controller.commandsFor(result);
    final commandState = controller.commandState;
    final commandsBusy = commandState is SearchCommandRunning;
    final commandResults = switch (commandState) {
      SearchCommandIdle() => null,
      SearchCommandRunning(:final resultIds) => resultIds,
      SearchCommandCompleted(:final resultIds) => resultIds,
      SearchCommandFailed(:final resultIds) => resultIds,
    };
    final commandConcernsThis = commandResults?.contains(result.id) ?? false;

    final rowContext = SearchResultRowContext(
      result: result,
      selected: controller.isSelected(result.id),
      focused: focused.value || controller.currentPreview?.id == result.id,
      loading: commandsBusy && commandConcernsThis,
      onTap: () {
        if (controller.selectionMode == .single) {
          controller.activate(result);
          return;
        }
        controller.toggleSelected(result.id);
      },
      shortcutActivator: activator,
    );

    final child =
        rowRenderers[result.type.rowRendererId]?.call(rowContext) ??
        MissingSearchResultRendererRow(result: result);

    void execute(SearchCommandId commandId) {
      controller.executeCommand(commandId, resultId: result.id);
    }

    Widget? commandIcon(SearchCommand command) {
      if (commandConcernsThis &&
          commandsBusy &&
          commandState.command == command.id) {
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
      if (command.presentation.icon != null) {
        return Icones(command.presentation.icon);
      }
      return null;
    }

    final resultCommandIndex =
        commandResults?.indexed
            .firstWhereOrNull((element) => element.$2 == result.id)
            ?.$1 ??
        -1;

    final delay = resultCommandIndex < 0
        ? 0.ms
        : 50.ms * (resultCommandIndex + 1);

    final errorAnimation = useForwardAnimation(
      play: commandConcernsThis && commandState is SearchCommandFailed,
      delay: delay,
      vsync: vsync,
    );

    final runningAnimation = useForwardAnimation(
      play: commandConcernsThis && commandsBusy,
      delay: delay,
      vsync: vsync,
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
      padding: EdgeInsets.only(
        left: context.spacing.space3 + row.depth * context.spacing.space4,
      ),
      child: ScaleTransition(
        scale: scale,
        child: ContextMenuRegion(
          items: [
            for (final resolved in commands)
              MenuItem(
                label: resolved.command.presentation.label,
                icon: ElasticSwitcher(child: commandIcon(resolved.command)),
                color: resolved.command.presentation.color,
                onPressed:
                    commandsBusy || resolved.state is! SearchCommandEnabled
                    ? null
                    : () => execute(resolved.command.id),
                shortcuts: [?resolved.command.presentation.shortcut],
              ),
          ],
          child: ManagedActionSet(
            shortcuts: [
              ActionShortcut(
                id: "search_tree_results_activate",
                label: "",
                description: "",
                activators: [
                  SingleActivator(LogicalKeyboardKey.enter),
                  SingleActivator(LogicalKeyboardKey.numpadEnter),
                ],
                priority: 0,
                show: false,
                onInvoke:
                    controller.isBusy ||
                        controller.activationState(result)
                            is! SearchActivationEnabled
                    ? null
                    : (_) => controller.activate(result),
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
              child: child,
            ),
          ),
        ),
      ),
    ).animate(controller: errorAnimation, autoPlay: false).shakeX();
  }
}

/// Renders one top level tree group as a sliver group.
///
/// Top level section headers are pinned so the section remains identifiable
/// while its animated rows scroll. Loose result rows have no header.
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
      padding: EdgeInsets.only(bottom: context.spacing.space2),
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
