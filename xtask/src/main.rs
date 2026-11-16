//! The Typewriter harness. Every command an agent, a developer or CI runs goes through here, so the
//! task graph, the build lock and the deploy steps are Rust instead of task wiring. devenv only
//! provides the tools these commands call.

mod branch;
mod cluster;
mod components;
mod deploy;
mod docs;
mod doctor;
mod e2e;
mod evidence;
mod generate;
mod gitops;
mod graph;
mod heavy;
mod hooks;
mod junit;
mod lock;
mod process;
mod results;
mod review;
mod secrets;
mod skirout;
mod stack;
#[cfg(test)]
mod test_support;

use std::fs::File;
use std::path::{Path, PathBuf};
use std::process::{Command, ExitCode, Stdio};

use anyhow::{Context as _, Result, bail};
use clap::Parser;
// The generated Skir types name their runtime as `crate::skir_client`.
#[allow(clippy::single_component_path_imports)]
use skir_client;

use crate::deploy::Cluster;
use crate::graph::Area;

#[derive(Parser)]
#[command(name = "xtask", about = "The Typewriter harness")]
enum Cli {
    /// Runs the pull request gate, or one area of it.
    Check {
        area: Option<Area>,
        /// Prints the areas with their time budgets as JSON (the CI matrix).
        #[arg(long, conflicts_with = "print")]
        list: bool,
        /// Prints each step's command instead of running it.
        #[arg(long)]
        print: bool,
        /// With `--list`, only the areas a change from this ref's merge base with HEAD to the
        /// working tree affects; empty when it touches only Markdown outside the documentation site.
        #[arg(long, requires = "list")]
        base: Option<String>,
    },
    /// Runs the component test suite, or one fixture of it; `check components` runs it all.
    Components(components::ComponentTestArgs),
    /// Builds and pushes components and the database image, then restarts workloads.
    Deploy { cluster: Cluster },
    /// Creates the throwaway CI cluster the full tier deploys to.
    #[command(subcommand)]
    Cluster(cluster::ClusterCommand),
    /// Regenerates the generated sources (Git ignores them) whose inputs changed.
    Generate,
    /// Runs an end to end suite against this worktree's stack and writes its `TestRun`.
    E2e(e2e::E2eArgs),
    /// Runs a command with this worktree's stack up, or removes stacks left behind.
    #[command(subcommand)]
    Stack(stack::StackCommand),
    /// Checks that the pinned tools are the ones on PATH, and says how to fix each problem.
    Doctor,
    /// Shows which secret profiles are satisfied, never a value.
    #[command(subcommand)]
    Secrets(secrets::SecretsCommand),
    /// The change report, the reviewer's investigation tools and code scanning findings.
    Review(review::ReviewArgs),
    /// Records end to end runs and publishes the pull request's evidence section.
    #[command(subcommand)]
    Evidence(evidence::EvidenceCommand),
    /// Publishes and removes documentation previews; `check docs` checks the site.
    #[command(subcommand)]
    Docs(docs::DocsCommand),
    /// Runs a command xtask has no command for under the machine wide heavy build lock,
    /// for example `cargo xtask heavy -- flutter test test/foo_test.dart`.
    Heavy {
        #[arg(last = true, required = true)]
        command: Vec<String>,
    },
    /// Runs a git hook's rules; devenv registers the hooks that call this.
    #[command(subcommand)]
    Hook(hooks::HookCommand),
    /// Runs one native step of the check graph, which starts it in its own process group.
    #[command(hide = true)]
    Step { name: String },
}

fn main() -> ExitCode {
    let context = Context::new();
    let result = match Cli::parse() {
        Cli::Check {
            area,
            list,
            print,
            base,
        } => {
            let steps = graph::select(area);
            if list {
                match base {
                    Some(base) => review::changed_paths(&context, &base)
                        .map(|paths| graph::list(&graph::affected(steps, &paths))),
                    None => {
                        graph::list(&steps);
                        Ok(())
                    }
                }
            } else if print {
                graph::print(&context, &steps);
                Ok(())
            } else {
                graph::run(&context, &steps)
            }
        }
        Cli::Components(args) => lock::HeavyLock::acquire("components")
            .and_then(|_lock| components::run(&context, &args, None)),
        Cli::Deploy { cluster } => deploy::deploy(&context, cluster),
        Cli::Cluster(command) => cluster::command(&context, command),
        Cli::Generate => generate::generate(&context, None),
        Cli::E2e(args) => e2e::run(&context, &args),
        Cli::Stack(command) => stack::command(&context, command),
        Cli::Doctor => doctor::doctor(&context),
        Cli::Secrets(command) => secrets::command(&context, command),
        Cli::Review(args) => review::run(&context, args),
        Cli::Evidence(command) => evidence::run(&context, command),
        Cli::Docs(command) => docs::run(&context, command),
        Cli::Hook(command) => hooks::run(&context, command),
        // The command's own exit code passes through.
        Cli::Heavy { command } => return heavy::run(&command).map_or_else(failed, ExitCode::from),
        Cli::Step { name } => graph::run_native(&context, &name),
    };
    result.map_or_else(failed, |()| ExitCode::SUCCESS)
}

fn failed(error: anyhow::Error) -> ExitCode {
    eprintln!("xtask: {error:#}");
    ExitCode::FAILURE
}

/// Where the repository is. Every path a command touches is resolved against `root`.
pub struct Context {
    pub root: PathBuf,
}

impl Context {
    fn new() -> Self {
        let manifest = Path::new(env!("CARGO_MANIFEST_DIR"));
        Self {
            root: manifest
                .parent()
                .expect("xtask lives inside the repository")
                .to_path_buf(),
        }
    }

    /// `program` with `args`, run from `cwd` relative to the repository root.
    pub fn tool(&self, cwd: &str, program: &str, args: &[&str]) -> Command {
        let mut command = Command::new(program);
        command.args(args).current_dir(self.root.join(cwd));
        // `cargo xtask` is itself a `cargo run`; its package variables must not leak into the
        // Cargo invocations the harness starts.
        command.env_remove("CARGO_MANIFEST_DIR");
        isolate_flutter_sdk(&mut command);
        command
    }
}

/// Git hands hooks in a worktree `GIT_DIR`, `GIT_INDEX_FILE` and friends. The Flutter launcher
/// compares `git -C $FLUTTER_ROOT rev-parse HEAD` with its tool stamp; with those variables set
/// that returns this repository's commit, so Flutter deletes the shared SDK's version cache and
/// rebuilds its tool, failing every other worktree building at that moment. Every `dart` or
/// `flutter` command therefore starts without them. `git` itself keeps them.
pub fn isolate_flutter_sdk(command: &mut Command) {
    let program = Path::new(command.get_program()).file_name();
    if program != Some("dart".as_ref()) && program != Some("flutter".as_ref()) {
        return;
    }
    for variable in [
        "GIT_DIR",
        "GIT_INDEX_FILE",
        "GIT_WORK_TREE",
        "GIT_PREFIX",
        "GIT_COMMON_DIR",
        "GIT_OBJECT_DIRECTORY",
    ] {
        command.env_remove(variable);
    }
}

/// Runs a command to completion with inherited output, failing on a nonzero exit.
pub trait CommandExt {
    fn run(&mut self) -> Result<()>;
    /// Captures standard output as text. Standard error is captured too unless the caller routes
    /// it elsewhere, and becomes part of the error on failure.
    fn output_text(&mut self) -> Result<String>;
    /// Sends standard error to `log` and closes standard input, or leaves both on the terminal.
    fn log_stderr(&mut self, log: Option<&File>) -> Result<&mut Self>;
    /// Sends standard output and standard error to `log`, or leaves them on the terminal.
    fn log_output(&mut self, log: Option<&File>) -> Result<&mut Self>;
}

impl CommandExt for Command {
    fn run(&mut self) -> Result<()> {
        let status = self
            .status()
            .with_context(|| format!("cannot start {}", display(self)))?;
        if !status.success() {
            bail!("{} failed with {status}", display(self));
        }
        Ok(())
    }

    fn output_text(&mut self) -> Result<String> {
        let output = self
            .output()
            .with_context(|| format!("cannot start {}", display(self)))?;
        if !output.status.success() {
            bail!(
                "{} failed with {}: {}",
                display(self),
                output.status,
                String::from_utf8_lossy(&output.stderr).trim()
            );
        }
        String::from_utf8(output.stdout)
            .with_context(|| format!("{} printed invalid UTF-8", display(self)))
    }

    fn log_stderr(&mut self, log: Option<&File>) -> Result<&mut Self> {
        if let Some(log) = log {
            self.stdin(Stdio::null()).stderr(log.try_clone()?);
        }
        Ok(self)
    }

    fn log_output(&mut self, log: Option<&File>) -> Result<&mut Self> {
        if let Some(log) = log {
            self.stdout(log.try_clone()?);
        }
        self.log_stderr(log)
    }
}

/// The value after this flag is a secret, which errors and logs show as `***`. A tool that reads a
/// secret only from its command line gets it through this long form.
const SECRET_FLAG: &str = "--password";

/// The command line as a person would type it, with secrets redacted.
pub fn display(command: &Command) -> String {
    let mut secret = false;
    std::iter::once(command.get_program())
        .chain(command.get_args())
        .map(|part| {
            let part = part.to_string_lossy();
            let shown = if secret {
                "***".to_owned()
            } else if part.starts_with(&format!("{SECRET_FLAG}=")) {
                format!("{SECRET_FLAG}=***")
            } else {
                part.into_owned()
            };
            secret = shown == SECRET_FLAG;
            shown
        })
        .collect::<Vec<_>>()
        .join(" ")
}

/// A temporary directory, removed on drop.
pub struct Scratch(pub PathBuf);

impl Scratch {
    pub fn new(purpose: &str) -> Result<Self> {
        let path =
            std::env::temp_dir().join(format!("typewriter-{purpose}-{}", std::process::id()));
        std::fs::create_dir_all(&path)
            .with_context(|| format!("cannot create {}", path.display()))?;
        Ok(Self(path))
    }
}

impl Drop for Scratch {
    fn drop(&mut self) {
        let _ = std::fs::remove_dir_all(&self.0);
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::test_support::removed_env;

    #[test]
    fn flutter_sdk_commands_get_no_git_repository_variables() {
        let ctx = Context::new();
        for program in ["dart", "flutter"] {
            let command = ctx.tool(".", program, &["--version"]);
            for variable in ["GIT_DIR", "GIT_INDEX_FILE", "GIT_WORK_TREE"] {
                assert!(
                    removed_env(&command).contains(&variable.to_string()),
                    "{program} keeps {variable}"
                );
            }
        }
    }

    #[test]
    fn git_commands_keep_their_repository_variables() {
        let command = Context::new().tool(".", "git", &["cat-file", "-p", ":file"]);
        assert!(!removed_env(&command).contains(&"GIT_DIR".to_string()));
        assert!(!removed_env(&command).contains(&"GIT_INDEX_FILE".to_string()));
    }

    #[test]
    fn heavy_flutter_commands_get_no_git_repository_variables() {
        let command = crate::heavy::command(&["flutter".into(), "test".into()]);
        assert!(removed_env(&command).contains(&"GIT_DIR".to_string()));
    }
}
