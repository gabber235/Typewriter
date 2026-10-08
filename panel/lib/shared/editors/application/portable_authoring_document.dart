import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";

abstract interface class PortableAuthoringDocument {
  skir.CatalogGeneration get generation;

  Map<skir.ResourceId, skir.AuthoringRecord> get resources;

  List<skir.LinkProjection> get links;

  List<skir.InitializationDiagnostic> get initializationFindings;

  int get operationCount;

  skir.AuthoringRecord? resource(skir.ResourceId id);

  PortablePathResult<skir.DataValue> read(skir.ValueLocation location);

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
    skir.InitializationRequest request,
    skir.PreparedCreation prepared,
  );

  skir.DataValue defaultValue(skir.TypeUse? type);

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
    skir.InitializationRequest request,
    skir.PreparedCreation prepared,
  );

  bool stageExpressionEdit(
    Iterable<PortableExpressionRead> reads,
    bool Function(PortableAuthoringDocument document) edit,
  );

  void delete(skir.ResourceId id);

  void connect(
    skir.LinkOccurrence source,
    skir.ResourceId target, {
    skir.CounterpartChoice? counterpart,
  });

  void disconnect(skir.LinkOccurrence occurrence);
}
