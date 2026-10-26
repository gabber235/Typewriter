//! `cargo xtask cluster`: the throwaway k3d cluster the full tier deploys to.
//!
//! The Infrastructure repository owns the cluster: its `clusters/ci` overlay is the local overlay
//! with only what cannot exist in CI swapped (decryption, images, resources). Typewriter pins the
//! revision in [`PIN`] and expects that revision checked out read only at [`CHECKOUT`]; the full
//! tier workflow checks it out with the Infrastructure deploy key. Every command here addresses
//! [`CONTEXT`] explicitly, so it can never reach Gabber's local cluster or production.

use std::env;
use std::io::Write as _;
use std::path::PathBuf;
use std::process::{Command, Stdio};

use anyhow::{Context as _, Result, ensure};
use clap::Subcommand;
use serde::Deserialize;

use crate::{CommandExt, Context};

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

/// The age key the CI cluster's secrets are encrypted to. Flux decrypts with it; it is passed to
/// kubectl on stdin, never on a command line.
const AGE_KEY: &str = "CI_AGE_KEY";

#[derive(Subcommand)]
pub enum ClusterCommand {
    /// Creates the CI cluster from the pinned Infrastructure overlay and waits until Flux has
    /// reconciled it. Expects the pinned revision at .xtask/infrastructure and the age key in
    /// CI_AGE_KEY.
    Ci,
}

pub fn command(ctx: &Context, command: ClusterCommand) -> Result<()> {
    match command {
        ClusterCommand::Ci => create_ci(ctx),
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
    /// The checkout, after making sure it is at the pinned revision.
    fn pinned(ctx: &Context) -> Result<Self> {
        let file = ctx.root.join(PIN);
        let pin: Pin = toml::from_str(
            &std::fs::read_to_string(&file)
                .with_context(|| format!("cannot read {}", file.display()))?,
        )
        .with_context(|| format!("{} is not a valid pin", file.display()))?;
        let head = ctx
            .tool(CHECKOUT, "git", &["rev-parse", "HEAD"])
            .output_text()
            .with_context(|| {
                format!(
                    "check out {} at {} into {CHECKOUT}",
                    pin.repository, pin.revision
                )
            })?;
        ensure!(
            head.trim() == pin.revision,
            "{CHECKOUT} is at {}, but {PIN} pins {}",
            head.trim(),
            pin.revision
        );
        Ok(Self(ctx.root.join(CHECKOUT)))
    }
}

/// Creates the cluster, gives Flux the age key and bootstraps Flux from the `ci` overlay.
pub fn create_ci(ctx: &Context) -> Result<()> {
    let infrastructure = Infrastructure::pinned(ctx)?;
    let age_key = env::var(AGE_KEY)
        .with_context(|| format!("{AGE_KEY} must hold the CI cluster's age key"))?;
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
        .write_all(age_key.as_bytes())?;
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
