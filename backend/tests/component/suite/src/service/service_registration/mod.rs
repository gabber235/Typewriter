use typewriter_component_test::prelude::*;
use wasmcloud_utils::skir::base::{
    kernel::v1::record_id::RecordId,
    service::v1::topology::{
        ConfigureServiceHostRequest, ConfigureServiceHostResponse, EngineRealmSelection,
        EngineRealmSelection_ExistingRealm, EngineTarget, HostConfigurationChange,
        HostExecutionConfiguration, HostedEngineConfiguration, HostedRealmConfiguration,
        RegisterServiceHostRequest, RegisterServiceHostResponse, SupportedEngine,
    },
};

mod binding;
mod lifecycle;
mod management;
mod status;
mod topology;

#[component_fixture(
    id = "service-registration",
    primary(package = "service-registration", target = "service_registration")
)]
pub struct ServiceRegistration;

impl FixtureSpec for ServiceRegistration {
    fn configure(builder: FixtureBuilder<Self>) -> FixtureBuilder<Self> {
        builder
            .messaging_subscriptions(
                wasmcloud_utils::transport_routes::service_registration::SUBSCRIPTIONS,
            )
            .otel()
            .typewriter_database(SchemaPreset::Registration)
    }
}

type Context = TestContext<ServiceRegistration>;

/// The subject on which the service `key` calls `route` of the registration component.
fn from_service(key: &str, route: &str) -> String {
    format!("typewriter.from.service.{key}.{route}")
}

/// The subject on which the registration component tells the service `key` about `event`.
fn to_service(key: &str, event: &str) -> String {
    format!("typewriter.to.service.{key}.{event}")
}

/// An organization other than Acme, founded by Grace.
fn globex() -> Organization {
    Organization::new("globex")
}

/// Acme, founded by Ada, with the bound service `key`. Organizations and services come from
/// other components.
async fn acme_with_service(context: &Context, key: &str) -> anyhow::Result<()> {
    Seed::new()
        .organization(&acme(), ada())
        .organization_service(&acme(), key)
        .apply(&context.database()?)
        .await
}

/// The record of the host that the service `key` runs; a host shares its service's key.
fn host_id(key: &str) -> RecordId {
    skir_record_id("service_host", key)
}

/// The Paper engine every host in these cases advertises unless a case says otherwise.
fn paper() -> EngineTarget {
    EngineTarget {
        engine_id: "paper".into(),
        version_constraint: "^1".into(),
        ..Default::default()
    }
}

/// A host running a Realm of its own and an engine attached to that Realm, both on `target`.
fn realm_with_engine(target: EngineTarget) -> HostExecutionConfiguration {
    HostExecutionConfiguration {
        realm: Some(HostedRealmConfiguration {
            primary_engine: target.clone(),
            ..Default::default()
        }),
        primary_engine: Some(HostedEngineConfiguration {
            target,
            realm: EngineRealmSelection::HostedRealm,
            ..Default::default()
        }),
        ..Default::default()
    }
}

/// A host running only a Realm whose primary engine is `target`.
fn realm_only(target: EngineTarget) -> HostExecutionConfiguration {
    HostExecutionConfiguration {
        realm: Some(HostedRealmConfiguration {
            primary_engine: target,
            ..Default::default()
        }),
        ..Default::default()
    }
}

/// A host running only an engine on `target`, attached to the existing Realm `realm`.
fn engine_in(realm: RecordId, target: EngineTarget) -> HostExecutionConfiguration {
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

/// The bound service `key` advertises a host that can run a Realm and the given engines.
async fn register_host(context: &Context, key: &str, engines: &[&str]) -> anyhow::Result<()> {
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

/// Ada configures Acme's host `key`.
async fn configure(
    context: &Context,
    key: &str,
    expected_revision: i64,
    execution: HostExecutionConfiguration,
) -> anyhow::Result<ConfigureServiceHostResponse> {
    context
        .request(
            from_member(ada(), &acme(), "topology.configure"),
            &configure_request(key, expected_revision, execution),
        )
        .await
}

/// Ada configures Acme's host `key` as setup and returns the accepted change.
async fn arrange_configuration(
    context: &Context,
    key: &str,
    expected_revision: i64,
    execution: HostExecutionConfiguration,
) -> anyhow::Result<HostConfigurationChange> {
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
        host_id: host_id(key),
        expected_revision,
        execution,
        ..Default::default()
    }
}
