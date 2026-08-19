use std::time::SystemTime;

use component_test::{TestContext, TestResult, component_test};
use json_matcher::assert_jm;
use typewriter_component_test::prelude::skir_record_id;
use wasmcloud_utils::skir::base::service::v1::topology::{
    ChildRuntimeState, ChildRuntimeStatus, ConfigureServiceHostRequest,
    ConfigureServiceHostResponse, EngineRealmSelection, EngineRealmSelection_ExistingRealm,
    EngineTarget, HostExecutionConfiguration, HostedEngineConfiguration,
    HostedRealmConfiguration, ReportHostExecutionRequest, ReportHostExecutionResponse,
    SemanticVersion, WatchHostExecutionRequest, WatchHostExecutionResponse,
    WatchOrganizationTopologyRequest, WatchOrganizationTopologyResponse,
};

use super::{ServiceRegistration, database, request};

const ORGANIZATION_TOPOLOGY_SUBJECT: &str = "typewriter.to.organization.test_org.topology.watch";
const HOST_EXECUTION_SUBJECT: &str = "typewriter.to.service.host_service.execution.watch";

#[component_test(ServiceRegistration)]
async fn watch_returns_first_class_topology_for_one_organization(
    context: &mut TestContext<ServiceRegistration>,
) -> TestResult {
    seed_paper_host(context, "host", "host_service").await?;
    let database = database(context)?;
    database
        .seed(
            "CREATE realm_instance:realm SET owner_host_id = service_host:host, target_engine = { engine_id: 'paper', major_version: 1 }; CREATE engine_instance:engine SET owner_host_id = service_host:host, realm_id = realm_instance:realm, target = { engine_id: 'paper', major_version: 1 }; CREATE service:other_service SET name = 'other_service', roles = [{ type: 'engine', version: '1' }], organization = organization:other_org; CREATE service_host:other_host SET service_id = service:other_service, entrypoint = 'PAPER', can_host_realm = true, supported_engines = [{ engine_id: 'paper', supported_major_versions: [1] }]",
        )
        .execute()
        .await?;

    let response: WatchOrganizationTopologyResponse = request(
        context,
        "typewriter.from.user.actor.organization.test_org.topology.watch",
        &WatchOrganizationTopologyRequest::default(),
        WatchOrganizationTopologyRequest::serializer(),
        WatchOrganizationTopologyResponse::serializer(),
    )
    .await?;

    let WatchOrganizationTopologyResponse::List(topology) = response else {
        anyhow::bail!("expected topology list");
    };
    assert_eq!(topology.hosts.len(), 1);
    assert_eq!(topology.realms.len(), 1);
    assert_eq!(topology.engines.len(), 1);
    assert_eq!(topology.hosts[0].host_id.key.to_string(), "host");
    Ok(())
}

#[component_test(ServiceRegistration)]
async fn configure_creates_local_realm_and_engine_transactionally(
    context: &mut TestContext<ServiceRegistration>,
) -> TestResult {
    seed_paper_host(context, "host", "host_service").await?;
    expect_publications(context, 3, 0, 1)?;

    let response = configure(
        context,
        1,
        HostExecutionConfiguration {
            realm: Some(HostedRealmConfiguration {
                target_engine: paper_target(),
                _unrecognized: None,
            }),
            engine: Some(HostedEngineConfiguration {
                target: paper_target(),
                realm: EngineRealmSelection::HostedRealm,
                _unrecognized: None,
            }),
            _unrecognized: None,
        },
    )
    .await?;

    let ConfigureServiceHostResponse::Success(configured) = response else {
        anyhow::bail!("expected successful combined configuration");
    };
    let realm = configured.realm.as_ref().expect("Realm must be returned");
    let engine = configured.engine.as_ref().expect("engine must be returned");
    assert_eq!(configured.host.revision, 2);
    assert_eq!(configured.host.desired_topology_revision, 1);
    assert_eq!(engine.realm_id, realm.realm_id);
    assert_eq!(realm.target_engine, paper_target());
    assert_eq!(engine.target, paper_target());
    assert_jm!(
        database(context)?
            .query_json("RETURN [(SELECT count() FROM realm_instance GROUP ALL)[0].count, (SELECT count() FROM engine_instance GROUP ALL)[0].count]")
            .await?,
        [1, 1]
    );
    Ok(())
}

#[component_test(ServiceRegistration)]
async fn configure_moves_engine_to_existing_realm_before_removing_local_realm(
    context: &mut TestContext<ServiceRegistration>,
) -> TestResult {
    seed_paper_host(context, "host", "host_service").await?;
    let database = database(context)?;
    database
        .seed(
            "CREATE service:realm_service SET name = 'realm_service', roles = [{ type: 'realm', version: '1' }], organization = organization:test_org; CREATE service_host:realm_host SET service_id = service:realm_service, entrypoint = 'STANDALONE', can_host_realm = true, supported_engines = [{ engine_id: 'paper', supported_major_versions: [1] }]; CREATE realm_instance:external_realm SET owner_host_id = service_host:realm_host, target_engine = { engine_id: 'paper', major_version: 1 }",
        )
        .execute()
        .await?;
    expect_publications(context, 3, 0, 1)?;
    let first = configure(context, 1, combined_execution()).await?;
    let ConfigureServiceHostResponse::Success(first) = first else {
        anyhow::bail!("expected initial combined configuration");
    };
    first.realm.expect("local Realm must exist");

    expect_publications(context, 2, 1, 1)?;
    let response = configure(
        context,
        2,
        HostExecutionConfiguration {
            realm: None,
            engine: Some(HostedEngineConfiguration {
                target: paper_target(),
                realm: EngineRealmSelection::ExistingRealm(Box::new(
                    EngineRealmSelection_ExistingRealm {
                        realm_id: skir_record_id("realm_instance", "external_realm"),
                        _unrecognized: None,
                    },
                )),
                _unrecognized: None,
            }),
            _unrecognized: None,
        },
    )
    .await?;

    let ConfigureServiceHostResponse::Success(configured) = response else {
        anyhow::bail!("expected distributed configuration");
    };
    assert!(configured.realm.is_none());
    assert_eq!(
        configured
            .engine
            .expect("engine must exist")
            .realm_id
            .key
            .to_string(),
        "external_realm"
    );
    assert_jm!(
        database
            .query_json("RETURN array::is_empty(SELECT * FROM realm_instance WHERE owner_host_id = service_host:host)")
            .await?,
        true
    );
    Ok(())
}

#[component_test(ServiceRegistration)]
async fn configure_rejects_invalid_relationships_without_partial_writes(
    context: &mut TestContext<ServiceRegistration>,
) -> TestResult {
    seed_standalone_host(context, "host", "host_service").await?;

    let invalid_engine = configure(
        context,
        1,
        HostExecutionConfiguration {
            realm: None,
            engine: Some(HostedEngineConfiguration {
                target: paper_target(),
                realm: EngineRealmSelection::ExistingRealm(Box::new(
                    EngineRealmSelection_ExistingRealm {
                        realm_id: skir_record_id("realm_instance", "missing"),
                        _unrecognized: None,
                    },
                )),
                _unrecognized: None,
            }),
            _unrecognized: None,
        },
    )
    .await?;
    assert!(matches!(
        invalid_engine,
        ConfigureServiceHostResponse::InvalidConfigurationError(_)
    ));

    let incompatible = configure(
        context,
        1,
        HostExecutionConfiguration {
            realm: Some(HostedRealmConfiguration {
                target_engine: EngineTarget {
                    engine_id: "paper".into(),
                    major_version: 2,
                    _unrecognized: None,
                },
                _unrecognized: None,
            }),
            engine: None,
            _unrecognized: None,
        },
    )
    .await?;
    assert!(matches!(
        incompatible,
        ConfigureServiceHostResponse::IncompatibleEngineError(_)
    ));
    assert_jm!(
        database(context)?
            .query_json("RETURN [service_host:host.revision, array::is_empty(SELECT * FROM realm_instance), array::is_empty(SELECT * FROM engine_instance)]")
            .await?,
        [1, true, true]
    );
    Ok(())
}

#[component_test(ServiceRegistration)]
async fn configure_returns_conflict_for_stale_host_revision(
    context: &mut TestContext<ServiceRegistration>,
) -> TestResult {
    seed_paper_host(context, "host", "host_service").await?;
    let response = configure(context, 0, HostExecutionConfiguration::default()).await?;
    let ConfigureServiceHostResponse::ConflictError(conflict) = response else {
        anyhow::bail!("expected host conflict");
    };
    assert_eq!(conflict.actual.revision, 1);
    Ok(())
}

#[component_test(ServiceRegistration)]
async fn configure_blocks_realm_removal_while_another_host_depends_on_it(
    context: &mut TestContext<ServiceRegistration>,
) -> TestResult {
    seed_standalone_host(context, "host", "host_service").await?;
    let database = database(context)?;
    database
        .seed(
            "CREATE realm_instance:shared_realm SET owner_host_id = service_host:host, target_engine = { engine_id: 'paper', major_version: 1 }; CREATE service:paper_service SET name = 'paper_service', roles = [{ type: 'engine', version: '1' }], organization = organization:test_org; CREATE service_host:paper_host SET service_id = service:paper_service, entrypoint = 'PAPER', can_host_realm = true, supported_engines = [{ engine_id: 'paper', supported_major_versions: [1] }]; CREATE engine_instance:remote_engine SET owner_host_id = service_host:paper_host, realm_id = realm_instance:shared_realm, target = { engine_id: 'paper', major_version: 1 }",
        )
        .execute()
        .await?;

    let response = configure(context, 1, HostExecutionConfiguration::default()).await?;
    assert!(matches!(
        response,
        ConfigureServiceHostResponse::InvalidConfigurationError(_)
    ));
    assert_jm!(
        database
            .query_json("RETURN [service_host:host.revision, realm_instance:shared_realm.owner_host_id, engine_instance:remote_engine.realm_id]")
            .await?,
        [1, "service_host:host", "realm_instance:shared_realm"]
    );
    Ok(())
}

#[component_test(ServiceRegistration)]
async fn host_watch_and_report_apply_only_current_topology_revision(
    context: &mut TestContext<ServiceRegistration>,
) -> TestResult {
    seed_paper_host(context, "host", "host_service").await?;
    let database = database(context)?;
    database
        .seed(
            "UPDATE service_host:host SET desired_topology_revision = 4; CREATE realm_instance:realm SET owner_host_id = service_host:host, target_engine = { engine_id: 'paper', major_version: 1 }, desired_manifest_revision = 2",
        )
        .execute()
        .await?;

    let desired: WatchHostExecutionResponse = request(
        context,
        "typewriter.from.service.host_service.execution.watch",
        &WatchHostExecutionRequest {
            host_id: skir_record_id("service_host", "host"),
            _unrecognized: None,
        },
        WatchHostExecutionRequest::serializer(),
        WatchHostExecutionResponse::serializer(),
    )
    .await?;
    assert!(matches!(
        desired,
        WatchHostExecutionResponse::Desired(value)
            if value.topology_revision == 4 && value.realm.is_some() && value.engine.is_none()
    ));

    let stale = report(context, 3, active_state()).await?;
    assert!(matches!(
        stale,
        ReportHostExecutionResponse::StaleRevisionError(_)
    ));

    expect_publications(context, 2, 0, 0)?;
    let applied = report(context, 4, active_state()).await?;
    assert!(matches!(
        applied,
        ReportHostExecutionResponse::Success(_)
    ));
    assert_jm!(
        database
            .query_json("RETURN [service_host:host.applied_topology_revision, service_host:host.state.status, realm_instance:realm.applied_manifest_revision, realm_instance:realm.state.status]")
            .await?,
        [4, "ACTIVE", 2, "ACTIVE"]
    );
    Ok(())
}

async fn configure(
    context: &mut TestContext<ServiceRegistration>,
    expected_revision: i64,
    execution: HostExecutionConfiguration,
) -> anyhow::Result<ConfigureServiceHostResponse> {
    request(
        context,
        "typewriter.from.user.actor.organization.test_org.topology.configure",
        &ConfigureServiceHostRequest {
            host_id: skir_record_id("service_host", "host"),
            expected_revision,
            execution,
            _unrecognized: None,
        },
        ConfigureServiceHostRequest::serializer(),
        ConfigureServiceHostResponse::serializer(),
    )
    .await
}

async fn report(
    context: &mut TestContext<ServiceRegistration>,
    topology_revision: i64,
    state: ChildRuntimeState,
) -> anyhow::Result<ReportHostExecutionResponse> {
    request(
        context,
        "typewriter.from.service.host_service.execution.report",
        &ReportHostExecutionRequest {
            host_id: skir_record_id("service_host", "host"),
            topology_revision,
            realm_state: Some(state),
            engine_state: None,
            _unrecognized: None,
        },
        ReportHostExecutionRequest::serializer(),
        ReportHostExecutionResponse::serializer(),
    )
    .await
}

fn combined_execution() -> HostExecutionConfiguration {
    HostExecutionConfiguration {
        realm: Some(HostedRealmConfiguration {
            target_engine: paper_target(),
            _unrecognized: None,
        }),
        engine: Some(HostedEngineConfiguration {
            target: paper_target(),
            realm: EngineRealmSelection::HostedRealm,
            _unrecognized: None,
        }),
        _unrecognized: None,
    }
}

fn paper_target() -> EngineTarget {
    EngineTarget {
        engine_id: "paper".into(),
        major_version: 1,
        _unrecognized: None,
    }
}

fn active_state() -> ChildRuntimeState {
    ChildRuntimeState {
        status: ChildRuntimeStatus::Active,
        active_artifact_version: Some(SemanticVersion {
            major: 1,
            minor: 0,
            patch: 0,
            _unrecognized: None,
        }),
        message: None,
        updated_at: SystemTime::now(),
        _unrecognized: None,
    }
}

async fn seed_paper_host(
    context: &TestContext<ServiceRegistration>,
    host_id: &str,
    service_id: &str,
) -> anyhow::Result<()> {
    seed_host(context, host_id, service_id, "PAPER").await
}

async fn seed_standalone_host(
    context: &TestContext<ServiceRegistration>,
    host_id: &str,
    service_id: &str,
) -> anyhow::Result<()> {
    seed_host(context, host_id, service_id, "STANDALONE").await
}

async fn seed_host(
    context: &TestContext<ServiceRegistration>,
    host_id: &str,
    service_id: &str,
    entrypoint: &str,
) -> anyhow::Result<()> {
    database(context)?
        .seed(format!(
            "CREATE user:actor SET name = 'actor'; CREATE user:other SET name = 'other'; CREATE organization:test_org SET name = 'test_org', founder = user:actor; CREATE organization:other_org SET name = 'other_org', founder = user:other; CREATE service:{service_id} SET name = '{service_id}', roles = [{{ type: 'engine', version: '1' }}], organization = organization:test_org; CREATE service_host:{host_id} SET service_id = service:{service_id}, entrypoint = '{entrypoint}', can_host_realm = true, supported_engines = [{{ engine_id: 'paper', supported_major_versions: [1] }}]",
        ))
        .execute()
        .await?;
    Ok(())
}

fn expect_publications(
    context: &TestContext<ServiceRegistration>,
    topology_updates: usize,
    removals: usize,
    host_updates: usize,
) -> anyhow::Result<()> {
    let messaging = context.messaging_mock()?;
    for _ in 0..topology_updates + removals {
        messaging.expect_publish(ORGANIZATION_TOPOLOGY_SUBJECT);
    }
    for _ in 0..host_updates {
        messaging.expect_publish(HOST_EXECUTION_SUBJECT);
    }
    Ok(())
}
