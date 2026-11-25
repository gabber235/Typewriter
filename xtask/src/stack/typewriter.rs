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
use super::spec::{
    BACKEND, Build, GradleBuild, How, Probe, Published, Role, Service, ServiceId, StackContext,
    StackSpec, state_dir,
};
use crate::cargo_build::{CargoBuild, Outcome, target_directory, workspace_files};
use crate::cluster::CiCluster;
use crate::{Context, deploy};

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
    with_realm(backend())
}

/// The panel stack plus what the game suite needs: an engine binder that binds each game Paper's
/// loader as the Realm's Paper engine, and observer credentials the game requirements read the
/// topology and the Realm's session keys with.
pub fn game() -> StackSpec {
    panel().with(Observer).with(BindEngines)
}

/// The `typewriter-stack` binary most services run. It links the wasm host, so its dependencies
/// take minutes to compile; it is reused while nothing below `backend` changed.
pub const STACK_BINARY: Build = Build {
    name: "typewriter-stack",
    how: How::Own(build_stack_binary),
};

/// The release wasm artifact of every deployable backend component, as `cargo xtask deploy`
/// builds them; reused while nothing below `backend` outside its tests changed.
pub const COMPONENTS: Build = Build {
    name: "the backend components",
    how: How::Own(build_components),
};

/// The standalone loader the Realm runs on, and the Realm and engine artifacts published into its
/// inbox.
pub const REALM_HOST_BUILD: Build = Build {
    name: "the standalone Realm host",
    how: How::Gradle(|ctx| GradleBuild {
        tasks: vec![
            format!("{REALM_HOST_PROJECT}:installDist"),
            "assembleDevelopmentArtifacts".to_owned(),
        ],
        properties: vec![(
            "typewriterArtifactInbox".to_owned(),
            realm_host_dir(ctx)
                .join("artifacts/inbox")
                .display()
                .to_string(),
        )],
    }),
};

/// `ci`'s backend, which `cargo xtask deploy ci` released, plus the same organization and Realm
/// host [`panel`] adds, for the full suite.
pub fn ci_cluster_panel(ci: &CiCluster) -> StackSpec {
    with_realm(StackSpec::default().with(CiClusterBackend(ci.clone())))
}

fn with_realm(backend: StackSpec) -> StackSpec {
    backend.with(Provision).with(RealmHost).with(BindRealmHost)
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
    fn builds(&self) -> &'static [&'static Build] {
        &[&STACK_BINARY]
    }
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

/// An OpenTelemetry collector that writes every span of this stack run to
/// `<state>/telemetry/traces.jsonl` (OTLP JSON, one export request per line), so the panel's,
/// the backend's and the Realm's spans of one run sit in one file, joined by the trace context
/// the panel propagates.
pub struct Collector;

impl Service for Collector {
    const ID: ServiceId = ServiceId("collector");
    fn command(&self, ctx: &StackContext) -> Result<Command> {
        let telemetry = ctx.state().join("telemetry");
        fs::create_dir_all(&telemetry)
            .with_context(|| format!("cannot create {}", telemetry.display()))?;
        let config = ctx.state().join("collector.yaml");
        fs::write(&config, collector_config(ctx, &telemetry.join(TRACES)))
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
/// for the panel (with CORS, so the web panel can export too), traces to `traces`, logs and
/// metrics dropped. The collector's own metrics are off; their default port collides across
/// worktree stacks.
fn collector_config(ctx: &StackContext, traces: &Path) -> String {
    let address = |port: &str| format!("127.0.0.1:{}", ctx.port(port));
    // A JSON string is a YAML string, quoted however the path looks.
    let traces = Value::String(traces.display().to_string());
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
      exporters: [nop]
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
    fn builds(&self) -> &'static [&'static Build] {
        &[&STACK_BINARY]
    }
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
    fn builds(&self) -> &'static [&'static Build] {
        &[&STACK_BINARY]
    }
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
    fn builds(&self) -> &'static [&'static Build] {
        &[&STACK_BINARY, &COMPONENTS]
    }
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
    fn builds(&self) -> &'static [&'static Build] {
        &[&STACK_BINARY]
    }
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
    fn builds(&self) -> &'static [&'static Build] {
        &[&STACK_BINARY]
    }
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

/// The standalone loader, the host the provisioned organization's Realm runs on.
pub struct RealmHost;

/// The Gradle project of the standalone loader and where `installDist` puts it.
const REALM_HOST_PROJECT: &str = ":loader-standalone";
const REALM_HOST_INSTALL: &str =
    "services/runtime/loader/standalone/build/install/loader-standalone/bin/loader-standalone";

impl Service for RealmHost {
    const ID: ServiceId = ServiceId("realm");
    fn builds(&self) -> &'static [&'static Build] {
        &[&REALM_HOST_BUILD]
    }
    fn needs(&self) -> &'static [ServiceId] {
        &[Provision::ID]
    }
    fn command(&self, ctx: &StackContext) -> Result<Command> {
        ctx.require(&REALM_HOST_BUILD)?;
        let work_dir = realm_host_dir(ctx.ctx);
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
        Probe::FileExists(realm_host_dir(ctx.ctx).join("state/registration-token"))
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
    fn builds(&self) -> &'static [&'static Build] {
        &[&STACK_BINARY]
    }
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
            .arg(realm_host_dir(ctx.ctx));
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
    fn builds(&self) -> &'static [&'static Build] {
        &[&STACK_BINARY]
    }
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
    fn builds(&self) -> &'static [&'static Build] {
        &[&STACK_BINARY]
    }
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

/// The work directory of the standalone Realm host, cleared with the rest of the run's state.
fn realm_host_dir(ctx: &Context) -> PathBuf {
    state_dir(ctx).join("realm-host")
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

/// `typewriter-stack <subcommand>`, from what [`STACK_BINARY`] built.
fn stack_binary(ctx: &StackContext, subcommand: &str) -> Result<Command> {
    ctx.require(&STACK_BINARY)?;
    let mut command = Command::new(stack_binary_path(ctx.ctx)?);
    command.arg(subcommand).current_dir(ctx.root());
    Ok(command)
}

/// Where Cargo puts the `typewriter-stack` binary: the component test workspace's target, whose
/// dependencies its suite shares.
fn stack_binary_path(ctx: &Context) -> Result<PathBuf> {
    Ok(target_directory(ctx, STACK_WORKSPACE)?.join("debug/typewriter-stack"))
}

fn build_stack_binary(ctx: &Context) -> Result<()> {
    let built = CargoBuild {
        name: "typewriter-stack",
        workspace: workspace_files(ctx, STACK_WORKSPACE)?,
        artifacts: vec![stack_binary_path(ctx)?],
    }
    .run(
        ctx,
        &mut ctx.tool(
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
        ),
    )?;
    say_reused(STACK_BINARY.name, &built);
    Ok(())
}

fn build_components(ctx: &Context) -> Result<()> {
    let components = deploy::deployable(ctx)?;
    let built = deploy::reusable_components_build(ctx, "components", &components)?
        .run(ctx, &mut deploy::components_build(ctx, &components))?;
    say_reused(COMPONENTS.name, &built);
    Ok(())
}

/// Says when a build was reused, so a run's log shows which builds its caches saved.
fn say_reused(name: &str, outcome: &Outcome) {
    if *outcome == Outcome::Reused {
        eprintln!("stack: reused {name}, built from the same inputs");
    }
}

/// Each deployable component's package and the artifact [`COMPONENTS`] built.
fn deployable_components(ctx: &StackContext) -> Result<Vec<(String, PathBuf)>> {
    ctx.require(&COMPONENTS)?;
    Ok(deploy::deployable(ctx.ctx)?
        .into_iter()
        .map(|component| (component.package, component.artifact))
        .collect())
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::test_support::{build_names, ci_cluster, ids};

    #[test]
    fn the_organization_is_provisioned_after_the_worktree_backend_routes() {
        let order = ids(&panel().ordered().unwrap());
        let position = |id: &str| order.iter().position(|ordered| *ordered == id).unwrap();
        assert!(position("backend-routes") < position("provision"));
    }

    #[test]
    fn the_game_stack_attaches_its_engines_and_observer_to_the_bound_realm() {
        let order = ids(&game().ordered().unwrap());
        let position = |id: &str| order.iter().position(|ordered| *ordered == id).unwrap();
        assert!(position("bind-realm-host") < position("observer"));
        assert!(position("bind-realm-host") < position("bind-engines"));
    }

    #[test]
    fn the_ci_target_builds_no_backend_components_of_its_own() {
        assert!(!build_names(&ci_cluster_panel(&ci_cluster())).contains(&COMPONENTS.name));
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
