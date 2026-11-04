//! `cargo xtask cluster`: the throwaway k3d cluster the full tier deploys to.
//!
//! The Infrastructure repository owns the cluster and its bootstrap: its `ci:up` task creates the
//! cluster from `config/k3d/ci.yaml`, hands 1Password Connect its credentials and applies Flux from
//! the `clusters/ci` overlay. Typewriter pins the revision in [`PIN`], fetches it into
//! [`CHECKOUT`] with the Infrastructure deploy key from the `ci` secrets and runs that task there.
//! Every other fact about the cluster comes from that checkout's [`CLIENTS`], read once into the
//! [`CiCluster`] that creating or opening the cluster returns; every command it runs addresses
//! its context explicitly, so it can never reach the local development cluster or production.

use std::collections::BTreeMap;
use std::fs::{self, OpenOptions};
use std::io::Write as _;
use std::os::unix::fs::OpenOptionsExt as _;
use std::path::{Path, PathBuf};
use std::process::Command;

use anyhow::{Context as _, Result, ensure};
use clap::Subcommand;
use serde::Deserialize;

use crate::secrets::Ci;
use crate::{CommandExt, Context, Scratch};

/// Tools the cluster commands run, for the doctor.
pub const TOOLS: &[&str] = &["devenv", "kubectl", "flux", "git"];

/// The pinned Infrastructure revision, relative to the repository root.
const PIN: &str = "harness/infrastructure.toml";

/// Where the pinned Infrastructure revision is checked out, relative to the repository root.
const CHECKOUT: &str = ".xtask/infrastructure";

/// The CI cluster's client facts in the Infrastructure checkout: the one path both repositories
/// agree on.
const CLIENTS: &str = "platform/_ci/clients.json";

/// GitHub's published SSH host key, so the deploy key is only ever offered to GitHub.
const GITHUB_HOST_KEY: &str = "github.com ssh-ed25519 \
    AAAAC3NzaC1lZDI1NTE5AAAAIOMqqnkVzrm0SdG6UOoqKLsabgH5C9okWi0dh2l9GKJl";

#[derive(Subcommand)]
pub enum ClusterCommand {
    /// Creates the CI cluster with the pinned Infrastructure revision's `ci:up` task, which
    /// waits until Flux has reconciled it. Reads the `ci` secrets.
    Ci,
}

pub fn command(ctx: &Context, command: ClusterCommand) -> Result<()> {
    match command {
        ClusterCommand::Ci => create_ci(ctx, &Ci::load()?).map(drop),
    }
}

/// `harness/infrastructure.toml`.
#[derive(Deserialize)]
struct Pin {
    repository: String,
    revision: String,
}

impl Pin {
    fn read(ctx: &Context) -> Result<Self> {
        let file = ctx.root.join(PIN);
        toml::from_str(
            &fs::read_to_string(&file)
                .with_context(|| format!("cannot read {}", file.display()))?,
        )
        .with_context(|| format!("{} is not a valid pin", file.display()))
    }
}

/// The checkout of the pinned Infrastructure revision.
struct Infrastructure(PathBuf);

impl Infrastructure {
    /// The checkout, when it holds `pin`'s revision.
    fn at_pin(ctx: &Context, pin: &Pin) -> Option<Self> {
        let head = ctx
            .tool(".", "git", &["-C", CHECKOUT, "rev-parse", "HEAD"])
            .output_text()
            .ok()?;
        (head.trim() == pin.revision).then(|| Self(ctx.root.join(CHECKOUT)))
    }

    /// The checkout at the pinned revision, fetched with `deploy_key` unless it is there already.
    fn pinned(ctx: &Context, deploy_key: &str) -> Result<Self> {
        let pin = Pin::read(ctx)?;
        if let Some(checkout) = Self::at_pin(ctx, &pin) {
            return Ok(checkout);
        }
        let checkout = ctx.root.join(CHECKOUT);
        fetch(ctx, &pin, &checkout, deploy_key)
            .with_context(|| format!("cannot fetch {} at {}", pin.repository, pin.revision))?;
        Ok(Self(checkout))
    }

    /// The checkout `cluster ci` made, refused unless it is at the pinned revision.
    fn existing(ctx: &Context) -> Result<Self> {
        let pin = Pin::read(ctx)?;
        Self::at_pin(ctx, &pin).with_context(|| {
            format!(
                "{CHECKOUT} is not the pinned Infrastructure revision {}; \
                 run `cargo xtask cluster ci` first",
                pin.revision
            )
        })
    }

    /// The CI cluster this revision describes in [`CLIENTS`].
    fn cluster(&self) -> Result<CiCluster> {
        let file = self.0.join(CLIENTS);
        let text =
            fs::read_to_string(&file).with_context(|| format!("cannot read {}", file.display()))?;
        let clients = CiClients::parse(&text)
            .with_context(|| format!("{} is not the CI client facts", file.display()))?;
        Ok(CiCluster { clients })
    }
}

/// How Typewriter reaches the CI cluster, as Infrastructure states it in [`CLIENTS`] at the
/// pinned revision.
#[derive(Clone, Deserialize)]
#[serde(deny_unknown_fields)]
pub struct CiClients {
    /// The kubeconfig context k3d creates for the cluster; every kubectl and flux call names it.
    pub context: String,
    /// Toxiproxy's API as a browser may call it.
    pub faults_url: String,
    /// The host port of each faults link.
    pub links: CiLinks,
    /// The Secret holding `<username>.password` and `<username>.app-password`.
    pub test_users: ObjectRef,
    pub panel_origin: PanelOrigin,
    pub registry: CiRegistry,
    pub tenant: CiTenant,
}

/// The host ports of the faults links, each in front of the address the panel's local
/// configuration names: the desktop panel's NATS, the web panel's NATS websocket and the Realm
/// host's NATS.
#[derive(Clone, Deserialize)]
#[serde(deny_unknown_fields)]
pub struct CiLinks {
    pub nats: u16,
    pub nats_web: u16,
    pub realm_nats: u16,
}

/// A namespaced Kubernetes object.
#[derive(Clone, Deserialize)]
#[serde(deny_unknown_fields)]
pub struct ObjectRef {
    pub namespace: String,
    pub name: String,
}

/// One key of a Secret.
#[derive(Clone, Deserialize)]
#[serde(deny_unknown_fields)]
pub struct SecretKey {
    pub namespace: String,
    pub name: String,
    pub key: String,
}

/// The cluster's image registry and the user that pushes to it.
#[derive(Clone, Deserialize)]
#[serde(deny_unknown_fields)]
pub struct CiRegistry {
    pub host: String,
    pub user: String,
    pub password: SecretKey,
}

/// The Typewriter tenant's Flux source and its Kustomizations, in dependency order.
#[derive(Clone, Deserialize)]
#[serde(deny_unknown_fields)]
pub struct CiTenant {
    pub source: String,
    pub kustomizations: Vec<String>,
}

/// The only origin the CI cluster's Authentik launches the panel at and redirects it back to,
/// such as `http://localhost:4000`; the full tier serves the panel on its port.
#[derive(Clone, Deserialize)]
#[serde(try_from = "String")]
pub struct PanelOrigin {
    pub origin: String,
    pub port: u16,
}

impl TryFrom<String> for PanelOrigin {
    type Error = anyhow::Error;

    fn try_from(origin: String) -> Result<Self> {
        let port = origin
            .rsplit_once(':')
            .and_then(|(_, port)| port.parse().ok())
            .with_context(|| format!("panel origin {origin} names no port"))?;
        Ok(Self { origin, port })
    }
}

impl CiClients {
    /// clients.json's facts; a missing or unknown field, or a panel origin without a port, is an
    /// error naming it.
    pub(crate) fn parse(text: &str) -> Result<Self> {
        Ok(serde_json::from_str(text)?)
    }
}

/// The CI cluster at the pinned Infrastructure revision: its client facts, read once from the
/// checkout, and every command that reaches it. Outside tests, which build one from fixed facts,
/// only [`create_ci`] and [`CiCluster::open`] make one, both after checking the checkout is at
/// the pin.
#[derive(Clone)]
pub struct CiCluster {
    pub(crate) clients: CiClients,
}

/// Fetches only the pinned commit and checks it out detached, discarding whatever was there. The
/// deploy key and GitHub's host key live in files only this process can read, removed afterwards.
fn fetch(ctx: &Context, pin: &Pin, checkout: &Path, deploy_key: &str) -> Result<()> {
    fs::create_dir_all(checkout)
        .with_context(|| format!("cannot create {}", checkout.display()))?;
    let scratch = Scratch::new("infrastructure-ssh")?;
    let key = scratch.0.join("deploy_key");
    let known_hosts = scratch.0.join("known_hosts");
    // ssh rejects a key file without its final newline, which a vault may have trimmed.
    write_private(&key, &format!("{}\n", deploy_key.trim_end()))?;
    write_private(&known_hosts, &format!("{GITHUB_HOST_KEY}\n"))?;
    let ssh = format!(
        // No user configuration or agent: the deploy key is the only identity offered.
        "ssh -F /dev/null -o IdentityAgent=none -o IdentitiesOnly=yes -i '{}' \
         -o UserKnownHostsFile='{}' -o StrictHostKeyChecking=yes",
        key.display(),
        known_hosts.display()
    );
    let git = |args: &[&str]| {
        let mut command = ctx.tool(".", "git", &["-C", CHECKOUT]);
        command.args(args).env("GIT_SSH_COMMAND", &ssh);
        command
    };
    git(&["init", "--quiet"]).run()?;
    git(&[
        "fetch",
        "--quiet",
        "--depth",
        "1",
        &format!("git@github.com:{}.git", pin.repository),
        &pin.revision,
    ])
    .run()?;
    git(&["checkout", "--quiet", "--force", "--detach", "FETCH_HEAD"]).run()
}

/// Writes `contents` to a new file only the current user can read.
fn write_private(path: &Path, contents: &str) -> Result<()> {
    OpenOptions::new()
        .write(true)
        .create_new(true)
        .mode(0o600)
        .open(path)
        .and_then(|mut file| file.write_all(contents.as_bytes()))
        .with_context(|| format!("cannot write {}", path.display()))
}

/// Creates the cluster through the pinned revision's `ci:up` task and returns it. The `ci`
/// secrets reach the task in its environment, never on a command line.
pub fn create_ci(ctx: &Context, secrets: &Ci) -> Result<CiCluster> {
    let infrastructure = Infrastructure::pinned(ctx, &secrets.infrastructure_deploy_key)?;
    let cluster = infrastructure.cluster()?;
    // The tasks run in Infrastructure's own environment, not in the one this process runs in.
    let task = |name: &str| {
        let mut task = ctx.tool(CHECKOUT, "devenv", &["tasks", "run", name]);
        for (key, _) in std::env::vars_os() {
            if key.to_string_lossy().starts_with("DEVENV_") {
                task.env_remove(key);
            }
        }
        task
    };
    let up = task("ci:up")
        .env("CI_CONNECT_CREDENTIALS", &secrets.connect_credentials)
        .env("CI_CONNECT_TOKEN", &secrets.connect_token)
        .env(
            "INFRASTRUCTURE_DEPLOY_KEY",
            &secrets.infrastructure_deploy_key,
        )
        .run();
    if let Err(error) = up {
        // Lists only what is broken; the error returned stays ci:up's.
        if let Err(status) = task("ci:status").run() {
            eprintln!("ci:status failed too: {status:#}");
        }
        cluster.print_failure(ctx);
        return Err(error)
            .with_context(|| format!("ci:up failed in {}", infrastructure.0.display()));
    }
    Ok(cluster)
}

/// What explains a cluster that did not come up, beyond what `ci:status` lists: its bootstrap order
/// runs through OpenBao's self init and the Terraform that configures it, which report nowhere else.
/// CI logs are public, so this reads state and errors only: no Secret contents, Terraform state or
/// full controller logs. The cluster and everything in it are thrown away with the runner.
const FAILURE_REPORT: &[&[&str]] = &[
    &[
        "-n",
        "flux-system",
        "get",
        "kustomization",
        "infrastructure-configs",
        "-o",
        "jsonpath={range .status.conditions[*]}{.type}={.status} {.reason}: {.message}{\"\\n\"}{end}",
    ],
    &[
        "-n",
        "openbao",
        "get",
        "terraform",
        "openbao-config",
        "-o",
        "jsonpath={range .status.conditions[*]}{.type}={.status} {.reason}: {.message}{\"\\n\"}{end}reconciliationFailures={.status.reconciliationFailures}{\"\\n\"}",
    ],
    &[
        "-n",
        "openbao",
        "get",
        "openbaocluster",
        "openbao-cluster",
        "-o",
        "jsonpath={.status}",
    ],
    &[
        "-n",
        "openbao",
        "get",
        "pods,certificates,networkpolicies",
        "-o",
        "wide",
    ],
    &[
        "-n",
        "openbao",
        "logs",
        "statefulset/openbao-cluster",
        "--all-containers",
        "--prefix",
        "--tail=150",
    ],
    &[
        "-n",
        "openbao",
        "logs",
        "statefulset/openbao-cluster",
        "--all-containers",
        "--prefix",
        "--previous",
        "--tail=100",
    ],
    &[
        "get",
        "clustersecretstore",
        "openbao-backend",
        "-o",
        "jsonpath={range .status.conditions[*]}{.type}={.status} {.reason}: {.message}{\"\\n\"}{end}",
    ],
    &["get", "gitrepositories,kustomizations", "-A"],
    &[
        "get",
        "workloaddeployments,workloads",
        "-A",
        "-o",
        "jsonpath={range .items[*]}{.kind} {.metadata.name}:{range .status.conditions[*]} {.type}={.status}({.message}){end}{\"\\n\"}{end}",
    ],
    &[
        "-n",
        "wasmcloud",
        "logs",
        "deployment/runtime-operator",
        "--tail=80",
    ],
    &[
        "-n",
        "surrealdb",
        "logs",
        "deployment/surrealdb",
        "--tail=40",
    ],
    &[
        "-n",
        "typewriter",
        "logs",
        "-l",
        "typewriter.seamlezz.com/db-rollout-action=start",
        "--tail=40",
    ],
    &[
        "-n",
        "wasmcloud",
        "logs",
        "-l",
        "wasmcloud.com/hostgroup=default",
        "--all-containers",
        "--prefix",
        "--tail=80",
    ],
    &["get", "pods", "-A", "-o", "wide"],
    &["describe", "nodes"],
    &[
        "get",
        "events",
        "-A",
        "--field-selector",
        "type=Warning",
        "--sort-by=.lastTimestamp",
    ],
];

/// Refuses a source that holds anything but `revision`, such as a branch that moved on.
fn ensure_fetched(fetched: &str, branch: &str, revision: &str) -> Result<()> {
    ensure!(
        fetched.ends_with(revision),
        "Flux fetched {fetched} from {branch}, not {revision}; the branch must still be at the \
         commit under test, and a newer commit gets its own run",
    );
    Ok(())
}

/// A container that is not ready after having restarted, so its previous run says why it died.
#[derive(Debug, PartialEq, Eq)]
struct CrashedContainer {
    namespace: String,
    pod: String,
    container: String,
}

/// The part of `kubectl get pods -A -o json` that says which containers crashed.
#[derive(Deserialize)]
struct PodList {
    items: Vec<Pod>,
}

#[derive(Deserialize)]
struct Pod {
    metadata: PodMetadata,
    status: PodStatus,
}

#[derive(Deserialize)]
struct PodMetadata {
    namespace: String,
    name: String,
}

#[derive(Deserialize)]
#[serde(rename_all = "camelCase")]
struct PodStatus {
    /// Absent on a pod that was never scheduled.
    #[serde(default)]
    container_statuses: Vec<ContainerStatus>,
}

#[derive(Deserialize)]
#[serde(rename_all = "camelCase")]
struct ContainerStatus {
    name: String,
    ready: bool,
    restart_count: u32,
}

/// Reads the crashed containers from the output of `kubectl get pods -A -o json`.
fn crashed_containers(pods: &str) -> Result<Vec<CrashedContainer>> {
    let pods: PodList = serde_json::from_str(pods).context("cannot read the cluster's pods")?;
    let mut crashed = Vec::new();
    for pod in pods.items {
        for status in pod.status.container_statuses {
            if !status.ready && status.restart_count > 0 {
                crashed.push(CrashedContainer {
                    namespace: pod.metadata.namespace.clone(),
                    pod: pod.metadata.name.clone(),
                    container: status.name,
                });
            }
        }
    }
    Ok(crashed)
}

impl CiCluster {
    /// Prints [`FAILURE_REPORT`]. A step that fails says so and the rest still run, since a broken
    /// cluster is what this reads.
    pub(crate) fn print_failure(&self, ctx: &Context) {
        for args in FAILURE_REPORT {
            eprintln!("--- kubectl {}", args.join(" "));
            if let Err(error) = self.kubectl(ctx, args).run() {
                eprintln!("{error:#}");
            }
        }
        if let Err(error) = self.print_crashes(ctx) {
            eprintln!("{error:#}");
        }
    }

    /// Prints why each crashed container died, from the logs of its previous run.
    fn print_crashes(&self, ctx: &Context) -> Result<()> {
        let pods = self
            .kubectl(ctx, &["get", "pods", "-A", "-o", "json"])
            .output_text()?;
        for crash in crashed_containers(&pods)? {
            let args = [
                "-n",
                &crash.namespace,
                "logs",
                &crash.pod,
                "-c",
                &crash.container,
                "--previous",
                "--tail=60",
            ];
            eprintln!("--- kubectl {}", args.join(" "));
            if let Err(error) = self.kubectl(ctx, &args).run() {
                eprintln!("{error:#}");
            }
        }
        Ok(())
    }

    /// The cluster an earlier `cargo xtask cluster ci` created from this checkout.
    pub fn open(ctx: &Context) -> Result<Self> {
        Infrastructure::existing(ctx)?.cluster()
    }

    /// The port the full tier serves the panel on.
    pub fn panel_port(&self) -> u16 {
        self.clients.panel_origin.port
    }

    /// The password of the user clients.json pushes to the cluster's registry with.
    pub fn registry_password(&self, ctx: &Context) -> Result<String> {
        let secret = &self.clients.registry.password;
        self.kubectl(
            ctx,
            &[
                "--namespace",
                &secret.namespace,
                "get",
                "secret",
                &secret.name,
                "--output",
                &format!(
                    r#"go-template={{{{index .data "{}" | base64decode}}}}"#,
                    secret.key
                ),
            ],
        )
        .output_text()
        .context("cannot read the CI registry's password")
    }

    /// Waits until the cluster has generated its test users' passwords into the Secret
    /// clients.json names: `<username>.password` for Authentik's sign in form and
    /// `<username>.app-password` for the password grant.
    pub fn test_users_generated(&self, ctx: &Context) -> Command {
        let users = &self.clients.test_users;
        self.kubectl(
            ctx,
            &[
                "--namespace",
                &users.namespace,
                "wait",
                "--for=create",
                &format!("secret/{}", users.name),
                "--timeout=10m",
            ],
        )
    }

    /// The cluster's test user passwords, by Secret key.
    pub fn test_user_passwords(&self, ctx: &Context) -> Result<BTreeMap<String, String>> {
        let users = &self.clients.test_users;
        let listed = self
            .kubectl(
                ctx,
                &[
                    "--namespace",
                    &users.namespace,
                    "get",
                    &format!("secret/{}", users.name),
                    "--output",
                    // One `key=value` line per password; the Secret's blueprint file is no password.
                    r#"go-template={{range $key, $value := .data}}{{if ne $key "blueprint.yaml"}}{{$key}}={{$value | base64decode}}{{"\n"}}{{end}}{{end}}"#,
                ],
            )
            .output_text()
            .context("cannot read the CI cluster's test users")?;
        Ok(listed
            .lines()
            .filter_map(|line| line.split_once('='))
            .map(|(key, value)| (key.to_owned(), value.to_owned()))
            .collect())
    }

    /// Points the cluster's Typewriter tenant at `branch` and reconciles it, now that its images
    /// are in the registry; returns once every tenant Kustomization is Ready at `revision`, the
    /// commit `branch` must hold, and every component runs on a host. Prints the cluster's state
    /// when it cannot.
    pub fn release(&self, ctx: &Context, branch: &str, revision: &str) -> Result<()> {
        let released = self.reconcile_tenant(ctx, branch, revision);
        if released.is_err() {
            self.print_failure(ctx);
        }
        released
    }

    fn reconcile_tenant(&self, ctx: &Context, branch: &str, revision: &str) -> Result<()> {
        let tenant = &self.clients.tenant;
        // A branch is a shallow fetch of one commit; a commit ref clones the repository's whole
        // history. A later push to the branch cancels the run this commit is tested in, and the
        // check below refuses any other commit.
        let patch = serde_json::json!([
            { "op": "add", "path": "/spec/ref", "value": { "branch": branch } }
        ])
        .to_string();
        self.kubectl(
            ctx,
            &[
                "--namespace",
                "flux-system",
                "patch",
                "gitrepository",
                &tenant.source,
                "--type=json",
                "--patch",
                &patch,
            ],
        )
        .run()?;
        // The source must hold the commit before the Kustomizations resume, or they would turn
        // Ready at the revision the tenant started from.
        self.flux(ctx, &["reconcile", "source", "git", &tenant.source])
            .args(["--timeout", "15m"])
            .run()
            .context("Flux cannot fetch the commit under test")?;
        let fetched = self
            .kubectl(
                ctx,
                &[
                    "--namespace",
                    "flux-system",
                    "get",
                    "gitrepository",
                    &tenant.source,
                    "--output",
                    "jsonpath={.status.artifact.revision}",
                ],
            )
            .output_text()?;
        ensure_fetched(fetched.trim(), branch, revision)?;
        // Without --wait, resuming several Kustomizations returns before any of them is Ready.
        self.flux(ctx, &["resume", "kustomization"])
            .args(&tenant.kustomizations)
            .args(["--wait", "--timeout", "20m"])
            .run()?;
        for kustomization in &tenant.kustomizations {
            let applied = self
                .kubectl(
                    ctx,
                    &[
                        "--namespace",
                        "flux-system",
                        "get",
                        "kustomization",
                        kustomization,
                        "--output",
                        "jsonpath={.status.lastAppliedRevision}",
                    ],
                )
                .output_text()?;
            ensure!(
                applied.trim().ends_with(revision),
                "{kustomization} applied {}, not {revision}",
                applied.trim()
            );
        }
        // An applied WorkloadDeployment is only a request: Ready says its component runs on a host
        // and answers its subjects.
        self.kubectl(
            ctx,
            &[
                "wait",
                "workloaddeployments",
                "--all",
                "--all-namespaces",
                "--for=condition=Ready",
                "--timeout=10m",
            ],
        )
        .run()
        .context("the backend's components did not start on a host")
    }

    /// flux against this cluster's `flux-system` namespace only.
    fn flux(&self, ctx: &Context, args: &[&str]) -> Command {
        let mut command = ctx.tool(
            ".",
            "flux",
            &[
                "--context",
                &self.clients.context,
                "--namespace",
                "flux-system",
            ],
        );
        command.args(args);
        command
    }

    /// kubectl against this cluster only.
    pub(crate) fn kubectl(&self, ctx: &Context, args: &[&str]) -> Command {
        let mut command = ctx.tool(".", "kubectl", &["--context", &self.clients.context]);
        command.args(args);
        command
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::test_support::{ci_clients, refusal};

    #[test]
    fn a_branch_that_moved_past_the_commit_under_test_is_refused() {
        assert!(ensure_fetched("main@sha1:abc", "main", "abc").is_ok());

        let error = refusal(ensure_fetched("main@sha1:def", "main", "abc"));
        assert!(error.contains("main@sha1:def"), "{error}");
        assert!(error.contains("not abc"), "{error}");
    }

    #[test]
    fn only_containers_that_restarted_and_are_not_ready_count_as_crashed() {
        let pods = serde_json::json!({ "items": [{
            "metadata": { "namespace": "surrealdb", "name": "tikv-0" },
            "status": { "containerStatuses": [
                { "name": "crashing", "ready": false, "restartCount": 12 },
                { "name": "recovered", "ready": true, "restartCount": 1 },
                { "name": "starting", "ready": false, "restartCount": 0 },
            ]},
        }, {
            "metadata": { "namespace": "surrealdb", "name": "surrealdb-1" },
            "status": { "phase": "Pending" },
        }]});

        assert_eq!(
            crashed_containers(&pods.to_string()).unwrap(),
            [CrashedContainer {
                namespace: "surrealdb".into(),
                pod: "tikv-0".into(),
                container: "crashing".into(),
            }]
        );
    }

    #[test]
    fn a_clients_file_without_a_fact_is_refused_naming_it() {
        let mut facts = ci_clients();
        facts.as_object_mut().unwrap().remove("faults_url");
        let error = refusal(CiClients::parse(&facts.to_string()));
        assert!(error.contains("missing field `faults_url`"), "{error}");
    }

    #[test]
    fn a_clients_file_with_an_unknown_fact_is_refused_naming_it() {
        let mut facts = ci_clients();
        facts["panel_port"] = 4000.into();
        let error = refusal(CiClients::parse(&facts.to_string()));
        assert!(error.contains("unknown field `panel_port`"), "{error}");
    }

    #[test]
    fn a_panel_origin_without_a_port_is_refused_naming_it() {
        let mut facts = ci_clients();
        facts["panel_origin"] = "http://localhost".into();
        let error = refusal(CiClients::parse(&facts.to_string()));
        assert!(
            error.contains("panel origin http://localhost names no port"),
            "{error}"
        );
    }
}
