use std::collections::HashMap;

use otel_wasi::ResultWithSlug;
use wasmcloud_utils::{
    database::{RecordId, read_query},
    decode_skir, extract_params,
    skir::base::service::v1::organization::{
        WatchOrganizationServicesRequest, WatchOrganizationServicesResponse,
    },
    wasmcloud::messaging::types::BrokerMessage,
};

use wasmcloud_utils::database::service::ServiceRecord;

#[tracing::instrument(skip(msg, params))]
pub async fn handle_watch(
    msg: BrokerMessage,
    params: HashMap<String, String>,
) -> Result<WatchOrganizationServicesResponse, otel_wasi::Error> {
    let (actor_id, org_id) = extract_params!(params, user_id, org_id)?;
    otel_wasi::main_attribute!(
        "actor.id" = actor_id.to_string(),
        "organization.id" = org_id.to_string()
    );
    let _ = decode_skir!(WatchOrganizationServicesRequest, &msg.body)?;

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
