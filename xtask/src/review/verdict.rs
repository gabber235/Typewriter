//! The reviewer's verdict in the pull request description, naming the commit it read. The evidence
//! section keeps a verdict only while that commit is the head; a later push marks it stale.

use std::fs;
use std::path::Path;

use anyhow::{Context as _, Result, bail, ensure};
use serde::Deserialize;

use super::change::{commit, git};
use crate::evidence::publish::{edit_pull_body, replace_between};
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
