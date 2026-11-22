//! Typewriter's services, each one process, and the compositions suites start.
//!
//! The broker, identity stand in, fault control, backend host, provisioning and binding are
//! subcommands of the `typewriter-stack` binary in the component test workspace, so the wasm host
//! and its heavy dependencies stay out of xtask.
//!
//! The panel suites run on two targets with the same organization and Realm host on top: the
//! worktree's own backend ([`panel`]) or the one the CI cluster runs ([`ci_cluster_panel`]).

use std::collections::BTreeMap;
use std::fs;
use std::path::{Path, PathBuf};
use std::process::Command;
use std::time::Duration;

use anyhow::{Context as _, Result};
use serde_json::Value;

use super::client_configuration::{ClientConfiguration, FIXTURE_USERS};
use super::spec::{BACKEND, Probe, Published, Role, Service, ServiceId, StackContext, StackSpec};
use crate::cluster::CiCluster;
use crate::{CommandExt, deploy, generate};

/// The component test workspace the `typewriter-stack` binary lives in.
const STACK_WORKSPACE: &str = "backend/tests/component/Cargo.toml";

/// The span collector, the broker, the identity stand in, the faults links and every backend
/// component.
pub fn backend() -> StackSpec {
    StackSpec::default()
        .with(Collector)
        .with(Toxiproxy)
        .with(Faults)
        .with(Broker)
        .with(Identity)
        .with(Backend)
        .with(BackendRoutes)
}

/// The backend plus the provisioned organization and a standalone Realm host bound to it, for
/// the panel suites.
pub fn panel() -> StackSpec {
    with_realm(backend(), RealmHost::PANEL)
}

/// The panel stack plus what the game suite needs: an engine binder that binds each game Paper's
/// loader as the Realm's Paper engine, observer credentials the game requirements read the
/// topology and the Realm's session keys with, and author credentials they write and publish the
/// Realm's content with.
pub fn game() -> StackSpec {
    with_realm(backend(), RealmHost::GAME)
        .with(Observer)
        .with(Author)
        .with(BindEngines)
}

/// `ci`'s backend, which `cargo xtask deploy ci` released, plus the same organization and Realm
/// host [`panel`] adds, for the full suite.
pub fn ci_cluster_panel(ci: &CiCluster) -> StackSpec {
    with_realm(
        StackSpec::default().with(CiClusterBackend(ci.clone())),
        RealmHost::PANEL,
    )
}

fn with_realm(backend: StackSpec, host: RealmHost) -> StackSpec {
    backend.with(Provision).with(host).with(BindRealmHost)
}

/// The toxiproxy server the desktop panel's, the web panel's and the Realm host's NATS links go
/// through, so scenarios can cut each.
pub struct Toxiproxy;

impl Service for Toxiproxy {
    const ID: ServiceId = ServiceId("toxiproxy");
    fn command(&self, ctx: &StackContext) -> Result<Command> {
        let mut command = Command::new("toxiproxy-server");
        command
            .args(["-host", "127.0.0.1", "-port"])
            .arg(ctx.port("toxiproxy").to_string());
        Ok(command)
    }
    fn ready(&self, ctx: &StackContext) -> Probe {
        Probe::http(ctx.port("toxiproxy"), "/version")
    }
}

/// Toxiproxy's API as scenarios call it, from the web panel's browser too; the CI cluster has
/// the same in front of its toxiproxy.
pub struct Faults;

impl Service for Faults {
    const ID: ServiceId = ServiceId("faults");
    fn needs(&self) -> &'static [ServiceId] {
        &[Toxiproxy::ID]
    }
    fn command(&self, ctx: &StackContext) -> Result<Command> {
        front(ctx, "faults", "toxiproxy")
    }
    fn ready(&self, ctx: &StackContext) -> Probe {
        Probe::http(ctx.port("faults"), "/version")
    }
}

/// The collector's spans file in `<state>/telemetry`.
pub const TRACES: &str = "traces.jsonl";
/// The collector's metrics file in `<state>/telemetry`.
pub const METRICS: &str = "metrics.jsonl";

/// An OpenTelemetry collector that writes every span of this stack run to
/// `<state>/telemetry/traces.jsonl` (OTLP JSON, one export request per line), so the panel's,
/// the backend's and the Realm's spans of one run sit in one file, joined by the trace context
/// the panel propagates. Every metric goes to `<state>/telemetry/metrics.jsonl` the same way, so
/// a game run reads the engines' handler times from it.
pub struct Collector;

impl Service for Collector {
    const ID: ServiceId = ServiceId("collector");
    fn command(&self, ctx: &StackContext) -> Result<Command> {
        let telemetry = ctx.state().join("telemetry");
        fs::create_dir_all(&telemetry)
            .with_context(|| format!("cannot create {}", telemetry.display()))?;
        let config = ctx.state().join("collector.yaml");
        fs::write(&config, collector_config(ctx, &telemetry))
            .with_context(|| format!("cannot write {}", config.display()))?;
        let mut command = Command::new("otelcol-contrib");
        command.arg("--config").arg(config);
        Ok(command)
    }
    fn ready(&self, ctx: &StackContext) -> Probe {
        Probe::http(ctx.port("collector-health"), "/")
    }
}

/// The collector's configuration: OTLP over gRPC for the backend and the Realm, OTLP over HTTP
/// for the panel (with CORS, so the web panel can export too), traces and metrics to their files
/// in `telemetry`, logs dropped. The collector's own metrics are off; their default port collides
/// across worktree stacks.
fn collector_config(ctx: &StackContext, telemetry: &Path) -> String {
    let traces = &telemetry.join(TRACES);
    let address = |port: &str| format!("127.0.0.1:{}", ctx.port(port));
    // A JSON string is a YAML string, quoted however the path looks.
    let traces = Value::String(traces.display().to_string());
    let metrics = Value::String(telemetry.join(METRICS).display().to_string());
    format!(
        r#"receivers:
  otlp:
    protocols:
      grpc:
        endpoint: {grpc}
      http:
        endpoint: {http}
        cors:
          allowed_origins: ["http://localhost:*", "http://127.0.0.1:*"]
exporters:
  file/traces:
    path: {traces}
  file/metrics:
    path: {metrics}
  nop: {{}}
extensions:
  health_check:
    endpoint: {health}
service:
  extensions: [health_check]
  telemetry:
    metrics:
      level: none
  pipelines:
    traces:
      receivers: [otlp]
      exporters: [file/traces]
    logs:
      receivers: [otlp]
      exporters: [nop]
    metrics:
      receivers: [otlp]
      exporters: [file/metrics]
"#,
        grpc = address("collector-grpc"),
        http = address("collector-http"),
        health = address("collector-health"),
    )
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
        &[Collector::ID, Broker::ID, Identity::ID, Toxiproxy::ID]
    }
    fn command(&self, ctx: &StackContext) -> Result<Command> {
        let components = deployable_components(ctx)?;
        let mut command = stack_binary(ctx, "host")?;
        command
            .arg("--state")
            .arg(ctx.state())
            .args(["--http", &ctx.port("backend-http").to_string()])
            .args(ctx.port_args(&[
                "nats-proxy",
                "nats-web-proxy",
                "realm-nats-proxy",
                "websocket",
                "toxiproxy",
                "identity",
            ]));
        for (package, artifact) in components {
            command
                .arg("--component")
                .arg(format!("{package}={}", artifact.display()));
        }
        // The wasmCloud host exports the components' spans over gRPC to the standard variable.
        command.env(
            "OTEL_EXPORTER_OTLP_ENDPOINT",
            ctx.url("http", "collector-grpc"),
        );
        Ok(command)
    }
    fn ready(&self, ctx: &StackContext) -> Probe {
        Probe::FileExists(ctx.state().join("backend/ready"))
    }
    fn startup(&self) -> Duration {
        // The host compiles each component on start, one after another; on CI runners that took
        // from 86 seconds to past two minutes.
        Duration::from_secs(300)
    }
}

/// The backend's public HTTP routes as clients reach them, with CORS for the web panel as the
/// CI cluster's ingress answers it; with them up, the backend is what clients connect to.
pub struct BackendRoutes;

impl Service for BackendRoutes {
    const ID: ServiceId = ServiceId("backend-routes");
    fn needs(&self) -> &'static [ServiceId] {
        &[Backend::ID]
    }
    fn provides(&self) -> &'static [Role] {
        &[BACKEND]
    }
    fn command(&self, ctx: &StackContext) -> Result<Command> {
        front(ctx, "http", "backend-http")
    }
    fn ready(&self, ctx: &StackContext) -> Probe {
        Probe::http(ctx.port("http"), "/auth/sentinel")
    }
    fn publish(&self, ctx: &StackContext, out: &mut Published) -> Result<()> {
        out.clients(ClientConfiguration::worktree(ctx));
        Ok(())
    }
}

/// `typewriter-stack front` from the port `listen` to the port `upstream`.
fn front(ctx: &StackContext, listen: &str, upstream: &str) -> Result<Command> {
    let mut command = stack_binary(ctx, "front")?;
    command.args([
        "--listen",
        &ctx.port(listen).to_string(),
        "--upstream",
        &ctx.port(upstream).to_string(),
    ]);
    Ok(command)
}

/// The backend the CI cluster runs, as the worktree's services reach it: its addresses and the
/// test users its overlay generated, whose passwords `publish` reads from the cluster. Ready once
/// the overlay has generated them.
pub struct CiClusterBackend(CiCluster);

/// Where the CI cluster's test users are written, in the fixture's format.
const CI_USERS: &str = "users.json";

impl Service for CiClusterBackend {
    const ID: ServiceId = ServiceId("ci-cluster");
    /// The organization and the Realm host start after it, as after the worktree's routes.
    fn provides(&self) -> &'static [Role] {
        &[BACKEND]
    }
    fn command(&self, ctx: &StackContext) -> Result<Command> {
        Ok(self.0.test_users_generated(ctx.ctx))
    }
    fn ready(&self, _: &StackContext) -> Probe {
        Probe::ExitSuccess
    }
    fn startup(&self) -> Duration {
        Duration::from_secs(600)
    }
    fn publish(&self, ctx: &StackContext, out: &mut Published) -> Result<()> {
        let users_file = ctx.state().join(CI_USERS);
        write_ci_users(
            &ctx.root().join(FIXTURE_USERS),
            &self.0.test_user_passwords(ctx.ctx)?,
            &users_file,
        )?;
        out.clients(ClientConfiguration::ci_cluster(
            ctx.ctx,
            &self.0.clients,
            users_file,
        )?);
        Ok(())
    }
}

/// Writes the fixture users with the password the CI cluster's password grant accepts for each:
/// the app password its overlay generated (`<username>.app-password`). The identity provider
/// assigns the subjects, so the fixture's are left out.
fn write_ci_users(fixture: &Path, passwords: &BTreeMap<String, String>, out: &Path) -> Result<()> {
    let mut users = read_json(fixture)?;
    for user in users
        .as_array_mut()
        .with_context(|| format!("{} is not a list", fixture.display()))?
    {
        let username = field(user, "username")?;
        let password = passwords
            .get(&format!("{username}.app-password"))
            .with_context(|| {
                format!(
                    "the CI cluster has no account for the fixture user {username}: the Secret \
                     `test_users` names in Infrastructure's platform/_ci/clients.json holds no \
                     {username}.app-password; add the user to Infrastructure \
                     platform/_ci/typewriter-test-users/secret.yaml"
                )
            })?;
        let user = user
            .as_object_mut()
            .with_context(|| format!("{username} is not an object"))?;
        user.insert("password".into(), Value::String(password.clone()));
        user.remove("subject");
    }
    fs::write(out, serde_json::to_string_pretty(&users)?)
        .with_context(|| format!("cannot write {}", out.display()))
}

/// The stack's organization, created by its owner through the real organization route.
pub struct Provision;

impl Service for Provision {
    const ID: ServiceId = ServiceId("provision");
    fn needs_roles(&self) -> &'static [Role] {
        &[BACKEND]
    }
    fn command(&self, ctx: &StackContext) -> Result<Command> {
        let mut command = stack_binary(ctx, "provision")?;
        command.args(owner_args(ctx)?);
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

/// The standalone loader, the host the provisioned organization's Realm runs on. The game
/// stack's host also deploys the extensions the game test modules declare (`gamePaper {
/// typewriterExtensions.from(...) }`), so the Realm deploys them to its game Papers; no other
/// host does.
pub struct RealmHost {
    game_extensions: bool,
}

impl RealmHost {
    /// The host of the panel stacks: the development artifacts only.
    pub const PANEL: Self = Self {
        game_extensions: false,
    };
    /// The host of the game stack: the development artifacts and the game modules' extensions.
    pub const GAME: Self = Self {
        game_extensions: true,
    };

    /// The Gradle arguments that build the host and publish its artifacts into `inbox`.
    fn build_args(&self, inbox: &Path) -> Vec<String> {
        let mut args = vec![
            "--quiet".to_owned(),
            format!("{REALM_HOST_PROJECT}:installDist"),
            // The Realm and engine artifacts, published into the host's inbox.
            "assembleDevelopmentArtifacts".to_owned(),
        ];
        if self.game_extensions {
            // Before the host starts, so its first deployment already holds them and no rollout
            // runs during the suite.
            args.push("installGameExtensions".to_owned());
        }
        args.push(format!("-PtypewriterArtifactInbox={}", inbox.display()));
        args
    }
}

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
        let args = self.build_args(&work_dir.join("artifacts/inbox"));
        let args: Vec<&str> = args.iter().map(String::as_str).collect();
        ctx.build_once("the standalone Realm host", || {
            ctx.ctx.tool("services", "./gradlew", &args).run()
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
    /// Where the host keeps the artifacts of its Realm's committed deployment, so the game
    /// requirements author with the catalog the Realm loads from them.
    fn publish(&self, ctx: &StackContext, out: &mut Published) -> Result<()> {
        out.values.insert(
            "STACK_REALM_HOST_ARTIFACTS".into(),
            realm_host_dir(ctx).join("artifacts").display().to_string(),
        );
        Ok(())
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
    /// It reads the clients through [`owner_args`].
    fn needs_roles(&self) -> &'static [Role] {
        &[BACKEND]
    }
    fn command(&self, ctx: &StackContext) -> Result<Command> {
        let mut command = stack_binary(ctx, "bind")?;
        command
            .args(owner_args(ctx)?)
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

/// Binds the loader of each game Paper slot as the Paper engine of the stack's Realm, through the
/// real routes, the first time the slot's loader writes its registration token to
/// `<STACK_GAME_ENGINES>/<slot>/registration-token`. It names each slot's service
/// `game_paper_<slot>`, so the game requirements find their engine in the topology. It keeps
/// running for the slots whose Papers boot later.
pub struct BindEngines;

impl Service for BindEngines {
    const ID: ServiceId = ServiceId("bind-engines");
    fn needs(&self) -> &'static [ServiceId] {
        &[BindRealmHost::ID]
    }
    fn needs_roles(&self) -> &'static [Role] {
        &[BACKEND]
    }
    fn command(&self, ctx: &StackContext) -> Result<Command> {
        let mut command = stack_binary(ctx, "bind")?;
        command
            .args(owner_args(ctx)?)
            .arg("--work-dir")
            .arg(game_engines_dir(ctx))
            .arg("--as-engine");
        Ok(command)
    }
    /// It signed the owner in and waits for the slots' tokens.
    fn ready(&self, ctx: &StackContext) -> Probe {
        Probe::FileExists(game_engines_dir(ctx).join("watching"))
    }
    fn publish(&self, ctx: &StackContext, out: &mut Published) -> Result<()> {
        out.values.insert(
            "STACK_GAME_ENGINES".into(),
            game_engines_dir(ctx).display().to_string(),
        );
        Ok(())
    }
}

/// Where each game Paper slot writes its registration token, one folder per slot.
fn game_engines_dir(ctx: &StackContext) -> PathBuf {
    ctx.state().join("game-engines")
}

/// Read only NATS credentials in the TYPEWRITER account for the game requirements: the owner's
/// topology snapshot request, and reads of the Realm's `sessions_<realm>` key value bucket.
pub struct Observer;

impl Service for Observer {
    const ID: ServiceId = ServiceId("observer");
    fn needs(&self) -> &'static [ServiceId] {
        &[BindRealmHost::ID]
    }
    fn command(&self, ctx: &StackContext) -> Result<Command> {
        let mut command = stack_binary(ctx, "observer")?;
        command.arg("--state").arg(ctx.state());
        Ok(command)
    }
    fn ready(&self, _: &StackContext) -> Probe {
        Probe::ExitSuccess
    }
    fn publish(&self, ctx: &StackContext, out: &mut Published) -> Result<()> {
        let observer = read_json(&ctx.state().join("observer.json"))?;
        out.values.extend([
            ("STACK_OBSERVER_CREDS".into(), field(&observer, "creds")?),
            ("STACK_OBSERVER_INBOX".into(), field(&observer, "inbox")?),
            (
                "STACK_OBSERVER_TOPOLOGY".into(),
                field(&observer, "topology")?,
            ),
        ]);
        Ok(())
    }
}

/// NATS credentials in the TYPEWRITER account for the game requirements to author with: the stack
/// owner's calls of the Realm routes that edit, commit and publish content and read what was
/// published.
pub struct Author;

impl Service for Author {
    const ID: ServiceId = ServiceId("author");
    fn needs(&self) -> &'static [ServiceId] {
        &[BindRealmHost::ID]
    }
    fn command(&self, ctx: &StackContext) -> Result<Command> {
        let mut command = stack_binary(ctx, "author")?;
        command.arg("--state").arg(ctx.state());
        Ok(command)
    }
    fn ready(&self, _: &StackContext) -> Probe {
        Probe::ExitSuccess
    }
    fn publish(&self, ctx: &StackContext, out: &mut Published) -> Result<()> {
        let author = read_json(&ctx.state().join("author.json"))?;
        out.values.extend([
            ("STACK_AUTHOR_CREDS".into(), field(&author, "creds")?),
            ("STACK_AUTHOR_INBOX".into(), field(&author, "inbox")?),
        ]);
        Ok(())
    }
}

/// The work directory of the standalone Realm host, cleared with the rest of the run's state.
fn realm_host_dir(ctx: &StackContext) -> PathBuf {
    ctx.state().join("realm-host")
}

/// What `provision` and `bind` need to sign the owner in, from the clients the backend
/// published: they connect the way the desktop panel does.
fn owner_args(ctx: &StackContext) -> Result<Vec<String>> {
    let clients = ctx.clients()?;
    Ok(vec![
        "--users".into(),
        clients.control.users_file.display().to_string(),
        "--state".into(),
        ctx.state().display().to_string(),
        "--identity".into(),
        clients.auth_base_url.clone(),
        "--api".into(),
        clients.api_base_url.clone(),
        "--nats".into(),
        clients.nats_desktop_url.clone(),
    ])
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

#[cfg(test)]
mod tests {
    use super::*;
    use crate::test_support::{TempRoot, ci_cluster, ids, stack_context};

    #[test]
    fn the_collector_keeps_every_metric_of_the_run_in_the_metrics_file() {
        let root = TempRoot::new();
        let ctx = stack_context(&root);
        let telemetry = ctx.state().join("telemetry");

        let config = collector_config(&ctx, &telemetry);

        let metrics = Value::String(telemetry.join(METRICS).display().to_string());
        assert!(config.contains(&format!("  file/metrics:\n    path: {metrics}\n")));
        assert!(
            config.contains(
                "    metrics:\n      receivers: [otlp]\n      exporters: [file/metrics]\n"
            )
        );
    }

    #[test]
    fn the_organization_is_provisioned_after_the_worktree_backend_routes() {
        let order = ids(&panel().ordered().unwrap());
        let position = |id: &str| order.iter().position(|ordered| *ordered == id).unwrap();
        assert!(position("backend-routes") < position("provision"));
    }

    #[test]
    fn the_game_stack_attaches_its_engines_observer_and_author_to_the_bound_realm() {
        let order = ids(&game().ordered().unwrap());
        let position = |id: &str| order.iter().position(|ordered| *ordered == id).unwrap();
        assert!(position("bind-realm-host") < position("observer"));
        assert!(position("bind-realm-host") < position("author"));
        assert!(position("bind-realm-host") < position("bind-engines"));
    }

    #[test]
    fn only_the_game_stack_s_realm_host_installs_the_game_modules_extensions_before_it_starts() {
        let inbox = Path::new("/stack/realm-host/artifacts/inbox");
        let tasks = |host: RealmHost| host.build_args(inbox);

        assert_eq!(
            tasks(RealmHost::GAME),
            [
                "--quiet",
                ":loader-standalone:installDist",
                "assembleDevelopmentArtifacts",
                "installGameExtensions",
                "-PtypewriterArtifactInbox=/stack/realm-host/artifacts/inbox",
            ]
        );
        assert_eq!(
            tasks(RealmHost::PANEL),
            [
                "--quiet",
                ":loader-standalone:installDist",
                "assembleDevelopmentArtifacts",
                "-PtypewriterArtifactInbox=/stack/realm-host/artifacts/inbox",
            ]
        );
    }

    #[test]
    fn the_realm_host_hands_on_where_it_keeps_the_artifacts_it_deployed() {
        let root = TempRoot::new();
        let ctx = stack_context(&root);
        let mut published = Published::default();

        RealmHost::GAME.publish(&ctx, &mut published).unwrap();

        assert_eq!(
            published.values.get("STACK_REALM_HOST_ARTIFACTS"),
            Some(
                &ctx.state()
                    .join("realm-host/artifacts")
                    .display()
                    .to_string()
            )
        );
    }

    #[test]
    fn the_ci_target_provisions_after_the_ci_cluster_backend() {
        assert_eq!(
            ids(&ci_cluster_panel(&ci_cluster()).ordered().unwrap()),
            ["ci-cluster", "provision", "realm", "bind-realm-host"]
        );
    }

    #[test]
    fn ci_users_sign_in_with_their_generated_app_password_and_no_fixture_subject() {
        let dir = tempfile::tempdir().unwrap();
        let fixture = dir.path().join("fixture.json");
        let out = dir.path().join("users.json");
        fs::write(
            &fixture,
            r#"[{"username":"ada","password":"stack","subject":"user_ada","organizations":["acme"]}]"#,
        )
        .unwrap();
        let passwords = BTreeMap::from([
            ("ada.password".to_owned(), "form".to_owned()),
            ("ada.app-password".to_owned(), "grant".to_owned()),
        ]);

        write_ci_users(&fixture, &passwords, &out).unwrap();

        assert_eq!(
            read_json(&out).unwrap(),
            serde_json::json!([{"username":"ada","password":"grant","organizations":["acme"]}])
        );
    }

    #[test]
    fn a_fixture_user_the_ci_cluster_has_no_app_password_for_is_refused() {
        let dir = tempfile::tempdir().unwrap();
        let fixture = dir.path().join("fixture.json");
        fs::write(
            &fixture,
            r#"[{"username":"grace","password":"stack","subject":"user_grace","organizations":[]}]"#,
        )
        .unwrap();

        let error =
            write_ci_users(&fixture, &BTreeMap::new(), &dir.path().join("users.json")).unwrap_err();

        assert!(format!("{error:#}").contains("grace"), "{error:#}");
    }
}
