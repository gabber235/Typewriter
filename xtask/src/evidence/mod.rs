//! `cargo xtask evidence`: records end to end runs, and keeps one managed section of the pull
//! request description current with what the run proved. Media lives on [`BRANCH`], an orphan
//! branch of [`REPOSITORY`] that shares no history with the code, so previews render inline from
//! [`media_url`].

mod prune;
pub(crate) mod publish;
mod record;

use std::path::PathBuf;
use std::time::Duration;

use anyhow::Result;
use clap::{ArgAction, Args, Subcommand};

use self::prune::Prune;
pub use self::record::{Recorded, record_with};
use crate::branch::{ATTEMPTS, BranchCheckout, REPOSITORY};
use crate::{CommandExt, Context};

/// The orphan branch holding the media, one folder per pull request commit.
const BRANCH: &str = "evidence";
/// Where the runners write their `TestRun`s, relative to the repository root; CI downloads the
/// other jobs' runs below it.
pub const RESULTS: &str = ".xtask/results";
/// Where `cargo xtask review report --json` output is read from, relative to the repository root.
const REPORT: &str = ".xtask/review/report.json";

#[derive(Subcommand)]
pub enum EvidenceCommand {
    /// Runs a command that writes a `TestRun` to <OUT>/test_run.json; on Linux it runs on a
    /// virtual display that is recorded and cut into one clip per case.
    Record {
        /// The evidence folder: the `TestRun`, the recording and the clips.
        #[arg(long)]
        out: PathBuf,
        /// Provides the display without recording it (the Minecraft client records itself).
        #[arg(long)]
        display_only: bool,
        /// A program to run on the display next to the command, for example
        /// `--with "chromedriver --port=4444"`.
        #[arg(long = "with")]
        companions: Vec<String>,
        #[arg(last = true, required = true)]
        command: Vec<String>,
    },
    /// Uploads the media and rewrites the managed section of the pull request description.
    Publish {
        #[arg(long)]
        pr: u64,
        /// The pull request's head commit.
        #[arg(long)]
        sha: String,
        #[command(flatten)]
        inputs: Inputs,
    },
    /// Prints the managed section without uploading media (fork pull requests' job summary).
    Summary {
        /// Defaults to HEAD.
        #[arg(long)]
        sha: Option<String>,
        #[command(flatten)]
        inputs: Inputs,
    },
    /// Drops media nobody can see any more from the evidence branch.
    #[command(subcommand)]
    Prune(PruneCommand),
}

/// What the section is rendered from.
#[derive(Args)]
pub struct Inputs {
    /// The folder searched, at any depth, for `TestRun` JSON files.
    #[arg(long, default_value = RESULTS)]
    results: PathBuf,
    /// The change report, as `cargo xtask review report --json` prints it.
    #[arg(long, default_value = REPORT)]
    report: PathBuf,
}

#[derive(Subcommand)]
pub enum PruneCommand {
    /// A pull request closed: drops all its media, or all but its final commit's when merged.
    Closed {
        #[arg(long)]
        pr: u64,
        #[arg(long, action = ArgAction::Set)]
        merged: bool,
        /// The head commit when the pull request closed.
        #[arg(long)]
        keep: String,
    },
    /// Drops merged pull requests' media older than the retention, then squashes history.
    Weekly {
        /// Days, written as `30d`.
        #[arg(long, value_parser = days)]
        retention: Duration,
    },
}

pub fn run(ctx: &Context, command: EvidenceCommand) -> Result<()> {
    match command {
        EvidenceCommand::Record {
            out,
            display_only,
            companions,
            command,
        } => {
            let recorded = companions.iter().fold(
                Recorded {
                    video: !display_only,
                    ..Recorded::video(command)
                },
                |recorded, line| recorded.with(line.split_whitespace().map(String::from).collect()),
            );
            let run = record::record(ctx, &ctx.root.join(out), recorded)?;
            println!("recorded {} cases", run.cases.len());
            Ok(())
        }
        EvidenceCommand::Publish { pr, sha, inputs } => publish::publish(ctx, pr, &sha, &inputs),
        EvidenceCommand::Summary { sha, inputs } => {
            let sha = match sha {
                Some(sha) => sha,
                None => ctx
                    .tool(".", "git", &["rev-parse", "HEAD"])
                    .output_text()?
                    .trim()
                    .to_string(),
            };
            print!("{}", publish::summary(ctx, &sha, &inputs)?);
            Ok(())
        }
        EvidenceCommand::Prune(PruneCommand::Closed { pr, merged, keep }) => {
            prune::prune(ctx, Prune::Closed { pr, merged, keep })
        }
        EvidenceCommand::Prune(PruneCommand::Weekly { retention }) => {
            prune::prune(ctx, Prune::Weekly { retention })
        }
    }
}

/// `30d` as a duration.
fn days(text: &str) -> Result<Duration, String> {
    text.strip_suffix('d')
        .and_then(|days| days.parse::<u64>().ok())
        .map(|days| Duration::from_secs(days * 24 * 60 * 60))
        .ok_or_else(|| format!("expected days such as 30d, got {text}"))
}

/// Where `path` on [`BRANCH`] is served. The raw host answers directly, where
/// `github.com/<repo>/raw/` redirects to it first. GitHub renders these images inline without its
/// image proxy, and browsers decode webp and png even though the host labels webp
/// `application/octet-stream`; for the same reason a linked mp4 downloads rather than playing in
/// the tab.
fn media_url(path: &str) -> String {
    format!("https://raw.githubusercontent.com/{REPOSITORY}/{BRANCH}/{path}")
}

/// The folder of one pull request's media, or of one of its commits.
fn pr_folder(pr: u64, sha: Option<&str>) -> String {
    match sha {
        Some(sha) => format!("pr/{pr}/{}", &sha[..sha.len().min(7)]),
        None => format!("pr/{pr}"),
    }
}

/// A shallow checkout of [`BRANCH`].
fn clone_branch(ctx: &Context) -> Result<BranchCheckout> {
    BranchCheckout::clone_shallow(ctx, BRANCH, "Typewriter evidence")
}
