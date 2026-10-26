//! `cargo xtask evidence`: records end to end runs, and keeps one managed section of the pull
//! request description current with what the run proved. Media lives on [`BRANCH`], an orphan
//! branch of [`REPOSITORY`] that shares no history with the code, so previews render inline from
//! [`media_url`].

mod prune;
pub(crate) mod publish;
mod record;

use std::fs;
use std::path::PathBuf;
use std::process::Command;
use std::time::Duration;

use anyhow::Result;
use clap::{ArgAction, Args, Subcommand};

use self::prune::Prune;
pub use self::record::{Recorded, record_with};
use crate::{CommandExt, Context, Scratch};

/// The repository whose pull requests carry the section and whose [`BRANCH`] holds the media.
const REPOSITORY: &str = "gabber235/TypeWriter";
/// The orphan branch holding the media, one folder per pull request commit.
const BRANCH: &str = "evidence";
/// Where the runners write their `TestRun`s, relative to the repository root; CI downloads the
/// other jobs' runs below it.
pub const RESULTS: &str = ".xtask/results";
/// Where `cargo xtask review report --json` output is read from, relative to the repository root.
const REPORT: &str = ".xtask/review/report.json";
/// How often a write that lost a race with another job (a push, a description edit) starts over
/// from the new state before giving up.
const ATTEMPTS: u32 = 5;

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

/// A shallow checkout of [`BRANCH`], removed on drop.
struct EvidenceRepository {
    scratch: Scratch,
    /// The branch tip the checkout started from, empty while the branch does not exist yet: the
    /// lease every force push checks.
    tip: String,
}

impl EvidenceRepository {
    /// Fetches only the tip of [`BRANCH`], or starts it as an orphan when it does not exist.
    fn clone_shallow(ctx: &Context) -> Result<Self> {
        let scratch = Scratch::new("evidence")?;
        fs::create_dir_all(scratch.0.join("repository"))?;
        let mut repository = Self {
            scratch,
            tip: String::new(),
        };
        let url = format!("https://github.com/{REPOSITORY}");
        repository.git(ctx, &["init", "--quiet"]).run()?;
        repository
            .git(ctx, &["remote", "add", "origin", &url])
            .run()?;
        let exists = !repository
            .git(ctx, &["ls-remote", "--heads", "origin", BRANCH])
            .output_text()?
            .trim()
            .is_empty();
        if exists {
            repository
                .git(ctx, &["fetch", "--quiet", "--depth", "1", "origin", BRANCH])
                .run()?;
            repository
                .git(ctx, &["checkout", "--quiet", "-B", BRANCH, "FETCH_HEAD"])
                .run()?;
            repository.tip = repository
                .git(ctx, &["rev-parse", "HEAD"])
                .output_text()?
                .trim()
                .to_string();
        } else {
            repository
                .git(ctx, &["checkout", "--quiet", "--orphan", BRANCH])
                .run()?;
        }
        Ok(repository)
    }

    fn checkout(&self) -> PathBuf {
        self.scratch.0.join("repository")
    }

    /// Git in the checkout. With `GH_TOKEN` set (CI passes the workflow token) gh answers the
    /// credential prompt; otherwise the user's own git credentials apply. The token stays in the
    /// environment, out of the command line and the checkout's config.
    fn git(&self, ctx: &Context, args: &[&str]) -> Command {
        let mut command = ctx.tool(".", "git", args);
        command.current_dir(self.checkout());
        if std::env::var_os("GH_TOKEN").is_some() {
            // An empty helper first clears the inherited ones, as `gh auth setup-git` does.
            let helper = "credential.https://github.com.helper";
            command
                .env("GIT_CONFIG_COUNT", "2")
                .env("GIT_CONFIG_KEY_0", helper)
                .env("GIT_CONFIG_VALUE_0", "")
                .env("GIT_CONFIG_KEY_1", helper)
                .env("GIT_CONFIG_VALUE_1", "!gh auth git-credential");
        }
        command
    }

    /// Commits everything and pushes. Fast forward only, so it never drops another push; when
    /// another job pushed first, the commit moves onto the new tip and the push is retried.
    fn commit_and_push(&self, ctx: &Context, message: &str) -> Result<()> {
        self.git(ctx, &["add", "--all"]).run()?;
        if self
            .git(ctx, &["diff", "--cached", "--quiet"])
            .run()
            .is_ok()
        {
            println!("evidence branch unchanged");
            return Ok(());
        }
        self.commit(ctx, message)?;
        let commit = self
            .git(ctx, &["rev-parse", "HEAD"])
            .output_text()?
            .trim()
            .to_string();
        let mut attempt = 1;
        loop {
            let Err(error) = self
                .git(ctx, &["push", "origin", &format!("HEAD:{BRANCH}")])
                .run()
            else {
                return Ok(());
            };
            if attempt == ATTEMPTS {
                return Err(error.context(format!("gave up after {ATTEMPTS} pushes")));
            }
            attempt += 1;
            self.git(ctx, &["fetch", "--quiet", "--depth", "1", "origin", BRANCH])
                .run()?;
            self.git(ctx, &["checkout", "--quiet", "-B", BRANCH, "FETCH_HEAD"])
                .run()?;
            self.committer(ctx, &["cherry-pick", &commit]).run()?;
        }
    }

    /// Replaces the history with one commit of the current tree, unless the branch moved since
    /// the checkout.
    fn squash(&self, ctx: &Context, message: &str) -> Result<()> {
        self.git(ctx, &["checkout", "--orphan", "snapshot"]).run()?;
        self.git(ctx, &["add", "--all"]).run()?;
        self.commit(ctx, message)?;
        let lease = format!("--force-with-lease={BRANCH}:{}", self.tip);
        self.git(ctx, &["push", &lease, "origin", &format!("HEAD:{BRANCH}")])
            .run()
    }

    fn commit(&self, ctx: &Context, message: &str) -> Result<()> {
        self.committer(ctx, &["commit", "--quiet", "--message", message])
            .run()
    }

    /// Git in the checkout, committing as the evidence bot.
    fn committer(&self, ctx: &Context, args: &[&str]) -> Command {
        let mut command = self.git(
            ctx,
            &[
                "-c",
                "user.name=Typewriter evidence",
                "-c",
                "user.email=evidence@typewriter.invalid",
            ],
        );
        command.args(args);
        command
    }

    fn path(&self, relative: &str) -> PathBuf {
        self.checkout().join(relative)
    }
}
