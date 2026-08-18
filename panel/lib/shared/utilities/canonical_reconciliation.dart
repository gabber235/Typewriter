import "package:flutter/foundation.dart";
import "package:typewriter_panel/shared/utilities/collection.dart";

typedef CanonicalReconciliation<T> = ({List<T> values, T canonical});

CanonicalReconciliation<T> reconcileCanonicalRevision<T extends Object, K>({
  required List<T>? values,
  required T incoming,
  required K Function(T value) keyOf,
  required int Function(T value) revisionOf,
  required String Function(T value) identityOf,
  required String entityName,
}) {
  final current = values ?? <T>[];
  final incomingKey = keyOf(incoming);
  T? existing;
  for (final value in current) {
    if (keyOf(value) == incomingKey) {
      existing = value;
      break;
    }
  }

  final incomingRevision = revisionOf(incoming);
  if (existing != null && revisionOf(existing) >= incomingRevision) {
    if (revisionOf(existing) == incomingRevision && existing != incoming) {
      FlutterError.reportError(
        FlutterErrorDetails(
          exception: StateError(
            "${identityOf(incoming)} has different values at revision $incomingRevision",
          ),
          library: "typewriter_panel",
          context: ErrorDescription(
            "while reconciling a canonical $entityName",
          ),
        ),
      );
    }
    return (values: current, canonical: existing);
  }

  return (values: current.upsertByKey(keyOf, incoming), canonical: incoming);
}
