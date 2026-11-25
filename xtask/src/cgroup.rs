//! Memory per part through cgroup v2, where the machine delegates a cgroup to the run's user, as
//! CI does with `cargo xtask cgroup delegate` and names in [`DELEGATED`]. A game run makes its
//! tree there: `run-<id>` holds `stack` (a leaf per service), `gradle` (the suite's Gradle, its
//! daemon and test JVMs) and `game`, where the pool makes a leaf per game part and its own. The
//! kernel counts each leaf's memory and records the most it took. While limits are only measured,
//! every cgroup takes the machine's memory as its limit, so nothing is killed for its limit; the
//! run file lists each part's peak beside its planned limit.

use std::ffi::CString;
use std::fs;
use std::io;
use std::os::unix::ffi::OsStrExt;
use std::os::unix::process::CommandExt;
use std::path::{Path, PathBuf};
use std::process::Command;
use std::sync::{Arc, Mutex};

use anyhow::{Context as _, Result, bail};

use crate::results::{self, Part, PartEnd, PartKind};

/// The cgroup the machine delegates to the run's user.
pub const DELEGATED: &str = "TYPEWRITER_CGROUP";

/// The game's cgroup in the run's tree, which the build hands the pool.
pub const GAME: &str = "PLAYTEST_CGROUP";

/// Where `cargo xtask cgroup delegate` makes the delegated cgroup.
const DELEGATE_ROOT: &str = "/sys/fs/cgroup";

/// The controllers every cgroup of the tree enables for its children.
const CONTROLLERS: &str = "+memory +pids";

/// One run's tree under the delegated cgroup.
pub struct Tree {
    run: PathBuf,
    limit: u64,
}

impl Tree {
    /// The tree of the run `id` under the cgroup the machine delegates, each cgroup held to the
    /// machine's memory; `None` where the machine delegates none, as on macOS.
    pub fn delegated(id: &str) -> Result<Option<Self>> {
        let Some(root) = std::env::var_os(DELEGATED).filter(|root| !root.is_empty()) else {
            return Ok(None);
        };
        Self::create(Path::new(&root), id, machine_memory()?).map(Some)
    }

    /// Makes the tree of the run `id` under `root`, every cgroup held to `limit` bytes. A parent
    /// enables the memory controller for its children before they are made, since a child gets its
    /// memory files only then.
    pub fn create(root: &Path, id: &str, limit: u64) -> Result<Self> {
        let run = root.join(format!("run-{id}"));
        make(&run, limit)?;
        write(&run.join("cgroup.subtree_control"), CONTROLLERS)?;
        let tree = Self { run, limit };
        for parent in [tree.stack(), tree.game()] {
            make(&parent, limit)?;
            write(&parent.join("cgroup.subtree_control"), CONTROLLERS)?;
        }
        leaf(&tree.run.join("gradle"), limit)?;
        Ok(tree)
    }

    /// The game's cgroup, where the pool makes the game parts' leaves.
    pub fn game(&self) -> PathBuf {
        self.run.join("game")
    }

    fn stack(&self) -> PathBuf {
        self.run.join("stack")
    }

    /// The leaf of the suite's Gradle.
    pub fn gradle(&self) -> Leaf {
        Leaf(self.run.join("gradle"))
    }

    /// The leaf of the stack service `id`, made on first use.
    pub fn stack_service(&self, id: &str) -> Result<Leaf> {
        let dir = self.stack().join(id);
        leaf(&dir, self.limit)?;
        Ok(Leaf(dir))
    }

    /// Adds Gradle and every stack service to the parts of the run file at `file`, each with the
    /// most memory it took. They have no planned limit yet; their first peaks set one.
    pub fn record(&self, file: &Path) -> Result<()> {
        let mut run = results::read(file)?;
        let mut measured = vec![("gradle".to_owned(), PartKind::Gradle, self.gradle())];
        let mut services = Vec::new();
        for entry in fs::read_dir(self.stack())
            .with_context(|| format!("cannot read {}", self.stack().display()))?
        {
            let entry = entry?;
            if entry.file_type()?.is_dir() {
                let name = entry.file_name().to_string_lossy().into_owned();
                services.push((name, PartKind::StackService, Leaf(entry.path())));
            }
        }
        services.sort_by(|a, b| a.0.cmp(&b.0));
        measured.extend(services);
        for (name, kind, leaf) in measured {
            run.parts.push(Part {
                name,
                kind,
                end: PartEnd::RanToEnd,
                peak_bytes: leaf.peak(),
                ..Part::default()
            });
        }
        results::write(&run, file)
    }

    /// Removes the tree once its processes are gone; a cgroup that still holds any stays.
    pub fn remove(&self) {
        for parent in [self.stack(), self.game()] {
            if let Ok(entries) = fs::read_dir(&parent) {
                for entry in entries.flatten() {
                    let _ = fs::remove_dir(entry.path());
                }
            }
        }
        for dir in [
            self.stack(),
            self.game(),
            self.run.join("gradle"),
            self.run.clone(),
        ] {
            let _ = fs::remove_dir(dir);
        }
    }
}

/// One part's leaf.
pub struct Leaf(PathBuf);

impl Leaf {
    /// Starts `command` inside this leaf: its child writes itself into the leaf before it execs,
    /// so every byte the part takes is counted here.
    pub fn place(&self, command: &mut Command) -> Result<()> {
        let procs = CString::new(self.0.join("cgroup.procs").as_os_str().as_bytes())
            .context("a cgroup path with a NUL byte")?;
        // Only async signal safe calls between fork and exec: open, write and close.
        unsafe {
            command.pre_exec(move || {
                let fd = libc::open(procs.as_ptr(), libc::O_WRONLY);
                if fd < 0 {
                    return Err(io::Error::last_os_error());
                }
                let written = libc::write(fd, b"0".as_ptr().cast(), 1);
                let error = io::Error::last_os_error();
                libc::close(fd);
                if written == 1 { Ok(()) } else { Err(error) }
            });
        }
        Ok(())
    }

    /// The most memory the leaf's processes took, in bytes; `None` when the kernel records none.
    pub fn peak(&self) -> Option<i64> {
        fs::read_to_string(self.0.join("memory.peak"))
            .ok()?
            .trim()
            .parse()
            .ok()
    }
}

/// The tree of the current game run, which the stack places its services in while it starts.
static INSTALLED: Mutex<Option<Arc<Tree>>> = Mutex::new(None);

/// Makes `tree` the current run's until the returned guard drops.
pub fn install(tree: Option<Tree>) -> Installed {
    let tree = tree.map(Arc::new);
    *INSTALLED
        .lock()
        .unwrap_or_else(|poisoned| poisoned.into_inner()) = tree.clone();
    Installed(tree)
}

/// The current game run's tree, if it has one.
pub fn installed() -> Option<Arc<Tree>> {
    INSTALLED
        .lock()
        .unwrap_or_else(|poisoned| poisoned.into_inner())
        .clone()
}

/// The current run's tree, installed until it drops.
pub struct Installed(Option<Arc<Tree>>);

impl Installed {
    pub fn tree(&self) -> Option<&Tree> {
        self.0.as_deref()
    }
}

impl Drop for Installed {
    fn drop(&mut self) {
        *INSTALLED
            .lock()
            .unwrap_or_else(|poisoned| poisoned.into_inner()) = None;
    }
}

/// Delegates a cgroup to this user, the way CI's game job needs it: the job's container mounts
/// cgroup2 read only, so it is remounted read write; every process of the job moves into a leaf,
/// since a cgroup holding processes cannot enable controllers for its children; the delegated
/// cgroup is handed to this user, and `TYPEWRITER_CGROUP` names it for the job's later steps.
pub fn delegate() -> Result<()> {
    let root = Path::new(DELEGATE_ROOT);
    let delegated = root.join("typewriter");
    let job = delegated.join("job");
    sudo(&["mount", "-o", "remount,rw", DELEGATE_ROOT])?;
    sudo(&["mkdir", "-p", &job.to_string_lossy()])?;
    let procs = fs::read_to_string(root.join("cgroup.procs"))
        .with_context(|| format!("cannot read {}/cgroup.procs", root.display()))?;
    for pid in procs.split_whitespace() {
        // A process that is gone, or one the kernel keeps in place, stays where it is.
        let _ = sudo_write(&job.join("cgroup.procs"), pid);
    }
    sudo_write(&root.join("cgroup.subtree_control"), CONTROLLERS)?;
    sudo_write(&delegated.join("cgroup.subtree_control"), CONTROLLERS)?;
    let owner = format!("{}:{}", unsafe { libc::getuid() }, unsafe {
        libc::getgid()
    });
    sudo(&["chown", "-R", &owner, &delegated.to_string_lossy()])?;
    let line = format!("{DELEGATED}={}\n", delegated.display());
    match std::env::var_os("GITHUB_ENV") {
        Some(env) => {
            use std::io::Write as _;
            fs::OpenOptions::new()
                .append(true)
                .open(&env)
                .with_context(|| format!("cannot open {}", Path::new(&env).display()))?
                .write_all(line.as_bytes())?;
        }
        None => print!("{line}"),
    }
    println!("cgroup: delegated {} to {owner}", delegated.display());
    Ok(())
}

fn sudo(args: &[&str]) -> Result<()> {
    let status = Command::new("sudo")
        .args(args)
        .status()
        .context("cannot run sudo")?;
    if !status.success() {
        bail!("sudo {} failed with {status}", args.join(" "));
    }
    Ok(())
}

fn sudo_write(path: &Path, value: &str) -> Result<()> {
    use std::io::Write as _;
    let mut tee = Command::new("sudo")
        .arg("tee")
        .arg(path)
        .stdin(std::process::Stdio::piped())
        .stdout(std::process::Stdio::null())
        .spawn()
        .context("cannot run sudo tee")?;
    tee.stdin
        .take()
        .context("sudo tee took no input")?
        .write_all(value.as_bytes())?;
    let status = tee.wait()?;
    if !status.success() {
        bail!("cannot write {value} into {}", path.display());
    }
    Ok(())
}

/// Makes the cgroup `dir` held to `limit` bytes.
fn make(dir: &Path, limit: u64) -> Result<()> {
    fs::create_dir_all(dir).with_context(|| format!("cannot make {}", dir.display()))?;
    write(&dir.join("memory.max"), &limit.to_string())
}

/// Makes the leaf `dir` held to `limit` bytes, whose processes the kernel kills together.
fn leaf(dir: &Path, limit: u64) -> Result<()> {
    make(dir, limit)?;
    write(&dir.join("memory.oom.group"), "1")
}

fn write(path: &Path, value: &str) -> Result<()> {
    fs::write(path, value).with_context(|| format!("cannot write {value} into {}", path.display()))
}

/// The machine's memory, in bytes, from `/proc/meminfo`.
fn machine_memory() -> Result<u64> {
    let meminfo = fs::read_to_string("/proc/meminfo").context("cannot read /proc/meminfo")?;
    meminfo
        .lines()
        .find_map(|line| line.strip_prefix("MemTotal:"))
        .and_then(|rest| rest.trim().strip_suffix("kB"))
        .and_then(|kib| kib.trim().parse::<u64>().ok())
        .map(|kib| kib * 1024)
        .context("/proc/meminfo names no MemTotal")
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::results::TestRun;

    const LIMIT: u64 = 16_834_887_680;

    // A folder stands in for the delegated cgroup: the kernel makes a cgroup's control files as the
    // cgroup is made, and counts into memory.peak.

    #[test]
    fn a_run_makes_its_tree_under_the_delegated_cgroup_each_cgroup_held_to_the_machines_memory() {
        let root = tempfile::tempdir().unwrap();

        let tree = Tree::create(root.path(), "7", LIMIT).unwrap();

        let run = root.path().join("run-7");
        for dir in [&run, &run.join("stack"), &run.join("game")] {
            assert_eq!(
                fs::read_to_string(dir.join("memory.max")).unwrap(),
                LIMIT.to_string(),
                "{}",
                dir.display()
            );
            assert_eq!(
                fs::read_to_string(dir.join("cgroup.subtree_control")).unwrap(),
                CONTROLLERS
            );
        }
        assert_eq!(
            fs::read_to_string(run.join("gradle/memory.max")).unwrap(),
            LIMIT.to_string()
        );
        assert_eq!(
            fs::read_to_string(run.join("gradle/memory.oom.group")).unwrap(),
            "1"
        );
        assert_eq!(tree.game(), run.join("game"));
    }

    #[test]
    fn a_placed_command_writes_itself_into_its_leaf_before_it_runs() {
        let root = tempfile::tempdir().unwrap();
        let tree = Tree::create(root.path(), "7", LIMIT).unwrap();
        let leaf = tree.stack_service("realm-host").unwrap();
        let dir = root.path().join("run-7/stack/realm-host");
        fs::write(dir.join("cgroup.procs"), "").unwrap();
        let mut command = Command::new("true");

        leaf.place(&mut command).unwrap();
        assert!(command.status().unwrap().success());

        assert_eq!(fs::read_to_string(dir.join("cgroup.procs")).unwrap(), "0");
        assert_eq!(
            fs::read_to_string(dir.join("memory.max")).unwrap(),
            LIMIT.to_string()
        );
        assert_eq!(
            fs::read_to_string(dir.join("memory.oom.group")).unwrap(),
            "1"
        );
    }

    #[test]
    fn the_run_file_lists_gradle_and_each_stack_service_with_the_most_memory_it_took() {
        let root = tempfile::tempdir().unwrap();
        let tree = Tree::create(root.path(), "7", LIMIT).unwrap();
        tree.stack_service("realm-host").unwrap();
        tree.stack_service("nats").unwrap();
        let run = root.path().join("run-7");
        fs::write(run.join("gradle/memory.peak"), "2147483648\n").unwrap();
        fs::write(run.join("stack/realm-host/memory.peak"), "1073741824\n").unwrap();
        let file = root.path().join("test_run.json");
        results::write(&TestRun::default(), &file).unwrap();

        tree.record(&file).unwrap();

        let parts: Vec<_> = results::read(&file)
            .unwrap()
            .parts
            .into_iter()
            .map(|part| (part.name, part.kind, part.peak_bytes, part.limit_bytes))
            .collect();
        assert_eq!(
            parts,
            [
                (
                    "gradle".to_owned(),
                    PartKind::Gradle,
                    Some(2_147_483_648),
                    0
                ),
                ("nats".to_owned(), PartKind::StackService, None, 0),
                (
                    "realm-host".to_owned(),
                    PartKind::StackService,
                    Some(1_073_741_824),
                    0
                ),
            ]
        );
    }
}
