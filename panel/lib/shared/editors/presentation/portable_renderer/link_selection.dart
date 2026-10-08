part of "../portable_presentation_renderer.dart";

Future<void> _chooseLink({
  required BuildContext context,
  required PortablePresentationScope scope,
  required skir.LinkControl control,
  required skir.ValueLocation location,
  required Map<skir.ResourceId, _AuthoredCollectionRow>? candidates,
  required skir.PresentationCollectionDefinition? candidateDefinition,
}) async {
  final draft = scope.authoring;
  final catalog = scope.catalog;
  if (draft == null || catalog == null) return;
  final plans = portableLinkPlans(
    draft: draft,
    catalog: catalog,
    source: location,
  );
  if (!context.mounted) return;
  final choices = _authoredLinkChoices(
    plans: plans,
    scope: scope,
    candidates: candidates,
    candidateDefinition: candidateDefinition,
  );
  final decision = await showSearchModal<_AuthoredLinkDecision>(
    context,
    (ref, modalContext) {
      final source = _AuthoredLinkSearchSource(
        choices,
        candidatePolicy: control.candidatePolicy,
        problem: switch (plans) {
          PortableLinkPlanUnavailable(:final message) => message,
          PortableLinkPlanReady() => null,
        },
      );
      return SearchContribution(
        session: SearchSession(
          source: source,
          interaction: SearchInteraction(
            activation: SearchActivation.custom(
              dependencies: const [],
              evaluate: (_, result) {
                final choice = result.payload as _AuthoredLinkChoice;
                final reason = choice.disabledReason;
                return reason == null
                    ? const SearchActivationState.enabled()
                    : SearchActivationState.disabled(reason);
              },
              activate: (_, result) async {
                final choice = result.payload as _AuthoredLinkChoice;
                try {
                  final decision = await _resolveAuthoredLinkChoice(
                    choice: choice,
                    scope: scope,
                    source: location,
                  );
                  return SearchActivationResult.complete(decision);
                } on Object catch (error) {
                  source.reportFailure(
                    "The counterpart could not be prepared: $error",
                  );
                  return const SearchActivationResult.keepOpen();
                }
              },
            ),
            selectionMode: SearchSelectionMode.single,
          ),
        ),
      );
    },
    searchHint: "Search linked resources",
    rowRenderers: {
      _authoredLinkChoiceResultType.rowRendererId:
          _buildAuthoredLinkChoiceResult,
    },
  );
  if (decision == null) return;
  draft.connect(
    decision.plan.source,
    decision.target.resource,
    counterpart: decision.counterpart,
  );
  scope.onDraftChanged?.call();
}

final class _AuthoredLinkDecision {
  const _AuthoredLinkDecision({
    required this.plan,
    required this.target,
    required this.counterpart,
  });

  final PortableLinkPlan plan;
  final PortableLinkTargetChoice target;
  final skir.CounterpartChoice? counterpart;
}

const _authoredLinkChoiceResultType = SearchResultType(
  id: "authoring.link.choice",
  rowRendererId: "authoring.link.choice",
  label: "Linked resource",
);

enum _AuthoredLinkChoiceKind { automatic, existing, create, unavailable }

final class _AuthoredLinkChoice {
  const _AuthoredLinkChoice({
    required this.id,
    required this.widgetKey,
    required this.plan,
    required this.target,
    required this.kind,
    required this.label,
    required this.typeLabel,
    required this.subtitle,
    required this.searchText,
    this.row,
    this.definition,
    this.occurrence,
    this.slot,
    this.disabledReason,
  });

  final String id;
  final String widgetKey;
  final PortableLinkPlan plan;
  final PortableLinkTargetChoice target;
  final _AuthoredLinkChoiceKind kind;
  final String label;
  final String typeLabel;
  final String subtitle;
  final String searchText;
  final _AuthoredCollectionRow? row;
  final skir.PresentationCollectionDefinition? definition;
  final skir.LinkOccurrence? occurrence;
  final PortableNewCounterpartChoice? slot;
  final String? disabledReason;
}

List<_AuthoredLinkChoice> _authoredLinkChoices({
  required PortableLinkPlanResult plans,
  required PortablePresentationScope scope,
  required Map<skir.ResourceId, _AuthoredCollectionRow>? candidates,
  required skir.PresentationCollectionDefinition? candidateDefinition,
}) {
  if (plans case PortableLinkPlanUnavailable()) return const [];
  final choices = <_AuthoredLinkChoice>[];
  for (final plan in (plans as PortableLinkPlanReady).plans) {
    final planId = [
      plan.relation.id.value,
      plan.source.id.endpoint.value,
      plan.source.id.location.resource.value,
      _pathLabel(plan.source.id.location.path),
    ].join(":");
    for (final target in plan.targets) {
      final row = candidates?[target.resource];
      if (candidates != null && row == null) continue;
      final record = scope.authoring?.resource(target.resource);
      final label = _authoredLinkTargetLabel(record) ?? target.resource.value;
      final typeLabel = record == null
          ? "Resource"
          : scope.catalog?.typeSelectionName(record.configuration) ??
                "Resource";
      final targetSearchText = [
        target.resource.value,
        label,
        typeLabel,
        if (row != null) canonicalAuthoredValue(row.row),
      ].join(" ").toLowerCase();
      if (target.automaticCounterpart) {
        choices.add(
          _AuthoredLinkChoice(
            id: "$planId:${target.resource.value}:automatic",
            widgetKey: "link.target.${target.resource.value}.automatic",
            plan: plan,
            target: target,
            kind: _AuthoredLinkChoiceKind.automatic,
            label: label,
            typeLabel: typeLabel,
            subtitle: "Use the declared counterpart",
            searchText: "$targetSearchText declared counterpart",
            row: row,
            definition: candidateDefinition,
          ),
        );
      }
      for (final occurrence in target.existing) {
        final path = _pathLabel(occurrence.id.location.path);
        choices.add(
          _AuthoredLinkChoice(
            id: "$planId:${target.resource.value}:existing:$path",
            widgetKey: "link.target.${target.resource.value}.existing.$path",
            plan: plan,
            target: target,
            kind: _AuthoredLinkChoiceKind.existing,
            label: label,
            typeLabel: typeLabel,
            subtitle: "Use $path",
            searchText: "$targetSearchText use $path",
            row: row,
            definition: candidateDefinition,
            occurrence: occurrence,
          ),
        );
      }
      for (final slot in target.creatable) {
        final path = _pathLabel(slot.containing.path);
        choices.add(
          _AuthoredLinkChoice(
            id: "$planId:${target.resource.value}:new:$path",
            widgetKey: "link.target.${target.resource.value}.new.$path",
            plan: plan,
            target: target,
            kind: _AuthoredLinkChoiceKind.create,
            label: label,
            typeLabel: typeLabel,
            subtitle: "Create counterpart in $path",
            searchText: "$targetSearchText create counterpart $path",
            row: row,
            definition: candidateDefinition,
            slot: slot,
            disabledReason: scope.prepareCreation == null
                ? "Creation preparation is unavailable"
                : null,
          ),
        );
      }
      if (!target.automaticCounterpart &&
          target.existing.isEmpty &&
          target.creatable.isEmpty) {
        choices.add(
          _AuthoredLinkChoice(
            id: "$planId:${target.resource.value}:unavailable",
            widgetKey: "link.target.${target.resource.value}.unavailable",
            plan: plan,
            target: target,
            kind: _AuthoredLinkChoiceKind.unavailable,
            label: label,
            typeLabel: typeLabel,
            subtitle: "Choose or create a counterpart location first",
            searchText: targetSearchText,
            row: row,
            definition: candidateDefinition,
            disabledReason: "No counterpart location is available",
          ),
        );
      }
    }
  }
  return choices;
}

String? _authoredLinkTargetLabel(skir.AuthoringRecord? record) {
  if (record == null) return null;
  for (final field in const ["name", "title"]) {
    final value = record.authoredField(field)?.authoredString?.trim();
    if (value != null && value.isNotEmpty) return value;
  }
  return null;
}

final class _AuthoredLinkSearchSource implements SearchSource {
  _AuthoredLinkSearchSource(
    this.choices, {
    required this.candidatePolicy,
    required this.problem,
  });

  final List<_AuthoredLinkChoice> choices;
  final skir.LinkCandidatePolicyId? candidatePolicy;
  final String? problem;
  final _snapshots = StreamController<SearchSourceSnapshot>.broadcast(
    sync: true,
  );
  SearchQueryContext _query = SearchQueryContext.empty;
  String? _failure;
  bool _disposed = false;

  @override
  Stream<SearchSourceSnapshot> get snapshots => _snapshots.stream;

  @override
  List<QuerySelectorDefinition> get selectors => const [];

  @override
  void initialize(SearchQueryContext context) => search(context);

  @override
  void search(SearchQueryContext context) {
    _query = context;
    _failure = null;
    _publish();
  }

  void reportFailure(String message) {
    _failure = message;
    _publish();
  }

  void _publish() {
    if (_disposed) return;
    final term = _query.normalizedQuery.trim().toLowerCase();
    final matches = choices
        .where((choice) => term.isEmpty || choice.searchText.contains(term))
        .toList(growable: false);
    final failure = _failure ?? problem;
    _snapshots.add(
      SearchSourceSnapshot(
        status: failure == null
            ? SearchSourceStatus.ready
            : SearchSourceStatus.error,
        nodes: [
          if (matches.isNotEmpty)
            SearchNode.section(
              id: "authoring.link.choices",
              title: "Available resources",
              children: [
                for (final choice in matches)
                  SearchNode.result(
                    result: SearchResult(
                      id: choice.id,
                      type: _authoredLinkChoiceResultType,
                      payload: choice,
                      title: choice.label,
                      subtitle: "${choice.typeLabel}. ${choice.subtitle}",
                    ),
                  ),
              ],
            ),
        ],
        errorSummaries: [
          if (failure != null)
            SearchErrorSummary(
              id: "authoring.link.prepare",
              message: failure,
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
    if (_disposed) return;
    _disposed = true;
    unawaited(_snapshots.close());
  }
}

Widget _buildAuthoredLinkChoiceResult(SearchResultRowContext context) {
  final choice = context.result.payload as _AuthoredLinkChoice;
  return Builder(
    builder: (buildContext) {
      final color = Theme.of(buildContext).colorScheme.primary;
      final appearance = choice.row != null && choice.definition != null
          ? _AuthoredCollectionRowAppearance(
              row: choice.row!,
              definition: choice.definition!,
            )
          : SearchResultTitle(title: choice.label);
      return SearchResultCard(
        key: ValueKey(choice.widgetKey),
        color: color,
        prefix: SearchResultIconTile(
          color: color,
          onColor: color.on(buildContext),
          icon: Icon(switch (choice.kind) {
            _AuthoredLinkChoiceKind.automatic => Icons.link,
            _AuthoredLinkChoiceKind.existing => Icons.link_outlined,
            _AuthoredLinkChoiceKind.create => Icons.add_link,
            _AuthoredLinkChoiceKind.unavailable => Icons.link_off,
          }),
          focused: context.focused,
          loading: context.loading,
        ),
        selected: context.selected,
        focused: context.focused,
        onTap: context.onTap,
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          spacing: buildContext.spacing.space1,
          children: [
            IgnorePointer(child: appearance),
            SearchResultDescription(
              description: "${choice.typeLabel}. ${choice.subtitle}",
            ),
          ],
        ),
        suffix: SearchResultSuffix(
          label: switch (choice.kind) {
            _AuthoredLinkChoiceKind.automatic => "automatic",
            _AuthoredLinkChoiceKind.existing => "existing",
            _AuthoredLinkChoiceKind.create => "create",
            _AuthoredLinkChoiceKind.unavailable => "unavailable",
          },
          shortcutActivator: context.shortcutActivator,
          selected: context.selected,
        ),
      );
    },
  );
}

Future<_AuthoredLinkDecision> _resolveAuthoredLinkChoice({
  required _AuthoredLinkChoice choice,
  required PortablePresentationScope scope,
  required skir.ValueLocation source,
}) async {
  switch (choice.kind) {
    case _AuthoredLinkChoiceKind.automatic:
      return _AuthoredLinkDecision(
        plan: choice.plan,
        target: choice.target,
        counterpart: null,
      );
    case _AuthoredLinkChoiceKind.existing:
      return _AuthoredLinkDecision(
        plan: choice.plan,
        target: choice.target,
        counterpart: skir.CounterpartChoice.wrapExisting(choice.occurrence!),
      );
    case _AuthoredLinkChoiceKind.create:
      final prepare = scope.prepareCreation;
      final draft = scope.authoring;
      final slot = choice.slot;
      if (prepare == null || draft == null || slot == null) {
        throw StateError("Creation preparation is unavailable");
      }
      final identity = _initializationIdentity(
        generation: draft.generation,
        source: source,
        target: choice.target.resource,
        slot: slot,
      );
      final prepared = await prepare(
        skir.InitializationRequest(
          id: skir.InitializationRequestId(value: "panel:link:$identity"),
          catalog: draft.generation,
          type: slot.selection,
          supplied: const [],
          intentHash: identity,
        ),
      );
      return _AuthoredLinkDecision(
        plan: choice.plan,
        target: choice.target,
        counterpart: skir.CounterpartChoice.createNew(
          containing: slot.containing,
          prepared: prepared,
        ),
      );
    case _AuthoredLinkChoiceKind.unavailable:
      throw StateError("No counterpart location is available");
  }
}

String _initializationIdentity({
  required skir.CatalogGeneration generation,
  required skir.ValueLocation source,
  required skir.ResourceId target,
  required PortableNewCounterpartChoice slot,
}) {
  final content = [
    generation.value,
    source.resource.value,
    _pathLabel(source.path),
    target.value,
    slot.containing.resource.value,
    _pathLabel(slot.containing.path),
    slot.selection.toString(),
  ].join("\u0000");
  return sha256.convert(utf8.encode(content)).toString();
}

String _pathLabel(skir.ValuePath path) {
  if (path.segments.isEmpty) return "resource root";
  return path.segments
      .map((segment) {
        return switch (segment) {
          skir.PathSegment_fieldWrapper(:final value) => value.name,
          skir.PathSegment_itemWrapper(:final value) =>
            "item ${value.id.value}",
          final value when value == skir.PathSegment.mapKey => "key",
          final value when value == skir.PathSegment.mapValue => "value",
          _ => "unknown",
        };
      })
      .join(" / ");
}
