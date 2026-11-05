//! Publishing branches of [`REPOSITORY`] that share no history with the code: `evidence` holds the
//! pull requests' media, `gh-pages` the documentation previews. Jobs of different pull requests
//! write them at the same time, so every push retries onto whatever another job pushed first.

use std::fs;
use std::path::PathBuf;
use std::process::Command;

use anyhow::Result;

use crate::{CommandExt, Context, Scratch};

/// The repository whose pull requests CI reports on and whose publishing branches it writes.
pub const REPOSITORY: &str = "gabber235/TypeWriter";
/// How often a write that lost a race with another job (a push, a description edit) starts over
/// from the new state before giving up.
pub const ATTEMPTS: u32 = 5;

/// A shallow checkout of one publishing branch, removed on drop.
pub struct BranchCheckout {
    scratch: Scratch,
    branch: &'static str,
    /// The name commits are made under, so the branch history says which command wrote them.
    author: &'static str,
    /// The branch tip the checkout started from, empty while the branch does not exist yet: the
    /// lease every force push checks.
    pub tip: String,
}

impl BranchCheckout {
    /// Fetches only the tip of `branch`, or starts it as an orphan when it does not exist.
    pub fn clone_shallow(
        ctx: &Context,
        branch: &'static str,
        author: &'static str,
    ) -> Result<Self> {
        let scratch = Scratch::new(branch)?;
        fs::create_dir_all(scratch.0.join("repository"))?;
        let mut checkout = Self {
            scratch,
            branch,
            author,
            tip: String::new(),
        };
        let url = format!("https://github.com/{REPOSITORY}");
        checkout.git(ctx, &["init", "--quiet"]).run()?;
        checkout
            .git(ctx, &["remote", "add", "origin", &url])
            .run()?;
        let exists = !checkout
            .git(ctx, &["ls-remote", "--heads", "origin", branch])
            .output_text()?
            .trim()
            .is_empty();
        if exists {
            checkout.fetch_tip(ctx)?;
            checkout.tip = checkout
                .git(ctx, &["rev-parse", "HEAD"])
                .output_text()?
                .trim()
                .to_string();
        } else {
            checkout
                .git(ctx, &["checkout", "--quiet", "--orphan", branch])
                .run()?;
        }
        Ok(checkout)
    }

    fn fetch_tip(&self, ctx: &Context) -> Result<()> {
        self.git(
            ctx,
            &["fetch", "--quiet", "--depth", "1", "origin", self.branch],
        )
        .run()?;
        self.git(
            ctx,
            &["checkout", "--quiet", "-B", self.branch, "FETCH_HEAD"],
        )
        .run()
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
    pub fn commit_and_push(&self, ctx: &Context, message: &str) -> Result<()> {
        self.git(ctx, &["add", "--all"]).run()?;
        if self
            .git(ctx, &["diff", "--cached", "--quiet"])
            .run()
            .is_ok()
        {
            println!("{} branch unchanged", self.branch);
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
                .git(ctx, &["push", "origin", &format!("HEAD:{}", self.branch)])
                .run()
            else {
                return Ok(());
            };
            if attempt == ATTEMPTS {
                return Err(error.context(format!("gave up after {ATTEMPTS} pushes")));
            }
            attempt += 1;
            self.fetch_tip(ctx)?;
            self.committer(ctx, &["cherry-pick", &commit]).run()?;
        }
    }

    /// Replaces the history with one commit of the current tree, unless the branch moved since
    /// the checkout.
    pub fn squash(&self, ctx: &Context, message: &str) -> Result<()> {
        self.git(ctx, &["checkout", "--orphan", "snapshot"]).run()?;
        self.git(ctx, &["add", "--all"]).run()?;
        self.commit(ctx, message)?;
        let lease = format!("--force-with-lease={}:{}", self.branch, self.tip);
        self.git(
            ctx,
            &["push", &lease, "origin", &format!("HEAD:{}", self.branch)],
        )
        .run()
    }

    fn commit(&self, ctx: &Context, message: &str) -> Result<()> {
        self.committer(ctx, &["commit", "--quiet", "--message", message])
            .run()
    }

    /// Git in the checkout, committing as [`Self::author`].
    fn committer(&self, ctx: &Context, args: &[&str]) -> Command {
        let name = format!("user.name={}", self.author);
        let email = format!("user.email={}@typewriter.invalid", self.branch);
        let mut command = self.git(ctx, &["-c", &name, "-c", &email]);
        command.args(args);
        command
    }

    pub fn path(&self, relative: &str) -> PathBuf {
        self.checkout().join(relative)
    }
}
