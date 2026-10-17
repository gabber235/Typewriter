/// Widgets for browsing and editing the Realm tag graph.
///
/// Presentation reads the projected tag providers. It does not retain tag
/// state, validate authoring conflicts, or persist placement and inheritance
/// changes; those responsibilities belong to the application layer.
library;

export "rejected_tag_drop_target.dart";
export "route.dart";
export "tag_graph.dart";
export "tag_node.dart";
