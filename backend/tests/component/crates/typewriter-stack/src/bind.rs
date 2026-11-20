//! Binds hosts to the stack's organization the way an owner does by hand, through the owner's
//! panel session and the binder the component suite proves (`typewriter_component_test::binder`).
//!
//! The Realm host gets a hosted Realm, and `bind` exits once that Realm is active. With
//! `--as-engine`, `bind` serves the game suite's Paper slots instead: each slot's loader writes its
//! token to `<work-dir>/<slot>/registration-token` when its Paper first boots, and `bind` names that
//! service `game_paper_<slot>` and attaches it to the stack's Realm as the Paper engine. It keeps
//! running, since own Papers boot only when a restart requirement runs.

use std::path::PathBuf;
use std::time::Duration;

use anyhow::{Context as _, Result, bail};
use serde::Serialize;
use typewriter_component_test::binder::{
    self, EngineSlots, OwnerRoutes, configure, deadline, paper_engine, topology,
};
use wasmcloud_utils::SkirType;
use wasmcloud_utils::skir::base::service::v1::topology::{
    ChildRuntimeStatus, HostExecutionConfiguration, HostedRealmConfiguration,
};
use wasmcloud_utils::transport::RequestRoute;

use crate::provision::Provisioned;
use crate::session::{Session, StackEndpoints, record_token};

#[derive(clap::Args)]
pub struct BindArgs {
    #[command(flatten)]
    endpoints: StackEndpoints,
    /// The host's work directory, where it writes `state/registration-token`; with `--as-engine`,
    /// the folder holding one folder per game Paper slot.
    #[arg(long = "work-dir")]
    work_dir: PathBuf,
    /// Binds each game Paper slot as the Paper engine of the stack's Realm, and keeps running.
    #[arg(long = "as-engine")]
    as_engine: bool,
}

/// How long the Realm host may take to write its token, be bound and advertise itself.
const REALM_HOST_WITHIN: Duration = Duration::from_secs(120);
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
    if args.as_engine {
        return bind_engines(args).await;
    }
    let endpoints = args.endpoints;
    let provisioned = Provisioned::read(&endpoints)?;
    let owner = Owner::sign_in(&endpoints, &provisioned).await?;
    let host = deadline(
        "the Realm host to bind",
        REALM_HOST_WITHIN,
        binder::bind(&owner, &args.work_dir.join("state/registration-token")),
    )
    .await?;
    let change = configure(
        &owner,
        &host,
        HostExecutionConfiguration {
            realm: Some(HostedRealmConfiguration {
                primary_engine: paper_engine(),
                ..Default::default()
            }),
            ..Default::default()
        },
    )
    .await?;
    let realm = change
        .realm
        .context("ConfigureServiceHost assigned no Realm")?
        .realm_id;

    deadline(
        "the Realm to become active",
        Duration::from_secs(120),
        async {
            loop {
                let snapshot = topology(&owner).await?;
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
        service: record_token(&host.service_id)?.as_str().to_owned(),
        host: record_token(&host.host_id)?.as_str().to_owned(),
        realm: record_token(&realm)?.as_str().to_owned(),
    };
    let file = endpoints.state.join("bound.json");
    let text = serde_json::to_string_pretty(&bound)?;
    std::fs::write(&file, &text).with_context(|| format!("cannot write {}", file.display()))?;
    println!("{text}");
    Ok(())
}

/// Binds every game Paper slot when its loader first asks to be bound, until the stack stops.
async fn bind_engines(args: BindArgs) -> Result<()> {
    let endpoints = args.endpoints;
    let provisioned = Provisioned::read(&endpoints)?;
    // Signing in once before the slots wait proves the owner can bind them later.
    Owner::sign_in(&endpoints, &provisioned).await?;
    let slots = EngineSlots {
        work_dir: args.work_dir.clone(),
    };
    slots.prepare()?;
    std::fs::write(args.work_dir.join("watching"), "")
        .context("cannot mark the engine binder as watching")?;
    let bind_every = slots.bind_every(
        || Owner::sign_in(&endpoints, &provisioned),
        |slot| {
            println!(
                "bound game Paper slot {}: service {}, engine {:?}",
                slot.slot,
                slot.host.service_id,
                slot.change
                    .engine
                    .map(|engine| engine.engine_id.to_string())
            );
        },
    );
    tokio::select! {
        _ = crate::shutdown_signal() => Ok(()),
        failed = bind_every => match failed? {},
    }
}

/// The stack's owner, signed in to its organization through the panel's gateway.
struct Owner {
    session: Session,
    scope: String,
}

impl Owner {
    async fn sign_in(endpoints: &StackEndpoints, provisioned: &Provisioned) -> Result<Self> {
        let owner = endpoints.owner()?;
        let session =
            Session::sign_in(endpoints, &owner, Some(&provisioned.organization_record())).await?;
        let scope = format!(
            "cloud.to.user.{}.organization.{}",
            session.user(),
            session.organization()?
        );
        Ok(Self { session, scope })
    }
}

impl OwnerRoutes for Owner {
    async fn request<R: RequestRoute>(
        &self,
        route: &str,
        request: &R::Request,
    ) -> Result<R::Response>
    where
        R::Request: SkirType + Sync,
        R::Response: SkirType + Send,
    {
        self.session
            .request::<R>(format!("{}.{route}", self.scope), request)
            .await
    }
}
