pub mod projections;

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

#[cfg(test)]
mod tests {
    use std::time::{Duration, SystemTime};

    use super::*;

    fn id(table: &str, key: &str) -> RecordId {
        RecordId::new(table, key)
    }

    #[test]
    fn organization_defaults_missing_logo_for_required_skir_field() {
        let organization: Organization = OrganizationRecord {
            id: id("organization", "writers"),
            name: "Writers".into(),
            logo_url: None,
        }
        .into();

        assert_eq!(organization.name, "Writers");
        assert_eq!(organization.logo_url, "");
        assert_eq!(organization.organization_id.table, "organization");
        assert_eq!(organization.organization_id.key.to_string(), "writers");
    }

    #[test]
    fn role_and_join_code_map_nested_database_values() {
        let role_id = id("organization_role", "writer");
        let role: OrganizationRole = OrganizationRoleRecord {
            id: role_id.clone(),
            name: "writer".into(),
            color: 0x53aad0,
            default_role: true,
            assignable: true,
            deletable: false,
        }
        .into();
        assert_eq!(role.role_id.key.to_string(), "writer");
        assert_eq!(role.name, "writer");
        assert!(role.default_role);
        assert!(!role.deletable);

        let created_at = SystemTime::UNIX_EPOCH + Duration::from_secs(123);
        let join_code: JoinCode = JoinCodeRecord {
            id: id("organization_join_code", "invite"),
            created_at: created_at.into(),
            expires_at: None,
            single_use: true,
            auto_accept_roles: vec![role_id],
        }
        .into();
        assert_eq!(join_code.code.key.to_string(), "invite");
        assert_eq!(join_code.created_at, created_at);
        assert_eq!(join_code.expires_at, None);
        assert!(join_code.single_use);
        assert_eq!(join_code.auto_accept.role_ids.len(), 1);
        assert_eq!(join_code.auto_accept.role_ids[0].key.to_string(), "writer");
    }
}
