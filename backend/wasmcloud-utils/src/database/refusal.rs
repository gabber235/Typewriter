//! Typed refusals that roll back a transaction.
//!
//! Only a thrown error rolls back the writes a transaction has already made, and SurrealDB
//! flattens every thrown value to a string before it reaches the component. A transaction that
//! must refuse with data after writing therefore calls `fn::refuse($refusal)` (defined in
//! `database/schema/kernel/refusal.surql`), which throws the refusal as JSON behind
//! [`REFUSAL_MARKER`], and the handler decodes it with
//! [`TransactionResponse::decode_refusable`](super::TransactionResponse::decode_refusable).
//! That function and `fn::refuse` are the only places that encode or decode the thrown string;
//! handlers throw and match typed refusals.

use std::fmt;

use serde::de::DeserializeOwned;
use surrealdb_component_sdk::{DomainError, QueryResultError};

/// The prefix `fn::refuse` puts before the JSON of a refusal. Kept in step with that function.
const REFUSAL_MARKER: &str = "refused:";

/// The outcome of a transaction that either commits `T` or refuses with `R` and rolls back.
#[derive(Debug, Clone, PartialEq, Eq)]
pub enum Refusable<T, R> {
    /// The transaction committed and produced `T`.
    Committed(T),
    /// The transaction called `fn::refuse` with `R`; every write it made was rolled back.
    Refused(R),
}

/// Why a refusable transaction could not be decoded.
#[derive(Debug)]
pub enum RefusalDecodeError {
    /// The committed value or the statement results could not be read.
    Query(QueryResultError),
    /// The transaction threw something other than `fn::refuse`.
    NotARefusal(DomainError),
    /// `fn::refuse` threw a value that is not the expected refusal type.
    Unreadable(serde_json::Error),
}

impl fmt::Display for RefusalDecodeError {
    fn fmt(&self, formatter: &mut fmt::Formatter<'_>) -> fmt::Result {
        match self {
            Self::Query(error) => write!(formatter, "{error}"),
            Self::NotARefusal(error) => write!(
                formatter,
                "the transaction threw {:?}, which is not a refusal",
                error.message()
            ),
            Self::Unreadable(error) => write!(formatter, "the refusal could not be read: {error}"),
        }
    }
}

impl std::error::Error for RefusalDecodeError {}

/// Reads the refusal `fn::refuse` threw from the message of a domain rejection, or `None` when
/// the transaction threw something else.
pub(super) fn read_refusal<R: DeserializeOwned>(
    message: &str,
) -> Option<Result<R, serde_json::Error>> {
    crate::database_domain_slug(message)
        .strip_prefix(REFUSAL_MARKER)
        .map(serde_json::from_str)
}

#[cfg(test)]
mod tests {
    use std::collections::BTreeMap;

    use super::read_refusal;

    #[test]
    fn a_thrown_refusal_reads_back_as_its_type() {
        let thrown =
            r#"An error occurred: refused:[{"index":"1","outcome":"realm-not-found-error"}]"#;

        let refused: Vec<BTreeMap<String, String>> = read_refusal(thrown)
            .expect("a refusal")
            .expect("a readable refusal");

        assert_eq!(
            refused,
            [BTreeMap::from([
                ("index".to_owned(), "1".to_owned()),
                ("outcome".to_owned(), "realm-not-found-error".to_owned()),
            ])]
        );
    }

    #[test]
    fn a_thrown_domain_slug_is_not_a_refusal() {
        let thrown = "An error occurred: founder-cannot-be-removed-error";

        assert!(read_refusal::<Vec<BTreeMap<String, String>>>(thrown).is_none());
    }
}
