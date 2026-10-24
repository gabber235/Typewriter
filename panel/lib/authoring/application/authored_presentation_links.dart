part of "authored_presentation_host.dart";

/// Link planning, connection and disconnection.
extension _AuthoredPresentationLinks on AuthoredPresentationHost {
  PortableLinkPlanResult _planLink(
    skir.ValueLocation source, {
    required PortableInvocationContext context,
  }) {
    if (context.catalogGeneration != authored.generation) {
      return const PortableLinkPlanUnavailable("The editor catalog changed");
    }
    return authored.linkPlans(catalog: authored.catalog, source: source);
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
        operation.expect(plan.source.id.location);
        final choice = await preparePortableLinkCounterpart(
          generation: operation.generation,
          counterpart: counterpart,
          prepareValue: prepareValue,
        );
        if (_disposed || !enabled || readOnly) {
          throw StateError("The presentation closed during preparation");
        }
        operation.applyResolvedReference(
          operation.resolveReference(
            catalog: authored.catalog,
            plan: plan,
            target: target,
            counterpart: choice,
            collection: switch (counterpart) {
              PortableCollectionCounterpart(:final containing) => containing,
              _ => null,
            },
          ),
        );
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
    return _stage("Clear link", (operation) {
      operation.disconnect(occurrence);
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
