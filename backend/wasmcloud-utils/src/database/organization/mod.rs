//! Database records, read projections, and snapshots for organizations.
//!
//! Record types preserve storage shapes. Projections and snapshots assemble read models for
//! callers and watches, then convert them into public SKIR values at the boundary.

pub mod projections;
pub mod snapshots;

use serde::{Deserialize, Serialize};
use surrealdb_component_sdk::{Datetime, RecordId};

use crate::{
    skir::base::organization::v1::{
        join_codes::{JoinCode, JoinCode_AutoAccept},
        organization::Organization,
        role::OrganizationRole,
    },
    skir_utils::IntoSkirRecordIds,
};

#[derive(Debug, Serialize, Deserialize, Clone)]
pub struct OrganizationRecord {
    pub id: RecordId,
    pub name: String,
    pub logo_url: Option<String>,
}

/// Stored user fields embedded in organization projections.
#[derive(Debug, Serialize, Deserialize, Clone)]
pub struct UserRecord {
    pub id: RecordId,
    pub name: Option<String>,
    pub email: Option<String>,
    pub avatar_url: Option<String>,
}

#[derive(Debug, Serialize, Deserialize, Clone)]
pub struct OrganizationRoleRecord {
    pub id: RecordId,
    pub name: String,
    pub color: i64,
    pub default_role: bool,
    pub assignable: bool,
    pub deletable: bool,
}

#[derive(Debug, Serialize, Deserialize)]
pub struct JoinCodeRecord {
    pub id: RecordId,
    pub created_at: Datetime,
    pub expires_at: Option<Datetime>,
    pub single_use: bool,
    pub auto_accept_roles: Vec<RecordId>,
}

/// Uses an empty logo URL when the stored organization has no logo.
impl From<OrganizationRecord> for Organization {
    fn from(value: OrganizationRecord) -> Self {
        Self {
            organization_id: value.id.into(),
            name: value.name,
            logo_url: value.logo_url.unwrap_or_default(),
            _unrecognized: None,
        }
    }
}

impl From<OrganizationRoleRecord> for OrganizationRole {
    fn from(value: OrganizationRoleRecord) -> Self {
        Self {
            role_id: value.id.into(),
            name: value.name,
            color: value.color.into(),
            default_role: value.default_role,
            assignable: value.assignable,
            deletable: value.deletable,
            _unrecognized: None,
        }
    }
}

impl From<JoinCodeRecord> for JoinCode {
    fn from(value: JoinCodeRecord) -> Self {
        Self {
            code: value.id.into(),
            created_at: value.created_at.into(),
            expires_at: value.expires_at.map(Into::into),
            single_use: value.single_use,
            auto_accept: JoinCode_AutoAccept {
                role_ids: value.auto_accept_roles.into_skir_record_ids(),
                _unrecognized: None,
            },
            _unrecognized: None,
        }
    }
}
