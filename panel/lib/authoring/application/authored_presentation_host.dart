import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";

part "authored_presentation_actions.dart";
part "authored_presentation_collections.dart";
part "authored_presentation_links.dart";
part "authored_presentation_resources.dart";

/// Connects portable presentation behavior to one authored resource and its shared edit binding.
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
    this.available = true,
    this.readOnly = false,
    this.prepareValue,
    this.edit,
    this.issues,
  });

  final skir.ResourceId resource;
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
    final record = observation.resource(resource);
    if (record == null) {
      throw StateError("The authored resource is absent");
    }
    final checked = observation.catalog;
    if (checked.snapshot.generation != observation.generation) {
      throw StateError("The authoring catalog is unavailable");
    }
    final payload = skir.DataValue.createRecord(fields: record.fields);
    final value = switch (record.configuration) {
      skir.TypeSelection_completeWrapper(:final value) =>
        skir.DataValue.createNamed(actualType: value, payload: payload),
      _ => payload,
    };
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
            value: value,
            editable: true,
            location: skir.ValueLocation(
              resource: resource,
              path: skir.ValuePath(segments: const []),
            ),
          ),
      },
      budget: budget,
      diagnosticFallback: PortableDiagnosticFallback.resource,
      diagnostics: diagnosticsFor(resource),
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
    final currentRecord = authored.resource(target.resource);
    if (!context.isCurrent(
      reference,
      authored.generation,
      currentRecord == null
          ? null
          : _recordValue(currentRecord).editorValueAt(target.path),
    )) {
      return _reject(
        "The presentation value changed before this write",
        target: target,
      );
    }
    final result = await binding.prepare(
      label: "Edit value",
      from: _observation(context),
      apply: (operation) async {
        operation.observeExpressionReads(context.expressionReads);
        if (prepareValue case final prepare?) {
          await operation.setWithInitialization(target, value, prepare);
        } else {
          operation.set(target, value);
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
