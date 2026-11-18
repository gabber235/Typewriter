//! `cargo xtask e2e game`: the game requirements against real Minecraft clients on a stepped
//! Paper, which the game pool boots on this machine. Paper, the clients and the Gradle build that
//! starts them all run here, so the whole run is one heavy build. A Gradle of its own builds the
//! suite first and exits, so no compiler is alive while the suite runs. Every project's `gameTest` task
//! runs at once, so their test JVMs share the one pool, which retries failed requirements on its
//! warm clients and writes the run file. That file is the gate: Gradle's exit only adds a failure
//! the file cannot show.

use std::fs;
use std::io::Write;
use std::path::{Path, PathBuf};
use std::process::ExitStatus;
use std::time::{SystemTime, UNIX_EPOCH};

use anyhow::{Context as _, Result, anyhow, bail};

use super::{E2eArgs, take_turn};
use crate::lock;
use crate::results::{self, Quarantine, TestRun};
use crate::review::change::Change;
use crate::skirout::base::harness::v1::test_run::Runner;
use crate::{CommandExt as _, Context, evidence, generate, goldens};

/// Runs the selected game requirements and reports the run the game pool wrote.
pub(super) fn run(ctx: &Context, args: &E2eArgs) -> Result<()> {
    // The suite compiles against the generated Skir types, and the pool writes its run with them.
    generate::protocol(ctx)?;
    goldens::fetch_missing(ctx)?;
    let shown = Path::new(evidence::RESULTS).join("game");
    let evidence = ctx.root.join(&shown);
    let commit = ctx
        .tool(".", "git", &["rev-parse", "HEAD"])
        .output_text()?
        .trim()
        .to_owned();
    let quarantine = Quarantine::load(ctx)?;
    // The folders of the last runs' logs outlive the clear; `next_run_folder` keeps the newest.
    let _lock = take_turn(
        Path::new(lock::HEAVY_LOCK),
        "e2e game",
        &evidence,
        &[results::LOGS],
    )?;
    let file = evidence.join("test_run.json");
    // A requirement that covered a line the change added reruns in demo mode.
    let touched = evidence.join("touched.txt");
    fs::create_dir_all(&evidence)?;
    fs::write(
        &touched,
        touched_lines(&Change::load(ctx, args.base.as_deref())?),
    )
    .with_context(|| format!("cannot write {}", touched.display()))?;
    // The pool, Paper and every client log into a folder of this run's own.
    let logs = next_run_folder(&evidence.join(results::LOGS))?;
    // The run's pool writes this id into the run file, and its test JVMs connect only to a pool of
    // it, so a file or pool an earlier run left never passes for this one.
    let run_id = format!("{}-{}", now_millis(), std::process::id());
    let ran = Ran {
        file: file.clone(),
        run_id: run_id.clone(),
        gradle: build_then_run(
            |gradle| {
                ctx.tool(
                    "services",
                    "./gradlew",
                    &gradle.iter().map(String::as_str).collect::<Vec<_>>(),
                )
                .status()
                .context("cannot start Gradle for the game suite")
            },
            &gradle_args(args, &quarantine, &run_id, &file, &touched, &logs),
        )?,
        pool_log: logs.join("pool.log"),
    };
    let run = TestRun {
        commit,
        logs: logs.strip_prefix(&evidence)?.to_string_lossy().into_owned(),
        ..own_run(&ran)?
    };
    results::write(&run, &file)?;
    judge(
        &run,
        ran.gradle,
        &args.only,
        &quarantine,
        &shown,
        &mut std::io::stderr(),
    )?;
    println!(
        "game: {} requirements passed ({})",
        run.cases.len(),
        file.display()
    );
    Ok(())
}

/// One Gradle run of the game suite: where its run file belongs, how Gradle exited and where the
/// pool logs (in the run's own logs folder).
pub(crate) struct Ran {
    pub file: PathBuf,
    pub run_id: String,
    pub gradle: ExitStatus,
    pub pool_log: PathBuf,
}

/// Builds the suite in a Gradle of its own, then runs `suite` with `gradle`. The build's Gradle
/// exits before the suite starts, and the Kotlin compile daemons it started end with it, so no
/// compiler holds memory while the clients and Paper run. It never stops other daemons
/// (`--stop`): another worktree's build may share them.
pub(crate) fn build_then_run(
    mut gradle: impl FnMut(&[String]) -> Result<ExitStatus>,
    suite: &[String],
) -> Result<ExitStatus> {
    let build = [
        "--console=plain",
        "--parallel",
        "--no-daemon",
        "gameTestBuild",
    ]
    .map(str::to_owned);
    let built = gradle(&build)?;
    if !built.success() {
        bail!(
            "game: building the game suite failed with {built}, so no requirement ran; Gradle's output above says why"
        );
    }
    gradle(suite)
}

/// What Gradle runs: every `gameTest` task, writing the run file to `file` and its logs into
/// `logs`, with the selection, the repeat count and the quarantined requirements, which the test
/// JVMs need since they retry inside the run, and the file of lines the change touched, which
/// picks the demo reruns.
pub(crate) fn gradle_args(
    args: &E2eArgs,
    quarantine: &Quarantine,
    run_id: &str,
    file: &Path,
    touched: &Path,
    logs: &Path,
) -> Vec<String> {
    let mut gradle = vec![
        "--console=plain".to_owned(),
        "--parallel".to_owned(),
        "gameTest".to_owned(),
        format!("-Pplaytest.runId={run_id}"),
        format!("-Pplaytest.testRun={}", file.display()),
        format!("-Pplaytest.touched={}", touched.display()),
        format!("-Pplaytest.logs={}", logs.display()),
    ];
    for selected in &args.only {
        gradle.push("--tests".to_owned());
        gradle.push(test_pattern(selected));
    }
    if args.repeat.get() > 1 {
        gradle.push(format!("-Pplaytest.repeat={}", args.repeat));
    }
    let held = quarantine.held(&Runner::Game);
    if !held.is_empty() {
        gradle.push(format!("-Pplaytest.quarantine={}", held.join(",")));
    }
    gradle
}

/// The lines `change` added to services' Kotlin and Java sources, as the game requirements read
/// them (`playtest.touched`): one source per line, named as JaCoCo names it (`package/File.kt`),
/// then its added lines, separated by spaces.
pub(crate) fn touched_lines(change: &Change) -> String {
    change
        .files
        .iter()
        .filter(|file| file.path.starts_with("services") && !file.added.is_empty())
        .filter(|file| {
            file.path
                .extension()
                .is_some_and(|extension| extension == "kt" || extension == "java")
        })
        .filter_map(|file| {
            let path = file.path.to_string_lossy();
            let (_, source) = path
                .split_once("/kotlin/")
                .or_else(|| path.split_once("/java/"))?;
            let lines: Vec<String> = file.added.iter().map(u32::to_string).collect();
            Some(format!("{source} {}\n", lines.join(" ")))
        })
        .collect()
}

/// The testBalloon pattern that selects the test `selected` names: a test id (the requirement id
/// and its sentence) as it is, a requirement id with any sentence. `/` sets the pattern's element
/// separator, so the test's own name starts with the id.
fn test_pattern(selected: &str) -> String {
    if selected.contains(' ') {
        format!("/*/{selected}")
    } else {
        format!("/*/{selected} *")
    }
}

/// The run `ran` wrote. The build starts the run's pool before its first game test, and the pool
/// writes the run file as it takes up the run, so a run with no file never reached its pool. Fails,
/// pointing at the pool's log, when there is no run file, or the file holds another run.
pub(crate) fn own_run(ran: &Ran) -> Result<TestRun> {
    let log = ran.pool_log.display();
    if !ran.file.exists() {
        bail!(
            "game: the run wrote no run file at {}, so it proved nothing: no game test ran, so the build never started the pool, or the pool wrote nothing (Gradle exited with {}); see {log}",
            ran.file.display(),
            ran.gradle,
        );
    }
    let run = results::read(&ran.file)?;
    if run.run_id != ran.run_id {
        bail!(
            "game: {} holds the run {}, not this run {}, which wrote none (Gradle exited with {}); see {log}",
            ran.file.display(),
            run.run_id,
            ran.run_id,
            ran.gradle,
        );
    }
    Ok(run)
}

/// How many run folders `cargo xtask e2e game` keeps, the new one included.
const KEPT_RUNS: usize = 3;

/// A new, empty folder below `runs` for this run's logs, numbered one past the newest run folder
/// there; run folders beyond the last [`KEPT_RUNS`] go.
pub(crate) fn next_run_folder(runs: &Path) -> Result<PathBuf> {
    fs::create_dir_all(runs).with_context(|| format!("cannot create {}", runs.display()))?;
    let mut numbers: Vec<u64> = fs::read_dir(runs)?
        .filter_map(|entry| entry.ok()?.file_name().to_str()?.parse().ok())
        .collect();
    numbers.sort_unstable();
    let next = runs.join((numbers.last().copied().unwrap_or(0) + 1).to_string());
    let gone = numbers.len().saturating_sub(KEPT_RUNS - 1);
    for number in &numbers[..gone] {
        let old = runs.join(number.to_string());
        fs::remove_dir_all(&old).with_context(|| format!("cannot remove {}", old.display()))?;
    }
    fs::create_dir(&next).with_context(|| format!("cannot create {}", next.display()))?;
    Ok(next)
}

/// The suite's verdict on its `run`: whether it ran and ran to the end, each case under the run's
/// attempt policy and the quarantine, the selection, a run that ran no requirement, and a Gradle
/// failure that no failing case explains, such as a test JVM that ended before it ran its
/// requirements.
pub(crate) fn judge(
    run: &TestRun,
    gradle: ExitStatus,
    only: &[String],
    quarantine: &Quarantine,
    shown: &Path,
    out: &mut dyn Write,
) -> Result<()> {
    // A run cut short still lists the cases that finished, whose evidence stages.
    results::report(run, quarantine, Some(shown), out)?;
    results::selection_matches(run, only).map_err(|unmatched| anyhow!("game: {unmatched}"))?;
    if run.cases.is_empty() {
        bail!(
            "game: no requirements ran ({})",
            shown.join("test_run.json").display()
        );
    }
    if !gradle.success() {
        bail!(
            "game: every reported requirement passed, but Gradle failed with {gradle}; its output above says why"
        );
    }
    Ok(())
}

fn now_millis() -> i64 {
    SystemTime::now()
        .duration_since(UNIX_EPOCH)
        .map_or(0, |since| {
            i64::try_from(since.as_millis()).unwrap_or(i64::MAX)
        })
}

#[cfg(test)]
mod tests {
    use super::*;
    use crate::results::{AttemptPolicy, Outcome, RunEnd};
    use crate::test_support::{
        TempRoot, changed, e2e_args as parsed, exited, failed, files_below, game_run, quarantining,
        refusal,
    };

    #[test]
    fn a_game_run_gets_a_folder_of_its_own_and_only_the_last_three_runs_keep_theirs() {
        let root = TempRoot::new();
        for run in [1, 9, 10] {
            root.write(&format!("logs/{run}/pool.log"), "log");
        }

        let folder = next_run_folder(&root.path("logs")).unwrap();

        assert_eq!(folder, root.path("logs/11"));
        assert!(folder.is_dir());
        assert_eq!(
            files_below(&root.path("logs")),
            ["10/pool.log", "9/pool.log"]
        );
    }

    #[test]
    fn a_run_with_no_run_file_fails_and_points_at_the_pool_s_log_even_when_gradle_passed() {
        let root = TempRoot::new();
        let error = refusal(own_run(&Ran {
            file: root.path("results/game/test_run.json"),
            run_id: "run-2".to_owned(),
            gradle: exited(0),
            pool_log: root.path("pool.log"),
        }));
        assert!(error.contains("wrote no run file"), "{error}");
        assert!(error.contains("no game test ran"), "{error}");
        assert!(error.contains("the pool wrote nothing"), "{error}");
        assert!(
            error.contains(&root.path("pool.log").display().to_string()),
            "{error}"
        );
    }

    #[test]
    fn a_run_whose_selection_matched_no_requirement_fails_by_the_selection() {
        let run = TestRun {
            run_id: "run-2".to_owned(),
            runner: Runner::Game,
            end: RunEnd::Completed,
            ..TestRun::default()
        };
        for (only, says) in [
            (
                vec!["NOPE-1".to_owned()],
                "game: --only NOPE-1 matched nothing",
            ),
            (vec![], "no requirements ran"),
        ] {
            let error = refusal(judge(
                &run,
                exited(0),
                &only,
                &Quarantine::default(),
                Path::new("results/game"),
                &mut Vec::new(),
            ));
            assert!(error.contains(says), "{only:?}: {error}");
        }
    }

    #[test]
    fn a_run_file_another_run_wrote_fails_the_game_run_even_when_it_started_later() {
        let root = TempRoot::new();
        let file = root.path("results/game/test_run.json");
        let other = TestRun {
            run_id: "run-1".to_owned(),
            started_at_millis: 9_000,
            ..game_run(
                AttemptPolicy::RerunFailures(4),
                &[("PROBE-1", &[Outcome::Passed])],
            )
        };
        results::write(&other, &file).unwrap();
        let error = refusal(own_run(&Ran {
            file: file.clone(),
            run_id: "run-2".to_owned(),
            gradle: exited(0),
            pool_log: root.path("pool.log"),
        }));
        assert!(error.contains("run run-1, not this run run-2"), "{error}");
        assert!(error.contains(&file.display().to_string()), "{error}");
        assert!(
            error.contains(&root.path("pool.log").display().to_string()),
            "{error}"
        );
    }

    #[test]
    fn the_run_file_of_this_run_s_id_is_its_run_even_when_a_pool_began_it_before_xtask_counted() {
        let root = TempRoot::new();
        let file = root.path("results/game/test_run.json");
        let written = TestRun {
            run_id: "run-2".to_owned(),
            started_at_millis: 1_000,
            ..game_run(
                AttemptPolicy::RerunFailures(4),
                &[("PROBE-1", &[Outcome::Passed])],
            )
        };
        results::write(&written, &file).unwrap();
        let read = own_run(&Ran {
            file,
            run_id: "run-2".to_owned(),
            gradle: exited(0),
            pool_log: root.path("pool.log"),
        })
        .unwrap();
        assert_eq!(read, written);
    }

    #[test]
    fn a_run_the_game_could_not_run_fails_with_why_rather_than_as_a_run_of_nothing() {
        let unable = TestRun {
            end: RunEnd::CouldNotRun(
                "the game was not ready within 300 s; see paper.log".to_owned(),
            ),
            ..game_run(AttemptPolicy::RerunFailures(4), &[])
        };

        let error = refusal(judge(
            &unable,
            exited(1),
            &["PROBE-1".to_owned()],
            &Quarantine::default(),
            Path::new("results/game"),
            &mut Vec::new(),
        ));

        assert_eq!(
            error,
            "the run could not run: the game was not ready within 300 s; see paper.log"
        );
    }

    #[test]
    fn a_game_requirement_that_passed_on_a_retry_is_flaky_and_gates() {
        let flaky = game_run(
            AttemptPolicy::RerunFailures(4),
            &[
                ("PROBE-1", &[Outcome::Passed]),
                ("FLAKY-1", &[failed("missed"), Outcome::Passed]),
            ],
        );
        let error = refusal(judge(
            &flaky,
            exited(1),
            &[],
            &Quarantine::default(),
            Path::new("results/game"),
            &mut Vec::new(),
        ));
        assert!(
            error.contains("1 of 2 cases are flaky: FLAKY-1 the requirement"),
            "{error}"
        );
    }

    #[test]
    fn a_quarantined_game_requirement_that_failed_does_not_gate() {
        let held = game_run(
            AttemptPolicy::RerunFailures(4),
            &[
                ("PROBE-1", &[Outcome::Passed]),
                ("LEAK-1", &[failed("leaked")]),
            ],
        );
        let mut out = Vec::new();
        let judged = judge(
            &held,
            exited(0),
            &[],
            &quarantining("game/LEAK-1"),
            Path::new("results/game"),
            &mut out,
        );
        assert!(judged.is_ok(), "{judged:?}");
        let out = String::from_utf8(out).unwrap();
        assert!(out.contains("LEAK-1 the requirement: quarantined"), "{out}");
    }

    #[test]
    fn a_game_run_whose_cases_pass_while_gradle_failed_fails() {
        let passing = game_run(
            AttemptPolicy::RerunFailures(4),
            &[("PROBE-1", &[Outcome::Passed])],
        );
        let error = refusal(judge(
            &passing,
            exited(1),
            &[],
            &Quarantine::default(),
            Path::new("results/game"),
            &mut Vec::new(),
        ));
        assert!(error.contains("Gradle failed"), "{error}");
    }

    #[test]
    fn a_run_the_pool_never_ended_fails_as_cut_short_after_its_finished_cases() {
        let finished = TestRun {
            end: RunEnd::CutShort,
            logs: "logs/4".to_owned(),
            ..game_run(
                AttemptPolicy::RerunFailures(4),
                &[
                    ("PROBE-1", &[Outcome::Passed]),
                    ("WINDOW-1", &[Outcome::Passed]),
                ],
            )
        };

        let error = refusal(judge(
            &finished,
            exited(1),
            &[],
            &Quarantine::default(),
            Path::new("results/game"),
            &mut Vec::new(),
        ));

        assert!(error.contains("cut short after 2 cases"), "{error}");
        assert!(error.contains("logs in results/game/logs/4/"), "{error}");
    }

    #[test]
    fn a_game_selection_that_names_no_requirement_fails() {
        let passing = game_run(
            AttemptPolicy::Exactly(2),
            &[("PROBE-1", &[Outcome::Passed, Outcome::Passed])],
        );
        let error = refusal(judge(
            &passing,
            exited(0),
            &["PROBE-1".to_owned(), "PROBE-9".to_owned()],
            &Quarantine::default(),
            Path::new("results/game"),
            &mut Vec::new(),
        ));
        assert_eq!(
            error,
            "game: --only PROBE-9 matched nothing: no requirement or case has that id"
        );
    }

    #[test]
    fn gradle_gets_the_run_id_the_run_file_the_logs_folder_the_selection_the_repeat_and_the_quarantine()
     {
        let file = Path::new("/repo/.xtask/results/game/test_run.json");
        let args = parsed(&[
            "game",
            "--only",
            "WINDOW-1,HUNG-1 work still running fails",
            "--repeat",
            "3",
        ])
        .unwrap();
        let touched = Path::new("/repo/.xtask/results/game/touched.txt");
        let logs = Path::new("/repo/.xtask/results/game/logs/4");
        let gradle = gradle_args(
            &args,
            &quarantining("game/LEAK-1"),
            "run-7",
            file,
            touched,
            logs,
        );
        for expected in [
            "gameTest",
            "-Pplaytest.runId=run-7",
            "-Pplaytest.testRun=/repo/.xtask/results/game/test_run.json",
            "-Pplaytest.touched=/repo/.xtask/results/game/touched.txt",
            "-Pplaytest.logs=/repo/.xtask/results/game/logs/4",
            "-Pplaytest.repeat=3",
            "-Pplaytest.quarantine=LEAK-1",
        ] {
            assert!(
                gradle.contains(&expected.to_owned()),
                "{expected} in {gradle:?}"
            );
        }
        // testBalloon selects a test whose name is the id and its sentence, or the whole test id.
        let selection: Vec<_> = gradle
            .windows(2)
            .filter(|pair| pair[0] == "--tests")
            .map(|pair| pair[1].as_str())
            .collect();
        assert_eq!(
            selection,
            ["/*/WINDOW-1 *", "/*/HUNG-1 work still running fails"]
        );
        let plain = gradle_args(
            &parsed(&["game"]).unwrap(),
            &Quarantine::default(),
            "run-7",
            file,
            touched,
            logs,
        );
        assert!(
            !plain.iter().any(|arg| arg == "--tests"
                || ["repeat", "quarantine"]
                    .iter()
                    .any(|name| arg.starts_with(&format!("-Pplaytest.{name}=")))),
            "{plain:?}"
        );
    }

    #[test]
    fn the_touched_lines_count_from_the_base_the_run_names_or_else_the_nearest_one() {
        assert_eq!(
            parsed(&["game", "--base", "4e61bf097"])
                .unwrap()
                .base
                .as_deref(),
            Some("4e61bf097")
        );
        assert_eq!(parsed(&["game"]).unwrap().base, None);
    }

    #[test]
    fn a_game_run_clears_the_last_results_but_keeps_the_log_folders_of_earlier_runs() {
        let root = TempRoot::new();
        let (lock, evidence) = (root.path("heavy.lock"), root.path("results/game"));

        for _ in 0..2 {
            let turn = take_turn(&lock, "e2e game", &evidence, &[results::LOGS]).unwrap();
            fs::create_dir_all(&evidence).unwrap();
            fs::write(evidence.join("test_run.json"), "{}").unwrap();
            next_run_folder(&evidence.join(results::LOGS)).unwrap();
            drop(turn);
        }
        take_turn(&lock, "e2e game", &evidence, &[results::LOGS])
            .map(drop)
            .unwrap();

        assert!(evidence.join("logs/1").is_dir() && evidence.join("logs/2").is_dir());
        assert_eq!(
            files_below(&evidence),
            Vec::<String>::new(),
            "only the log folders survive"
        );
    }

    #[test]
    fn the_suite_is_built_in_a_gradle_of_its_own_that_ends_before_the_suite_starts() {
        let suite = vec!["gameTest".to_owned()];
        let mut calls = Vec::new();

        let status = build_then_run(
            |gradle: &[String]| {
                calls.push(gradle.to_vec());
                Ok(exited(0))
            },
            &suite,
        )
        .unwrap();

        assert!(status.success());
        assert_eq!(calls.len(), 2, "{calls:?}");
        let (build, run) = (&calls[0], &calls[1]);
        assert!(build.contains(&"gameTestBuild".to_owned()), "{build:?}");
        assert!(build.contains(&"--no-daemon".to_owned()), "{build:?}");
        // Another worktree's Gradle may share the daemons, so the build never stops them.
        assert!(!build.contains(&"--stop".to_owned()), "{build:?}");
        assert_eq!(run, &suite);
    }

    #[test]
    fn a_suite_that_fails_to_build_runs_no_requirement() {
        let mut calls = 0;

        let error = build_then_run(
            |_: &[String]| {
                calls += 1;
                Ok(exited(1))
            },
            &["gameTest".to_owned()],
        )
        .unwrap_err()
        .to_string();

        assert_eq!(calls, 1);
        assert!(error.contains("building the game suite failed"), "{error}");
        assert!(error.contains("no requirement ran"), "{error}");
    }

    #[test]
    fn touched_lines_name_each_changed_services_source_as_jacoco_does_with_its_added_lines() {
        let change = Change {
            base: "0".repeat(40),
            files: vec![
                changed(
                    "services/playtest/plugin/src/main/java/com/typewritermc/playtest/plugin/Probes.java",
                    &[12, 40],
                ),
                changed(
                    "services/playtest/framework/src/main/kotlin/com/typewritermc/playtest/Window.kt",
                    &[3],
                ),
                changed("services/playtest/plugin/build.gradle.kts", &[5]),
                changed("panel/lib/main.dart", &[1]),
                changed(
                    "services/playtest/plugin/src/main/java/com/typewritermc/playtest/plugin/Gone.java",
                    &[],
                ),
            ],
        };

        assert_eq!(
            touched_lines(&change),
            "com/typewritermc/playtest/plugin/Probes.java 12 40\n\
             com/typewritermc/playtest/Window.kt 3\n"
        );
    }
}
