//! Role builder for seeding test data.

use anyhow::{Context, Result};
use serde::{Deserialize, Serialize};
use surrealdb::engine::remote::ws::Client;
use surrealdb::Surreal;

use super::organization::Organization;

/// A role record created in the database.
#[derive(Debug, Clone, Serialize, Deserialize)]
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
    pub async fn create(self, db: &Surreal<Client>) -> Result<Role> {
        let id = uuid::Uuid::new_v4().to_string();

        #[derive(Serialize)]
        struct CreateRole {
            name: String,
            organization: String, // Record link format
            color: i64,
            deletable: bool,
            assignable: bool,
            default_role: bool,
            priority: i32,
        }

        let _: Option<serde_json::Value> = db
            .create(("role", &id))
            .content(CreateRole {
                name: self.name.clone(),
                organization: format!("organization:{}", self.organization_id),
                color: self.color as i64,
                deletable: self.deletable,
                assignable: self.assignable,
                default_role: self.default_role,
                priority: self.priority,
            })
            .await
            .context("Failed to create role")?;

        Ok(Role {
            id,
            name: self.name,
            organization_id: self.organization_id,
            color: self.color,
            deletable: self.deletable,
            assignable: self.assignable,
            default_role: self.default_role,
            priority: self.priority,
        })
    }
}
