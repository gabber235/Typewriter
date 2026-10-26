//! Typewriter's services, each one process, and the compositions suites start.
//!
//! The broker, identity stand in, backend host, provisioning and binding are subcommands of the
//! `typewriter-stack` binary in the component test workspace, so the wasm host and its heavy
//! dependencies stay out of xtask.

use std::fs;
use std::path::{Path, PathBuf};
use std::process::Command;
use std::time::Duration;

use anyhow::{Context as _, Result};
use serde_json::Value;

use super::client_configuration::{ClientConfiguration, FIXTURE_USERS};
use super::spec::{Probe, Published, Service, ServiceId, StackContext, StackSpec};
use crate::{CommandExt, deploy, generate};

/// The component test workspace the `typewriter-stack` binary lives in.
const STACK_WORKSPACE: &str = "backend/tests/component/Cargo.toml";

/// The broker, the identity stand in and every backend component.
pub fn backend() -> StackSpec {
    StackSpec::default()
        .with(Faults)
        .with(Broker)
        .with(Identity)
        .with(Backend)
}

/// The backend plus the provisioned organization and a standalone Realm host bound to it, for
/// the panel suites.
pub fn panel() -> StackSpec {
    backend()
        .with(Provision)
        .with(RealmHost)
        .with(BindRealmHost)
}

/// The toxiproxy server the panel's NATS link goes through, so scenarios can cut it.
pub struct Faults;

impl Service for Faults {
    const ID: ServiceId = ServiceId("faults");
    fn command(&self, ctx: &StackContext) -> Result<Command> {
        let mut command = Command::new("toxiproxy-server");
        command
            .args(["-host", "127.0.0.1", "-port"])
            .arg(ctx.port("faults").to_string());
        Ok(command)
    }
    fn ready(&self, ctx: &StackContext) -> Probe {
        Probe::http(ctx.port("faults"), "/version")
    }
}

/// NATS with the TYPEWRITER account, auth callout and sentinel installed, plus the account
/// service tests use.
pub struct Broker;

impl Service for Broker {
    const ID: ServiceId = ServiceId("broker");
    fn command(&self, ctx: &StackContext) -> Result<Command> {
        let mut command = stack_binary(ctx, "broker")?;
        command
            .arg("--state")
            .arg(ctx.state())
            .args(ctx.port_args(&["nats", "websocket", "accounts"]));
        Ok(command)
    }
    fn ready(&self, ctx: &StackContext) -> Probe {
        Probe::http(ctx.port("accounts"), "/ready")
    }
}

/// The Authentik surface Typewriter calls (identity stand in).
pub struct Identity;

impl Service for Identity {
    const ID: ServiceId = ServiceId("identity");
    fn command(&self, ctx: &StackContext) -> Result<Command> {
        let mut command = stack_binary(ctx, "identity")?;
        command
            .arg("--users")
            .arg(ctx.root().join(FIXTURE_USERS))
            .args(ctx.port_args(&["identity"]));
        Ok(command)
    }
    fn ready(&self, ctx: &StackContext) -> Probe {
        Probe::http(
            ctx.port("identity"),
            "/application/o/typewriter-panel/.well-known/openid-configuration",
        )
    }
}

/// Every deployable backend component in one wash host.
pub struct Backend;

impl Service for Backend {
    const ID: ServiceId = ServiceId("backend");
    fn needs(&self) -> &'static [ServiceId] {
        &[Broker::ID, Identity::ID, Faults::ID]
    }
    fn command(&self, ctx: &StackContext) -> Result<Command> {
        let components = deployable_components(ctx)?;
        let mut command = stack_binary(ctx, "host")?;
        command
            .arg("--state")
            .arg(ctx.state())
            .args(ctx.port_args(&["http", "nats-proxy", "faults", "identity"]));
        for (package, artifact) in components {
            command
                .arg("--component")
                .arg(format!("{package}={}", artifact.display()));
        }
        Ok(command)
    }
    fn ready(&self, ctx: &StackContext) -> Probe {
        Probe::FileExists(ctx.state().join("backend/ready"))
    }
    fn startup(&self) -> Duration {
        Duration::from_secs(120)
    }
    fn publish(&self, ctx: &StackContext, out: &mut Published) -> Result<()> {
        let clients = ClientConfiguration::worktree(ctx)?;
        out.values.extend([
            ("STACK_API_BASE_URL".into(), clients.api_base_url.clone()),
            ("STACK_AUTH_ISSUER".into(), clients.auth_issuer.clone()),
            ("STACK_NATS_URL".into(), clients.nats_host_url.clone()),
            (
                "STACK_NATS_DESKTOP_URL".into(),
                clients.nats_desktop_url.clone(),
            ),
            ("STACK_NATS_WEB_URL".into(), clients.nats_web_url.clone()),
            (
                "STACK_PANEL_DEFINES".into(),
                ctx.state().join("panel.json").display().to_string(),
            ),
            (
                "TYPEWRITER_CONFIG_FILE".into(),
                ctx.state().join("realm.properties").display().to_string(),
            ),
        ]);
        out.clients = Some(clients);
        Ok(())
    }
}

/// The stack's organization, created by its owner through the real organization route.
pub struct Provision;

impl Service for Provision {
    const ID: ServiceId = ServiceId("provision");
    fn needs(&self) -> &'static [ServiceId] {
        &[Backend::ID]
    }
    fn command(&self, ctx: &StackContext) -> Result<Command> {
        let mut command = stack_binary(ctx, "provision")?;
        command.args(owner_args(ctx));
        Ok(command)
    }
    fn ready(&self, _: &StackContext) -> Probe {
        Probe::ExitSuccess
    }
    fn publish(&self, ctx: &StackContext, out: &mut Published) -> Result<()> {
        let provisioned = read_json(&ctx.state().join("provisioned.json"))?;
        out.values.extend([
            (
                "STACK_ORGANIZATION".into(),
                field(&provisioned, "organization")?,
            ),
            ("STACK_OWNER".into(), field(&provisioned, "owner")?),
        ]);
        Ok(())
    }
}

/// The standalone loader, the host the provisioned organization's Realm runs on.
pub struct RealmHost;

/// The Gradle project of the standalone loader and where `installDist` puts it.
const REALM_HOST_PROJECT: &str = ":loader-standalone";
const REALM_HOST_INSTALL: &str =
    "services/runtime/loader/standalone/build/install/loader-standalone/bin/loader-standalone";

impl Service for RealmHost {
    const ID: ServiceId = ServiceId("realm");
    fn needs(&self) -> &'static [ServiceId] {
        &[Provision::ID]
    }
    fn command(&self, ctx: &StackContext) -> Result<Command> {
        let work_dir = realm_host_dir(ctx);
        let inbox = format!(
            "-PtypewriterArtifactInbox={}",
            work_dir.join("artifacts/inbox").display()
        );
        ctx.build_once("the standalone Realm host", || {
            ctx.ctx
                .tool(
                    "services",
                    "./gradlew",
                    &[
                        "--quiet",
                        &format!("{REALM_HOST_PROJECT}:installDist"),
                        // The Realm and engine artifacts, published into the host's inbox.
                        "assembleDevelopmentArtifacts",
                        &inbox,
                    ],
                )
                .run()
        })?;
        fs::create_dir_all(&work_dir)
            .with_context(|| format!("cannot create {}", work_dir.display()))?;
        let mut command = Command::new(ctx.root().join(REALM_HOST_INSTALL));
        command
            .arg(&work_dir)
            .current_dir(&work_dir)
            .env(
                "TYPEWRITER_CONFIG_FILE",
                ctx.state().join("realm.properties"),
            )
            // Opts in to the token file `ready` waits for and `bind` reads.
            .env(
                "TYPEWRITER_REGISTRATION_TOKEN_FILE",
                work_dir.join("state/registration-token"),
            );
        Ok(command)
    }
    /// The loader is registered and waiting to be bound.
    fn ready(&self, ctx: &StackContext) -> Probe {
        Probe::FileExists(realm_host_dir(ctx).join("state/registration-token"))
    }
    fn startup(&self) -> Duration {
        Duration::from_secs(180)
    }
}

/// Binds the standalone loader to the stack's organization through the real routes and assigns
/// it the organization's Realm; done when that Realm is active.
pub struct BindRealmHost;

impl Service for BindRealmHost {
    const ID: ServiceId = ServiceId("bind-realm-host");
    fn needs(&self) -> &'static [ServiceId] {
        &[RealmHost::ID]
    }
    fn command(&self, ctx: &StackContext) -> Result<Command> {
        let mut command = stack_binary(ctx, "bind")?;
        command
            .args(owner_args(ctx))
            .arg("--work-dir")
            .arg(realm_host_dir(ctx));
        Ok(command)
    }
    fn ready(&self, _: &StackContext) -> Probe {
        Probe::ExitSuccess
    }
    fn startup(&self) -> Duration {
        Duration::from_secs(300)
    }
    fn publish(&self, ctx: &StackContext, out: &mut Published) -> Result<()> {
        let bound = read_json(&ctx.state().join("bound.json"))?;
        out.values.extend([
            ("STACK_SERVICE".into(), field(&bound, "service")?),
            ("STACK_HOST".into(), field(&bound, "host")?),
            ("STACK_REALM".into(), field(&bound, "realm")?),
        ]);
        Ok(())
    }
}

/// The work directory of the standalone Realm host, cleared with the rest of the run's state.
fn realm_host_dir(ctx: &StackContext) -> PathBuf {
    ctx.state().join("realm-host")
}

/// What `provision` and `bind` need to sign the owner in.
fn owner_args(ctx: &StackContext) -> Vec<String> {
    let mut args = vec![
        "--users".into(),
        ctx.root().join(FIXTURE_USERS).display().to_string(),
        "--state".into(),
        ctx.state().display().to_string(),
    ];
    args.extend(ctx.port_args(&["identity", "http", "nats"]));
    args
}

fn read_json(file: &Path) -> Result<Value> {
    serde_json::from_str(
        &fs::read_to_string(file).with_context(|| format!("cannot read {}", file.display()))?,
    )
    .with_context(|| format!("{} is not JSON", file.display()))
}

fn field(value: &Value, name: &str) -> Result<String> {
    value[name]
        .as_str()
        .map(str::to_owned)
        .with_context(|| format!("`{name}` is missing"))
}

/// `typewriter-stack <subcommand>`, built once per stack start.
fn stack_binary(ctx: &StackContext, subcommand: &str) -> Result<Command> {
    ctx.build_once("typewriter-stack", || {
        ctx.ctx
            .tool(
                ".",
                "cargo",
                &[
                    "build",
                    "--quiet",
                    "--locked",
                    "--manifest-path",
                    STACK_WORKSPACE,
                    "-p",
                    "typewriter-stack",
                ],
            )
            .run()
    })?;
    let metadata: Value = serde_json::from_str(
        &ctx.ctx
            .tool(
                ".",
                "cargo",
                &[
                    "metadata",
                    "--format-version",
                    "1",
                    "--no-deps",
                    "--locked",
                    "--manifest-path",
                    STACK_WORKSPACE,
                ],
            )
            .output_text()?,
    )?;
    let target = metadata["target_directory"]
        .as_str()
        .context("cargo metadata printed no target_directory")?;
    let mut command = Command::new(PathBuf::from(target).join("debug/typewriter-stack"));
    command.arg(subcommand).current_dir(ctx.root());
    Ok(command)
}

/// Builds every deployable component, as `cargo xtask deploy` does, and returns each package's
/// artifact.
fn deployable_components(ctx: &StackContext) -> Result<Vec<(String, PathBuf)>> {
    // The components compile against the generated Skir sources.
    generate::generate(ctx.ctx, None)?;
    let components = deploy::deployable(ctx.ctx)?;
    ctx.build_once("the backend components", || {
        deploy::build_components(ctx.ctx, &components)
    })?;
    Ok(components
        .into_iter()
        .map(|component| (component.package, component.artifact))
        .collect())
}
