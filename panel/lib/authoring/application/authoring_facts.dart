part of "realm_edit_model.dart";

/// Reads exact authoring witnesses without changing local intent.
@freezed
abstract class AuthoringFacts with _$AuthoringFacts {
  const factory AuthoringFacts({
    required Map<skir.ResourceId, skir.AuthoringRecord> resources,
    required List<skir.LinkProjection> links,
  }) = _AuthoringFacts;
  const AuthoringFacts._();

  factory AuthoringFacts.capture({
    required Map<skir.ResourceId, skir.AuthoringRecord> resources,
    required Iterable<skir.LinkProjection> links,
  }) => AuthoringFacts(
    resources: Map.unmodifiable(resources),
    links: List.unmodifiable(links),
  );

  List<skir.ExpectationConflict> conflicts(
    Iterable<skir.EditExpectation> expectations,
  ) {
    final result = <skir.ExpectationConflict>[];
    for (final expected in expectations) {
      final actual = observe(expected);
      if (!_sameExpectation(expected, actual)) {
        result.add(
          skir.ExpectationConflict(expected: expected, actual: actual),
        );
      }
    }
    return List.unmodifiable(result);
  }

  skir.EditExpectation observe(skir.EditExpectation expected) {
    skir.DataValue? value(skir.ValueLocation at) {
      final record = resources[at.resource];
      if (record == null) return null;
      if (at.path.segments.isEmpty) {
        return skir.DataValue.createRecord(fields: record.fields);
      }
      return switch (record.readAt(at.path)) {
        PortablePathValue(:final value) => value,
        _ => null,
      };
    }

    return switch (expected) {
      skir.EditExpectation_valueWrapper(value: final expected) =>
        skir.EditExpectation.createValue(
          at: expected.at,
          expected: value(expected.at),
        ),
      skir.EditExpectation_resourceWrapper(:final value) =>
        skir.EditExpectation.createResource(
          id: value.id,
          expected: resources[value.id],
        ),
      skir.EditExpectation_resourceExistsWrapper(:final value) =>
        skir.EditExpectation.createResourceExists(
          id: value.id,
          expected: resources.containsKey(value.id),
        ),
      skir.EditExpectation_configurationWrapper(value: final config) =>
        skir.EditExpectation.createConfiguration(
          at: config.at,
          expected: config.at.path.segments.isEmpty
              ? resources[config.at.resource]?.configuration
              : switch (value(config.at)) {
                  skir.DataValue_namedWrapper(:final value) =>
                    skir.TypeSelection.wrapComplete(value.actualType),
                  _ => null,
                },
        ),
      skir.EditExpectation_resourceIdsWrapper() =>
        skir.EditExpectation.wrapResourceIds(
          resources.keys.toList()..sort((a, b) => a.value.compareTo(b.value)),
        ),
      skir.EditExpectation_linksWrapper(:final value) =>
        skir.EditExpectation.createLinks(
          resource: value.resource,
          contract: value.contract,
          direction: value.direction,
          expected: links
              .where(
                (link) =>
                    link.contract == value.contract &&
                    switch (value.direction) {
                      skir.TraversalDirection.forward =>
                        link.first == value.resource,
                      skir.TraversalDirection.reverse =>
                        link.second == value.resource,
                      skir.TraversalDirection.both =>
                        link.first == value.resource ||
                            link.second == value.resource,
                      _ => false,
                    },
              )
              .toSet()
              .toList(),
        ),
      _ => throw StateError("Unknown edit expectation"),
    };
  }
}

extension AuthoringDocumentFacts on AuthoringDocument {
  AuthoringFacts get facts =>
      AuthoringFacts.capture(resources: resources, links: links);
}
