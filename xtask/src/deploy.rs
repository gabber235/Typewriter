//! Publishes the backend to a cluster: every deployable component, the database image, then a
//! restart so the runtime operator pulls the new images.

use std::fs;
use std::io::Write;
use std::path::{Path, PathBuf};
use std::process::Stdio;

use anyhow::{Context as _, Result, bail, ensure};
use clap::ValueEnum;
use serde_json::Value;

use crate::cluster::CiCluster;
use crate::lock::HeavyLock;
use crate::{CommandExt, Context, Scratch, secrets};

/// Tools deploy runs, for the doctor.
pub const TOOLS: &[&str] = &["wash", "crane", "kubectl", "tar", "git"];

/// The database jobs run surrealkit from this image's binary (`deploy/base/start/job.yaml`).
const SURREALKIT_IMAGE: &str = "ghcr.io/surrealdb/surrealkit:0.6.3";
/// The base of the database jobs, which need `/bin/sh`. surrealkit is linked against glibc, and
/// its image is built on Debian 12; on a musl base such as Alpine it does not start, which the
/// shell reports as the file not being found.
const DATABASE_BASE_IMAGE: &str = "debian:12-slim";
/// surrealkit's own CA bundle, which the slim base does not have.
const SURREALKIT_CA_BUNDLE: &str = "etc/ssl/certs/ca-certificates.crt";
/// The tag the component overlays pull (`deploy/local/workloaddeployment-patch.yaml`).
const COMPONENT_TAG: &str = "latest";
/// The tag the database overlay pulls (`backend/database/deploy/local/start/kustomization.yaml`).
const DATABASE_TAG: &str = "dev";
/// The local k3d cluster's kubeconfig context.
const LOCAL_CONTEXT: &str = "k3d-seamlezz-local";
/// The kubectl arguments that restart every workload, so the runtime operator pulls the images
/// just pushed.
const RESTART_WORKLOADS: [&str; 4] = ["delete", "workloadreplicasets", "--all-namespaces", "--all"];
/// The kubectl arguments that remove the local cluster's finished schema sync.
const RESYNC_SCHEMA: [&str; 5] = [
    "delete",
    "job",
    "--namespace=typewriter",
    "--selector=typewriter.seamlezz.com/db-rollout-action=start",
    "--ignore-not-found",
];

/// A cluster this command may deploy to. Nothing else is reachable.
#[derive(Clone, Copy, ValueEnum)]
pub enum Cluster {
    /// The local k3d cluster on the main checkout's machine.
    Local,
    /// The full tier's throwaway cluster (`cargo xtask cluster ci`).
    Ci,
}

/// The platform images are pushed for: k3d nodes run the host's architecture.
fn platform() -> &'static str {
    if cfg!(target_arch = "aarch64") {
        "linux/arm64"
    } else {
        "linux/amd64"
    }
}

/// How pushes reach a cluster's registry.
struct Registry {
    host: String,
    user: String,
    password: String,
}

impl Registry {
    fn repository(&self) -> String {
        format!("{}/typewriter", self.host)
    }
}

/// A component the runtime deploys: a cdylib with a `deploy/` folder, the predicate the
/// component catalog check uses.
pub(crate) struct Component {
    pub(crate) package: String,
    pub(crate) artifact: PathBuf,
}

/// Pushes this commit's backend to `cluster`'s registry; the CI cluster is the one an earlier
/// `cargo xtask cluster ci` created.
pub fn deploy(ctx: &Context, cluster: Cluster) -> Result<()> {
    match cluster {
        Cluster::Local => {
            ensure_main_checkout(ctx)?;
            publish(
                ctx,
                &Registry {
                    host: "oci.local.seamlezz.net".into(),
                    user: "gabber235".into(),
                    password: secrets::local_registry_password()?,
                },
            )?;
            // A finished Job does not run again, so Flux recreates this one and it syncs the schema
            // of the image just pushed (`backend/database/deploy/local/start`).
            ctx.tool(".", "kubectl", &["--context", LOCAL_CONTEXT])
                .args(RESYNC_SCHEMA)
                .run()?;
            ctx.tool(".", "kubectl", &["--context", LOCAL_CONTEXT])
                .args(RESTART_WORKLOADS)
                .run()
        }
        Cluster::Ci => deploy_ci(ctx, &CiCluster::open(ctx)?),
    }
}

/// Pushes this commit's backend to `ci`'s registry and releases it to its Typewriter tenant.
pub fn deploy_ci(ctx: &Context, ci: &CiCluster) -> Result<()> {
    ensure_main_checkout(ctx)?;
    let registry = &ci.clients.registry;
    publish(
        ctx,
        &Registry {
            host: registry.host.clone(),
            user: registry.user.clone(),
            password: ci.registry_password(ctx)?,
        },
    )?;
    ci.kubectl(ctx, &RESTART_WORKLOADS).run()?;
    let revision = ctx.tool(".", "git", &["rev-parse", "HEAD"]).output_text()?;
    let branch = ctx
        .tool(".", "git", &["branch", "--show-current"])
        .output_text()?;
    ensure!(
        !branch.trim().is_empty(),
        "the cluster reads this commit from its branch on GitHub, and HEAD is on no branch"
    );
    ci.release(ctx, branch.trim(), revision.trim())
}

/// Builds every deployable component and pushes it and the database image to `registry`; the
/// caller restarts the cluster's workloads so they pull them.
fn publish(ctx: &Context, registry: &Registry) -> Result<()> {
    // The components compile against the generated Skir sources.
    crate::generate::generate(ctx, None)?;
    let components = deployable(ctx)?;
    {
        let _lock = HeavyLock::acquire("deploy")?;
        build_components(ctx, &components)?;
    }
    for component in &components {
        let reference = format!(
            "{}/{}:{}",
            registry.repository(),
            component.package,
            COMPONENT_TAG
        );
        // The wash fork reads registry credentials from flags only; the long form keeps the
        // password out of errors (`crate::display`), and `=` keeps a password that starts with
        // `-` from parsing as a flag.
        ctx.tool(
            ".",
            "wash",
            &[
                "oci",
                "push",
                "-u",
                &registry.user,
                &format!("--password={}", registry.password),
                &reference,
            ],
        )
        .arg(&component.artifact)
        .run()
        .with_context(|| format!("cannot push {reference}"))?;
    }
    push_database_image(ctx, registry)
}

/// Agent worktrees never deploy; only the main checkout publishes to a cluster.
fn ensure_main_checkout(ctx: &Context) -> Result<()> {
    let git_dir = |flag: &str| -> Result<PathBuf> {
        let path = ctx
            .tool(".", "git", &["rev-parse", "--path-format=absolute", flag])
            .output_text()?;
        Ok(PathBuf::from(path.trim()))
    };
    ensure!(
        git_dir("--git-dir")? == git_dir("--git-common-dir")?,
        "deploy runs from the main checkout only, not from a worktree"
    );
    Ok(())
}

/// Builds the release wasm artifact of every component in `components`. The caller holds the
/// heavy lock.
pub(crate) fn build_components(ctx: &Context, components: &[Component]) -> Result<()> {
    let mut build = ctx.tool(
        "backend",
        "cargo",
        &[
            "build",
            "--locked",
            "--release",
            "--target",
            "wasm32-wasip2",
        ],
    );
    for component in components {
        build.args(["-p", &component.package]);
    }
    build.run()
}

pub(crate) fn deployable(ctx: &Context) -> Result<Vec<Component>> {
    let metadata: Value = serde_json::from_str(
        &ctx.tool(
            "backend",
            "cargo",
            &["metadata", "--format-version", "1", "--no-deps", "--locked"],
        )
        .output_text()?,
    )?;
    let target = metadata["target_directory"]
        .as_str()
        .context("cargo metadata printed no target_directory")?;
    let release = Path::new(target).join("wasm32-wasip2/release");
    let packages = metadata["packages"]
        .as_array()
        .context("cargo metadata printed no packages")?;
    let mut components = Vec::new();
    for package in packages {
        let (Some(name), Some(manifest)) =
            (package["name"].as_str(), package["manifest_path"].as_str())
        else {
            continue;
        };
        let cdylib = package["targets"]
            .as_array()
            .into_iter()
            .flatten()
            .any(|target| {
                target["crate_types"]
                    .as_array()
                    .into_iter()
                    .flatten()
                    .any(|kind| kind == "cdylib")
            });
        let has_deploy = Path::new(manifest)
            .parent()
            .is_some_and(|dir| dir.join("deploy").is_dir());
        if cdylib && has_deploy {
            components.push(Component {
                package: name.to_owned(),
                artifact: release.join(format!("{}.wasm", name.replace('-', "_"))),
            });
        }
    }
    if components.is_empty() {
        bail!("no deployable components in backend");
    }
    Ok(components)
}

/// Debian, plus /usr/local/bin/surrealkit, its CA bundle and /workspace/backend/database, entrypoint surrealkit.
fn push_database_image(ctx: &Context, registry: &Registry) -> Result<()> {
    let image = format!("{}/database:{DATABASE_TAG}", registry.repository());
    let scratch = Scratch::new("database-image")?;
    let stage = |name: &str| -> Result<PathBuf> {
        let path = scratch.0.join(name);
        fs::create_dir_all(&path)?;
        Ok(path)
    };

    let surrealkit = stage("surrealkit")?;
    let exported = scratch.0.join("surrealkit-image.tar");
    ctx.tool(
        ".",
        "crane",
        &["export", "--platform", platform(), SURREALKIT_IMAGE],
    )
    .arg(&exported)
    .run()?;
    tar(ctx)
        .arg("-xf")
        .arg(&exported)
        .arg("-C")
        .arg(&surrealkit)
        .arg("usr/local/bin/surrealkit")
        .arg(SURREALKIT_CA_BUNDLE)
        .run()?;

    let schema = stage("schema/workspace/backend")?;
    ctx.tool("backend", "cp", &["-R", "database", "surrealkit.toml"])
        .arg(&schema)
        .run()?;

    let surrealkit_layer = scratch.0.join("surrealkit.tar");
    let schema_layer = scratch.0.join("schema.tar");
    tar(ctx)
        .arg("-cf")
        .arg(&surrealkit_layer)
        .arg("-C")
        .arg(&surrealkit)
        .arg("usr")
        .arg("etc")
        .run()?;
    tar(ctx)
        .arg("-cf")
        .arg(&schema_layer)
        .arg("-C")
        .arg(scratch.0.join("schema"))
        .arg("workspace")
        .run()?;

    let mut login = ctx
        .tool(
            ".",
            "crane",
            &[
                "auth",
                "login",
                &registry.host,
                "-u",
                &registry.user,
                "--password-stdin",
            ],
        )
        .stdin(Stdio::piped())
        .spawn()
        .context("cannot start crane")?;
    login
        .stdin
        .take()
        .expect("stdin is piped")
        .write_all(registry.password.as_bytes())?;
    ensure!(
        login.wait()?.success(),
        "crane cannot log in to {}",
        registry.host
    );

    ctx.tool(
        ".",
        "crane",
        &[
            "append",
            "--platform",
            platform(),
            "-b",
            DATABASE_BASE_IMAGE,
            "-t",
            &image,
            "-f",
        ],
    )
    .arg(&surrealkit_layer)
    .arg("-f")
    .arg(&schema_layer)
    .run()?;
    ctx.tool(
        ".",
        "crane",
        &[
            "mutate",
            &image,
            "--workdir",
            "/workspace/backend",
            "--entrypoint",
            "/usr/local/bin/surrealkit",
        ],
    )
    .run()
}

/// tar without macOS resource fork entries, which would land in the image as `._` files.
fn tar(ctx: &Context) -> std::process::Command {
    let mut tar = ctx.tool(".", "tar", &[]);
    tar.env("COPYFILE_DISABLE", "1");
    tar
}
