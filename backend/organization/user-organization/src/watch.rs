use std::collections::HashMap;

use otel_wasi::ResultWithSlug;
use surrealdb_component_sdk::query;
use wasmcloud_utils::{
    decode_skir, extract_param,
    skir::base::organization::v1::organization::{
        Organization, WatchUserOrganizationsRequest, WatchUserOrganizationsResponse,
    },
    wasmcloud::messaging::types::BrokerMessage,
};

use crate::OrganizationRecord;

pub async fn handle_watch(
    msg: BrokerMessage,
    params: HashMap<String, String>,
) -> Result<WatchUserOrganizationsResponse, otel_wasi::Error> {
    let user_id = extract_param!(params, user_id)?;
    let _request = decode_skir!(WatchUserOrganizationsRequest, &msg.body)?;

    let organizations = query(
        "SELECT VALUE ->member_of->organization.* AS orgs FROM type::thing('user', $user_id)",
    )
    .bind("user_id", user_id)
    .execute()
    .await
    .error_with_slug("organization-watch-query-failed")?
    .take::<Vec<OrganizationRecord>>(0)
    .error_with_slug("organization-watch-result-parse-failed")?
    .into_iter()
    .map(Organization::from)
    .collect::<Vec<_>>();

    Ok(WatchUserOrganizationsResponse::List(organizations))
}
