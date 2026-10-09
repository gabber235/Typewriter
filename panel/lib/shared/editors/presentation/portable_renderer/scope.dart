part of "../portable_presentation_renderer.dart";

final _configuredValueBindingId = skir.ExpressionBindingId(
  value: "configured_value",
);

typedef PortableSlotBuilder = Widget Function(PortablePresentationScope scope);

final class PortablePresentationScope {
  const PortablePresentationScope({
    required this.bindings,
    required this.budget,
    required this.setBinding,
    this.readOnly = false,
    this.enabled = true,
    this.invokeCommand,
    this.watchSearch,
    this.reload,
    this.reportStatus,
    this.commit,
    this.catalog,
    this.resource,
    this.searchHistoryNamespace,
    this.openResource,
    this.role,
    this.material,
    this.activePresentations = const {},
    this.slots = const {},
    this.slotBuilders = const {},
    this.host,
    this.projectedWriters = const {},
  });

  final Map<skir.ExpressionBindingId, PortableExpressionBinding> bindings;
  final skir.EvaluationBudget budget;
  final PortableBindingSetter setBinding;
  final bool readOnly;
  final bool enabled;
  final Future<void> Function(
    skir.CapabilityId capabilityId,
    skir.DataValue payload,
  )?
  invokeCommand;
  final Stream<skir.RealmPresentationSearchUpdate> Function(
    skir.RealmPresentationSearchRequest request,
  )?
  watchSearch;
  final Future<void> Function()? reload;
  final ValueChanged<String>? reportStatus;
  final Future<void> Function()? commit;
  final CheckedEditorCatalog? catalog;
  final skir.ResourceId? resource;
  final String? searchHistoryNamespace;
  final ValueChanged<skir.ResourceId>? openResource;
  final skir.PresentationRole? role;
  final skir.PresentationMaterial? material;
  final Set<skir.PresentationId> activePresentations;
  final Map<String, skir.PresentationNode> slots;
  final Map<String, PortableSlotBuilder> slotBuilders;
  final PortablePresentationHost? host;
  final Map<skir.ExpressionBindingId, PortableBindingSetter> projectedWriters;

  PortableInvocationContext get invocation => PortableInvocationContext(
    bindings: bindings,
    catalogGeneration:
        (catalog ?? host?.document.catalog)?.snapshot.generation ??
        (throw StateError("Portable invocation has no checked catalog")),
  );

  PortableExpressionResult evaluate(skir.ExpressionNode node) =>
      PortableExpressionEvaluator.located(
        bindings,
        budget: budget,
      ).evaluate(node);

  skir.DataValue? read(skir.BindingRef reference) {
    return host?.read(reference, context: invocation);
  }

  skir.ValueLocation? location(skir.BindingRef reference) {
    return host?.location(reference, context: invocation);
  }

  skir.BindingRef? sourceReference(skir.BindingRef reference) {
    final document = host?.document;
    if (document == null) return null;
    if (document.bindings.containsKey(reference.bindingId)) {
      return reference;
    }
    final local = bindings[reference.bindingId]?.location;
    if (local == null) return null;
    final targetSegments = [...local.path.segments, ...reference.path.segments];
    MapEntry<skir.ExpressionBindingId, PortablePresentationBinding>? owner;
    for (final candidate in document.bindings.entries) {
      final base = candidate.value.location;
      if (base == null || base.resource != local.resource) continue;
      if (!_isPathPrefix(base.path.segments.toList(), targetSegments)) {
        continue;
      }
      final previous = owner?.value.location?.path.segments.length ?? -1;
      if (base.path.segments.length > previous) owner = candidate;
    }
    final base = owner?.value.location;
    if (owner == null || base == null) return null;
    return skir.BindingRef(
      bindingId: owner.key,
      path: skir.ValuePath(
        segments: targetSegments.skip(base.path.segments.length),
      ),
    );
  }

  skir.TypeUse? expectedType(skir.BindingRef reference) {
    return host?.expectedType(reference, context: invocation);
  }

  skir.TypeUse? expectedPayloadType(skir.BindingRef reference) {
    final expected = expectedType(reference);
    final unwrapped = _unwrapNullable(expected);
    if (unwrapped case skir.TypeUse_namedWrapper(:final value)) {
      final representation = catalog
          ?.published(value.definition)
          ?.definition
          .representation;
      if (representation case skir.RepresentationTemplate_scalarWrapper(
        :final value,
      )) {
        return skir.TypeUse.wrapScalar(value.kind);
      }
    }
    return unwrapped;
  }

  void write(skir.BindingRef reference, skir.DataValue value) {
    final target = host;
    if (!enabled || readOnly || target == null) return;
    final projectedWriter = projectedWriters[reference.bindingId];
    if (projectedWriter != null) {
      projectedWriter(reference, value);
      return;
    }
    unawaited(
      target.write(reference, value, context: invocation).then((result) {
        if (result case PortablePresentationWriteRejected(:final message)) {
          reportStatus?.call(message);
        }
      }),
    );
  }

  void writePayload(skir.BindingRef reference, skir.DataValue payload) {
    final current = read(reference);
    final actual = switch (_unwrapNullable(expectedType(reference))) {
      skir.TypeUse_namedWrapper(:final value) => value,
      _ => null,
    };
    write(
      reference,
      current is skir.DataValue_namedWrapper
          ? _preserveNamedIdentity(current, payload)
          : actual == null
          ? payload
          : skir.DataValue.createNamed(actualType: actual, payload: payload),
    );
  }

  bool get canExecuteAction => enabled && !readOnly && host != null;

  PortablePresentationScope withReadOnly(bool value) =>
      PortablePresentationScope(
        bindings: bindings,
        budget: budget,
        setBinding: setBinding,
        readOnly: readOnly || value,
        enabled: enabled,
        invokeCommand: invokeCommand,
        watchSearch: watchSearch,
        reload: reload,
        reportStatus: reportStatus,
        commit: commit,
        catalog: catalog,
        resource: resource,
        searchHistoryNamespace: searchHistoryNamespace,
        openResource: openResource,
        role: role,
        material: material,
        activePresentations: activePresentations,
        slots: slots,
        slotBuilders: slotBuilders,
        host: host,
        projectedWriters: projectedWriters,
      );

  PortablePresentationScope withEnabled(bool value) =>
      PortablePresentationScope(
        bindings: bindings,
        budget: budget,
        setBinding: setBinding,
        readOnly: readOnly,
        enabled: enabled && value,
        invokeCommand: invokeCommand,
        watchSearch: watchSearch,
        reload: reload,
        reportStatus: reportStatus,
        commit: commit,
        catalog: catalog,
        resource: resource,
        searchHistoryNamespace: searchHistoryNamespace,
        openResource: openResource,
        role: role,
        material: material,
        activePresentations: activePresentations,
        slots: slots,
        slotBuilders: slotBuilders,
        host: host,
        projectedWriters: projectedWriters,
      );

  PortablePresentationScope withNamedPayload(PortableNamedPayload payload) {
    final configured = skir.ExpressionBindingId(value: "configured_value");
    void writeConfigured(skir.BindingRef reference, skir.DataValue value) {
      final replaced = reference.path.segments.isEmpty
          ? PortablePathValue(value)
          : payload.value.replaceAt(reference.path, value);
      if (replaced case PortablePathValue(:final value)) {
        payload.replace(value);
      }
    }

    return PortablePresentationScope(
      bindings: {
        ...bindings.withSubjectAt(payload.location),
        configured: PortableExpressionBinding(
          value: payload.value,
          location: payload.location,
        ),
      },
      budget: budget,
      readOnly: readOnly,
      enabled: enabled,
      invokeCommand: invokeCommand,
      watchSearch: watchSearch,
      reload: reload,
      reportStatus: reportStatus,
      commit: commit,
      catalog: catalog,
      resource: resource,
      searchHistoryNamespace: searchHistoryNamespace,
      openResource: openResource,
      role: role,
      material: material,
      activePresentations: activePresentations,
      slots: slots,
      slotBuilders: slotBuilders,
      host: host,
      projectedWriters: {...projectedWriters, configured: writeConfigured},
      setBinding: (reference, value) {
        if (reference.bindingId != configured) {
          setBinding(reference, value);
          return;
        }
        writeConfigured(reference, value);
      },
    );
  }

  PortablePresentationScope? withConfiguredValue(skir.BindingRef reference) {
    final source = bindings[reference.bindingId];
    if (source == null) return null;
    final resolved = reference.path.segments.isEmpty
        ? PortablePathValue(source.value)
        : source.value.readAt(reference.path);
    if (resolved case PortablePathUnavailable()) return null;
    final configured = skir.ExpressionBindingId(value: "configured_value");
    final value = (resolved as PortablePathValue<skir.DataValue>).value;
    final baseLocation = source.location;
    final location = baseLocation == null
        ? null
        : skir.ValueLocation(
            resource: baseLocation.resource,
            path: skir.ValuePath(
              segments: [
                ...baseLocation.path.segments,
                ...reference.path.segments,
              ],
            ),
          );
    return PortablePresentationScope(
      bindings: {
        ...bindings.withSubjectAt(location),
        configured: PortableExpressionBinding(
          value: value,
          location: location,
          schema: switch (expectedType(reference)) {
            final use? => CompletePortablePresentationBinding(use),
            null => null,
          },
        ),
      },
      budget: budget,
      readOnly: readOnly,
      enabled: enabled,
      invokeCommand: invokeCommand,
      watchSearch: watchSearch,
      reload: reload,
      reportStatus: reportStatus,
      commit: commit,
      catalog: catalog,
      resource: resource,
      searchHistoryNamespace: searchHistoryNamespace,
      openResource: openResource,
      setBinding: (nestedReference, replacement) {
        if (nestedReference.bindingId != configured) {
          write(nestedReference, replacement);
          return;
        }
        if (nestedReference.path.segments.isEmpty) {
          writePayload(reference, replacement);
          return;
        }
        final replaced = value.replaceAt(nestedReference.path, replacement);
        if (replaced case PortablePathValue(value: final next)) {
          write(reference, next);
        }
      },
      role: role,
      material: material,
      activePresentations: activePresentations,
      slots: slots,
      slotBuilders: slotBuilders,
      host: host,
      projectedWriters: projectedWriters,
    );
  }

  PortablePresentationScope? withBinding(
    skir.BindingRef reference,
    skir.ExpressionBindingId id,
  ) {
    final source = bindings[reference.bindingId];
    if (source == null) return null;
    final resolved = reference.path.segments.isEmpty
        ? PortablePathValue(source.value)
        : source.value.readAt(reference.path);
    if (resolved case PortablePathUnavailable()) return null;
    final value = (resolved as PortablePathValue<skir.DataValue>).value;
    final baseLocation = source.location;
    final location = baseLocation == null
        ? null
        : skir.ValueLocation(
            resource: baseLocation.resource,
            path: skir.ValuePath(
              segments: [
                ...baseLocation.path.segments,
                ...reference.path.segments,
              ],
            ),
          );
    return PortablePresentationScope(
      bindings: {
        ...(id == _configuredValueBindingId
            ? bindings.withSubjectAt(location)
            : bindings),
        id: PortableExpressionBinding(
          value: value,
          location: location,
          schema: switch (expectedType(reference)) {
            final use? => CompletePortablePresentationBinding(use),
            null => null,
          },
        ),
      },
      budget: budget,
      readOnly: readOnly,
      enabled: enabled,
      invokeCommand: invokeCommand,
      watchSearch: watchSearch,
      reload: reload,
      reportStatus: reportStatus,
      commit: commit,
      catalog: catalog,
      resource: resource,
      searchHistoryNamespace: searchHistoryNamespace,
      openResource: openResource,
      role: role,
      material: material,
      activePresentations: activePresentations,
      slots: slots,
      slotBuilders: slotBuilders,
      host: host,
      projectedWriters: projectedWriters,
      setBinding: (nestedReference, replacement) {
        if (nestedReference.bindingId != id) {
          write(nestedReference, replacement);
          return;
        }
        if (nestedReference.path.segments.isEmpty) {
          writePayload(reference, replacement);
          return;
        }
        final replaced = value.replaceAt(nestedReference.path, replacement);
        if (replaced case PortablePathValue(value: final next)) {
          write(reference, next);
        }
      },
    );
  }

  PortablePresentationScope withValues(
    Map<skir.ExpressionBindingId, skir.DataValue> values,
  ) => PortablePresentationScope(
    bindings: {
      ...bindings,
      for (final entry in values.entries)
        entry.key: PortableExpressionBinding(value: entry.value),
    },
    budget: budget,
    setBinding: setBinding,
    readOnly: readOnly,
    enabled: enabled,
    invokeCommand: invokeCommand,
    watchSearch: watchSearch,
    reload: reload,
    reportStatus: reportStatus,
    commit: commit,
    catalog: catalog,
    resource: resource,
    searchHistoryNamespace: searchHistoryNamespace,
    openResource: openResource,
    role: role,
    material: material,
    activePresentations: activePresentations,
    slots: slots,
    slotBuilders: slotBuilders,
    host: host,
    projectedWriters: projectedWriters,
  );

  PortablePresentationScope withSlotBuilders(
    Map<String, PortableSlotBuilder> values,
  ) => PortablePresentationScope(
    bindings: bindings,
    budget: budget,
    setBinding: setBinding,
    readOnly: readOnly,
    enabled: enabled,
    invokeCommand: invokeCommand,
    watchSearch: watchSearch,
    reload: reload,
    reportStatus: reportStatus,
    commit: commit,
    catalog: catalog,
    resource: resource,
    searchHistoryNamespace: searchHistoryNamespace,
    openResource: openResource,
    role: role,
    material: material,
    activePresentations: activePresentations,
    slots: slots,
    slotBuilders: {...slotBuilders, ...values},
    host: host,
    projectedWriters: projectedWriters,
  );

  PortablePresentationScope withActivePresentation(
    skir.PresentationId presentation,
  ) => PortablePresentationScope(
    bindings: bindings,
    budget: budget,
    setBinding: setBinding,
    readOnly: readOnly,
    enabled: enabled,
    invokeCommand: invokeCommand,
    watchSearch: watchSearch,
    reload: reload,
    reportStatus: reportStatus,
    commit: commit,
    catalog: catalog,
    resource: resource,
    searchHistoryNamespace: searchHistoryNamespace,
    openResource: openResource,
    role: role,
    material: material,
    activePresentations: {...activePresentations, presentation},
    slots: slots,
    slotBuilders: slotBuilders,
    host: host,
    projectedWriters: projectedWriters,
  );

  PortablePresentationScope withMaterial(skir.PresentationMaterial value) =>
      PortablePresentationScope(
        bindings: bindings,
        budget: budget,
        setBinding: setBinding,
        readOnly: readOnly,
        enabled: enabled,
        invokeCommand: invokeCommand,
        watchSearch: watchSearch,
        reload: reload,
        reportStatus: reportStatus,
        commit: commit,
        catalog: catalog,
        resource: resource,
        searchHistoryNamespace: searchHistoryNamespace,
        openResource: openResource,
        role: role,
        material: value,
        activePresentations: activePresentations,
        slots: slots,
        slotBuilders: slotBuilders,
        host: host,
        projectedWriters: projectedWriters,
      );
}

bool _isPathPrefix(List<skir.PathSegment> prefix, List<skir.PathSegment> path) {
  if (prefix.length > path.length) return false;
  for (var index = 0; index < prefix.length; index++) {
    if (prefix[index] != path[index]) return false;
  }
  return true;
}

skir.DataValue _preserveNamedIdentity(
  skir.DataValue? current,
  skir.DataValue payload,
) {
  if (current is! skir.DataValue_namedWrapper) return payload;
  return skir.DataValue.createNamed(
    actualType: current.value.actualType,
    payload: _preserveNamedIdentity(current.value.payload, payload),
  );
}

skir.TypeUse? _unwrapNullable(skir.TypeUse? type) {
  var current = type;
  while (current is skir.TypeUse_nullableWrapper) {
    current = current.value.value;
  }
  return current;
}

extension _PresentationSubjectBindings
    on Map<skir.ExpressionBindingId, PortableExpressionBinding> {
  Map<skir.ExpressionBindingId, PortableExpressionBinding> withSubjectAt(
    skir.ValueLocation? location,
  ) => {
    for (final entry in entries)
      if (entry.key != presentationSubjectIdentifierBindingId)
        entry.key: entry.value,
    if (location case final subject? when subject.path.segments.isEmpty)
      presentationSubjectIdentifierBindingId: PortableExpressionBinding(
        value: skir.DataValue.wrapStringValue(subject.resource.value),
      ),
  };
}
