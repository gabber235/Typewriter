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
mod refresh;

use serde::{Deserialize, Serialize};
use surrealdb_component::{Datetime, RecordId};
use wasmcloud_component::debug;
use wasmcloud_utils::dispatch_actions;
use wasmcloud_utils::wasmcloud::messaging::handler::Guest;
use wasmcloud_utils::wasmcloud::messaging::types::BrokerMessage;

mod typewriter {
    pub mod models {
        pub mod v1 {
            include!("generated/typewriter.models.v1.rs");
        }
    }
    pub mod api {
        pub mod v1 {
            include!("generated/typewriter.api.v1.rs");
        }
    }
}

#[derive(Debug, Serialize, Deserialize, Clone)]
pub struct RoleRecord {
    id: RecordId,
    name: String,
    color: i64,
    default_role: bool,
    assignable: bool,
    deletable: bool,
}

impl From<RoleRecord> for typewriter::models::v1::Role {
    fn from(record: RoleRecord) -> Self {
        typewriter::models::v1::Role {
            id: record.id.id.to_string(),
            name: record.name,
            color: Some(typewriter::models::v1::Color {
                value: record.color as u32,
            }),
            default_role: record.default_role,
            assignable: record.assignable,
            deletable: record.deletable,
        }
    }
}

#[derive(Debug, Serialize, Deserialize, Clone)]
pub struct UserRecord {
    id: RecordId,
    name: Option<String>,
    email: Option<String>,
    avatar_url: Option<String>,
}

#[derive(Debug, Serialize, Deserialize, Clone)]
pub struct MemberWithRolesRecord {
    id: RecordId,
    user: UserRecord,
    roles: Vec<RoleRecord>,
    joined_at: Datetime,
}

impl From<MemberWithRolesRecord> for typewriter::models::v1::OrganizationMember {
    fn from(record: MemberWithRolesRecord) -> Self {
        typewriter::models::v1::OrganizationMember {
            id: record.user.id.id.to_string(),
            name: record.user.name.unwrap_or_default(),
            email: record.user.email.unwrap_or_default(),
            avatar_url: record.user.avatar_url.unwrap_or_default(),
            roles: record.roles.into_iter().map(|r| r.into()).collect(),
            joined_at: record.joined_at.into(),
        }
    }
}

#[derive(Debug, Serialize, Deserialize, Clone)]
pub struct JoinRequestRecord {
    id: RecordId,
    user: UserRecord,
    requested_at: Datetime,
    expires_at: Datetime,
}

impl Into<typewriter::models::v1::JoinRequest> for JoinRequestRecord {
    fn into(self) -> typewriter::models::v1::JoinRequest {
        typewriter::models::v1::JoinRequest {
            id: self.id.id.to_string(),
            user_id: self.user.id.id.to_string(),
            user_name: self.user.name.unwrap_or_default(),
            user_email: self.user.email.unwrap_or_default(),
            user_avatar_url: self.user.avatar_url.unwrap_or_default(),
            requested_at: self.requested_at.into(),
            expires_at: self.expires_at.into(),
        }
    }
}

#[derive(Debug, Serialize, Deserialize, Clone)]
pub struct JoinCodeRecord {
    id: RecordId,
    created_at: Datetime,
    expires_at: Option<Datetime>,
    created_by: RecordId,
    organization: RecordId,
    single_use: bool,
    auto_accept_roles: Vec<RecordId>,
}

impl Into<typewriter::models::v1::JoinCode> for JoinCodeRecord {
    fn into(self) -> typewriter::models::v1::JoinCode {
        typewriter::models::v1::JoinCode {
            code: self.id.id.to_string(),
            created_at: self.created_at.into(),
            expires_at: self.expires_at.map(|dt| dt.into()),
            single_use: self.single_use,
            auto_accept: (!self.auto_accept_roles.is_empty()).then(|| {
                typewriter::models::v1::JoinCodeAutoAccept {
                    role_ids: self
                        .auto_accept_roles
                        .into_iter()
                        .map(|r| r.id.to_string())
                        .collect(),
                }
            }),
        }
    }
}

struct OrganizationMembers;
wasmcloud_utils::export!(OrganizationMembers);

impl Guest for OrganizationMembers {
    fn handle_message(msg: BrokerMessage) -> Result<(), String> {
        debug!("Received message with subject: {}", msg.subject);
        dispatch_actions!(
            msg,
            "typewriter.in.user.<user_id>.organization.<org_id>.members.<action>",
            "list" => members::handle_list => members::internal_error_list,
            "update" => members::handle_update => members::internal_error_update,
            "remove" => members::handle_remove => members::internal_error_remove,
            "join_requests.list" => join_requests::handle_list => join_requests::internal_error_list,
            "join_requests.approve" => join_requests::handle_approve => join_requests::internal_error_approve,
            "join_requests.decline" => join_requests::handle_decline => join_requests::internal_error_decline,
            "join_codes.generate" => join_codes::handle_generate => join_codes::internal_error_generate,
            "join_codes.list" => join_codes::handle_list => join_codes::internal_error_list,
            "join_codes.revoke" => join_codes::handle_revoke => join_codes::internal_error_revoke,
        )
    }
}
