wit_bindgen::generate!({
    with: {
        "wasmcloud:messaging/consumer@0.2.0": wasmcloud_utils::wasmcloud::messaging::consumer,
        "wasmcloud:messaging/handler@0.2.0": wasmcloud_utils::wasmcloud::messaging::handler,
    },
    generate_all,
});

use prost::Message;
use wasmcloud_component::debug;
use wasmcloud_utils::wasmcloud::messaging::{handler::Guest, reply, types};

mod common;
mod services;
mod users;

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

struct TypewriterPermissions;
wasmcloud_utils::export!(TypewriterPermissions);

const PANEL_SUBJECT: &str = "auth.permissions.typewriter-panel";
const SERVICES_SUBJECT: &str = "auth.permissions.typewriter-services";

impl Guest for TypewriterPermissions {
    fn handle_message(msg: types::BrokerMessage) -> Result<(), String> {
        let request = typewriter::api::v1::PermissionRequest::decode(&msg.body[..])
            .map_err(|e| format!("failed to decode request: {}", e))?;

        let organization_id = request.organization_id;

        // Route based on the subject the message arrived on
        let (nats_permissions, tags) = match msg.subject.as_str() {
            PANEL_SUBJECT => {
                debug!("Handling panel user permission request");
                let claims: jose::jwt::Claims<common::AuthentikClaims> =
                    serde_json::from_slice(&request.jwt_claims).map_err(|e| e.to_string())?;
                users::handle_panel_user(claims, organization_id).map_err(|e| e.to_string())?
            }
            SERVICES_SUBJECT => {
                debug!("Handling service permission request");
                let claims: jose::jwt::Claims<services::ServiceClaims> =
                    serde_json::from_slice(&request.jwt_claims).map_err(|e| e.to_string())?;
                services::handle_service(claims, organization_id).map_err(|e| e.to_string())?
            }
            other => {
                return Err(format!("Unknown subject: {}", other));
            }
        };

        let response = common::build_permission_response(nats_permissions, tags);
        let response_bytes = response.encode_to_vec();

        reply(msg, response_bytes)
    }
}
