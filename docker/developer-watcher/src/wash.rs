use crate::config::{Config, WASH_CMD, WASH_CREDS_FILE, WASMCLOUD_JS_DOMAIN};
use anyhow::{Context, Result, anyhow};
use std::path::Path;
use std::process::Stdio;
use tokio::process::Command;
use tracing::{debug, error, info};

pub async fn run_wash_command(
    cmd_args: &[&str],
    cwd: Option<&Path>,
    config: &Config,
) -> Result<()> {
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
