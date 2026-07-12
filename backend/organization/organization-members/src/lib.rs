wit_bindgen::generate!({
    with: {
        "wasmcloud:messaging/consumer@0.2.0": wasmcloud_utils::wasmcloud::messaging::consumer,
        "wasmcloud:messaging/handler@0.2.0": wasmcloud_utils::wasmcloud::messaging::handler,
    },
    generate_all,
});

mod join_codes;
mod join_requests;
mod members;

use otel_wasi::ResultWithSlug;
use serde::{Deserialize, Serialize};
use surrealdb_component_sdk::{Datetime, query};
use wasmcloud_utils::{
    dispatch_actions,
    skir::base::organization::v1::{organization::Organization, role::OrganizationRole},
    wasmcloud::messaging::{handler::Guest, types},
};

struct Component;
wasmcloud_utils::export!(Component);

#[derive(Debug, Serialize, Deserialize, Clone)]
pub(crate) struct OrganizationRecord {
    pub id: surrealdb_component_sdk::RecordId,
    pub name: String,
    pub logo_url: Option<String>,
}

impl From<OrganizationRecord> for Organization {
    fn from(v: OrganizationRecord) -> Self {
        Self {
            organization_id: v.id.into(),
            name: v.name,
            logo_url: v.logo_url.unwrap_or_default(),
            _unrecognized: None,
        }
    }
}

#[derive(Debug, Serialize, Deserialize, Clone)]
pub(crate) struct UserRecord {
    pub id: surrealdb_component_sdk::RecordId,
    pub name: Option<String>,
    pub email: Option<String>,
    pub avatar_url: Option<String>,
}

#[derive(Debug, Serialize, Deserialize, Clone)]
pub(crate) struct RoleRecord {
    pub id: surrealdb_component_sdk::RecordId,
    pub name: String,
    pub color: i64,
    pub default_role: bool,
    pub assignable: bool,
    pub deletable: bool,
}
#[derive(Debug)]
pub(crate) struct RoleValidation {
    pub missing: Vec<surrealdb_component_sdk::RecordId>,
    pub unassignable: Vec<surrealdb_component_sdk::RecordId>,
}

fn classify_requested_roles(
    requested: &[surrealdb_component_sdk::RecordId],
) -> (
    Vec<surrealdb_component_sdk::RecordId>,
    Vec<surrealdb_component_sdk::RecordId>,
) {
    requested
        .iter()
        .cloned()
        .partition(|id| id.table == "organization_role")
}

pub(crate) async fn validate_roles(
    org_id: &str,
    requested: &[surrealdb_component_sdk::RecordId],
    allowed_unassignable: &[surrealdb_component_sdk::RecordId],
    query_slug: &'static str,
    parse_slug: &'static str,
) -> Result<RoleValidation, otel_wasi::Error> {
    let (requested_db, incorrectly_typed) = classify_requested_roles(requested);
    let found = query("SELECT id, assignable FROM $roles WHERE organization = $org")
        .bind("roles", requested_db.clone())
        .bind(
            "org",
            surrealdb_component_sdk::RecordId::new("organization", org_id),
        )
        .execute()
        .await
        .error_with_slug(query_slug)?
        .take::<Vec<ValidatedRoleRecord>>(0)
        .error_with_slug(parse_slug)?;

    let missing: Vec<surrealdb_component_sdk::RecordId> = requested
        .iter()
        .filter(|id| id.table != "organization_role" || !found.iter().any(|role| role.id == **id))
        .cloned()
        .collect();

    let unassignable: Vec<surrealdb_component_sdk::RecordId> = requested
        .iter()
        .filter(|id| id.table == "organization_role")
        .filter(|id| {
            found.iter().any(|role| role.id == **id && !role.assignable)
                && !allowed_unassignable.contains(&id)
        })
        .cloned()
        .collect();

    debug_assert_eq!(
        incorrectly_typed,
        missing
            .iter()
            .filter(|id| id.table != "organization_role")
            .cloned()
            .collect::<Vec<_>>()
    );
    Ok(RoleValidation {
        missing,
        unassignable,
    })
}

#[derive(Debug, Deserialize)]
struct ValidatedRoleRecord {
    id: surrealdb_component_sdk::RecordId,
    assignable: bool,
}

impl From<RoleRecord> for OrganizationRole {
    fn from(v: RoleRecord) -> Self {
        Self {
            role_id: v.id.into(),
            name: v.name,
            color: v.color.into(),
            default_role: v.default_role,
            assignable: v.assignable,
            deletable: v.deletable,
            _unrecognized: None,
        }
    }
}

#[derive(Debug, Serialize, Deserialize, Clone)]
pub(crate) struct MemberRecord {
    pub user_id: surrealdb_component_sdk::RecordId,
    pub name: Option<String>,
    pub email: Option<String>,
    pub avatar_url: Option<String>,
    pub roles: Vec<RoleRecord>,
    pub joined_at: Datetime,
}
impl From<MemberRecord>
    for wasmcloud_utils::skir::base::organization::v1::member::OrganizationMember
{
    fn from(v: MemberRecord) -> Self {
        Self {
            user_id: v.user_id.into(),
            name: v.name,
            email: v.email,
            avatar_url: v.avatar_url,
            roles: v.roles.into_iter().map(Into::into).collect(),
            joined_at: v.joined_at.into(),
            _unrecognized: None,
        }
    }
}

impl Guest for Component {
    #[otel_wasi::wasi_instrument(service = "organization_members", export)]
    fn handle_message(msg: types::BrokerMessage) -> Result<(), otel_wasi::Error> {
        wit_bindgen::block_on(handle_message_async(msg))
    }
}

async fn handle_message_async(msg: types::BrokerMessage) -> Result<(), otel_wasi::Error> {
    dispatch_actions!(msg, "typewriter.in.user.<user_id>.organization.<org_id>.members.<action>",
        "watch" => async members::handle_watch,
        "update" => async members::handle_update,
        "remove" => async members::handle_remove,
        "join_requests.watch" => async join_requests::handle_watch,
        "join_requests.approve" => async join_requests::handle_approve,
        "join_requests.decline" => async join_requests::handle_decline,
        "join_codes.watch" => async join_codes::handle_watch,
        "join_codes.generate" => async join_codes::handle_generate,
        "join_codes.revoke" => async join_codes::handle_revoke,
    )
}

#[cfg(test)]
mod tests {
    use super::classify_requested_roles;
    use surrealdb_component_sdk::{RecordId, RecordIdKey};

    fn id(table: &str, key: &str) -> RecordId {
        surrealdb_component_sdk::RecordId {
            table: table.to_owned(),
            key: RecordIdKey::String(key.to_owned()),
        }
    }

    #[test]
    fn classifies_only_organization_role_ids_as_queryable() {
        let valid = id("organization_role", "shared");
        let wrong_table = id("other_role", "shared");
        let another_valid = id("organization_role", "another");

        let (queryable, missing) = classify_requested_roles(&[
            wrong_table.clone(),
            valid.clone(),
            wrong_table.clone(),
            another_valid.clone(),
        ]);

        assert_eq!(
            queryable,
            vec![valid.into(), another_valid.into()],
            "wrong-table IDs must never be queried"
        );
        assert_eq!(missing, vec![wrong_table.clone(), wrong_table]);
    }
}
