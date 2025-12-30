//! User builder for seeding test data.

use anyhow::{Context, Result};
use serde::{Deserialize, Serialize};
use surrealdb::engine::any::Any;
use surrealdb::{RecordId, Surreal};
use uuid::Uuid;

/// A user record created in the database.
#[derive(Debug, Clone, Deserialize)]
pub struct User {
    pub id: String,
    pub name: Option<String>,
    pub email: Option<String>,
    pub avatar_url: Option<String>,
}

/// Data to be stored for a user record.
#[derive(Debug, Serialize)]
struct UserData {
    name: Option<String>,
    email: Option<String>,
    avatar_url: Option<String>,
}

/// Record returned from SurrealDB create operation.
#[derive(Debug, Deserialize)]
struct UserRecord {
    id: RecordId,
    name: Option<String>,
    email: Option<String>,
    avatar_url: Option<String>,
}

/// Builder for creating test users.
pub struct UserBuilder {
    name: Option<String>,
    email: Option<String>,
    avatar_url: Option<String>,
}

impl UserBuilder {
    /// Create a new user builder with a name.
    pub fn new(name: impl Into<String>) -> Self {
        Self {
            name: Some(name.into()),
            email: None,
            avatar_url: None,
        }
    }

    /// Set the user's email.
    pub fn email(mut self, email: impl Into<String>) -> Self {
        self.email = Some(email.into());
        self
    }

    /// Set the user's avatar URL.
    pub fn avatar_url(mut self, url: impl Into<String>) -> Self {
        self.avatar_url = Some(url.into());
        self
    }

    /// Create the user in the database.
    ///
    /// Uses string-type record keys to match what the component expects when using
    /// `type::thing('user', $user_id)` in SurrealQL queries.
    pub async fn create(self, db: &Surreal<Any>) -> Result<User> {
        // Use string ID to match component's type::thing() usage
        let id = Uuid::new_v4().to_string();

        let data = UserData {
            name: self.name,
            email: self.email,
            avatar_url: self.avatar_url,
        };

        let record: Option<UserRecord> = db
            .create(("user", &id))
            .content(data)
            .await
            .context("Failed to create user")?;

        let record = record.context("No record returned from create")?;

        Ok(User {
            id,
            name: record.name,
            email: record.email,
            avatar_url: record.avatar_url,
        })
    }
}
