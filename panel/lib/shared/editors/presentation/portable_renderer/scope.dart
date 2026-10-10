part of "../portable_presentation_renderer.dart";

final _configuredValueBindingId = skir.ExpressionBindingId(
  value: "configured_value",
);

typedef PortableSlotBuilder = Widget Function(PortablePresentationScope scope);

@Freezed(map: FreezedMapOptions.none, when: FreezedWhenOptions.none)
abstract class PortablePresentationScope with _$PortablePresentationScope {
  factory PortablePresentationScope({
    required Map<skir.ExpressionBindingId, PortableExpressionBinding> bindings,
    required skir.EvaluationBudget budget,
    bool readOnly = false,
    bool enabled = true,
    Stream<skir.RealmPresentationSearchUpdate> Function(
      skir.RealmPresentationSearchRequest request,
    )?
    watchSearch,
    ValueChanged<String>? reportStatus,
    Future<void> Function()? commit,
    CheckedEditorCatalog? catalog,
    skir.ResourceId? resource,
    String? searchHistoryNamespace,
    ValueChanged<skir.ResourceId>? openResource,
    skir.PresentationRole? role,
    skir.PresentationMaterial? material,
    Set<skir.PresentationId> activePresentations = const {},
    Map<String, skir.PresentationNode> slots = const {},
    Map<String, PortableSlotBuilder> slotBuilders = const {},
    PortablePresentationHost? host,
    Map<skir.ExpressionBindingId, PortableBindingSetter> projectedWriters =
        const {},
  }) => PortablePresentationScope._value(
    bindings: Map.unmodifiable(bindings),
    budget: budget,
    readOnly: readOnly,
    enabled: enabled,
    watchSearch: watchSearch,
    reportStatus: reportStatus,
    commit: commit,
    catalog: catalog,
    resource: resource,
    searchHistoryNamespace: searchHistoryNamespace,
    openResource: openResource,
    role: role,
    material: material,
    activePresentations: Set.unmodifiable(activePresentations),
    slots: Map.unmodifiable(slots),
    slotBuilders: Map.unmodifiable(slotBuilders),
    host: host,
    projectedWriters: Map.unmodifiable(projectedWriters),
  );

  const factory PortablePresentationScope._value({
    required Map<skir.ExpressionBindingId, PortableExpressionBinding> bindings,
    required skir.EvaluationBudget budget,
    required bool readOnly,
    required bool enabled,
    required Stream<skir.RealmPresentationSearchUpdate> Function(
      skir.RealmPresentationSearchRequest request,
    )?
    watchSearch,
    required ValueChanged<String>? reportStatus,
    required Future<void> Function()? commit,
    required CheckedEditorCatalog? catalog,
    required skir.ResourceId? resource,
    required String? searchHistoryNamespace,
    required ValueChanged<skir.ResourceId>? openResource,
    required skir.PresentationRole? role,
    required skir.PresentationMaterial? material,
    required Set<skir.PresentationId> activePresentations,
    required Map<String, skir.PresentationNode> slots,
    required Map<String, PortableSlotBuilder> slotBuilders,
    required PortablePresentationHost? host,
    required Map<skir.ExpressionBindingId, PortableBindingSetter>
    projectedWriters,
  }) = _PortablePresentationScope;
  const PortablePresentationScope._();

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
      if (!skir.ValuePath(segments: targetSegments).isAtOrBelow(base.path)) {
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
    final unwrapped = expected.withoutNullableWrappers;
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
    final actual = switch (expectedType(reference).withoutNullableWrappers) {
      skir.TypeUse_namedWrapper(:final value) => value,
      _ => null,
    };
    write(
      reference,
      current is skir.DataValue_namedWrapper
          ? current.preservingNamedIdentity(payload)
          : actual == null
          ? payload
          : skir.DataValue.createNamed(actualType: actual, payload: payload),
    );
  }

  bool get canExecuteAction => enabled && !readOnly && host != null;

  PortablePresentationScope withReadOnly(bool value) =>
      copyWith(readOnly: readOnly || value);

  PortablePresentationScope withEnabled(bool value) =>
      copyWith(enabled: enabled && value);

  // Collection replacements allocate owned values because generated copyWith
  // enters the private Freezed value constructor directly.
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

    return copyWith(
      bindings: {
        ...bindings.withSubjectAt(payload.location),
        configured: PortableExpressionBinding(
          value: payload.value,
          location: payload.location,
        ),
      },
      projectedWriters: {...projectedWriters, configured: writeConfigured},
    );
  }

  PortablePresentationScope? withConfiguredValue(skir.BindingRef reference) =>
      withBinding(reference, _configuredValueBindingId);

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
    final originalWriter = projectedWriters[reference.bindingId];
    final nextWriters = {...projectedWriters}..remove(id);
    if (originalWriter != null) {
      nextWriters[id] = (nestedReference, replacement) {
        originalWriter(
          skir.BindingRef(
            bindingId: reference.bindingId,
            path: skir.ValuePath(
              segments: [
                ...reference.path.segments,
                ...nestedReference.path.segments,
              ],
            ),
          ),
          replacement,
        );
      };
    }
    return copyWith(
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
      projectedWriters: nextWriters,
    );
  }

  PortablePresentationScope withValues(
    Map<skir.ExpressionBindingId, skir.DataValue> values,
  ) => copyWith(
    bindings: {
      ...bindings,
      for (final entry in values.entries)
        entry.key: PortableExpressionBinding(value: entry.value),
    },
  );

  PortablePresentationScope withSlotBuilders(
    Map<String, PortableSlotBuilder> values,
  ) => copyWith(slotBuilders: {...slotBuilders, ...values});

  PortablePresentationScope withActivePresentation(
    skir.PresentationId presentation,
  ) => copyWith(activePresentations: {...activePresentations, presentation});

  PortablePresentationScope withMaterial(skir.PresentationMaterial value) =>
      copyWith(material: value);
}

extension _PortableNamedIdentity on skir.DataValue? {
  skir.DataValue preservingNamedIdentity(skir.DataValue payload) {
    final current = this;
    if (current is! skir.DataValue_namedWrapper) return payload;
    return skir.DataValue.createNamed(
      actualType: current.value.actualType,
      payload: current.value.payload.preservingNamedIdentity(payload),
    );
  }
}

extension _PortableNullableTypeUse on skir.TypeUse? {
  skir.TypeUse? get withoutNullableWrappers {
    var current = this;
    while (current is skir.TypeUse_nullableWrapper) {
      current = current.value.value;
    }
    return current;
  }
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
