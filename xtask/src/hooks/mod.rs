//! The git hooks' rules. devenv's `git-hooks` module registers `commit-msg` and `pre-commit` on
//! shell entry (devenv.nix) and each runs `cargo xtask hook <name>`, so the hook, CI and an agent
//! checking its own commits run the same Rust. Nothing here installs hooks or touches git config.

mod commit_msg;
mod pre_commit;

use std::fs;
use std::path::PathBuf;

use anyhow::{Context as _, Result};
use clap::Subcommand;

use crate::Context;

#[derive(Subcommand)]
pub enum HookCommand {
    /// Checks a commit message file (the hook), or every commit in `--range base..head` (CI).
    CommitMsg {
        #[arg(required_unless_present = "range")]
        file: Option<PathBuf>,
        #[arg(long, conflicts_with = "file")]
        range: Option<String>,
    },
    /// Checks the staged files only: no generated output, Rust and Dart formatted.
    PreCommit,
}

pub fn run(ctx: &Context, command: HookCommand) -> Result<()> {
    match command {
        HookCommand::CommitMsg {
            range: Some(range), ..
        } => commit_msg::check_range(ctx, &range),
        HookCommand::CommitMsg {
            file: Some(file), ..
        } => {
            let message = fs::read_to_string(&file)
                .with_context(|| format!("cannot read {}", file.display()))?;
            commit_msg::check(&commit_msg::Scopes::load(ctx)?, &message)
        }
        HookCommand::CommitMsg { .. } => unreachable!("clap requires a file or --range"),
        HookCommand::PreCommit => pre_commit::check(ctx),
    }
}
