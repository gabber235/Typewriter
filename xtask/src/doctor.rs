//! The first command to run when the harness itself misbehaves. Each check prints `ok` or what is
//! wrong and the one command that fixes it.

use std::env;
use std::path::PathBuf;

use anyhow::{Result, bail};

use crate::graph::{CHECKS, Run};
use crate::{CommandExt, Context, cluster, deploy};

/// Tools native steps and commands call, beyond the programs the graph names.
const NATIVE_TOOLS: &[&str] = &[
    "ast-grep",
    "bun",
    "dart",
    "kustomize",
    "kubeconform",
    "yamllint",
    "gh",
];

const ENTER_SHELL: &str = "run inside `devenv shell`, or prefix the command with `devenv shell --`";

/// A named check; `None` means it passed, `Some` says what is wrong and how to fix it.
type Check = (&'static str, fn(&Context) -> Option<String>);

const DOCTOR_CHECKS: &[Check] = &[
    ("tools", tools_on_path),
    ("flutter", flutter_is_pinned),
    ("nats-server", nats_server_is_pinned),
    ("hooks", hooks_installed),
    ("stacks", no_orphaned_stacks),
];

pub fn doctor(ctx: &Context) -> Result<()> {
    let mut problems = 0;
    for (name, check) in DOCTOR_CHECKS {
        match check(ctx) {
            None => println!("{name:<12} ok"),
            Some(problem) => {
                problems += 1;
                println!("{name:<12} {problem}");
            }
        }
    }
    if problems > 0 {
        bail!("{problems} doctor checks failed");
    }
    Ok(())
}

/// Every program a step, a native step, deploy or the cluster commands run resolves on PATH.
fn tools_on_path(_: &Context) -> Option<String> {
    let mut tools = CHECKS
        .iter()
        .filter_map(|step| match step.run {
            // `./gradlew` ships with the repository; Java on PATH runs it.
            Run::Program {
                program: "./gradlew",
                ..
            } => Some("java"),
            Run::Program { program, .. } => Some(program),
            Run::Native { .. } => None,
        })
        .chain(NATIVE_TOOLS.iter().copied())
        .chain(deploy::TOOLS.iter().copied())
        .chain(cluster::TOOLS.iter().copied())
        .collect::<Vec<_>>();
    tools.sort_unstable();
    tools.dedup();
    let missing = tools
        .into_iter()
        .filter(|tool| which(tool).is_none())
        .collect::<Vec<_>>();
    (!missing.is_empty()).then(|| format!("missing {}; {ENTER_SHELL}", missing.join(", ")))
}

/// The Flutter on PATH is the one devenv pins through flutter-overlay, not another install.
fn flutter_is_pinned(_: &Context) -> Option<String> {
    let path = which("flutter")?;
    let pinned = env::var_os("DEVENV_PROFILE")
        .map(|profile| PathBuf::from(profile).join("bin/flutter"))
        .and_then(|pinned| pinned.canonicalize().ok())
        .is_some_and(|pinned| path.canonicalize().is_ok_and(|found| found == pinned));
    (!pinned).then(|| {
        format!(
            "{} is not the pinned Flutter; {ENTER_SHELL} so it comes first on PATH",
            path.display()
        )
    })
}

/// Tests that start their own broker use the pinned nats-server.
fn nats_server_is_pinned(_: &Context) -> Option<String> {
    match env::var_os("NATS_SERVER_BIN").map(PathBuf::from) {
        Some(path) if path.is_file() => None,
        Some(path) => Some(format!(
            "NATS_SERVER_BIN points at missing {}; re-enter `devenv shell`",
            path.display()
        )),
        None => Some(format!("NATS_SERVER_BIN is unset; {ENTER_SHELL}")),
    }
}

/// devenv installed the `commit-msg` and `pre-commit` hooks and linked this worktree's
/// `.pre-commit-config.yaml`, which happens on shell entry.
fn hooks_installed(ctx: &Context) -> Option<String> {
    let hooks = match ctx
        .tool(".", "git", &["rev-parse", "--git-path", "hooks"])
        .output_text()
    {
        Ok(hooks) => ctx.root.join(hooks.trim()),
        Err(error) => return Some(format!("cannot find the git hooks directory: {error:#}")),
    };
    let mut missing = ["commit-msg", "pre-commit"]
        .into_iter()
        .filter(|hook| !hooks.join(hook).is_file())
        .map(|hook| format!("{hook} hook"))
        .collect::<Vec<_>>();
    if !ctx.root.join(".pre-commit-config.yaml").is_file() {
        missing.push(".pre-commit-config.yaml".into());
    }
    (!missing.is_empty()).then(|| {
        format!(
            "missing {}; enter `devenv shell` once in this worktree to install the hooks",
            missing.join(", ")
        )
    })
}

fn which(program: &str) -> Option<PathBuf> {
    env::split_paths(&env::var_os("PATH")?)
        .map(|dir| dir.join(program))
        .find(|path| path.is_file())
}

/// No stack outlived its supervisor, as a stack does when an agent is killed with SIGKILL.
fn no_orphaned_stacks(_: &Context) -> Option<String> {
    let records = match crate::stack::StackRecord::all() {
        Ok(records) => records,
        Err(error) => return Some(format!("cannot read the stack registry: {error:#}")),
    };
    let orphaned: Vec<String> = records
        .into_iter()
        .filter(|record| !crate::stack::process_alive(record.owner))
        .map(|record| record.worktree.display().to_string())
        .collect();
    (!orphaned.is_empty()).then(|| {
        format!(
            "orphaned stacks of {}; run `cargo xtask stack gc`",
            orphaned.join(", ")
        )
    })
}
