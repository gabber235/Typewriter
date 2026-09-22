//! Serves the organization topology snapshot used to initialize topology watches.
//!
//! A snapshot joins host, Realm, and engine records for one organization. Realm and engine
//! records are returned as views with owner context, matching the shapes used by configuration
//! and runtime update events. Each collection is ordered by record identifier for deterministic
//! initialization; subsequent changes arrive on the typed topology subject.

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
    wasmcloud::messaging::types::NatsMessage,
};

#[derive(Debug, Deserialize)]
struct TopologyListRecord {
    hosts: Vec<ServiceHostRecord>,
    realms: Vec<RealmInstanceViewRecord>,
    engines: Vec<EngineInstanceViewRecord>,
}

#[tracing::instrument(skip(msg, params))]
/// Decodes the topology watch request and returns the caller's organization snapshot.
///
/// The organization path parameter defines the query scope. The actor parameter is retained for
/// tracing context supplied by the subject, while the request body currently carries no fields
/// beyond the Skir boundary.
pub async fn handle_watch(
    msg: NatsMessage,
    params: HashMap<String, String>,
) -> Result<WatchOrganizationTopologyResponse, otel_wasi::Error> {
    let (actor_id, org_id) = extract_params!(params, user_id, org_id)?;
    let _ = decode_skir!(WatchOrganizationTopologyRequest, &msg.body)?;
    otel_wasi::main_attribute!(
        "actor.id" = actor_id.to_string(),
        "organization.id" = org_id.to_string(),
    );
    snapshot(org_id).await
}

/// Reads all topology resources belonging to one organization.
///
/// The query excludes resources owned by other organizations and projects Realm and engine rows
/// through the database view functions before serialization. The complete list initializes a
/// consumer; configuration and runtime handlers publish incremental topology events afterward.
pub async fn snapshot(org_id: &str) -> Result<WatchOrganizationTopologyResponse, otel_wasi::Error> {
    let organization_id = RecordId::new("organization", org_id);
    let topology = read_query!(
        r#"
        RETURN {
            hosts: (SELECT * FROM service_host
                WHERE service_id.organization = $organization_id
                ORDER BY id),
            realms: (
                (SELECT * FROM realm_instance
                    WHERE owner_host_id.service_id.organization = $organization_id
                    ORDER BY id)
                    .map(|$row| fn::service::realm_view($row))
            ),
            engines: (
                (SELECT * FROM engine_instance
                    WHERE owner_host_id.service_id.organization = $organization_id
                    ORDER BY id)
                    .map(|$row| fn::service::engine_view($row))
            ),
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
