import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";

part "authored_presentation_actions.dart";
part "authored_presentation_collections.dart";
part "authored_presentation_links.dart";
part "authored_presentation_resources.dart";

/// Connects portable presentation behavior to an authored resource and its shared edit binding.
///
/// Several resources of one kind edit as one through [editedWith]: the
/// presentation shows what they agree on, every part they disagree on is
/// unfilled, and each change stages its intents for every one of them in one
/// edit of the binding's group, so it is saved all or nothing. A change that
/// needs a prepared value prepares each distinct request once and applies the
/// result to each resource. One resource alone is the case with no
/// [editedWith].
///
/// Display and collection projections read the current working document. Invocation
/// contexts retain the observation that produced an action, so expression reads can
/// become original expectations when the action stages a write. Preparation rechecks
/// availability after suspension and reports rejected writes as portable diagnostics.
///
/// The host owns view metadata and its disposed flag, while [RealmEditingBinding]
/// owns access to the shared edit group. Disposing this host prevents new presentation
/// work without saving, discarding, or closing that group.
final class AuthoredPresentationHost extends ChangeNotifier
    implements
        PortablePresentationHost,
        PortableCollectionMutationHost,
        PortableCollectionProjectionHost,
        PortableLinkHost,
        PortableResourcesHost {
  AuthoredPresentationHost({
    required this.resource,
    required this._source,
    required this.material,
    required this.role,
    required this.budget,
    required this.capabilities,
    this.editedWith = const [],
    this.available = true,
    this.readOnly = false,
    this.prepareValue,
    this.edit,
    this.issues,
  });

  /// The resource the presentation's locations address.
  final skir.ResourceId resource;

  /// The other resources of the same kind edited together with [resource].
  final List<skir.ResourceId> editedWith;

  /// Every resource this host edits, [resource] first.
  List<skir.ResourceId> get resources => [resource, ...editedWith];
  AuthoringDocument _source;
  AuthoringDocument get authored => edit?.document ?? _source;
  final skir.PresentationMaterial material;
  final skir.PresentationRole role;
  final skir.EvaluationBudget budget;
  @override
  PortablePresentationCapabilities capabilities;
  bool available;
  @override
  bool readOnly;
  Future<skir.PreparedValue> Function(skir.ValuePreparationRequest request)?
  prepareValue;
  final RealmEditingBinding? edit;
  ResourceIssues? issues;
  var _disposed = false;

  /// Updates view metadata without replacing an active operation's host.
  void update({
    required AuthoringDocument source,
    required PortablePresentationCapabilities capabilities,
    required bool available,
    required bool readOnly,
    ResourceIssues? issues,
    Future<skir.PreparedValue> Function(skir.ValuePreparationRequest)?
    prepareValue,
  }) {
    _source = source;
    this.issues = issues;
    this.capabilities = capabilities;
    this.available = available;
    this.readOnly = readOnly;
    this.prepareValue = prepareValue;
  }

  @override
  EditControl? commitControl(
    skir.BindingRef reference, {
    required PortableInvocationContext context,
  }) {
    if (!enabled ||
        readOnly ||
        context.catalogGeneration != authored.generation ||
        edit == null ||
        location(reference, context: context) == null) {
      return null;
    }
    return edit!.control;
  }

  @override
  bool get enabled => !_disposed && available;

  @override
  PortablePresentationDocument get document {
    final observation = authored;
    final records = [
      for (final id in resources)
        observation.resource(id) ??
            (throw StateError("The authored resource is absent")),
    ];
    final record = records.first;
    final checked = observation.catalog;
    if (checked.snapshot.generation != observation.generation) {
      throw StateError("The authoring catalog is unavailable");
    }
    final values = [for (final each in records) _recordValue(each)];
    final schema = switch (record.configuration) {
      skir.TypeSelection_completeWrapper(:final value) =>
        CompletePortablePresentationBinding(skir.TypeUse.wrapNamed(value)),
      skir.TypeSelection_pendingWrapper() => PartialPortablePresentationBinding(
        record.configuration,
      ),
      skir.TypeSelection_unknown() => null,
    };
    final observationIssues =
        issues ?? ResourceIssues.evaluate(document: observation);
    List<PortablePresentationDiagnostic> diagnosticsFor(skir.ResourceId id) =>
        observationIssues
            .currentFor(id)
            .map((issue) => issue.diagnostic)
            .toList();
    return PortablePresentationDocument(
      catalog: checked,
      queries: PortableExpressionQueries(
        catalog: checked,
        authored: observation,
      ),
      resourceDiagnostics: diagnosticsFor,
      root: material.layout,
      bindings: {
        presentationSubjectIdentifierBindingId: PortablePresentationBinding(
          schema: CompletePortablePresentationBinding(
            skir.TypeUse.wrapNamed(skir.resourceIdType),
          ),
          value: resource.toExpressionValue(),
        ),
        presentationSubjectAppearanceBindingId: PortablePresentationBinding(
          schema: CompletePortablePresentationBinding(
            skir.TypeUse.wrapNamed(canonicalReadModels.resourceAppearanceUse),
          ),
          value: checked.appearanceOf(record).toExpressionValue(),
        ),
        if (schema != null)
          configuredValueBindingId: PortablePresentationBinding(
            schema: schema,
            value: values.agreement,
            editable: true,
            location: skir.ValueLocation(
              resource: resource,
              path: skir.ValuePath(segments: const []),
            ),
            itemValues: editedWith.isEmpty ? const [] : values,
          ),
      },
      budget: budget,
      diagnosticFallback: PortableDiagnosticFallback.resource,
      diagnostics: [
        for (final id in resources)
          for (final diagnostic in diagnosticsFor(id))
            if (id == resource) diagnostic else _retargeted(diagnostic, id),
      ],
      role: role,
      material: material,
      activePresentations: {material.provider},
    );
  }

  @override
  skir.DataValue? read(
    skir.BindingRef reference, {
    required PortableInvocationContext context,
  }) {
    return context.read(reference, authored.generation);
  }

  @override
  skir.ValueLocation? location(
    skir.BindingRef reference, {
    required PortableInvocationContext context,
  }) {
    return context.location(reference, authored.generation);
  }

  @override
  skir.TypeUse? expectedType(
    skir.BindingRef reference, {
    required PortableInvocationContext context,
  }) {
    final target = location(reference, context: context);
    final observation = context.queries?.authored ?? authored;
    final checked = context.queries?.catalog ?? authored.catalog;
    final record = target == null
        ? null
        : observation.resource(target.resource);
    return record == null
        ? null
        : checked.valueTypeAt(
            record.configuration,
            target!.path,
            value: _recordValue(record),
          );
  }

  skir.DataValue _recordValue(skir.AuthoringRecord record) {
    final payload = skir.DataValue.createRecord(fields: record.fields);
    return switch (record.configuration) {
      skir.TypeSelection_completeWrapper(:final value) =>
        skir.DataValue.createNamed(actualType: value, payload: payload),
      _ => payload,
    };
  }

  @override
  Future<PortablePresentationWriteResult> write(
    skir.BindingRef reference,
    skir.DataValue value, {
    required PortableInvocationContext context,
  }) async {
    if (!enabled || readOnly) {
      return _reject("This presentation is read only");
    }
    final target = location(reference, context: context);
    if (target == null) {
      return _reject("The presentation binding is unavailable", target: target);
    }
    final binding = edit;
    if (binding == null) {
      return _reject("This presentation is read only", target: target);
    }
    if (!context.isCurrent(reference, authored.generation, _current(target))) {
      return _reject(
        "The presentation value changed before this write",
        target: target,
      );
    }
    final result = await binding.prepare(
      label: "Edit value",
      from: _observation(context),
      apply: (operation) async {
        operation.observeExpressionReads(_eachRead(context.expressionReads));
        final prepare = _preparedOnce(prepareValue);
        for (final at in _each(target)) {
          if (prepare != null) {
            await operation.setWithInitialization(at, value, prepare);
          } else {
            operation.set(at, value);
          }
        }
        if (_disposed || !enabled || readOnly) {
          throw StateError("The presentation closed during preparation");
        }
      },
    );
    if (result case EditStageRejected(:final message)) {
      return _reject(message, target: target);
    }
    return const PortablePresentationWriteApplied();
  }

  @override
  Future<PortablePresentationWriteResult> execute(
    skir.EditorAction editorAction, {
    required PortableInvocationContext context,
  }) => _execute(editorAction, context: context);

  @override
  Future<PortablePresentationWriteResult> addCollectionItem(
    skir.BindingRef reference, {
    required PortableInvocationContext context,
  }) => _addCollectionItem(reference, context: context);

  @override
  PortableCollectionProjection projectCollection(
    String sourceId, {
    required skir.PresentationMaterial material,
    required PortableInvocationContext context,
  }) => _projectCollection(sourceId, material: material, context: context);

  @override
  PortableResourceProjection? projectResource(
    skir.ResourceId resource, {
    required PortableInvocationContext context,
  }) => _projectResource(resource, context: context);

  @override
  PortableLinkPlanResult planLink(
    skir.ValueLocation source, {
    required PortableInvocationContext context,
  }) => _planLink(source, context: context);

  @override
  bool get canPrepareCounterpart => prepareValue != null;

  @override
  Future<PortablePresentationWriteResult> connectLink({
    required PortableLinkPlan plan,
    required PortableLinkTargetChoice target,
    required PortableLinkCounterpartRequest counterpart,
    required PortableInvocationContext context,
  }) => _connectLink(
    plan: plan,
    target: target,
    counterpart: counterpart,
    context: context,
  );

  @override
  PortablePresentationWriteResult disconnectLink(
    skir.LinkOccurrence occurrence, {
    required PortableInvocationContext context,
  }) => _disconnectLink(occurrence, context: context);

  /// Members of a resources binding: the link targets of the bound field, in
  /// link order. Links come from the document's link projections at or below
  /// the bound location, ordered by their item in the field's value.
  @override
  PortableResourcesProjection projectResources(
    skir.BindingRef source, {
    required PortableInvocationContext context,
  }) => _projectResources(source, context: context);

  @override
  PortablePresentationWriteResult moveGraphNodes(
    List<PortableGraphPositionChange> changes, {
    required PortableInvocationContext context,
  }) => _moveGraphNodes(changes, context: context);

  @override
  PortablePresentationWriteResult resizeGraphNodes(
    List<PortableGraphSizeChange> changes, {
    required PortableInvocationContext context,
  }) => _resizeGraphNodes(changes, context: context);

  @override
  PortablePresentationWriteResult moveTimelineElements(
    List<PortableTimelineChange> changes, {
    required PortableInvocationContext context,
  }) => _moveTimelineElements(changes, context: context);

  @override
  PortablePresentationWriteResult removeMember(
    PortableResourceMember member, {
    required bool delete,
    required PortableInvocationContext context,
  }) => _removeMember(member, delete: delete, context: context);

  @override
  Future<PortablePresentationWriteResult> addMapRow(
    skir.BindingRef reference, {
    required PortableInvocationContext context,
  }) => _addMapRow(reference, context: context);

  /// Where a change at [target] applies: the same path in every resource
  /// this host edits when [target] is in [resource], otherwise [target]
  /// alone.
  Iterable<skir.ValueLocation> _each(skir.ValueLocation target) =>
      target.resource != resource
      ? [target]
      : [
          for (final id in resources)
            skir.ValueLocation(resource: id, path: target.path),
        ];

  /// [reads] expanded to every resource this host edits, so a change made
  /// from what they agree on expects each of them unchanged.
  List<skir.ValueLocation> _eachRead(Iterable<skir.ValueLocation> reads) => [
    for (final read in reads) ..._each(read),
  ];

  /// What the resources this host edits agree on at [target], as the
  /// presentation shows it; null when one of them is absent.
  skir.DataValue? _current(skir.ValueLocation target) {
    final values = <skir.DataValue>[];
    for (final at in _each(target)) {
      final record = authored.resource(at.resource);
      if (record == null) return null;
      values.add(_recordValue(record));
    }
    return values.agreement.editorValueAt(target.path);
  }

  /// [prepare] answering each distinct request once, so a change across
  /// several resources prepares each value once and applies it to each.
  Future<skir.PreparedValue> Function(skir.ValuePreparationRequest)?
  _preparedOnce(
    Future<skir.PreparedValue> Function(skir.ValuePreparationRequest)? prepare,
  ) {
    if (prepare == null) return null;
    final prepared =
        <skir.ValuePreparationRequest, Future<skir.PreparedValue>>{};
    return (request) => prepared.putIfAbsent(request, () => prepare(request));
  }

  /// [diagnostic] of [other], one of [editedWith], aimed at the same path in
  /// [resource], where the shared presentation shows it.
  PortablePresentationDiagnostic _retargeted(
    PortablePresentationDiagnostic diagnostic,
    skir.ResourceId other,
  ) => diagnostic.copyWith(
    targets: [
      for (final target in diagnostic.targets)
        switch (target) {
          PortableValueDiagnosticTarget(:final location)
              when location.resource == other =>
            PortableDiagnosticTarget.value(
              skir.ValueLocation(resource: resource, path: location.path),
            ),
          _ => target,
        },
    ],
  );

  PortablePresentationWriteResult _stage(
    String label,
    void Function(AuthoringEdit operation) apply, {
    bool independent = false,
    skir.ValueLocation? target,
    AuthoringDocument? from,
  }) {
    final binding = edit;
    if (!enabled || readOnly || binding == null) {
      return _reject("This presentation is read only", target: target);
    }
    final result = independent
        ? binding.workspace.edit(
            label: label,
            apply: apply,
            from: from ?? authored,
          )
        : binding.edit(label: label, apply: apply, from: from ?? authored);
    return switch (result) {
      EditStageRejected(:final message) => _reject(message, target: target),
      _ => const PortablePresentationWriteApplied(),
    };
  }

  PortablePresentationWriteResult _reject(
    String message, {
    skir.ValueLocation? target,
  }) => PortablePresentationWriteResult.rejected([
    PortablePresentationDiagnostic(
      code: "edit_rejected",
      message: message,
      severity: skir.DiagnosticSeverity.error,
      targets: target == null
          ? const []
          : [PortableDiagnosticTarget.value(target)],
    ),
  ]);

  @override
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    super.dispose();
  }
}

final class _AuthoredActionValue {
  const _AuthoredActionValue(this.value, this.reads);

  final skir.DataValue value;
  final List<skir.ValueLocation> reads;
}
