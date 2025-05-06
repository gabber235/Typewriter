use anyhow::{Context, Result, anyhow};
use clap::Parser;
use heck::ToSnakeCase;
use itertools::Itertools;
use notify::{EventKind, RecursiveMode, event::ModifyKind, event::RenameMode};
use notify_debouncer_full::{Debouncer, new_debouncer};
use std::{
    fmt as std_fmt, fs,
    path::{Path, PathBuf},
    process::Stdio,
    sync::mpsc as std_mpsc,
    time::Duration,
};
use tokio::process::Command;
use tracing::{debug, error, info, warn};
use tracing_subscriber::{filter::EnvFilter, fmt, layer::SubscriberExt, util::SubscriberInitExt};
use walkdir::WalkDir;

const WASH_CMD: &str = "wash";
const WASH_CREDS_FILE: &str = "/app/wasmcloud.creds";
const WASMCLOUD_JS_DOMAIN: &str = "core";
const PROJECT_MARKER: &str = "wasmcloud.toml";
const PROJECT_CARGO: &str = "Cargo.toml";
const BUILD_DIR: &str = "build";
const COMPONENT_SUFFIX: &str = "_s.wasm";
const PROVIDER_SUFFIX: &str = ".par.gz";
const DEVELOP_WADM_YAML: &str = "develop.wadm.yaml";

const WATCHED_EXTENSIONS: &[&str] = &["rs", "toml", "yaml", "yml", "json"];
const IGNORED_PATTERNS: &[&str] = &[
    "target",
    "build",
    ".git",
    ".idea",
    ".vscode",
    "node_modules",
];

#[derive(Parser, Debug, Clone)]
#[clap(author, version, about, long_about = None)]
struct Config {
    #[clap(long, env = "WDEV_PROJECTS_BASE_DIR", default_value = "/app/projects")]
    projects_base_dir: PathBuf,

    #[clap(long, env = "WASH_NATS_HOST", default_value = "nats")]
    nats_host: String,

    #[clap(long, env = "WASH_NATS_PORT", default_value = "4222")]
    nats_port: u16,

    #[clap(long, env = "WASH_REGISTRY", default_value = "registry:5001")]
    registry_url: String,

    #[clap(long, env = "WASH_REGISTRY_INSECURE", action, default_value = "true")]
    registry_insecure: bool,

    #[clap(long, env = "WASMCLOUD_CTL_HOST", default_value = "nats")]
    ctl_host: String,

    #[clap(long, env = "WASMCLOUD_CTL_PORT", default_value = "4222")]
    ctl_port: u16,

    #[clap(long, env = "WDEV_DEBOUNCE_MS", default_value = "1000")]
    debounce_ms: u64,
}

#[derive(Debug, PartialEq, Eq, PartialOrd, Ord)]
enum Project {
    Component {
        name: String,
        version: String,
        directory: PathBuf,
    },
    Provider {
        name: String,
        version: String,
        directory: PathBuf,
    },
}

impl std_fmt::Display for Project {
    fn fmt(&self, f: &mut std_fmt::Formatter<'_>) -> std_fmt::Result {
        match self {
            Project::Component {
                name,
                version,
                directory,
            } => {
                write!(
                    f,
                    "Component {} (version: {}) in {}",
                    name,
                    version,
                    directory.display()
                )
            }
            Project::Provider {
                name,
                version,
                directory,
            } => {
                write!(
                    f,
                    "Provider {} (version: {}) in {}",
                    name,
                    version,
                    directory.display()
                )
            }
        }
    }
}

impl Project {
    fn name(&self) -> &str {
        match self {
            Project::Component { name, .. } => name,
            Project::Provider { name, .. } => name,
        }
    }

    fn version(&self) -> &str {
        match self {
            Project::Component { version, .. } => version,
            Project::Provider { version, .. } => version,
        }
    }

    fn directory(&self) -> &PathBuf {
        match self {
            Project::Component { directory, .. } => directory,
            Project::Provider { directory, .. } => directory,
        }
    }

    fn get_image_reference(&self, registry_url: &str, file_name: &str) -> Option<String> {
        let snake_name = self.name().to_snake_case();
        match self {
            Project::Component { .. } if file_name.ends_with(COMPONENT_SUFFIX) => Some(format!(
                "{}/{}:{}",
                registry_url,
                snake_name,
                self.version()
            )),
            Project::Provider { .. } if file_name.ends_with(PROVIDER_SUFFIX) => Some(format!(
                "{}/{}:{}",
                registry_url,
                snake_name,
                self.version()
            )),
            _ => None,
        }
    }
}

fn is_relevant_change(event: &notify::Event) -> bool {
    if !matches!(
        event.kind,
        EventKind::Create(_)
            | EventKind::Modify(
                ModifyKind::Data(_)
                    | ModifyKind::Name(RenameMode::Both)
                    | ModifyKind::Name(RenameMode::To)
            )
            | EventKind::Remove(_)
    ) {
        return false;
    }

    event.paths.iter().all(|p| {
        if p.components().any(|comp| {
            let comp_str = comp.as_os_str().to_string_lossy();
            IGNORED_PATTERNS.contains(&comp_str.as_ref())
        }) {
            return false;
        }

        if let Some(ext) = p.extension() {
            let ext_str = ext.to_string_lossy();
            WATCHED_EXTENSIONS.contains(&ext_str.as_ref())
        } else {
            false
        }
    })
}

fn find_projects(base_dir: &Path) -> Result<Vec<Project>> {
    let mut projects = Vec::new();
    for entry in WalkDir::new(base_dir).min_depth(1).max_depth(4) {
        let entry = entry.context("Failed to read directory entry")?;
        if entry.file_type().is_dir() {
            let marker_path = entry.path().join(PROJECT_MARKER);
            let cargo_path = entry.path().join(PROJECT_CARGO);

            if !marker_path.is_file() || !cargo_path.is_file() {
                continue;
            }

            let marker_content =
                fs::read_to_string(&marker_path).context("Failed to read project marker file")?;
            let marker: toml::Value =
                toml::from_str(&marker_content).context("Failed to parse wasmcloud.toml")?;

            let project_type = marker
                .get("type")
                .and_then(|t| t.as_str())
                .ok_or_else(|| anyhow!("Missing or invalid type in wasmcloud.toml"))?;
            let project_name = marker
                .get("name")
                .and_then(|n| n.as_str())
                .ok_or_else(|| anyhow!("Missing or invalid name in wasmcloud.toml"))?;

            let cargo_content =
                fs::read_to_string(&cargo_path).context("Failed to read Cargo.toml")?;
            let cargo_toml: toml::Value =
                toml::from_str(&cargo_content).context("Failed to parse Cargo.toml")?;
            let version = cargo_toml
                .get("package")
                .and_then(|p| p.get("version"))
                .and_then(|v| v.as_str())
                .unwrap_or("unknown")
                .to_string();

            let project = match project_type.to_lowercase().as_str() {
                "component" => Project::Component {
                    name: project_name.to_string(),
                    version: version.clone(),
                    directory: entry.path().to_path_buf(),
                },
                "provider" => Project::Provider {
                    name: project_name.to_string(),
                    version: version.clone(),
                    directory: entry.path().to_path_buf(),
                },
                _ => {
                    warn!(
                        "Unknown project type '{}' in {}",
                        project_type,
                        marker_path.display()
                    );
                    continue;
                }
            };

            info!("Found {}", project);
            projects.push(project);
        }
    }
    projects.sort();
    projects.dedup();
    Ok(projects)
}

async fn run_wash_command(cmd_args: &[&str], cwd: Option<&Path>, config: &Config) -> Result<()> {
    let args_string = cmd_args.join(" ");
    let cwd_display = cwd.map_or_else(|| ".".to_string(), |p| p.display().to_string());
    info!("Running command: wash {} (in {})", args_string, cwd_display);

    let mut command = Command::new(WASH_CMD);
    command
        .args(cmd_args)
        .stdout(Stdio::piped())
        .stderr(Stdio::piped());

    if let Some(dir) = cwd {
        command.current_dir(dir);
    }

    command
        .env("WASH_NATS_HOST", &config.nats_host)
        .env("WASH_NATS_PORT", config.nats_port.to_string())
        .env("WASMCLOUD_CTL_HOST", &config.ctl_host)
        .env("WASMCLOUD_CTL_PORT", config.ctl_port.to_string())
        .env("WASH_CTL_CREDS", WASH_CREDS_FILE)
        .env("WASMCLOUD_JS_DOMAIN", WASMCLOUD_JS_DOMAIN);

    // Debug that the creds file exists
    let creds_path = Path::new(WASH_CREDS_FILE);
    if !creds_path.exists() {
        error!("WASH_CTL_CREDS file not found at {}", creds_path.display());
        return Err(anyhow!("WASH_CTL_CREDS file not found"));
    }

    let child = command
        .spawn()
        .context(format!("Failed to spawn wash command: {}", args_string))?;

    let output = child
        .wait_with_output()
        .await
        .context(format!("Failed to execute wash command: {}", args_string))?;

    let stdout = String::from_utf8_lossy(&output.stdout);
    let stderr = String::from_utf8_lossy(&output.stderr);

    if output.status.success() {
        info!("wash {} completed successfully.", args_string);
        if !stdout.is_empty() {
            debug!("stdout:\n{}", stdout);
        }
        if !stderr.is_empty() {
            debug!("stderr:\n{}", stderr);
        }
        Ok(())
    } else {
        error!("wash {} failed with status: {}", args_string, output.status);
        if !stdout.is_empty() {
            error!("stdout:\n{}", stdout);
        }
        if !stderr.is_empty() {
            error!("stderr:\n{}", stderr);
        }
        Err(anyhow!("wash command [{}] failed", args_string))
    }
}

async fn build_project(project: &Project, config: &Config) -> Result<bool> {
    info!("Building {}", project);
    match run_wash_command(&["build"], Some(project.directory()), config).await {
        Ok(_) => {
            info!("Build successful for {}", project);
            Ok(true)
        }
        Err(e) => {
            warn!("Build failed for {}: {:?}", project, e);
            Ok(false)
        }
    }
}

async fn push_project(project: &Project, config: &Config) -> Result<()> {
    let build_output_dir = project.directory().join(BUILD_DIR);
    if !build_output_dir.is_dir() {
        warn!(
            "Build directory {} not found for project {}",
            build_output_dir.display(),
            project.directory().display()
        );
        return Ok(());
    }

    let mut artifacts_pushed = 0;
    for entry in WalkDir::new(&build_output_dir).max_depth(1).min_depth(1) {
        let entry = entry.context("Failed to read build directory entry")?;
        let path = entry.path();

        if !path.is_file() {
            continue;
        }

        let file_name = path.file_name().and_then(|n| n.to_str()).unwrap_or("");
        let Some(image_ref) = project.get_image_reference(&config.registry_url, file_name) else {
            continue;
        };

        let artifact_path_str = path.to_string_lossy().to_string();
        info!(
            "Found artifact: {}. Pushing to {}",
            artifact_path_str, image_ref
        );

        let mut push_args = vec!["push", &image_ref, &artifact_path_str];
        if config.registry_insecure {
            push_args.push("--insecure");
        }

        run_wash_command(&push_args, Some(project.directory()), config)
            .await
            .with_context(|| format!("Failed to push artifact: {}", artifact_path_str))?;
        artifacts_pushed += 1;
    }

    if artifacts_pushed == 0 {
        warn!(
            "No component/provider artifacts found in {} for {}",
            build_output_dir.display(),
            project.directory().display()
        );
    }

    info!("Finished pushing artifacts for project: {}", project);
    Ok(())
}

fn find_deployment_manifest(project_dir: &Path) -> Option<PathBuf> {
    let manifest_path = project_dir.join(DEVELOP_WADM_YAML);
    if manifest_path.exists() {
        return Some(manifest_path);
    }

    if let Some(parent) = project_dir.parent() {
        find_deployment_manifest(parent)
    } else {
        None
    }
}

async fn deploy_project(project: &Project, config: &Config) -> Result<()> {
    match find_deployment_manifest(project.directory()) {
        Some(manifest_path) => {
            info!("Found {} for {}, deploying...", DEVELOP_WADM_YAML, project);
            let manifest_path_str = manifest_path.to_string_lossy();
            run_wash_command(
                &["app", "deploy", "--replace", &manifest_path_str],
                None,
                config,
            )
            .await
            .context("Wash app deploy command failed")
        }
        None => {
            info!(
                "No {} found in project or parent directories for {}, skipping deployment",
                DEVELOP_WADM_YAML, project
            );
            Ok(())
        }
    }
}

async fn rebuild_and_redeploy_project(project: &Project, config: &Config) -> Result<()> {
    if !build_project(project, config).await? {
        return Ok(());
    }

    push_project(project, config).await?;
    deploy_project(project, config).await?;
    Ok(())
}

async fn watch_projects(projects: Vec<Project>, config: &Config) -> Result<()> {
    let (tx, rx) = std_mpsc::channel();
    let mut debouncer: Debouncer<notify::RecommendedWatcher, _> =
        new_debouncer(Duration::from_millis(config.debounce_ms), None, tx)
            .context("Failed to create file watcher")?;

    for project in &projects {
        debouncer
            .watch(project.directory(), RecursiveMode::Recursive)
            .with_context(|| format!("Failed to watch project directory: {}", project))?;
    }

    info!("Watching {} projects for changes", projects.len());

    while let Ok(result) = rx.recv() {
        match result {
            Ok(events) => {
                let changed_projects = events
                    .iter()
                    .filter(|event| is_relevant_change(&event))
                    .filter_map(|event| {
                        projects.iter().find(|p| {
                            event
                                .paths
                                .iter()
                                .any(|path| path.starts_with(p.directory()))
                        })
                    })
                    .dedup()
                    .collect::<Vec<_>>();

                if changed_projects.is_empty() {
                    continue;
                }

                info!(
                    "Detected changes in files: {:?}",
                    events
                        .iter()
                        .flat_map(|e| e.paths.iter())
                        .collect::<Vec<_>>()
                );
                for project in changed_projects {
                    info!("Change detected in {}", project);
                    if let Err(e) = rebuild_and_redeploy_project(project, config).await {
                        error!("Failed to rebuild and redeploy {}: {:?}", project, e);
                    }
                }
            }
            Err(e) => error!("Error watching files: {:?}", e),
        }
    }

    Ok(())
}

#[tokio::main]
async fn main() -> Result<()> {
    let filter = EnvFilter::try_from_default_env()
        .unwrap_or_else(|_| EnvFilter::new("warn,developer_watcher=info"));

    tracing_subscriber::registry()
        .with(fmt::layer())
        .with(filter)
        .init();

    info!("Starting wasmCloud Developer Watcher...");

    let config = Config::parse();
    debug!("Configuration: {:?}", config);

    if !config.projects_base_dir.is_dir() {
        error!(
            "Projects base directory not found or not a directory: {}",
            config.projects_base_dir.display()
        );
        return Err(anyhow!("Invalid projects_base_dir"));
    }

    let projects = find_projects(&config.projects_base_dir)?;

    info!("Performing initial build and deploy of all projects...");
    for project in &projects {
        info!("Building and deploying {}...", project);
        if let Err(e) = rebuild_and_redeploy_project(project, &config).await {
            error!("Failed to build and deploy {}: {:?}", project, e);
        }
    }

    watch_projects(projects, &config).await?;

    info!("wasmCloud Developer Watcher finished.");
    Ok(())
}
