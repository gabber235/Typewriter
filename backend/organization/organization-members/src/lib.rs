wit_bindgen::generate!({
    with: {
        "wasmcloud:messaging/consumer@0.4.0": wasmcloud_utils::wasmcloud::messaging::consumer,
        "wasmcloud:messaging/handler@0.4.0": wasmcloud_utils::wasmcloud::messaging::handler,
    },
    generate_all,
});

mod join_codes;
mod join_requests;
mod members;

use otel_wasi::ResultWithSlug;
use serde::Deserialize;
use surrealdb_component_sdk::query;
use wasmcloud_utils::{
    dispatch_actions,
    wasmcloud::messaging::{handler::Guest, types},
};

struct Component;
wasmcloud_utils::export!(Component);

#[derive(Debug)]
pub(crate) struct RoleValidation {
    pub missing: Vec<surrealdb_component_sdk::RecordId>,
    pub unassignable: Vec<surrealdb_component_sdk::RecordId>,
}

pub(crate) async fn validate_roles(
    org_id: &str,
    requested: &[surrealdb_component_sdk::RecordId],
    allowed_unassignable: &[surrealdb_component_sdk::RecordId],
    query_slug: &'static str,
    parse_slug: &'static str,
) -> Result<RoleValidation, otel_wasi::Error> {
    let found = query("SELECT id, assignable FROM $roles WHERE organization = $org")
        .bind("roles", requested.to_vec())
        .bind(
            "org",
            surrealdb_component_sdk::RecordId::new("organization", org_id),
        )
        .execute()
        .await
        .error_with_slug(query_slug)?
        .take::<Vec<ValidatedRoleRecord>>(0)
        .error_with_slug(parse_slug)?;

    let missing: Vec<surrealdb_component_sdk::RecordId> = requested
        .iter()
        .filter(|id| !found.iter().any(|role| role.id == **id))
        .cloned()
        .collect();

    let unassignable: Vec<surrealdb_component_sdk::RecordId> = requested
        .iter()
        .filter(|id| {
            found.iter().any(|role| role.id == **id && !role.assignable)
                && !allowed_unassignable.contains(id)
        })
        .cloned()
        .collect();
    Ok(RoleValidation {
        missing,
        unassignable,
    })
}

#[derive(Debug, Deserialize)]
struct ValidatedRoleRecord {
    id: surrealdb_component_sdk::RecordId,
    assignable: bool,
}

impl Guest for Component {
    #[otel_wasi::wasi_instrument(service = "organization-members", export)]
    async fn handle_message(msg: types::BrokerMessage) -> Result<(), otel_wasi::Error> {
        handle_message_async(msg).await
    }
}

async fn handle_message_async(msg: types::BrokerMessage) -> Result<(), otel_wasi::Error> {
    dispatch_actions!(msg, "typewriter.from.user.<user_id>.organization.<org_id>.members.<action>",
        "watch" => async members::handle_watch,
        "update" => async members::handle_update,
        "remove" => async members::handle_remove,
        "join_requests.watch" => async join_requests::handle_watch,
        "join_requests.approve" => async join_requests::handle_approve,
        "join_requests.decline" => async join_requests::handle_decline,
        "join_codes.watch" => async join_codes::handle_watch,
        "join_codes.generate" => async join_codes::handle_generate,
        "join_codes.revoke" => async join_codes::handle_revoke,
    )
}
