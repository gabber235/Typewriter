//! Member builder for seeding test data.

use anyhow::{Context, Result};
use surrealdb::engine::any::Any;
use surrealdb::Surreal;

use super::organization::Organization;
use super::role::Role;
use super::user::User;

/// Builder for creating member_of relationships (user -> organization).
pub struct MemberBuilder {
    user_id: String,
    organization_id: String,
    role_ids: Vec<String>,
}

impl MemberBuilder {
    /// Create a new member builder.
    pub fn new(user: &User, org: &Organization) -> Self {
        Self {
            user_id: user.id.clone(),
            organization_id: org.id.clone(),
            role_ids: Vec::new(),
        }
    }

    /// Add a role to the member.
    pub fn with_role(mut self, role: &Role) -> Self {
        self.role_ids.push(role.id.clone());
        self
    }

    /// Add multiple roles to the member.
    pub fn with_roles(mut self, roles: &[&Role]) -> Self {
        for role in roles {
            self.role_ids.push(role.id.clone());
        }
        self
    }

    /// Create the membership in the database.
    ///
    /// Uses raw RELATE query due to known issues with insert().relation() in SurrealDB Rust SDK.
    /// See: https://github.com/surrealdb/surrealdb/issues/5209
    ///
    /// Uses string-type record keys (backtick syntax) to match what the component expects when
    /// using `type::thing()` in SurrealQL queries.
    pub async fn create(self, db: &Surreal<Any>) -> Result<()> {
        if self.role_ids.is_empty() {
            anyhow::bail!("At least one role is required for membership");
        }

        // Use backtick syntax for string-type record keys to match component's type::thing() usage
        let roles: Vec<String> = self
            .role_ids
            .iter()
            .map(|id| format!("role:`{}`", id))
            .collect();

        let query = format!(
            "RELATE user:`{}`->member_of->organization:`{}` SET roles = [{}]",
            self.user_id,
            self.organization_id,
            roles.join(", ")
        );

        db.query(&query)
            .await
            .context("Failed to create membership")?;

        Ok(())
    }
}
