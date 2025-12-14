wit_bindgen::generate!({
    with: {
        "wasmcloud:messaging/consumer@0.2.0": wasmcloud_utils::wasmcloud::messaging::consumer,
        "wasmcloud:messaging/handler@0.2.0": wasmcloud_utils::wasmcloud::messaging::handler,
    },
    generate_all,
});

use prost::Message;
use serde::{Deserialize, Serialize};
use std::collections::HashMap;
use surrealdb_component::query;
use wasmcloud_component::info;
use wasmcloud_utils::dispatch_actions;
use wasmcloud_utils::wasmcloud::messaging::{handler::Guest, reply, types::BrokerMessage};

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
struct OrganizationRecord {
    id: String,
    name: String,
    icon_url: String,
    created_at: Option<String>,
    updated_at: Option<String>,
}

impl From<OrganizationRecord> for typewriter::models::v1::OrganizationData {
    fn from(record: OrganizationRecord) -> Self {
        let parse_timestamp = |s: Option<String>| -> Option<prost_types::Timestamp> {
            s.and_then(|ts| {
                chrono::DateTime::parse_from_rfc3339(&ts)
                    .ok()
                    .map(|dt| prost_types::Timestamp {
                        seconds: dt.timestamp(),
                        nanos: dt.timestamp_subsec_nanos() as i32,
                    })
            })
        };

        typewriter::models::v1::OrganizationData {
            id: record.id,
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
        dispatch_actions!(
            msg,
            "user.<user_id>.organization.<action>",
            "list" => handle_list,
            "create" => handle_create,
        )
    }
}

fn handle_list(msg: BrokerMessage, params: HashMap<String, String>) -> Result<(), String> {
    let user_id = params
        .get("user_id")
        .ok_or("failed to parse user_id from subject")?;

    let _request = typewriter::api::v1::ListOrganizationsRequest::decode(&msg.body[..])
        .map_err(|e| format!("failed to decode request: {}", e))?;

    let result =
        query("SELECT ->member_of->organizations.* AS orgs FROM type::thing('user', $user_id)")
            .bind("user_id", user_id)
            .execute()
            .map_err(|e| format!("failed to query organizations: {}", e))?;

    let organizations_data: Vec<OrganizationRecord> = result
        .take(0)
        .map_err(|e| format!("failed to take result: {}", e))?;

    info!("organizations: {:?}", organizations_data);

    let organizations: Vec<typewriter::models::v1::OrganizationData> = organizations_data
        .into_iter()
        .map(|record| record.into())
        .collect();

    let response = typewriter::api::v1::ListOrganizationsResponse { organizations };

    let response_bytes = response.encode_to_vec();
    reply(msg, response_bytes)
}

fn handle_create(msg: BrokerMessage, params: HashMap<String, String>) -> Result<(), String> {
    let user_id = params
        .get("user_id")
        .ok_or("failed to parse user_id from subject")?;

    let request = typewriter::api::v1::CreateOrganizationRequest::decode(&msg.body[..])
        .map_err(|e| format!("failed to decode request: {}", e))?;

    let name = request.name;
    let icon_url = request.icon_url;

    info!(
        "Creating organization '{}' for user '{}' with icon '{}'",
        name, user_id, icon_url
    );

    let org_id = format!("org_{}", uuid::Uuid::new_v4());

    info!("Created organization with id: {}", org_id);

    let now = chrono::Utc::now();
    let timestamp = prost_types::Timestamp {
        seconds: now.timestamp(),
        nanos: now.timestamp_subsec_nanos() as i32,
    };

    let organization = typewriter::models::v1::OrganizationData {
        id: org_id.clone(),
        name,
        icon_url,
        created_at: Some(timestamp.clone()),
        updated_at: Some(timestamp),
    };

    let response = typewriter::api::v1::CreateOrganizationResponse {
        result: Some(
            typewriter::api::v1::create_organization_response::Result::Organization(organization),
        ),
    };

    let response_bytes = response.encode_to_vec();
    reply(msg, response_bytes)
}
