use json_matcher::assert_jm;
use typewriter_component_test::{
    prelude::*,
    service::{
        InvalidHostConfiguration, arrange_host_configuration, configure_host, engine, engine_in,
        expect_configuration_change, expect_desired_execution, expect_no_topology_change,
        organization_with_hosts, paper, realm_only, realm_with_engine, register_host,
        report_execution, seed_organization_services,
    },
};
use wasmcloud_utils::skir::base::service::v1::topology::{
    ChildRuntimeStatus, ConfigureServiceHostResponse, EngineTarget,
    GetServiceMessagingScopeRequest, GetServiceMessagingScopeResponse, HostExecutionConfiguration,
    HostRuntimeStatus, OrganizationTopologyChanged, RegisterServiceHostRequest,
    RegisterServiceHostResponse, ReportHostExecutionResponse, SupportedEngine,
    WatchHostExecutionRequest, WatchHostExecutionResponse, WatchOrganizationTopologyRequest,
    WatchOrganizationTopologyResponse,
};

use super::ServiceRegistration;

/// The revision of `lobby`'s host and the number of Realms and engines in the database.
const TOPOLOGY: &str = "RETURN [service_host:lobby.revision, count(SELECT id FROM realm_instance), count(SELECT id FROM engine_instance)]";
/// The applied revision and status of `lobby`'s host and the state of its Realm.
const EXECUTION: &str = "RETURN [service_host:lobby.topology_revision.applied, service_host:lobby.state, (SELECT VALUE state FROM realm_instance WHERE owner_host_id = service_host:lobby)]";

#[component_test(ServiceRegistration)]
async fn register_host_is_idempotent_and_publishes_new_topology(
    context: &mut TestContext<ServiceRegistration>,
) -> TestResult {
    seed_organization_services(context, &acme(), ada(), &["lobby"]).await?;
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
async fn messaging_scope_reports_owned_and_attached_realm(
    context: &mut TestContext<ServiceRegistration>,
) -> TestResult {
    organization_with_hosts(context, &acme(), ada(), &["lobby", "arena"], &["paper"]).await?;
    let hosted = arrange_host_configuration(context, "lobby", 1, realm_only(paper())).await?;
    let realm = hosted.realm.expect("lobby hosts a Realm").realm_id;
    arrange_host_configuration(context, "arena", 1, engine_in(realm.clone(), paper())).await?;

    let owner: GetServiceMessagingScopeResponse = context
        .request(
            from_service("lobby", "messaging.scope"),
            &GetServiceMessagingScopeRequest {
                service_id: skir_record_id("service", "lobby"),
                ..Default::default()
            },
        )
        .await?;
    let attached: GetServiceMessagingScopeResponse = context
        .request(
            from_service("arena", "messaging.scope"),
            &GetServiceMessagingScopeRequest {
                service_id: skir_record_id("service", "arena"),
                ..Default::default()
            },
        )
        .await?;

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
async fn messaging_scope_for_unknown_service_is_not_found(
    context: &mut TestContext<ServiceRegistration>,
) -> TestResult {
    let reply: GetServiceMessagingScopeResponse = context
        .request(
            from_service("missing", "messaging.scope"),
            &GetServiceMessagingScopeRequest {
                service_id: skir_record_id("service", "missing"),
                ..Default::default()
            },
        )
        .await?;

    assert!(
        matches!(reply, GetServiceMessagingScopeResponse::NotFoundError(_)),
        "{reply:?}"
    );
    Ok(())
}

#[component_test(ServiceRegistration)]
async fn watch_returns_first_class_topology_for_one_organization(
    context: &mut TestContext<ServiceRegistration>,
) -> TestResult {
    organization_with_hosts(context, &acme(), ada(), &["lobby"], &["paper"]).await?;
    arrange_host_configuration(context, "lobby", 1, realm_with_engine(paper())).await?;
    seed_organization_services(context, &globex(), grace(), &["arena"]).await?;
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
    assert_eq!(host.host_id, skir_record_id("service_host", "lobby"));
    assert_eq!(realm.owner_host.id, skir_record_id("service_host", "lobby"));
    assert_eq!(realm.owner_host.name, "lobby");
    assert_eq!(engine.owner_host.name, "lobby");
    assert_eq!(engine.realm.realm_id, realm.realm_id);
    assert_eq!(engine.realm.owner_host.name, "lobby");
    Ok(())
}

#[component_test(ServiceRegistration)]
async fn configure_creates_hosted_realm_and_attached_engine(
    context: &mut TestContext<ServiceRegistration>,
) -> TestResult {
    organization_with_hosts(context, &acme(), ada(), &["lobby"], &["paper"]).await?;
    expect_configuration_change(context, &acme(), |change| {
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

    let reply = configure_host(context, "lobby", 1, realm_with_engine(paper())).await?;

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
    assert_jm!(context.database()?.query_json(TOPOLOGY).await?, [2, 1, 1]);
    Ok(())
}

#[component_test(ServiceRegistration)]
async fn configure_runs_an_advertised_custom_engine_on_a_host(
    context: &mut TestContext<ServiceRegistration>,
) -> TestResult {
    organization_with_hosts(context, &acme(), ada(), &["lobby"], &["custom_engine"]).await?;
    let custom = engine("custom_engine", "^0.1");
    let expected = custom.clone();
    expect_configuration_change(context, &acme(), move |change| {
        change
            .engine
            .as_ref()
            .is_some_and(|engine| engine.target == expected)
    })?;
    let expected = custom.clone();
    expect_desired_execution(context, "lobby", move |desired| {
        matches!(desired, WatchHostExecutionResponse::Desired(desired)
            if desired.engine.as_ref().is_some_and(|engine| engine.target == expected))
    })?;

    let reply = configure_host(context, "lobby", 1, realm_with_engine(custom.clone())).await?;

    let ConfigureServiceHostResponse::Success(configured) = reply else {
        anyhow::bail!("expected the custom engine to be accepted, received {reply:?}");
    };
    assert_eq!(
        configured
            .realm
            .expect("the hosted Realm is returned")
            .target_engine,
        custom
    );
    assert_eq!(
        configured.engine.expect("the engine is returned").target,
        custom
    );
    Ok(())
}

#[component_test(ServiceRegistration)]
async fn configuring_an_engine_in_another_realm_removes_the_hosted_realm(
    context: &mut TestContext<ServiceRegistration>,
) -> TestResult {
    organization_with_hosts(context, &acme(), ada(), &["lobby", "arena"], &["paper"]).await?;
    let arena = arrange_host_configuration(context, "arena", 1, realm_only(paper())).await?;
    let external = arena.realm.expect("arena hosts a Realm").realm_id;
    let lobby = arrange_host_configuration(context, "lobby", 1, realm_with_engine(paper())).await?;
    let hosted = lobby.realm.expect("lobby hosts a Realm").realm_id;
    let removed = hosted.clone();
    let attached = external.clone();
    expect_configuration_change(context, &acme(), move |change| {
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

    let reply = configure_host(context, "lobby", 2, engine_in(external.clone(), paper())).await?;

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
            .read("RETURN record::exists($realm)", &[("realm", hosted)])
            .await?,
        false
    );
    Ok(())
}

/// Each invalid configuration is rejected for its own reason and writes nothing.
#[component_test(ServiceRegistration)]
#[case::missing_realm(InvalidHostConfiguration::MissingRealm)]
#[case::missing_realm_with_hosted_realm(InvalidHostConfiguration::MissingRealmWithHostedRealm)]
#[case::incompatible_engine(InvalidHostConfiguration::IncompatibleEngine)]
async fn configure_rejects_invalid_configuration_without_writing(
    context: &mut TestContext<ServiceRegistration>,
    invalid: InvalidHostConfiguration,
) -> TestResult {
    organization_with_hosts(context, &acme(), ada(), &["lobby"], &["paper"]).await?;
    expect_no_topology_change(context, &acme(), "lobby")?;
    let missing = skir_record_id("realm_instance", "missing");
    let unsupported = EngineTarget {
        engine_id: "unsupported".into(),
        ..paper()
    };
    let execution = match invalid {
        InvalidHostConfiguration::MissingRealm => engine_in(missing.clone(), paper()),
        InvalidHostConfiguration::MissingRealmWithHostedRealm => HostExecutionConfiguration {
            realm: realm_only(paper()).realm,
            ..engine_in(missing.clone(), paper())
        },
        InvalidHostConfiguration::IncompatibleEngine => realm_with_engine(unsupported.clone()),
    };

    let reply = configure_host(context, "lobby", 1, execution).await?;

    let rejected_for_its_reason = match (&invalid, &reply) {
        (
            InvalidHostConfiguration::MissingRealm
            | InvalidHostConfiguration::MissingRealmWithHostedRealm,
            ConfigureServiceHostResponse::RealmNotFoundError(error),
        ) => error.realm_id == missing,
        (
            InvalidHostConfiguration::IncompatibleEngine,
            ConfigureServiceHostResponse::IncompatibleEngineError(error),
        ) => error.target == unsupported,
        _ => false,
    };
    assert!(
        rejected_for_its_reason,
        "{invalid:?} was not rejected for its reason: {reply:?}"
    );
    assert_jm!(context.database()?.query_json(TOPOLOGY).await?, [1, 0, 0]);
    Ok(())
}

#[component_test(ServiceRegistration)]
async fn realm_only_host_may_target_an_engine_it_does_not_execute(
    context: &mut TestContext<ServiceRegistration>,
) -> TestResult {
    organization_with_hosts(context, &acme(), ada(), &["lobby"], &[]).await?;
    expect_configuration_change(context, &acme(), |change| {
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

    let reply = configure_host(context, "lobby", 1, realm_only(paper())).await?;

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
async fn a_different_configuration_with_a_stale_revision_conflicts_and_changes_nothing(
    context: &mut TestContext<ServiceRegistration>,
) -> TestResult {
    organization_with_hosts(context, &acme(), ada(), &["lobby"], &["paper"]).await?;
    arrange_host_configuration(context, "lobby", 1, realm_with_engine(paper())).await?;
    expect_no_topology_change(context, &acme(), "lobby")?;

    let reply = configure_host(context, "lobby", 1, realm_only(paper())).await?;

    let ConfigureServiceHostResponse::ConflictError(conflict) = reply else {
        anyhow::bail!("expected a host conflict, received {reply:?}");
    };
    assert_eq!(conflict.actual.host.revision, 2);
    assert!(conflict.actual.engine.is_some());
    assert_jm!(context.database()?.query_json(TOPOLOGY).await?, [2, 1, 1]);
    Ok(())
}

#[component_test(ServiceRegistration)]
async fn repeated_configuration_after_it_landed_answers_and_republishes_the_stored_state(
    context: &mut TestContext<ServiceRegistration>,
) -> TestResult {
    organization_with_hosts(context, &acme(), ada(), &["lobby"], &["paper"]).await?;
    let first =
        arrange_host_configuration(context, "lobby", 1, realm_with_engine(paper())).await?;
    expect_configuration_change(context, &acme(), |change| {
        change.host.revision == 2 && change.removed_resources.is_empty()
    })?;
    expect_desired_execution(context, "lobby", |desired| {
        matches!(desired, WatchHostExecutionResponse::Desired(desired)
            if desired.topology_revision == 1)
    })?;

    let reply = configure_host(context, "lobby", 1, realm_with_engine(paper())).await?;

    let ConfigureServiceHostResponse::Success(stored) = reply else {
        anyhow::bail!("expected the repeated configuration to succeed, received {reply:?}");
    };
    assert_eq!(stored.host.revision, 2);
    assert_eq!(stored.host.topology_revision.desired, 1);
    assert_eq!(stored.realm, first.realm);
    assert_eq!(stored.engine, first.engine);
    assert!(stored.removed_resources.is_empty());
    assert_jm!(context.database()?.query_json(TOPOLOGY).await?, [2, 1, 1]);
    Ok(())
}

#[component_test(ServiceRegistration)]
async fn repeated_engine_in_another_realm_after_it_landed_answers_the_stored_state(
    context: &mut TestContext<ServiceRegistration>,
) -> TestResult {
    organization_with_hosts(context, &acme(), ada(), &["arena", "lobby"], &["paper"]).await?;
    let arena = arrange_host_configuration(context, "arena", 1, realm_only(paper())).await?;
    let realm = arena.realm.expect("arena hosts a Realm").realm_id;
    let first =
        arrange_host_configuration(context, "lobby", 1, engine_in(realm.clone(), paper())).await?;
    expect_configuration_change(context, &acme(), |change| change.host.revision == 2)?;
    expect_desired_execution(context, "lobby", |_| true)?;

    let reply = configure_host(context, "lobby", 1, engine_in(realm, paper())).await?;

    let ConfigureServiceHostResponse::Success(stored) = reply else {
        anyhow::bail!("expected the repeated configuration to succeed, received {reply:?}");
    };
    assert_eq!(stored.host.revision, 2);
    assert_eq!(stored.engine, first.engine);
    Ok(())
}

#[component_test(ServiceRegistration)]
async fn configure_blocks_realm_removal_while_another_host_depends_on_it(
    context: &mut TestContext<ServiceRegistration>,
) -> TestResult {
    organization_with_hosts(context, &acme(), ada(), &["lobby", "arena"], &["paper"]).await?;
    let lobby = arrange_host_configuration(context, "lobby", 1, realm_only(paper())).await?;
    let shared = lobby.realm.expect("lobby hosts a Realm").realm_id;
    let arena =
        arrange_host_configuration(context, "arena", 1, engine_in(shared.clone(), paper())).await?;
    let engine = arena.engine.expect("arena runs an engine").engine_id;
    expect_no_topology_change(context, &acme(), "lobby")?;

    let reply = configure_host(context, "lobby", 2, HostExecutionConfiguration::default()).await?;

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
            .read("RETURN [service_host:lobby.revision, $shared.owner_host_id = service_host:lobby, $engine.realm_id = $shared]", &[("shared", shared), ("engine", engine)])
            .await?,
        [2, true, true]
    );
    Ok(())
}

#[component_test(ServiceRegistration)]
async fn watch_returns_desired_execution(
    context: &mut TestContext<ServiceRegistration>,
) -> TestResult {
    organization_with_hosts(context, &acme(), ada(), &["lobby"], &["paper"]).await?;
    let configured = arrange_host_configuration(context, "lobby", 1, realm_only(paper())).await?;
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
async fn stale_report_is_rejected(context: &mut TestContext<ServiceRegistration>) -> TestResult {
    organization_with_hosts(context, &acme(), ada(), &["lobby"], &["paper"]).await?;
    let configured = arrange_host_configuration(context, "lobby", 1, realm_only(paper())).await?;
    expect_no_topology_change(context, &acme(), "lobby")?;
    let desired = configured.host.topology_revision.desired;
    let before = context.database()?.query_json(EXECUTION).await?;

    let reply = report_execution(context, "lobby", desired - 1).await?;

    assert!(
        matches!(reply, ReportHostExecutionResponse::StaleRevisionError(_)),
        "{reply:?}"
    );
    assert_eq!(context.database()?.query_json(EXECUTION).await?, before);
    Ok(())
}

#[component_test(ServiceRegistration)]
async fn current_report_marks_host_and_realm_active(
    context: &mut TestContext<ServiceRegistration>,
) -> TestResult {
    organization_with_hosts(context, &acme(), ada(), &["lobby"], &["paper"]).await?;
    let configured = arrange_host_configuration(context, "lobby", 1, realm_only(paper())).await?;
    seed_organization_services(context, &globex(), grace(), &["arena"]).await?;
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

    let reply = report_execution(context, "lobby", desired).await?;

    assert!(
        matches!(reply, ReportHostExecutionResponse::Success(_)),
        "{reply:?}"
    );
    assert_eq!(
        context
            .database()?
            .read("RETURN [service_host:lobby.topology_revision.applied, service_host:lobby.state.status, $realm.state.status, service_host:arena.topology_revision.applied, service_host:arena.state.status]", &[("realm", realm)])
            .await?,
        serde_json::json!([desired, "active", "active", 0, "offline"])
    );
    Ok(())
}
