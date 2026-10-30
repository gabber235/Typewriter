import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/typewriter_panel.dart";

/// Supplies one explicit operation lifetime to a manual presentation fixture.
PortableOperationResults testPortableOperations() {
  final operations = PortableOperationResults();
  addTearDown(operations.dispose);
  return operations;
}
