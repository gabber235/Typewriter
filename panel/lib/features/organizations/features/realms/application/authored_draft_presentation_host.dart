import "package:flutter/foundation.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skirout/editor/v1/action.dart"
    as action;
import "package:typewriter_panel/infrastructure/protocols/skir/skirout/editor/v1/authoring.dart"
    as authoring;
import "package:typewriter_panel/infrastructure/protocols/skir/skirout/editor/v1/authoring_facts.dart"
    as facts;
import "package:typewriter_panel/infrastructure/protocols/skir/skirout/editor/v1/binding.dart"
    as binding;
import "package:typewriter_panel/infrastructure/protocols/skir/skirout/editor/v1/catalog.dart"
    as catalog;
import "package:typewriter_panel/infrastructure/protocols/skir/skirout/editor/v1/diagnostic.dart"
    as diagnostic_wire;
import "package:typewriter_panel/infrastructure/protocols/skir/skirout/editor/v1/expression.dart"
    as expression;
import "package:typewriter_panel/infrastructure/protocols/skir/skirout/editor/v1/type_catalog.dart"
    as types;
import "package:typewriter_panel/typewriter_panel.dart";

final class AuthoredDraftAuthoringDocument
    implements PortableAuthoringDocument {
  AuthoredDraftAuthoringDocument(this.draft);

  final AuthoredDraft draft;

  @override
  types.CatalogGeneration get generation => draft.generation;

  @override
  Map<types.ResourceId, types.AuthoringRecord> get resources => draft.resources;

  @override
  List<facts.LinkProjection> get links => draft.links;

  @override
  List<diagnostic_wire.InitializationDiagnostic> get initializationFindings =>
      draft.initializationFindings;

  @override
  int get operationCount => draft.intents.length;

  @override
  types.AuthoringRecord? resource(types.ResourceId id) => draft.resource(id);

  @override
  PortablePathResult<types.DataValue> read(types.ValueLocation location) =>
      draft.read(location);

  @override
  PortablePathResult<types.AuthoringRecord> set(
    types.ValueLocation location,
    types.DataValue value,
  ) => draft.set(location, value);

  @override
  PortablePathResult<types.AuthoringRecord> insert(
    types.ValueLocation location,
    types.ItemId? after,
    types.ListItem item,
  ) => draft.insert(location, after, item);

  @override
  PortablePathResult<types.AuthoringRecord> insertPrepared(
    types.ValueLocation location,
    types.ItemId? after,
    types.ItemId item,
    catalog.InitializationRequest request,
    catalog.PreparedCreation prepared,
  ) => draft.insertPrepared(location, after, item, request, prepared);

  @override
  types.DataValue defaultValue(types.TypeUse? type) => draft.defaultValue(type);

  @override
  PortablePathResult<types.AuthoringRecord> remove(
    types.ValueLocation location,
    types.ItemId item,
  ) => draft.remove(location, item);

  @override
  PortablePathResult<types.AuthoringRecord> move(
    types.ValueLocation location,
    types.ItemId item,
    types.ItemId? after,
  ) => draft.move(location, item, after);

  @override
  PortablePathResult<types.AuthoringRecord> replaceMap(
    types.ValueLocation location,
    Iterable<types.MapRow> rows,
  ) => draft.replaceMap(location, rows);

  @override
  PortablePathResult<types.AuthoringRecord> applyPreparedRecord(
    types.ValueLocation location,
    catalog.InitializationRequest request,
    catalog.PreparedCreation prepared,
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
  void delete(types.ResourceId id) => draft.delete(id);

  @override
  void connect(
    authoring.LinkOccurrence source,
    types.ResourceId target, {
    authoring.CounterpartChoice? counterpart,
  }) => draft.connect(source, target, counterpart: counterpart);

  @override
  void disconnect(authoring.LinkOccurrence occurrence) =>
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

  final types.ResourceId resource;
  final AuthoredDraft draft;
  final AuthoredDraftAuthoringDocument authored;
  final catalog.PresentationMaterial material;
  final catalog.PresentationRole role;
  final expression.EvaluationBudget budget;
  @override
  final PortablePresentationCapabilities capabilities;
  final bool available;
  @override
  final bool readOnly;
  final Future<catalog.PreparedCreation> Function(
    catalog.InitializationRequest request,
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
    final payload = types.DataValue.createRecord(fields: record.fields);
    final value = switch (record.configuration) {
      types.TypeSelection_completeWrapper(:final value) =>
        types.DataValue.createNamed(actualType: value, payload: payload),
      _ => payload,
    };
    return PortablePresentationDocument(
      catalog: checked,
      root: material.layout,
      bindings: {
        configuredValueBindingId: PortablePresentationBinding(
          schema: switch (record.configuration) {
            types.TypeSelection_completeWrapper(:final value) =>
              CompletePortablePresentationBinding(
                types.TypeUse.wrapNamed(value),
              ),
            _ => PartialPortablePresentationBinding(record.configuration),
          },
          value: value,
          editable: true,
          location: types.ValueLocation(
            resource: resource,
            path: types.ValuePath(segments: const []),
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
  types.DataValue? read(binding.BindingRef reference) {
    final exposed = document.bindings[reference.bindingId];
    if (exposed == null) return null;
    if (reference.path.segments.isEmpty) return exposed.value;
    return switch (exposed.value.readAt(reference.path)) {
      PortablePathValue(:final value) => value,
      PortablePathUnavailable() => null,
    };
  }

  @override
  types.ValueLocation? location(binding.BindingRef reference) {
    final base = document.bindings[reference.bindingId]?.location;
    if (base == null) return null;
    return types.ValueLocation(
      resource: base.resource,
      path: types.ValuePath(
        segments: [...base.path.segments, ...reference.path.segments],
      ),
    );
  }

  @override
  types.TypeUse? expectedType(binding.BindingRef reference) {
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

  types.DataValue _recordValue(types.AuthoringRecord record) {
    final payload = types.DataValue.createRecord(fields: record.fields);
    return switch (record.configuration) {
      types.TypeSelection_completeWrapper(:final value) =>
        types.DataValue.createNamed(actualType: value, payload: payload),
      _ => payload,
    };
  }

  @override
  Future<PortablePresentationWriteResult> write(
    binding.BindingRef reference,
    types.DataValue value,
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
    action.EditorAction editorAction,
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
