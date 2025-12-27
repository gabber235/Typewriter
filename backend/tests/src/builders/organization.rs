//! Organization builder for seeding test data.

use anyhow::{Context, Result};
use serde::{Deserialize, Serialize};
use surrealdb::engine::remote::ws::Client;
use surrealdb::Surreal;

/// An organization record created in the database.
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Organization {
    pub id: String,
    pub name: String,
    pub icon_url: String,
}

/// Builder for creating test organizations.
pub struct OrganizationBuilder {
    name: String,
    icon_url: String,
}

impl OrganizationBuilder {
    /// Create a new organization builder with a name.
    ///
    /// Note: Organization names must match the pattern `^[a-z0-9][a-z0-9_]{1,}[a-z0-9]$`
    pub fn new(name: impl Into<String>) -> Self {
        Self {
            name: name.into(),
            icon_url: "https://example.com/icon.png".to_string(),
        }
    }

    /// Set the organization's icon URL.
    pub fn icon_url(mut self, url: impl Into<String>) -> Self {
        self.icon_url = url.into();
        self
    }

    /// Create the organization in the database.
    pub async fn create(self, db: &Surreal<Client>) -> Result<Organization> {
        let id = uuid::Uuid::new_v4().to_string();

        #[derive(Serialize)]
        struct CreateOrg {
            name: String,
            icon_url: String,
        }

        let _: Option<serde_json::Value> = db
            .create(("organization", &id))
            .content(CreateOrg {
                name: self.name.clone(),
                icon_url: self.icon_url.clone(),
            })
            .await
            .context("Failed to create organization")?;

        Ok(Organization {
            id,
            name: self.name,
            icon_url: self.icon_url,
        })
    }
}
