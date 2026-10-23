import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";

/// The panel's record operations.
final class PanelRecordKernel implements skir.RecordKernel {
  const PanelRecordKernel();

  @override
  skir.DataValue withField(
    skir.DataValue source,
    String field,
    skir.DataValue value,
  ) {
    final fields = source.asRecordFields();
    if (!fields.containsKey(field)) {
      throw skir.PortableOperationFailure(
        skir.PortableFailures.illTypedArgument,
        "The record has no field $field.",
      );
    }
    // A named record keeps its type; only the payload changes.
    return source.withAuthoredPayload(
      skir.recordValue({...fields, field: value}),
    );
  }
}
