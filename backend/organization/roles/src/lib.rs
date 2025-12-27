wit_bindgen::generate!({
    with: {
        "wasmcloud:messaging/consumer@0.2.0": wasmcloud_utils::wasmcloud::messaging::consumer,
        "wasmcloud:messaging/handler@0.2.0": wasmcloud_utils::wasmcloud::messaging::handler,
    },
    generate_all,
});

mod list;

use serde::{Deserialize, Serialize};
use surrealdb_component::RecordId;
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
    default_role: Option<bool>,
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
            default_role: record.default_role.unwrap_or(false),
            assignable: record.assignable,
            deletable: record.deletable,
        }
    }
}

struct OrganizationRoles;
wasmcloud_utils::export!(OrganizationRoles);

impl Guest for OrganizationRoles {
    fn handle_message(msg: BrokerMessage) -> Result<(), String> {
        debug!("Received message with subject: {}", msg.subject);
        dispatch_actions!(
            msg,
            "typewriter.in.user.<user_id>.organization.<org_id>.roles.<action>",
            "list" => list::handle_list => list::internal_error_data,
        )
    }
}
