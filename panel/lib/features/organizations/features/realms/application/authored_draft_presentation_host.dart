import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";

final class AuthoredDraftAuthoringDocument
    implements PortableAuthoringDocument {
  AuthoredDraftAuthoringDocument(this.draft);

  final AuthoredDraft draft;

  @override
  skir.CatalogGeneration get generation => draft.generation;

  @override
  Map<skir.ResourceId, skir.AuthoringRecord> get resources => draft.resources;

  @override
  List<skir.LinkProjection> get links => draft.links;

  @override
  List<skir.InitializationDiagnostic> get initializationFindings =>
      draft.initializationFindings;

  @override
  int get operationCount => draft.intents.length;

  @override
  skir.AuthoringRecord? resource(skir.ResourceId id) => draft.resource(id);

  @override
  PortablePathResult<skir.DataValue> read(skir.ValueLocation location) =>
      draft.read(location);

  @override
  PortablePathResult<skir.AuthoringRecord> set(
    skir.ValueLocation location,
    skir.DataValue value,
  ) => draft.set(location, value);

  @override
  PortablePathResult<skir.AuthoringRecord> insert(
    skir.ValueLocation location,
    skir.ItemId? after,
    skir.ListItem item,
  ) => draft.insert(location, after, item);

  @override
  PortablePathResult<skir.AuthoringRecord> insertPrepared(
    skir.ValueLocation location,
    skir.ItemId? after,
    skir.ItemId item,
    skir.InitializationRequest request,
    skir.PreparedCreation prepared,
  ) => draft.insertPrepared(location, after, item, request, prepared);

  @override
  skir.DataValue defaultValue(skir.TypeUse? type) => draft.defaultValue(type);

  @override
  PortablePathResult<skir.AuthoringRecord> remove(
    skir.ValueLocation location,
    skir.ItemId item,
  ) => draft.remove(location, item);

  @override
  PortablePathResult<skir.AuthoringRecord> move(
    skir.ValueLocation location,
    skir.ItemId item,
    skir.ItemId? after,
  ) => draft.move(location, item, after);

  @override
  PortablePathResult<skir.AuthoringRecord> replaceMap(
    skir.ValueLocation location,
    Iterable<skir.MapRow> rows,
  ) => draft.replaceMap(location, rows);

  @override
  PortablePathResult<skir.AuthoringRecord> applyPreparedRecord(
    skir.ValueLocation location,
    skir.InitializationRequest request,
    skir.PreparedCreation prepared,
  ) => draft.applyPreparedRecord(location, request, prepared);

  @override
  bool stageExpressionEdit(
    Iterable<PortableExpressionRead> reads,
    bool Function(PortableAuthoringDocument document) edit,
  ) => draft.stageExpressionEdit(
    reads,
    (branch) => edit(AuthoredDraftAuthoringDocument(branch)),
  );

  @override
  void delete(skir.ResourceId id) => draft.delete(id);

  @override
  void connect(
    skir.LinkOccurrence source,
    skir.ResourceId target, {
    skir.CounterpartChoice? counterpart,
  }) => draft.connect(source, target, counterpart: counterpart);

  @override
  void disconnect(skir.LinkOccurrence occurrence) =>
      draft.disconnect(occurrence);
}

final class AuthoredDraftPresentationHost extends ChangeNotifier
    implements PortablePresentationHost {
  AuthoredDraftPresentationHost({
    required this.resource,
    required AuthoredDraft draft,
    required this.material,
    required this.role,
    required this.budget,
    required this.capabilities,
    this.available = true,
    this.readOnly = false,
    this.prepareCreation,
    this.onDraftChanged,
    this.reportStatus,
  }) : draft = draft,
       authored = AuthoredDraftAuthoringDocument(draft);

  final skir.ResourceId resource;
  final AuthoredDraft draft;
  final AuthoredDraftAuthoringDocument authored;
  final skir.PresentationMaterial material;
  final skir.PresentationRole role;
  final skir.EvaluationBudget budget;
  @override
  final PortablePresentationCapabilities capabilities;
  final bool available;
  @override
  final bool readOnly;
  final Future<skir.PreparedCreation> Function(
    skir.InitializationRequest request,
  )?
  prepareCreation;
  final VoidCallback? onDraftChanged;
  final ValueChanged<String>? reportStatus;
  var _preparing = false;
  var _disposed = false;

  @override
  bool get enabled => !_disposed && available && !_preparing;

  @override
  PortablePresentationDocument get document {
    final record = draft.resource(resource);
    if (record == null) {
      throw StateError("The authored resource is absent");
    }
    final checked = draft.catalog;
    if (checked == null || checked.snapshot.generation != draft.generation) {
      throw StateError("The authored draft catalog is unavailable");
    }
    final payload = skir.DataValue.createRecord(fields: record.fields);
    final value = switch (record.configuration) {
      skir.TypeSelection_completeWrapper(:final value) =>
        skir.DataValue.createNamed(actualType: value, payload: payload),
      _ => payload,
    };
    return PortablePresentationDocument(
      catalog: checked,
      root: material.layout,
      bindings: {
        configuredValueBindingId: PortablePresentationBinding(
          schema: switch (record.configuration) {
            skir.TypeSelection_completeWrapper(:final value) =>
              CompletePortablePresentationBinding(
                skir.TypeUse.wrapNamed(value),
              ),
            _ => PartialPortablePresentationBinding(record.configuration),
          },
          value: value,
          editable: true,
          location: skir.ValueLocation(
            resource: resource,
            path: skir.ValuePath(segments: const []),
          ),
        ),
      },
      budget: budget,
      role: role,
      material: material,
      activePresentations: {material.provider},
    );
  }

  @override
  skir.DataValue? read(skir.BindingRef reference) {
    final exposed = document.bindings[reference.bindingId];
    if (exposed == null) return null;
    if (reference.path.segments.isEmpty) return exposed.value;
    return switch (exposed.value.readAt(reference.path)) {
      PortablePathValue(:final value) => value,
      PortablePathUnavailable() => null,
    };
  }

  @override
  skir.ValueLocation? location(skir.BindingRef reference) {
    final base = document.bindings[reference.bindingId]?.location;
    if (base == null) return null;
    return skir.ValueLocation(
      resource: base.resource,
      path: skir.ValuePath(
        segments: [...base.path.segments, ...reference.path.segments],
      ),
    );
  }

  @override
  skir.TypeUse? expectedType(skir.BindingRef reference) {
    final target = location(reference);
    final record = target == null ? null : draft.resource(target.resource);
    return record == null
        ? null
        : draft.catalog?.valueTypeAt(
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
    skir.DataValue value,
  ) async {
    if (!enabled || readOnly) {
      return const PortablePresentationWriteRejected(
        "This presentation is read only",
      );
    }
    final target = location(reference);
    if (target == null) {
      return const PortablePresentationWriteRejected(
        "The presentation binding is unavailable",
      );
    }
    var result = draft.set(target, value);
    if (result case PortablePathUnavailable(
      message: "The parent field needs prepared initialization",
    )) {
      final prepare = prepareCreation;
      if (prepare == null) {
        return PortablePresentationWriteRejected(result.message);
      }
      final previousFindingCount = draft.initializationFindings.length;
      _preparing = true;
      notifyListeners();
      try {
        result = await draft.setWithInitialization(target, value, prepare);
        final findings = draft.initializationFindings.skip(
          previousFindingCount,
        );
        if (!_disposed && findings.isNotEmpty) {
          reportStatus?.call(
            findings.map(formatPortableInitializationDiagnostic).join("\n"),
          );
        }
      } on Object {
        return const PortablePresentationWriteRejected(
          "The parent field could not be initialized. Retry this edit",
        );
      } finally {
        _preparing = false;
        if (!_disposed) notifyListeners();
      }
    }
    return switch (result) {
      PortablePathValue() => _applied(),
      PortablePathUnavailable(:final message) =>
        PortablePresentationWriteRejected(message),
    };
  }

  PortablePresentationWriteResult _applied() {
    if (!_disposed) {
      notifyListeners();
      onDraftChanged?.call();
    }
    return const PortablePresentationWriteApplied();
  }

  @override
  Future<PortablePresentationWriteResult> execute(
    skir.EditorAction editorAction,
  ) async => _disposed
      ? const PortablePresentationWriteRejected(
          "This presentation is no longer available",
        )
      : const PortablePresentationWriteRejected(
          "This action requires the authored Realm operation boundary",
        );

  @override
  void dispose() {
    if (_disposed) return;
    _disposed = true;
    super.dispose();
  }
}
