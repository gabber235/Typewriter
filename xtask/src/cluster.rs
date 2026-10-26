//! `cargo xtask cluster`: the throwaway k3d cluster the full tier deploys to.
//!
//! The Infrastructure repository owns the cluster: its `clusters/ci` overlay is the local overlay
//! with only what cannot exist in CI swapped (decryption, images, resources). Typewriter pins the
//! revision in [`PIN`] and fetches it into [`CHECKOUT`] with the Infrastructure deploy key from the
//! `ci` secrets. Every command here addresses [`CONTEXT`] explicitly, so it can never reach
//! the local development cluster or production.

use std::fs::{self, OpenOptions};
use std::io::Write as _;
use std::os::unix::fs::OpenOptionsExt as _;
use std::path::{Path, PathBuf};
use std::process::{Command, Stdio};

use anyhow::{Context as _, Result, ensure};
use clap::Subcommand;
use serde::Deserialize;

use crate::secrets::Ci;
use crate::{CommandExt, Context, Scratch};

/// Tools the cluster commands run, for the doctor.
pub const TOOLS: &[&str] = &["k3d", "kubectl", "flux", "git"];

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
    /// Creates the CI cluster from the pinned Infrastructure overlay and waits until Flux has
    /// reconciled it. Reads the `ci` secrets.
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

/// Creates the cluster, gives Flux the age key and bootstraps Flux from the `ci` overlay. The age
/// key reaches kubectl on stdin, never on a command line.
pub fn create_ci(ctx: &Context, secrets: &Ci) -> Result<()> {
    let infrastructure = Infrastructure::pinned(ctx, &secrets.infrastructure_deploy_key)?;
    ctx.tool(".", "k3d", &["cluster", "create", "--config"])
        .arg(infrastructure.0.join("config/k3d/ci.yaml"))
        .arg("--wait")
        .run()?;
    kubectl(ctx, &["create", "namespace", "flux-system"]).run()?;
    let mut secret = kubectl(
        ctx,
        &[
            "create",
            "secret",
            "generic",
            "sops-age",
            "--namespace",
            "flux-system",
            "--from-file=age.agekey=/dev/stdin",
        ],
    )
    .stdin(Stdio::piped())
    .spawn()
    .context("cannot start kubectl")?;
    secret
        .stdin
        .take()
        .expect("stdin is piped")
        .write_all(secrets.age_key.as_bytes())?;
    ensure!(
        secret.wait()?.success(),
        "kubectl cannot create the sops-age secret"
    );
    let flux_system = infrastructure.0.join("clusters/ci/flux-system");
    let mut apply = kubectl(ctx, &["apply", "--kustomize"]);
    apply.arg(&flux_system);
    // The first apply creates Flux's CRDs but rejects the GitRepository and Kustomization that
    // use them, since kubectl resolves every kind before applying; once the CRDs are established
    // the second apply creates those.
    if apply.run().is_err() {
        kubectl(
            ctx,
            &[
                "wait",
                "--for=condition=established",
                "--timeout=2m",
                "crd",
                "--all",
            ],
        )
        .run()?;
        apply.run()?;
    }
    ctx.tool(
        ".",
        "flux",
        &[
            "--context",
            CONTEXT,
            "reconcile",
            "kustomization",
            "flux-system",
            "--with-source",
            "--timeout",
            "20m",
        ],
    )
    .run()
}

/// kubectl against the CI cluster only.
fn kubectl(ctx: &Context, args: &[&str]) -> Command {
    let mut command = ctx.tool(".", "kubectl", &["--context", CONTEXT]);
    command.args(args);
    command
}
