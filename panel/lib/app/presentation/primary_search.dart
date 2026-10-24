import "package:typewriter_panel/typewriter_panel.dart";

part "primary_search.g.dart";

/// The modal configuration produced for the current route context.
final class PrimarySearchRequest {
  const PrimarySearchRequest({
    required this.contributionBuilder,
    this.searchHint = "Search",
    this.rowRenderers = const {},
    this.previewRenderers = const {},
  });

  final SearchContributionBuilder<void> contributionBuilder;
  final String searchHint;
  final Map<String, SearchResultRowBuilder> rowRenderers;
  final Map<String, SearchResultPreviewBuilder> previewRenderers;
}

/// Resolves the primary search surface for the current route context.
///
/// Keeping the complete request behind a provider lets alternate application
/// hosts supply their own data source while retaining the production surface
/// and result renderers.
@Riverpod(keepAlive: true)
PrimarySearchRequest primarySearchRequest(Ref ref) =>
    buildPrimarySearchRequest(ref);

/// Opens the route supplied primary search request.
Future<void> openPrimarySearch(BuildContext context, WidgetRef ref) async {
  final request = ref.read(primarySearchRequestProvider);
  await showSearchModal<void>(
    context,
    request.contributionBuilder,
    searchHint: request.searchHint,
    rowRenderers: request.rowRenderers,
    previewRenderers: request.previewRenderers,
  );
}

/// Compact app bar trigger for the primary search surface.
class PrimarySearchButton extends ConsumerWidget {
  const PrimarySearchButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.theme.colorScheme;
    return AppBarControl.filled(
      contentBuilder: (context, compact) => AppBarControlContent(
        compact: compact,
        icon: const Icon(Icons.search_rounded, size: 18),
        label: "Search",
        shortcut: ShortcutDisplay(
          shortcut: AdaptiveSingleActivator(
            LogicalKeyboardKey.keyK,
            control: true,
          ),
          size: 10,
          style: .solid(),
        ),
      ),
      tooltip: "Search",
      semanticLabel: "Search",
      preferredWidth: 360,
      onPressed: () => openPrimarySearch(context, ref),
      style: FilledButton.styleFrom(
        alignment: Alignment.centerLeft,
        minimumSize: const Size.fromHeight(40),
        backgroundColor: colors.surfaceContainer,
        foregroundColor: colors.onSurfaceVariant,
      ),
    );
  }
}

/// Registers the adaptive primary search shortcut for the application shell.
class PrimarySearchShortcut extends ConsumerWidget {
  const PrimarySearchShortcut({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ManagedActionSet(
      shortcuts: [
        ActionShortcut.intent(
          id: "primary_search",
          label: "Search",
          description: "Open primary search",
          intent: OpenSearchIntent,
          priority: -12,
          icon: const Icon(Icons.search_rounded),
          onInvoke: (ref) => openPrimarySearch(context, ref),
        ),
      ],
      child: child,
    );
  }
}
