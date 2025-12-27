//! User builder for seeding test data.

use anyhow::{Context, Result};
use serde::{Deserialize, Serialize};
use surrealdb::engine::remote::ws::Client;
use surrealdb::Surreal;

/// A user record created in the database.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct User {
    pub id: String,
    pub name: Option<String>,
    pub email: Option<String>,
    pub avatar_url: Option<String>,
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
    pub async fn create(self, db: &Surreal<Client>) -> Result<User> {
        let id = uuid::Uuid::new_v4().to_string();

        #[derive(Serialize)]
        struct CreateUser {
            name: Option<String>,
            email: Option<String>,
            avatar_url: Option<String>,
        }

        let _: Option<serde_json::Value> = db
            .create(("user", &id))
            .content(CreateUser {
                name: self.name.clone(),
                email: self.email.clone(),
                avatar_url: self.avatar_url.clone(),
            })
            .await
            .context("Failed to create user")?;

        Ok(User {
            id,
            name: self.name,
            email: self.email,
            avatar_url: self.avatar_url,
        })
    }
}
