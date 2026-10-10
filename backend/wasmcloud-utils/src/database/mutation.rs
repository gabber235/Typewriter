//! Stable identities for mutation receipts.
//!
//! A receipt belongs to the authenticated actor, operation scope, operation name, and caller
//! supplied identity. It owns the original request bytes and binds both values to the transaction
//! that creates or recalls the result.

use super::RecordId;

/// Stable identity and original input for one idempotent mutation.
///
/// The receipt is only useful for idempotency when the transaction stores it with the mutation
/// result. Reusing the identity with different request bytes is a rejected operation, not a new
/// mutation.
pub struct MutationReceipt {
    record: RecordId,
    request_bytes: Vec<u8>,
}

impl MutationReceipt {
    /// Creates the receipt identity and retains the exact encoded request used by the caller.
    pub fn new(
        actor: &str,
        scope: &str,
        operation: &str,
        operation_id: &str,
        request_bytes: Vec<u8>,
    ) -> Self {
        let key = serde_json::to_string(&(actor, scope, operation, operation_id))
            .expect("serializing a tuple of strings cannot fail");
        Self {
            record: RecordId::new("mutation_receipt", key),
            request_bytes,
        }
    }

    /// Consumes the receipt and binds its inseparable identity and request bytes to a transaction.
    pub fn bind<'query, Outcome: serde::de::DeserializeOwned>(
        self,
        query: super::TransactionQuery<'query, Outcome>,
    ) -> super::TransactionQuery<'query, Outcome> {
        query
            .bind("receipt", self.record)
            .bind("request_bytes", self.request_bytes)
    }
}
