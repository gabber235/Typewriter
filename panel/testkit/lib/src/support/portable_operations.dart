import "package:flutter_test/flutter_test.dart";
import "package:typewriter_panel/infrastructure/protocols/skir/skir.dart"
    as skir;
import "package:typewriter_panel/typewriter_panel.dart";

/// Supplies one explicit operation lifetime to a manual presentation fixture.
PortableOperationResults testPortableOperations() {
  final operations = PortableOperationResults();
  addTearDown(operations.dispose);
  return operations;
}

/// A scope with the test operations and no bindings, evaluating within a
/// budget of 1000 steps and 100 collection items.
PortablePresentationScope unboundPresentationScope() =>
    PortablePresentationScope(
      operations: testPortableOperations(),
      bindings: const {},
      budget: skir.EvaluationBudget(maxSteps: 1000, maxCollectionItems: 100),
    );

/// A scope whose binding [binding] holds a record of [fields] at [location],
/// rendered through [host] with the test operations, evaluating within a
/// budget of 100 steps and 100 collection items.
PortablePresentationScope recordPresentationScope(
  PortablePresentationHost host,
  skir.ExpressionBindingId binding,
  Map<String, skir.DataValue> fields, {
  skir.ValueLocation? location,
}) => PortablePresentationScope(
  operations: testPortableOperations(),
  bindings: {
    binding: PortableExpressionBinding(
      value: skir.DataValue.createRecord(
        fields: [
          for (final field in fields.entries)
            skir.FieldValue(name: field.key, value: field.value),
        ],
      ),
      location: location,
    ),
  },
  budget: skir.EvaluationBudget(maxSteps: 100, maxCollectionItems: 100),
  host: host,
);
