//! `cargo xtask e2e`: the end to end suites. Each suite starts the worktree's panel stack, drives
//! the panel's `integration_test` scenarios through `flutter drive` inside the evidence recorder
//! and writes their `TestRun`, every attempt included, to `.xtask/results/<suite>`, where the
//! change report and the evidence section read it. Each attempt keeps its clips, screenshots and
//! stamped drive output under `attempts/<n>/` beside it, and a failed attempt also leaves a local
//! failure folder there ([`failures`]). `--only` selects scenarios and `--repeat` runs each of
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
use crate::process::Supervisor;
use crate::results::{self, AttemptPolicy, Outcome, Quarantine, TestCase, TestRun};
use crate::skirout::base::harness::v1::test_run::Runner;
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
    only: Vec<String>,
    /// Attempts per selected scenario, instead of one attempt plus a rerun of failures.
    #[arg(long, default_value_t = NonZeroU32::MIN)]
    repeat: NonZeroU32,
}

impl E2eArgs {
    /// One attempt and a rerun of failures, or exactly `--repeat` attempts.
    fn policy(&self) -> AttemptPolicy {
        match self.repeat.get() {
            1 => AttemptPolicy::RerunFailures(2),
            n => AttemptPolicy::Exactly(i32::try_from(n).unwrap_or(i32::MAX)),
        }
    }
}

/// An end to end suite.
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
    fn name(self) -> &'static str {
        match self {
            Self::Panel => "panel",
            Self::PanelWeb => "panel-web",
            Self::Full => "full",
        }
    }

    /// The whole run of one attempt once the stack is up: the app build, the scenarios and
    /// one rerun.
    fn budget(self) -> Duration {
        Duration::from_secs(30 * 60)
    }
}

/// Runs the selected scenarios of the suite and reports them.
pub fn run(ctx: &Context, args: &E2eArgs) -> Result<()> {
    match args.suite {
        Suite::Full => {
            let ci = cluster::create_ci(ctx, &secrets::Ci::load()?)?;
            deploy::deploy_ci(ctx, &ci)?;
            scenarios(ctx, args, Suite::PanelWeb, &Target::Cluster(Box::new(ci)))
        }
        suite => scenarios(ctx, args, suite, &Target::Stack),
    }
}

/// What the scenarios run against.
pub(crate) enum Target {
    /// A fresh worktree stack, up for the run only.
    Stack,
    /// The CI cluster `cargo xtask deploy ci` deployed to, with this worktree's organization and
    /// Realm host on top.
    Cluster(Box<CiCluster>),
}

/// Runs `suite`'s selected scenarios against `target`.
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

fn scenarios(ctx: &Context, args: &E2eArgs, suite: Suite, target: &Target) -> Result<()> {
    // The panel compiles against the generated Skir and build_runner sources.
    generate::generate(ctx, None)?;
    let name = match target {
        Target::Stack => suite.name().to_owned(),
        Target::Cluster(_) => format!("{}-{}", Suite::Full.name(), suite.name()),
    };
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
    // Both targets bring up the same organization and Realm host; only the backend differs.
    let spec = match target {
        Target::Stack => typewriter::panel(),
        Target::Cluster(ci) => typewriter::ci_cluster_panel(ci),
    };
    let budget = suite.budget() * args.repeat.get();
    let keep = ctx.root.join(STACK_EVIDENCE).join(&name);
    let (mut run, stack) = stack::run_keeping_evidence(ctx, &spec, budget, &keep, |stack| {
        let _lock = lock()?;
        // Both drives share the stack, so each attempt borrows it in turn.
        let stack = std::cell::RefCell::new(stack);
        results::attempts(args.policy(), &args.only, &quarantine, |n, ids| {
            attempt(
                n,
                ids,
                target,
                |n, ids| {
                    let stack = &mut **stack.borrow_mut();
                    drive(ctx, stack, suite, target, &defines, &evidence, n, ids)
                },
                |n| {
                    let stack = &mut **stack.borrow_mut();
                    sign_in_journey(ctx, stack, target, &defines, &evidence, n)
                },
            )
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

/// Attempt `n` of the scenarios `only` selects (every scenario when empty): one `flutter drive`
/// writing its evidence to `attempts/<n>/` of the suite's `evidence` folder. Its artifact paths
/// are made relative to `evidence`, where the folded run is written.
#[allow(clippy::too_many_arguments)]
fn drive(
    ctx: &Context,
    supervisor: &mut dyn Supervisor,
    suite: Suite,
    target: &Target,
    defines_file: &Path,
    evidence: &Path,
    n: u32,
    only: &[String],
) -> Result<TestRun> {
    let folder = Drive::Scenarios.folder(n);
    let mut run = drive_once(
        ctx,
        supervisor,
        suite,
        target,
        defines_file,
        &evidence.join(&folder),
        only,
    )?;
    for artifact in run
        .cases
        .iter_mut()
        .flat_map(|case| &mut case.attempts)
        .flat_map(|attempt| &mut attempt.artifacts)
    {
        artifact.path = folder.join(&artifact.path).display().to_string();
    }
    Ok(run)
}

/// One `flutter drive` run writing its `TestRun` to `out`; a non empty `only` limits it to those
/// scenario or requirement ids. A failing scenario is a result, not an error; a drive that fails
/// without reporting a failing scenario is one.
fn drive_once(
    ctx: &Context,
    supervisor: &mut dyn Supervisor,
    suite: Suite,
    target: &Target,
    defines_file: &Path,
    out: &Path,
    only: &[String],
) -> Result<TestRun> {
    let mut command: Vec<String> = [
        "flutter",
        "drive",
        "--driver=test_driver/integration_test.dart",
        "--target=integration_test/all_test.dart",
    ]
    .map(String::from)
    .into();
    command.push(defines(defines_file));
    if !only.is_empty() {
        command.push(format!(
            "--dart-define=SCENARIOS={}",
            serde_json::to_string(only)?
        ));
    }
    let recorded = match suite {
        Suite::Panel => {
            command.extend(["-d".into(), desktop_device()?.into()]);
            let recorded = UNSIGNED_MACOS.iter().fold(
                Recorded::video(command).env(
                    "FLUTTER_XCODE_CODE_SIGN_ENTITLEMENTS",
                    ctx.root.join(UNSIGNED_ENTITLEMENTS).display().to_string(),
                ),
                |recorded, (setting, value)| {
                    recorded.env(&format!("FLUTTER_XCODE_{setting}"), *value)
                },
            );
            NIX_TOOLCHAIN
                .iter()
                .fold(recorded, |recorded, key| recorded.env_remove(key))
        }
        Suite::PanelWeb => in_chrome(command, target)?,
        Suite::Full => unreachable!("the full suite drives the panel web scenarios"),
    }
    .in_dir("panel")
    .env("EVIDENCE_DIR", out.display().to_string())
    .log_to(out.join(failures::DRIVE_LOG));
    // Without a results file the scenarios never ran (the build or the launch failed), and
    // recording fails.
    let (run, exit) = evidence::record_with(ctx, out, recorded, supervisor)?;
    driven(exit, run)
}

/// `flutter drive` `command` in Chrome through chromedriver, serving the panel where `target`'s
/// identity provider accepts it.
fn in_chrome(mut command: Vec<String>, target: &Target) -> Result<Recorded> {
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
    if let Target::Cluster(ci) = target {
        command.push(format!("--web-port={}", ci.panel_port()));
    }
    Ok(Recorded::video(command).with(vec!["chromedriver".into(), format!("--port={port}")]))
}

/// The requirement the full suite's sign in journey proves.
pub(crate) const JOURNEY: &str = "AUTH-2";

/// The folder of a suite's evidence its attempts write to, one `attempts/<n>/` each; run
/// evidence, never another run (`results::RUN_EVIDENCE`), so the journey's own `test_run.json`
/// inside it is read only through the suite's run.
pub(crate) const ATTEMPTS: &str = "attempts";

/// One of the two drives an attempt of the full suite makes.
#[derive(Clone, Copy)]
enum Drive {
    /// The scenarios' `flutter drive`, writing to `attempts/<n>/`.
    Scenarios,
    /// The sign in journey's `flutter drive`, writing to `attempts/<n>/journey/`.
    Journey,
}

impl Drive {
    /// The drive that reported `case`.
    fn of(case: &TestCase) -> Self {
        if case.requirement.as_deref() == Some(JOURNEY) {
            Self::Journey
        } else {
            Self::Scenarios
        }
    }

    /// Where the drive keeps attempt `n`'s evidence, relative to the suite's evidence folder.
    fn folder(self, n: u32) -> PathBuf {
        let attempt = Path::new(ATTEMPTS).join(n.to_string());
        match self {
            Self::Scenarios => attempt,
            Self::Journey => attempt.join("journey"),
        }
    }
}

/// Where attempt `n` of `case` keeps its evidence, relative to the suite's evidence folder: the
/// one layout the drives, the failure folders and the report all read.
pub(crate) fn attempt_folder(case: &TestCase, n: u32) -> PathBuf {
    Drive::of(case).folder(n)
}

/// Attempt `n` of the cases `ids` selects (every case when empty): `scenarios(n, ids)` drives the
/// scenario ids among them and `journey(n)` the sign in journey when selected, folded into one
/// run, so the journey is attempted, rerun and repeated like every scenario.
pub(crate) fn attempt(
    n: u32,
    ids: &[String],
    target: &Target,
    mut scenarios: impl FnMut(u32, &[String]) -> Result<TestRun>,
    mut journey: impl FnMut(u32) -> Result<TestRun>,
) -> Result<TestRun> {
    let selection = Selection::of(ids, target);
    let mut run = match &selection.scenarios {
        Some(ids) => scenarios(n, ids)?,
        None => TestRun {
            runner: Runner::PanelWeb,
            ..TestRun::default()
        },
    };
    if selection.journey {
        run.cases.extend(journey(n)?.cases);
    }
    Ok(run)
}

/// What one run of a suite drives, from its `--only` ids.
struct Selection {
    /// The scenario ids to drive (every scenario when empty), or none when only the journey was
    /// selected.
    scenarios: Option<Vec<String>>,
    /// Whether the sign in journey runs, which only the CI cluster target has.
    journey: bool,
}

impl Selection {
    /// Every scenario and, on the CI cluster, the journey when `only` is empty; otherwise the ids
    /// `only` names, the journey's requirement or case id taken out for the journey.
    fn of(only: &[String], target: &Target) -> Self {
        if let Target::Stack = target {
            return Self {
                scenarios: Some(only.to_vec()),
                journey: false,
            };
        }
        let is_journey = |id: &String| id == JOURNEY || id.starts_with(&format!("[{JOURNEY}] "));
        let scenarios: Vec<String> = only.iter().filter(|id| !is_journey(id)).cloned().collect();
        Self {
            journey: only.is_empty() || only.iter().any(is_journey),
            scenarios: (only.is_empty() || !scenarios.is_empty()).then_some(scenarios),
        }
    }
}

/// The fixture user the sign in journey signs in as.
const JOURNEY_USER: &str = "ada";

/// The full suite's sign in journey through the CI cluster's Authentik pages, which no scenario
/// can drive (`panel/test_driver/sign_in_journey_test.dart`), signing in as [`JOURNEY_USER`]
/// with the password of its sign in form. Attempt `n`'s one case and its evidence land in its
/// journey folder ([`Drive::Journey`]) of the suite's `evidence` folder.
fn sign_in_journey(
    ctx: &Context,
    supervisor: &mut dyn Supervisor,
    target: &Target,
    defines_file: &Path,
    evidence: &Path,
    n: u32,
) -> Result<TestRun> {
    let Target::Cluster(ci) = target else {
        bail!("only the CI cluster has the sign in journey's Authentik pages");
    };
    let folder = Drive::Journey.folder(n);
    let out = evidence.join(&folder);
    let password = ci
        .test_user_passwords(ctx)?
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
    .chain([defines(defines_file)])
    .collect();
    let recorded = in_chrome(command, target)?
        .in_dir("panel")
        .env("EVIDENCE_DIR", out.display().to_string())
        .env("STACK_SIGN_IN_USERNAME", JOURNEY_USER)
        .env("STACK_SIGN_IN_PASSWORD", password)
        .log_to(out.join(failures::DRIVE_LOG));
    let (run, exit) = evidence::record_with(ctx, &out, recorded, supervisor)?;
    let mut run = driven(exit, run)?;
    for artifact in run
        .cases
        .iter_mut()
        .flat_map(|case| &mut case.attempts)
        .flat_map(|attempt| &mut attempt.artifacts)
    {
        artifact.path = folder.join(&artifact.path).display().to_string();
    }
    Ok(run)
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
        ci_cluster, e2e_args as parsed, exited, failed, full_suite_attempts, refusal, report_text,
        requirement_run, run,
    };

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
    fn an_attempt_drives_the_scenarios_and_the_journey_its_selection_names() {
        let cases = [
            (
                Target::Cluster(Box::new(ci_cluster())),
                "",
                vec!["1 scenarios ", "1 journey"],
            ),
            (Target::Stack, "", vec!["1 scenarios "]),
            (
                Target::Cluster(Box::new(ci_cluster())),
                "AUTH-2",
                vec!["1 journey"],
            ),
            (
                Target::Cluster(Box::new(ci_cluster())),
                "[AUTH-2] Signs in",
                vec!["1 journey"],
            ),
            (
                Target::Cluster(Box::new(ci_cluster())),
                "CONN-1,AUTH-2",
                vec!["1 scenarios CONN-1", "1 journey"],
            ),
            (
                Target::Cluster(Box::new(ci_cluster())),
                "CONN-1",
                vec!["1 scenarios CONN-1"],
            ),
        ];
        for (target, only, expected) in cases {
            let only: Vec<String> = only
                .split(',')
                .filter(|id| !id.is_empty())
                .map(String::from)
                .collect();
            let (run, drives) =
                full_suite_attempts(&target, AttemptPolicy::Exactly(1), &only, |_, _| {
                    Outcome::Passed
                });
            assert_eq!(drives, expected, "{only:?}");
            let journey_reported = run
                .cases
                .iter()
                .any(|case| case.requirement.as_deref() == Some(JOURNEY));
            assert_eq!(
                journey_reported,
                expected.contains(&"1 journey"),
                "{only:?}"
            );
        }
    }

    #[test]
    fn a_selection_repeated_on_the_command_line_attempts_each_case_exactly_that_often() {
        let args = parsed(&["full", "--repeat", "20", "--only", "CONN-1,AUTH-2"]).unwrap();
        let (folded, drives) = full_suite_attempts(
            &Target::Cluster(Box::new(ci_cluster())),
            args.policy(),
            &args.only,
            |_, _| Outcome::Passed,
        );
        let expected: Vec<String> = (1..=20)
            .flat_map(|n| [format!("{n} scenarios CONN-1"), format!("{n} journey")])
            .collect();
        assert_eq!(drives, expected);
        assert_eq!(folded.cases.len(), 2);
        assert!(folded.cases.iter().all(|case| case.attempts.len() == 20));
    }

    #[test]
    fn a_plain_run_attempts_a_failed_journey_again_until_it_passes() {
        let args = parsed(&["full"]).unwrap();
        let (folded, drives) = full_suite_attempts(
            &Target::Cluster(Box::new(ci_cluster())),
            args.policy(),
            &args.only,
            |n, requirement| {
                if n == 1 && requirement == JOURNEY {
                    failed("boom")
                } else {
                    Outcome::Passed
                }
            },
        );
        assert_eq!(drives, ["1 scenarios ", "1 journey", "2 journey"]);
        let journey = folded
            .cases
            .iter()
            .find(|case| case.requirement.as_deref() == Some(JOURNEY))
            .unwrap();
        assert!(matches!(journey.attempts[1].outcome, Outcome::Passed));
    }

    #[test]
    fn the_report_points_a_failed_journey_at_its_own_attempt_folder() {
        let mut journey = requirement_run(JOURNEY, "[AUTH-2] Signs in", failed("boom"));
        journey.cases[0].attempts.extend(
            requirement_run(JOURNEY, "[AUTH-2] Signs in", Outcome::Passed).cases[0]
                .attempts
                .clone(),
        );
        journey.attempt_policy = AttemptPolicy::RerunFailures(2);
        let (result, out) = report_text(&journey, &Quarantine::default());
        assert!(result.is_ok());
        assert_eq!(
            out,
            "[AUTH-2] Signs in: flaky, failed 1 of 2 attempts (1); see results/panel/attempts/1/journey/\n"
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
