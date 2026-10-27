//! Services and their hosts as service registration knows them: the execution a host is
//! configured with, the requests that register, configure and report a host, and the
//! expectations on what registration tells an organization and a host.

use std::time::{Duration, SystemTime, UNIX_EPOCH};

use anyhow::Result;
use component_test::TestContext;
use wasmcloud_utils::skir::base::{
    kernel::v1::record_id::RecordId,
    service::v1::{
        organization::{OrganizationServicesChanged, UpdateOrganizationServiceRequest},
        registration::{UnbindServiceRequest, UnbindServiceResponse},
        service::ServiceStatus,
        status::{EnsureRegistrationLeaseRequest, EnsureRegistrationLeaseResponse},
        topology::{
            ChildRuntimeState, ChildRuntimeStatus, ConfigureServiceHostRequest,
            ConfigureServiceHostResponse, EngineRealmSelection, EngineRealmSelection_ExistingRealm,
            EngineTarget, HostConfigurationChange, HostExecutionConfiguration,
            HostedEngineConfiguration, HostedRealmConfiguration, OrganizationTopologyChanged,
            RegisterServiceHostRequest, RegisterServiceHostResponse, ReportHostExecutionRequest,
            ReportHostExecutionResponse, SupportedEngine, WatchHostExecutionResponse,
        },
    },
};

use crate::{
    Organization, Seed, StackUser, TypewriterContext, acme, ada, skir_record_id,
    topology::{from_member, from_service, to_organization, to_service},
};

/// The Paper engine, version 1.
pub fn paper() -> EngineTarget {
    engine("paper", "^1")
}

/// An engine target: the engine `engine_id` at a version matching `version_constraint`.
pub fn engine(engine_id: &str, version_constraint: &str) -> EngineTarget {
    EngineTarget {
        engine_id: engine_id.into(),
        version_constraint: version_constraint.into(),
        ..Default::default()
    }
}

/// A host running a Realm of its own and an engine attached to that Realm, both on `target`.
pub fn realm_with_engine(target: EngineTarget) -> HostExecutionConfiguration {
    HostExecutionConfiguration {
        primary_engine: Some(HostedEngineConfiguration {
            target: target.clone(),
            realm: EngineRealmSelection::HostedRealm,
            ..Default::default()
        }),
        ..realm_only(target)
    }
}

/// A host running only a Realm whose primary engine is `target`.
pub fn realm_only(target: EngineTarget) -> HostExecutionConfiguration {
    HostExecutionConfiguration {
        realm: Some(HostedRealmConfiguration {
            primary_engine: target,
            ..Default::default()
        }),
        ..Default::default()
    }
}

/// A host running only an engine on `target`, attached to the existing Realm `realm`.
pub fn engine_in(realm: RecordId, target: EngineTarget) -> HostExecutionConfiguration {
    HostExecutionConfiguration {
        primary_engine: Some(HostedEngineConfiguration {
            target,
            realm: EngineRealmSelection::ExistingRealm(Box::new(
                EngineRealmSelection_ExistingRealm {
                    realm_id: realm,
                    ..Default::default()
                },
            )),
            ..Default::default()
        }),
        ..Default::default()
    }
}

/// Seeds `organization`, founded by `founder`, with a bound host service for each of
/// `services`.
pub async fn seed_organization_services<F>(
    context: &TestContext<F>,
    organization: &Organization,
    founder: &StackUser,
    services: &[&str],
) -> Result<()> {
    services
        .iter()
        .fold(
            Seed::new().organization(organization, founder),
            |seed, key| seed.organization_service(organization, key),
        )
        .apply(context)
        .await
}

/// Seeds the unbound host service `key`, holding the registration token `token` for `lease`.
pub async fn seed_registration_lease<F>(
    context: &TestContext<F>,
    key: &str,
    token: &str,
    lease: Duration,
) -> Result<()> {
    Seed::new()
        .service(key)
        .registration_lease(key, token, lease)
        .apply(context)
        .await
}

/// [`seed_organization_services`] with each service registered as a host that can run a Realm
/// and `engines`.
pub async fn organization_with_hosts<F>(
    context: &TestContext<F>,
    organization: &Organization,
    founder: &StackUser,
    hosts: &[&str],
    engines: &[&str],
) -> Result<()> {
    seed_organization_services(context, organization, founder, hosts).await?;
    for key in hosts {
        register_host(context, key, engines).await?;
    }
    Ok(())
}

/// The service `key` registers as a host that can run a Realm and the listed engines.
pub async fn register_host<F>(context: &TestContext<F>, key: &str, engines: &[&str]) -> Result<()> {
    let reply: RegisterServiceHostResponse = context
        .arrange(
            from_service(key, "execution.register"),
            &RegisterServiceHostRequest {
                entrypoint: "PAPER".into(),
                can_host_realm: true,
                supported_engines: engines
                    .iter()
                    .map(|engine| SupportedEngine {
                        engine_id: (*engine).to_owned(),
                        ..Default::default()
                    })
                    .collect(),
                ..Default::default()
            },
        )
        .await?;
    match reply {
        RegisterServiceHostResponse::Success(_) => Ok(()),
        reply => anyhow::bail!("registering host `{key}` failed: {reply:?}"),
    }
}

/// Ada configures Acme's host `key`, expecting it at `expected_revision`.
pub async fn configure_host<F>(
    context: &TestContext<F>,
    key: &str,
    expected_revision: i64,
    execution: HostExecutionConfiguration,
) -> Result<ConfigureServiceHostResponse> {
    context
        .request(
            from_member(ada(), &acme(), "topology.configure"),
            &configure_request(key, expected_revision, execution),
        )
        .await
}

/// [`configure_host`] as setup for a case: the configuration must be accepted, and the events
/// it causes are neither expected nor unexpected.
pub async fn arrange_host_configuration<F>(
    context: &TestContext<F>,
    key: &str,
    expected_revision: i64,
    execution: HostExecutionConfiguration,
) -> Result<HostConfigurationChange> {
    let reply: ConfigureServiceHostResponse = context
        .arrange(
            from_member(ada(), &acme(), "topology.configure"),
            &configure_request(key, expected_revision, execution),
        )
        .await?;
    match reply {
        ConfigureServiceHostResponse::Success(change) => Ok(*change),
        reply => anyhow::bail!("configuring host `{key}` failed: {reply:?}"),
    }
}

fn configure_request(
    key: &str,
    expected_revision: i64,
    execution: HostExecutionConfiguration,
) -> ConfigureServiceHostRequest {
    ConfigureServiceHostRequest {
        host_id: skir_record_id("service_host", key),
        expected_revision,
        execution,
        ..Default::default()
    }
}

/// The host `key` reports that it runs `topology_revision` with an active Realm and no engine.
pub async fn report_execution<F>(
    context: &TestContext<F>,
    key: &str,
    topology_revision: i64,
) -> Result<ReportHostExecutionResponse> {
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

/// The service `key` asks for its registration lease.
pub async fn ensure_registration_lease<F>(
    context: &TestContext<F>,
    key: &str,
) -> Result<EnsureRegistrationLeaseResponse> {
    context
        .request(
            from_service(key, "registration.ensure"),
            &EnsureRegistrationLeaseRequest::default(),
        )
        .await
}

/// Ada unbinds the service `key` from Acme.
pub async fn unbind_service<F>(
    context: &TestContext<F>,
    key: &str,
) -> Result<UnbindServiceResponse> {
    context
        .request(
            from_member(ada(), &acme(), "services.unbind"),
            &UnbindServiceRequest {
                service_id: key.into(),
                ..Default::default()
            },
        )
        .await
}

/// A request to rename the service `key`, expected at `expected_revision`, to `name`.
pub fn rename_service(
    key: &str,
    expected_revision: i64,
    name: &str,
) -> UpdateOrganizationServiceRequest {
    UpdateOrganizationServiceRequest {
        service_id: skir_record_id("service", key),
        expected_revision,
        name: name.into(),
        ..Default::default()
    }
}

/// Expects the topology watchers of `organization` to receive one accepted host configuration
/// that satisfies `matches`.
pub fn expect_configuration_change<F>(
    context: &TestContext<F>,
    organization: &Organization,
    matches: impl Fn(&HostConfigurationChange) -> bool + Send + Sync + 'static,
) -> Result<()> {
    context.expect_publish(
        to_organization(organization, "topology.watch"),
        move |event: &OrganizationTopologyChanged| {
            matches!(event, OrganizationTopologyChanged::ConfigurationChanged(change) if matches(change))
        },
    )?;
    Ok(())
}

/// Expects the host `key` to be told one new desired execution that satisfies `matches`.
pub fn expect_desired_execution<F>(
    context: &TestContext<F>,
    key: &str,
    matches: impl Fn(&WatchHostExecutionResponse) -> bool + Send + Sync + 'static,
) -> Result<()> {
    context.expect_publish(to_service(key, "execution.watch"), matches)?;
    Ok(())
}

/// States that neither the topology watchers of `organization` nor the host `key` hear of a
/// change.
pub fn expect_no_topology_change<F>(
    context: &TestContext<F>,
    organization: &Organization,
    key: &str,
) -> Result<()> {
    context.expect_no_publish(to_organization(organization, "topology.watch"))?;
    context.expect_no_publish(to_service(key, "execution.watch"))
}

/// Expects the service watchers of `organization` to learn that the service `key` is now
/// `status`, seen at a real time.
pub fn expect_status_update<F>(
    context: &TestContext<F>,
    organization: &Organization,
    key: &'static str,
    status: ServiceStatus,
) -> Result<()> {
    context.expect_publish(
        to_organization(organization, "services.watch"),
        move |event: &OrganizationServicesChanged| {
            matches!(event, OrganizationServicesChanged::Update(service)
            if service.service_id.key.to_string() == key
                && service.state.as_ref().is_some_and(|state| {
                    state.status == status && state.last_seen > UNIX_EPOCH
                }))
        },
    )?;
    Ok(())
}

/// A host configuration that cannot be carried out.
#[derive(Debug)]
pub enum InvalidHostConfiguration {
    /// The engine joins a Realm that does not exist.
    MissingRealm,
    /// The host runs its own Realm, while its engine joins a Realm that does not exist.
    MissingRealmWithHostedRealm,
    /// The engine is one the host does not advertise.
    IncompatibleEngine,
}
