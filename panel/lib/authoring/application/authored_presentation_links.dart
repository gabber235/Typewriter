part of "authored_presentation_host.dart";

/// Link planning, connection and disconnection.
///
/// A link at the same path of several resources edited together offers only
/// the targets every one of them may link, and a target one opposite
/// resource may hold for one source only is offered to none of them. Linking
/// and clearing reach every one of them in one edit.
extension _AuthoredPresentationLinks on AuthoredPresentationHost {
  PortableLinkPlanResult _planLink(
    skir.ValueLocation source, {
    required PortableInvocationContext context,
  }) {
    if (context.catalogGeneration != authored.generation) {
      return const PortableLinkPlanUnavailable("The editor catalog changed");
    }
    final planned = authored.linkPlans(
      catalog: authored.catalog,
      source: source,
    );
    final others = _each(source).skip(1).toList();
    if (others.isEmpty || planned is! PortableLinkPlanReady) return planned;
    final elsewhere = [
      for (final other in others)
        switch (authored.linkPlans(catalog: authored.catalog, source: other)) {
          PortableLinkPlanReady(:final plans) => plans,
          PortableLinkPlanUnavailable() => const <PortableLinkPlan>[],
        },
    ];
    return PortableLinkPlanResult.ready([
      for (final plan in planned.plans)
        plan.copyWith(
          targets: [
            for (final target in plan.targets)
              if (elsewhere.every(
                (plans) => _matchingTarget(plans, plan, target) != null,
              ))
                if (_sourceEndpoint(plan).cardinality ==
                    skir.EndpointCardinality.one)
                  target.copyWith(
                    disabledReason:
                        "Only one of the selected resources can link to the "
                        "same resource here",
                  )
                else
                  target,
          ],
        ),
    ]);
  }

  /// The endpoint [plan] links from.
  skir.EndpointDefinition _sourceEndpoint(PortableLinkPlan plan) =>
      plan.relation.first.id == plan.source.id.endpoint
      ? plan.relation.first
      : plan.relation.second;

  /// The plan among [plans] for the same relation end as [plan], and in it
  /// the choice of [target]'s resource, when it offers that resource.
  (PortableLinkPlan, PortableLinkTargetChoice)? _matchingTarget(
    List<PortableLinkPlan> plans,
    PortableLinkPlan plan,
    PortableLinkTargetChoice target,
  ) {
    for (final candidate in plans) {
      if (candidate.relation.id != plan.relation.id ||
          candidate.source.id.endpoint != plan.source.id.endpoint) {
        continue;
      }
      final choice = candidate.targets
          .where((option) => option.resource == target.resource)
          .firstOrNull;
      if (choice != null) return (candidate, choice);
    }
    return null;
  }

  Future<PortablePresentationWriteResult> _connectLink({
    required PortableLinkPlan plan,
    required PortableLinkTargetChoice target,
    required PortableLinkCounterpartRequest counterpart,
    required PortableInvocationContext context,
  }) async {
    final binding = edit;
    if (!enabled || readOnly || binding == null) {
      return _reject("This presentation is read only");
    }
    if (context.catalogGeneration != authored.generation) {
      return _reject("The editor catalog changed");
    }
    final result = await binding.prepare(
      label: "Change link",
      from: authored,
      apply: (operation) async {
        final sources = _each(plan.source.id.location).toList()
          ..forEach(operation.expect);
        final choice = await preparePortableLinkCounterpart(
          generation: operation.generation,
          counterpart: counterpart,
          prepareValue: prepareValue,
        );
        if (_disposed || !enabled || readOnly) {
          throw StateError("The presentation closed during preparation");
        }
        final collection = switch (counterpart) {
          PortableCollectionCounterpart(:final containing) => containing,
          _ => null,
        };
        for (final source in sources) {
          // Each later source plans against the edit so far, which already
          // holds the links and counterparts staged before it.
          final (sourcePlan, sourceTarget) = source == plan.source.id.location
              ? (plan, target)
              : _matchingTarget(
                      switch (operation.linkPlans(
                        catalog: authored.catalog,
                        source: source,
                      )) {
                        PortableLinkPlanReady(:final plans) => plans,
                        PortableLinkPlanUnavailable(:final message) =>
                          throw StateError(message),
                      },
                      plan,
                      target,
                    ) ??
                    (throw StateError(
                      "A selected resource cannot link to this resource",
                    ));
          operation.applyResolvedReference(
            operation.resolveReference(
              catalog: authored.catalog,
              plan: sourcePlan,
              target: sourceTarget,
              counterpart: choice,
              collection: collection,
            ),
          );
        }
      },
    );
    return switch (result) {
      EditStageRejected(:final message) => _reject(message),
      _ => const PortablePresentationWriteApplied(),
    };
  }

  PortablePresentationWriteResult _disconnectLink(
    skir.LinkOccurrence occurrence, {
    required PortableInvocationContext context,
  }) {
    if (context.catalogGeneration != authored.generation) {
      return _reject("The editor catalog changed");
    }
    // Each resource clears the link it holds at the occurrence's path, which
    // may lead elsewhere than [occurrence] when the links differ.
    return _stage("Clear link", (operation) {
      var cleared = false;
      for (final at in _each(occurrence.id.location)) {
        final link = switch (operation.read(at)) {
          PortablePathValue(:final value) => value.authoredLink,
          PortablePathUnavailable() => null,
        };
        if (link == null) continue;
        cleared = true;
        operation.disconnect(
          skir.LinkOccurrence(
            id: skir.LinkOccurrenceId(endpoint: link.endpoint, location: at),
            source: at.resource,
            target: link.target,
          ),
        );
      }
      if (!cleared) throw StateError("The link is no longer available");
    });
  }

  String _linkOccurrenceKey(
    skir.LinkProjection link,
    skir.RelationContract? relation,
  ) {
    final location = link.firstLocation ?? link.secondLocation;
    final first = link.firstLocation != null;
    final endpoint = first ? relation?.first.id : relation?.second.id;
    final containing = first ? link.first : link.second;
    return _framed([
      endpoint?.value ?? link.contract.value,
      containing.value,
      _pathKey(location),
    ]);
  }

  String _pathKey(skir.ValuePath? path) {
    if (path == null) return "n";
    return _framed([
      for (final segment in path.segments)
        switch (segment) {
          skir.PathSegment_fieldWrapper(:final value) => "f:${value.name}",
          skir.PathSegment_itemWrapper(:final value) => "i:${value.id.value}",
          skir.PathSegment.mapKey => "k",
          skir.PathSegment.mapValue => "v",
          skir.PathSegment_unknown() => "u",
        },
    ]);
  }

  String _framed(Iterable<String> values) =>
      values.map((value) => "${value.length}:$value").join();
}
