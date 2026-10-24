import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;

/// The panel's map entry operations. An entry is a record of key and value.
final class PanelEntryKernel implements skir.EntryKernel {
  const PanelEntryKernel();

  @override
  skir.DataValue of(skir.DataValue key, skir.DataValue value) =>
      skir.entryValue(key, value);
}
