wit_bindgen::generate!({
    with: {
        "wasmcloud:messaging/consumer@0.3.0": wasmcloud_utils::wasmcloud::messaging::consumer,
        "wasmcloud:messaging/handler@0.3.0": wasmcloud_utils::wasmcloud::messaging::handler,
    },
    generate_all,
});

mod bind;
mod heartbeat;
mod shutdown;
mod status;
mod unbind;
mod update;
mod utils;
mod watch;

use std::fmt::Display;

use serde::{Deserialize, Serialize};
use wasmcloud_utils::{
    dispatch_actions,
    wasmcloud::messaging::{handler::Guest, parse_subject, types},
};

#[derive(Debug, Serialize, Deserialize, Clone)]
pub(crate) struct ServiceRegistrationRecord {
    pub token: String,
    pub expires_at: surrealdb_component_sdk::Datetime,
}

#[derive(Debug, Serialize, Deserialize, Clone)]
#[serde(rename_all = "lowercase")]
pub(crate) enum ServiceRoleTypeRecord {
    Engine,
    Realm,
    Custom,
}

#[derive(Debug, Serialize, Deserialize, Clone)]
pub(crate) struct ServiceRoleRecord {
    #[serde(rename = "type")]
    pub role_type: ServiceRoleTypeRecord,
    pub version: String,
    pub name: Option<String>,
}

#[derive(Debug, Serialize, Deserialize, Clone)]
#[serde(rename_all = "UPPERCASE")]
pub(crate) enum ServiceStatusRecord {
    Online,
    Offline,
}

impl Display for ServiceStatusRecord {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        match self {
            ServiceStatusRecord::Online => write!(f, "ONLINE"),
            ServiceStatusRecord::Offline => write!(f, "OFFLINE"),
        }
    }
}

#[derive(Debug, Serialize, Deserialize, Clone)]
pub(crate) struct ServiceStateRecord {
    pub status: ServiceStatusRecord,
    pub last_seen: surrealdb_component_sdk::Datetime,
}

#[derive(Debug, Serialize, Deserialize, Clone)]
pub(crate) struct ServiceRecord {
    pub id: surrealdb_component_sdk::RecordId,
    pub name: String,
    pub roles: Vec<ServiceRoleRecord>,
    pub created_at: surrealdb_component_sdk::Datetime,
    pub organization: Option<surrealdb_component_sdk::RecordId>,
    pub registration: Option<ServiceRegistrationRecord>,
    pub state: Option<ServiceStateRecord>,
    pub runs_in: Option<surrealdb_component_sdk::RecordId>,
}

#[derive(Debug, Serialize, Deserialize, Clone)]
pub(crate) struct OrganizationRecord {
    pub id: surrealdb_component_sdk::RecordId,
    pub name: String,
}

struct Component;
wasmcloud_utils::export!(Component);

impl Guest for Component {
    #[otel_wasi::wasi_instrument(service = "service_registration", export)]
    async fn handle_message(msg: types::BrokerMessage) -> Result<(), otel_wasi::Error> {
        handle_message_async(msg).await
    }
}

async fn handle_message_async(msg: types::BrokerMessage) -> Result<(), otel_wasi::Error> {
    if let Ok(params) = parse_subject(
        "[typewriter.from.]service.<service_id>.heartbeat",
        &msg.subject,
    ) {
        return heartbeat::handle_heartbeat(msg, params).await;
    }

    if let Ok(params) = parse_subject(
        "[typewriter.from.]service.<service_id>.shutdown",
        &msg.subject,
    ) {
        return shutdown::handle_shutdown(msg, params).await;
    }

    dispatch_actions!(
        msg,
        services: "[typewriter.from.]service.<service_id>",
        user_services: "[typewriter.from.]user.<user_id>.organization.<org_id>.services";
        "{services}.status" => async status::handle_status,
        "{user_services}.bind" => async bind::handle_bind,
        "{user_services}.watch" => async watch::handle_watch,
        "{user_services}.update" => async update::handle_update,
        "{user_services}.unbind" => async unbind::handle_unbind,
    )
}
