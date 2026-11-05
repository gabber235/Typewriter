//! `cargo xtask review`: the change report, the detectors behind it, and the investigation tools
//! the typewriter-review skill uses. Every command compares the working tree with a base commit.

mod change;
mod coverage;
mod detectors;
mod index;
mod investigate;
mod report;
mod sarif;
mod tests;
pub mod verdict;

pub(crate) use self::coverage::walk as files_in;
pub use self::coverage::{COVERAGE_DIR, stamp as stamp_coverage};

use std::fs::{self, File};
use std::io::Write as _;
use std::path::PathBuf;

use anyhow::{Context as _, Result, bail};
use clap::{Args, Subcommand};

use self::detectors::DETECTORS;
use self::investigate::InvestigateCommand;
use self::report::{ChangeContext, ChangeReport, Severity};
use crate::{CommandExt as _, Context};

pub const DESCRIBE: &str = "cargo xtask review gate: project rules and new clones on changed lines";

/// Where `report` writes the SARIF log and the report as JSON, relative to the repository root.
const SARIF: &str = ".xtask/review/review.sarif";
const REPORT: &str = ".xtask/review/report.json";

#[derive(Args)]
pub struct ReviewArgs {
    /// The ref the working tree is compared with, through its merge base with HEAD. Defaults to
    /// the base CI uses: the pull request's base branch, or before a pull request exists, the
    /// remote branch HEAD grew from most recently.
    #[arg(long, global = true)]
    base: Option<String>,
    /// Prints the facts as JSON instead of text.
    #[arg(long, global = true)]
    json: bool,
    #[command(subcommand)]
    command: ReviewCommand,
}

#[derive(Subcommand)]
pub enum ReviewCommand {
    /// The report as compact markdown, change shape first; writes .xtask/review/review.sarif and
    /// .xtask/review/report.json.
    Report,
    /// Gating detectors only (the `quality` check step).
    Gate,
    /// Questions about the change and the code around it.
    #[command(flatten)]
    Investigate(InvestigateCommand),
    /// Publishes the reviewer's verdict for the current head commit into the pull request description.
    Verdict { file: PathBuf },
    /// Fails unless the pull request's verdict covers `head`: the same commit, or a commit with
    /// the same changes. The `Review` workflow's one job.
    Covered {
        #[arg(long)]
        pr: u64,
        #[arg(long)]
        head: String,
    },
}

pub fn run(ctx: &Context, args: ReviewArgs) -> Result<()> {
    let base = args.base.as_deref();
    match args.command {
        ReviewCommand::Report => report(ctx, base, args.json),
        ReviewCommand::Gate => {
            let findings = gate_findings(ctx, base)?;
            print!("{findings}");
            Ok(())
        }
        ReviewCommand::Investigate(command) => investigate::run(ctx, command, base, args.json),
        ReviewCommand::Verdict { file } => verdict::publish(ctx, &file),
        ReviewCommand::Covered { pr, head } => verdict::require_covered(ctx, pr, &head, base),
    }
}

/// Every path the change from `base` touches, both ends of a move, legacy references and generated
/// output left out: what `check --list --base` selects areas from.
pub fn changed_paths(ctx: &Context, base: &str) -> Result<Vec<PathBuf>> {
    let change = change::Change::load(ctx, Some(base))?;
    Ok(change
        .files
        .into_iter()
        .flat_map(|file| std::iter::once(file.path).chain(file.from))
        .collect())
}

/// Builds the report, writes the SARIF log and prints the report.
fn report(ctx: &Context, base: Option<&str>, json: bool) -> Result<()> {
    let change = ChangeContext::load(ctx, base)?;
    let report = ChangeReport::build(ctx, &change)?;
    let json_report = serde_json::to_string_pretty(&report)?;
    for (path, text) in [
        (
            SARIF,
            serde_json::to_string_pretty(&sarif::to_sarif(&report, &change.change))?,
        ),
        (REPORT, json_report.clone()),
    ] {
        let path = ctx.root.join(path);
        if let Some(parent) = path.parent() {
            fs::create_dir_all(parent)
                .with_context(|| format!("cannot create {}", parent.display()))?;
        }
        fs::write(&path, text).with_context(|| format!("cannot write {}", path.display()))?;
    }
    if json {
        println!("{json_report}");
    } else {
        print!("{}", report.markdown());
    }
    Ok(())
}

/// Where the project rules and their tests live, relative to the repository root (sgconfig.yml).
const RULES: &str = "rules";
const RULE_TESTS: &str = "rule-tests";

/// The `quality` step: fails when a project rule fails its tests or has none, or when a gating
/// detector finds anything on a changed line. The rule tests run first, since a rule that does not
/// load finds nothing and would otherwise pass silently.
pub fn gate(ctx: &Context, log: &File) -> Result<()> {
    ctx.tool(".", "ast-grep", &["test", "--skip-snapshot-tests"])
        .log_output(Some(log))?
        .run()?;
    every_rule_has_tests(ctx)?;
    let findings = gate_findings(ctx, None)?;
    write!(&*log, "{findings}")?;
    Ok(())
}

/// Fails when a rule id in `rules/` has no `rule-tests/<id>-test.yml`. A rule file may hold several
/// rules as YAML documents; each document's top level `id:` names one.
fn every_rule_has_tests(ctx: &Context) -> Result<()> {
    let rules = ctx.root.join(RULES);
    let mut files: Vec<PathBuf> = fs::read_dir(&rules)
        .with_context(|| format!("cannot list {}", rules.display()))?
        .map(|entry| entry.map(|entry| entry.path()))
        .collect::<Result<_, _>>()?;
    files.sort();
    let mut untested = Vec::new();
    for file in files
        .iter()
        .filter(|file| file.extension().is_some_and(|ext| ext == "yml"))
    {
        let text =
            fs::read_to_string(file).with_context(|| format!("cannot read {}", file.display()))?;
        for id in text.lines().filter_map(|line| line.strip_prefix("id:")) {
            let id = id.trim();
            if !ctx
                .root
                .join(RULE_TESTS)
                .join(format!("{id}-test.yml"))
                .is_file()
            {
                untested.push(id.to_owned());
            }
        }
    }
    if !untested.is_empty() {
        bail!(
            "rules without tests: {}. Add {RULE_TESTS}/<id>-test.yml with valid and invalid cases for each",
            untested.join(", ")
        );
    }
    Ok(())
}

/// Runs the gating detectors; the text lists their findings, and any gating one is an error
/// that carries the list.
fn gate_findings(ctx: &Context, base: Option<&str>) -> Result<String> {
    let change = ChangeContext::load(ctx, base)?;
    let mut text = String::new();
    let mut gating = 0;
    for detector in DETECTORS.iter().filter(|detector| detector.gate) {
        for finding in (detector.run)(ctx, &change)? {
            if finding.severity == Severity::Gate {
                gating += 1;
            }
            text.push_str(&format!(
                "{} {}:{} {}\n  Fix: {}\n",
                finding.detector,
                finding.file.display(),
                finding.line,
                finding.message,
                finding.fix
            ));
        }
    }
    if gating > 0 {
        bail!(
            "{gating} gating findings on changed lines against {}:\n{text}",
            change.change.short_base()
        );
    }
    Ok(text)
}

#[cfg(test)]
mod gate_tests {
    use super::*;

    use crate::test_support::{TempRoot, refusal};

    #[test]
    fn every_rule_in_a_file_needs_its_own_test_file() {
        let root = TempRoot::new();
        root.write(
            "rules/test-local-helper.yml",
            "id: test-local-helper\nlanguage: rust\nrule:\n  kind: function_item\n---\n\
             id: test-file-local-helper\nlanguage: rust\nrule:\n  kind: struct_item\n",
        );
        root.write(
            "rules/test-skip-added.yml",
            "id: test-skip-added\nlanguage: rust\n",
        );
        root.write(
            "rule-tests/test-local-helper-test.yml",
            "id: test-local-helper\n",
        );
        root.write(
            "rule-tests/test-skip-added-test.yml",
            "id: test-skip-added\n",
        );

        let error = refusal(every_rule_has_tests(&root.ctx));

        assert!(
            error.contains("rules without tests: test-file-local-helper."),
            "{error}"
        );
    }

    #[test]
    fn rules_that_all_have_tests_pass() {
        let root = TempRoot::new();
        root.write(
            "rules/test-skip-added.yml",
            "id: test-skip-added\nlanguage: rust\n",
        );
        root.write("rules/README.md", "id: not-a-rule\n");
        root.write(
            "rule-tests/test-skip-added-test.yml",
            "id: test-skip-added\n",
        );

        every_rule_has_tests(&root.ctx).unwrap();
    }
}
