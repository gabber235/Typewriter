import "package:flutter/material.dart";
import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/typewriter_panel.dart";

import "../../../support/test_utils.dart";

part "connection_anchor_export_scenarios.dart";
part "connection_marker_scenarios.dart";
part "connection_path_scenarios.dart";
part "connection_renderer_test_support.dart";

void main() {
  registerConnectionMarkerScenarios();
  registerConnectionAnchorExportScenarios();
  registerConnectionPathScenarios();
}
