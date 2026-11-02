//! The reviewer's verdict in the pull request description, naming the commit it read. A verdict
//! covers a head with the same changes, so a clean rebase keeps it and any other push asks for a
//! new one: the `Review` workflow fails and the evidence section marks the verdict stale.

use std::fs;
use std::path::Path;
use std::process::Stdio;

use anyhow::{Context as _, Result, bail, ensure};
use serde::Deserialize;

use super::change::{self, commit, git};
use crate::evidence::publish::{edit_pull_body, pull_body, replace_between};
use crate::{CommandExt, Context};

pub const START: &str = "<!-- verdict:start -->";
pub const END: &str = "<!-- verdict:end -->";
/// The first line inside the markers names the reviewed commit: `<!-- verdict:commit <hash> -->`.
pub const COMMIT: &str = "<!-- verdict:commit ";

#[derive(Deserialize)]
#[serde(rename_all = "camelCase")]
struct PullRequest {
    number: u64,
    head_ref_oid: String,
}

/// Writes the verdict in `file` into the description of the current branch's pull request, for
/// the head commit. Refuses when the reviewed code is not exactly what the pull request holds.
pub fn publish(ctx: &Context, file: &Path) -> Result<()> {
    let text =
        fs::read_to_string(file).with_context(|| format!("cannot read {}", file.display()))?;
    let dirty = git(ctx, &["status", "--porcelain", "--untracked-files=no"]).output_text()?;
    ensure!(
        dirty.trim().is_empty(),
        "the working tree has uncommitted changes; a verdict names a commit, so commit and push first"
    );
    let head = commit(ctx, "HEAD")?;
    let view = ctx
        .tool(".", "gh", &["pr", "view", "--json", "number,headRefOid"])
        .output_text()
        .context("no pull request found for this branch")?;
    let pull: PullRequest =
        serde_json::from_str(&view).context("gh printed an unexpected pull request")?;
    if pull.head_ref_oid != head {
        bail!(
            "the pull request head is {}, not the local HEAD {head}; push first",
            pull.head_ref_oid
        );
    }
    let block = format!("{COMMIT}{head} -->\n{}", text.trim());
    edit_pull_body(ctx, pull.number, |body| {
        Ok(replace_between(body, START, END, &block))
    })?;
    println!("verdict for {} published to #{}", &head[..9], pull.number);
    Ok(())
}

/// Fails unless the verdict in pull request `pr` covers `head`, naming what to review next.
pub fn require_covered(ctx: &Context, pr: u64, head: &str, base: Option<&str>) -> Result<()> {
    let body = pull_body(ctx, pr)?;
    let Some(reviewed) = reviewed_commit(&body) else {
        bail!("#{pr} has no verdict: run the typewriter-review skill on {head}");
    };
    let base = change::base(ctx, base)?;
    if !covers(ctx, reviewed, head, &base)? {
        bail!(
            "the verdict on #{pr} read {reviewed}, and {head} changes more: review what is new with `cargo xtask review report --base {reviewed}`"
        );
    }
    println!("the verdict on #{pr} covers {head}");
    Ok(())
}

/// The commit named by the verdict block in a pull request description.
fn reviewed_commit(body: &str) -> Option<&str> {
    let (_, block) = body.split_once(START)?;
    let (commit, _) = block.trim_start().strip_prefix(COMMIT)?.split_once("-->")?;
    Some(commit.trim())
}

/// Whether a review of `reviewed` also read everything in `head`: the same commit, or the same
/// changes against each commit's merge base with `base`. A commit a force push left unreachable
/// is fetched; one the remote no longer has cannot be compared, so it covers nothing.
pub fn covers(ctx: &Context, reviewed: &str, head: &str, base: &str) -> Result<bool> {
    if head.starts_with(reviewed) {
        return Ok(true);
    }
    let known = |commit: &str| {
        git(ctx, &["cat-file", "-e", &format!("{commit}^{{commit}}")])
            .stderr(Stdio::null())
            .status()
            .is_ok_and(|status| status.success())
    };
    if !known(reviewed) {
        let fetched = git(ctx, &["fetch", "--quiet", "origin", reviewed])
            .stderr(Stdio::null())
            .status()
            .is_ok_and(|status| status.success());
        if !fetched {
            return Ok(false);
        }
    }
    Ok(patch_id(ctx, reviewed, base)? == patch_id(ctx, head, base)?)
}

/// A hash of the change `commit` makes on top of its merge base with `base`, stable across the
/// line shifts a rebase causes.
fn patch_id(ctx: &Context, commit: &str, base: &str) -> Result<String> {
    let merge_base = git(ctx, &["merge-base", base, commit]).output_text()?;
    let mut diff = git(ctx, &["diff", merge_base.trim(), commit])
        .stdout(Stdio::piped())
        .spawn()
        .context("cannot start git diff")?;
    let patch = diff.stdout.take().context("git diff has no output")?;
    let id = git(ctx, &["patch-id", "--stable"])
        .stdin(patch)
        .output_text()?;
    ensure!(diff.wait()?.success(), "git diff {commit} failed");
    Ok(id.trim().to_owned())
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::test_support::diverged_branches;

    #[test]
    fn a_clean_rebase_keeps_the_verdict() {
        let root = diverged_branches();
        let reviewed = commit(&root.ctx, "feature").unwrap();
        root.git(&["rebase", "--quiet", "base", "feature"]);
        let head = commit(&root.ctx, "feature").unwrap();
        assert_ne!(reviewed, head);
        assert!(covers(&root.ctx, &reviewed, &head, "base").unwrap());
    }

    #[test]
    fn a_new_change_needs_a_new_verdict() {
        let root = diverged_branches();
        let reviewed = commit(&root.ctx, "feature").unwrap();
        root.git(&["checkout", "--quiet", "feature"]);
        root.save("feature.txt", "not reviewed\n");
        let head = commit(&root.ctx, "feature").unwrap();
        assert!(!covers(&root.ctx, &reviewed, &head, "base").unwrap());
    }

    #[test]
    fn a_description_names_the_reviewed_commit() {
        let body = format!("text\n{START}\n{COMMIT}abc123 -->\nLooks right.\n{END}");
        assert_eq!(reviewed_commit(&body), Some("abc123"));
        assert_eq!(reviewed_commit("no verdict here"), None);
    }
}
