use std::{num::NonZeroU32, time::Duration};

use surrealdb_component_sdk::{ConflictRetryPolicy, Query, query};

pub mod organization;
pub mod service;

/// Builds an explicit transaction with bounded conflict retries.
pub fn retrying_transaction(query_str: &str) -> Query<'_> {
    let query_str = query_str.trim();
    assert!(
        query_str.starts_with("BEGIN TRANSACTION;") && query_str.ends_with("COMMIT TRANSACTION;"),
        "retrying transaction must have an explicit transaction boundary"
    );

    query(query_str).retry_conflicts(ConflictRetryPolicy::new(
        NonZeroU32::new(3).expect("transaction attempt count is nonzero"),
        Duration::from_millis(10),
        Duration::from_millis(40),
    ))
}

#[cfg(test)]
mod tests {
    use super::retrying_transaction;

    #[test]
    fn accepts_explicit_transaction() {
        retrying_transaction("BEGIN TRANSACTION; RETURN true; COMMIT TRANSACTION;");
    }

    #[test]
    #[should_panic(expected = "retrying transaction must have an explicit transaction boundary")]
    fn rejects_implicit_transaction() {
        retrying_transaction("UPDATE user:test SET name = 'unsafe';");
    }
}
