//! Binds hosts to an organization the way its owner does by hand, every step a real route of the
//! owner: `BindService` with the token a loader wrote, then the organization topology until the
//! host advertises, then `ConfigureServiceHost`. The stack's `bind` drives it through the owner's
//! panel session; the component suite drives it through member subjects, so both prove one binder.
//!
//! [`EngineSlots`] serves the game suite's Paper slots: each slot's loader writes its pending
//! registration token to `<work-dir>/<slot>/registration-token` when its Paper first boots, and the
//! binder names that service `game_paper_<slot>` and attaches its host to the organization's Realm
//! as the Paper engine.

use std::future::Future;
use std::path::{Path, PathBuf};
use std::time::Duration;

use anyhow::{Context as _, Result, bail};
use futures_util::future::try_join_all;
use wasmcloud_utils::SkirType;
use wasmcloud_utils::skir::base::kernel::v1::record_id::RecordId;
use wasmcloud_utils::skir::base::service::v1::organization::{
    UpdateOrganizationServiceRequest, UpdateOrganizationServiceResponse,
};
use wasmcloud_utils::skir::base::service::v1::registration::{
    BindServiceRequest, BindServiceResponse,
};
use wasmcloud_utils::skir::base::service::v1::topology::{
    ConfigureServiceHostRequest, ConfigureServiceHostResponse, EngineTarget,
    HostConfigurationChange, HostExecutionConfiguration, OrganizationTopologySnapshot, ServiceHost,
    WatchOrganizationTopologyRequest, WatchOrganizationTopologyResponse,
};

use crate::service::engine_in;
use crate::skir_record_id;

/// How often the binder looks again at a token file or the topology.
const POLL: Duration = Duration::from_millis(200);

/// The routes of an organization's owner, named relative to the organization (`services.bind`).
pub trait OwnerRoutes: Send + Sync {
    /// Sends `request` on the organization's `route` and decodes the reply.
    fn request<Req: SkirType + Sync, Resp: SkirType + Send>(
        &self,
        route: &str,
        request: &Req,
    ) -> impl Future<Output = Result<Resp>> + Send;
}

/// The engine every game Paper slot runs.
pub fn paper_engine() -> EngineTarget {
    EngineTarget {
        engine_id: "typewritermc:paper".into(),
        version_constraint: ">=0.0.0".into(),
        ..Default::default()
    }
}

/// Binds the service whose pending token is in `token_file`, and returns its host once it
/// advertised, however long that takes: the process that wrote the token may stop first, and a
/// later process with the same identity advertises the service. A token that no longer binds,
/// because its loader rotated it or its service is bound already, is waited past until the file
/// holds another. A caller that needs a bound host by some time sets its own [`deadline`].
pub async fn bind(owner: &impl OwnerRoutes, token_file: &Path) -> Result<ServiceHost> {
    let mut refused = None;
    let service = loop {
        let token = wait_for_token(token_file, refused.as_deref()).await?;
        let response: BindServiceResponse = owner
            .request(
                "services.bind",
                &BindServiceRequest {
                    registration_token: token.clone(),
                    ..Default::default()
                },
            )
            .await
            .context("BindService")?;
        match response {
            BindServiceResponse::Success(success) => break success.service_id,
            BindServiceResponse::InvalidRegistrationTokenError(_) => refused = Some(token),
            other => bail!("BindService failed: {other:?}"),
        }
    };
    loop {
        if let Some(host) = advertised(&topology(owner).await?, &service) {
            return Ok(host);
        }
        tokio::time::sleep(POLL).await;
    }
}

/// The organization's topology as the backend holds it now.
pub async fn topology(owner: &impl OwnerRoutes) -> Result<OrganizationTopologySnapshot> {
    let response: WatchOrganizationTopologyResponse = owner
        .request(
            "topology.watch",
            &WatchOrganizationTopologyRequest::default(),
        )
        .await
        .context("WatchOrganizationTopology")?;
    match response {
        WatchOrganizationTopologyResponse::List(snapshot) => Ok(*snapshot),
        other => bail!("WatchOrganizationTopology failed: {other:?}"),
    }
}

/// Configures `host` to run `execution`, at the revision it advertised.
pub async fn configure(
    owner: &impl OwnerRoutes,
    host: &ServiceHost,
    execution: HostExecutionConfiguration,
) -> Result<HostConfigurationChange> {
    let response: ConfigureServiceHostResponse = owner
        .request(
            "topology.configure",
            &ConfigureServiceHostRequest {
                host_id: host.host_id.clone(),
                expected_revision: host.revision,
                execution,
                ..Default::default()
            },
        )
        .await
        .context("ConfigureServiceHost")?;
    match response {
        ConfigureServiceHostResponse::Success(change) => Ok(*change),
        other => bail!("ConfigureServiceHost failed: {other:?}"),
    }
}

/// Names the service `name`, as an owner does in the panel; a stale revision is retried at the
/// current one.
pub async fn rename(owner: &impl OwnerRoutes, service: &RecordId, name: &str) -> Result<()> {
    let mut revision = 0;
    loop {
        let response: UpdateOrganizationServiceResponse = owner
            .request(
                "services.update",
                &UpdateOrganizationServiceRequest {
                    service_id: service.clone(),
                    expected_revision: revision,
                    name: name.into(),
                    ..Default::default()
                },
            )
            .await
            .context("UpdateOrganizationService")?;
        match response {
            UpdateOrganizationServiceResponse::Success(_) => return Ok(()),
            UpdateOrganizationServiceResponse::ConflictError(conflict)
                if conflict.actual.revision != revision =>
            {
                revision = conflict.actual.revision;
            }
            other => bail!("UpdateOrganizationService failed: {other:?}"),
        }
    }
}

/// The game suite's Paper slots, numbered from 0, each with a folder in `work_dir`. A slot keeps
/// its loader's identity across its Papers, so a slot whose Paper stopped before it advertised is
/// attached once a later Paper of that slot advertises.
pub struct EngineSlots {
    pub work_dir: PathBuf,
    pub slots: u8,
}

/// A slot the binder attached to the Realm.
#[derive(Debug, Clone, PartialEq)]
pub struct BoundSlot {
    pub slot: u8,
    pub host: ServiceHost,
    pub change: HostConfigurationChange,
}

impl EngineSlots {
    /// Where slot `slot`'s loader writes its pending registration token.
    pub fn token_file(&self, slot: u8) -> PathBuf {
        self.work_dir
            .join(slot.to_string())
            .join("registration-token")
    }

    /// Creates every slot's folder, without a token: a token an earlier run left names a
    /// service of that run.
    pub fn prepare(&self) -> Result<()> {
        for slot in 0..self.slots {
            let token = self.token_file(slot);
            let folder = token.parent().context("a token file has no folder")?;
            std::fs::create_dir_all(folder)
                .with_context(|| format!("cannot create {}", folder.display()))?;
            match std::fs::remove_file(&token) {
                Err(error) if error.kind() != std::io::ErrorKind::NotFound => {
                    return Err(error).with_context(|| format!("cannot clear {}", token.display()));
                }
                _ => {}
            }
        }
        Ok(())
    }

    /// Binds every slot once its loader wrote a token, signing in again for each slot, since a
    /// slot's Paper may boot long after the binder started. Fails as soon as one slot fails.
    pub async fn bind_all<O, S, F>(&self, sign_in: S) -> Result<Vec<BoundSlot>>
    where
        O: OwnerRoutes,
        S: Fn() -> F,
        F: Future<Output = Result<O>>,
    {
        try_join_all((0..self.slots).map(|slot| {
            let token = self.token_file(slot);
            let sign_in = &sign_in;
            async move {
                wait_for_token(&token, None).await?;
                let owner = sign_in().await?;
                self.bind_slot(&owner, slot)
                    .await
                    .with_context(|| format!("binding game Paper slot {slot}"))
            }
        }))
        .await
    }

    /// Binds slot `slot`, names its service `game_paper_<slot>` and attaches its host to the
    /// organization's Realm as the Paper engine.
    pub async fn bind_slot(&self, owner: &impl OwnerRoutes, slot: u8) -> Result<BoundSlot> {
        let host = bind(owner, &self.token_file(slot)).await?;
        rename(owner, &host.service_id, &format!("game_paper_{slot}")).await?;
        let realm = topology(owner)
            .await?
            .realms
            .first()
            .context("the organization has no Realm to attach the engine to")?
            .realm_id
            .clone();
        let change = configure(owner, &host, engine_in(realm, paper_engine())).await?;
        if change.engine.is_none() {
            bail!("ConfigureServiceHost assigned no engine");
        }
        Ok(BoundSlot { slot, host, change })
    }
}

/// The host the bound service `service` advertised, matched by the service's record key.
fn advertised(snapshot: &OrganizationTopologySnapshot, service: &str) -> Option<ServiceHost> {
    let id = skir_record_id("service", service);
    snapshot
        .hosts
        .iter()
        .find(|host| host.service_id == id || host.service_id.to_string() == service)
        .cloned()
}

/// Waits until `file` holds a token other than `refused`, and returns it trimmed.
async fn wait_for_token(file: &Path, refused: Option<&str>) -> Result<String> {
    loop {
        match tokio::fs::read_to_string(file).await {
            Ok(text) => {
                let token = text.trim();
                if !token.is_empty() && Some(token) != refused {
                    return Ok(token.to_owned());
                }
            }
            Err(error) if error.kind() == std::io::ErrorKind::NotFound => {}
            Err(error) => return Err(error).with_context(|| format!("reading {}", file.display())),
        }
        tokio::time::sleep(POLL).await;
    }
}

/// Runs `work` for at most `limit`, failing with a message that names `step`.
pub async fn deadline<T>(
    step: &str,
    limit: Duration,
    work: impl Future<Output = Result<T>>,
) -> Result<T> {
    tokio::time::timeout(limit, work)
        .await
        .with_context(|| format!("timed out after {}s waiting for {step}", limit.as_secs()))?
}

/// The binder's slots in a scratch folder of their own, removed when dropped.
pub struct ScratchSlots(pub EngineSlots);

impl ScratchSlots {
    /// `slots` slots in a fresh scratch folder.
    pub fn new(slots: u8) -> Result<Self> {
        let engines = EngineSlots {
            work_dir: std::env::temp_dir().join(format!("engine-slots-{}", uuid::Uuid::new_v4())),
            slots,
        };
        engines.prepare()?;
        Ok(Self(engines))
    }

    /// Writes `token` as slot `slot`'s pending registration token, as its loader does.
    pub fn write_token(&self, slot: u8, token: &str) -> Result<()> {
        let file = self.0.token_file(slot);
        std::fs::write(&file, token).with_context(|| format!("cannot write {}", file.display()))
    }
}

impl Drop for ScratchSlots {
    fn drop(&mut self) {
        let _ = std::fs::remove_dir_all(&self.0.work_dir);
    }
}

/// An organization member's routes on a component fixture (`typewriter.from.user...`), so the
/// component suite drives the binder the stack drives through the panel's gateway.
pub struct MemberRoutes<'a, F> {
    pub context: &'a component_test::TestContext<F>,
    pub user: &'a crate::StackUser,
    pub organization: crate::Organization,
}

impl<F> OwnerRoutes for MemberRoutes<'_, F>
where
    component_test::TestContext<F>: Sync,
    F: Sync,
{
    fn request<Req: SkirType + Sync, Resp: SkirType + Send>(
        &self,
        route: &str,
        request: &Req,
    ) -> impl Future<Output = Result<Resp>> + Send {
        crate::TypewriterContext::request(
            self.context,
            crate::topology::from_member(self.user, &self.organization, route),
            request,
        )
    }
}

/// Expects what the binder causes for the slot service `key` in `organization`: its host hears it
/// was bound, its watchers hear of the bind and, when `attached`, of its new name, its host's
/// advertisement and configuration, and the host hears its desired execution.
pub fn expect_slot<F>(
    context: &component_test::TestContext<F>,
    organization: &crate::Organization,
    key: &str,
    attached: bool,
) -> Result<()> {
    use crate::TypewriterContext as _;
    use crate::topology::{to_organization, to_service};
    use wasmcloud_utils::skir::base::service::v1::organization::OrganizationServicesChanged;
    use wasmcloud_utils::skir::base::service::v1::registration::ServiceBoundNotification;
    use wasmcloud_utils::skir::base::service::v1::topology::{
        OrganizationTopologyChanged, WatchHostExecutionResponse,
    };

    let organization_id = organization.key.to_string();
    context.expect_publish(
        to_service(key, "registration.bound"),
        move |bound: &ServiceBoundNotification| bound.organization_id == organization_id,
    )?;
    let changes = if attached { 2 } else { 1 };
    context
        .expect_publish(
            to_organization(organization, "services.watch"),
            |_: &OrganizationServicesChanged| true,
        )?
        .times(changes);
    if attached {
        let advertised = skir_record_id("service_host", key);
        context.expect_publish(
            to_organization(organization, "topology.watch"),
            move |event: &OrganizationTopologyChanged| {
                matches!(event, OrganizationTopologyChanged::HostAdvertised(host) if host.host_id == advertised)
            },
        )?;
        let configured = skir_record_id("service_host", key);
        context.expect_publish(
            to_organization(organization, "topology.watch"),
            move |event: &OrganizationTopologyChanged| {
                matches!(event, OrganizationTopologyChanged::ConfigurationChanged(change)
                    if change.host.host_id == configured)
            },
        )?;
        context.expect_publish(
            to_service(key, "execution.watch"),
            |_: &WatchHostExecutionResponse| true,
        )?;
    }
    Ok(())
}
