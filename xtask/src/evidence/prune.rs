//! Keeps both media stores to what someone can still see. A pull request that closes unmerged
//! loses its media; a merged one keeps only its final commit's folder, for the retention. Pushes retry onto whatever another job pushed first, and a squash pushes with a lease
//! and starts over when it loses it, so neither drops media published a moment earlier.

use std::fs;
use std::path::Path;
use std::time::{Duration, SystemTime, UNIX_EPOCH};

use anyhow::{Context as _, Result};

use super::{ATTEMPTS, Store};
use crate::Context;

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
        match Store::ALL
            .into_iter()
            .try_for_each(|store| prune_store(ctx, store, &action))
        {
            Err(error) if matches!(action, Prune::Weekly { .. }) && attempt < ATTEMPTS => {
                eprintln!("squash lost its lease, starting over: {error:#}");
                attempt += 1;
            }
            result => return result,
        }
    }
}

fn prune_store(ctx: &Context, store: Store, action: &Prune) -> Result<()> {
    let repository = store.checkout(ctx)?;
    if repository.tip.is_empty() {
        println!("no {store:?} branch yet");
        return Ok(());
    }
    prune_tree(&repository.path(""), store, action)?;
    match action {
        Prune::Weekly { .. } => repository.squash(ctx, "evidence snapshot"),
        Prune::Closed { .. } => repository.commit_and_push(ctx, &format!("prune {action:?}")),
    }
}

/// Drops what `action` drops from the pull request folders of `store` in the branch tree at
/// `tree`. Only those folders: what lives beside them, such as the golden images, stays.
fn prune_tree(tree: &Path, store: Store, action: &Prune) -> Result<()> {
    match action {
        Prune::Closed {
            pr, merged: false, ..
        } => remove(&tree.join(store.folder(*pr, None)))?,
        Prune::Closed {
            pr,
            merged: true,
            keep,
        } => {
            let folder = tree.join(store.folder(*pr, None));
            let kept = tree.join(store.folder(*pr, Some(keep)));
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
            let prs = tree.join(store.root());
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
        }
    }
    Ok(())
}

fn remove(path: &Path) -> Result<()> {
    if path.exists() {
        remove_path(path)?;
    }
    Ok(())
}

fn remove_path(path: &Path) -> Result<()> {
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

#[cfg(test)]
mod tests {
    use std::fs;
    use std::time::Duration;

    use super::{Prune, prune_tree};
    use crate::evidence::Store;
    use crate::test_support::TempRoot;

    #[test]
    fn pruning_pull_requests_keeps_the_golden_images_beside_them() {
        let branch = TempRoot::new();
        branch.write("goldens/5e1d.png", "golden");
        branch.write("pr/546/abc1234/frame.png", "closed unmerged");
        branch.write("pr/547/def5678/frame.png", "merged long ago");
        branch.write("pr/547/merged-at", "0");

        for action in [
            Prune::Closed {
                pr: 546,
                merged: false,
                keep: String::new(),
            },
            Prune::Weekly {
                retention: Duration::from_secs(60),
            },
        ] {
            prune_tree(&branch.ctx.root, Store::Images, &action).unwrap();
        }

        assert!(!branch.path("pr/546").exists());
        assert!(!branch.path("pr/547").exists());
        assert_eq!(
            fs::read_to_string(branch.path("goldens/5e1d.png")).unwrap(),
            "golden"
        );
    }
}
