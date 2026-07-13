wit_bindgen::generate!({
    with: {
        "wasmcloud:messaging/consumer@0.2.0": wasmcloud_utils::wasmcloud::messaging::consumer,
        "wasmcloud:messaging/handler@0.2.0": wasmcloud_utils::wasmcloud::messaging::handler,
    },
    generate_all,
});

mod watch;

use serde::{Deserialize, Serialize};
use wasmcloud_utils::dispatch_actions;
use wasmcloud_utils::skir::base::organization::v1::role::OrganizationRole;
use wasmcloud_utils::wasmcloud::messaging::handler::Guest;
use wasmcloud_utils::wasmcloud::messaging::types::{self};

#[derive(Debug, Serialize, Deserialize, Clone)]
pub struct OrganizationRoleRecord {
    id: surrealdb_component_sdk::RecordId,
    name: String,
    color: i64,
    default_role: bool,
    assignable: bool,
    deletable: bool,
}

impl From<OrganizationRoleRecord> for OrganizationRole {
    fn from(value: OrganizationRoleRecord) -> Self {
        OrganizationRole {
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

struct Component;
wasmcloud_utils::export!(Component);

impl Guest for Component {
    #[otel_wasi::wasi_instrument(service = "organization_roles", export)]
    fn handle_message(msg: types::BrokerMessage) -> Result<(), otel_wasi::Error> {
        wit_bindgen::block_on(handle_message_async(msg))
    }
}

async fn handle_message_async(msg: types::BrokerMessage) -> Result<(), otel_wasi::Error> {
    dispatch_actions!(msg, "typewriter.from.user.<user_id>.organization.<org_id>.roles.<action>",
        "watch" => async watch::handle_watch,
    )
}
