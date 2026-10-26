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
/// up to [`STOP_GRACE`] for the group to empty, then SIGKILL. Reaps the leader.
pub fn stop(leader: &mut Child) {
    let group = leader.id();
    kill_group(group, libc::SIGTERM);
    let deadline = Instant::now() + STOP_GRACE;
    while Instant::now() < deadline {
        // Reaping the leader keeps an exited leader from counting as a member.
        let _ = leader.try_wait();
        if !group_alive(group) {
            break;
        }
        thread::sleep(POLL);
    }
    kill_group(group, libc::SIGKILL);
    let _ = leader.wait();
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
