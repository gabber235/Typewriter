import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";

/// The panel's record operations.
final class PanelRecordKernel implements skir.RecordKernel {
  const PanelRecordKernel();

  /// Replaces the field, or inserts it in name order when the record lacks
  /// it. A named record keeps its type; only the payload changes.
  @override
  skir.DataValue withField(
    skir.DataValue source,
    String field,
    skir.DataValue value,
  ) => source.withAuthoredPayload(
    skir.recordValue({...source.asRecordFields(), field: value}),
  );
}
