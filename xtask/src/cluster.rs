//! `cargo xtask cluster`: the throwaway k3d cluster the full tier deploys to.
//!
//! The Infrastructure repository owns the cluster and its bootstrap: its `ci:up` task creates the
//! cluster from `config/k3d/ci.yaml`, hands 1Password Connect its credentials and applies Flux from
//! the `clusters/ci` overlay. Typewriter pins the revision in [`PIN`], fetches it into
//! [`CHECKOUT`] with the Infrastructure deploy key from the `ci` secrets and runs that task there.
//! Every command here addresses [`CONTEXT`] explicitly, so it can never reach the local
//! development cluster or production.

use std::fs::{self, OpenOptions};
use std::io::Write as _;
use std::os::unix::fs::OpenOptionsExt as _;
use std::path::{Path, PathBuf};
use std::process::Command;

use anyhow::{Context as _, Result};
use clap::Subcommand;
use serde::Deserialize;

use crate::secrets::Ci;
use crate::{CommandExt, Context, Scratch};

/// Tools the cluster commands run, for the doctor.
pub const TOOLS: &[&str] = &["devenv", "kubectl", "flux", "git"];

/// The kubeconfig context k3d creates for the cluster `config/k3d/ci.yaml` names.
pub const CONTEXT: &str = "k3d-seamlezz-ci";

/// Where `cargo xtask deploy ci` writes the cluster's client configuration, relative to the
/// repository root.
pub const STATE: &str = ".xtask/state/cluster";

/// The pinned Infrastructure revision, relative to the repository root.
const PIN: &str = "harness/infrastructure.toml";

/// Where the pinned Infrastructure revision is checked out, relative to the repository root.
const CHECKOUT: &str = ".xtask/infrastructure";

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
        ClusterCommand::Ci => create_ci(ctx, &Ci::load()?),
    }
}

/// `harness/infrastructure.toml`.
#[derive(Deserialize)]
struct Pin {
    repository: String,
    revision: String,
}

/// The checkout of the pinned Infrastructure revision.
struct Infrastructure(PathBuf);

impl Infrastructure {
    /// The checkout at the pinned revision, fetched with `deploy_key` unless it is there already.
    fn pinned(ctx: &Context, deploy_key: &str) -> Result<Self> {
        let file = ctx.root.join(PIN);
        let pin: Pin = toml::from_str(
            &fs::read_to_string(&file)
                .with_context(|| format!("cannot read {}", file.display()))?,
        )
        .with_context(|| format!("{} is not a valid pin", file.display()))?;
        let checkout = ctx.root.join(CHECKOUT);
        let head = ctx
            .tool(".", "git", &["-C", CHECKOUT, "rev-parse", "HEAD"])
            .output_text()
            .ok();
        if head.as_deref().map(str::trim) != Some(pin.revision.as_str()) {
            fetch(ctx, &pin, &checkout, deploy_key)
                .with_context(|| format!("cannot fetch {} at {}", pin.repository, pin.revision))?;
        }
        Ok(Self(checkout))
    }
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

/// Creates the cluster through the pinned revision's `ci:up` task. The `ci` secrets reach the task
/// in its environment, never on a command line.
pub fn create_ci(ctx: &Context, secrets: &Ci) -> Result<()> {
    let infrastructure = Infrastructure::pinned(ctx, &secrets.infrastructure_deploy_key)?;
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
        return Err(error)
            .with_context(|| format!("ci:up failed in {}", infrastructure.0.display()));
    }
    Ok(())
}

/// The registry password of the `admin` user Artifact Keeper provisions in the CI cluster.
pub fn registry_password(ctx: &Context) -> Result<String> {
    kubectl(
        ctx,
        &[
            "--namespace",
            "artifact-keeper",
            "get",
            "secret",
            "artifact-keeper-admin",
            "--output",
            r#"go-template={{index .data "admin-password" | base64decode}}"#,
        ],
    )
    .output_text()
    .context("cannot read the CI registry's admin password")
}

/// Points the CI cluster's Typewriter tenant at `revision` and reconciles it, now that its images
/// are in the registry; returns once every Typewriter Kustomization is Ready.
pub fn release(ctx: &Context, revision: &str) -> Result<()> {
    let patch = serde_json::json!([
        { "op": "add", "path": "/spec/ref", "value": { "commit": revision } }
    ])
    .to_string();
    kubectl(
        ctx,
        &[
            "--namespace",
            "flux-system",
            "patch",
            "gitrepository",
            "typewriter-backend",
            "--type=json",
            "--patch",
            &patch,
        ],
    )
    .run()?;
    let mut resume = ctx.tool(
        ".",
        "flux",
        &[
            "--context",
            CONTEXT,
            "--namespace",
            "flux-system",
            "resume",
            "kustomization",
        ],
    );
    // Without --wait, resuming several Kustomizations returns before any of them is Ready.
    resume.args(TENANT).args(["--wait", "--timeout", "20m"]);
    resume.run()
}

/// The Typewriter tenant's Kustomizations, in their dependency order.
const TENANT: [&str; 3] = [
    "typewriter-db-start",
    "typewriter-backend",
    "typewriter-db-complete",
];

/// kubectl against the CI cluster only.
fn kubectl(ctx: &Context, args: &[&str]) -> Command {
    let mut command = ctx.tool(".", "kubectl", &["--context", CONTEXT]);
    command.args(args);
    command
}
