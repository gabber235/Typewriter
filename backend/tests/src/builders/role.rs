//! Role builder for seeding test data.

use anyhow::{Context, Result};
use serde::{Deserialize, Serialize};
use surrealdb::engine::any::Any;
use surrealdb::{RecordId, Surreal};
use uuid::Uuid;

use super::organization::Organization;

// Note: Uuid is still used for generating new IDs as strings via Uuid::new_v4().to_string()

/// A role record created in the database.
#[derive(Debug, Clone, Deserialize)]
pub struct Role {
    pub id: String,
    pub name: String,
    pub organization_id: String,
    pub color: u32,
    pub deletable: bool,
    pub assignable: bool,
    pub default_role: bool,
    pub priority: i32,
}

/// Data to be stored for a role record.
#[derive(Debug, Serialize)]
struct RoleData {
    name: String,
    organization: RecordId,
    color: i64,
    deletable: bool,
    assignable: bool,
    default_role: bool,
    priority: i32,
}

/// Record returned from SurrealDB create operation.
#[derive(Debug, Deserialize)]
struct RoleRecord {
    id: RecordId,
    name: String,
    organization: RecordId,
    color: i64,
    deletable: bool,
    assignable: bool,
    default_role: bool,
    priority: i32,
}

/// Builder for creating test roles.
pub struct RoleBuilder {
    name: String,
    organization_id: String,
    color: u32,
    deletable: bool,
    assignable: bool,
    default_role: bool,
    priority: i32,
}

impl RoleBuilder {
    /// Create a new role builder.
    ///
    /// Note: Role names must match the pattern `^[a-z0-9][a-z0-9_]{1,}[a-z0-9]$`
    pub fn new(name: impl Into<String>, org: &Organization) -> Self {
        Self {
            name: name.into(),
            organization_id: org.id.clone(),
            color: 0xFF9E9E9E, // Default neutral gray
            deletable: true,
            assignable: true,
            default_role: false,
            priority: 1,
        }
    }

    /// Set the role color (ARGB format).
    pub fn color(mut self, color: u32) -> Self {
        self.color = color;
        self
    }

    /// Mark this role as the default role.
    pub fn default_role(mut self) -> Self {
        self.default_role = true;
        self
    }

    /// Set the role priority.
    pub fn priority(mut self, priority: i32) -> Self {
        self.priority = priority;
        self
    }

    /// Make the role non-deletable.
    pub fn not_deletable(mut self) -> Self {
        self.deletable = false;
        self
    }

    /// Make the role non-assignable.
    pub fn not_assignable(mut self) -> Self {
        self.assignable = false;
        self
    }

    /// Create the role in the database.
    ///
    /// Uses string-type record keys to match what the component expects when using
    /// `type::thing('role', $role_id)` in SurrealQL queries.
    pub async fn create(self, db: &Surreal<Any>) -> Result<Role> {
        // Use string ID to match component's type::thing() usage
        let id = Uuid::new_v4().to_string();

        let data = RoleData {
            name: self.name,
            // Use string key for organization reference to match component's type::thing() usage
            organization: RecordId::from(("organization", self.organization_id.as_str())),
            color: self.color as i64,
            deletable: self.deletable,
            assignable: self.assignable,
            default_role: self.default_role,
            priority: self.priority,
        };

        let record: Option<RoleRecord> = db
            .create(("role", &id))
            .content(data)
            .await
            .context("Failed to create role")?;

        let record = record.context("No record returned from create")?;

        // Extract organization ID from the record
        let org_id = record.organization.key().to_string();

        Ok(Role {
            id,
            name: record.name,
            organization_id: org_id,
            color: record.color as u32,
            deletable: record.deletable,
            assignable: record.assignable,
            default_role: record.default_role,
            priority: record.priority,
        })
    }
}
