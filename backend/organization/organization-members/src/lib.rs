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
use wasmcloud_utils::{
    database::{RecordId, read_query},
    dispatch_actions,
    wasmcloud::messaging::{handler::Guest, types},
};

struct Component;
wasmcloud_utils::export!(Component);

#[derive(Debug)]
pub(crate) struct RoleValidation {
    pub missing: Vec<RecordId>,
    pub unassignable: Vec<RecordId>,
}

pub(crate) async fn validate_roles(
    organization_id: &RecordId,
    requested: &[RecordId],
    allowed_unassignable: &[RecordId],
    query_slug: &'static str,
    parse_slug: &'static str,
) -> Result<RoleValidation, otel_wasi::Error> {
    let found = read_query!("SELECT id, assignable FROM $roles WHERE organization = $org")
        .bind("roles", requested.to_vec())
        .bind("org", organization_id.clone())
        .execute()
        .await
        .error_with_slug(query_slug)?
        .take::<Vec<ValidatedRoleRecord>>()
        .error_with_slug(parse_slug)?;

    let missing: Vec<RecordId> = requested
        .iter()
        .filter(|id| !found.iter().any(|role| role.id == **id))
        .cloned()
        .collect();

    let unassignable: Vec<RecordId> = requested
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
    id: RecordId,
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
