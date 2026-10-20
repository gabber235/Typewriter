part of "../portable_presentation_renderer.dart";

Future<void> _chooseLink({
  required BuildContext context,
  required PortablePresentationScope scope,
  required skir.LinkControl control,
  required skir.ValueLocation location,
  required Map<skir.ResourceId, _AuthoredCollectionRow>? candidates,
  required skir.PresentationCollectionDefinition? candidateDefinition,
}) async {
  final linkHost = switch (scope.host) {
    final PortableLinkHost value => value,
    _ => null,
  };
  if (linkHost == null) return;
  final plans = linkHost.planLink(location, context: scope.invocation);
  if (!context.mounted) return;
  final choices = _authoredLinkChoices(
    plans: plans,
    scope: scope,
    candidates: candidates,
    candidateDefinition: candidateDefinition,
  );
  final selected = await showReferencePicker<_AuthoredLinkChoice>(
    context,
    candidates: [
      for (final choice in choices)
        ReferencePickerCandidate(
          id: choice.id,
          value: choice,
          label: choice.label,
          description: "${choice.typeLabel}. ${choice.subtitle}",
          searchText: choice.searchText,
          disabledReason: choice.disabledReason,
        ),
    ],
    candidatePolicy: control.candidatePolicy,
    problem: switch (plans) {
      PortableLinkPlanUnavailable(:final message) => message,
      PortableLinkPlanReady() => null,
    },
    searchHint:
        _entryPlaceholder(control.inputContent, scope) ??
        "Search linked resources",
    queryDecoration: _controlStyle(
      context,
      scope,
      control.inputAppearance,
    ).decoration,
    useDefaultQueryIcon:
        control.inputContent?.leading != skir.InputAdornment.none,
    queryStyle: _controlStyle(
      context,
      scope,
      control.inputAppearance,
    ).valueStyle,
    queryAlignment: _controlStyle(
      context,
      scope,
      control.inputAppearance,
    ).alignment,
    surfaceStyle: SearchSurfaceStyle(
      constraints: _popupConstraints(scope, control.popup),
      shape: _popupShape(context, scope, control.popup),
      fill: control.popup?.fill == null
          ? null
          : PresentationValueEnvironment.of(context)
                .resolve(control.popup!.fill!, scope),
      padding: control.popup?.padding == null
          ? null
          : _presentationInsets(control.popup!.padding),
    ),
    rowBuilder: (row) => _buildAuthoredLinkChoiceResult(row, scope: scope),
  );
  if (selected == null || !context.mounted) return;
  final decision = await _resolveAuthoredLinkChoice(choice: selected);
  final reference = control.control.binding;
  final address = scope.diagnosticTarget(reference);
  await scope.operations.run(
    key: PortableOperationKey.write(address),
    input: PortableDiagnosticObservation(
      target: address,
      value: scope.read(reference),
    ),
    operation: () => linkHost.connectLink(
      plan: decision.plan,
      target: decision.target,
      counterpart: decision.counterpart,
      context: scope.invocation,
    ),
  );
}

@freezed
abstract class _AuthoredLinkDecision with _$AuthoredLinkDecision {
  const factory _AuthoredLinkDecision({
    required PortableLinkPlan plan,
    required PortableLinkTargetChoice target,
    required PortableLinkCounterpartRequest counterpart,
  }) = __AuthoredLinkDecision;
}

enum _AuthoredLinkChoiceKind {
  automatic,
  existing,
  append,
  create,
  unavailable,
}

@freezed
abstract class _AuthoredLinkChoice with _$AuthoredLinkChoice {
  const factory _AuthoredLinkChoice({
    required String id,
    required String widgetKey,
    required PortableLinkPlan plan,
    required PortableLinkTargetChoice target,
    required _AuthoredLinkChoiceKind kind,
    required String label,
    required String typeLabel,
    required String subtitle,
    required String searchText,
    _AuthoredCollectionRow? row,
    skir.PresentationCollectionDefinition? definition,
    skir.LinkOccurrence? occurrence,
    PortableNewCounterpartChoice? slot,
    skir.ValueLocation? collection,
    String? disabledReason,
  }) = __AuthoredLinkChoice;
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
      final host = scope.host;
      final projectionHost = switch (host) {
        final PortableCollectionProjectionHost value => value,
        _ => null,
      };
      final resource = projectionHost?.projectResource(
        target.resource,
        context: scope.invocation,
      );
      final label =
          row?.label ?? resource?.appearance.label ?? target.resource.value;
      final typeLabel = resource == null
          ? "Resource"
          : scope.catalog?.typeSelectionName(resource.configuration) ??
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
      for (final collection in target.collections) {
        final path = _pathLabel(collection.path);
        choices.add(
          _AuthoredLinkChoice(
            id: "$planId:${target.resource.value}:append:$path",
            widgetKey: "link.target.${target.resource.value}.append.$path",
            plan: plan,
            target: target,
            kind: _AuthoredLinkChoiceKind.append,
            label: label,
            typeLabel: typeLabel,
            subtitle: "Add counterpart to $path",
            searchText: "$targetSearchText add counterpart $path",
            row: row,
            definition: candidateDefinition,
            collection: collection,
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
            disabledReason:
                scope.host is! PortableLinkHost ||
                    !(scope.host! as PortableLinkHost).canPrepareCounterpart
                ? "Creation preparation is unavailable"
                : null,
          ),
        );
      }
      if (!target.automaticCounterpart &&
          target.existing.isEmpty &&
          target.creatable.isEmpty &&
          target.collections.isEmpty) {
        choices.add(
          _AuthoredLinkChoice(
            id: "$planId:${target.resource.value}:unavailable",
            widgetKey: "link.target.${target.resource.value}.unavailable",
            plan: plan,
            target: target,
            kind: _AuthoredLinkChoiceKind.unavailable,
            label: label,
            typeLabel: typeLabel,
            subtitle:
                target.disabledReason ??
                "Choose or create a counterpart location first",
            searchText: targetSearchText,
            row: row,
            definition: candidateDefinition,
            disabledReason:
                target.disabledReason ?? "No counterpart location is available",
          ),
        );
      }
    }
  }
  return choices;
}

Widget _buildAuthoredLinkChoiceResult(
  SearchResultRowContext row, {
  required PortablePresentationScope scope,
}) {
  final payload = row.result.payload;
  if (payload is! _AuthoredLinkChoice) {
    return MissingSearchResultRendererRow(result: row.result);
  }
  final choice = payload;
  return Builder(
    builder: (context) {
      final kind = switch (choice.kind) {
        _AuthoredLinkChoiceKind.automatic => "automatic",
        _AuthoredLinkChoiceKind.existing => "existing",
        _AuthoredLinkChoiceKind.append => "append",
        _AuthoredLinkChoiceKind.create => "create",
        _AuthoredLinkChoiceKind.unavailable => "unavailable",
      };
      final footer = Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        spacing: context.spacing.space1,
        children: [
          SearchResultDescription(
            description: "${choice.typeLabel}. ${choice.subtitle}",
          ),
          if (choice.disabledReason case final reason?
              when reason != choice.subtitle)
            SearchResultDescription(description: reason),
        ],
      );
      // The reference picker is a modal, so its rows are cards.
      Widget fallback(ResourceAppearance? appearance, String? problem) =>
          SearchResultRow(
            row: row,
            density: SearchResultDensity.card,
            title: appearance?.label ?? choice.label,
            accent: appearance?.accent,
            leading: appearance == null
                ? Icon(switch (choice.kind) {
                    _AuthoredLinkChoiceKind.automatic => Icons.link,
                    _AuthoredLinkChoiceKind.existing => Icons.link_outlined,
                    _AuthoredLinkChoiceKind.append ||
                    _AuthoredLinkChoiceKind.create => Icons.add_link,
                    _AuthoredLinkChoiceKind.unavailable => Icons.link_off,
                  })
                : ResourceIcon(icon: appearance.icon),
            kindLabel: kind,
            footer: footer,
            body: problem == null ? null : Text(problem),
          );
      Widget render(
        skir.PresentationNode node,
        PortablePresentationScope targetScope,
        ResourceAppearance appearance,
      ) => PortableResultContent(
        node: node,
        appearance: appearance,
        scope: targetScope,
        row: row,
        density: SearchResultDensity.card,
        kindLabel: kind,
        footer: footer,
      );
      return KeyedSubtree(
        key: ValueKey(choice.widgetKey),
        child: _ResourceReferenceAppearance(
          resource: choice.target.resource,
          scope: choice.row?.scope ?? scope,
          role: skir.PresentationRole.referencePickerResult,
          render: render,
          fallback: fallback,
        ),
      );
    },
  );
}

Future<_AuthoredLinkDecision> _resolveAuthoredLinkChoice({
  required _AuthoredLinkChoice choice,
}) async {
  switch (choice.kind) {
    case _AuthoredLinkChoiceKind.automatic:
      return _AuthoredLinkDecision(
        plan: choice.plan,
        target: choice.target,
        counterpart: const PortableAutomaticCounterpart(),
      );
    case _AuthoredLinkChoiceKind.existing:
      return _AuthoredLinkDecision(
        plan: choice.plan,
        target: choice.target,
        counterpart: PortableExistingCounterpart(choice.occurrence!),
      );
    case _AuthoredLinkChoiceKind.append:
      return _AuthoredLinkDecision(
        plan: choice.plan,
        target: choice.target,
        counterpart: PortableCollectionCounterpart(choice.collection!),
      );
    case _AuthoredLinkChoiceKind.create:
      final slot = choice.slot;
      if (slot == null) {
        throw StateError("Creation preparation is unavailable");
      }
      return _AuthoredLinkDecision(
        plan: choice.plan,
        target: choice.target,
        counterpart: PortableCreatedCounterpart(slot),
      );
    case _AuthoredLinkChoiceKind.unavailable:
      throw StateError("No counterpart location is available");
  }
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
