use clap::Parser;
use std::path::PathBuf;

pub const WASH_CMD: &str = "wash";
pub const WASH_CREDS_FILE: &str = "/app/wasmcloud.creds";
pub const WASMCLOUD_JS_DOMAIN: &str = "core";
pub const PROJECT_MARKER: &str = "wasmcloud.toml";
pub const PROJECT_CARGO: &str = "Cargo.toml";
pub const BUILD_DIR: &str = "build";
pub const COMPONENT_SUFFIX: &str = "_s.wasm";
pub const PROVIDER_SUFFIX: &str = ".par.gz";
pub const DEVELOP_WADM_YAML: &str = "develop.wadm.yaml";

pub const WATCHED_EXTENSIONS: &[&str] = &["rs", "toml", "yaml", "yml", "json"];
pub const IGNORED_PATTERNS: &[&str] = &[
    "target",
    "build",
    ".git",
    ".idea",
    ".vscode",
    "node_modules",
];

#[derive(Parser, Debug, Clone)]
#[clap(author, version, about, long_about = None)]
pub struct Config {
    #[clap(long, env = "WDEV_PROJECTS_BASE_DIR", default_value = "/app/projects")]
    pub projects_base_dir: PathBuf,

    #[clap(long, env = "WASH_NATS_HOST", default_value = "nats")]
    pub nats_host: String,

    #[clap(long, env = "WASH_NATS_PORT", default_value = "4222")]
    pub nats_port: u16,

    #[clap(long, env = "WASH_REGISTRY", default_value = "registry:5001")]
    pub registry_url: String,

    #[clap(long, env = "WASH_REGISTRY_INSECURE", action, default_value = "true")]
    pub registry_insecure: bool,

    #[clap(long, env = "WASMCLOUD_CTL_HOST", default_value = "nats")]
    pub ctl_host: String,

    #[clap(long, env = "WASMCLOUD_CTL_PORT", default_value = "4222")]
    pub ctl_port: u16,

    #[clap(long, env = "WDEV_DEBOUNCE_MS", default_value = "1000")]
    pub debounce_ms: u64,
}
