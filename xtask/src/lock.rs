//! Machine wide limits shared by every worktree.

use std::fs::{File, OpenOptions, TryLockError};
use std::io::{Read as _, Seek as _, Write as _};
use std::path::Path;
use std::thread;
use std::time::Duration;

use anyhow::{Context as _, Result, bail};

use crate::process;

const HEAVY_LOCK: &str = "/tmp/typewriter-heavy.lock";
/// How often a waiter tries the lock again; polling instead of blocking lets it see an interrupt.
const LOCK_POLL: Duration = Duration::from_millis(500);

/// Held around compiles (Gradle, Cargo, Flutter tests), so only one heavy build runs on the
/// machine at a time, whichever worktree starts it. Released on drop.
pub struct HeavyLock {
    _file: File,
}

impl HeavyLock {
    /// Takes the lock, waiting for whoever holds it. `holder` says who is waiting, so the
    /// message names the step that queues. Gives up when the harness is interrupted.
    pub fn acquire(holder: &str) -> Result<Self> {
        let file = OpenOptions::new()
            .create(true)
            .truncate(false)
            .write(true)
            .open(HEAVY_LOCK)
            .with_context(|| format!("cannot open {HEAVY_LOCK}"))?;
        let mut announced = false;
        while !try_lock(&file, HEAVY_LOCK)? {
            if !announced {
                eprintln!("{holder}: waiting for another heavy build ({HEAVY_LOCK})");
                announced = true;
            }
            wait_turn()?;
        }
        Ok(Self { _file: file })
    }
}

/// One of a fixed number of machine wide end to end slots, so ten agents cannot start ten stacks
/// at once. There is one slot per 8 GB of memory unless `TYPEWRITER_E2E_SLOTS` says otherwise.
/// Each slot file names the worktree holding it, so a waiting run says who it waits for.
/// Released on drop.
pub struct E2eSlot {
    _file: File,
}

impl E2eSlot {
    /// Takes the first free slot, waiting until one frees up. Gives up when the harness is
    /// interrupted.
    pub fn acquire(worktree: &Path) -> Result<Self> {
        let slots = std::env::var("TYPEWRITER_E2E_SLOTS")
            .ok()
            .and_then(|value| value.parse::<usize>().ok())
            .unwrap_or_else(|| (total_memory_gb() / 8).max(1));
        let mut files = Vec::with_capacity(slots);
        for index in 0..slots {
            let path = format!("/tmp/typewriter-e2e-{index}.lock");
            let file = OpenOptions::new()
                .create(true)
                .truncate(false)
                .read(true)
                .write(true)
                .open(&path)
                .with_context(|| format!("cannot open {path}"))?;
            files.push((path, file));
        }
        let mut announced = false;
        loop {
            for index in 0..files.len() {
                let (path, file) = &files[index];
                if try_lock(file, path)? {
                    let (_, file) = files.swap_remove(index);
                    return Self::claim(file, worktree);
                }
            }
            if !announced {
                for (path, file) in &mut files {
                    let mut holder = String::new();
                    file.rewind()?;
                    file.read_to_string(&mut holder)?;
                    eprintln!("stack: {path} is held by {}", holder.trim());
                }
                eprintln!("stack: waiting for an end to end slot");
                announced = true;
            }
            wait_turn()?;
        }
    }

    fn claim(mut file: File, worktree: &Path) -> Result<Self> {
        file.set_len(0)?;
        file.rewind()?;
        writeln!(file, "{}", worktree.display())?;
        Ok(Self { _file: file })
    }
}

/// Whether `file` is now locked by this process.
fn try_lock(file: &File, path: &str) -> Result<bool> {
    match file.try_lock() {
        Ok(()) => Ok(true),
        Err(TryLockError::WouldBlock) => Ok(false),
        Err(TryLockError::Error(error)) => {
            Err(error).with_context(|| format!("cannot lock {path}"))
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
