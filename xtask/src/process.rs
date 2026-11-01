//! Child processes that never outlive the harness.
//!
//! Every long running child gets its own process group, so stopping it also stops the compilers,
//! browsers and daemons it started. Those groups never see the terminal's Ctrl-C; instead
//! [`install_interrupt_handler`] turns SIGINT, SIGTERM and SIGHUP into one flag that every wait
//! loop polls, and the waiting code stops its groups with SIGTERM, a grace period and SIGKILL.

use std::collections::VecDeque;
use std::fs::File;
use std::io::{BufRead as _, BufReader};
use std::os::unix::process::CommandExt as _;
use std::path::Path;
use std::process::{Child, Command, ExitStatus};
use std::sync::atomic::{AtomicBool, Ordering};
use std::thread;
use std::time::{Duration, Instant};

use anyhow::{Context as _, Result, bail};

/// How long a stopped group gets between SIGTERM and SIGKILL.
pub const STOP_GRACE: Duration = Duration::from_secs(5);
pub const POLL: Duration = Duration::from_millis(100);

static INTERRUPTED: AtomicBool = AtomicBool::new(false);

extern "C" fn on_interrupt(_: libc::c_int) {
    INTERRUPTED.store(true, Ordering::SeqCst);
}

/// Turns SIGINT, SIGTERM and SIGHUP into the flag [`interrupted`] reads, so an interrupted
/// command still stops the groups it started instead of dying and orphaning them.
pub fn install_interrupt_handler() {
    for signal in [libc::SIGINT, libc::SIGTERM, libc::SIGHUP] {
        // SAFETY: the handler only stores to an atomic, which is async signal safe.
        unsafe { libc::signal(signal, on_interrupt as *const () as libc::sighandler_t) };
    }
}

/// Whether the harness was asked to stop.
pub fn interrupted() -> bool {
    INTERRUPTED.load(Ordering::SeqCst)
}

pub fn kill_group(group: u32, signal: libc::c_int) {
    if let Ok(group) = libc::pid_t::try_from(group) {
        // SAFETY: sending a signal has no memory effects. Every group the harness signals was
        // created by it for one of its children.
        unsafe { libc::killpg(group, signal) };
    }
}

fn group_alive(group: u32) -> bool {
    let Ok(group) = libc::pid_t::try_from(group) else {
        return false;
    };
    // SAFETY: signal 0 only checks that the group has members; it has no memory effects.
    unsafe { libc::killpg(group, 0) == 0 }
}

/// Stops the process group `leader` leads, whether or not the leader already exited: SIGTERM,
/// up to [`STOP_GRACE`] for the group to empty, then SIGKILL and up to [`STOP_GRACE`] more for
/// the killed members to be gone. Reaps the leader. Returns once the group is empty unless a
/// member outlasts both deadlines, for example one stuck in uninterruptible sleep.
pub fn stop(leader: &mut Child) {
    let group = leader.id();
    kill_group(group, libc::SIGTERM);
    if !wait_until_empty(leader, group) {
        // SIGKILL lands asynchronously, and a killed orphan counts as a member until its new
        // parent reaps it, so the group can outlive the signal by a moment.
        kill_group(group, libc::SIGKILL);
        wait_until_empty(leader, group);
    }
    let _ = leader.wait();
}

/// Waits up to [`STOP_GRACE`] for the group to have no members left.
fn wait_until_empty(leader: &mut Child, group: u32) -> bool {
    let deadline = Instant::now() + STOP_GRACE;
    loop {
        // Reaping the leader keeps an exited leader from counting as a member.
        let _ = leader.try_wait();
        if !group_alive(group) {
            return true;
        }
        if Instant::now() >= deadline {
            return false;
        }
        thread::sleep(POLL);
    }
}

/// A child leading its own process group. Dropping it stops the whole group.
pub struct Group(Child);

impl Group {
    pub fn spawn(command: &mut Command) -> Result<Self> {
        let child = command
            .process_group(0)
            .spawn()
            .with_context(|| format!("cannot start {}", crate::display(command)))?;
        Ok(Self(child))
    }

    pub fn id(&self) -> u32 {
        self.0.id()
    }

    pub fn child(&mut self) -> &mut Child {
        &mut self.0
    }

    /// Waits for the leader to exit. Fails when the harness is interrupted or `deadline` passes
    /// first; the group is stopped on drop either way.
    pub fn wait(&mut self, deadline: Option<Instant>) -> Result<ExitStatus> {
        loop {
            if let Some(status) = self.0.try_wait()? {
                return Ok(status);
            }
            if interrupted() {
                bail!("interrupted");
            }
            if deadline.is_some_and(|deadline| Instant::now() > deadline) {
                bail!("ran out of its time budget");
            }
            thread::sleep(POLL);
        }
    }
}

impl Drop for Group {
    fn drop(&mut self) {
        stop(&mut self.0);
    }
}

/// Starts the processes of a run. A stack registers every group it starts, so `stack gc` can
/// stop them after the supervisor itself is killed outright.
pub trait Supervisor {
    /// Runs `command` to completion in its own group and stops whatever it left running.
    fn run(&mut self, command: &mut Command) -> Result<ExitStatus>;
    /// Starts `command` in its own group, for as long as the returned [`Group`] lives.
    fn spawn(&mut self, command: &mut Command) -> Result<Group>;
}

/// Runs processes with nothing to register them in, stopping them when interrupted.
pub struct Unsupervised;

impl Unsupervised {
    pub fn with_interrupts() -> Self {
        install_interrupt_handler();
        Self
    }
}

impl Supervisor for Unsupervised {
    fn run(&mut self, command: &mut Command) -> Result<ExitStatus> {
        Group::spawn(command)?.wait(None)
    }

    fn spawn(&mut self, command: &mut Command) -> Result<Group> {
        Group::spawn(command)
    }
}

/// The last `count` lines of a process log, or none when it cannot be read.
pub fn log_tail(log: &Path, count: usize) -> Vec<String> {
    let mut lines = VecDeque::with_capacity(count);
    let Ok(file) = File::open(log) else {
        return Vec::new();
    };
    for line in BufReader::new(file).lines().map_while(Result::ok) {
        if lines.len() == count {
            lines.pop_front();
        }
        lines.push_back(line);
    }
    lines.into()
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn dropping_a_group_stops_every_process_in_it() {
        let group = Group::spawn(Command::new("sh").args(["-c", "sleep 60 & sleep 60"])).unwrap();
        let id = group.id();
        assert!(group_alive(id));
        drop(group);
        assert!(!group_alive(id));
    }

    #[test]
    fn a_group_that_ignores_sigterm_is_killed() {
        let dir = tempfile::tempdir().unwrap();
        let ready = dir.path().join("ready");
        let group = Group::spawn(Command::new("sh").args([
            "-c".as_ref(),
            "trap '' TERM; sleep 60 & touch \"$1\"; wait".as_ref(),
            "sh".as_ref(),
            ready.as_os_str(),
        ]))
        .unwrap();
        let id = group.id();
        // The stop must find SIGTERM already ignored, or it never reaches SIGKILL.
        let deadline = Instant::now() + Duration::from_secs(30);
        while !ready.exists() {
            assert!(Instant::now() < deadline, "the shell never ignored SIGTERM");
            thread::sleep(Duration::from_millis(10));
        }
        drop(group);
        assert!(!group_alive(id));
    }

    #[test]
    fn a_wait_past_its_deadline_fails_and_leaves_the_group_to_stop() {
        let mut group = Group::spawn(Command::new("sleep").arg("60")).unwrap();
        let error = group
            .wait(Some(Instant::now() + Duration::from_millis(200)))
            .unwrap_err();
        assert_eq!(error.to_string(), "ran out of its time budget");
    }

    #[test]
    fn a_log_tail_keeps_the_last_lines() {
        let dir = tempfile::tempdir().unwrap();
        let log = dir.path().join("step.log");
        std::fs::write(&log, "1\n2\n3\n4\n").unwrap();
        assert_eq!(log_tail(&log, 2), ["3", "4"]);
        assert!(log_tail(&dir.path().join("missing.log"), 2).is_empty());
    }
}
