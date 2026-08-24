use std::collections::HashMap;

use otel_wasi::ResultWithSlug;
use serde::Deserialize;
use wasmcloud_utils::{
    database::{
        RecordId, read_query,
        topology::{EngineInstanceViewRecord, RealmInstanceViewRecord, ServiceHostRecord},
    },
    decode_skir, extract_params,
    skir::base::service::v1::topology::{
        WatchOrganizationTopologyRequest, WatchOrganizationTopologyResponse,
        WatchOrganizationTopologyResponse_List,
    },
    skir_variant,
    wasmcloud::messaging::types::BrokerMessage,
};

#[derive(Debug, Deserialize)]
struct TopologyListRecord {
    hosts: Vec<ServiceHostRecord>,
    realms: Vec<RealmInstanceViewRecord>,
    engines: Vec<EngineInstanceViewRecord>,
}

#[tracing::instrument(skip(msg, params))]
pub async fn handle_watch(
    msg: BrokerMessage,
    params: HashMap<String, String>,
) -> Result<WatchOrganizationTopologyResponse, otel_wasi::Error> {
    let (actor_id, org_id) = extract_params!(params, user_id, org_id)?;
    let _ = decode_skir!(WatchOrganizationTopologyRequest, &msg.body)?;
    otel_wasi::main_attribute!(
        "actor.id" = actor_id.to_string(),
        "organization.id" = org_id.to_string(),
    );
    let organization_id = RecordId::new("organization", org_id);
    let topology = read_query!(
        r#"
        RETURN {
            hosts: (SELECT * FROM service_host
                WHERE service_id.organization = $organization_id
                ORDER BY id),
            realms: (SELECT
                    id,
                    revision,
                    target_engine,
                    state,
                    {
                        id: owner_host_id,
                        name: owner_host_id.service_id.name,
                    } AS owner_host
                FROM realm_instance
                WHERE owner_host_id.service_id.organization = $organization_id
                ORDER BY id),
            engines: (SELECT
                    id,
                    revision,
                    target,
                    state,
                    {
                        id: owner_host_id,
                        name: owner_host_id.service_id.name,
                    } AS owner_host,
                    {
                        realm_id: realm_id,
                        owner_host: {
                            id: realm_id.owner_host_id,
                            name: realm_id.owner_host_id.service_id.name,
                        },
                    } AS realm
                FROM engine_instance
                WHERE owner_host_id.service_id.organization = $organization_id
                ORDER BY id),
        };
        "#,
    )
    .bind("organization_id", organization_id)
    .execute()
    .await
    .error_with_slug("organization-topology-watch-query-failed")?
    .parse::<TopologyListRecord>()
    .error_with_slug("organization-topology-watch-result-parse-failed")?;
    otel_wasi::main_attribute!(
        "topology.host_count" = topology.hosts.len() as i64,
        "topology.realm_count" = topology.realms.len() as i64,
        "topology.engine_count" = topology.engines.len() as i64,
    );
    Ok(skir_variant!(WatchOrganizationTopologyResponse::List {
        hosts: topology.hosts.into_iter().map(Into::into).collect(),
        realms: topology.realms.into_iter().map(Into::into).collect(),
        engines: topology.engines.into_iter().map(Into::into).collect(),
    }))
}
