import "package:typewriter_panel/typewriter_panel.dart";

/// The reconciled collection and the value accepted as canonical.
///
/// [values] is safe to publish as the current collection. [canonical] is the
/// value callers must use for revision sensitive decisions, including mutation
/// conflict expectations.
typedef CanonicalReconciliation<T> = ({List<T> values, T canonical});

/// Reconciles one incoming value into a revisioned canonical collection.
///
/// Values are matched by [keyOf]. An older or equal revision cannot replace the
/// existing value. Equal revisions with unequal values report a
/// [FlutterError], because the same canonical revision has diverged, then keep
/// the existing value. A newer revision replaces the matching value through
/// [upsertByKey]. A null collection is treated as empty.
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
