//! Serves the organization service snapshot used to initialize the service watch.
//!
//! The snapshot is the initial state for consumers that then process service add, update, and
//! remove events on the same typed subject. Results are scoped to one organization and sorted by
//! service name so the initial order is deterministic.

use std::collections::HashMap;

use otel_wasi::ResultWithSlug;
use wasmcloud_utils::{
    database::{RecordId, read_query},
    decode_skir, extract_params,
    skir::base::service::v1::organization::{
        WatchOrganizationServicesRequest, WatchOrganizationServicesResponse,
    },
    wasmcloud::messaging::types::NatsMessage,
};

use wasmcloud_utils::database::service::ServiceRecord;

#[tracing::instrument(skip(msg, params))]
/// Decodes the watch request and returns the current services for its organization.
///
/// The user and organization path parameters identify the requested scope. The request body is
/// still decoded to enforce the Skir boundary, although the current request has no fields.
pub async fn handle_watch(
    msg: NatsMessage,
    params: HashMap<String, String>,
) -> Result<WatchOrganizationServicesResponse, otel_wasi::Error> {
    let (actor_id, org_id) = extract_params!(params, user_id, org_id)?;
    otel_wasi::main_attribute!(
        "actor.id" = actor_id.to_string(),
        "organization.id" = org_id.to_string()
    );
    let _ = decode_skir!(WatchOrganizationServicesRequest, &msg.body)?;

    snapshot(org_id).await
}

/// Reads one organization's service records in stable name order.
///
/// This helper is also the snapshot boundary used by the request handler. It returns a complete
/// list, while later service state changes use the typed update stream rather than being folded
/// into this query.
pub async fn snapshot(org_id: &str) -> Result<WatchOrganizationServicesResponse, otel_wasi::Error> {
    let organization_id = RecordId::new("organization", org_id);
    let records = read_query!(
        r#"
        SELECT * FROM service
        WHERE organization = $org_id
        ORDER BY name ASC
        "#,
    )
    .bind("org_id", organization_id)
    .execute()
    .await
    .error_with_slug("organization-services-watch-query-failed")?
    .take::<Vec<ServiceRecord>>()
    .error_with_slug("organization-services-watch-result-parse-failed")?;

    let services = records
        .into_iter()
        .map(TryInto::try_into)
        .collect::<Result<Vec<_>, _>>()?;
    otel_wasi::main_attribute!("service.result_count" = services.len() as i64);

    Ok(WatchOrganizationServicesResponse::List(services))
}
