wit_bindgen::generate!({
    with: {
        "wasmcloud:messaging/consumer@0.2.0": wasmcloud_utils::wasmcloud::messaging::consumer,
        "wasmcloud:messaging/handler@0.2.0": wasmcloud_utils::wasmcloud::messaging::handler,
    },
    generate_all,
});

mod create;
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
        let parse_timestamp = |dt: Datetime| -> Option<prost_types::Timestamp> {
            Some(prost_types::Timestamp {
                seconds: dt.timestamp(),
                nanos: dt.timestamp_subsec_nanos() as i32,
            })
        };

        typewriter::models::v1::OrganizationData {
            id: record.id.to_string(),
            name: record.name,
            icon_url: record.icon_url,
            created_at: parse_timestamp(record.created_at),
            updated_at: parse_timestamp(record.updated_at),
        }
    }
}

struct Organizations;
wasmcloud_utils::export!(Organizations);

impl Guest for Organizations {
    fn handle_message(msg: BrokerMessage) -> Result<(), String> {
        debug!("Received message with subject: {}", msg.subject);
        dispatch_actions!(
            msg,
            "typewriter.in.user.<user_id>.organization.<action>",
            "create" => create::handle_create, on_error: create::internal_error_data,
            "list" => list::handle_list,
        )
    }
}
