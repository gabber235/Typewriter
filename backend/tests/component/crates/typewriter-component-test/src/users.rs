//! The people and organization every Typewriter test speaks about.
//!
//! `backend/tests/component/fixtures/stack-users.json` names the people once for component tests,
//! the local stack and the panel's integration tests: Ada owns the organization Acme, Grace belongs
//! to none. Component tests use the same names, so a case reads the same at every layer.

use std::{path::Path, sync::OnceLock};

use anyhow::{Context, Result};
use serde::Deserialize;
use wasmcloud_utils::skir::base::kernel::v1::record_id::RecordId;

use crate::skir_record_id;

/// A person the stack knows.
#[derive(Clone, Debug, Deserialize)]
pub struct StackUser {
    pub username: String,
    pub password: String,
    /// The identity provider's subject, which is also the user's record key and subject token.
    pub subject: String,
    /// Names of the organizations the person belongs to once the stack is provisioned.
    pub organizations: Vec<String>,
}

impl StackUser {
    /// Reads the fixture users from `path`.
    pub fn read_all(path: &Path) -> Result<Vec<StackUser>> {
        parse(
            &std::fs::read_to_string(path)
                .with_context(|| format!("cannot read {}", path.display()))?,
        )
        .with_context(|| format!("{} is not a user list", path.display()))
    }

    /// Someone else the case needs, such as a second applicant in a race. Prefer [`ada`] and
    /// [`grace`].
    pub fn new(username: &str) -> Self {
        Self {
            username: username.to_owned(),
            password: String::new(),
            subject: format!("user_{username}"),
            organizations: Vec::new(),
        }
    }

    /// The token that names the user in NATS subjects.
    pub fn token(&self) -> &str {
        &self.subject
    }

    /// The user's record.
    pub fn id(&self) -> RecordId {
        skir_record_id("user", &self.subject)
    }
}

fn parse(json: &str) -> Result<Vec<StackUser>> {
    Ok(serde_json::from_str(json)?)
}

fn stack_users() -> &'static [StackUser] {
    static USERS: OnceLock<Vec<StackUser>> = OnceLock::new();
    USERS.get_or_init(|| {
        parse(include_str!("../../../fixtures/stack-users.json"))
            .expect("stack-users.json is a user list")
    })
}

fn stack_user(username: &str) -> &'static StackUser {
    stack_users()
        .iter()
        .find(|user| user.username == username)
        .unwrap_or_else(|| panic!("stack-users.json names no `{username}`"))
}

/// The owner of Acme.
pub fn ada() -> &'static StackUser {
    stack_user("ada")
}

/// A person outside every organization.
pub fn grace() -> &'static StackUser {
    stack_user("grace")
}

/// An organization, named by the key of its record.
#[derive(Clone, Debug, PartialEq, Eq)]
pub struct Organization {
    pub key: String,
}

impl Organization {
    pub fn new(key: impl Into<String>) -> Self {
        Self { key: key.into() }
    }

    /// The organization a reply names by its record.
    pub fn from_id(id: &RecordId) -> Self {
        Self::new(id.key.to_string())
    }

    /// The organization's record.
    pub fn id(&self) -> RecordId {
        skir_record_id("organization", &self.key)
    }
}

/// The organization Ada owns.
pub fn acme() -> Organization {
    Organization::new("acme")
}
