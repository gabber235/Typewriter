import "package:typewriter_panel/infrastructure/protocols/skir/skirout/editor/v1/authoring.dart"
    as authoring;
import "package:typewriter_panel/infrastructure/protocols/skir/skirout/editor/v1/authoring_facts.dart"
    as facts;
import "package:typewriter_panel/infrastructure/protocols/skir/skirout/editor/v1/catalog.dart"
    as catalog;
import "package:typewriter_panel/infrastructure/protocols/skir/skirout/editor/v1/diagnostic.dart"
    as diagnostic;
import "package:typewriter_panel/infrastructure/protocols/skir/skirout/editor/v1/type_catalog.dart"
    as types;
import "package:typewriter_panel/typewriter_panel.dart";

abstract interface class PortableAuthoringDocument {
  types.CatalogGeneration get generation;

  Map<types.ResourceId, types.AuthoringRecord> get resources;

  List<facts.LinkProjection> get links;

  List<diagnostic.InitializationDiagnostic> get initializationFindings;

  int get operationCount;

  types.AuthoringRecord? resource(types.ResourceId id);

  PortablePathResult<types.DataValue> read(types.ValueLocation location);

  PortablePathResult<types.AuthoringRecord> set(
    types.ValueLocation location,
    types.DataValue value,
  );

  PortablePathResult<types.AuthoringRecord> insert(
    types.ValueLocation location,
    types.ItemId? after,
    types.ListItem item,
  );

  PortablePathResult<types.AuthoringRecord> insertPrepared(
    types.ValueLocation location,
    types.ItemId? after,
    types.ItemId item,
    catalog.InitializationRequest request,
    catalog.PreparedCreation prepared,
  );

  types.DataValue defaultValue(types.TypeUse? type);

  PortablePathResult<types.AuthoringRecord> remove(
    types.ValueLocation location,
    types.ItemId item,
  );

  PortablePathResult<types.AuthoringRecord> move(
    types.ValueLocation location,
    types.ItemId item,
    types.ItemId? after,
  );

  PortablePathResult<types.AuthoringRecord> replaceMap(
    types.ValueLocation location,
    Iterable<types.MapRow> rows,
  );

  PortablePathResult<types.AuthoringRecord> applyPreparedRecord(
    types.ValueLocation location,
    catalog.InitializationRequest request,
    catalog.PreparedCreation prepared,
  );

  bool stageExpressionEdit(
    Iterable<PortableExpressionRead> reads,
    bool Function(PortableAuthoringDocument document) edit,
  );

  void delete(types.ResourceId id);

  void connect(
    authoring.LinkOccurrence source,
    types.ResourceId target, {
    authoring.CounterpartChoice? counterpart,
  });

  void disconnect(authoring.LinkOccurrence occurrence);
}
