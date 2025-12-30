//! Join request builder for seeding test data.

use anyhow::{Context, Result};
use serde::Deserialize;
use surrealdb::engine::any::Any;
use surrealdb::{RecordId, Surreal};

use super::organization::Organization;
use super::user::User;

/// A join request record created in the database.
#[derive(Debug, Clone)]
pub struct JoinRequest {
    pub id: String,
    pub user_id: String,
    pub organization_id: String,
}

/// Record returned from SurrealDB RELATE query.
#[derive(Debug, Deserialize)]
struct RequestsToJoinRecord {
    id: RecordId,
}

/// Builder for creating requests_to_join relationships (user -> organization).
pub struct JoinRequestBuilder {
    user_id: String,
    organization_id: String,
    expires_in_days: i64,
}

impl JoinRequestBuilder {
    /// Create a new join request builder.
    pub fn new(user: &User, org: &Organization) -> Self {
        Self {
            user_id: user.id.clone(),
            organization_id: org.id.clone(),
            expires_in_days: 7,
        }
    }

    /// Set custom expiration in days from now.
    pub fn expires_in_days(mut self, days: i64) -> Self {
        self.expires_in_days = days;
        self
    }

    /// Create the join request in the database.
    ///
    /// Uses raw RELATE query due to known issues with insert().relation() in SurrealDB Rust SDK.
    /// See: https://github.com/surrealdb/surrealdb/issues/5209
    ///
    /// Uses string-type record keys (backtick syntax) to match what the component expects when
    /// using `type::thing()` in SurrealQL queries.
    pub async fn create(self, db: &Surreal<Any>) -> Result<JoinRequest> {
        // Calculate expiration time offset string for SurrealDB
        let expires_offset = if self.expires_in_days >= 0 {
            format!("time::now() + {}d", self.expires_in_days)
        } else {
            format!("time::now() - {}d", -self.expires_in_days)
        };

        // Use backtick syntax for string-type record keys to match component's type::thing() usage
        let query = format!(
            "RELATE user:`{}`->requests_to_join->organization:`{}` SET expires_at = {}",
            self.user_id, self.organization_id, expires_offset
        );

        let mut result = db
            .query(&query)
            .await
            .context("Failed to create join request")?;

        let records: Vec<RequestsToJoinRecord> = result
            .take(0)
            .context("Failed to get join request result")?;

        let record = records
            .into_iter()
            .next()
            .context("No record returned from RELATE")?;

        // The relation ID is a composite key, we use the string representation
        let id = record.id.key().to_string();

        Ok(JoinRequest {
            id,
            user_id: self.user_id,
            organization_id: self.organization_id,
        })
    }
}
