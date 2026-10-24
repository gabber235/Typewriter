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

/// Resource observation used by portable expressions and link planning.
/// Reads expose values without creating persistence expectations. Catalog
/// generation identifies their interpretation context, not a resource revision.
abstract interface class PortableAuthoringView {
  skir.CatalogGeneration get generation;

  Map<skir.ResourceId, skir.AuthoringRecord> get resources;

  List<skir.LinkProjection> get links;

  skir.AuthoringRecord? resource(skir.ResourceId id);

  PortablePathResult<skir.DataValue> read(skir.ValueLocation location);

  skir.DataValue defaultValue(skir.TypeUse? type);
}

/// Mutable operation branch whose reads and intent can be captured for a save.
///
/// Editing stays local to the branch. Its enclosing workspace decides when to
/// publish and persist the resulting operations and expectations.
abstract interface class PortableAuthoringEdit
    implements PortableAuthoringView {
  int get operationCount;

  /// Reads a value while recording the semantic fact this edit depends on.
  /// Display only reads should use [read] so they do not widen save conflicts.
  PortablePathResult<skir.DataValue> expect(skir.ValueLocation location);
  void observeExpressionReads(Iterable<skir.ValueLocation> reads);

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

  /// Publishes a callback's branch and expression read witnesses only if the
  /// callback accepts. A false result abandons both mutations and witnesses.
  bool stageExpressionEdit(
    Iterable<skir.ValueLocation> reads,
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
