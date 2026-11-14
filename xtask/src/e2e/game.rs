//! `cargo xtask e2e game`: the game requirements against real Minecraft clients on a stepped
//! Paper, which the game pool boots on this machine. Paper, the clients and the Gradle build that
//! starts them all run here, so the whole run is one heavy build. Every project's `gameTest` task
//! runs at once, so their test JVMs share the one pool, which retries failed requirements on its
//! warm clients and writes the run file. That file is the gate: Gradle's exit only adds a failure
//! the file cannot show.

use std::fs;
use std::io::Write;
use std::path::{Path, PathBuf};
use std::process::ExitStatus;
use std::time::{SystemTime, UNIX_EPOCH};

use anyhow::{Context as _, Result, bail};

use super::{E2eArgs, take_turn, verdict};
use crate::lock;
use crate::results::{self, Quarantine, TestRun};
use crate::skirout::base::harness::v1::test_run::Runner;
use crate::{CommandExt as _, Context, evidence, generate};

/// The game pool's log, relative to the repository root.
const POOL_LOG: &str = "services/build/playtest/pool/pool.log";

/// Runs the selected game requirements and reports the run the game pool wrote.
pub(super) fn run(ctx: &Context, args: &E2eArgs) -> Result<()> {
    // The pool writes its run with the generated Skir types.
    generate::generate(ctx, None)?;
    let shown = Path::new(evidence::RESULTS).join("game");
    let evidence = ctx.root.join(&shown);
    let commit = ctx
        .tool(".", "git", &["rev-parse", "HEAD"])
        .output_text()?
        .trim()
        .to_owned();
    let quarantine = Quarantine::load(ctx)?;
    let _lock = take_turn(Path::new(lock::HEAVY_LOCK), "e2e game", &evidence)?;
    let file = evidence.join("test_run.json");
    let ran = Ran {
        file: file.clone(),
        started_millis: now_millis(),
        gradle: ctx
            .tool(
                "services",
                "./gradlew",
                &gradle_args(args, &quarantine, &file)
                    .iter()
                    .map(String::as_str)
                    .collect::<Vec<_>>(),
            )
            .status()
            .context("cannot start Gradle for the game suite")?,
        pool_log: ctx.root.join(POOL_LOG),
    };
    let run = TestRun {
        commit,
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

/// One Gradle run of the game suite: where its run file belongs, when it started, how Gradle
/// exited and where the pool logs.
pub(crate) struct Ran {
    pub file: PathBuf,
    pub started_millis: i64,
    pub gradle: ExitStatus,
    pub pool_log: PathBuf,
}

/// What Gradle runs: every `gameTest` task, writing the run file to `file`, with the selection,
/// the repeat count and the quarantined requirements, which the test JVMs need since they retry
/// inside the run.
pub(crate) fn gradle_args(args: &E2eArgs, quarantine: &Quarantine, file: &Path) -> Vec<String> {
    let mut gradle = vec![
        "--console=plain".to_owned(),
        "--parallel".to_owned(),
        "gameTest".to_owned(),
        format!("-Pplaytest.testRun={}", file.display()),
    ];
    if !args.only.is_empty() {
        gradle.push(format!("-Pplaytest.only={}", args.only.join(",")));
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

/// The run `ran` wrote. Fails, with the cause and the pool's log, when there is none or the file
/// belongs to a run that started before this one: a test JVM of an earlier run that outlived it
/// still ends its session and writes there.
pub(crate) fn own_run(ran: &Ran) -> Result<TestRun> {
    let log = ran.pool_log.display();
    if !ran.file.exists() {
        bail!(
            "game: the run wrote no run file at {} (Gradle exited with {}): {}; see {log}",
            ran.file.display(),
            ran.gradle,
            pool_cause(ran)
        );
    }
    let run = results::read(&ran.file)?;
    if run.started_at_millis < ran.started_millis {
        bail!(
            "game: {} holds another run, which started at {} ms, before this one at {} ms; this run \
             wrote none (Gradle exited with {}): {}; see {log}",
            ran.file.display(),
            run.started_at_millis,
            ran.started_millis,
            ran.gradle,
            pool_cause(ran)
        );
    }
    Ok(run)
}

/// Why the pool wrote no run file for `ran`, as the pool logged it during the run.
fn pool_cause(ran: &Ran) -> String {
    let logged_since = fs::metadata(&ran.pool_log)
        .and_then(|meta| meta.modified())
        .ok()
        .and_then(|modified| modified.duration_since(UNIX_EPOCH).ok())
        .and_then(|since| i64::try_from(since.as_millis()).ok())
        .is_some_and(|modified| modified >= ran.started_millis);
    let failed = logged_since
        .then(|| fs::read_to_string(&ran.pool_log).ok())
        .flatten()
        .and_then(|log| {
            log.lines().rev().find_map(|line| {
                line.split_once("The game failed: ")
                    .map(|(_, why)| why.to_owned())
            })
        });
    failed.unwrap_or_else(|| "no test JVM ended its session with the game pool".to_owned())
}

/// The suite's verdict on its `run`: each case under the run's attempt policy and the quarantine,
/// the selection, and a Gradle failure that no failing case explains, such as a test JVM that
/// ended before it ran its requirements.
pub(crate) fn judge(
    run: &TestRun,
    gradle: ExitStatus,
    only: &[String],
    quarantine: &Quarantine,
    shown: &Path,
    out: &mut dyn Write,
) -> Result<()> {
    results::selection_matches(run, only)?;
    verdict(
        "game",
        &shown.join("test_run.json"),
        run,
        quarantine,
        shown,
        out,
    )?;
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
    use crate::results::{AttemptPolicy, Outcome};
    use crate::test_support::{
        TempRoot, e2e_args as parsed, exited, failed, game_run, quarantining, refusal,
    };

    #[test]
    fn a_game_run_that_wrote_no_run_file_fails_with_the_pool_s_cause_and_its_log() {
        let root = TempRoot::new();
        root.write(
            "pool.log",
            "Attempt 1: PROBE-1 on gv-1\nThe game failed: the game was not ready within 300 s; see paper.log\n",
        );
        let error = refusal(own_run(&Ran {
            file: root.path("results/game/test_run.json"),
            started_millis: 0,
            gradle: exited(1),
            pool_log: root.path("pool.log"),
        }));
        assert!(error.contains("wrote no run file"), "{error}");
        assert!(
            error.contains("the game was not ready within 300 s; see paper.log"),
            "{error}"
        );
        assert!(
            error.contains(&root.path("pool.log").display().to_string()),
            "{error}"
        );
    }

    #[test]
    fn a_game_run_that_wrote_no_run_file_and_started_no_pool_says_no_session_reached_it() {
        let root = TempRoot::new();
        let error = refusal(own_run(&Ran {
            file: root.path("results/game/test_run.json"),
            started_millis: 0,
            gradle: exited(1),
            pool_log: root.path("pool.log"),
        }));
        assert!(
            error.contains("no test JVM ended its session with the game pool"),
            "{error}"
        );
        assert!(
            error.contains(&root.path("pool.log").display().to_string()),
            "{error}"
        );
    }

    #[test]
    fn a_run_file_a_run_that_started_earlier_wrote_fails_the_game_run() {
        let root = TempRoot::new();
        let file = root.path("results/game/test_run.json");
        let earlier = TestRun {
            started_at_millis: 1_000,
            ..game_run(
                AttemptPolicy::RerunFailures(4),
                &[("PROBE-1", &[Outcome::Passed])],
            )
        };
        results::write(&earlier, &file).unwrap();
        let error = refusal(own_run(&Ran {
            file: file.clone(),
            started_millis: 2_000,
            gradle: exited(0),
            pool_log: root.path("pool.log"),
        }));
        assert!(error.contains("another run"), "{error}");
        assert!(error.contains(&file.display().to_string()), "{error}");
        assert!(
            error.contains(&root.path("pool.log").display().to_string()),
            "{error}"
        );
    }

    #[test]
    fn the_run_file_this_run_wrote_is_its_run() {
        let root = TempRoot::new();
        let file = root.path("results/game/test_run.json");
        let written = TestRun {
            started_at_millis: 2_500,
            ..game_run(
                AttemptPolicy::RerunFailures(4),
                &[("PROBE-1", &[Outcome::Passed])],
            )
        };
        results::write(&written, &file).unwrap();
        let read = own_run(&Ran {
            file,
            started_millis: 2_000,
            gradle: exited(0),
            pool_log: root.path("pool.log"),
        })
        .unwrap();
        assert_eq!(read, written);
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
        assert_eq!(error, "no case matches PROBE-9");
    }

    #[test]
    fn gradle_gets_the_run_file_the_selection_the_repeat_and_the_quarantine() {
        let file = Path::new("/repo/.xtask/results/game/test_run.json");
        let args = parsed(&["game", "--only", "WINDOW-1,HUNG-1", "--repeat", "3"]).unwrap();
        let gradle = gradle_args(&args, &quarantining("game/LEAK-1"), file);
        for expected in [
            "gameTest",
            "-Pplaytest.testRun=/repo/.xtask/results/game/test_run.json",
            "-Pplaytest.only=WINDOW-1,HUNG-1",
            "-Pplaytest.repeat=3",
            "-Pplaytest.quarantine=LEAK-1",
        ] {
            assert!(
                gradle.contains(&expected.to_owned()),
                "{expected} in {gradle:?}"
            );
        }
        let plain = gradle_args(&parsed(&["game"]).unwrap(), &Quarantine::default(), file);
        assert!(
            !plain.iter().any(|arg| ["only", "repeat", "quarantine"]
                .iter()
                .any(|name| arg.starts_with(&format!("-Pplaytest.{name}=")))),
            "{plain:?}"
        );
    }
}
