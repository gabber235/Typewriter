use std::collections::HashMap;

use otel_wasi::ResultWithSlug;
use surrealdb_component_sdk::query;
use wasmcloud_utils::{
    decode_skir, extract_params, otel_wasi,
    skir::base::organization::v1::role::{
        WatchOrganizationRolesRequest, WatchOrganizationRolesResponse,
    },
    wasmcloud::messaging::types::BrokerMessage,
};

use crate::OrganizationRoleRecord;

#[tracing::instrument(skip(msg, params))]
pub async fn handle_watch(
    msg: BrokerMessage,
    params: HashMap<String, String>,
) -> Result<WatchOrganizationRolesResponse, otel_wasi::Error> {
    let (actor_id, org_id) = extract_params!(params, user_id, org_id)?;
    otel_wasi::main_attribute!(
        "actor.id" = actor_id.to_string(),
        "organization.id" = org_id.to_string()
    );
    let _ = decode_skir!(WatchOrganizationRolesRequest, &msg.body)?;

    let roles = query(
        r#"
        SELECT * FROM organization_role
        WHERE organization = type::thing('organization', $org_id)
        ORDER BY priority DESC
        "#,
    )
    .bind("org_id", org_id)
    .execute()
    .await
    .error_with_slug("role-watch-query-failed")?
    .take::<Vec<OrganizationRoleRecord>>(0)
    .error_with_slug("role-watch-result-parse-failed")?
    .into_iter()
    .map(Into::into)
    .collect::<Vec<_>>();

    otel_wasi::main_attribute!(
        "role.outcome" = "listed",
        "role.result_count" = roles.len() as i64
    );
    Ok(WatchOrganizationRolesResponse::List(roles))
}
