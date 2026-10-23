import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";

const _typeSearchResultType = SearchResultType(
  id: "authoring.type",
  rowRendererId: "authoring.type",
  label: "Type",
);

/// Opens a single choice search over type [candidates].
///
/// [id] must give each candidate a unique, non empty identity; [label] and the
/// optional [display] metadata drive matching, sorting and the result rows.
/// Completes with the chosen candidate, or null when the search is dismissed.
Future<T?> showTypeSearch<T extends Object>(
  BuildContext context, {
  required String searchHint,
  required Iterable<T> candidates,
  required String Function(T candidate) id,
  required String Function(T candidate) label,
  skir.TypeDisplay? Function(T candidate)? display,
  String initialQuery = "",
  ValueChanged<String>? onQueryChanged,
  VoidCallback? onBack,
  Future<void>? cancelled,
}) {
  final values = List<T>.unmodifiable(candidates);
  final identities = <String>{};
  for (final candidate in values) {
    final identity = id(candidate);
    if (identity.isEmpty) {
      throw ArgumentError.value(
        identity,
        "id",
        "Type identity must not be empty",
      );
    }
    if (!identities.add(identity)) {
      throw ArgumentError.value(
        identity,
        "id",
        "Type identities must be unique",
      );
    }
  }
  return showSearchModal<T>(
    context,
    (_, _) => SearchContribution(
      session: SearchSession(
        initialQuery: initialQuery,
        source: _TypeSearchSource(
          candidates: values,
          id: id,
          label: label,
          display: display,
        ),
        interaction: SearchInteraction(
          activation: SearchActivation.custom(
            dependencies: const [],
            evaluate: (_, _) => const SearchActivationState.enabled(),
            activate: (_, result) async =>
                SearchActivationResult.complete(result.payload as T),
          ),
          selectionMode: SearchSelectionMode.single,
        ),
      ),
    ),
    searchHint: searchHint,
    onBack: onBack,
    onQueryChanged: onQueryChanged,
    cancelled: cancelled,
    rowRenderers: {
      _typeSearchResultType.rowRendererId: (row) {
        final candidate = row.result.payload as T;
        return _TypeSearchResultItem(
          label: label(candidate),
          display: display?.call(candidate),
          selected: row.selected,
          focused: row.focused,
          onTap: row.onTap,
          shortcutActivator: row.shortcutActivator,
        );
      },
    },
  );
}

final class _TypeSearchSource<T extends Object> implements SearchSource {
  _TypeSearchSource({
    required Iterable<T> candidates,
    required this.id,
    required this.label,
    required this.display,
  }) : candidates = List<T>.unmodifiable(candidates);

  final List<T> candidates;
  final String Function(T candidate) id;
  final String Function(T candidate) label;
  final skir.TypeDisplay? Function(T candidate)? display;
  final _snapshots = StreamController<SearchSourceSnapshot>.broadcast(
    sync: true,
  );
  bool _disposed = false;

  @override
  Stream<SearchSourceSnapshot> get snapshots => _snapshots.stream;

  @override
  List<QuerySelectorDefinition> get selectors => const [];

  @override
  void initialize(SearchQueryContext context) => search(context);

  @override
  void search(SearchQueryContext context) {
    if (_disposed) return;
    final term = context.normalizedQuery.trim().toLowerCase();
    final matches =
        candidates
            .where((candidate) {
              if (term.isEmpty) return true;
              final metadata = display?.call(candidate);
              return label(candidate).toLowerCase().contains(term) ||
                  (metadata?.description.toLowerCase().contains(term) ?? false);
            })
            .toList(growable: false)
          ..sort((left, right) => label(left).compareTo(label(right)));
    _snapshots.add(
      SearchSourceSnapshot.ready(
        nodes: [
          for (final candidate in matches)
            SearchNode.result(
              result: SearchResult(
                id: id(candidate),
                type: _typeSearchResultType,
                payload: candidate,
                title: label(candidate),
                subtitle: display?.call(candidate)?.description,
              ),
            ),
        ],
      ),
    );
  }

  @override
  Future<SearchPreviewRequestResult> preview(
    SearchPreviewRequest request,
  ) async => const SearchPreviewRequestResult.error(
    message: "Type choices do not provide a separate preview",
  );

  @override
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    unawaited(_snapshots.close());
  }
}

final class _TypeSearchResultItem extends StatelessWidget {
  const _TypeSearchResultItem({
    required this.label,
    required this.display,
    required this.selected,
    required this.focused,
    required this.onTap,
    required this.shortcutActivator,
  });

  final String label;
  final skir.TypeDisplay? display;
  final bool selected;
  final bool focused;
  final VoidCallback? onTap;
  final ShortcutActivator? shortcutActivator;

  @override
  Widget build(BuildContext context) {
    final color =
        display?.color.toFlutterColor() ??
        Theme.of(context).colorScheme.primary;
    final icon = display?.icon;
    final description = display?.description.trim();
    return SearchResultCard(
      color: color,
      prefix: SearchResultIconTile(
        color: color,
        onColor: color.on(context),
        icon: icon?.iconValue == null
            ? const Icon(Icons.category_outlined)
            : ResourceIcon(icon: icon),
        focused: focused,
      ),
      selected: selected,
      focused: focused,
      onTap: onTap,
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        spacing: context.spacing.space1,
        children: [
          SearchResultTitle(title: label),
          if (description != null && description.isNotEmpty)
            SearchResultDescription(description: description),
        ],
      ),
      suffix: SearchResultSuffix(
        label: "type",
        shortcutActivator: shortcutActivator,
        selected: selected,
      ),
    );
  }
}
