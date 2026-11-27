//! Memory per part through cgroup v2, where the machine delegates a cgroup to the run's user, as
//! CI does with `cargo xtask cgroup delegate` and names in [`DELEGATED`]. A game run makes its
//! tree there: `run-<id>` holds `stack` (a leaf per service, held to the service's limit),
//! `gradle-build` (every Gradle build of the run, the Kotlin daemon it starts among them),
//! `gradle-test` (the Gradle that runs the suite, with its test JVMs) and `game`, where the pool
//! makes a leaf per game part and its own. The game's `memory.max` is its budget: the machine less
//! the system's share, the test run's limit and the stack's limits. The build ends whole before the
//! test run starts, so it may take the machine.

use std::ffi::CString;
use std::fs;
use std::io;
use std::os::unix::ffi::OsStrExt;
use std::os::unix::process::CommandExt;
use std::path::{Path, PathBuf};
use std::process::Command;

use anyhow::{Context as _, Result, bail};

use crate::results::{self, LossCause, MemoryKill, Part, PartEnd, PartKind, PartLoss};

/// The cgroup the machine delegates to the run's user.
pub const DELEGATED: &str = "TYPEWRITER_CGROUP";

/// The game's cgroup in the run's tree, which the build hands the pool.
pub const GAME: &str = "PLAYTEST_CGROUP";

/// Set to `1` on the pinned runner, which must enforce every limit.
pub const PINNED_RUNNER: &str = "PLAYTEST_PINNED_RUNNER";

/// Where `cargo xtask cgroup delegate` makes the delegated cgroup.
const DELEGATE_ROOT: &str = "/sys/fs/cgroup";

/// The controllers every cgroup of the tree enables for its children.
const CONTROLLERS: &str = "+memory +pids";

const MIB: u64 = 1024 * 1024;

/// What the system outside the run keeps: the kernel, the runner's agent and xtask itself.
const SYSTEM_MIB: u64 = 768;

/// The most memory the Gradle that runs the suite may take with its test JVMs.
pub const GRADLE_TEST_MIB: u64 = 2048;

/// A Gradle of the run, each in a leaf of its own.
#[derive(Clone, Copy, Debug, PartialEq, Eq)]
pub enum Gradle {
    /// Every Gradle build of the run, the Kotlin daemon it starts among them. It ends whole before
    /// the test run starts, so it may take the machine and is held to no limit of its own.
    Build,
    /// The Gradle that runs the suite, with its test JVMs, held to [`GRADLE_TEST_MIB`].
    Test,
}

impl Gradle {
    /// Both, in the order they run.
    const ALL: [Self; 2] = [Self::Build, Self::Test];

    /// Its leaf's name in the run's tree, and its part's name in the run file.
    fn name(self) -> &'static str {
        match self {
            Self::Build => "gradle-build",
            Self::Test => "gradle-test",
        }
    }

    /// The memory its leaf is held to on a machine of `machine` bytes.
    fn limit(self, machine: u64) -> u64 {
        match self {
            Self::Build => machine,
            Self::Test => GRADLE_TEST_MIB * MIB,
        }
    }

    /// The limit the run file lists for it: none for the build, which ends before the game starts.
    fn recorded_limit(self, leaf: &Leaf) -> Result<i64> {
        match self {
            Self::Build => Ok(0),
            Self::Test => leaf.limit(),
        }
    }
}

/// One run's tree under the delegated cgroup.
pub struct Tree {
    run: PathBuf,
}

impl Tree {
    /// The tree of the run `id` under the cgroup the machine delegates, its game held to what the
    /// machine leaves beside a stack whose services may take `stack_bytes`; `None` where the
    /// machine delegates none, as on macOS, which the pinned runner refuses.
    pub fn delegated(id: &str, stack_bytes: u64) -> Result<Option<Self>> {
        let root = std::env::var_os(DELEGATED).filter(|root| !root.is_empty());
        let pinned = std::env::var_os(PINNED_RUNNER).is_some_and(|pinned| pinned == "1");
        require_enforced(pinned, root.is_some())?;
        let Some(root) = root else {
            return Ok(None);
        };
        Self::create(Path::new(&root), id, machine_memory()?, stack_bytes).map(Some)
    }

    /// Makes the tree of the run `id` under `root` on a machine of `machine` bytes, beside a stack
    /// whose services may take `stack_bytes`. A parent enables the memory controller for its
    /// children before they are made, since a child gets its memory files only then.
    pub fn create(root: &Path, id: &str, machine: u64, stack_bytes: u64) -> Result<Self> {
        let controllers = fs::read_to_string(root.join("cgroup.controllers"))
            .with_context(|| format!("cannot read {}/cgroup.controllers", root.display()))?;
        if !controllers
            .split_whitespace()
            .any(|controller| controller == "memory")
        {
            bail!(
                "{} does not offer the memory controller, so no part's memory can be held to its limit",
                root.display()
            );
        }
        let kept = (SYSTEM_MIB + GRADLE_TEST_MIB) * MIB + stack_bytes;
        let Some(game) = machine.checked_sub(kept).filter(|game| *game > 0) else {
            bail!(
                "the machine's {} MiB, less {SYSTEM_MIB} MiB for the system, {GRADLE_TEST_MIB} MiB for Gradle's test run and {} MiB for the stack, leave nothing for the game",
                machine / MIB,
                stack_bytes / MIB
            );
        };
        let run = root.join(format!("run-{id}"));
        make(&run, machine)?;
        write(&run.join("cgroup.subtree_control"), CONTROLLERS)?;
        let tree = Self { run };
        // Each stack service is held by its own leaf; the game, by its budget.
        for (parent, limit) in [(tree.stack(), machine), (tree.game(), game)] {
            make(&parent, limit)?;
            write(&parent.join("cgroup.subtree_control"), CONTROLLERS)?;
        }
        for gradle in Gradle::ALL {
            leaf(&tree.gradle(gradle).0, gradle.limit(machine))?;
        }
        Ok(tree)
    }

    /// The game's cgroup, where the pool makes the game parts' leaves.
    pub fn game(&self) -> PathBuf {
        self.run.join("game")
    }

    fn stack(&self) -> PathBuf {
        self.run.join("stack")
    }

    /// The leaf of `gradle`.
    pub fn gradle(&self, gradle: Gradle) -> Leaf {
        Leaf(self.run.join(gradle.name()))
    }

    /// Kills every process the builds left, as the Kotlin daemon, so only the test run's Gradle
    /// sits beside the game.
    pub fn end_build(&self) -> Result<()> {
        write(&self.gradle(Gradle::Build).0.join("cgroup.kill"), "1")
    }

    /// The leaf of the stack service `id`, made on first use and held to `limit` bytes.
    pub fn stack_service(&self, id: &str, limit: u64) -> Result<Leaf> {
        let dir = self.stack().join(id);
        leaf(&dir, limit)?;
        Ok(Leaf(dir))
    }

    /// Adds Gradle's build and test run and every stack service to the parts of the run file at
    /// `file`, each with its limit, the most memory it took and whether the kernel killed it for
    /// memory. The build has no limit of its own: it ends before the game starts.
    pub fn record(&self, file: &Path) -> Result<()> {
        let mut run = results::read(file)?;
        let mut measured = Vec::new();
        for gradle in Gradle::ALL {
            let leaf = self.gradle(gradle);
            let limit = gradle.recorded_limit(&leaf)?;
            measured.push((gradle.name().to_owned(), PartKind::Gradle, leaf, limit));
        }
        let mut services = Vec::new();
        for entry in fs::read_dir(self.stack())
            .with_context(|| format!("cannot read {}", self.stack().display()))?
        {
            let entry = entry?;
            if entry.file_type()?.is_dir() {
                let name = entry.file_name().to_string_lossy().into_owned();
                let leaf = Leaf(entry.path());
                let limit = leaf.limit()?;
                services.push((name, PartKind::StackService, leaf, limit));
            }
        }
        services.sort_by(|a, b| a.0.cmp(&b.0));
        measured.extend(services);
        for (name, kind, leaf, limit_bytes) in measured {
            let end = match leaf.kill()? {
                Some(kill) => PartEnd::Lost(Box::new(PartLoss {
                    cause: LossCause::KilledForMemory(Box::new(kill)),
                    ..PartLoss::default()
                })),
                None => PartEnd::RanToEnd,
            };
            run.parts.push(Part {
                name,
                kind,
                end,
                limit_bytes,
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
        let gradles = Gradle::ALL.map(|gradle| self.gradle(gradle).0);
        for dir in [self.stack(), self.game()]
            .into_iter()
            .chain(gradles)
            .chain([self.run.clone()])
        {
            let _ = fs::remove_dir(dir);
        }
    }
}

/// Refuses a run on the `pinned` runner that is not `enforced`: there a part over its limit must
/// be killed for it, not pass on a runner that happens to have room.
pub fn require_enforced(pinned: bool, enforced: bool) -> Result<()> {
    if pinned && !enforced {
        bail!(
            "this is the pinned runner ({PINNED_RUNNER}=1), but no cgroup is delegated ({DELEGATED}), so no part's memory is held to its limit; run `cargo xtask cgroup delegate` first"
        );
    }
    Ok(())
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

    /// The memory the leaf may take, in bytes.
    fn limit(&self) -> Result<i64> {
        let file = self.0.join("memory.max");
        let limit =
            fs::read_to_string(&file).with_context(|| format!("cannot read {}", file.display()))?;
        limit
            .trim()
            .parse()
            .with_context(|| format!("{} holds no limit: {limit}", file.display()))
    }

    /// Why the kernel killed the leaf's processes for memory, if it did: for its own limit when the
    /// leaf reached it, otherwise because the machine ran out. The kernel counts a kill in the
    /// victim's cgroup whatever chose it, but a reached limit only where it was reached.
    fn kill(&self) -> Result<Option<MemoryKill>> {
        let file = self.0.join("memory.events");
        let events = match fs::read_to_string(&file) {
            Ok(events) => events,
            Err(error) if error.kind() == io::ErrorKind::NotFound => return Ok(None),
            Err(error) => {
                return Err(error).with_context(|| format!("cannot read {}", file.display()));
            }
        };
        let count = |name: &str| {
            events
                .lines()
                .filter_map(|line| line.split_once(' '))
                .find(|(event, _)| *event == name)
                .map_or(Ok(0), |(_, count)| count.trim().parse::<u64>())
                .with_context(|| format!("{} counts {name} as no number", file.display()))
        };
        Ok(match (count("oom_kill")?, count("oom")?) {
            (0, _) => None,
            (_, 0) => Some(MemoryKill::MachineOutOfMemory),
            _ => Some(MemoryKill::OwnLimit),
        })
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
    use crate::test_support::delegated_cgroup;

    const MIB: u64 = 1024 * 1024;
    const MACHINE: u64 = 16_053 * MIB;
    const STACK: u64 = 2_489 * MIB;

    #[test]
    fn a_run_holds_the_game_to_the_machine_less_the_system_gradle_s_test_run_and_the_stack() {
        let root = delegated_cgroup();

        let tree = Tree::create(root.path(), "7", MACHINE, STACK).unwrap();

        let run = root.path().join("run-7");
        assert_eq!(
            fs::read_to_string(run.join("game").join("memory.max")).unwrap(),
            ((16_053 - 768 - GRADLE_TEST_MIB - 2_489) * MIB).to_string()
        );
        assert_eq!(
            fs::read_to_string(run.join("gradle-test").join("memory.max")).unwrap(),
            (GRADLE_TEST_MIB * MIB).to_string()
        );
        // The build ends before the game starts, so it may take the machine.
        assert_eq!(
            fs::read_to_string(run.join("gradle-build").join("memory.max")).unwrap(),
            MACHINE.to_string()
        );
        for dir in [&run, &run.join("stack"), &run.join("game")] {
            assert_eq!(
                fs::read_to_string(dir.join("cgroup.subtree_control")).unwrap(),
                CONTROLLERS,
                "{}",
                dir.display()
            );
        }
        for leaf in ["gradle-build", "gradle-test"] {
            assert_eq!(
                fs::read_to_string(run.join(leaf).join("memory.oom.group")).unwrap(),
                "1",
                "{leaf}"
            );
        }
        assert_eq!(tree.game(), run.join("game"));
    }

    #[test]
    fn each_stack_service_runs_held_to_its_own_limit() {
        let root = delegated_cgroup();
        let tree = Tree::create(root.path(), "7", MACHINE, STACK).unwrap();

        tree.stack_service("realm", 1_330 * MIB).unwrap();

        let leaf = root.path().join("run-7/stack/realm");
        assert_eq!(
            fs::read_to_string(leaf.join("memory.max")).unwrap(),
            (1_330 * MIB).to_string()
        );
        assert_eq!(
            fs::read_to_string(leaf.join("memory.oom.group")).unwrap(),
            "1"
        );
    }

    #[test]
    fn a_machine_the_system_gradle_s_test_run_and_the_stack_leave_no_game_budget_of_is_refused_naming_the_numbers()
     {
        let root = delegated_cgroup();

        let error = Tree::create(root.path(), "7", 4_000 * MIB, STACK)
            .err()
            .unwrap()
            .to_string();

        assert!(error.contains("4000 MiB"), "{error}");
        assert!(error.contains("2489 MiB"), "{error}");
    }

    #[test]
    fn a_delegated_cgroup_without_the_memory_controller_is_refused() {
        let root = tempfile::tempdir().unwrap();
        fs::write(root.path().join("cgroup.controllers"), "cpu pids\n").unwrap();

        let error = Tree::create(root.path(), "7", MACHINE, 0)
            .err()
            .unwrap()
            .to_string();

        assert!(error.contains("memory controller"), "{error}");
    }

    #[test]
    fn the_build_ends_whole_before_the_test_run_starts() {
        let root = delegated_cgroup();
        let tree = Tree::create(root.path(), "7", MACHINE, 0).unwrap();

        tree.end_build().unwrap();

        // The kernel kills every process the leaf still holds, the Kotlin daemon the build left among them.
        assert_eq!(
            fs::read_to_string(root.path().join("run-7/gradle-build/cgroup.kill")).unwrap(),
            "1"
        );
    }

    #[test]
    fn the_pinned_runner_fails_where_no_cgroup_enforces_the_limits() {
        let error = require_enforced(true, false).unwrap_err().to_string();

        assert!(error.contains(DELEGATED), "{error}");
        require_enforced(true, true).unwrap();
        require_enforced(false, false).unwrap();
    }

    #[test]
    fn a_placed_command_writes_itself_into_its_leaf_before_it_runs() {
        let root = delegated_cgroup();
        let tree = Tree::create(root.path(), "7", MACHINE, 0).unwrap();
        let leaf = tree.stack_service("realm", 1_330 * MIB).unwrap();
        let dir = root.path().join("run-7/stack/realm");
        fs::write(dir.join("cgroup.procs"), "").unwrap();
        let mut command = Command::new("true");

        leaf.place(&mut command).unwrap();
        assert!(command.status().unwrap().success());

        assert_eq!(fs::read_to_string(dir.join("cgroup.procs")).unwrap(), "0");
    }

    #[test]
    fn the_run_file_lists_gradle_s_build_and_test_run_and_each_stack_service_with_its_limit_peak_and_kill()
     {
        let root = delegated_cgroup();
        let tree = Tree::create(root.path(), "7", MACHINE, STACK).unwrap();
        tree.stack_service("realm", 1_330 * MIB).unwrap();
        tree.stack_service("broker", 64 * MIB).unwrap();
        let run = root.path().join("run-7");
        fs::write(run.join("gradle-build/memory.peak"), "4294967296\n").unwrap();
        fs::write(run.join("gradle-test/memory.peak"), "1073741824\n").unwrap();
        fs::write(run.join("stack/realm/memory.peak"), "1073741824\n").unwrap();
        fs::write(
            run.join("stack/broker/memory.events"),
            "low 0\nhigh 0\nmax 9\noom 1\noom_kill 1\noom_group_kill 1\n",
        )
        .unwrap();
        let file = root.path().join("test_run.json");
        results::write(&TestRun::default(), &file).unwrap();

        tree.record(&file).unwrap();

        let parts: Vec<_> = results::read(&file)
            .unwrap()
            .parts
            .into_iter()
            .map(|part| {
                (
                    part.name,
                    part.kind,
                    part.limit_bytes,
                    part.peak_bytes,
                    part.end,
                )
            })
            .collect();
        let killed = PartEnd::Lost(Box::new(PartLoss {
            cause: LossCause::KilledForMemory(Box::new(MemoryKill::OwnLimit)),
            ..PartLoss::default()
        }));
        assert_eq!(
            parts,
            [
                (
                    "gradle-build".to_owned(),
                    PartKind::Gradle,
                    0,
                    Some(4_294_967_296),
                    PartEnd::RanToEnd
                ),
                (
                    "gradle-test".to_owned(),
                    PartKind::Gradle,
                    (GRADLE_TEST_MIB * MIB) as i64,
                    Some(1_073_741_824),
                    PartEnd::RanToEnd
                ),
                (
                    "broker".to_owned(),
                    PartKind::StackService,
                    (64 * MIB) as i64,
                    None,
                    killed
                ),
                (
                    "realm".to_owned(),
                    PartKind::StackService,
                    (1_330 * MIB) as i64,
                    Some(1_073_741_824),
                    PartEnd::RanToEnd
                ),
            ]
        );
    }
}
