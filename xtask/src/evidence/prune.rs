//! Keeps both media stores to what someone can still see. A pull request that closes unmerged
//! loses its media; a merged one keeps only its final commit's folder, for the retention. A golden
//! image no golden file on a long lived branch names goes once it is older than the retention too;
//! the weekly run fetches each long lived branch and reads its golden files. Pushes retry onto whatever another job pushed first, and a squash pushes with a lease
//! and starts over when it loses it, so neither drops media published a moment earlier.

use std::fs;
use std::path::Path;
use std::time::{Duration, SystemTime, UNIX_EPOCH};

use anyhow::{Context as _, Result};

use super::{ATTEMPTS, Store};
use crate::{Context, goldens};

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
    let used = match action {
        Prune::Weekly { .. } => goldens::named_on_long_lived(ctx)?,
        Prune::Closed { .. } => Vec::new(),
    };
    let mut attempt = 1;
    loop {
        match Store::ALL
            .into_iter()
            .try_for_each(|store| prune_store(ctx, store, &action, &used))
        {
            Err(error) if matches!(action, Prune::Weekly { .. }) && attempt < ATTEMPTS => {
                eprintln!("squash lost its lease, starting over: {error:#}");
                attempt += 1;
            }
            result => return result,
        }
    }
}

fn prune_store(ctx: &Context, store: Store, action: &Prune, used: &[String]) -> Result<()> {
    let repository = store.checkout(ctx)?;
    if repository.tip.is_empty() {
        println!("no {store:?} branch yet");
        return Ok(());
    }
    prune_tree(&repository.path(""), store, action, used)?;
    match action {
        Prune::Weekly { .. } => repository.squash(ctx, "evidence snapshot"),
        Prune::Closed { .. } => repository.commit_and_push(ctx, &format!("prune {action:?}")),
    }
}

/// Drops what `action` drops from the pull request folders of `store` in the branch tree at
/// `tree`; a weekly prune of the images also drops the golden images whose hash is not among
/// `used` once they are older than the retention.
fn prune_tree(tree: &Path, store: Store, action: &Prune, used: &[String]) -> Result<()> {
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
            if store == Store::Images {
                goldens::drop_unused(tree, used, cutoff)?;
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
    use std::time::Duration;

    use super::{Prune, prune_tree};
    use crate::evidence::Store;
    use crate::test_support::TempRoot;

    #[test]
    fn a_golden_image_a_golden_file_on_develop_names_is_kept_however_old() {
        let branch = TempRoot::new();
        branch.write("goldens/5e1d.png", "golden");
        branch.write("goldens/5e1d.approved-at", "0");

        prune_tree(
            &branch.ctx.root,
            Store::Images,
            &Prune::Weekly {
                retention: Duration::from_secs(60),
            },
            &["5e1d".to_owned()],
        )
        .unwrap();

        assert!(branch.path("goldens/5e1d.png").exists());
        assert!(branch.path("goldens/5e1d.approved-at").exists());
    }

    #[test]
    fn an_unused_golden_image_approved_within_the_retention_is_kept() {
        let branch = TempRoot::new();
        branch.write("goldens/5e1d.png", "golden");
        branch.write(
            "goldens/5e1d.approved-at",
            &super::now().as_secs().to_string(),
        );

        prune_tree(
            &branch.ctx.root,
            Store::Images,
            &Prune::Weekly {
                retention: Duration::from_secs(60),
            },
            &[],
        )
        .unwrap();

        assert!(branch.path("goldens/5e1d.png").exists());
        assert!(branch.path("goldens/5e1d.approved-at").exists());
    }

    #[test]
    fn an_unused_golden_image_older_than_the_retention_goes_and_one_without_an_approval_time_counts_as_old()
     {
        let branch = TempRoot::new();
        branch.write("goldens/5e1d.png", "old");
        branch.write("goldens/5e1d.approved-at", "0");
        branch.write("goldens/9a2f.png", "never timed");

        prune_tree(
            &branch.ctx.root,
            Store::Images,
            &Prune::Weekly {
                retention: Duration::from_secs(60),
            },
            &[],
        )
        .unwrap();

        assert!(!branch.path("goldens/5e1d.png").exists());
        assert!(!branch.path("goldens/5e1d.approved-at").exists());
        assert!(!branch.path("goldens/9a2f.png").exists());
    }
}
