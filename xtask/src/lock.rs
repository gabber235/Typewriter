//! Machine wide limits shared by every worktree.

use std::fs::{File, OpenOptions, TryLockError};
use std::io::{Read as _, Seek as _, Write as _};
use std::path::{Path, PathBuf};
use std::thread;
use std::time::{Duration, SystemTime, UNIX_EPOCH};

use anyhow::{Context as _, Result, bail};
use serde::{Deserialize, Serialize};

use crate::process;

const HEAVY_LOCK: &str = "/tmp/typewriter-heavy.lock";
/// How often a waiter tries the lock again; polling instead of blocking lets it see an interrupt.
const LOCK_POLL: Duration = Duration::from_millis(500);

/// Set by `cargo xtask heavy` for its child, which runs while the heavy lock is held.
pub const HELD_BY_PARENT: &str = "TYPEWRITER_HEAVY_LOCK_HELD";

/// Held around compiles (Gradle, Cargo, Flutter tests), so only one heavy build runs on the
/// machine at a time, whichever worktree starts it. Released on drop.
pub struct HeavyLock {
    _file: File,
}

impl HeavyLock {
    /// Takes the lock, waiting for whoever holds it. `holder` says who is waiting, so the
    /// message names the step that queues. Gives up when the harness is interrupted.
    pub fn acquire(holder: &str) -> Result<Self> {
        Self::acquire_at(Path::new(HEAVY_LOCK), holder)
    }

    /// The lock at `path`; tests pass a temp file so they never queue behind real builds.
    pub fn acquire_at(path: &Path, holder: &str) -> Result<Self> {
        // flock is per open file, so a nested acquire would wait on its own parent forever.
        if std::env::var_os(HELD_BY_PARENT).is_some() {
            bail!(
                "{holder}: runs inside `cargo xtask heavy`, which already holds the heavy lock; \
                 run it directly"
            );
        }
        let mut file = open_lock(path)?;
        let mut announced = false;
        while !try_lock(&file, path)? {
            if !announced {
                let message = waiting_message(Holder::read(&mut file), now_secs());
                eprintln!("{holder}: {message}");
                announced = true;
            }
            wait_turn()?;
        }
        Holder::current(holder).claim(&mut file)?;
        Ok(Self { _file: file })
    }
}

/// One of a fixed number of machine wide end to end slots, so ten agents cannot start ten stacks
/// at once. There is one slot per 8 GB of memory unless `TYPEWRITER_E2E_SLOTS` says otherwise.
/// Each slot file records its holder, so a waiting run says who it waits for. Released on drop.
pub struct E2eSlot {
    _file: File,
}

impl E2eSlot {
    /// Takes the first free slot for the stack of `worktree`, waiting until one frees up. Gives
    /// up when the harness is interrupted.
    pub fn acquire(worktree: &Path) -> Result<Self> {
        let slots = std::env::var("TYPEWRITER_E2E_SLOTS")
            .ok()
            .and_then(|value| value.parse::<usize>().ok())
            .unwrap_or_else(|| (total_memory_gb() / 8).max(1));
        let mut files = Vec::with_capacity(slots);
        for index in 0..slots {
            let path = PathBuf::from(format!("/tmp/typewriter-e2e-{index}.lock"));
            let file = open_lock(&path)?;
            files.push((path, file));
        }
        let mut announced = false;
        loop {
            for index in 0..files.len() {
                let (path, file) = &files[index];
                if try_lock(file, path)? {
                    let (_, mut file) = files.swap_remove(index);
                    Holder {
                        worktree: worktree.to_path_buf(),
                        ..Holder::current("stack")
                    }
                    .claim(&mut file)?;
                    return Ok(Self { _file: file });
                }
            }
            if !announced {
                let now = now_secs();
                for (path, file) in &mut files {
                    let message = waiting_message(Holder::read(file), now);
                    eprintln!("stack: {} is held; {message}", path.display());
                }
                eprintln!("stack: waiting for an end to end slot");
                announced = true;
            }
            wait_turn()?;
        }
    }
}

/// Who holds a machine wide lock, written into its file once it is taken. HeavyLock and E2eSlot
/// share it, so a waiter can say who it waits for. The next holder rewrites it.
#[derive(Debug, PartialEq, Serialize, Deserialize)]
struct Holder {
    name: String,
    worktree: PathBuf,
    pid: u32,
    started_at_secs: u64,
}

impl Holder {
    /// This process in this worktree, holding from now on.
    fn current(name: &str) -> Self {
        Self {
            name: name.to_owned(),
            worktree: crate::Context::new().root,
            pid: std::process::id(),
            started_at_secs: now_secs(),
        }
    }

    /// Writes this holder into a lock file the caller has just locked.
    fn claim(&self, file: &mut File) -> Result<()> {
        file.set_len(0)?;
        file.rewind()?;
        serde_json::to_writer(&mut *file, self)?;
        file.flush()?;
        Ok(())
    }

    /// The holder in a lock file, None when it is empty or unreadable.
    fn read(file: &mut File) -> Option<Self> {
        let mut text = String::new();
        file.rewind().ok()?;
        file.read_to_string(&mut text).ok()?;
        serde_json::from_str(&text).ok()
    }
}

/// `waiting for "e2e panel" in features-test-review (pid 4121, 3m 10s)`. An empty or unreadable
/// record, as in the moment between taking a lock and writing it, gives the generic message.
fn waiting_message(holder: Option<Holder>, now: u64) -> String {
    let Some(holder) = holder else {
        return "waiting for another heavy build".to_owned();
    };
    let worktree = holder.worktree.file_name().map_or_else(
        || holder.worktree.display().to_string(),
        |name| name.to_string_lossy().into_owned(),
    );
    let held = now.saturating_sub(holder.started_at_secs);
    let elapsed = match (held / 3600, held / 60 % 60, held % 60) {
        (0, 0, seconds) => format!("{seconds}s"),
        (0, minutes, seconds) => format!("{minutes}m {seconds}s"),
        (hours, minutes, _) => format!("{hours}h {minutes}m"),
    };
    format!(
        "waiting for \"{}\" in {worktree} (pid {}, {elapsed})",
        holder.name, holder.pid
    )
}

fn now_secs() -> u64 {
    SystemTime::now()
        .duration_since(UNIX_EPOCH)
        .map_or(0, |since| since.as_secs())
}

/// A lock file, created when missing and kept intact, so a waiter can read its holder.
fn open_lock(path: &Path) -> Result<File> {
    OpenOptions::new()
        .create(true)
        .truncate(false)
        .read(true)
        .write(true)
        .open(path)
        .with_context(|| format!("cannot open {}", path.display()))
}

/// Whether `file` is now locked by this process.
fn try_lock(file: &File, path: &Path) -> Result<bool> {
    match file.try_lock() {
        Ok(()) => Ok(true),
        Err(TryLockError::WouldBlock) => Ok(false),
        Err(TryLockError::Error(error)) => {
            Err(error).with_context(|| format!("cannot lock {}", path.display()))
        }
    }
}

/// Sleeps before the next lock attempt, or fails when the harness was interrupted meanwhile.
fn wait_turn() -> Result<()> {
    if process::interrupted() {
        bail!("interrupted while waiting for a lock");
    }
    thread::sleep(LOCK_POLL);
    Ok(())
}

/// Total physical memory, rounded down to whole gigabytes; 8 when it cannot be read.
fn total_memory_gb() -> usize {
    let bytes = if cfg!(target_os = "macos") {
        std::process::Command::new("sysctl")
            .args(["-n", "hw.memsize"])
            .output()
            .ok()
            .and_then(|output| String::from_utf8(output.stdout).ok())
            .and_then(|text| text.trim().parse::<u64>().ok())
    } else {
        std::fs::read_to_string("/proc/meminfo")
            .ok()
            .and_then(|text| {
                text.lines()
                    .find_map(|line| line.strip_prefix("MemTotal:"))
                    .and_then(|rest| {
                        rest.trim()
                            .trim_end_matches("kB")
                            .trim()
                            .parse::<u64>()
                            .ok()
                    })
                    .map(|kilobytes| kilobytes * 1024)
            })
    };
    bytes.map_or(8, |bytes| (bytes >> 30) as usize)
}

#[cfg(test)]
mod tests {
    use std::sync::mpsc;

    use super::*;

    #[test]
    fn a_second_heavy_build_waits_until_the_first_releases() {
        let dir = tempfile::tempdir().unwrap();
        let path = dir.path().join("heavy.lock");
        let first = HeavyLock::acquire_at(&path, "first").unwrap();
        let (sender, received) = mpsc::channel();
        let waiter = thread::spawn({
            let path = path.clone();
            move || {
                let _second = HeavyLock::acquire_at(&path, "second").unwrap();
                sender.send(()).unwrap();
            }
        });
        assert!(received.recv_timeout(Duration::from_secs(1)).is_err());
        drop(first);
        assert!(received.recv_timeout(Duration::from_secs(5)).is_ok());
        waiter.join().unwrap();
    }

    #[test]
    fn a_waiter_names_the_holder_its_worktree_and_how_long_it_has_held() {
        let dir = tempfile::tempdir().unwrap();
        let path = dir.path().join("heavy.lock");
        let _held = HeavyLock::acquire_at(&path, "e2e panel").unwrap();
        let mut waiter = open_lock(&path).unwrap();
        let holder = Holder::read(&mut waiter).unwrap();
        let worktree = crate::Context::new().root;
        let worktree = worktree.file_name().unwrap().to_string_lossy();
        let pid = std::process::id();

        let message = waiting_message(Some(holder), now_secs() + 190);

        assert!(
            message.starts_with(&format!(
                "waiting for \"e2e panel\" in {worktree} (pid {pid}, 3m 1"
            )),
            "{message}"
        );
    }

    #[test]
    fn a_waiter_without_a_readable_holder_gives_the_generic_message() {
        let dir = tempfile::tempdir().unwrap();
        let path = dir.path().join("heavy.lock");
        std::fs::write(&path, "/worktrees/old-plain-line\n").unwrap();
        let mut waiter = open_lock(&path).unwrap();

        let message = waiting_message(Holder::read(&mut waiter), now_secs());

        assert_eq!(message, "waiting for another heavy build");
    }
}
