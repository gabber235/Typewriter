//! Binds a host to the stack's organization the way an owner does by hand, every step a real
//! route with the owner's credentials: `BindService` with the token the loader wrote, then the
//! organization topology until the host advertises, then `ConfigureServiceHost` assigning it a
//! hosted Realm, then the topology again until that Realm reports active. Each wait has a deadline
//! and fails naming its step, so a host that never advertises says so instead of hanging.

use std::future::Future;
use std::path::{Path, PathBuf};
use std::time::Duration;

use anyhow::{Context as _, Result, bail};
use serde::Serialize;
use wasmcloud_utils::skir::base::service::v1::registration::{
    BindServiceRequest, BindServiceResponse,
};
use wasmcloud_utils::skir::base::service::v1::topology::{
    ChildRuntimeStatus, ConfigureServiceHostRequest, ConfigureServiceHostResponse, EngineTarget,
    HostExecutionConfiguration, HostedRealmConfiguration, OrganizationTopologySnapshot,
    ServiceHost, WatchOrganizationTopologyRequest, WatchOrganizationTopologyResponse,
};
use wasmcloud_utils::transport_routes::{
    OrganizationTopologyWatchRoute, ServiceBindRoute, ServiceTopologyConfigureRoute,
};

use crate::provision::Provisioned;
use crate::session::{Session, StackEndpoints, record_token};

#[derive(clap::Args)]
pub struct BindArgs {
    #[command(flatten)]
    endpoints: StackEndpoints,
    /// The host's work directory, where it writes `state/registration-token`.
    #[arg(long = "work-dir")]
    work_dir: PathBuf,
}

/// The engine the hosted Realm targets. A standalone host advertises no engine of its own, so the
/// Realm targets the Paper engine its game servers attach with.
const REALM_ENGINE: &str = "typewritermc:paper";
const POLL: Duration = Duration::from_millis(500);

/// What `bind` bound, written to `bound.json` in the stack's state directory and printed.
#[derive(Serialize)]
struct Bound {
    organization: String,
    service: String,
    host: String,
    realm: String,
}

pub async fn run(args: BindArgs) -> Result<()> {
    let endpoints = args.endpoints;
    let provisioned = Provisioned::read(&endpoints)?;
    let owner = endpoints.owner()?;
    let owner =
        Session::sign_in(&endpoints, &owner, Some(&provisioned.organization_record())).await?;
    let scope = format!(
        "cloud.to.user.{}.organization.{}",
        owner.user(),
        owner.organization()?
    );

    let token_file = args.work_dir.join("state/registration-token");
    let service = deadline("BindService", Duration::from_secs(60), async {
        loop {
            let token = wait_for_file(&token_file).await?;
            let response = owner
                .request::<ServiceBindRoute>(
                    format!("{scope}.services.bind"),
                    &BindServiceRequest {
                        registration_token: token.trim().to_owned(),
                        ..Default::default()
                    },
                )
                .await?;
            match response {
                BindServiceResponse::Success(success) => return Ok(success.service_id),
                // The token rotated between reading and binding; read the new one.
                BindServiceResponse::InvalidRegistrationTokenError(_) => {
                    tokio::time::sleep(POLL).await;
                }
                other => bail!("BindService failed: {other:?}"),
            }
        }
    })
    .await?;

    let topology = || async {
        match owner
            .request::<OrganizationTopologyWatchRoute>(
                format!("{scope}.topology.watch"),
                &WatchOrganizationTopologyRequest::default(),
            )
            .await?
        {
            WatchOrganizationTopologyResponse::List(snapshot) => Ok(*snapshot),
            other => bail!("WatchOrganizationTopology failed: {other:?}"),
        }
    };
    let host = deadline("the host to advertise", Duration::from_secs(60), async {
        loop {
            if let Some(host) = advertised(&topology().await?, &service) {
                return Ok(host);
            }
            tokio::time::sleep(POLL).await;
        }
    })
    .await?;

    let response = owner
        .request::<ServiceTopologyConfigureRoute>(
            format!("{scope}.topology.configure"),
            &ConfigureServiceHostRequest {
                host_id: host.host_id.clone(),
                expected_revision: host.revision,
                execution: HostExecutionConfiguration {
                    realm: Some(HostedRealmConfiguration {
                        primary_engine: EngineTarget {
                            engine_id: REALM_ENGINE.into(),
                            version_constraint: ">=0.0.0".into(),
                            ..Default::default()
                        },
                        ..Default::default()
                    }),
                    ..Default::default()
                },
                ..Default::default()
            },
        )
        .await
        .context("ConfigureServiceHost")?;
    let ConfigureServiceHostResponse::Success(change) = response else {
        bail!("ConfigureServiceHost failed: {response:?}");
    };
    let realm = change
        .realm
        .context("ConfigureServiceHost assigned no Realm")?
        .realm_id;

    deadline(
        "the Realm to become active",
        Duration::from_secs(120),
        async {
            loop {
                let snapshot = topology().await?;
                let state = snapshot
                    .realms
                    .iter()
                    .find(|instance| instance.realm_id == realm)
                    .map(|instance| &instance.state);
                match state.map(|state| &state.status) {
                    Some(ChildRuntimeStatus::Active) => return Ok(()),
                    Some(ChildRuntimeStatus::Failed) => bail!(
                        "the Realm failed: {}",
                        state
                            .and_then(|state| state.message.clone())
                            .unwrap_or_default()
                    ),
                    _ => tokio::time::sleep(POLL).await,
                }
            }
        },
    )
    .await?;

    let bound = Bound {
        organization: provisioned.organization,
        service,
        host: record_token(&host.host_id)?.as_str().to_owned(),
        realm: record_token(&realm)?.as_str().to_owned(),
    };
    let file = endpoints.state.join("bound.json");
    let text = serde_json::to_string_pretty(&bound)?;
    std::fs::write(&file, &text).with_context(|| format!("cannot write {}", file.display()))?;
    println!("{text}");
    Ok(())
}

/// The host the bound service advertised, matched by the service's record key.
fn advertised(snapshot: &OrganizationTopologySnapshot, service: &str) -> Option<ServiceHost> {
    snapshot
        .hosts
        .iter()
        .find(|host| {
            record_token(&host.service_id).is_ok_and(|token| token.as_str() == service)
                || host.service_id.to_string() == service
        })
        .cloned()
}

async fn wait_for_file(file: &Path) -> Result<String> {
    loop {
        match tokio::fs::read_to_string(file).await {
            Ok(text) if !text.trim().is_empty() => return Ok(text),
            Ok(_) => {}
            Err(error) if error.kind() == std::io::ErrorKind::NotFound => {}
            Err(error) => return Err(error).with_context(|| format!("reading {}", file.display())),
        }
        tokio::time::sleep(POLL).await;
    }
}

async fn deadline<T>(
    step: &str,
    limit: Duration,
    work: impl Future<Output = Result<T>>,
) -> Result<T> {
    tokio::time::timeout(limit, work)
        .await
        .with_context(|| format!("timed out after {}s waiting for {step}", limit.as_secs()))?
}
