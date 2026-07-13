wit_bindgen::generate!({
    with: {
        "wasmcloud:messaging/consumer@0.2.0": wasmcloud_utils::wasmcloud::messaging::consumer,
        "wasmcloud:messaging/handler@0.2.0": wasmcloud_utils::wasmcloud::messaging::handler,
    },
    generate_all,
});

mod bind;
mod heartbeat;
mod list;
mod notifications;
mod shutdown;
mod status;
mod unbind;
mod update;
mod utils;

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
pub struct RegistrationData {
    pub token: String,
    pub expires_at: Datetime,
}

#[derive(Debug, Serialize, Deserialize, Clone)]
pub struct ServiceMetadataRecord {
    pub engine_version: Option<String>,
    pub realm_version: Option<String>,
}

#[derive(Debug, Serialize, Deserialize, Clone)]
pub struct ServiceStateRecord {
    pub status: Option<String>,
    pub last_seen: Option<Datetime>,
}

#[derive(Debug, Serialize, Deserialize, Clone)]
pub struct ServiceRecord {
    pub id: RecordId,
    pub name: String,
    pub service_types: Vec<String>,
    pub created_at: Datetime,
    pub metadata: Option<ServiceMetadataRecord>,
    pub organization: Option<RecordId>,
    pub registration: Option<RegistrationData>,
    pub state: Option<ServiceStateRecord>,
}

#[derive(Debug, Serialize, Deserialize, Clone)]
pub struct OrganizationRecord {
    pub id: RecordId,
    pub name: String,
}

#[derive(Debug, Serialize, Deserialize, Clone)]
pub struct ServiceWithOrganizationRecord {
    pub id: RecordId,
    pub name: String,
    pub service_types: Vec<String>,
    pub organization: Option<OrganizationRecord>,
    pub registration: Option<RegistrationData>,
}

struct ServiceRegistration;
wasmcloud_utils::export!(ServiceRegistration);

impl Guest for ServiceRegistration {
    fn handle_message(msg: BrokerMessage) -> Result<(), String> {
        debug!("Received message with subject: {}", msg.subject);
        dispatch_actions!(
            msg,
            services: "[typewriter.from.]service.<service_id>",
            user_services: "[typewriter.from.]user.<user_id>.organization.<org_id>.services";
            "{services}.status" => status::handle_status => status::internal_error_status,
            "{services}.heartbeat" => heartbeat::handle_heartbeat,
            "{services}.shutdown" => shutdown::handle_shutdown,
            "{user_services}.bind" => bind::handle_bind => bind::internal_error_bind,
            "{user_services}.list" => list::handle_list => list::internal_error_list,
            "{user_services}.update" => update::handle_update => update::internal_error_update,
            "{user_services}.unbind" => unbind::handle_unbind => unbind::internal_error_unbind,
        )
    }
}
