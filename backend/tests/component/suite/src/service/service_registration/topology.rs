use std::time::SystemTime;

use json_matcher::assert_jm;
use typewriter_component_test::prelude::*;
use wasmcloud_utils::skir::base::service::v1::topology::{
    ChildRuntimeState, ChildRuntimeStatus, ConfigureServiceHostResponse, EngineTarget,
    GetServiceMessagingScopeRequest, GetServiceMessagingScopeResponse, HostExecutionConfiguration,
    HostRuntimeStatus, OrganizationTopologyChanged, RegisterServiceHostRequest,
    RegisterServiceHostResponse, ReportHostExecutionRequest, ReportHostExecutionResponse,
    SupportedEngine, WatchHostExecutionRequest, WatchHostExecutionResponse,
    WatchOrganizationTopologyRequest, WatchOrganizationTopologyResponse,
};

use super::{
    Context, ServiceRegistration, acme_with_service, arrange_configuration, configure, engine_in,
    from_service, globex, host_id, paper, realm_only, realm_with_engine, register_host, to_service,
};

/// Acme with one bound service per host, each registered as a host that runs its engines.
async fn acme_with_hosts(context: &Context, hosts: &[(&str, &[&str])]) -> anyhow::Result<()> {
    let mut seed = Seed::new().organization(&acme(), ada());
    for (key, _) in hosts {
        seed = seed.organization_service(&acme(), key);
    }
    seed.apply(&context.database()?).await?;
    for (key, engines) in hosts {
        register_host(context, key, engines).await?;
    }
    Ok(())
}

fn custom_engine() -> EngineTarget {
    EngineTarget {
        engine_id: "custom_engine".into(),
        version_constraint: "^0.1".into(),
        ..Default::default()
    }
}

/// Expects Acme's topology watchers to receive the accepted configuration of a host.
fn expect_configuration_event(
    context: &Context,
    matches: impl Fn(
        &wasmcloud_utils::skir::base::service::v1::topology::HostConfigurationChange,
    ) -> bool
    + Send
    + Sync
    + 'static,
) -> TestResult {
    context.expect_publish(
        to_organization(&acme(), "topology.watch"),
        move |event: &OrganizationTopologyChanged| {
            matches!(event, OrganizationTopologyChanged::ConfigurationChanged(change) if matches(change))
        },
    )?;
    Ok(())
}

/// Expects the host `key` to be told its new desired execution.
fn expect_desired_execution(
    context: &Context,
    key: &str,
    matches: impl Fn(&WatchHostExecutionResponse) -> bool + Send + Sync + 'static,
) -> TestResult {
    context.expect_publish(to_service(key, "execution.watch"), matches)?;
    Ok(())
}

/// States that neither Acme's topology watchers nor the host `key` hear of a change.
fn expect_no_topology_event(context: &Context, key: &str) -> TestResult {
    context.expect_no_publish(to_organization(&acme(), "topology.watch"))?;
    context.expect_no_publish(to_service(key, "execution.watch"))?;
    Ok(())
}

/// The host revision and the number of Realms and engines in the database.
async fn topology_state(context: &Context, key: &str) -> anyhow::Result<serde_json::Value> {
    context
        .database()?
        .seed("RETURN [$host.revision, count(SELECT id FROM realm_instance), count(SELECT id FROM engine_instance)]")
        .bind("host", surrealdb_types::RecordId::from(host_id(key)))?
        .query_json()
        .await
}

/// The applied revision and status of lobby's host and the state of its Realm.
async fn execution_state(context: &Context) -> anyhow::Result<serde_json::Value> {
    context
        .database()?
        .query_json("RETURN [service_host:lobby.topology_revision.applied, service_host:lobby.state, (SELECT VALUE state FROM realm_instance WHERE owner_host_id = service_host:lobby)]")
        .await
}

async fn messaging_scope(
    context: &Context,
    key: &str,
) -> anyhow::Result<GetServiceMessagingScopeResponse> {
    context
        .request(
            from_service(key, "messaging.scope"),
            &GetServiceMessagingScopeRequest {
                service_id: skir_record_id("service", key),
                ..Default::default()
            },
        )
        .await
}

async fn report(
    context: &Context,
    key: &str,
    topology_revision: i64,
) -> anyhow::Result<ReportHostExecutionResponse> {
    context
        .request(
            from_service(key, "execution.report"),
            &ReportHostExecutionRequest {
                topology_revision,
                realm_state: Some(ChildRuntimeState {
                    status: ChildRuntimeStatus::Active,
                    active_artifact_version: Some("1.0.0-alpha.1+build.7".into()),
                    message: None,
                    updated_at: SystemTime::now(),
                    ..Default::default()
                }),
                engine_state: None,
                ..Default::default()
            },
        )
        .await
}

#[component_test(ServiceRegistration)]
async fn register_host_is_idempotent_and_publishes_new_topology(
    context: &mut Context,
) -> TestResult {
    acme_with_service(context, "lobby").await?;
    context.expect_publish(
        to_organization(&acme(), "topology.watch"),
        |event: &OrganizationTopologyChanged| {
            matches!(event, OrganizationTopologyChanged::HostAdvertised(host)
                if host.host_id.key.to_string() == "lobby" && host.revision == 1)
        },
    )?;
    let advertisement = RegisterServiceHostRequest {
        entrypoint: "PAPER".into(),
        can_host_realm: true,
        supported_engines: vec![SupportedEngine {
            engine_id: "typewritermc:paper".into(),
            ..Default::default()
        }],
        ..Default::default()
    };

    for _ in 0..2 {
        let reply: RegisterServiceHostResponse = context
            .request(from_service("lobby", "execution.register"), &advertisement)
            .await?;
        let RegisterServiceHostResponse::Success(host) = reply else {
            anyhow::bail!("expected the host to register, received {reply:?}");
        };
        assert_eq!(host.revision, 1);
        assert_eq!(host.entrypoint, "PAPER");
        assert_eq!(host.supported_engines, advertisement.supported_engines);
    }

    assert_jm!(
        context
            .database()?
            .query_json(
                "RETURN count(SELECT id FROM service_host WHERE service_id = service:lobby)"
            )
            .await?,
        1
    );
    Ok(())
}

#[component_test(ServiceRegistration)]
async fn messaging_scope_reports_owned_and_attached_realm(context: &mut Context) -> TestResult {
    acme_with_hosts(context, &[("lobby", &["paper"]), ("arena", &["paper"])]).await?;
    let hosted = arrange_configuration(context, "lobby", 1, realm_only(paper())).await?;
    let realm = hosted.realm.expect("lobby hosts a Realm").realm_id;
    arrange_configuration(context, "arena", 1, engine_in(realm.clone(), paper())).await?;

    let owner = messaging_scope(context, "lobby").await?;
    let attached = messaging_scope(context, "arena").await?;

    let GetServiceMessagingScopeResponse::Found(owner) = owner else {
        anyhow::bail!("expected the Realm host's scope, received {owner:?}");
    };
    assert_eq!(owner.organization_id, "acme");
    assert_eq!(owner.owned_realm.as_ref(), Some(&realm));
    assert_eq!(owner.attached_realm, None);
    let GetServiceMessagingScopeResponse::Found(attached) = attached else {
        anyhow::bail!("expected the engine host's scope, received {attached:?}");
    };
    assert_eq!(attached.organization_id, "acme");
    assert_eq!(attached.owned_realm, None);
    assert_eq!(attached.attached_realm.as_ref(), Some(&realm));
    Ok(())
}

#[component_test(ServiceRegistration)]
async fn messaging_scope_for_unknown_service_is_not_found(context: &mut Context) -> TestResult {
    let reply = messaging_scope(context, "missing").await?;

    assert!(
        matches!(reply, GetServiceMessagingScopeResponse::NotFoundError(_)),
        "{reply:?}"
    );
    Ok(())
}

#[component_test(ServiceRegistration)]
async fn watch_returns_first_class_topology_for_one_organization(
    context: &mut Context,
) -> TestResult {
    acme_with_hosts(context, &[("lobby", &["paper"])]).await?;
    arrange_configuration(context, "lobby", 1, realm_with_engine(paper())).await?;
    Seed::new()
        .organization(&globex(), grace())
        .organization_service(&globex(), "arena")
        .apply(&context.database()?)
        .await?;
    register_host(context, "arena", &["paper"]).await?;

    let reply: WatchOrganizationTopologyResponse = context
        .request(
            from_member(ada(), &acme(), "topology.watch"),
            &WatchOrganizationTopologyRequest::default(),
        )
        .await?;

    let WatchOrganizationTopologyResponse::List(topology) = reply else {
        anyhow::bail!("expected Acme's topology, received {reply:?}");
    };
    let ([host], [realm], [engine]) = (
        topology.hosts.as_slice(),
        topology.realms.as_slice(),
        topology.engines.as_slice(),
    ) else {
        anyhow::bail!("expected one host, Realm and engine, received {topology:?}");
    };
    assert_eq!(host.host_id, host_id("lobby"));
    assert_eq!(realm.owner_host.id, host_id("lobby"));
    assert_eq!(realm.owner_host.name, "lobby");
    assert_eq!(engine.owner_host.name, "lobby");
    assert_eq!(engine.realm.realm_id, realm.realm_id);
    assert_eq!(engine.realm.owner_host.name, "lobby");
    Ok(())
}

#[component_test(ServiceRegistration)]
async fn configure_creates_hosted_realm_and_attached_engine(context: &mut Context) -> TestResult {
    acme_with_hosts(context, &[("lobby", &["paper"])]).await?;
    expect_configuration_event(context, |change| {
        change.host.revision == 2
            && change.realm.is_some()
            && change.engine.is_some()
            && change.removed_resources.is_empty()
    })?;
    expect_desired_execution(context, "lobby", |desired| {
        matches!(desired, WatchHostExecutionResponse::Desired(desired)
            if desired.topology_revision == 1
                && desired.realm.is_some()
                && desired.engine.is_some())
    })?;

    let reply = configure(context, "lobby", 1, realm_with_engine(paper())).await?;

    let ConfigureServiceHostResponse::Success(configured) = reply else {
        anyhow::bail!("expected the configuration to be accepted, received {reply:?}");
    };
    let realm = configured
        .realm
        .as_ref()
        .expect("the hosted Realm is returned");
    let engine = configured.engine.as_ref().expect("the engine is returned");
    assert_eq!(configured.host.revision, 2);
    assert_eq!(configured.host.topology_revision.desired, 1);
    assert_eq!(engine.realm.realm_id, realm.realm_id);
    assert_eq!(realm.owner_host.name, "lobby");
    assert_eq!(engine.owner_host.name, "lobby");
    assert_eq!(engine.realm.owner_host.name, "lobby");
    assert_eq!(realm.target_engine, paper());
    assert_eq!(engine.target, paper());
    assert_jm!(topology_state(context, "lobby").await?, [2, 1, 1]);
    Ok(())
}

#[component_test(ServiceRegistration)]
async fn configure_runs_an_advertised_custom_engine_on_a_host(context: &mut Context) -> TestResult {
    acme_with_hosts(context, &[("lobby", &["custom_engine"])]).await?;
    expect_configuration_event(context, |change| {
        change
            .engine
            .as_ref()
            .is_some_and(|engine| engine.target == custom_engine())
    })?;
    expect_desired_execution(context, "lobby", |desired| {
        matches!(desired, WatchHostExecutionResponse::Desired(desired)
            if desired.engine.as_ref().is_some_and(|engine| engine.target == custom_engine()))
    })?;

    let reply = configure(context, "lobby", 1, realm_with_engine(custom_engine())).await?;

    let ConfigureServiceHostResponse::Success(configured) = reply else {
        anyhow::bail!("expected the custom engine to be accepted, received {reply:?}");
    };
    assert_eq!(
        configured
            .realm
            .expect("the hosted Realm is returned")
            .target_engine,
        custom_engine()
    );
    assert_eq!(
        configured.engine.expect("the engine is returned").target,
        custom_engine()
    );
    Ok(())
}

#[component_test(ServiceRegistration)]
async fn configuring_an_engine_in_another_realm_removes_the_hosted_realm(
    context: &mut Context,
) -> TestResult {
    acme_with_hosts(context, &[("lobby", &["paper"]), ("arena", &["paper"])]).await?;
    let arena = arrange_configuration(context, "arena", 1, realm_only(paper())).await?;
    let external = arena.realm.expect("arena hosts a Realm").realm_id;
    let lobby = arrange_configuration(context, "lobby", 1, realm_with_engine(paper())).await?;
    let hosted = lobby.realm.expect("lobby hosts a Realm").realm_id;
    let removed = hosted.clone();
    let attached = external.clone();
    expect_configuration_event(context, move |change| {
        change.realm.is_none()
            && change.removed_resources == [removed.clone()]
            && change
                .engine
                .as_ref()
                .is_some_and(|engine| engine.realm.realm_id == attached)
    })?;
    let attached = external.clone();
    expect_desired_execution(context, "lobby", move |desired| {
        matches!(desired, WatchHostExecutionResponse::Desired(desired)
            if desired.realm.is_none()
                && desired.engine.as_ref().is_some_and(|engine| engine.realm.realm_id == attached))
    })?;

    let reply = configure(context, "lobby", 2, engine_in(external.clone(), paper())).await?;

    let ConfigureServiceHostResponse::Success(configured) = reply else {
        anyhow::bail!("expected the engine to move, received {reply:?}");
    };
    assert!(configured.realm.is_none());
    assert_eq!(configured.removed_resources, std::slice::from_ref(&hosted));
    assert_eq!(
        configured
            .engine
            .expect("the engine is returned")
            .realm
            .realm_id,
        external
    );
    assert_jm!(
        context
            .database()?
            .seed("RETURN record::exists($realm)")
            .bind("realm", surrealdb_types::RecordId::from(hosted))?
            .query_json()
            .await?,
        false
    );
    Ok(())
}

/// A host configuration that cannot be carried out.
#[derive(Debug)]
enum Invalid {
    /// The engine joins a Realm that does not exist.
    MissingRealm,
    /// The host runs its own Realm, while its engine joins a Realm that does not exist.
    MissingRealmWithHostedRealm,
    /// The engine is one the host does not advertise.
    IncompatibleEngine,
}

/// Each invalid configuration is rejected for its own reason and writes nothing.
#[component_test(ServiceRegistration)]
#[case::missing_realm(Invalid::MissingRealm)]
#[case::missing_realm_with_hosted_realm(Invalid::MissingRealmWithHostedRealm)]
#[case::incompatible_engine(Invalid::IncompatibleEngine)]
async fn configure_rejects_invalid_configuration_without_writing(
    context: &mut Context,
    invalid: Invalid,
) -> TestResult {
    acme_with_hosts(context, &[("lobby", &["paper"])]).await?;
    expect_no_topology_event(context, "lobby")?;
    let missing = skir_record_id("realm_instance", "missing");
    let unsupported = EngineTarget {
        engine_id: "unsupported".into(),
        ..paper()
    };
    let execution = match invalid {
        Invalid::MissingRealm => engine_in(missing.clone(), paper()),
        Invalid::MissingRealmWithHostedRealm => HostExecutionConfiguration {
            realm: realm_only(paper()).realm,
            ..engine_in(missing.clone(), paper())
        },
        Invalid::IncompatibleEngine => realm_with_engine(unsupported.clone()),
    };

    let reply = configure(context, "lobby", 1, execution).await?;

    let rejected_for_its_reason = match (&invalid, &reply) {
        (
            Invalid::MissingRealm | Invalid::MissingRealmWithHostedRealm,
            ConfigureServiceHostResponse::RealmNotFoundError(error),
        ) => error.realm_id == missing,
        (
            Invalid::IncompatibleEngine,
            ConfigureServiceHostResponse::IncompatibleEngineError(error),
        ) => error.target == unsupported,
        _ => false,
    };
    assert!(
        rejected_for_its_reason,
        "{invalid:?} was not rejected for its reason: {reply:?}"
    );
    assert_jm!(topology_state(context, "lobby").await?, [1, 0, 0]);
    Ok(())
}

#[component_test(ServiceRegistration)]
async fn realm_only_host_may_target_an_engine_it_does_not_execute(
    context: &mut Context,
) -> TestResult {
    acme_with_hosts(context, &[("lobby", &[])]).await?;
    expect_configuration_event(context, |change| {
        change.engine.is_none()
            && change
                .realm
                .as_ref()
                .is_some_and(|realm| realm.target_engine == paper())
    })?;
    expect_desired_execution(context, "lobby", |desired| {
        matches!(desired, WatchHostExecutionResponse::Desired(desired)
            if desired.engine.is_none() && desired.realm.is_some())
    })?;

    let reply = configure(context, "lobby", 1, realm_only(paper())).await?;

    let ConfigureServiceHostResponse::Success(configured) = reply else {
        anyhow::bail!("expected the Realm only configuration to be accepted, received {reply:?}");
    };
    assert_eq!(
        configured
            .realm
            .expect("the hosted Realm is returned")
            .target_engine,
        paper()
    );
    assert!(configured.engine.is_none());
    Ok(())
}

#[component_test(ServiceRegistration)]
async fn configure_returns_conflict_for_stale_host_revision(context: &mut Context) -> TestResult {
    acme_with_hosts(context, &[("lobby", &["paper"])]).await?;
    expect_no_topology_event(context, "lobby")?;

    let reply = configure(context, "lobby", 0, HostExecutionConfiguration::default()).await?;

    let ConfigureServiceHostResponse::ConflictError(conflict) = reply else {
        anyhow::bail!("expected a host conflict, received {reply:?}");
    };
    assert_eq!(conflict.actual.host.revision, 1);
    assert_jm!(topology_state(context, "lobby").await?, [1, 0, 0]);
    Ok(())
}

#[component_test(ServiceRegistration)]
async fn configure_blocks_realm_removal_while_another_host_depends_on_it(
    context: &mut Context,
) -> TestResult {
    acme_with_hosts(context, &[("lobby", &["paper"]), ("arena", &["paper"])]).await?;
    let lobby = arrange_configuration(context, "lobby", 1, realm_only(paper())).await?;
    let shared = lobby.realm.expect("lobby hosts a Realm").realm_id;
    let arena =
        arrange_configuration(context, "arena", 1, engine_in(shared.clone(), paper())).await?;
    let engine = arena.engine.expect("arena runs an engine").engine_id;
    expect_no_topology_event(context, "lobby")?;

    let reply = configure(context, "lobby", 2, HostExecutionConfiguration::default()).await?;

    assert!(
        matches!(
            reply,
            ConfigureServiceHostResponse::InvalidConfigurationError(_)
        ),
        "{reply:?}"
    );
    assert_jm!(
        context
            .database()?
            .seed("RETURN [service_host:lobby.revision, $shared.owner_host_id = service_host:lobby, $engine.realm_id = $shared]")
            .bind("shared", surrealdb_types::RecordId::from(shared))?
            .bind("engine", surrealdb_types::RecordId::from(engine))?
            .query_json()
            .await?,
        [2, true, true]
    );
    Ok(())
}

#[component_test(ServiceRegistration)]
async fn watch_returns_desired_execution(context: &mut Context) -> TestResult {
    acme_with_hosts(context, &[("lobby", &["paper"])]).await?;
    let configured = arrange_configuration(context, "lobby", 1, realm_only(paper())).await?;
    let realm = configured.realm.expect("lobby hosts a Realm");

    let reply: WatchHostExecutionResponse = context
        .request(
            from_service("lobby", "execution.watch"),
            &WatchHostExecutionRequest::default(),
        )
        .await?;

    let WatchHostExecutionResponse::Desired(desired) = reply else {
        anyhow::bail!("expected the desired execution, received {reply:?}");
    };
    assert_eq!(
        desired.topology_revision,
        configured.host.topology_revision.desired
    );
    let desired_realm = desired.realm.expect("the Realm is assigned");
    assert_eq!(desired_realm.realm_id, realm.realm_id);
    assert_eq!(desired_realm.owner_host.name, "lobby");
    assert!(desired.engine.is_none());
    Ok(())
}

#[component_test(ServiceRegistration)]
async fn stale_report_is_rejected(context: &mut Context) -> TestResult {
    acme_with_hosts(context, &[("lobby", &["paper"])]).await?;
    let configured = arrange_configuration(context, "lobby", 1, realm_only(paper())).await?;
    expect_no_topology_event(context, "lobby")?;
    let desired = configured.host.topology_revision.desired;
    let before = execution_state(context).await?;

    let reply = report(context, "lobby", desired - 1).await?;

    assert!(
        matches!(reply, ReportHostExecutionResponse::StaleRevisionError(_)),
        "{reply:?}"
    );
    assert_eq!(execution_state(context).await?, before);
    Ok(())
}

#[component_test(ServiceRegistration)]
async fn current_report_marks_host_and_realm_active(context: &mut Context) -> TestResult {
    acme_with_hosts(context, &[("lobby", &["paper"])]).await?;
    let configured = arrange_configuration(context, "lobby", 1, realm_only(paper())).await?;
    Seed::new()
        .organization(&globex(), grace())
        .organization_service(&globex(), "arena")
        .apply(&context.database()?)
        .await?;
    register_host(context, "arena", &["paper"]).await?;
    let desired = configured.host.topology_revision.desired;
    let realm = configured.realm.expect("lobby hosts a Realm").realm_id;
    let observed = realm.clone();
    context.expect_publish(
        to_organization(&acme(), "topology.watch"),
        move |event: &OrganizationTopologyChanged| {
            matches!(event, OrganizationTopologyChanged::ObservationsReported(observation)
            if observation.host.state.status == HostRuntimeStatus::Active
                && observation.host.topology_revision.applied == desired
                && observation.realm.as_ref().is_some_and(|realm| {
                    realm.realm_id == observed && realm.state.status == ChildRuntimeStatus::Active
                }))
        },
    )?;

    let reply = report(context, "lobby", desired).await?;

    assert!(
        matches!(reply, ReportHostExecutionResponse::Success(_)),
        "{reply:?}"
    );
    assert_eq!(
        context
            .database()?
            .seed("RETURN [service_host:lobby.topology_revision.applied, service_host:lobby.state.status, $realm.state.status, service_host:arena.topology_revision.applied, service_host:arena.state.status]")
            .bind("realm", surrealdb_types::RecordId::from(realm))?
            .query_json()
            .await?,
        serde_json::json!([desired, "active", "active", 0, "offline"])
    );
    Ok(())
}
