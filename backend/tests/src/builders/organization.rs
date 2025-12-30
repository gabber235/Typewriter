//! Organization builder for seeding test data.

use anyhow::{Context, Result};
use serde::{Deserialize, Serialize};
use surrealdb::engine::any::Any;
use surrealdb::{RecordId, Surreal};
use uuid::Uuid;

/// An organization record created in the database.
#[derive(Debug, Clone, Deserialize)]
pub struct Organization {
    pub id: String,
    pub name: String,
    pub icon_url: String,
}

/// Data to be stored for an organization record.
#[derive(Debug, Serialize)]
struct OrganizationData {
    name: String,
    icon_url: String,
}

/// Record returned from SurrealDB create operation.
#[derive(Debug, Deserialize)]
struct OrganizationRecord {
    id: RecordId,
    name: String,
    icon_url: String,
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
    ///
    /// Uses string-type record keys to match what the component expects when using
    /// `type::thing('organization', $org_id)` in SurrealQL queries.
    pub async fn create(self, db: &Surreal<Any>) -> Result<Organization> {
        // Use string ID to match component's type::thing() usage
        let id = Uuid::new_v4().to_string();

        let data = OrganizationData {
            name: self.name,
            icon_url: self.icon_url,
        };

        let record: Option<OrganizationRecord> = db
            .create(("organization", &id))
            .content(data)
            .await
            .context("Failed to create organization")?;

        let record = record.context("No record returned from create")?;

        Ok(Organization {
            id,
            name: record.name,
            icon_url: record.icon_url,
        })
    }
}
