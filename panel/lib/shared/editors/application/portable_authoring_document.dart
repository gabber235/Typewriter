import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";

extension PreparedRecordContent on skir.PreparedValue {
  skir.AuthoringRecord get recordContent => switch (content) {
    skir.PreparedContent_recordWrapper(:final value) => value,
    _ => throw StateError("Record preparation returned scalar content"),
  };
}

extension RecordPreparationTarget on skir.ValuePreparationRequest {
  skir.TypeSelection get recordSelection => switch (target) {
    skir.PreparationTarget_recordWrapper(:final value) => value,
    _ => throw StateError("Record operation received a scalar preparation"),
  };

  List<skir.FieldValue> get recordSuppliedFields => switch (suppliedValue) {
    skir.DataValue_recordWrapper(:final value) => value.fields.toList(),
    _ => const [],
  };
}

abstract interface class PortableAuthoringView {
  skir.CatalogGeneration get generation;

  Map<skir.ResourceId, skir.AuthoringRecord> get resources;

  List<skir.LinkProjection> get links;

  List<skir.InitializationDiagnostic> get initializationFindings;

  skir.AuthoringRecord? resource(skir.ResourceId id);

  PortablePathResult<skir.DataValue> read(skir.ValueLocation location);

  skir.DataValue defaultValue(skir.TypeUse? type);
}

abstract interface class PortableAuthoringEdit
    implements PortableAuthoringView {
  int get operationCount;
  PortablePathResult<skir.DataValue> expect(skir.ValueLocation location);
  void observeExpressionReads(Iterable<PortableExpressionRead> reads);

  PortablePathResult<skir.AuthoringRecord> set(
    skir.ValueLocation location,
    skir.DataValue value,
  );

  PortablePathResult<skir.AuthoringRecord> insert(
    skir.ValueLocation location,
    skir.ItemId? after,
    skir.ListItem item,
  );

  PortablePathResult<skir.AuthoringRecord> insertPrepared(
    skir.ValueLocation location,
    skir.ItemId? after,
    skir.ItemId item,
    skir.ValuePreparationRequest request,
    skir.PreparedValue prepared,
  );

  PortablePathResult<skir.AuthoringRecord> remove(
    skir.ValueLocation location,
    skir.ItemId item,
  );

  PortablePathResult<skir.AuthoringRecord> move(
    skir.ValueLocation location,
    skir.ItemId item,
    skir.ItemId? after,
  );

  PortablePathResult<skir.AuthoringRecord> replaceMap(
    skir.ValueLocation location,
    Iterable<skir.MapRow> rows,
  );

  PortablePathResult<skir.AuthoringRecord> applyPreparedRecord(
    skir.ValueLocation location,
    skir.ValuePreparationRequest request,
    skir.PreparedValue prepared,
  );

  bool stageExpressionEdit(
    Iterable<PortableExpressionRead> reads,
    bool Function(PortableAuthoringEdit edit) edit,
  );

  void delete(skir.ResourceId id);

  void connect(
    skir.LinkOccurrence source,
    skir.ResourceId target, {
    skir.CounterpartChoice? counterpart,
  });

  void disconnect(skir.LinkOccurrence occurrence);
}
