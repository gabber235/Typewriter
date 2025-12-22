wit_bindgen::generate!({
    with: {
        "wasmcloud:messaging/consumer@0.2.0": wasmcloud_utils::wasmcloud::messaging::consumer,
        "wasmcloud:messaging/handler@0.2.0": wasmcloud_utils::wasmcloud::messaging::handler,
    },
    generate_all,
});

mod create;
mod join_requests;
mod list;

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
pub struct OrganizationRecord {
    id: RecordId,
    name: String,
    icon_url: String,
    created_at: Datetime,
    updated_at: Datetime,
}

impl From<OrganizationRecord> for typewriter::models::v1::OrganizationData {
    fn from(record: OrganizationRecord) -> Self {
        typewriter::models::v1::OrganizationData {
            id: record.id.id.to_string(),
            name: record.name,
            icon_url: record.icon_url,
            created_at: record.created_at.into(),
            updated_at: record.updated_at.into(),
        }
    }
}

#[derive(Debug, Serialize, Deserialize, Clone)]
pub struct UserJoinRequestRecord {
    id: RecordId,
    organization: OrganizationRecord,
    requested_at: Datetime,
    expires_at: Datetime,
}

impl UserJoinRequestRecord {
    fn into_proto(self) -> typewriter::models::v1::UserJoinRequest {
        typewriter::models::v1::UserJoinRequest {
            id: self.id.id.to_string(),
            organization_id: self.organization.id.id.to_string(),
            organization_name: self.organization.name,
            organization_icon_url: self.organization.icon_url,
            requested_at: self.requested_at.into(),
            expires_at: self.expires_at.into(),
        }
    }
}

struct UserOrganizations;
wasmcloud_utils::export!(UserOrganizations);

impl Guest for UserOrganizations {
    fn handle_message(msg: BrokerMessage) -> Result<(), String> {
        debug!("Received message with subject: {}", msg.subject);
        dispatch_actions!(
            msg,
            "typewriter.in.user.<user_id>.organization.<action>",
            "create" => create::handle_create => create::internal_error_data,
            "list" => list::handle_list => list::internal_error_data,
            "join_requests.list" => join_requests::handle_list => join_requests::internal_error_list,
            "join_requests.request" => join_requests::handle_request => join_requests::internal_error_request,
            "join_requests.cancel" => join_requests::handle_cancel => join_requests::internal_error_cancel,
        )
    }
}
