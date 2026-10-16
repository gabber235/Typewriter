import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";

part "reference_picker.freezed.dart";

@freezed
abstract class ReferencePickerCandidate<T extends Object>
    with _$ReferencePickerCandidate<T> {
  const factory ReferencePickerCandidate({
    required String id,
    required T value,
    required String label,
    @Default("") String description,
    @Default("") String searchText,
    skir.TypeDisplay? display,
    String? disabledReason,
  }) = _ReferencePickerCandidate<T>;
}

const _referencePickerResultType = SearchResultType(
  id: "authoring.reference.choice",
  rowRendererId: "authoring.reference.choice",
  label: "Linked resource",
);

/// Shows reference choices while the caller retains ownership of mutation.
Future<T?> showReferencePicker<T extends Object>(
  BuildContext context, {
  required List<ReferencePickerCandidate<T>> candidates,
  String searchHint = "Search linked resources",
  String initialQuery = "",
  ValueChanged<String>? onQueryChanged,
  VoidCallback? onBack,
  Future<void>? cancelled,
  String? problem,
  skir.LinkCandidatePolicyId? candidatePolicy,
  SearchResultRowBuilder? rowBuilder,
  SearchSurfaceStyle? surfaceStyle,
  InputDecoration? queryDecoration,
  TextStyle? queryStyle,
  TextAlign queryAlignment = TextAlign.start,
  bool useDefaultQueryIcon = true,
}) {
  final byId = {for (final candidate in candidates) candidate.id: candidate};
  if (byId.length != candidates.length) {
    throw ArgumentError("Reference candidate identities must be unique");
  }
  return showSearchModal<T>(
    context,
    (_, _) => SearchContribution(
      session: SearchSession(
        initialQuery: initialQuery,
        source: _ReferencePickerSearchSource(
          candidates,
          problem: problem,
          candidatePolicy: candidatePolicy,
        ),
        interaction: SearchInteraction(
          activation: SearchActivation.custom(
            dependencies: const [],
            evaluate: (_, result) {
              final reason = byId[result.id]!.disabledReason;
              return reason == null
                  ? const SearchActivationState.enabled()
                  : SearchActivationState.disabled(reason);
            },
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
    surfaceStyle: surfaceStyle,
    queryDecoration: queryDecoration,
    queryStyle: queryStyle,
    queryAlignment: queryAlignment,
    useDefaultQueryIcon: useDefaultQueryIcon,
    rowRenderers: {
      _referencePickerResultType.rowRendererId:
          rowBuilder ??
          (row) {
            final candidate = byId[row.result.id]!;
            return SearchResultCard(
              color: Theme.of(context).colorScheme.primary,
              prefix: SearchResultIconTile(
                color: Theme.of(context).colorScheme.primary,
                onColor: Theme.of(context).colorScheme.primary.on(context),
                icon: candidate.display?.icon.trim().isNotEmpty == true
                    ? Icones(candidate.display!.icon)
                    : const Icon(Icons.link),
                focused: row.focused,
                loading: row.loading,
              ),
              selected: row.selected,
              focused: row.focused,
              onTap: row.onTap,
              content: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  SearchResultTitle(title: candidate.label),
                  if (candidate.description.isNotEmpty)
                    SearchResultDescription(description: candidate.description),
                  if (candidate.disabledReason case final reason?)
                    SearchResultDescription(description: reason),
                ],
              ),
              suffix: SearchResultSuffix(
                label: candidate.disabledReason == null
                    ? "select"
                    : "unavailable",
                shortcutActivator: row.shortcutActivator,
                selected: row.selected,
              ),
            );
          },
    },
  );
}

/// Pure search over choices supplied by reference planning and creation.
final class _ReferencePickerSearchSource<T extends Object>
    implements SearchSource {
  _ReferencePickerSearchSource(
    Iterable<ReferencePickerCandidate<T>> candidates, {
    this.problem,
    this.candidatePolicy,
  }) : candidates = List.unmodifiable(candidates);

  final List<ReferencePickerCandidate<T>> candidates;
  final String? problem;
  final skir.LinkCandidatePolicyId? candidatePolicy;
  final _snapshots = StreamController<SearchSourceSnapshot>.broadcast(
    sync: true,
  );
  var _disposed = false;

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
    final matches = candidates.where(
      (candidate) =>
          term.isEmpty ||
          [
            candidate.label,
            candidate.description,
            candidate.searchText,
          ].join(" ").toLowerCase().contains(term),
    );
    _snapshots.add(
      SearchSourceSnapshot(
        status: problem == null
            ? SearchSourceStatus.ready
            : SearchSourceStatus.error,
        nodes: [
          if (matches.isNotEmpty)
            SearchNode.section(
              id: "authoring.link.choices",
              title: "Available resources",
              children: [
                for (final candidate in matches)
                  SearchNode.result(
                    result: SearchResult(
                      id: candidate.id,
                      type: _referencePickerResultType,
                      payload: candidate.value,
                      title: candidate.label,
                      subtitle: candidate.description,
                    ),
                  ),
              ],
            ),
        ],
        errorSummaries: [
          if (problem case final message?)
            SearchErrorSummary(
              id: "authoring.link.prepare",
              message: message,
              severity: SearchErrorSeverity.error,
              sourceLabel: "Linked resource",
            ),
        ],
        guidance: [
          if (candidatePolicy case final policy?)
            SearchGuidance(
              id: "authoring.link.candidate_policy",
              title: "Candidate policy",
              description: policy.value,
              visibility: SearchGuidanceVisibility.always,
            ),
        ],
      ),
    );
  }

  @override
  Future<SearchPreviewRequestResult> preview(
    SearchPreviewRequest request,
  ) async => const SearchPreviewRequestResult.error(
    message: "Linked resources do not provide a separate preview",
  );
  @override
  void dispose() {
    _disposed = true;
    unawaited(_snapshots.close());
  }
}
