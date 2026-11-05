//! Joined database read models for organization related views.
//!
//! Projections are query shaped values, not independent sources of truth. They carry the related
//! records needed by a particular caller and convert into the corresponding public view only at
//! the storage boundary.

use serde::{Deserialize, Serialize};
use surrealdb_component_sdk::{Datetime, RecordId};

use crate::skir::base::organization::v1::{
    join_request::{OrganizationJoinRequest, UserJoinRequest},
    member::OrganizationMember,
};

use super::{OrganizationRecord, OrganizationRoleRecord, UserRecord};

/// Join request with the user and organization data needed by either watch direction.
#[derive(Debug, Serialize, Deserialize, Clone)]
pub struct JoinRequestProjection {
    pub id: RecordId,
    pub user: UserRecord,
    pub organization: OrganizationRecord,
    pub requested_at: Datetime,
    pub expires_at: Datetime,
}

/// Organization member with roles joined for the organization members watch.
#[derive(Debug, Serialize, Deserialize, Clone)]
pub struct OrganizationMemberProjection {
    pub user_id: RecordId,
    pub name: Option<String>,
    pub email: Option<String>,
    pub avatar_url: Option<String>,
    pub roles: Vec<OrganizationRoleRecord>,
    pub joined_at: Datetime,
}

impl From<JoinRequestProjection> for OrganizationJoinRequest {
    fn from(value: JoinRequestProjection) -> Self {
        Self {
            request_id: value.id.into(),
            user_id: value.user.id.into(),
            user_name: value.user.name,
            user_email: value.user.email,
            user_avatar_url: value.user.avatar_url,
            requested_at: value.requested_at.into(),
            expires_at: value.expires_at.into(),
            _unrecognized: None,
        }
    }
}

impl From<JoinRequestProjection> for UserJoinRequest {
    fn from(value: JoinRequestProjection) -> Self {
        Self {
            request_id: value.id.into(),
            organization_id: value.organization.id.into(),
            organization_name: value.organization.name,
            organization_logo_url: value.organization.logo_url.unwrap_or_default(),
            requested_at: value.requested_at.into(),
            expires_at: value.expires_at.into(),
            _unrecognized: None,
        }
    }
}

impl From<OrganizationMemberProjection> for OrganizationMember {
    fn from(value: OrganizationMemberProjection) -> Self {
        Self {
            user_id: value.user_id.into(),
            name: value.name,
            email: value.email,
            avatar_url: value.avatar_url,
            roles: value.roles.into_iter().map(Into::into).collect(),
            joined_at: value.joined_at.into(),
            _unrecognized: None,
        }
    }
}
