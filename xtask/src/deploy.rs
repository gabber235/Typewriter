//! Publishes the backend to a cluster: every deployable component, the database image, then a
//! restart so the runtime operator pulls the new images. The CI cluster also gets the client
//! configuration the end to end suites read.

use std::fs;
use std::io::Write;
use std::path::{Path, PathBuf};
use std::process::Stdio;

use anyhow::{Context as _, Result, bail, ensure};
use clap::ValueEnum;
use serde_json::Value;

use crate::lock::HeavyLock;
use crate::stack::client_configuration::ClientConfiguration;
use crate::{CommandExt, Context, Scratch, cluster, secrets};

/// Tools deploy runs, for the doctor.
pub const TOOLS: &[&str] = &["wash", "crane", "kubectl", "tar", "git"];

/// The database jobs run surrealkit from this image's binary (`deploy/base/start/job.yaml`).
const SURREALKIT_IMAGE: &str = "ghcr.io/surrealdb/surrealkit:0.6.3";
/// A base with `/bin/sh` and CA certificates, which the database jobs need.
const DATABASE_BASE_IMAGE: &str = "alpine:3.20";

/// A cluster this command may deploy to. Nothing else is reachable.
#[derive(Clone, Copy, ValueEnum)]
pub enum Cluster {
    /// The local k3d cluster on the main checkout's machine.
    Local,
    /// The full tier's throwaway cluster (`cargo xtask cluster ci`).
    Ci,
}

impl Cluster {
    fn context(self) -> &'static str {
        match self {
            Self::Local => "k3d-seamlezz-local",
            Self::Ci => cluster::CONTEXT,
        }
    }

    /// The CI overlay keeps the local overlay's in cluster registry.
    fn registry(self) -> &'static str {
        "oci.local.seamlezz.net"
    }

    fn repository(self) -> String {
        format!("{}/typewriter", self.registry())
    }

    /// The tag the component overlays pull (`deploy/local/workloaddeployment-patch.yaml`).
    fn component_tag(self) -> &'static str {
        "latest"
    }

    /// The tag the database overlay pulls (`backend/database/deploy/local/start/kustomization.yaml`).
    fn database_tag(self) -> &'static str {
        "dev"
    }

    /// k3d nodes run the host's architecture.
    fn platform(self) -> &'static str {
        if cfg!(target_arch = "aarch64") {
            "linux/arm64"
        } else {
            "linux/amd64"
        }
    }
}

/// How pushes reach a cluster's registry.
struct Registry {
    cluster: Cluster,
    user: &'static str,
    password: String,
}

/// A component the runtime deploys: a cdylib with a `deploy/` folder, the predicate the
/// component catalog check uses.
pub(crate) struct Component {
    pub(crate) package: String,
    pub(crate) artifact: PathBuf,
}

/// Pushes this commit's backend to `cluster`'s registry. The CI cluster then gets the commit
/// released to its Typewriter tenant.
pub fn deploy(ctx: &Context, cluster: Cluster) -> Result<()> {
    ensure_main_checkout(ctx)?;
    let registry = match cluster {
        Cluster::Local => Registry {
            cluster,
            user: "gabber235",
            password: secrets::local_registry_password()?,
        },
        Cluster::Ci => Registry {
            cluster,
            user: "admin",
            password: cluster::registry_password(ctx)?,
        },
    };
    publish(ctx, &registry)?;
    if let Cluster::Ci = cluster {
        let revision = ctx.tool(".", "git", &["rev-parse", "HEAD"]).output_text()?;
        cluster::release(ctx, revision.trim())?;
    }
    Ok(())
}

fn publish(ctx: &Context, registry: &Registry) -> Result<()> {
    let cluster = registry.cluster;
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
            cluster.repository(),
            component.package,
            cluster.component_tag()
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
                registry.user,
                &format!("--password={}", registry.password),
                &reference,
            ],
        )
        .arg(&component.artifact)
        .run()
        .with_context(|| format!("cannot push {reference}"))?;
    }
    push_database_image(ctx, registry)?;
    if let Cluster::Ci = cluster {
        let state = ctx.root.join(cluster::STATE);
        fs::create_dir_all(&state).with_context(|| format!("cannot create {}", state.display()))?;
        ClientConfiguration::ci_cluster(ctx)?.write(&state)?;
    }
    ctx.tool(
        ".",
        "kubectl",
        &[
            "--context",
            cluster.context(),
            "delete",
            "workloadreplicasets",
            "--all-namespaces",
            "--all",
        ],
    )
    .run()
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

/// alpine, plus /usr/local/bin/surrealkit and /workspace/backend/database, entrypoint surrealkit.
fn push_database_image(ctx: &Context, registry: &Registry) -> Result<()> {
    let cluster = registry.cluster;
    let image = format!(
        "{}/database:{}",
        cluster.repository(),
        cluster.database_tag()
    );
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
        &["export", "--platform", cluster.platform(), SURREALKIT_IMAGE],
    )
    .arg(&exported)
    .run()?;
    tar(ctx)
        .arg("-xf")
        .arg(&exported)
        .arg("-C")
        .arg(&surrealkit)
        .arg("usr/local/bin/surrealkit")
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
                cluster.registry(),
                "-u",
                registry.user,
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
        cluster.registry()
    );

    ctx.tool(
        ".",
        "crane",
        &[
            "append",
            "--platform",
            cluster.platform(),
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
