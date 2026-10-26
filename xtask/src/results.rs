//! The results contract every runner writes (`skir-src/harness/v1/test_run.skir`) and the one
//! flake policy for every suite. A failed case is rerun once, and passing on the rerun records it
//! as flaky: visible, not gating. A case listed in [`QUARANTINE`] still runs and is reported but
//! does not gate; each entry names a reason and an issue, and every report lists the quarantined
//! cases so they cannot be forgotten.

use std::fs;
use std::io::Write;
use std::path::{Path, PathBuf};

use anyhow::{Context as _, Result, bail};
use serde::Deserialize;

use crate::Context;
use crate::skirout::base::harness::v1::test_run::Runner;
pub use crate::skirout::base::harness::v1::test_run::{Failure, Outcome, TestCase, TestRun};

/// The quarantine file, relative to the repository root.
const QUARANTINE: &str = "harness/quarantine.toml";

/// The cases that run and report but do not gate.
#[derive(Deserialize)]
#[serde(deny_unknown_fields)]
pub struct Quarantine {
    #[serde(default, rename = "case")]
    cases: Vec<QuarantinedCase>,
}

#[derive(Deserialize)]
#[serde(deny_unknown_fields)]
struct QuarantinedCase {
    /// `<runner>/<case id>`, for example `components/service::service_identity::rotates_keys`.
    id: String,
    reason: String,
    issue: u32,
}

impl Quarantine {
    pub fn load(ctx: &Context) -> Result<Self> {
        let path = ctx.root.join(QUARANTINE);
        let text =
            fs::read_to_string(&path).with_context(|| format!("cannot read {}", path.display()))?;
        toml::from_str(&text).with_context(|| format!("{} is invalid", path.display()))
    }

    fn entry(&self, runner: &Runner, case: &str) -> Option<&QuarantinedCase> {
        let id = format!("{}/{case}", runner_name(runner));
        self.cases.iter().find(|entry| entry.id == id)
    }
}

/// Applies the single rerun and the quarantine to a finished run. `rerun` runs exactly the given
/// case ids again; quarantined failures are not rerun, since their outcome is decided.
pub fn settle(
    run: TestRun,
    rerun: impl FnOnce(&[&str]) -> Result<TestRun>,
    quarantine: &Quarantine,
) -> Result<TestRun> {
    let failed: Vec<&str> = run
        .cases
        .iter()
        .filter(|case| {
            matches!(case.outcome, Outcome::Failed(_))
                && quarantine.entry(&run.runner, &case.id).is_none()
        })
        .map(|case| case.id.as_str())
        .collect();
    let second = if failed.is_empty() {
        None
    } else {
        Some(rerun(&failed)?)
    };
    let passed_again = |id: &str| {
        second.as_ref().is_some_and(|second| {
            second
                .cases
                .iter()
                .any(|case| case.id == id && case.outcome == Outcome::Passed)
        })
    };
    let runner = run.runner.clone();
    let cases = run
        .cases
        .into_iter()
        .map(|case| {
            let outcome = match case.outcome {
                Outcome::Failed(failure) if quarantine.entry(&runner, &case.id).is_some() => {
                    Outcome::Quarantined(failure)
                }
                Outcome::Failed(failure) if passed_again(&case.id) => Outcome::Flaky(failure),
                outcome => outcome,
            };
            TestCase { outcome, ..case }
        })
        .collect();
    Ok(TestRun { cases, ..run })
}

/// Reads the `TestRun` at `path`.
pub fn read(path: &Path) -> Result<TestRun> {
    let text =
        fs::read_to_string(path).with_context(|| format!("cannot read {}", path.display()))?;
    TestRun::serializer()
        .from_json(&text, skir_client::UnrecognizedValues::Drop)
        .map_err(|error| anyhow::anyhow!("{} is not a TestRun: {error:?}", path.display()))
}

/// Every `TestRun` under `dir`, at any depth, with the path it was read from.
pub fn read_all(dir: &Path) -> Result<Vec<(PathBuf, TestRun)>> {
    let mut runs = Vec::new();
    let mut pending = vec![dir.to_path_buf()];
    while let Some(dir) = pending.pop() {
        let Ok(entries) = fs::read_dir(&dir) else {
            continue;
        };
        for entry in entries {
            let path = entry?.path();
            if path.is_dir() {
                pending.push(path);
            } else if path
                .extension()
                .is_some_and(|extension| extension == "json")
            {
                let run = read(&path)?;
                runs.push((path, run));
            }
        }
    }
    runs.sort_by(|a, b| a.0.cmp(&b.0));
    Ok(runs)
}

/// Writes `run` as readable JSON.
pub fn write(run: &TestRun, path: &Path) -> Result<()> {
    if let Some(parent) = path.parent() {
        fs::create_dir_all(parent)
            .with_context(|| format!("cannot create {}", parent.display()))?;
    }
    let json = TestRun::serializer().to_json(run, skir_client::JsonFlavor::Readable);
    fs::write(path, json).with_context(|| format!("cannot write {}", path.display()))
}

/// Lists every case that did not plainly pass, then fails when any case failed.
pub fn report(run: &TestRun, quarantine: &Quarantine, out: &mut dyn Write) -> Result<()> {
    let mut failed = Vec::new();
    for case in &run.cases {
        match &case.outcome {
            Outcome::Failed(_) => {
                writeln!(out, "FAILED       {}", case.id)?;
                failed.push(case.id.as_str());
            }
            // An outcome this harness does not know cannot prove anything.
            Outcome::Unknown(_) => {
                writeln!(out, "FAILED       {} (unknown outcome)", case.id)?;
                failed.push(case.id.as_str());
            }
            Outcome::Flaky(_) => writeln!(out, "flaky        {} (passed on rerun)", case.id)?,
            Outcome::Quarantined(_) => match quarantine.entry(&run.runner, &case.id) {
                Some(entry) => writeln!(
                    out,
                    "quarantined  {}: {} (issue #{})",
                    case.id, entry.reason, entry.issue
                )?,
                None => writeln!(out, "quarantined  {}", case.id)?,
            },
            Outcome::OverBudget(millis) => {
                writeln!(out, "over budget  {} by {millis} ms", case.id)?;
            }
            Outcome::Passed => {}
        }
    }
    if !failed.is_empty() {
        bail!(
            "{} of {} cases failed: {}",
            failed.len(),
            run.cases.len(),
            failed.join(", ")
        );
    }
    Ok(())
}

/// The name a quarantine entry and the evidence section use for `runner`.
pub fn runner_name(runner: &Runner) -> &'static str {
    match runner {
        Runner::Components => "components",
        Runner::Schema => "schema",
        Runner::Panel => "panel",
        Runner::PanelWeb => "panel-web",
        Runner::Step => "step",
        Runner::Unknown(_) => "unknown",
    }
}
