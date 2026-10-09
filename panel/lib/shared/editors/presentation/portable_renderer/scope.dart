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
    this.authoring,
    this.catalog,
    this.resource,
    this.edit,
    this.openResource,
    this.prepareCreation,
    this.role,
    this.material,
    this.activePresentations = const {},
    this.slots = const {},
    this.slotBuilders = const {},
    this.host,
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
  final PortableAuthoringView? authoring;
  final CheckedEditorCatalog? catalog;
  final skir.ResourceId? resource;
  final AuthoringBinding? edit;
  final ValueChanged<skir.ResourceId>? openResource;
  final Future<skir.PreparedCreation> Function(
    skir.InitializationRequest request,
  )?
  prepareCreation;
  final skir.PresentationRole? role;
  final skir.PresentationMaterial? material;
  final Set<skir.PresentationId> activePresentations;
  final Map<String, skir.PresentationNode> slots;
  final Map<String, PortableSlotBuilder> slotBuilders;
  final PortablePresentationHost? host;

  AuthoringEditResult stage(
    String label,
    void Function(AuthoringEdit edit) apply, {
    bool independent = false,
  }) {
    final binding = edit;
    final from = authoring is AuthoringDocument
        ? authoring! as AuthoringDocument
        : null;
    final result = binding == null || !enabled || readOnly
        ? const AuthoringEditResult.rejected(
            "This presentation is read only",
            null,
          )
        : independent
        ? binding.workspace.edit(label: label, apply: apply, from: from)
        : binding.edit(label: label, apply: apply, from: from);
    if (result case AuthoringEditRejected(:final message)) {
      reportStatus?.call(message);
    }
    return result;
  }

  Future<AuthoringEditResult> prepare(
    String label,
    Future<void> Function(AuthoringEdit edit) apply,
  ) async {
    final binding = edit;
    final from = authoring is AuthoringDocument
        ? authoring! as AuthoringDocument
        : null;
    if (binding == null || !enabled || readOnly) {
      return const AuthoringEditResult.rejected(
        "This presentation is read only",
        null,
      );
    }
    final result = await binding.prepare(
      label: label,
      apply: apply,
      from: from,
    );
    if (result case AuthoringEditRejected(:final message)) {
      reportStatus?.call(message);
    }
    return result;
  }

  PortableExpressionResult evaluate(skir.ExpressionNode node) =>
      PortableExpressionEvaluator.located(
        bindings,
        budget: budget,
      ).evaluate(node);

  skir.DataValue? read(skir.BindingRef reference) {
    final source = bindings[reference.bindingId];
    if (source == null) return null;
    if (reference.path.segments.isEmpty) return source.value;
    return switch (source.value.readAt(reference.path)) {
      PortablePathValue(:final value) => value,
      PortablePathUnavailable() => null,
    };
  }

  skir.ValueLocation? location(skir.BindingRef reference) {
    final source = bindings[reference.bindingId]?.location;
    if (source == null) return null;
    return skir.ValueLocation(
      resource: source.resource,
      path: skir.ValuePath(
        segments: [...source.path.segments, ...reference.path.segments],
      ),
    );
  }

  skir.TypeUse? expectedType(skir.BindingRef reference) {
    final hosted = host?.expectedType(reference);
    if (hosted != null) return hosted;
    final target = location(reference);
    final checked = catalog;
    final authored = authoring;
    if (target == null || checked == null || authored == null) return null;
    final record = authored.resource(target.resource);
    if (record == null) return null;
    final payload = skir.DataValue.createRecord(fields: record.fields);
    final value = switch (record.configuration) {
      skir.TypeSelection_completeWrapper(:final value) =>
        skir.DataValue.createNamed(actualType: value, payload: payload),
      _ => payload,
    };
    return checked.valueTypeAt(record.configuration, target.path, value: value);
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
    if (enabled && !readOnly) setBinding(reference, value);
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

  bool get canExecuteAction =>
      enabled && !readOnly && (authoring != null || host != null);

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
        authoring: authoring,
        catalog: catalog,
        resource: resource,
        edit: edit,
        openResource: openResource,
        prepareCreation: prepareCreation,
        role: role,
        material: material,
        activePresentations: activePresentations,
        slots: slots,
        slotBuilders: slotBuilders,
        host: host,
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
        authoring: authoring,
        catalog: catalog,
        resource: resource,
        edit: edit,
        openResource: openResource,
        prepareCreation: prepareCreation,
        role: role,
        material: material,
        activePresentations: activePresentations,
        slots: slots,
        slotBuilders: slotBuilders,
        host: host,
      );

  PortablePresentationScope withNamedPayload(PortableNamedPayload payload) {
    final configured = skir.ExpressionBindingId(value: "configured_value");
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
      authoring: authoring,
      catalog: catalog,
      resource: resource,
      edit: edit,
      openResource: openResource,
      prepareCreation: prepareCreation,
      role: role,
      material: material,
      activePresentations: activePresentations,
      slots: slots,
      slotBuilders: slotBuilders,
      host: host,
      setBinding: (reference, value) {
        if (reference.bindingId != configured) {
          setBinding(reference, value);
          return;
        }
        final replaced = reference.path.segments.isEmpty
            ? PortablePathValue(value)
            : payload.value.replaceAt(reference.path, value);
        if (replaced case PortablePathValue(:final value)) {
          payload.replace(value);
        }
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
        configured: PortableExpressionBinding(value: value, location: location),
      },
      budget: budget,
      readOnly: readOnly,
      enabled: enabled,
      invokeCommand: invokeCommand,
      watchSearch: watchSearch,
      reload: reload,
      reportStatus: reportStatus,
      commit: commit,
      authoring: authoring,
      catalog: catalog,
      resource: resource,
      edit: edit,
      openResource: openResource,
      prepareCreation: prepareCreation,
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
        id: PortableExpressionBinding(value: value, location: location),
      },
      budget: budget,
      readOnly: readOnly,
      enabled: enabled,
      invokeCommand: invokeCommand,
      watchSearch: watchSearch,
      reload: reload,
      reportStatus: reportStatus,
      commit: commit,
      authoring: authoring,
      catalog: catalog,
      resource: resource,
      edit: edit,
      openResource: openResource,
      prepareCreation: prepareCreation,
      role: role,
      material: material,
      activePresentations: activePresentations,
      slots: slots,
      slotBuilders: slotBuilders,
      host: host,
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
    authoring: authoring,
    catalog: catalog,
    resource: resource,
    edit: edit,
    openResource: openResource,
    prepareCreation: prepareCreation,
    role: role,
    material: material,
    activePresentations: activePresentations,
    slots: slots,
    slotBuilders: slotBuilders,
    host: host,
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
    authoring: authoring,
    catalog: catalog,
    resource: resource,
    edit: edit,
    openResource: openResource,
    prepareCreation: prepareCreation,
    role: role,
    material: material,
    activePresentations: activePresentations,
    slots: slots,
    slotBuilders: {...slotBuilders, ...values},
    host: host,
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
    authoring: authoring,
    catalog: catalog,
    resource: resource,
    edit: edit,
    openResource: openResource,
    prepareCreation: prepareCreation,
    role: role,
    material: material,
    activePresentations: {...activePresentations, presentation},
    slots: slots,
    slotBuilders: slotBuilders,
    host: host,
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
        authoring: authoring,
        catalog: catalog,
        resource: resource,
        edit: edit,
        openResource: openResource,
        prepareCreation: prepareCreation,
        role: role,
        material: value,
        activePresentations: activePresentations,
        slots: slots,
        slotBuilders: slotBuilders,
        host: host,
      );
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
