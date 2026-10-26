//! How a stack is described: each service is a typed handle with its dependencies, the command
//! that runs it and the probe that says it is ready. Internal to xtask, not a reusable library.

use std::cell::RefCell;
use std::collections::{BTreeMap, BTreeSet};
use std::fs::{self, File, OpenOptions};
use std::net::{Ipv4Addr, TcpListener};
use std::path::{Path, PathBuf};
use std::process::Command;
use std::time::Duration;

use anyhow::{Context as _, Result, bail};
use sha2::{Digest, Sha256};

use super::client_configuration::ClientConfiguration;
use super::{StackRecord, process_alive};

/// Identifies a service in a composition. Dependencies name handles, not strings, so a typo does
/// not compile.
#[derive(Clone, Copy, PartialEq, Eq, PartialOrd, Ord, Hash, Debug)]
pub struct ServiceId(pub &'static str);

/// One process in a stack.
pub trait Service {
    const ID: ServiceId;
    /// Services that must be ready before this one starts.
    fn needs(&self) -> &'static [ServiceId] {
        &[]
    }
    /// The process. Building what it runs happens here, under the heavy build lock.
    fn command(&self, ctx: &StackContext) -> Result<Command>;
    fn ready(&self, ctx: &StackContext) -> Probe;
    /// How long the service may take to become ready.
    fn startup(&self) -> Duration {
        Duration::from_secs(60)
    }
    /// Values this service hands to later services and to the command under test.
    fn publish(&self, ctx: &StackContext, out: &mut Published) -> Result<()> {
        let _ = (ctx, out);
        Ok(())
    }
}

/// The object safe face of [`Service`], so a spec can hold different services.
pub trait DynService {
    fn id(&self) -> ServiceId;
    fn needs(&self) -> &'static [ServiceId];
    fn command(&self, ctx: &StackContext) -> Result<Command>;
    fn ready(&self, ctx: &StackContext) -> Probe;
    fn startup(&self) -> Duration;
    fn publish(&self, ctx: &StackContext, out: &mut Published) -> Result<()>;
}

impl<S: Service> DynService for S {
    fn id(&self) -> ServiceId {
        S::ID
    }
    fn needs(&self) -> &'static [ServiceId] {
        Service::needs(self)
    }
    fn command(&self, ctx: &StackContext) -> Result<Command> {
        Service::command(self, ctx)
    }
    fn ready(&self, ctx: &StackContext) -> Probe {
        Service::ready(self, ctx)
    }
    fn startup(&self) -> Duration {
        Service::startup(self)
    }
    fn publish(&self, ctx: &StackContext, out: &mut Published) -> Result<()> {
        Service::publish(self, ctx, out)
    }
}

/// When a started service counts as ready.
pub enum Probe {
    /// `GET path` on a local port answers with a 2xx status.
    Http { port: u16, path: &'static str },
    /// The file exists.
    FileExists(PathBuf),
    /// The process ran once and exited successfully; it is not supervised afterwards.
    ExitSuccess,
}

impl Probe {
    pub fn http(port: u16, path: &'static str) -> Self {
        Self::Http { port, path }
    }
}

/// A composition of services; start order is derived from `needs`.
#[derive(Default)]
pub struct StackSpec(Vec<Box<dyn DynService>>);

impl StackSpec {
    pub fn with<S: Service + 'static>(mut self, service: S) -> Self {
        self.0.push(Box::new(service));
        self
    }

    /// Dependencies before dependents, otherwise in declaration order. A dependency missing from
    /// the spec or a cycle is an error naming the services involved.
    pub fn ordered(&self) -> Result<Vec<&dyn DynService>> {
        let declared: BTreeSet<ServiceId> = self.0.iter().map(|service| service.id()).collect();
        for service in &self.0 {
            for need in service.needs() {
                if !declared.contains(need) {
                    bail!(
                        "service `{}` needs `{}`, which the stack does not contain",
                        service.id().0,
                        need.0
                    );
                }
            }
        }
        let mut ordered: Vec<&dyn DynService> = Vec::new();
        let mut started = BTreeSet::new();
        while ordered.len() < self.0.len() {
            let next = self.0.iter().find(|service| {
                !started.contains(&service.id())
                    && service.needs().iter().all(|need| started.contains(need))
            });
            let Some(next) = next else {
                let waiting: Vec<&str> = self
                    .0
                    .iter()
                    .filter(|service| !started.contains(&service.id()))
                    .map(|service| service.id().0)
                    .collect();
                bail!("the services {} need each other", waiting.join(", "));
            };
            started.insert(next.id());
            ordered.push(next.as_ref());
        }
        Ok(ordered)
    }
}

/// Values services publish for later services, the client files and the command under test.
#[derive(Default)]
pub struct Published {
    pub values: BTreeMap<String, String>,
    pub clients: Option<ClientConfiguration>,
}

impl Published {
    /// Writes the client files and `stack.env`; the supervisor is their only writer.
    pub fn write(&self, dir: &Path) -> Result<()> {
        if let Some(clients) = &self.clients {
            clients.write(dir)?;
        }
        let env: String = self
            .values
            .iter()
            .map(|(key, value)| format!("{key}={value}\n"))
            .collect();
        let path = dir.join("stack.env");
        fs::write(&path, env).with_context(|| format!("cannot write {}", path.display()))
    }
}

/// Where the machine wide stack registry lives: one record per running stack.
pub const REGISTRY: &str = "/tmp/typewriter-stacks";
/// Ports one stack may use. Each name has a fixed offset, so a worktree keeps its addresses
/// across runs.
pub const PORTS: [&str; 7] = [
    "nats",
    "websocket",
    "accounts",
    "identity",
    "http",
    "nats-proxy",
    "faults",
];
const BLOCK_SIZE: u16 = 20;
const FIRST_PORT: u16 = 20000;
const BLOCKS: u16 = 2000;

/// A block of ports leased through the stack registry and released with the stack record.
pub struct PortLease {
    pub base: u16,
    pub record: PathBuf,
}

impl PortLease {
    /// Prefers the block hashed from the worktree path, so ports are stable, and takes the next
    /// free block when another live stack holds it or something else listens on it. The lease is
    /// the stack record, written while the registry is locked, so two stacks never share a block.
    pub fn acquire(worktree: &Path) -> Result<Self> {
        let registry = Path::new(REGISTRY);
        fs::create_dir_all(registry)
            .with_context(|| format!("cannot create {}", registry.display()))?;
        let lock = registry_lock(registry)?;
        let key = worktree_key(worktree);
        let record = registry.join(format!("{key}.json"));
        let taken: BTreeSet<u16> = StackRecord::all()?
            .into_iter()
            .filter(|other| other.path != record && process_alive(other.owner))
            .map(|other| other.base)
            .collect();
        if let Ok(previous) = StackRecord::read(&record)
            && process_alive(previous.owner)
        {
            bail!(
                "a stack for this worktree is already running (supervisor pid {}); \
                 stop it or run `cargo xtask stack gc`",
                previous.owner
            );
        }
        let preferred = u16::from_be_bytes([key.as_bytes()[0], key.as_bytes()[1]]) % BLOCKS;
        let base = (0..BLOCKS)
            .map(|offset| FIRST_PORT + ((preferred + offset) % BLOCKS) * BLOCK_SIZE)
            .find(|base| !taken.contains(base) && block_free(*base))
            .context("no free port block for a stack")?;
        StackRecord {
            path: record.clone(),
            worktree: worktree.to_owned(),
            owner: std::process::id(),
            base,
            groups: Vec::new(),
        }
        .write()?;
        drop(lock);
        Ok(Self { base, record })
    }

    pub fn port(&self, name: &str) -> u16 {
        let offset = PORTS
            .iter()
            .position(|port| *port == name)
            .unwrap_or_else(|| panic!("port `{name}` is not in the stack's port table"));
        self.base + offset as u16
    }
}

fn registry_lock(registry: &Path) -> Result<File> {
    let path = registry.join("registry.lock");
    let file = OpenOptions::new()
        .create(true)
        .truncate(false)
        .write(true)
        .open(&path)
        .with_context(|| format!("cannot open {}", path.display()))?;
    file.lock()
        .with_context(|| format!("cannot lock {}", path.display()))?;
    Ok(file)
}

/// The stable registry key of a worktree.
pub fn worktree_key(worktree: &Path) -> String {
    let digest = Sha256::digest(worktree.as_os_str().as_encoded_bytes());
    digest[..8]
        .iter()
        .map(|byte| format!("{byte:02x}"))
        .collect()
}

fn block_free(base: u16) -> bool {
    (0..PORTS.len() as u16)
        .all(|offset| TcpListener::bind((Ipv4Addr::LOCALHOST, base + offset)).is_ok())
}

/// What services see while the stack starts.
pub struct StackContext<'a> {
    pub ctx: &'a crate::Context,
    pub ports: PortLease,
    built: RefCell<BTreeSet<&'static str>>,
}

impl<'a> StackContext<'a> {
    pub fn new(ctx: &'a crate::Context, ports: PortLease) -> Self {
        Self {
            ctx,
            ports,
            built: RefCell::default(),
        }
    }

    pub fn root(&self) -> &Path {
        &self.ctx.root
    }

    /// The stack's state directory, `.xtask/state/stack`.
    pub fn state(&self) -> PathBuf {
        self.ctx.root.join(".xtask/state/stack")
    }

    pub fn port(&self, name: &str) -> u16 {
        self.ports.port(name)
    }

    /// `--<name> <port>` for each name.
    pub fn port_args(&self, names: &[&str]) -> Vec<String> {
        names
            .iter()
            .flat_map(|name| [format!("--{name}"), self.port(name).to_string()])
            .collect()
    }

    pub fn url(&self, scheme: &str, port: &str) -> String {
        format!("{scheme}://127.0.0.1:{}", self.port(port))
    }

    /// Runs `build` once per stack start, under the heavy build lock.
    pub fn build_once(&self, what: &'static str, build: impl FnOnce() -> Result<()>) -> Result<()> {
        if self.built.borrow().contains(what) {
            return Ok(());
        }
        let _lock = crate::lock::HeavyLock::acquire(&format!("stack: building {what}"))?;
        build()?;
        self.built.borrow_mut().insert(what);
        Ok(())
    }
}
