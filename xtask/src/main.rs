//! The Typewriter harness. Every command an agent, Gabber or CI runs goes through here, so the
//! task graph, the build lock and the deploy steps are Rust instead of task wiring. devenv only
//! provides the tools these commands call.

mod cluster;
mod components;
mod deploy;
mod doctor;
mod e2e;
mod evidence;
mod generate;
mod gitops;
mod graph;
mod hooks;
mod lock;
mod process;
mod results;
mod review;
mod skirout;
mod stack;

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
        /// working tree affects; empty when it touches only documentation.
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
    E2e { suite: e2e::Suite },
    /// Runs a command with this worktree's stack up, or removes stacks left behind.
    #[command(subcommand)]
    Stack(stack::StackCommand),
    /// Checks that the pinned tools are the ones on PATH, and says how to fix each problem.
    Doctor,
    /// The change report, the reviewer's investigation tools and code scanning findings.
    Review(review::ReviewArgs),
    /// Records end to end runs and publishes the pull request's evidence section.
    #[command(subcommand)]
    Evidence(evidence::EvidenceCommand),
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
        Cli::E2e { suite } => e2e::run(&context, suite),
        Cli::Stack(command) => stack::command(&context, command),
        Cli::Doctor => doctor::doctor(&context),
        Cli::Review(args) => review::run(&context, args),
        Cli::Evidence(command) => evidence::run(&context, command),
        Cli::Hook(command) => hooks::run(&context, command),
        Cli::Step { name } => graph::run_native(&context, &name),
    };
    match result {
        Ok(()) => ExitCode::SUCCESS,
        Err(error) => {
            eprintln!("xtask: {error:#}");
            ExitCode::FAILURE
        }
    }
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
        command
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
