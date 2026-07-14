use serde::{Deserialize, Serialize};
use surrealdb_component_sdk::{Datetime, RecordId};

use crate::skir::base::organization::v1::{
    join_request::{OrganizationJoinRequest, UserJoinRequest},
    member::OrganizationMember,
};

use super::{OrganizationRecord, OrganizationRoleRecord, UserRecord};

#[derive(Debug, Serialize, Deserialize, Clone)]
pub struct JoinRequestProjection {
    pub id: RecordId,
    pub user: UserRecord,
    pub organization: OrganizationRecord,
    pub requested_at: Datetime,
    pub expires_at: Datetime,
}

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

#[cfg(test)]
mod tests {
    use std::time::{Duration, SystemTime};

    use super::*;

    fn id(table: &str, key: &str) -> RecordId {
        RecordId::new(table, key)
    }

    fn join_request() -> JoinRequestProjection {
        JoinRequestProjection {
            id: id("request_to_join", "request"),
            user: UserRecord {
                id: id("user", "user"),
                name: Some("Writer".into()),
                email: Some("writer@example.com".into()),
                avatar_url: Some("https://example.com/avatar.png".into()),
            },
            organization: OrganizationRecord {
                id: id("organization", "organization"),
                name: "Organization".into(),
                logo_url: None,
            },
            requested_at: SystemTime::UNIX_EPOCH.into(),
            expires_at: (SystemTime::UNIX_EPOCH + Duration::from_secs(60)).into(),
        }
    }

    #[test]
    fn join_request_maps_both_reusable_views() {
        let organization_view: OrganizationJoinRequest = join_request().into();
        assert_eq!(organization_view.request_id.key.to_string(), "request");
        assert_eq!(organization_view.user_id.key.to_string(), "user");
        assert_eq!(organization_view.user_name.as_deref(), Some("Writer"));
        assert_eq!(
            organization_view.user_email.as_deref(),
            Some("writer@example.com")
        );
        assert_eq!(
            organization_view.user_avatar_url.as_deref(),
            Some("https://example.com/avatar.png")
        );

        let user_view: UserJoinRequest = join_request().into();
        assert_eq!(user_view.request_id.key.to_string(), "request");
        assert_eq!(user_view.organization_id.key.to_string(), "organization");
        assert_eq!(user_view.organization_name, "Organization");
        assert_eq!(user_view.organization_logo_url, "");
    }

    #[test]
    fn member_maps_nested_roles() {
        let joined_at = SystemTime::UNIX_EPOCH + Duration::from_secs(30);
        let member: OrganizationMember = OrganizationMemberProjection {
            user_id: id("user", "user"),
            name: Some("Writer".into()),
            email: None,
            avatar_url: None,
            roles: vec![OrganizationRoleRecord {
                id: id("organization_role", "writer"),
                name: "writer".into(),
                color: 42,
                default_role: true,
                assignable: true,
                deletable: false,
            }],
            joined_at: joined_at.into(),
        }
        .into();

        assert_eq!(member.user_id.key.to_string(), "user");
        assert_eq!(member.joined_at, joined_at);
        assert_eq!(member.roles.len(), 1);
        assert_eq!(member.roles[0].role_id.key.to_string(), "writer");
        assert_eq!(member.roles[0].name, "writer");
    }
}
