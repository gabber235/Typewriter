//! `cargo xtask evidence`: records end to end runs, and keeps one managed section of the pull
//! request description current with what the run proved. Media lives in the two [`Store`]s of
//! [`REPOSITORY`], on branches that share no history with the code.

mod captions;
mod prune;
pub(crate) mod publish;
mod record;
mod stage;

use std::path::{Path, PathBuf};
use std::time::Duration;

use anyhow::Result;
use clap::{ArgAction, Args, Subcommand};

use self::prune::Prune;
pub(crate) use self::record::file_name;
pub use self::record::{Recorded, record_with};
pub(crate) use self::record::{SCREEN, WindowMargins};
use crate::branch::{ATTEMPTS, BranchCheckout, REPOSITORY};
use crate::docs::{PAGES, SITE};
use crate::{CommandExt, Context};

/// The orphan branch holding the images, one folder per pull request.
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
    /// Writes the public projection of the results folder to `.xtask/public`, the only folder
    /// CI uploads; refuses when it would hold a known secret.
    Stage,
    /// Drops media nobody can see any more from both stores.
    #[command(subcommand)]
    Prune(PruneCommand),
}

/// What the section is rendered from.
#[derive(Args)]
pub struct Inputs {
    /// The folder searched, at any depth, for `TestRun` JSON files; only its staged projection
    /// is read.
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
        EvidenceCommand::Stage => stage::stage(ctx),
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

/// Where a kind of media lives. Each pull request holds only its latest run's commit folder; the
/// commit stays in the path because GitHub's image proxy may keep serving an old file at a reused
/// URL.
#[derive(Clone, Copy, Debug, PartialEq, Eq)]
enum Store {
    /// Previews and screenshots on [`BRANCH`]. The raw host answers directly, where
    /// `github.com/<repo>/raw/` redirects to it first, and browsers decode webp and png even
    /// though it labels webp `application/octet-stream`.
    Images,
    /// Clips on the documentation site's branch, in a folder of their own. The raw host labels an
    /// mp4 `application/octet-stream`, so a link to it downloads; the site serves it as a video
    /// that plays in the tab. Only clips live here: they are small, and the site shares GitHub's
    /// limit of about 1 GB with the documentation.
    Videos,
}

impl Store {
    const ALL: [Self; 2] = [Self::Images, Self::Videos];

    /// The store `file` belongs in.
    fn of(file: &Path) -> Self {
        if file.extension().is_some_and(|extension| extension == "mp4") {
            Self::Videos
        } else {
            Self::Images
        }
    }

    /// The folder of every pull request's media, relative to the branch.
    fn root(self) -> &'static str {
        match self {
            Self::Images => "pr",
            Self::Videos => "evidence/pr",
        }
    }

    /// The folder of one pull request's media, or of one of its commits.
    fn folder(self, pr: u64, sha: Option<&str>) -> String {
        let root = self.root();
        match sha {
            Some(sha) => format!("{root}/{pr}/{}", &sha[..sha.len().min(7)]),
            None => format!("{root}/{pr}"),
        }
    }

    /// Where `file` of pull request `pr`'s commit `sha` is served.
    fn url(self, pr: u64, sha: &str, file: &Path) -> String {
        let folder = self.folder(pr, Some(sha));
        let file = file.display();
        match self {
            Self::Images => {
                format!("https://raw.githubusercontent.com/{REPOSITORY}/{BRANCH}/{folder}/{file}")
            }
            Self::Videos => format!("{SITE}/{folder}/{file}"),
        }
    }

    /// A shallow checkout of the store's branch.
    fn checkout(self, ctx: &Context) -> Result<BranchCheckout> {
        let branch = match self {
            Self::Images => BRANCH,
            Self::Videos => PAGES,
        };
        BranchCheckout::clone_shallow(ctx, branch, "Typewriter evidence")
    }
}
