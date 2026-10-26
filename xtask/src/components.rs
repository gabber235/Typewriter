//! The component test runner. It reads the suite's fixture catalog, builds the backend components
//! the fixtures name, writes the run manifest the suite verifies those artifacts against, runs the
//! cases and settles their results with the shared rerun and quarantine policy.
//!
//! The suite links the wasm host, so the harness never links it: the catalog comes from the
//! suite's `catalog` binary, and each case appends its result to a file the runner reads.

use std::collections::{BTreeMap, BTreeSet};
use std::fs::{self, File};
use std::io::{BufRead, BufReader};
use std::num::NonZeroUsize;
use std::path::{Path, PathBuf};
use std::process::{Command, Stdio};
use std::time::{SystemTime, UNIX_EPOCH};

use anyhow::{Context as _, Result, bail, ensure};
use serde::Deserialize;
use serde_json::{Value, json};
use sha2::{Digest, Sha256};

use crate::results::{self, Failure, Outcome, Quarantine, TestCase, TestRun};
use crate::skirout::base::harness::v1::test_run::Runner;
use crate::{CommandExt, Context, deploy};

pub const DESCRIBE: &str = "cargo xtask components --results .xtask/results/components.json: \
                            every fixture of the component test suite, a failed case rerun once";

/// The suite's Cargo manifest, relative to the repository root.
const SUITE: &str = "backend/tests/component/Cargo.toml";
const SUITE_PACKAGE: &str = "typewriter-component-tests";
/// Must match `component_test_model::{COMPONENT_TARGET, COMPONENT_PROFILE,
/// RUN_MANIFEST_SCHEMA_VERSION}`, which the suite checks every manifest against.
const COMPONENT_TARGET: &str = "wasm32-wasip2";
const COMPONENT_PROFILE: &str = "release";
const RUN_MANIFEST_SCHEMA_VERSION: u32 = 1;

#[derive(clap::Args, Default)]
pub struct ComponentTestArgs {
    /// Runs only this fixture.
    fixture: Option<String>,
    /// Runs only the fixture's cases whose name contains this text.
    #[arg(requires = "fixture")]
    case_filter: Option<String>,
    /// Lists the fixtures, their components and their cases instead of running them.
    #[arg(long)]
    list: bool,
    /// Cases that run at once and Cargo build jobs; defaults to the machine's parallelism.
    #[arg(long)]
    jobs: Option<NonZeroUsize>,
    /// Prints each case's lifecycle phases as they happen.
    #[arg(long)]
    live: bool,
    /// Writes the settled results here as a `TestRun` (`skir-src/harness/v1/test_run.skir`).
    #[arg(long)]
    results: Option<PathBuf>,
}

/// The graph step: the whole suite, with its results where the change report reads them.
pub fn step(ctx: &Context, log: &File) -> Result<()> {
    let args = ComponentTestArgs {
        results: Some(ctx.root.join(".xtask/results/components.json")),
        ..ComponentTestArgs::default()
    };
    run(ctx, &args, Some(log))
}

/// Runs the selected cases. Program output goes to `log`, or to the terminal.
pub fn run(ctx: &Context, args: &ComponentTestArgs, log: Option<&File>) -> Result<()> {
    let catalog = Catalog::load(ctx, args, log)?;
    catalog.check_deployable_coverage(ctx)?;
    if args.list {
        catalog.print();
        return Ok(());
    }
    let fixtures = catalog.select_fixtures(args)?;
    let selected = catalog.select_tests(&fixtures, args);
    ensure!(!selected.is_empty(), "the selection contains no cases");
    let artifacts = build_components(ctx, &fixtures, args, log)?;
    let manifest = write_manifest(ctx, &fixtures, &artifacts)?;
    catalog.verify_libtest_listing(ctx, args, &manifest)?;

    let suite = Suite {
        ctx,
        args,
        manifest: &manifest,
        log,
        commit: ctx
            .tool(".", "git", &["rev-parse", "HEAD"])
            .output_text()?
            .trim()
            .to_owned(),
    };
    // The whole suite runs without filters; the listing check proved it is exactly `selected`.
    let everything = args.fixture.is_none();
    let first = suite.run(&selected, everything)?;
    let quarantine = Quarantine::load(ctx)?;
    let run = results::settle(first, |failed| suite.run(failed, false), &quarantine)?;
    if let Some(path) = &args.results {
        results::write(&run, path)?;
    }
    match log {
        Some(mut log) => results::report(&run, &quarantine, &mut log),
        None => results::report(&run, &quarantine, &mut std::io::stderr()),
    }
}

/// What the suite registered, as its `catalog` binary prints it.
#[derive(Deserialize)]
struct Catalog {
    fixtures: Vec<Fixture>,
    tests: Vec<Test>,
}

#[derive(Deserialize)]
struct Fixture {
    id: String,
    primary: ComponentBuild,
    dependencies: Vec<ComponentBuild>,
}

#[derive(Deserialize)]
struct ComponentBuild {
    package: String,
    target: String,
    role: String,
}

impl Fixture {
    fn components(&self) -> impl Iterator<Item = &ComponentBuild> {
        std::iter::once(&self.primary).chain(&self.dependencies)
    }
}

#[derive(Deserialize)]
struct Test {
    fixture: String,
    /// The name libtest lists and filters by.
    name: String,
    case: Option<String>,
}

impl Catalog {
    fn load(ctx: &Context, args: &ComponentTestArgs, log: Option<&File>) -> Result<Self> {
        let mut command = cargo(
            ctx,
            &["run", "--locked", "--quiet", "--manifest-path", SUITE],
        );
        command.args(["-p", SUITE_PACKAGE, "--bin", "catalog"]);
        jobs(&mut command, args);
        let json = command
            .log_stderr(log)?
            .output_text()
            .context("cannot read the component test catalog")?;
        serde_json::from_str(&json).context("the component test catalog is unreadable")
    }

    /// Every deployable backend component is the primary component of a fixture.
    fn check_deployable_coverage(&self, ctx: &Context) -> Result<()> {
        let covered: BTreeSet<&str> = self
            .fixtures
            .iter()
            .map(|fixture| fixture.primary.package.as_str())
            .collect();
        let missing: Vec<String> = deploy::deployable(ctx)?
            .into_iter()
            .map(|component| component.package)
            .filter(|package| !covered.contains(package.as_str()))
            .collect();
        ensure!(
            missing.is_empty(),
            "deployable components without fixtures: {}",
            missing.join(", ")
        );
        Ok(())
    }

    fn print(&self) {
        for fixture in &self.fixtures {
            let packages: Vec<&str> = fixture
                .components()
                .map(|component| component.package.as_str())
                .collect();
            println!("{}\t{}", fixture.id, packages.join(", "));
            for test in self.tests.iter().filter(|test| test.fixture == fixture.id) {
                println!("  {}", test.name);
            }
        }
    }

    fn select_fixtures(&self, args: &ComponentTestArgs) -> Result<Vec<&Fixture>> {
        let Some(id) = &args.fixture else {
            return Ok(self.fixtures.iter().collect());
        };
        let found: Vec<&Fixture> = self.fixtures.iter().filter(|f| &f.id == id).collect();
        ensure!(!found.is_empty(), "unknown fixture `{id}`");
        Ok(found)
    }

    fn select_tests(&self, fixtures: &[&Fixture], args: &ComponentTestArgs) -> Vec<&str> {
        let ids: BTreeSet<&str> = fixtures.iter().map(|fixture| fixture.id.as_str()).collect();
        self.tests
            .iter()
            .filter(|test| ids.contains(test.fixture.as_str()))
            .filter(|test| {
                args.case_filter.as_ref().is_none_or(|filter| {
                    test.case.as_ref().is_some_and(|case| case.contains(filter))
                        || test.name.contains(filter)
                })
            })
            .map(|test| test.name.as_str())
            .collect()
    }

    /// The cases libtest lists are exactly the cases the catalog registers.
    fn verify_libtest_listing(
        &self,
        ctx: &Context,
        args: &ComponentTestArgs,
        manifest: &Path,
    ) -> Result<()> {
        let mut command = suite_test(ctx, args);
        command
            .args(["--", "--list", "--format", "terse"])
            .env("COMPONENT_TEST_RUN_MANIFEST", manifest);
        let listed: BTreeSet<String> = command
            .output_text()
            .context("cannot list the suite's cases")?
            .lines()
            .filter_map(|line| line.strip_suffix(": test"))
            .map(str::to_owned)
            .collect();
        let registered: BTreeSet<String> = self.tests.iter().map(|t| t.name.clone()).collect();
        ensure!(
            listed == registered,
            "registered cases differ from libtest's listing; not listed: {:?}; not registered: {:?}",
            registered.difference(&listed).collect::<Vec<_>>(),
            listed.difference(&registered).collect::<Vec<_>>()
        );
        Ok(())
    }
}

/// One built component artifact.
struct Artifact {
    package_id: String,
    path: PathBuf,
    fresh: bool,
}

/// Builds every component the fixtures name in one Cargo invocation, keyed by package and target.
fn build_components(
    ctx: &Context,
    fixtures: &[&Fixture],
    args: &ComponentTestArgs,
    log: Option<&File>,
) -> Result<BTreeMap<(String, String), Artifact>> {
    let wanted: BTreeSet<(&str, &str)> = fixtures
        .iter()
        .flat_map(|fixture| fixture.components())
        .map(|component| (component.package.as_str(), component.target.as_str()))
        .collect();
    let names = package_names(ctx)?;
    let mut command = cargo(
        ctx,
        &[
            "build",
            "--locked",
            "--manifest-path",
            "backend/Cargo.toml",
            "--target",
            COMPONENT_TARGET,
            "--release",
            "--message-format=json-render-diagnostics",
        ],
    );
    jobs(&mut command, args);
    let packages: BTreeSet<&str> = wanted.iter().map(|(package, _)| *package).collect();
    for package in &packages {
        command.args(["-p", package]);
    }
    let mut child = command
        .log_stderr(log)?
        .stdout(Stdio::piped())
        .spawn()
        .context("cannot start the component build")?;
    let stdout = child
        .stdout
        .take()
        .context("cargo printed no build output")?;
    let mut artifacts = BTreeMap::new();
    let mut finished = false;
    for line in BufReader::new(stdout).lines() {
        let message: Value = serde_json::from_str(&line?)?;
        match message["reason"].as_str() {
            Some("compiler-artifact") => {
                let (Some(package_id), Some(target)) = (
                    message["package_id"].as_str(),
                    message["target"]["name"].as_str(),
                ) else {
                    continue;
                };
                let Some(package) = names.get(package_id).map(String::as_str) else {
                    continue;
                };
                if !wanted.contains(&(package, target)) {
                    continue;
                }
                let wasm: Vec<&str> = message["filenames"]
                    .as_array()
                    .into_iter()
                    .flatten()
                    .filter_map(Value::as_str)
                    .filter(|file| file.ends_with(".wasm"))
                    .collect();
                ensure!(
                    wasm.len() == 1,
                    "package `{package}` target `{target}` built {} .wasm files, expected one",
                    wasm.len()
                );
                artifacts.insert(
                    (package.to_owned(), target.to_owned()),
                    Artifact {
                        package_id: package_id.to_owned(),
                        path: PathBuf::from(wasm[0]),
                        fresh: message["fresh"].as_bool().unwrap_or(false),
                    },
                );
            }
            Some("build-finished") => finished = message["success"].as_bool() == Some(true),
            _ => {}
        }
    }
    let status = child.wait()?;
    ensure!(
        status.success() && finished,
        "the component build failed with {status}"
    );
    for (package, target) in &wanted {
        ensure!(
            artifacts.contains_key(&((*package).to_owned(), (*target).to_owned())),
            "the build produced no artifact for package `{package}` target `{target}`"
        );
    }
    Ok(artifacts)
}

/// Backend package names by package id. Cargo's package ids are opaque, so a build message's
/// package is looked up here rather than parsed out of its id.
fn package_names(ctx: &Context) -> Result<BTreeMap<String, String>> {
    let metadata: Value = serde_json::from_str(
        &cargo(
            ctx,
            &[
                "metadata",
                "--format-version",
                "1",
                "--no-deps",
                "--locked",
                "--manifest-path",
                "backend/Cargo.toml",
            ],
        )
        .output_text()?,
    )?;
    Ok(metadata["packages"]
        .as_array()
        .context("cargo metadata printed no packages")?
        .iter()
        .filter_map(|package| {
            Some((
                package["id"].as_str()?.to_owned(),
                package["name"].as_str()?.to_owned(),
            ))
        })
        .collect())
}

/// Writes the manifest that ties each fixture to the exact artifacts this run built. The suite
/// refuses artifacts whose digest differs, so a stale or hand edited build never runs.
fn write_manifest(
    ctx: &Context,
    fixtures: &[&Fixture],
    artifacts: &BTreeMap<(String, String), Artifact>,
) -> Result<PathBuf> {
    let run_id = format!(
        "{}-{}",
        SystemTime::now().duration_since(UNIX_EPOCH)?.as_nanos(),
        std::process::id()
    );
    let mut records = Vec::new();
    for fixture in fixtures {
        for component in fixture.components() {
            let built = &artifacts[&(component.package.clone(), component.target.clone())];
            records.push(json!({
                "fixture_id": fixture.id,
                "role": component.role,
                "package_id": built.package_id,
                "package": component.package,
                "target_name": component.target,
                "path": built.path,
                "sha256": sha256(&built.path)?,
                "fresh": built.fresh,
            }));
        }
    }
    let manifest = json!({
        "schema_version": RUN_MANIFEST_SCHEMA_VERSION,
        "run_id": run_id,
        "workspace_root": ctx.root,
        "backend_lock_sha256": sha256(&ctx.root.join("backend/Cargo.lock"))?,
        "test_lock_sha256": sha256(&ctx.root.join("backend/tests/component/Cargo.lock"))?,
        "rustc_version": ctx.tool(".", "rustc", &["--version"]).output_text()?.trim(),
        "cargo_version": ctx.tool(".", "cargo", &["--version"]).output_text()?.trim(),
        "target": COMPONENT_TARGET,
        "profile": COMPONENT_PROFILE,
        "fixtures": fixtures.iter().map(|fixture| &fixture.id).collect::<Vec<_>>(),
        "artifacts": records,
    });
    let directory = ctx.root.join("backend/target/component-tests/runs");
    fs::create_dir_all(&directory)
        .with_context(|| format!("cannot create {}", directory.display()))?;
    let path = directory.join(format!("{run_id}.json"));
    fs::write(&path, serde_json::to_string_pretty(&manifest)?)
        .with_context(|| format!("cannot write {}", path.display()))?;
    Ok(path)
}

fn sha256(path: &Path) -> Result<String> {
    let bytes = fs::read(path).with_context(|| format!("cannot read {}", path.display()))?;
    Ok(format!("{:x}", Sha256::digest(bytes)))
}

/// Runs cases of the suite against one manifest.
struct Suite<'a> {
    ctx: &'a Context,
    args: &'a ComponentTestArgs,
    manifest: &'a Path,
    log: Option<&'a File>,
    commit: String,
}

/// One case's result as the suite appends it to `COMPONENT_TEST_RESULTS`.
#[derive(Deserialize)]
struct CaseResult {
    id: String,
    duration_millis: i64,
    failure: Option<String>,
}

impl Suite<'_> {
    /// Runs `cases`, all of them unfiltered when `everything`, and returns one result per case.
    /// A case that recorded no result failed: the test process stopped before it finished.
    fn run(&self, cases: &[&str], everything: bool) -> Result<TestRun> {
        let started_at_millis =
            i64::try_from(SystemTime::now().duration_since(UNIX_EPOCH)?.as_millis())?;
        let results = self.ctx.root.join(format!(
            ".xtask/results/components-{started_at_millis}.jsonl"
        ));
        fs::create_dir_all(results.parent().context("results file has no directory")?)?;
        let mut command = suite_test(self.ctx, self.args);
        command.arg("--");
        if !everything {
            command.arg("--exact").args(cases);
        }
        command
            .env("COMPONENT_TEST_RUN_MANIFEST", self.manifest)
            .env("COMPONENT_TEST_RESULTS", &results)
            .env(
                "COMPONENT_TEST_LIVE",
                if self.args.live { "1" } else { "0" },
            );
        if let Some(jobs) = self.args.jobs {
            command.env("COMPONENT_TEST_JOBS", jobs.to_string());
        }
        if let Some(log) = self.log {
            command
                .stdin(Stdio::null())
                .stdout(log.try_clone()?)
                .stderr(log.try_clone()?);
        }
        let status = command
            .status()
            .with_context(|| format!("cannot start {}", crate::display(&command)))?;
        let recorded: BTreeMap<String, CaseResult> = match fs::read_to_string(&results) {
            Ok(text) => text
                .lines()
                .map(serde_json::from_str::<CaseResult>)
                .map(|result| result.map(|result| (result.id.clone(), result)))
                .collect::<Result<_, _>>()
                .context("the suite wrote an unreadable result")?,
            Err(_) if !status.success() => {
                bail!("the suite failed with {status} before any case ran")
            }
            Err(_) => BTreeMap::new(),
        };
        let _ = fs::remove_file(&results);
        let cases = cases
            .iter()
            .map(|id| {
                let (outcome, duration_millis) = match recorded.get(*id) {
                    Some(result) => (
                        match &result.failure {
                            None => Outcome::Passed,
                            Some(message) => failed(message.clone()),
                        },
                        result.duration_millis,
                    ),
                    None => (
                        failed("recorded no result: the test process stopped first".to_owned()),
                        0,
                    ),
                };
                TestCase {
                    id: (*id).to_owned(),
                    outcome,
                    duration_millis,
                    ..TestCase::default()
                }
            })
            .collect();
        Ok(TestRun {
            runner: Runner::Components,
            commit: self.commit.clone(),
            started_at_millis,
            cases,
            _unrecognized: None,
        })
    }
}

fn failed(message: String) -> Outcome {
    Outcome::Failed(Box::new(Failure {
        message,
        ..Failure::default()
    }))
}

/// `cargo test` of the suite's cases, without libtest arguments yet.
fn suite_test(ctx: &Context, args: &ComponentTestArgs) -> Command {
    let mut command = cargo(ctx, &["test", "--locked", "--manifest-path", SUITE]);
    command.args(["-p", SUITE_PACKAGE, "--lib"]);
    jobs(&mut command, args);
    command
}

fn cargo(ctx: &Context, args: &[&str]) -> Command {
    ctx.tool(".", "cargo", args)
}

fn jobs(command: &mut Command, args: &ComponentTestArgs) {
    if let Some(jobs) = args.jobs {
        command.args(["--jobs", &jobs.to_string()]);
    }
}
