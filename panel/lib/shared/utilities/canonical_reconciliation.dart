import "package:typewriter_panel/typewriter_panel.dart";

part "canonical_reconciliation.freezed.dart";

/// The reconciled collection and the value accepted as canonical.
///
/// [values] is safe to publish as the current collection. [canonical] is the
/// value callers must use for revision sensitive decisions, including mutation
/// conflict expectations.
@freezed
abstract class CanonicalReconciliation<T> with _$CanonicalReconciliation<T> {
  const factory CanonicalReconciliation({
    required List<T> values,
    required T canonical,
  }) = _CanonicalReconciliation<T>;
}

/// Reconciles one incoming value into a revisioned canonical collection.
///
/// Values are matched by [keyOf]. An older or equal revision cannot replace the
/// existing value. Equal revisions with unequal values report a
/// [FlutterError], because the same canonical revision has diverged, then keep
/// the existing value. A newer revision replaces the matching value through
/// [upsertByKey]. A null collection is treated as empty.
extension CanonicalRevisionOperations<T extends Object> on List<T>? {
  CanonicalReconciliation<T> reconcileRevision<K>({
    required T incoming,
    required K Function(T value) keyOf,
    required int Function(T value) revisionOf,
    required String Function(T value) identityOf,
    required String entityName,
  }) {
    final current = this ?? <T>[];
    final incomingKey = keyOf(incoming);
    final existing = current.firstWhereOrNull(
      (value) => keyOf(value) == incomingKey,
    );

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
      return CanonicalReconciliation(values: current, canonical: existing);
    }

    return CanonicalReconciliation(
      values: current.upsertByKey(keyOf, incoming),
      canonical: incoming,
    );
  }
}
