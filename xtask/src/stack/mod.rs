//! The worktree's Typewriter stack, up for exactly as long as one command needs it.
//!
//! Each service runs in its own process group with its output in `.xtask/state/stack/logs`.
//! Dropping [`Stack`] sends SIGTERM to every group and SIGKILL after five seconds, so a failing,
//! timed out or interrupted command never leaves a stack behind. A group whose leader exits is
//! stopped the same way, so its descendants do not outlive it. A supervisor killed outright
//! leaves its record in [`spec::REGISTRY`], which `cargo xtask stack gc` reads to kill what it
//! left. devenv's process dependencies are not used: devenv 2.4.0 still has the bugs where an on
//! demand process waits forever and disabled processes start their prerequisites.

pub mod client_configuration;
pub mod spec;
pub mod typewriter;

use std::collections::BTreeMap;
use std::fs::{self, File};
use std::io::{Read as _, Write as _};
use std::net::{Ipv4Addr, TcpStream};
use std::os::unix::process::CommandExt as _;
use std::path::{Path, PathBuf};
use std::process::{Child, Command, ExitStatus, Stdio};
use std::time::{Duration, Instant};

use anyhow::{Context as _, Result, bail};
use serde::{Deserialize, Serialize};

use self::spec::{DynService, PortLease, Probe, Published, REGISTRY, StackContext, StackSpec};
use crate::Context;
use crate::lock::E2eSlot;
use crate::process::{self, Group, POLL, STOP_GRACE, Supervisor, interrupted, kill_group};

/// Per run state a new run keeps; everything else in the state directory is cleared.
pub enum Keep {
    /// The broker's operator and account keys, so credentials written by earlier runs and
    /// cached by tools stay valid.
    BrokerKeys,
}

impl Keep {
    fn entry(&self) -> &'static str {
        match self {
            Self::BrokerKeys => "broker-keys",
        }
    }
}

/// Runs `inside` with `spec` up for this worktree. `cargo xtask stack run` and the end to end
/// suites call this.
pub fn run<T>(
    ctx: &Context,
    spec: &StackSpec,
    timeout: Duration,
    inside: impl FnOnce(&mut Stack) -> Result<T>,
) -> Result<T> {
    let order = spec.ordered()?;
    process::install_interrupt_handler();
    let _slot = E2eSlot::acquire(&ctx.root)?;
    let stack_ctx = StackContext::new(ctx, PortLease::acquire(&ctx.root)?);
    reset_state(&stack_ctx.state(), &[Keep::BrokerKeys])?;
    let mut stack = Stack::register(&stack_ctx)?;
    let mut published = Published::default();
    for service in order {
        stack.start(service, &stack_ctx)?;
        service.publish(&stack_ctx, &mut published)?;
        // Later services read the client files, like the Realm host its `realm.properties`.
        published.write(&stack_ctx.state())?;
    }
    stack.env = published.values;
    stack.deadline = Some(Instant::now() + timeout);
    inside(&mut stack)
}

/// Clears `state` except the entries `keep` names.
fn reset_state(state: &Path, keep: &[Keep]) -> Result<()> {
    fs::create_dir_all(state).with_context(|| format!("cannot create {}", state.display()))?;
    for entry in fs::read_dir(state)? {
        let entry = entry?;
        let path = entry.path();
        let name = entry.file_name();
        if keep.iter().any(|kept| name == kept.entry()) {
            continue;
        }
        if path.is_dir() {
            fs::remove_dir_all(&path)
        } else {
            fs::remove_file(&path)
        }
        .with_context(|| format!("cannot clear {}", path.display()))?;
    }
    fs::create_dir_all(state.join("logs"))?;
    Ok(())
}

/// The running processes of one stack.
pub struct Stack {
    record: StackRecord,
    services: Vec<(&'static str, Child)>,
    logs: PathBuf,
    env: BTreeMap<String, String>,
    deadline: Option<Instant>,
}

impl Stack {
    fn register(ctx: &StackContext) -> Result<Self> {
        let record = StackRecord::read(&ctx.ports.record)?;
        Ok(Self {
            record,
            services: Vec::new(),
            logs: ctx.state().join("logs"),
            env: BTreeMap::new(),
            deadline: None,
        })
    }

    /// Starts `service` and waits until its probe passes.
    fn start(&mut self, service: &dyn DynService, ctx: &StackContext) -> Result<()> {
        let id = service.id().0;
        let mut command = service.command(ctx)?;
        let log_path = self.logs.join(format!("{id}.log"));
        let log = File::create(&log_path)
            .with_context(|| format!("cannot create {}", log_path.display()))?;
        eprintln!("stack: starting {id}");
        let mut child = command
            .process_group(0)
            // A held stdin keeps interactive hosts, like the loader's console, running.
            .stdin(Stdio::piped())
            .stdout(log.try_clone()?)
            .stderr(log)
            .spawn()
            .with_context(|| format!("cannot start {id}: {}", crate::display(&command)))?;
        self.record.groups.push(child.id());
        self.record.write()?;
        let deadline = Instant::now() + service.startup();
        let probe = service.ready(ctx);
        loop {
            if interrupted() {
                self.services.push((id, child));
                bail!("interrupted while {id} started");
            }
            if let Some(status) = child.try_wait()? {
                // A one shot service is done, but what it started in the background is not.
                process::stop(&mut child);
                self.record.groups.retain(|group| *group != child.id());
                self.record.write()?;
                if status.success() && matches!(probe, Probe::ExitSuccess) {
                    eprintln!("stack: {id} done");
                    return Ok(());
                }
                bail!(
                    "{id} exited with {status} before it was ready{}",
                    tail(&log_path)
                );
            }
            if probe_passes(&probe) {
                eprintln!("stack: {id} ready");
                self.services.push((id, child));
                return Ok(());
            }
            if Instant::now() > deadline {
                self.services.push((id, child));
                bail!(
                    "{id} was not ready within {}s{}",
                    service.startup().as_secs(),
                    tail(&log_path)
                );
            }
            std::thread::sleep(POLL);
        }
    }

    /// Runs `command` against the stack, with the published values in its environment. It is
    /// stopped when the run's time budget ends, when the run is interrupted or when a stack
    /// service dies; whatever it left running is stopped when it exits.
    pub fn run_command(&mut self, command: &mut Command) -> Result<ExitStatus> {
        let mut group = Group::spawn(command.envs(&self.env))?;
        self.record.groups.push(group.id());
        self.record.write()?;
        let outcome = self.supervise(group.child());
        let id = group.id();
        drop(group);
        self.record.groups.retain(|group| *group != id);
        self.record.write()?;
        outcome
    }

    fn supervise(&mut self, child: &mut Child) -> Result<ExitStatus> {
        loop {
            if let Some(status) = child.try_wait()? {
                return Ok(status);
            }
            if interrupted() {
                bail!("interrupted");
            }
            if self
                .deadline
                .is_some_and(|deadline| Instant::now() > deadline)
            {
                bail!("the command ran out of its time budget");
            }
            for (id, service) in &mut self.services {
                if let Some(status) = service.try_wait()? {
                    let log = self.logs.join(format!("{id}.log"));
                    bail!("stack service {id} exited with {status}{}", tail(&log));
                }
            }
            std::thread::sleep(POLL);
        }
    }
}

/// Helpers of the command, like a recorder or a browser driver, are registered too, so `stack gc`
/// stops them after a supervisor killed outright. Their groups stay listed until the stack stops.
impl Supervisor for Stack {
    fn run(&mut self, command: &mut Command) -> Result<ExitStatus> {
        self.run_command(command)
    }

    fn spawn(&mut self, command: &mut Command) -> Result<Group> {
        let group = Group::spawn(command.envs(&self.env))?;
        self.record.groups.push(group.id());
        self.record.write()?;
        Ok(group)
    }
}

impl Drop for Stack {
    fn drop(&mut self) {
        for group in &self.record.groups {
            kill_group(*group, libc::SIGTERM);
        }
        let deadline = Instant::now() + STOP_GRACE;
        while Instant::now() < deadline
            && self
                .services
                .iter_mut()
                .any(|(_, child)| matches!(child.try_wait(), Ok(None)))
        {
            std::thread::sleep(POLL);
        }
        for group in &self.record.groups {
            kill_group(*group, libc::SIGKILL);
        }
        for (_, child) in &mut self.services {
            let _ = child.wait();
        }
        self.record.forget();
        eprintln!("stack: stopped");
    }
}

/// A running stack as the registry knows it: who supervises it and which process groups it
/// started. The record is also the stack's port lease.
#[derive(Serialize, Deserialize)]
pub struct StackRecord {
    #[serde(skip)]
    pub path: PathBuf,
    pub worktree: PathBuf,
    pub owner: u32,
    pub base: u16,
    pub groups: Vec<u32>,
}

impl StackRecord {
    pub fn all() -> Result<Vec<Self>> {
        let Ok(entries) = fs::read_dir(REGISTRY) else {
            return Ok(Vec::new());
        };
        let mut records = Vec::new();
        for entry in entries {
            let path = entry?.path();
            if path
                .extension()
                .is_some_and(|extension| extension == "json")
            {
                records.push(Self::read(&path)?);
            }
        }
        Ok(records)
    }

    pub fn read(path: &Path) -> Result<Self> {
        let text =
            fs::read_to_string(path).with_context(|| format!("cannot read {}", path.display()))?;
        let mut record: Self = serde_json::from_str(&text)
            .with_context(|| format!("{} is not a stack record", path.display()))?;
        record.path = path.to_owned();
        Ok(record)
    }

    pub fn write(&self) -> Result<()> {
        let temporary = self.path.with_extension("tmp");
        fs::write(&temporary, serde_json::to_string_pretty(self)?)
            .with_context(|| format!("cannot write {}", temporary.display()))?;
        fs::rename(&temporary, &self.path)
            .with_context(|| format!("cannot write {}", self.path.display()))
    }

    fn forget(&self) {
        let _ = fs::remove_file(&self.path);
    }
}

/// Kills stacks whose supervisor is gone (an agent killed with SIGKILL) and releases their port
/// blocks.
pub fn gc() -> Result<Vec<StackRecord>> {
    let mut removed = Vec::new();
    for record in StackRecord::all()? {
        if !process_alive(record.owner) {
            for group in &record.groups {
                kill_group(*group, libc::SIGKILL);
            }
            record.forget();
            removed.push(record);
        }
    }
    Ok(removed)
}

pub fn process_alive(pid: u32) -> bool {
    let Ok(pid) = libc::pid_t::try_from(pid) else {
        return false;
    };
    // SAFETY: signal 0 only checks that the process exists; it has no memory effects.
    unsafe { libc::kill(pid, 0) == 0 }
}

fn probe_passes(probe: &Probe) -> bool {
    match probe {
        Probe::Http { port, path } => http_ok(*port, path),
        Probe::FileExists(path) => path.exists(),
        Probe::ExitSuccess => false,
    }
}

/// Whether `GET path` on a local port answers with a 2xx status.
fn http_ok(port: u16, path: &str) -> bool {
    let attempt = || -> std::io::Result<bool> {
        let mut stream = TcpStream::connect((Ipv4Addr::LOCALHOST, port))?;
        stream.set_read_timeout(Some(Duration::from_secs(2)))?;
        write!(stream, "GET {path} HTTP/1.0\r\nHost: 127.0.0.1\r\n\r\n")?;
        let mut head = [0; 12];
        stream.read_exact(&mut head)?;
        Ok(head.starts_with(b"HTTP/1.") && head[9] == b'2')
    };
    attempt().unwrap_or(false)
}

/// The last lines of a service log, for an error message.
fn tail(log: &Path) -> String {
    format!(
        "\n--- {} (last lines) ---\n{}",
        log.display(),
        process::log_tail(log, 30).join("\n")
    )
}

/// The `stack` subcommands.
#[derive(clap::Subcommand)]
pub enum StackCommand {
    /// Runs a command with this worktree's stack up and stops the stack afterwards.
    Run {
        /// Which services to start.
        #[arg(long, value_enum, default_value_t = Spec::Panel)]
        spec: Spec,
        /// The command's time budget in seconds.
        #[arg(long, default_value_t = 1800)]
        timeout: u64,
        /// The command and its arguments.
        #[arg(last = true, required = true)]
        command: Vec<String>,
    },
    /// Kills the processes of stacks whose supervisor was killed and releases their ports.
    Gc,
}

/// The compositions `stack run` can start.
#[derive(Clone, Copy, clap::ValueEnum)]
pub enum Spec {
    /// The broker, the identity stand in and every backend component.
    Backend,
    /// The backend plus the provisioned organization and its bound Realm host.
    Panel,
}

impl Spec {
    fn services(self) -> StackSpec {
        match self {
            Self::Backend => typewriter::backend(),
            Self::Panel => typewriter::panel(),
        }
    }
}

pub fn command(ctx: &Context, command: StackCommand) -> Result<()> {
    match command {
        StackCommand::Run {
            spec,
            timeout,
            command,
        } => {
            let status = run(
                ctx,
                &spec.services(),
                Duration::from_secs(timeout),
                |stack| {
                    let mut process = Command::new(&command[0]);
                    process.args(&command[1..]);
                    stack.run_command(&mut process)
                },
            )?;
            if !status.success() {
                bail!("{} exited with {status}", command.join(" "));
            }
            Ok(())
        }
        StackCommand::Gc => {
            let removed = gc()?;
            if removed.is_empty() {
                println!("no orphaned stacks");
            }
            for record in removed {
                println!(
                    "removed the stack of {} (ports {}, {} process groups)",
                    record.worktree.display(),
                    record.base,
                    record.groups.len()
                );
            }
            Ok(())
        }
    }
}
