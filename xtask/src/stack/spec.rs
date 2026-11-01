//! How a stack is described: each service is a typed handle with its dependencies, the command
//! that runs it and the probe that says it is ready. Internal to xtask, not a reusable library.

use std::cell::{OnceCell, RefCell};
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

/// Something later services rely on without naming who supplies it, such as a backend clients
/// can reach. A spec holds exactly one provider of each role its services need.
#[derive(Clone, Copy, PartialEq, Eq, PartialOrd, Ord, Hash, Debug)]
pub struct Role(pub &'static str);

/// Serves the backend's routes and publishes the [`ClientConfiguration`] clients reach it with:
/// the worktree's backend routes or the CI cluster's backend.
pub const BACKEND: Role = Role("backend");

/// One process in a stack.
pub trait Service {
    const ID: ServiceId;
    /// Services that must be ready before this one starts.
    fn needs(&self) -> &'static [ServiceId] {
        &[]
    }
    /// Roles this service fills once it is ready and has published.
    fn provides(&self) -> &'static [Role] {
        &[]
    }
    /// Roles whose provider must be ready, and published, before this one starts.
    fn needs_roles(&self) -> &'static [Role] {
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
    fn provides(&self) -> &'static [Role];
    fn needs_roles(&self) -> &'static [Role];
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
    fn provides(&self) -> &'static [Role] {
        Service::provides(self)
    }
    fn needs_roles(&self) -> &'static [Role] {
        Service::needs_roles(self)
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

    /// Dependencies and role providers before their dependents, otherwise in declaration order.
    /// A missing dependency, a role with no provider or two, or a cycle is an error naming the
    /// services involved.
    pub fn ordered(&self) -> Result<Vec<&dyn DynService>> {
        let needs = self.resolved_needs()?;
        let mut ordered: Vec<&dyn DynService> = Vec::new();
        let mut started = BTreeSet::new();
        while ordered.len() < self.0.len() {
            let next = self.0.iter().zip(&needs).find(|(service, needs)| {
                !started.contains(&service.id()) && needs.iter().all(|need| started.contains(need))
            });
            let Some((next, _)) = next else {
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

    /// Each service's needs with its roles replaced by their one provider, in spec order.
    fn resolved_needs(&self) -> Result<Vec<Vec<ServiceId>>> {
        let mut providers: BTreeMap<Role, ServiceId> = BTreeMap::new();
        for service in &self.0 {
            for role in service.provides() {
                if let Some(first) = providers.insert(*role, service.id()) {
                    bail!(
                        "`{}` and `{}` both provide {}",
                        first.0,
                        service.id().0,
                        role.0
                    );
                }
            }
        }
        let declared: BTreeSet<ServiceId> = self.0.iter().map(|service| service.id()).collect();
        self.0
            .iter()
            .map(|service| {
                let mut needs = Vec::new();
                for need in service.needs() {
                    if !declared.contains(need) {
                        bail!(
                            "service `{}` needs `{}`, which the stack does not contain",
                            service.id().0,
                            need.0
                        );
                    }
                    needs.push(*need);
                }
                for role in service.needs_roles() {
                    let provider = providers.get(role).with_context(|| {
                        format!(
                            "service `{}` needs a {}, which no service provides",
                            service.id().0,
                            role.0
                        )
                    })?;
                    needs.push(*provider);
                }
                Ok(needs)
            })
            .collect()
    }
}

/// Values services publish for later services, the client files and the command under test.
#[derive(Default)]
pub struct Published {
    pub values: BTreeMap<String, String>,
    pub clients: Option<ClientConfiguration>,
}

impl Published {
    /// How clients reach the backend; only a [`BACKEND`] provider publishes it.
    pub fn clients(&mut self, clients: ClientConfiguration) {
        self.clients = Some(clients);
    }
}

/// The machine wide stack registry: one record per running stack. Tests use a temp dir.
pub struct Registry(PathBuf);

impl Registry {
    pub fn machine() -> Self {
        Self(PathBuf::from("/tmp/typewriter-stacks"))
    }

    #[cfg(test)]
    pub fn at(dir: &Path) -> Self {
        Self(dir.to_owned())
    }

    pub fn dir(&self) -> &Path {
        &self.0
    }
}

/// Ports one stack may use. Each name has a fixed offset, so a worktree keeps its addresses
/// across runs.
pub const PORTS: [&str; 14] = [
    "nats",
    "websocket",
    "accounts",
    "identity",
    "http",
    "nats-proxy",
    "realm-nats-proxy",
    "faults",
    "toxiproxy",
    "nats-web-proxy",
    "backend-http",
    "collector-grpc",
    "collector-http",
    "collector-health",
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
    pub fn acquire(registry: &Registry, worktree: &Path) -> Result<Self> {
        let dir = registry.dir();
        fs::create_dir_all(dir).with_context(|| format!("cannot create {}", dir.display()))?;
        let lock = registry_lock(dir)?;
        let key = worktree_key(worktree);
        let record = dir.join(format!("{key}.json"));
        let taken: BTreeSet<u16> = StackRecord::all(registry)?
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
    /// What the started services published, in start order.
    values: RefCell<BTreeMap<String, String>>,
    clients: OnceCell<ClientConfiguration>,
}

impl<'a> StackContext<'a> {
    pub fn new(ctx: &'a crate::Context, ports: PortLease) -> Self {
        Self {
            ctx,
            ports,
            built: RefCell::default(),
            values: RefCell::default(),
            clients: OnceCell::new(),
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

    /// How clients reach the backend, as the [`BACKEND`] provider published it.
    pub fn clients(&self) -> Result<&ClientConfiguration> {
        self.clients
            .get()
            .context("no backend has published its clients yet; declare needs_roles BACKEND")
    }

    /// Takes what `service`, now ready, published: its values join `stack.env`, its clients
    /// become [`Self::clients`] and their files; then rewrites the client files and `stack.env` in
    /// the state directory, which later services and the command under test read. The supervisor
    /// is their only writer. A [`BACKEND`] provider must publish clients and no other service may;
    /// either mistake is refused before anything is written.
    pub(super) fn absorb(&self, service: &dyn DynService, published: Published) -> Result<()> {
        let id = service.id().0;
        let clients = match (service.provides().contains(&BACKEND), published.clients) {
            (true, None) => bail!(
                "`{id}` provides the {} but published no clients; its publish must call \
                 Published::clients",
                BACKEND.0
            ),
            (false, Some(_)) => bail!(
                "`{id}` published clients but does not provide the {}; only its provider does",
                BACKEND.0
            ),
            (_, clients) => clients,
        };
        let state = self.state();
        let mut values = self.values.borrow_mut();
        values.extend(published.values);
        if let Some(clients) = clients {
            clients.write(&state)?;
            values.extend(clients.published(&state));
            // `StackSpec::ordered` admits one provider of each role, so this is the only one.
            assert!(
                self.clients.set(clients).is_ok(),
                "a second backend provider published clients"
            );
        }
        let env: String = values
            .iter()
            .map(|(key, value)| format!("{key}={value}\n"))
            .collect();
        let path = state.join("stack.env");
        fs::write(&path, env).with_context(|| format!("cannot write {}", path.display()))
    }

    /// Everything published, for the command under test's environment.
    pub(super) fn env(&self) -> BTreeMap<String, String> {
        self.values.borrow().clone()
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

#[cfg(test)]
mod tests {
    use super::*;
    use crate::stack::client_configuration::ClientConfiguration;
    use crate::test_support::{TempRoot, fake_service, ids, refusal, stack_context};

    mod roles {
        use super::*;
        fake_service!(Routes, ; provides BACKEND);
        fake_service!(Cluster, ; provides BACKEND);
        fake_service!(Owner, ; needs_roles BACKEND);
    }

    #[test]
    fn a_service_that_needs_a_role_starts_after_its_provider() {
        let spec = StackSpec::default().with(roles::Owner).with(roles::Routes);
        assert_eq!(ids(&spec.ordered().unwrap()), ["Routes", "Owner"]);
    }

    #[test]
    fn a_needed_role_no_service_provides_is_refused_before_anything_starts() {
        let spec = StackSpec::default().with(roles::Owner);
        assert_eq!(
            refusal(spec.ordered()),
            "service `Owner` needs a backend, which no service provides"
        );
    }

    #[test]
    fn two_providers_of_one_role_are_both_named() {
        let spec = StackSpec::default()
            .with(roles::Routes)
            .with(roles::Cluster)
            .with(roles::Owner);
        assert_eq!(
            refusal(spec.ordered()),
            "`Routes` and `Cluster` both provide backend"
        );
    }

    #[test]
    fn a_backend_provider_that_publishes_no_clients_is_refused_before_anything_is_written() {
        let root = TempRoot::new();
        let ctx = stack_context(&root);
        assert_eq!(
            refusal(ctx.absorb(&roles::Routes, Published::default())),
            "`Routes` provides the backend but published no clients; its publish must call \
             Published::clients"
        );
        assert!(!ctx.state().join("stack.env").exists());
    }

    #[test]
    fn clients_from_a_service_that_does_not_provide_the_backend_are_refused() {
        let root = TempRoot::new();
        let ctx = stack_context(&root);
        let mut published = Published::default();
        published.clients(ClientConfiguration::worktree(&ctx));
        assert_eq!(
            refusal(ctx.absorb(&roles::Owner, published)),
            "`Owner` published clients but does not provide the backend; only its provider does"
        );
        assert!(ctx.clients().is_err());
        assert!(!ctx.state().join("panel.json").exists());
    }

    mod chain {
        use super::*;
        fake_service!(Broker,);
        fake_service!(Accounts, Broker);
        fake_service!(Realm, Accounts, Broker);
    }

    mod cycle {
        use super::*;
        fake_service!(First, Second);
        fake_service!(Second, First);
        fake_service!(Free,);
    }

    mod missing {
        use super::*;
        fake_service!(Broker,);
        fake_service!(Accounts, Broker);
    }

    #[test]
    fn dependencies_start_before_their_dependents() {
        let spec = StackSpec::default()
            .with(chain::Realm)
            .with(chain::Accounts)
            .with(chain::Broker);
        assert_eq!(
            spec.ordered()
                .unwrap()
                .iter()
                .map(|service| service.id().0)
                .collect::<Vec<_>>(),
            ["Broker", "Accounts", "Realm"]
        );
    }

    #[test]
    fn a_missing_dependency_is_named() {
        let spec = StackSpec::default().with(missing::Accounts);
        let error = refusal(spec.ordered());
        assert_eq!(
            error,
            "service `Accounts` needs `Broker`, which the stack does not contain"
        );
    }

    #[test]
    fn services_that_need_each_other_are_named() {
        let spec = StackSpec::default()
            .with(cycle::First)
            .with(cycle::Free)
            .with(cycle::Second);
        let error = refusal(spec.ordered());
        assert_eq!(error, "the services First, Second need each other");
    }

    #[test]
    fn live_stacks_of_different_worktrees_never_share_a_port_block() {
        let registry = tempfile::tempdir().unwrap();
        let registry = Registry::at(registry.path());
        // Enough worktrees that some prefer the same block (fixed paths, so the same ones every
        // run).
        let bases: Vec<u16> = (0..100)
            .map(|index| {
                let worktree = PathBuf::from(format!("/worktrees/{index}"));
                PortLease::acquire(&registry, &worktree).unwrap().base
            })
            .collect();
        let distinct: BTreeSet<u16> = bases.iter().copied().collect();
        assert_eq!(distinct.len(), bases.len());
    }

    #[test]
    fn a_worktree_keeps_its_ports_across_runs() {
        let dir = tempfile::tempdir().unwrap();
        let registry = Registry::at(dir.path());
        let worktree = Path::new("/worktrees/stable");
        let first = PortLease::acquire(&registry, worktree).unwrap();
        // The run ended: its supervisor forgot the record.
        fs::remove_file(&first.record).unwrap();
        let second = PortLease::acquire(&registry, worktree).unwrap();
        assert_eq!(first.base, second.base);
    }

    #[test]
    fn a_second_stack_of_the_same_worktree_is_refused() {
        let dir = tempfile::tempdir().unwrap();
        let registry = Registry::at(dir.path());
        let worktree = Path::new("/worktrees/busy");
        let _running = PortLease::acquire(&registry, worktree).unwrap();
        let error = PortLease::acquire(&registry, worktree)
            .err()
            .unwrap()
            .to_string();
        assert!(error.contains("a stack for this worktree is already running"));
    }
}
