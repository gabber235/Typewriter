//! `cargo xtask e2e`: the end to end suites. Each suite starts the worktree's panel stack, drives
//! the panel's `integration_test` scenarios through `flutter drive` inside the evidence recorder
//! and writes their `TestRun`, every attempt included, to `.xtask/results/<suite>`, where the
//! change report and the evidence section read it. Each attempt runs every drive of the suite's
//! [`Target`]; a drive keeps its clips, screenshots and stamped output in its own folder of
//! `attempts/<n>/` beside the run file, which the attempt records (`Attempt.folder`), and a
//! failed attempt also leaves a local failure folder there ([`failures`]). `--only` selects scenarios and `--repeat` runs each of
//! them an exact number of times, to hunt a flaky scenario. The full suite runs the panel web
//! scenarios against a fresh CI cluster instead (`cargo xtask cluster ci`, `cargo xtask deploy ci`),
//! with the worktree's organization and Realm host on top of the cluster's backend, plus the sign
//! in journey through the cluster's Authentik pages that no scenario can drive.
//!
//! `flutter drive` rather than `flutter test integration_test`: only the host driver
//! (`panel/test_driver/integration_test.dart`) can write files on desktop and on web, and it is
//! what receives the scenarios' results and screenshots.

pub(crate) mod failures;

use std::io::Write;
use std::net::{Ipv4Addr, TcpListener};
use std::num::NonZeroU32;
use std::path::{Path, PathBuf};
use std::process::ExitStatus;
use std::time::Duration;

use anyhow::{Context as _, Result, bail};

use crate::cluster::CiCluster;
use crate::deploy;
use crate::evidence::{self, Recorded};
use crate::lock::{self, HeavyLock};
use crate::results::{self, AttemptPolicy, Outcome, Quarantine, TestRun};
use crate::stack::spec::StackSpec;
use crate::stack::{self, typewriter};
use crate::{CommandExt, Context, cluster, generate, secrets};

/// Where the stack writes the panel's compile time defines (it publishes the same path as
/// `STACK_PANEL_DEFINES`), relative to the repository root.
const PANEL_DEFINES: &str = ".xtask/state/stack/panel.json";

/// Where a suite keeps its stopped stack's logs and spans for failure folders, relative to the
/// repository root; outside the results folder, so CI never uploads them.
const STACK_EVIDENCE: &str = ".xtask/state/e2e";

/// Xcode build settings (Flutter passes `FLUTTER_XCODE_<setting>` variables to xcodebuild) that
/// sign the macOS app ad hoc without the keychain entitlement, so the build needs no provisioning
/// profile or developer account; scenarios keep tokens in memory. Linux ignores them.
const UNSIGNED_MACOS: [(&str, &str); 4] = [
    ("CODE_SIGN_IDENTITY", "-"),
    ("CODE_SIGN_STYLE", "Manual"),
    ("DEVELOPMENT_TEAM", ""),
    ("PROVISIONING_PROFILE_SPECIFIER", ""),
];

/// Relative to the repository root. Xcode applies command line settings to every target,
/// including the plugins' package targets, so the path passed is absolute.
const UNSIGNED_ENTITLEMENTS: &str = "panel/macos/Runner/EndToEnd.entitlements";

/// The devenv shell's Nix C toolchain. xcodebuild reads environment variables as build settings,
/// and these would replace Xcode's compiler and linker with the Nix wrappers, which cannot link a
/// macOS app.
const NIX_TOOLCHAIN: [&str; 3] = ["CC", "CXX", "LD"];

/// What `cargo xtask e2e` runs.
#[derive(clap::Args)]
pub struct E2eArgs {
    suite: Suite,
    /// Requirement ids (CONN-1) or full scenario ids; empty runs every scenario.
    #[arg(long, value_delimiter = ',')]
    pub(crate) only: Vec<String>,
    /// Attempts per selected scenario, instead of one attempt plus a rerun of failures.
    #[arg(long, default_value_t = NonZeroU32::MIN)]
    repeat: NonZeroU32,
}

impl E2eArgs {
    /// One attempt and a rerun of failures, or exactly `--repeat` attempts.
    pub(crate) fn policy(&self) -> AttemptPolicy {
        match self.repeat.get() {
            1 => AttemptPolicy::RerunFailures(2),
            n => AttemptPolicy::Exactly(i32::try_from(n).unwrap_or(i32::MAX)),
        }
    }
}

/// An end to end suite: the device the panel runs on and the target it runs against.
#[derive(Clone, Copy, PartialEq, Eq, clap::ValueEnum)]
pub enum Suite {
    /// The panel as a desktop app on this machine, over native NATS.
    Panel,
    /// The panel in Chrome through chromedriver, over NATS websockets.
    PanelWeb,
    /// A fresh CI cluster with this commit's backend deployed, and the panel web scenarios
    /// against its real Authentik, operator mode NATS and runtime operator.
    Full,
}

impl Suite {
    /// The whole run of one attempt once the stack is up: the app build, the scenarios and
    /// one rerun.
    fn budget(self) -> Duration {
        Duration::from_secs(30 * 60)
    }
}

/// Where the panel runs; names the suite's results folder.
#[derive(Clone, Copy)]
enum Device {
    Desktop,
    Chrome,
}

impl Device {
    fn name(self) -> &'static str {
        match self {
            Self::Desktop => "panel",
            Self::Chrome => "panel-web",
        }
    }
}

/// Runs the selected cases of the suite and reports them.
pub fn run(ctx: &Context, args: &E2eArgs) -> Result<()> {
    match args.suite {
        Suite::Panel => scenarios::<WorktreeStack>(ctx, args, Device::Desktop),
        Suite::PanelWeb => scenarios::<WorktreeStack>(ctx, args, Device::Chrome),
        Suite::Full => scenarios::<CiCluster>(ctx, args, Device::Chrome),
    }
}

/// What a suite runs against: brought up before the stack starts, the stack built on top of it,
/// and the drives every attempt makes there.
pub(crate) trait Target: Sized + 'static {
    /// Before the device's name in the results folder: `full-panel-web` on the CI cluster.
    const PREFIX: &'static str;
    /// What every attempt drives, in order. A drive runs on one target type, so a drive that
    /// needs the CI cluster is a type error in any other target's list.
    const DRIVES: &'static [Drive<Self>];
    /// Brings the target up before the stack starts.
    fn prepare(ctx: &Context) -> Result<Self>;
    /// The organization and Realm host on top of the target's backend.
    fn spec(&self) -> StackSpec;
    /// The port Chrome serves the panel on when the target accepts only one; any free port
    /// otherwise.
    fn web_port(&self) -> Option<u16>;
}

/// A fresh worktree stack, up for the run only; its own services bring its backend up.
pub(crate) struct WorktreeStack;

impl Target for WorktreeStack {
    const PREFIX: &'static str = "";
    const DRIVES: &'static [Drive<Self>] = &[Drive::SCENARIOS];

    fn prepare(_: &Context) -> Result<Self> {
        Ok(Self)
    }

    fn spec(&self) -> StackSpec {
        typewriter::panel()
    }

    fn web_port(&self) -> Option<u16> {
        None
    }
}

/// A fresh CI cluster with this commit's backend deployed.
impl Target for CiCluster {
    const PREFIX: &'static str = "full-";
    const DRIVES: &'static [Drive<Self>] = &[Drive::SCENARIOS, SIGN_IN];

    fn prepare(ctx: &Context) -> Result<Self> {
        let ci = cluster::create_ci(ctx, &secrets::Ci::load()?)?;
        deploy::deploy_ci(ctx, &ci)?;
        Ok(ci)
    }

    fn spec(&self) -> StackSpec {
        typewriter::ci_cluster_panel(self)
    }

    /// Its Authentik accepts the panel only at clients.json's panel origin.
    fn web_port(&self) -> Option<u16> {
        Some(self.panel_port())
    }
}

/// Takes the heavy lock at `lock`, then clears the previous run's results in `evidence`.
/// Clearing only once the lock is held means a run that waits for its turn never removes
/// the results of the run still writing them.
fn take_turn(lock: &Path, holder: &str, evidence: &Path) -> Result<HeavyLock> {
    let held = HeavyLock::acquire_at(lock, holder)?;
    if evidence.exists() {
        std::fs::remove_dir_all(evidence)
            .with_context(|| format!("cannot clear {}", evidence.display()))?;
    }
    Ok(held)
}

/// Brings `T` up, then runs the selected cases of its drives on `device` and reports them.
fn scenarios<T: Target>(ctx: &Context, args: &E2eArgs, device: Device) -> Result<()> {
    let target = T::prepare(ctx)?;
    // The panel compiles against the generated Skir and build_runner sources.
    generate::generate(ctx, None)?;
    let name = format!("{}{}", T::PREFIX, device.name());
    let shown = Path::new(evidence::RESULTS).join(&name);
    let evidence = ctx.root.join(&shown);
    let commit = ctx
        .tool(".", "git", &["rev-parse", "HEAD"])
        .output_text()?
        .trim()
        .to_owned();
    let quarantine = Quarantine::load(ctx)?;
    // Flutter builds the app inside `flutter drive`, so the whole run is one heavy build.
    let lock = || {
        take_turn(
            Path::new(lock::HEAVY_LOCK),
            &format!("e2e {name}"),
            &evidence,
        )
    };
    let defines = ctx.root.join(PANEL_DEFINES);
    let launch = Launch {
        ctx,
        device,
        defines: &defines,
        target: &target,
    };
    let budget = args.suite.budget() * args.repeat.get();
    let keep = ctx.root.join(STACK_EVIDENCE).join(&name);
    let (mut run, stack) =
        stack::run_keeping_evidence(ctx, &target.spec(), budget, &keep, |stack| {
            let _lock = lock()?;
            results::attempts(args.policy(), &args.only, &quarantine, |n, ids| {
                attempt::<T>(&evidence, n, ids, |drive, out, ids| {
                    let recorded = (drive.launch)(&launch, ids)?
                        .in_dir("panel")
                        .env("EVIDENCE_DIR", out.display().to_string())
                        .log_to(out.join(failures::DRIVE_LOG));
                    // Without a results file the drive never ran (the build or the launch
                    // failed), and recording fails.
                    evidence::record_with(ctx, out, recorded, &mut *stack)
                })
            })
        })?;
    failures::collect(&evidence, &mut run, &stack)?;
    let run = TestRun { commit, ..run };
    let file = evidence.join("test_run.json");
    results::write(&run, &file)?;
    verdict(
        &name,
        &file,
        &run,
        &quarantine,
        &shown,
        &mut std::io::stderr(),
    )?;
    println!(
        "{name}: {} scenarios passed ({})",
        run.cases.len(),
        file.display()
    );
    Ok(())
}

/// One `flutter drive` an attempt on a `T` makes: where its evidence lies inside
/// `attempts/<n>/`, the requirements it reports and the command it records.
pub(crate) struct Drive<T> {
    /// Below `attempts/<n>/`; `None` for the attempt folder itself.
    pub(crate) folder: Option<&'static str>,
    owns: Owns,
    /// The command for the drive's `ids` (every case when empty); it writes into the folder
    /// `EVIDENCE_DIR` names.
    launch: fn(&Launch<'_, T>, &[String]) -> Result<Recorded>,
}

/// The requirements a drive reports.
enum Owns {
    /// Every requirement no other drive of its target declares.
    Rest,
    /// Exactly these; every case the drive reports names one of them.
    Requirements(&'static [&'static str]),
}

/// The sign in journey, which names its requirement in
/// `panel/test_driver/sign_in_journey_test.dart`.
const SIGN_IN: Drive<CiCluster> = Drive {
    folder: Some("sign-in"),
    owns: Owns::Requirements(&["AUTH-2"]),
    launch: sign_in_journey,
};

/// What every drive's command is built from.
struct Launch<'a, T> {
    ctx: &'a Context,
    device: Device,
    defines: &'a Path,
    /// The target `T::prepare` brought up for this run.
    target: &'a T,
}

impl<T: Target> Drive<T> {
    /// The panel's `integration_test` scenarios, which run on every target.
    const SCENARIOS: Self = Self {
        folder: None,
        owns: Owns::Rest,
        launch: scenario_drive::<T>,
    };

    /// Whether this drive, one of `T::DRIVES`, reports `requirement`.
    fn declares(&self, requirement: &str) -> bool {
        let owned = |drive: &Drive<T>| matches!(drive.owns, Owns::Requirements(owned) if owned.contains(&requirement));
        match self.owns {
            Owns::Requirements(_) => owned(self),
            Owns::Rest => !T::DRIVES.iter().any(owned),
        }
    }

    fn name(&self) -> &'static str {
        self.folder.unwrap_or("the scenario drive")
    }

    /// Attempt `n`'s evidence folder, relative to the suite's evidence folder.
    fn folder(&self, n: u32) -> PathBuf {
        let attempt = Path::new(results::ATTEMPTS).join(n.to_string());
        match self.folder {
            None => attempt,
            Some(below) => attempt.join(below),
        }
    }
}

/// The requirement an `--only` id names: the id itself, or the `[REQ]` prefix of a case id.
fn requirement_of(id: &str) -> &str {
    id.strip_prefix('[')
        .and_then(|rest| rest.split_once(']'))
        .map_or(id, |(requirement, _)| requirement)
}

/// The drives of `T` an attempt of `ids` launches, each with the ids it owns. Empty `ids` means
/// everything, so every drive runs with empty ids; otherwise a drive that owns none of them is
/// not launched.
fn route<T: Target>(ids: &[String]) -> Vec<(&'static Drive<T>, Vec<String>)> {
    T::DRIVES
        .iter()
        .filter_map(|drive| {
            let owned: Vec<String> = ids
                .iter()
                .filter(|id| drive.declares(requirement_of(id)))
                .cloned()
                .collect();
            (ids.is_empty() || !owned.is_empty()).then_some((drive, owned))
        })
        .collect()
}

/// Records one drive into `out` and returns its run (the drive's `test_run.json`) and exit.
pub(crate) type Record<'a, T> =
    dyn FnMut(&Drive<T>, &Path, &[String]) -> Result<(TestRun, ExitStatus)> + 'a;

/// Attempt `n` of `ids` (everything when empty) on `T`: every drive `route` hands ids runs
/// through `record` into its folder of `evidence`, and their cases fold into one run.
pub(crate) fn attempt<T: Target>(
    evidence: &Path,
    n: u32,
    ids: &[String],
    mut record: impl FnMut(&Drive<T>, &Path, &[String]) -> Result<(TestRun, ExitStatus)>,
) -> Result<TestRun> {
    let mut folded: Option<TestRun> = None;
    for (drive, owned) in route::<T>(ids) {
        let run = run_drive(drive, evidence, n, &owned, &mut record)?;
        match &mut folded {
            Some(folded) => folded.cases.extend(run.cases),
            None => folded = Some(run),
        }
    }
    folded.with_context(|| format!("no drive runs {}", ids.join(", ")))
}

/// Drives `drive`'s attempt `n` of `ids` into its folder of `evidence`: records it, reads its
/// run, records that folder on every attempt, and fails when the drive crashed ([`driven`]),
/// reported a requirement it does not declare, or, owning requirements, reported a case without
/// one.
fn run_drive<T: Target>(
    drive: &Drive<T>,
    evidence: &Path,
    n: u32,
    ids: &[String],
    record: &mut Record<'_, T>,
) -> Result<TestRun> {
    let folder = drive.folder(n);
    let (run, exit) = record(drive, &evidence.join(&folder), ids)?;
    let mut run = driven(exit, run)?;
    for case in &mut run.cases {
        match case.requirement.as_deref() {
            Some(requirement) if !drive.declares(requirement) => bail!(
                "{} reported {requirement}, which it does not declare",
                drive.name()
            ),
            None if matches!(drive.owns, Owns::Requirements(_)) => bail!(
                "{} reported {} without the requirement it proves",
                drive.name(),
                case.id
            ),
            _ => {}
        }
        for attempt in &mut case.attempts {
            attempt.folder = folder.display().to_string();
        }
    }
    Ok(run)
}

/// The panel's `integration_test` scenarios, `ids` limiting them to those scenario or
/// requirement ids (every scenario when empty). A failing scenario is a result, not an error.
fn scenario_drive<T: Target>(launch: &Launch<'_, T>, ids: &[String]) -> Result<Recorded> {
    let mut command: Vec<String> = [
        "flutter",
        "drive",
        "--driver=test_driver/integration_test.dart",
        "--target=integration_test/all_test.dart",
    ]
    .map(String::from)
    .into();
    command.push(defines(launch.defines));
    if !ids.is_empty() {
        command.push(format!(
            "--dart-define=SCENARIOS={}",
            serde_json::to_string(ids)?
        ));
    }
    match launch.device {
        Device::Desktop => {
            command.extend(["-d".into(), desktop_device()?.into()]);
            let recorded = UNSIGNED_MACOS.iter().fold(
                Recorded::video(command).env(
                    "FLUTTER_XCODE_CODE_SIGN_ENTITLEMENTS",
                    launch
                        .ctx
                        .root
                        .join(UNSIGNED_ENTITLEMENTS)
                        .display()
                        .to_string(),
                ),
                |recorded, (setting, value)| {
                    recorded.env(&format!("FLUTTER_XCODE_{setting}"), *value)
                },
            );
            Ok(NIX_TOOLCHAIN
                .iter()
                .fold(recorded, |recorded, key| recorded.env_remove(key)))
        }
        Device::Chrome => in_chrome(command, launch),
    }
}

/// `flutter drive` `command` in Chrome through chromedriver, serving the panel on the target's
/// web port when it accepts only one.
fn in_chrome<T: Target>(mut command: Vec<String>, launch: &Launch<'_, T>) -> Result<Recorded> {
    // A free port rather than chromedriver's 4444, so worktrees can run this at once.
    let port = TcpListener::bind((Ipv4Addr::LOCALHOST, 0))?
        .local_addr()?
        .port();
    command.extend([
        "-d".into(),
        "web-server".into(),
        "--browser-name=chrome".into(),
        format!("--driver-port={port}"),
        // Linux records Chrome's window on the virtual display; elsewhere nothing is
        // recorded and no window should open.
        if cfg!(target_os = "linux") {
            "--no-headless".into()
        } else {
            "--headless".into()
        },
    ]);
    // chromedriver drives only the Chrome release it was built for. Without a binary it starts
    // whatever Chrome the machine has, such as a CI runner's preinstalled one, so the devenv
    // Chrome it matches is named where devenv provides one.
    if let Some(chrome) = std::env::var_os("CHROME_EXECUTABLE") {
        command.push(format!("--chrome-binary={}", chrome.to_string_lossy()));
    }
    if let Some(web_port) = launch.target.web_port() {
        command.push(format!("--web-port={web_port}"));
    }
    Ok(Recorded::video(command).with(vec!["chromedriver".into(), format!("--port={port}")]))
}

/// The fixture user the sign in journey signs in as.
const JOURNEY_USER: &str = "ada";

/// The sign in journey through the CI cluster's Authentik pages, which no scenario can drive
/// (`panel/test_driver/sign_in_journey_test.dart`), signing in as [`JOURNEY_USER`] with the
/// password of its sign in form. It runs its one case whatever ids it is handed.
fn sign_in_journey(launch: &Launch<'_, CiCluster>, _ids: &[String]) -> Result<Recorded> {
    let password = launch
        .target
        .test_user_passwords(launch.ctx)?
        .remove(&format!("{JOURNEY_USER}.password"))
        .with_context(|| format!("the CI cluster has no sign in password for {JOURNEY_USER}"))?;
    let command = [
        "flutter",
        "drive",
        "--driver=test_driver/sign_in_journey_test.dart",
        "--target=test_driver/sign_in_journey.dart",
    ]
    .map(String::from)
    .into_iter()
    .chain([defines(launch.defines)])
    .collect();
    Ok(in_chrome(command, launch)?
        .env("STACK_SIGN_IN_USERNAME", JOURNEY_USER)
        .env("STACK_SIGN_IN_PASSWORD", password))
}

/// The results of one drive that exited with `exit`. A drive that exits non zero without a
/// failing scenario crashed (the build, the launch or the driver failed), so its results prove
/// nothing; a failing scenario explains the exit and is a result.
fn driven(exit: ExitStatus, run: TestRun) -> Result<TestRun> {
    let failed = run
        .cases
        .iter()
        .flat_map(|case| &case.attempts)
        .any(|attempt| matches!(attempt.outcome, Outcome::Failed(_)));
    if !exit.success() && !failed {
        bail!(
            "flutter drive failed with {exit} without a failing scenario; its output above says why"
        );
    }
    Ok(run)
}

/// The suite's verdict on its `run`, written to `file` in the `evidence` folder: every case that
/// did not plainly pass goes to `out`, pointing at its evidence, and the run fails when a
/// scenario failed or none was reported.
fn verdict(
    name: &str,
    file: &Path,
    run: &TestRun,
    quarantine: &Quarantine,
    evidence: &Path,
    out: &mut dyn Write,
) -> Result<()> {
    // Every suite drives the same registered scenarios, so a drive reporting none is broken.
    if run.cases.is_empty() {
        bail!(
            "{name}: the drive reported no scenarios ({})",
            file.display()
        );
    }
    results::report(run, quarantine, Some(evidence), out)
}

fn defines(file: &Path) -> String {
    format!("--dart-define-from-file={}", file.display())
}

/// The Flutter desktop device of this machine.
fn desktop_device() -> Result<&'static str> {
    if cfg!(target_os = "macos") {
        Ok("macos")
    } else if cfg!(target_os = "linux") {
        Ok("linux")
    } else {
        bail!("the panel suite runs on macOS and Linux")
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::test_support::{
        Drove, drive_attempts, drove, e2e_args as parsed, exited, failed, refusal, report_text,
        requirement_run, run,
    };

    #[test]
    fn each_attempt_launches_the_drives_of_its_target_that_own_the_selection() {
        let reply = |folder: Option<&str>, _| match folder {
            None => requirement_run("CONN-1", "[CONN-1] Reconnects", Outcome::Passed),
            Some(_) => requirement_run("AUTH-2", "[AUTH-2] Signs in", Outcome::Passed),
        };
        let ci = |args: &[&str]| {
            drive_attempts::<CiCluster>(&parsed(args).unwrap(), reply)
                .unwrap()
                .1
        };
        let worktree = |args: &[&str]| {
            drive_attempts::<WorktreeStack>(&parsed(args).unwrap(), reply)
                .unwrap()
                .1
        };
        let table: [(Drove, Drove); 4] = [
            (
                ci(&["full"]),
                drove(&[("attempts/1", &[]), ("attempts/1/sign-in", &[])]),
            ),
            (worktree(&["panel-web"]), drove(&[("attempts/1", &[])])),
            (
                ci(&["full", "--only", "CONN-1"]),
                drove(&[("attempts/1", &["CONN-1"])]),
            ),
            (
                ci(&["full", "--only", "CONN-1,AUTH-2", "--repeat", "2"]),
                drove(&[
                    ("attempts/1", &["CONN-1"]),
                    ("attempts/1/sign-in", &["AUTH-2"]),
                    ("attempts/2", &["CONN-1"]),
                    ("attempts/2/sign-in", &["AUTH-2"]),
                ]),
            ),
        ];
        for (made, expected) in table {
            assert_eq!(made, expected);
        }
    }

    #[test]
    fn a_requirement_drive_reporting_a_case_without_a_requirement_fails_the_run() {
        let args = parsed(&["full", "--only", "AUTH-2"]).unwrap();
        let error =
            drive_attempts::<CiCluster>(&args, |_, _| run(&[("Signs in", Outcome::Passed)]))
                .unwrap_err();
        assert_eq!(
            error.to_string(),
            "sign-in reported Signs in without the requirement it proves"
        );
    }

    #[test]
    fn a_waiting_run_keeps_the_running_run_s_results_until_its_turn() {
        let dir = tempfile::tempdir().unwrap();
        let (lock, evidence) = (dir.path().join("heavy.lock"), dir.path().join("panel"));
        std::fs::create_dir(&evidence).unwrap();
        let running = HeavyLock::acquire_at(&lock, "first run").unwrap();
        let waiting = std::thread::spawn({
            let (lock, evidence) = (lock.clone(), evidence.clone());
            move || take_turn(&lock, "second run", &evidence).map(drop)
        });
        std::thread::sleep(std::time::Duration::from_millis(300));
        assert!(
            evidence.exists(),
            "a waiting run must not clear the running run's results"
        );
        drop(running);
        waiting.join().unwrap().unwrap();
        assert!(
            !evidence.exists(),
            "its turn starts by clearing the previous results"
        );
    }

    #[test]
    fn a_repeated_journey_selection_drives_only_the_journey_into_its_own_folder() {
        let args = parsed(&["full", "--only", "AUTH-2", "--repeat", "5"]).unwrap();
        let (folded, drove) = drive_attempts::<CiCluster>(&args, |_, _| {
            requirement_run("AUTH-2", "[AUTH-2] Signs in", Outcome::Passed)
        })
        .unwrap();
        let folders: Vec<String> = (1..=5).map(|n| format!("attempts/{n}/sign-in")).collect();
        assert_eq!(
            drove,
            folders
                .iter()
                .map(|folder| (folder.clone(), vec!["AUTH-2".to_owned()]))
                .collect::<Vec<_>>()
        );
        let recorded: Vec<&str> = folded.cases[0]
            .attempts
            .iter()
            .map(|attempt| attempt.folder.as_str())
            .collect();
        assert_eq!(recorded, folders);
    }

    #[test]
    fn a_rerun_after_a_failed_journey_drives_only_the_journey() {
        let args = parsed(&["full", "--only", "CONN-1,AUTH-2"]).unwrap();
        let (_, made) = drive_attempts::<CiCluster>(&args, |folder, n| match (folder, n) {
            (None, _) => requirement_run("CONN-1", "[CONN-1] Reconnects", Outcome::Passed),
            (_, 1) => requirement_run("AUTH-2", "[AUTH-2] Signs in", failed("boom")),
            _ => requirement_run("AUTH-2", "[AUTH-2] Signs in", Outcome::Passed),
        })
        .unwrap();
        assert_eq!(
            made,
            drove(&[
                ("attempts/1", &["CONN-1"]),
                ("attempts/1/sign-in", &["AUTH-2"]),
                ("attempts/2/sign-in", &["[AUTH-2] Signs in"]),
            ])
        );
    }

    #[test]
    fn a_drive_reporting_a_requirement_it_does_not_declare_fails_the_run() {
        let args = parsed(&["full", "--only", "AUTH-2"]).unwrap();
        let error = drive_attempts::<CiCluster>(&args, |_, _| {
            requirement_run("AUTH-3", "[AUTH-3] Signs up", Outcome::Passed)
        })
        .unwrap_err();
        assert_eq!(
            error.to_string(),
            "sign-in reported AUTH-3, which it does not declare"
        );
    }

    #[test]
    fn the_report_points_a_failed_attempt_at_the_folder_its_drive_wrote() {
        let mut journey = requirement_run("AUTH-2", "[AUTH-2] Signs in", failed("boom"));
        journey.cases[0].attempts[0].folder = "attempts/1/sign-in".to_owned();
        let (result, out) = report_text(&journey, &Quarantine::default());
        assert!(result.is_err());
        assert_eq!(
            out,
            "[AUTH-2] Signs in: failed 1 of 1 attempts (1); see results/panel/attempts/1/sign-in/\n"
        );
    }

    #[test]
    fn a_repeat_of_zero_is_refused() {
        assert!(parsed(&["panel", "--repeat", "0"]).is_err());
    }

    #[test]
    fn a_drive_that_crashes_without_results_fails_the_run_and_says_so() {
        let error = driven(exited(1), run(&[])).unwrap_err().to_string();
        assert!(error.contains("without a failing scenario"), "{error}");
    }

    #[test]
    fn a_drive_that_crashes_after_passing_scenarios_fails_the_run() {
        assert!(driven(exited(1), run(&[("a", Outcome::Passed)])).is_err());
    }

    #[test]
    fn a_drive_that_exits_non_zero_for_a_failing_scenario_reports_it() {
        let reported = driven(exited(1), run(&[("a", failed("boom"))])).unwrap();
        assert!(matches!(
            reported.cases[0].attempts[0].outcome,
            Outcome::Failed(_)
        ));
    }

    #[test]
    fn a_run_that_reports_no_scenarios_fails() {
        let error = refusal(verdict(
            "panel",
            Path::new("test_run.json"),
            &run(&[]),
            &Quarantine::default(),
            Path::new("results/panel"),
            &mut Vec::new(),
        ));
        assert!(error.contains("no scenarios"), "{error}");
    }

    #[test]
    fn a_run_whose_scenarios_pass_passes() {
        let passing = run(&[("a", Outcome::Passed), ("b", Outcome::Passed)]);
        assert!(driven(exited(0), passing.clone()).is_ok());
        assert!(
            verdict(
                "panel",
                Path::new("test_run.json"),
                &passing,
                &Quarantine::default(),
                Path::new("results/panel"),
                &mut Vec::new()
            )
            .is_ok()
        );
    }

    #[test]
    fn a_run_with_one_failing_scenario_fails_and_names_it() {
        let failing = run(&[("a", Outcome::Passed), ("b", failed("boom"))]);
        let error = refusal(verdict(
            "panel",
            Path::new("test_run.json"),
            &failing,
            &Quarantine::default(),
            Path::new("results/panel"),
            &mut Vec::new(),
        ));
        assert!(error.contains("1 of 2 cases failed: b"), "{error}");
    }
}
