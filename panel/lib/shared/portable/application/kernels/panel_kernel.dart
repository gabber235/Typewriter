import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";

/// Every operation group the panel evaluates, rule and panel profile alike.
const panelKernel = skir.PortableKernel(
  boolean: PanelBooleanKernel(),
  bytes: PanelBytesKernel(),
  catalog: PanelCatalogKernel(),
  collection: PanelCollectionKernel(),
  decimal: PanelDecimalKernel(),
  duration: PanelDurationKernel(),
  entry: PanelEntryKernel(),
  enumeration: PanelEnumKernel(),
  integer: PanelIntegerKernel(),
  link: PanelLinkKernel(),
  list: PanelListKernel(),
  map: PanelMapKernel(),
  number: PanelNumberKernel(),
  record: PanelRecordKernel(),
  regex: PanelRegexKernel(),
  resource: PanelResourceKernel(),
  set: PanelSetKernel(),
  text: PanelTextKernel(),
  timestamp: PanelTimestampKernel(),
  value: PanelValueKernel(),
);
