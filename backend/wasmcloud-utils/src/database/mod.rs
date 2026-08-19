use std::{num::NonZeroU32, time::Duration};

use serde::{Serialize, de::DeserializeOwned};
use surrealdb_component_sdk::{ConflictRetryPolicy, Query, query};

pub use crate::{read_query, transaction_query, transaction_query_file};
pub use surrealdb_component_sdk::{
    Datetime, DomainError, Duration as DatabaseDuration, QueryError, QueryResponse,
    QueryResultError, RecordId, RecordIdKey, RecordIdValue, SingleQueryResultExtractor,
    TransactionOutcome,
};

pub mod organization;
pub mod service;

pub const TRANSACTION_CONFLICT_MAX_ATTEMPTS: u32 = 3;
pub const TRANSACTION_CONFLICT_INITIAL_DELAY: Duration = Duration::from_millis(10);
pub const TRANSACTION_CONFLICT_MAXIMUM_DELAY: Duration = Duration::from_millis(40);

/// Read query that cannot opt into mutation retry behavior.
pub struct ReadQuery<'a> {
    query: Query<'a>,
    outcome_index: usize,
}

impl ReadQuery<'_> {
    #[doc(hidden)]
    pub fn __from_literal(query_str: &str, outcome_index: usize) -> ReadQuery<'_> {
        ReadQuery {
            query: query(query_str),
            outcome_index,
        }
    }

    pub fn bind<V: Serialize>(mut self, key: impl Into<String>, value: V) -> Self {
        self.query = self.query.bind(key, value);
        self
    }

    pub async fn execute(self) -> Result<ReadResponse, QueryError> {
        Ok(ReadResponse {
            response: self.query.execute().await?,
            outcome_index: self.outcome_index,
        })
    }
}

pub struct ReadResponse {
    response: QueryResponse,
    outcome_index: usize,
}

impl ReadResponse {
    pub fn take<T: SingleQueryResultExtractor>(&self) -> Result<T, QueryResultError> {
        self.response.take(self.outcome_index)
    }

    pub fn parse<T: DeserializeOwned>(&self) -> Result<T, QueryResultError> {
        self.response.parse(self.outcome_index)
    }

    pub fn transaction<T: DeserializeOwned>(
        &self,
    ) -> Result<TransactionOutcome<T>, QueryResultError> {
        self.response.transaction(self.outcome_index)
    }
}

/// Explicit transaction query with a typed outcome and bounded conflict retries.
pub struct TransactionQuery<'a, T: DeserializeOwned> {
    query: Query<'a>,
    outcome_index: usize,
    outcome: std::marker::PhantomData<fn() -> T>,
}

impl<T: DeserializeOwned> TransactionQuery<'_, T> {
    #[doc(hidden)]
    pub fn __from_literal(query_str: &str, outcome_index: usize) -> TransactionQuery<'_, T> {
        TransactionQuery {
            query: apply_transaction_retry(query(query_str)),
            outcome_index,
            outcome: std::marker::PhantomData,
        }
    }

    pub fn bind<V: Serialize>(mut self, key: impl Into<String>, value: V) -> Self {
        self.query = self.query.bind(key, value);
        self
    }

    pub async fn execute(self) -> Result<TransactionResponse<T>, QueryError> {
        Ok(TransactionResponse {
            response: self.query.execute().await?,
            outcome_index: self.outcome_index,
            outcome: std::marker::PhantomData,
        })
    }
}

pub struct TransactionResponse<T: DeserializeOwned> {
    response: QueryResponse,
    outcome_index: usize,
    outcome: std::marker::PhantomData<fn() -> T>,
}

impl<T: DeserializeOwned> TransactionResponse<T> {
    pub fn attempts(&self) -> NonZeroU32 {
        self.response.attempts()
    }

    pub fn decode(self) -> Result<TransactionOutcome<T>, QueryResultError> {
        self.response.transaction(self.outcome_index)
    }
}

fn transaction_retry_policy() -> ConflictRetryPolicy {
    ConflictRetryPolicy::new(
        NonZeroU32::new(TRANSACTION_CONFLICT_MAX_ATTEMPTS)
            .expect("transaction attempt count is nonzero"),
        TRANSACTION_CONFLICT_INITIAL_DELAY,
        TRANSACTION_CONFLICT_MAXIMUM_DELAY,
    )
}

trait ConflictRetryQuery: Sized {
    fn with_conflict_retry(self, policy: ConflictRetryPolicy) -> Self;
}

impl ConflictRetryQuery for Query<'_> {
    fn with_conflict_retry(self, policy: ConflictRetryPolicy) -> Self {
        self.retry_conflicts(policy)
    }
}

fn apply_transaction_retry<T: ConflictRetryQuery>(query: T) -> T {
    query.with_conflict_retry(transaction_retry_policy())
}

#[cfg(test)]
mod tests {
    use serde::Deserialize;

    use super::{ConflictRetryQuery, ReadQuery, TransactionQuery, apply_transaction_retry};

    #[derive(Deserialize)]
    struct Outcome;

    #[test]
    fn builds_read_query() {
        ReadQuery::__from_literal("SELECT * FROM user;", 0);
    }

    #[test]
    fn transaction_query_applies_conflict_retry_policy() {
        struct Probe(bool);

        impl ConflictRetryQuery for Probe {
            fn with_conflict_retry(
                mut self,
                _policy: surrealdb_component_sdk::ConflictRetryPolicy,
            ) -> Self {
                self.0 = true;
                self
            }
        }

        assert!(apply_transaction_retry(Probe(false)).0);

        TransactionQuery::<Outcome>::__from_literal(
            "BEGIN TRANSACTION; RETURN true; COMMIT TRANSACTION;",
            1,
        );
    }
}
