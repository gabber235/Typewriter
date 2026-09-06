use std::collections::HashMap;

use otel_wasi::ResultWithSlug;
use serde::Deserialize;
use wasmcloud_utils::{
    database::{RecordId, transaction_query},
    decode_skir, extract_params,
    skir::base::service::v1::{
        organization::WatchOrganizationServicesResponse,
        registration::{
            UnbindServiceRequest, UnbindServiceResponse,
            UnbindServiceResponse_ServiceNotFoundError, UnbindServiceResponse_Success,
        },
        topology::WatchOrganizationTopologyResponse,
    },
    skir_variant,
    wasmcloud::messaging::types::BrokerMessage,
};

use wasmcloud_utils::database::service::ServiceRecord;

#[derive(Debug, Deserialize)]
struct UnbindResult {
    service: ServiceRecord,
    host_id: Option<RecordId>,
    realm_id: Option<RecordId>,
    engine_id: Option<RecordId>,
}

#[tracing::instrument(skip(msg, params))]
pub async fn handle_unbind(
    msg: BrokerMessage,
    params: HashMap<String, String>,
) -> Result<UnbindServiceResponse, otel_wasi::Error> {
    let (actor_id, org_id) = extract_params!(params, user_id, org_id)?;
    let request = decode_skir!(UnbindServiceRequest, &msg.body)?;
    otel_wasi::main_attribute!(
        "actor.id" = actor_id.to_string(),
        "organization.id" = org_id.to_string(),
        "service.id" = request.service_id.clone()
    );
    let service_id = RecordId::new("service", request.service_id.as_str());
    let organization_id = RecordId::new("organization", org_id);

    let result = transaction_query!(
        Option<UnbindResult>,
        r#"
        BEGIN TRANSACTION;

        RETURN {
            LET $services = SELECT * FROM $service_id
                WHERE organization = $organization_id;
            IF array::is_empty($services) {
                RETURN NONE
            };
            LET $service = array::first($services);
            LET $host_id = array::first(
                SELECT VALUE id FROM service_host WHERE service_id = $service_id
            );
            LET $realm_id = array::first(
                SELECT VALUE id FROM realm_instance WHERE owner_host_id = $host_id
            );
            LET $engine_id = array::first(
                SELECT VALUE id FROM engine_instance WHERE owner_host_id = $host_id
            );
            UPDATE ONLY $service_id SET
                organization = NONE,
                registration = NONE;
            RETURN {
                service: $service,
                host_id: $host_id,
                realm_id: $realm_id,
                engine_id: $engine_id,
            };
        };

        COMMIT TRANSACTION;
        "#,
    )
    .bind("service_id", service_id)
    .bind("organization_id", organization_id)
    .execute()
    .await
    .error_with_slug("service-unbind-query-failed")?
    .decode()
    .error_with_slug("service-unbind-result-parse-failed")?;
    let result = wasmcloud_utils::skir_domain_result!(UnbindServiceResponse, result);

    let Some(result) = result else {
        otel_wasi::main_attribute!("service.outcome" = "not_found");
        return Ok(skir_variant!(UnbindServiceResponse::ServiceNotFoundError));
    };

    let topology = wasmcloud_utils::skir_subjects::organization_topology(org_id);
    for resource_id in [result.engine_id, result.realm_id, result.host_id]
        .into_iter()
        .flatten()
    {
        topology
            .publish(WatchOrganizationTopologyResponse::ResourceRemoved(
                Box::new(resource_id.into()),
            ))
            .await?;
    }
    wasmcloud_utils::skir_subjects::organization_services(org_id)
        .publish(WatchOrganizationServicesResponse::Remove(Box::new(
            result.service.id.into(),
        )))
        .await?;

    otel_wasi::main_attribute!("service.outcome" = "unbound");
    Ok(skir_variant!(UnbindServiceResponse::Success))
}
