wit_bindgen::generate!({
    with: {
        "wasmcloud:messaging/consumer@0.2.0": wasmcloud_utils::wasmcloud::messaging::consumer,
        "wasmcloud:messaging/handler@0.2.0": wasmcloud_utils::wasmcloud::messaging::handler,
    },
    generate_all,
});

mod create;
mod join_requests;
mod watch;

use serde::{Deserialize, Serialize};
use wasmcloud_utils::{
    dispatch_actions,
    skir::base::organization::v1::organization::Organization,
    wasmcloud::messaging::{handler::Guest, types},
};

struct Component;
wasmcloud_utils::export!(Component);

#[derive(Debug, Serialize, Deserialize, Clone)]
pub struct OrganizationRecord {
    id: surrealdb_component_sdk::RecordId,
    name: String,
    logo_url: String,
}

impl From<OrganizationRecord> for Organization {
    fn from(value: OrganizationRecord) -> Self {
        Organization {
            organization_id: value.id.into(),
            name: value.name,
            logo_url: value.logo_url,
            _unrecognized: None,
        }
    }
}

impl Guest for Component {
    #[otel_wasi::wasi_instrument(service = "user_organization", export)]
    fn handle_message(msg: types::BrokerMessage) -> Result<(), otel_wasi::Error> {
        wit_bindgen::block_on(handle_message_async(msg))
    }
}

async fn handle_message_async(msg: types::BrokerMessage) -> Result<(), otel_wasi::Error> {
    dispatch_actions!(
        msg,
        "typewriter.from.user.<user_id>.organization.<action>",
        "create" => async create::handle_create,
        "watch" => async watch::handle_watch,
        "join_requests.watch" => async join_requests::handle_watch,
        "join_requests.request" => async join_requests::handle_request,
        "join_requests.cancel" => async join_requests::handle_cancel,
    )
}
