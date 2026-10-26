//! Keeps the evidence branch to media someone can still see. A pull request that closes
//! unmerged loses its media; a merged one keeps only its final commit's folder, for the
//! retention. Pushes retry onto whatever another job pushed first, and a squash pushes with a lease
//! and starts over when it loses it, so neither drops media published a moment earlier.

use std::fs;
use std::time::{Duration, SystemTime, UNIX_EPOCH};

use anyhow::{Context as _, Result};

use super::{ATTEMPTS, clone_branch, pr_folder};
use crate::Context;
use crate::branch::BranchCheckout;

/// Written into a merged pull request's folder: the Unix seconds it merged, which the weekly
/// run compares with the retention.
const MERGED_AT: &str = "merged-at";

#[derive(Debug)]
pub enum Prune {
    /// A pull request closed: drop everything (unmerged) or everything except `keep` (merged).
    Closed { pr: u64, merged: bool, keep: String },
    /// Drop merged pull requests older than `retention`, then replace history with one commit.
    Weekly { retention: Duration },
}

pub fn prune(ctx: &Context, action: Prune) -> Result<()> {
    let mut attempt = 1;
    loop {
        match prune_once(ctx, &action) {
            Err(error) if matches!(action, Prune::Weekly { .. }) && attempt < ATTEMPTS => {
                eprintln!("squash lost its lease, starting over: {error:#}");
                attempt += 1;
            }
            result => return result,
        }
    }
}

fn prune_once(ctx: &Context, action: &Prune) -> Result<()> {
    let repository = clone_branch(ctx)?;
    if repository.tip.is_empty() {
        println!("no evidence branch yet");
        return Ok(());
    }
    match action {
        Prune::Closed {
            pr, merged: false, ..
        } => remove(&repository, &pr_folder(*pr, None))?,
        Prune::Closed {
            pr,
            merged: true,
            keep,
        } => {
            let folder = repository.path(&pr_folder(*pr, None));
            let kept = repository.path(&pr_folder(*pr, Some(keep)));
            if folder.exists() {
                for entry in fs::read_dir(&folder)? {
                    let path = entry?.path();
                    if path != kept {
                        remove_path(&path)?;
                    }
                }
                fs::write(folder.join(MERGED_AT), now().as_secs().to_string())?;
            }
        }
        Prune::Weekly { retention } => {
            let cutoff = now().saturating_sub(*retention).as_secs();
            let prs = repository.path("pr");
            if prs.exists() {
                for entry in fs::read_dir(&prs)? {
                    let folder = entry?.path();
                    let merged_at = fs::read_to_string(folder.join(MERGED_AT))
                        .ok()
                        .and_then(|text| text.trim().parse::<u64>().ok());
                    if merged_at.is_some_and(|merged_at| merged_at < cutoff) {
                        remove_path(&folder)?;
                    }
                }
            }
            return repository.squash(ctx, "evidence snapshot");
        }
    }
    repository.commit_and_push(ctx, &format!("prune {action:?}"))
}

fn remove(repository: &BranchCheckout, relative: &str) -> Result<()> {
    let path = repository.path(relative);
    if path.exists() {
        remove_path(&path)?;
    }
    Ok(())
}

fn remove_path(path: &std::path::Path) -> Result<()> {
    if path.is_dir() {
        fs::remove_dir_all(path)
    } else {
        fs::remove_file(path)
    }
    .with_context(|| format!("cannot remove {}", path.display()))
}

/// The time since the Unix epoch. A clock before 1970 is a broken host, not a case to handle.
fn now() -> Duration {
    SystemTime::now()
        .duration_since(UNIX_EPOCH)
        .expect("the system clock is after the Unix epoch")
}
