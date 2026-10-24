part of "../portable_presentation_renderer.dart";

final _configuredValueBindingId = skir.ExpressionBindingId(
  value: "configured_value",
);

typedef PortableSlotBuilder = Widget Function(PortablePresentationScope scope);

/// Immutable lexical rendering context. Copies borrow the host, query observer
/// and operation results while carrying bindings, authored field claims and
/// recursion guards into descendants. Copying a scope creates no disposal duty.
///
/// Read only and enabled restrictions accumulate through the helper methods.
/// Projected writers preserve edits through aliases and named payload views;
/// an expression value alone does not establish an editable source location.
@Freezed(map: FreezedMapOptions.none, when: FreezedWhenOptions.none)
abstract class PortablePresentationScope with _$PortablePresentationScope {
  factory PortablePresentationScope({
    required Map<skir.ExpressionBindingId, PortableExpressionBinding> bindings,
    required skir.EvaluationBudget budget,
    required PortableOperationResults operations,
    List<PortableAppearanceLayer> appearanceLayers = const [],
    Map<skir.ExpressionBindingId, AuthoredBindingAddress> authoredAliases =
        const {},
    AuthoredPresentationIndex? authoredIndex,
    AuthoredPresentationIndex? independentAuthoredIndex,
    List<PortableAuthoredPart> authoredParts = const [],
    PortableInspectorFrame? inspectorFrame,
    Set<ActiveInspectorLayout> activeInspectorLayouts = const {},
    Set<ActivePartPresentation> activeParts = const {},
    bool readOnly = false,
    bool enabled = true,
    Stream<skir.RealmPresentationSearchUpdate> Function(
      skir.RealmPresentationSearchRequest request,
    )?
    watchSearch,
    ValueChanged<String>? reportStatus,
    CheckedEditorCatalog? catalog,
    PortableExpressionQueries? queries,
    ResourceDiagnosticReader resourceDiagnostics = noResourceDiagnostics,
    skir.ResourceId? resource,
    String? searchHistoryNamespace,
    ValueChanged<skir.ResourceId>? openResource,
    skir.PresentationRole? role,
    skir.PresentationMaterial? material,
    Set<skir.PresentationId> activePresentations = const {},
    Set<ActiveFieldPresentation> activeFieldPresentations = const {},
    skir.BoundControl? associatedControl,
    ResolvedFieldAssociation? fieldAssociation,
    Map<String, skir.PresentationNode> slots = const {},
    Map<String, PortableSlotBuilder> slotBuilders = const {},
    PortablePresentationHost? host,
    Map<skir.ExpressionBindingId, PortableBindingSetter> projectedWriters =
        const {},
  }) => PortablePresentationScope._value(
    bindings: Map.unmodifiable(bindings),
    budget: budget,
    operations: operations,
    appearanceLayers: List.unmodifiable(appearanceLayers),
    authoredAliases: Map.unmodifiable(authoredAliases),
    authoredIndex: authoredIndex,
    independentAuthoredIndex: independentAuthoredIndex,
    authoredParts: List.unmodifiable(authoredParts),
    inspectorFrame: inspectorFrame,
    activeInspectorLayouts: Set.unmodifiable(activeInspectorLayouts),
    activeParts: Set.unmodifiable(activeParts),
    readOnly: readOnly,
    enabled: enabled,
    watchSearch: watchSearch,
    reportStatus: reportStatus,
    catalog: catalog,
    queries: queries,
    resourceDiagnostics: resourceDiagnostics,
    resource: resource,
    searchHistoryNamespace: searchHistoryNamespace,
    openResource: openResource,
    role: role,
    material: material,
    activePresentations: Set.unmodifiable(activePresentations),
    activeFieldPresentations: Set.unmodifiable(activeFieldPresentations),
    associatedControl: associatedControl,
    fieldAssociation: fieldAssociation,
    slots: Map.unmodifiable(slots),
    slotBuilders: Map.unmodifiable(slotBuilders),
    host: host,
    projectedWriters: Map.unmodifiable(projectedWriters),
  );

  const factory PortablePresentationScope._value({
    required Map<skir.ExpressionBindingId, PortableExpressionBinding> bindings,
    required skir.EvaluationBudget budget,
    required PortableOperationResults operations,
    required List<PortableAppearanceLayer> appearanceLayers,
    required Map<skir.ExpressionBindingId, AuthoredBindingAddress>
    authoredAliases,
    required AuthoredPresentationIndex? authoredIndex,
    required AuthoredPresentationIndex? independentAuthoredIndex,
    required List<PortableAuthoredPart> authoredParts,
    required PortableInspectorFrame? inspectorFrame,
    required Set<ActiveInspectorLayout> activeInspectorLayouts,
    required Set<ActivePartPresentation> activeParts,
    required bool readOnly,
    required bool enabled,
    required Stream<skir.RealmPresentationSearchUpdate> Function(
      skir.RealmPresentationSearchRequest request,
    )?
    watchSearch,
    required ValueChanged<String>? reportStatus,
    required CheckedEditorCatalog? catalog,
    required PortableExpressionQueries? queries,
    required ResourceDiagnosticReader resourceDiagnostics,
    required skir.ResourceId? resource,
    required String? searchHistoryNamespace,
    required ValueChanged<skir.ResourceId>? openResource,
    required skir.PresentationRole? role,
    required skir.PresentationMaterial? material,
    required Set<skir.PresentationId> activePresentations,
    required Set<ActiveFieldPresentation> activeFieldPresentations,
    required skir.BoundControl? associatedControl,
    required ResolvedFieldAssociation? fieldAssociation,
    required Map<String, skir.PresentationNode> slots,
    required Map<String, PortableSlotBuilder> slotBuilders,
    required PortablePresentationHost? host,
    required Map<skir.ExpressionBindingId, PortableBindingSetter>
    projectedWriters,
  }) = _PortablePresentationScope;
  const PortablePresentationScope._();

  PortablePresentationScope withAuthoredLayout(
    skir.PresentationNode layout, {
    bool startInspector = true,
  }) {
    final aliases = {
      for (final entry in bindings.entries)
        entry.key: entry.value.location == null
            ? authoredAliases[entry.key] ??
                  AuthoredBindingAddress.binding(entry.key, entry.value)
            : AuthoredBindingAddress.binding(entry.key, entry.value),
    };
    final additional = [
      if (layout == material?.layout &&
          material?.resultAppearance?.leading != null)
        material!.resultAppearance!.leading!,
    ];
    final sources = {
      for (final source
          in material?.dependencies.collections ??
              const <skir.PresentationCollectionDefinition>[])
        source.sourceId: source,
    };
    final parts = <PortableAuthoredPart>[];
    final independent = AuthoredPresentationIndex.build(
      layout,
      aliases,
      additionalLayouts: additional,
      sources: sources,
      onPart: (node, part, lexicalAliases) {
        parts.add(
          PortableAuthoredPart(
            nodeId: node.nodeId,
            part: part,
            owner: lexicalAliases[_configuredValueBindingId],
          ),
        );
        return false;
      },
    );
    final indexed = copyWith(
      authoredAliases: Map.unmodifiable(aliases),
      independentAuthoredIndex: independent,
      authoredParts: parts,
      authoredIndex: AuthoredPresentationIndex.build(
        layout,
        aliases,
        additionalLayouts: additional,
        sources: sources,
      ),
    );
    return startInspector ? indexed.startInspectorLayout() : indexed;
  }

  PortablePresentationScope withAppearance(skir.InputAppearance appearance) =>
      copyWith(
        appearanceLayers: List.unmodifiable([
          ...appearanceLayers,
          PortableAppearanceLayer(
            appearance: appearance,
            bindings: bindings,
            budget: budget,
          ),
        ]),
      );

  List<PortableDiagnosticObservation> get diagnosticObservations => [
    for (final entry in bindings.entries)
      PortableDiagnosticObservation(
        target: entry.value.location == null
            ? PortableDiagnosticTarget.binding(
                skir.BindingRef(bindingId: entry.key, path: editorRootPath),
              )
            : PortableDiagnosticTarget.value(entry.value.location!),
        value: entry.value.value,
      ),
  ];

  PortableInvocationContext get invocation => PortableInvocationContext(
    bindings: bindings,
    catalogGeneration:
        (queries?.catalog ?? catalog ?? host?.document.catalog)
            ?.snapshot
            .generation ??
        (throw StateError("Portable invocation has no checked catalog")),
    queries: queries,
    resourceDiagnostics: resourceDiagnostics,
  );

  PortableExpressionResult evaluate(skir.ExpressionNode expression) {
    final checked = queries?.catalog ?? catalog ?? host?.document.catalog;
    if (checked == null) {
      return PortableExpressionEvaluator.located(
        bindings,
        budget: budget,
      ).evaluate(expression);
    }
    return checked.evaluateExpression(
      expression,
      bindings: bindings,
      budget: budget,
      queries: queries,
    );
  }

  /// Resolves declared expression typing without inspecting its runtime value.
  PortablePresentationBindingSchema? expressionSchema(
    skir.ExpressionNode expression,
  ) {
    if (expression case skir.ExpressionNode_inputWrapper(:final value)
        when value.path.segments.isEmpty) {
      final declared = bindings[value.binding]?.schema;
      if (declared != null) return declared;
    }
    final checked = queries?.catalog ?? catalog ?? host?.document.catalog;
    if (checked == null) return null;
    return switch (checked.expressionPrograms.program(
      expression,
      lexicalTypes: bindings.lexicalSchemas,
    )) {
      CheckedExpressionReady(:final program) =>
        switch (program.result.declaredUse()) {
          final use? => CompletePortablePresentationBinding(use),
          _ => null,
        },
      _ => null,
    };
  }

  skir.DataValue? read(skir.BindingRef reference) {
    return host?.read(reference, context: invocation);
  }

  skir.ValueLocation? location(skir.BindingRef reference) {
    return host?.location(reference, context: invocation);
  }

  /// Translates a lexical alias back to the nearest document binding that owns
  /// its location. Reused binding IDs are global only when locations still match.
  skir.BindingRef? sourceReference(skir.BindingRef reference) {
    final document = host?.document;
    if (document == null) return null;
    final authored = authoredAliases.resolve(reference);
    if (authored?.root case AuthoredLocalRoot(:final binding)
        when document.bindings.containsKey(binding) &&
            authored!.path.every((step) => step is ExactAuthoredPathStep)) {
      return skir.BindingRef(
        bindingId: binding,
        path: skir.ValuePath(
          segments: [
            for (final step in authored.path)
              (step as ExactAuthoredPathStep).segment,
          ],
        ),
      );
    }
    final local = bindings[reference.bindingId]?.location;
    final documentBinding = document.bindings[reference.bindingId];
    // A selected presentation can reuse a document binding ID for a nested
    // value. Only an unchanged source location makes the lexical path global.
    if (documentBinding != null && local == documentBinding.location) {
      return reference;
    }
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

  Object? nativeSourceIdentity(skir.BindingRef reference) {
    final current = host;
    if (current is BoundPresentationHost) {
      final source = sourceReference(reference) ?? reference;
      return current.bindingOwner(source.bindingId)?.portableSourceLifetime ??
          current;
    }
    return current;
  }

  PortableDiagnosticTarget diagnosticTarget(skir.BindingRef reference) {
    final located = location(reference);
    if (located != null) return PortableDiagnosticTarget.value(located);
    return PortableDiagnosticTarget.binding(
      sourceReference(reference) ?? reference,
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
    if (!enabled || readOnly || host == null) return;
    final address = diagnosticTarget(reference);
    unawaited(
      operations.run(
        key: PortableOperationKey.write(address),
        input: PortableDiagnosticObservation(
          target: address,
          value: read(reference),
        ),
        operation: () => apply(reference, value),
      ),
    );
  }

  Future<PortablePresentationWriteResult> apply(
    skir.BindingRef reference,
    skir.DataValue value, {
    Iterable<PortableExpressionRead> reads = const [],
  }) async {
    final target = host;
    if (!enabled || readOnly || target == null) {
      return PortablePresentationWriteResult.rejected([
        PortablePresentationDiagnostic(
          code: "read_only",
          message: "This presentation is read only",
          severity: skir.DiagnosticSeverity.error,
          targets: [diagnosticTarget(reference)],
        ),
      ]);
    }
    final writer = projectedWriters[reference.bindingId];
    return writer == null
        ? target.write(
            reference,
            value,
            context: invocation.withExpressionReads(reads),
          )
        : await writer(reference, value, reads: reads);
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

  skir.EditorAction sourceAction(skir.EditorAction action) {
    if (action is! skir.EditorAction_localWrapper) return action;
    final local = action.value;
    return skir.EditorAction.wrapLocal(switch (local) {
      skir.LocalEditorAction_setValueWrapper(:final value) =>
        skir.LocalEditorAction.wrapSetValue(
          (value.toMutable()
                ..target = sourceReference(value.target) ?? value.target)
              .toFrozen(),
        ),
      skir.LocalEditorAction_insertListItemWrapper(:final value) =>
        skir.LocalEditorAction.wrapInsertListItem(
          (value.toMutable()
                ..target = sourceReference(value.target) ?? value.target)
              .toFrozen(),
        ),
      skir.LocalEditorAction_appendListItemWrapper(:final value) =>
        skir.LocalEditorAction.wrapAppendListItem(
          (value.toMutable()
                ..target = sourceReference(value.target) ?? value.target)
              .toFrozen(),
        ),
      skir.LocalEditorAction_removeListItemWrapper(:final value) =>
        skir.LocalEditorAction.wrapRemoveListItem(
          (value.toMutable()
                ..target = sourceReference(value.target) ?? value.target)
              .toFrozen(),
        ),
      skir.LocalEditorAction_duplicateListItemWrapper(:final value) =>
        skir.LocalEditorAction.wrapDuplicateListItem(
          (value.toMutable()
                ..target = sourceReference(value.target) ?? value.target)
              .toFrozen(),
        ),
      skir.LocalEditorAction_moveListItemWrapper(:final value) =>
        skir.LocalEditorAction.wrapMoveListItem(
          (value.toMutable()
                ..target = sourceReference(value.target) ?? value.target)
              .toFrozen(),
        ),
      skir.LocalEditorAction_insertMapRowWrapper(:final value) =>
        skir.LocalEditorAction.wrapInsertMapRow(
          (value.toMutable()
                ..target = sourceReference(value.target) ?? value.target)
              .toFrozen(),
        ),
      skir.LocalEditorAction_updateMapRowWrapper(:final value) =>
        skir.LocalEditorAction.wrapUpdateMapRow(
          (value.toMutable()
                ..target = sourceReference(value.target) ?? value.target)
              .toFrozen(),
        ),
      skir.LocalEditorAction_removeMapRowWrapper(:final value) =>
        skir.LocalEditorAction.wrapRemoveMapRow(
          (value.toMutable()
                ..target = sourceReference(value.target) ?? value.target)
              .toFrozen(),
        ),
      skir.LocalEditorAction_chooseFormWrapper(:final value) =>
        skir.LocalEditorAction.wrapChooseForm(
          (value.toMutable()
                ..target = sourceReference(value.target) ?? value.target)
              .toFrozen(),
        ),
      _ => local,
    });
  }

  bool get canExecuteAction => enabled && !readOnly && host != null;

  bool canExecuteActionFor(skir.EditorAction action) =>
      action is skir.EditorAction_navigateWrapper
      ? enabled && host?.capabilities.resourceAction != null
      : canExecuteAction;

  PortablePresentationScope withReadOnly(bool value) =>
      copyWith(readOnly: readOnly || value);

  PortablePresentationScope withEnabled(bool value) =>
      copyWith(enabled: enabled && value);

  // Collection replacements allocate owned values because generated copyWith
  // enters the private Freezed value constructor directly.
  PortablePresentationScope withNamedPayload(PortableNamedPayload payload) {
    final configured = skir.ExpressionBindingId(value: "configured_value");
    FutureOr<PortablePresentationWriteResult> writeConfigured(
      skir.BindingRef reference,
      skir.DataValue value, {
      Iterable<PortableExpressionRead> reads = const [],
    }) {
      var replacement = value;
      if (reference.path.segments.isEmpty &&
          value is skir.DataValue_namedWrapper) {
        if (value.value.actualType != payload.actualType) {
          return PortablePresentationWriteResult.rejected([
            PortablePresentationDiagnostic(
              code: "invalid_type",
              message: "The named payload cannot change its type",
              severity: skir.DiagnosticSeverity.error,
              targets: [diagnosticTarget(reference)],
            ),
          ]);
        }
        replacement = value.value.payload;
      }
      final replaced = reference.path.segments.isEmpty
          ? PortablePathValue(replacement)
          : payload.value.replaceAt(reference.path, replacement);
      if (replaced case PortablePathValue(:final value)) {
        return payload.replace(value, reads: reads);
      }
      return PortablePresentationWriteResult.rejected([
        PortablePresentationDiagnostic(
          code: "invalid_path",
          message: "The named value path is unavailable",
          severity: skir.DiagnosticSeverity.error,
          targets: [diagnosticTarget(reference)],
        ),
      ]);
    }

    return copyWith(
      bindings: {
        ...bindings.withSubjectAt(payload.location),
        configured: PortableExpressionBinding(
          value: skir.DataValue.createNamed(
            actualType: payload.actualType,
            payload: payload.value,
          ),
          location: payload.location,
          schema: CompletePortablePresentationBinding(
            skir.TypeUse.wrapNamed(payload.actualType),
          ),
        ),
      },
      projectedWriters: {...projectedWriters, configured: writeConfigured},
      authoredAliases: {
        ...authoredAliases,
        configured:
            authoredAliases.resolve(payload.reference) ??
            AuthoredBindingAddress.binding(
              configured,
              PortableExpressionBinding(
                value: payload.value,
                location: payload.location,
              ),
            ),
      },
    );
  }

  PortablePresentationScope? withConfiguredValue(skir.BindingRef reference) =>
      withBinding(reference, _configuredValueBindingId);

  /// Rebinds an existing value and its schema, location and projected writer.
  /// An unavailable source returns null rather than inventing an editable value.
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
    if (originalWriter != null || source.location == null) {
      nextWriters[id] =
          (
            nestedReference,
            replacement, {
            reads = const <PortableExpressionRead>[],
          }) {
            final original = skir.BindingRef(
              bindingId: reference.bindingId,
              path: skir.ValuePath(
                segments: [
                  ...reference.path.segments,
                  ...nestedReference.path.segments,
                ],
              ),
            );
            return originalWriter == null
                ? apply(original, replacement, reads: reads)
                : originalWriter(original, replacement, reads: reads);
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
          schema: reference.path.segments.isEmpty
              ? source.schema
              : expressionSchema(
                      skir.ExpressionNode.createInput(
                        binding: reference.bindingId,
                        path: reference.path,
                      ),
                    ) ??
                    switch (expectedType(reference)) {
                      final use? => CompletePortablePresentationBinding(use),
                      null => null,
                    },
        ),
      },
      projectedWriters: nextWriters,
      authoredAliases: {
        ...authoredAliases,
        id:
            authoredAliases.resolve(reference) ??
            AuthoredBindingAddress.binding(
              id,
              PortableExpressionBinding(value: value, location: location),
            ),
      },
    );
  }

  PortablePresentationScope withValues(
    Map<skir.ExpressionBindingId, skir.DataValue> values, {
    Map<skir.ExpressionBindingId, PortablePresentationBindingSchema> schemas =
        const {},
    String? authoredOrigin,
  }) {
    return copyWith(
      bindings: Map.unmodifiable({
        ...bindings,
        for (final entry in values.entries)
          entry.key: PortableExpressionBinding(
            value: entry.value,
            schema: schemas[entry.key] ?? bindings[entry.key]?.schema,
          ),
      }),
      authoredAliases: Map.unmodifiable({
        ...authoredAliases,
        for (final entry in values.entries)
          entry.key: AuthoredBindingAddress(
            root: AuthoredBindingRoot.local(entry.key, origin: authoredOrigin),
            path: const [],
          ),
      }),
    );
  }

  PortablePresentationScope withSlotBuilders(
    Map<String, PortableSlotBuilder> values,
  ) => copyWith(slotBuilders: {...slotBuilders, ...values});

  PortablePresentationScope withActivePresentation(
    skir.PresentationId presentation,
  ) => copyWith(activePresentations: {...activePresentations, presentation});

  PortablePresentationScope withMaterial(skir.PresentationMaterial value) =>
      withMaterialContext(value).withAuthoredLayout(value.layout);

  PortablePresentationScope withMaterialContext(
    skir.PresentationMaterial value,
  ) => copyWith(
    material: value,
    bindings: bindings.withContextImports(
      catalog: queries?.catalog ?? catalog!,
      imports: value.dependencies.contextInputs,
    ),
  );

  /// Starts a resource presentation with its own subject and authored bindings.
  /// The caller's observation and declared context inputs remain shared.
  PortablePresentationScope forResourcePresentation(
    PortableResourceProjection projected,
    SelectedEditorPresentation selected,
  ) {
    final location = skir.ValueLocation(
      resource: projected.resource,
      path: editorRootPath,
    );
    return PortablePresentationScope(
      bindings: {
        for (final input in selected.material.dependencies.contextInputs)
          input.bindingId: ?bindings[input.bindingId],
        presentationSubjectIdentifierBindingId: projected.resource
            .toExpressionBinding(),
        _configuredValueBindingId: PortableExpressionBinding(
          value: projected.value,
          schema: switch (projected.configuration) {
            skir.TypeSelection_completeWrapper(:final value) =>
              CompletePortablePresentationBinding(
                skir.TypeUse.wrapNamed(value),
              ),
            skir.TypeSelection_pendingWrapper() =>
              PartialPortablePresentationBinding(projected.configuration),
            _ => null,
          },
          location: location,
        ),
      },
      budget: budget,
      appearanceLayers: appearanceLayers,
      readOnly: readOnly,
      enabled: enabled,
      operations: operations,
      watchSearch: watchSearch,
      reportStatus: reportStatus,
      catalog: catalog,
      queries: queries,
      resourceDiagnostics: resourceDiagnostics,
      resource: projected.resource,
      searchHistoryNamespace: searchHistoryNamespace,
      role: selected.resolvedRole,
      activePresentations: {selected.material.provider},
      openResource: openResource,
      host: host,
    ).withMaterial(selected.material);
  }
}

extension _PortableBackendSourceLifetime on Listenable {
  Object get portableSourceLifetime => switch (this) {
    ValueEditing(:final workspace, :final groupId) => (workspace, groupId),
    MultiEditOwner(:final owners) => EqualUnmodifiableListView([
      for (final owner in owners) owner.portableSourceLifetime,
    ]),
    _ => this,
  };
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
      presentationSubjectIdentifierBindingId: subject.resource
          .toExpressionBinding(),
  };
}
