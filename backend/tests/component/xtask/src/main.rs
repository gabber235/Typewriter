use std::collections::{BTreeMap, BTreeSet};
use std::env;
use std::fs::{self, File, OpenOptions};
use std::io::{BufReader, Write};
use std::path::{Path, PathBuf};
use std::process::{Command, ExitCode, Stdio};
use std::time::{SystemTime, UNIX_EPOCH};

use anyhow::{Context, Result, anyhow, bail, ensure};
use cargo_metadata::{Artifact, Message, Metadata, MetadataCommand, PackageId};
use clap::{ArgAction, Parser};
use component_test::{FixtureDescriptor, TestDescriptor};
use component_test_model::{
    ArtifactRecord, COMPONENT_PROFILE, COMPONENT_TARGET, OwnedComponentRole,
    RUN_MANIFEST_SCHEMA_VERSION, RunManifest, select_affected,
};
use sha2::{Digest, Sha256};
use typewriter_component_tests as _;

#[derive(Parser, Debug)]
#[command(name = "component-test")]
struct Args {
    fixture: Option<String>,
    case_filter: Option<String>,
    #[arg(long, action = ArgAction::SetTrue)]
    all: bool,
    #[arg(long)]
    affected: Option<String>,
    #[arg(long)]
    affected_paths_file: Option<PathBuf>,
    #[arg(long, action = ArgAction::SetTrue)]
    list: bool,
    #[arg(long)]
    jobs: Option<usize>,
    #[arg(long, action = ArgAction::SetTrue)]
    live: bool,
    #[arg(long)]
    shard_index: Option<usize>,
    #[arg(long)]
    shard_count: Option<usize>,
}

struct Roots {
    repository: PathBuf,
    backend: PathBuf,
    tests: PathBuf,
}

#[derive(Clone)]
struct BuiltArtifact {
    package_id: String,
    package: String,
    target: String,
    path: PathBuf,
    fresh: bool,
}

fn main() -> ExitCode {
    match run() {
        Ok(code) => ExitCode::from(code.try_into().unwrap_or(1)),
        Err(error) => {
            eprintln!("component-test: {error:#}");
            ExitCode::FAILURE
        }
    }
}

fn run() -> Result<i32> {
    let mut arguments = env::args_os().collect::<Vec<_>>();
    if arguments
        .get(1)
        .is_some_and(|argument| argument == "component-test")
    {
        arguments.remove(1);
    }
    let args = Args::parse_from(arguments);
    validate_args(&args)?;
    let roots = roots()?;
    let fixtures =
        component_test::registered_fixtures().context("catalog phase: invalid fixture catalog")?;
    let tests =
        component_test::registered_tests().context("catalog phase: invalid test catalog")?;

    if args.list {
        for fixture in &fixtures {
            let packages = fixture
                .components()
                .map(|c| c.package)
                .collect::<Vec<_>>()
                .join(", ");
            println!("{}\t{}", fixture.id, packages);
            for test in tests.iter().filter(|test| test.fixture_id == fixture.id) {
                println!("  {}", test.exact_name);
            }
        }
        return Ok(0);
    }

    let metadata = metadata(&roots)?;
    let selected_fixtures = select_fixtures(&args, &roots, &metadata, &fixtures)?;
    let selected_tests = select_tests(&args, &selected_fixtures, &tests)?;
    ensure!(
        !selected_tests.is_empty(),
        "selection phase: selection contains no registered tests"
    );

    let mut builds = BTreeMap::new();
    for fixture in &selected_fixtures {
        for component in fixture.components() {
            builds
                .entry((component.package, component.target))
                .or_insert(component);
        }
    }
    let mut artifacts = BTreeMap::new();
    for ((package, target), _) in builds {
        artifacts.insert(
            (package, target),
            build_component(&roots, &metadata, package, target)?,
        );
    }

    let manifest_path = write_manifest(&roots, &selected_fixtures, &artifacts)?;
    run_tests(&args, &roots, &tests, &selected_tests, &manifest_path)
}

fn validate_args(args: &Args) -> Result<()> {
    ensure!(
        !(args.all && args.fixture.is_some()),
        "selection phase: --all cannot be combined with FIXTURE"
    );
    let affected_count =
        usize::from(args.affected.is_some()) + usize::from(args.affected_paths_file.is_some());
    ensure!(
        affected_count <= 1,
        "selection phase: --affected and --affected-paths-file are mutually exclusive"
    );
    ensure!(
        !(affected_count == 1 && (args.all || args.fixture.is_some())),
        "selection phase: affected selection cannot be combined with --all or FIXTURE"
    );
    ensure!(
        args.case_filter.is_none() || args.fixture.is_some(),
        "selection phase: CASE_FILTER requires FIXTURE"
    );
    ensure!(
        args.jobs != Some(0),
        "selection phase: --jobs must be greater than zero"
    );
    match (args.shard_index, args.shard_count) {
        (None, None) => {}
        (Some(index), Some(count)) if count > 0 && index < count => {}
        _ => bail!(
            "sharding phase: --shard-index and --shard-count are both required, count must be positive, and index must be less than count"
        ),
    }
    Ok(())
}

fn roots() -> Result<Roots> {
    let tests = PathBuf::from(env!("CARGO_MANIFEST_DIR"))
        .parent()
        .context("root phase: xtask manifest has no parent")?
        .to_path_buf();
    let backend = tests
        .parent()
        .and_then(Path::parent)
        .context("root phase: cannot locate backend root")?
        .to_path_buf();
    let repository = backend
        .parent()
        .context("root phase: cannot locate repository root")?
        .to_path_buf();
    ensure!(
        backend.join("Cargo.toml").is_file(),
        "root phase: {} is not a backend workspace",
        backend.display()
    );
    Ok(Roots {
        repository,
        backend,
        tests,
    })
}

fn metadata(roots: &Roots) -> Result<Metadata> {
    MetadataCommand::new()
        .manifest_path(roots.backend.join("Cargo.toml"))
        .exec()
        .context("metadata phase: cargo metadata for backend/Cargo.toml failed")
}

fn cargo_command() -> Command {
    let mut command = Command::new("cargo");
    command.env_remove("CARGO_MANIFEST_DIR");
    command
}

fn select_fixtures<'a>(
    args: &Args,
    roots: &Roots,
    metadata: &Metadata,
    fixtures: &[&'a FixtureDescriptor],
) -> Result<Vec<&'a FixtureDescriptor>> {
    if let Some(id) = &args.fixture {
        return fixtures
            .iter()
            .copied()
            .filter(|fixture| fixture.id == id)
            .collect::<Vec<_>>()
            .pipe(|found| {
                if found.is_empty() {
                    Err(anyhow!("selection phase: unknown fixture `{id}`"))
                } else {
                    Ok(found)
                }
            });
    }
    if let Some(base) = &args.affected {
        return affected_fixtures(base, roots, metadata, fixtures);
    }
    if let Some(path) = &args.affected_paths_file {
        let changed = fs::read_to_string(path).with_context(|| {
            format!(
                "affected phase: failed to read changed paths from {}",
                path.display()
            )
        })?;
        return affected_fixtures_for_paths(
            changed.lines().map(str::to_string).collect(),
            format!("changed paths file {}", path.display()),
            roots,
            metadata,
            fixtures,
        );
    }
    Ok(fixtures.to_vec())
}

trait Pipe: Sized {
    fn pipe<T>(self, f: impl FnOnce(Self) -> T) -> T {
        f(self)
    }
}
impl<T> Pipe for T {}

fn affected_fixtures<'a>(
    base: &str,
    roots: &Roots,
    metadata: &Metadata,
    fixtures: &[&'a FixtureDescriptor],
) -> Result<Vec<&'a FixtureDescriptor>> {
    let command_text = format!("git diff --name-only {base}...HEAD");
    let output = Command::new("git")
        .args(["diff", "--name-only", &format!("{base}...HEAD")])
        .current_dir(&roots.repository)
        .output()
        .with_context(|| format!("affected phase: failed command `{command_text}`"))?;
    ensure!(
        output.status.success(),
        "affected phase: command `{command_text}` failed: {}",
        String::from_utf8_lossy(&output.stderr)
    );
    let changed =
        String::from_utf8(output.stdout).context("affected phase: git returned non-UTF-8 paths")?;
    affected_fixtures_for_paths(
        changed.lines().map(str::to_string).collect(),
        command_text,
        roots,
        metadata,
        fixtures,
    )
}

fn affected_fixtures_for_paths<'a>(
    paths: Vec<String>,
    source: String,
    roots: &Roots,
    metadata: &Metadata,
    fixtures: &[&'a FixtureDescriptor],
) -> Result<Vec<&'a FixtureDescriptor>> {
    let path_refs = paths.iter().map(String::as_str).collect::<Vec<_>>();
    let model = select_affected(fixtures, &path_refs);
    let package_selection = affected_packages(metadata, &roots.repository, &path_refs);
    let mut ids = model.fixture_ids;
    for fixture in fixtures {
        if fixture
            .components()
            .any(|component| package_selection.contains(component.package))
        {
            ids.insert(fixture.id.to_string());
        }
    }
    if model.all {
        println!(
            "affected: all ({})",
            model
                .reasons
                .values()
                .flatten()
                .cloned()
                .collect::<Vec<_>>()
                .join(", ")
        );
        return Ok(fixtures.to_vec());
    }
    for id in &ids {
        println!("affected: {id}");
    }
    ensure!(
        !ids.is_empty(),
        "affected phase: no fixtures affected by `{source}`"
    );
    Ok(fixtures
        .iter()
        .copied()
        .filter(|fixture| ids.contains(fixture.id))
        .collect())
}

fn affected_packages(metadata: &Metadata, repository: &Path, paths: &[&str]) -> BTreeSet<String> {
    let mut ids = BTreeSet::new();
    for package in &metadata.packages {
        let Some(dir) = package.manifest_path.parent() else {
            continue;
        };
        let Ok(relative) = dir.as_std_path().strip_prefix(repository) else {
            continue;
        };
        if paths
            .iter()
            .any(|path| Path::new(path).starts_with(relative))
        {
            ids.insert(package.id.clone());
        }
    }
    let mut changed = true;
    while changed {
        changed = false;
        if let Some(resolve) = &metadata.resolve {
            for node in &resolve.nodes {
                if node.deps.iter().any(|dep| ids.contains(&dep.pkg)) && ids.insert(node.id.clone())
                {
                    changed = true;
                }
            }
        }
    }
    metadata
        .packages
        .iter()
        .filter(|package| ids.contains(&package.id))
        .map(|package| package.name.to_string())
        .collect()
}

fn select_tests<'a>(
    args: &Args,
    fixtures: &[&FixtureDescriptor],
    tests: &[&'a TestDescriptor],
) -> Result<Vec<&'a TestDescriptor>> {
    let ids = fixtures
        .iter()
        .map(|fixture| fixture.id)
        .collect::<BTreeSet<_>>();
    let mut selected = tests
        .iter()
        .copied()
        .filter(|test| ids.contains(test.fixture_id))
        .filter(|test| {
            args.case_filter.as_ref().is_none_or(|filter| {
                test.case.is_some_and(|case| case.contains(filter))
                    || test.exact_name.contains(filter)
            })
        })
        .collect::<Vec<_>>();
    if let (Some(index), Some(count)) = (args.shard_index, args.shard_count) {
        selected = shard(&selected, index, count);
    }
    Ok(selected)
}

fn shard<'a>(tests: &[&'a TestDescriptor], index: usize, count: usize) -> Vec<&'a TestDescriptor> {
    tests
        .iter()
        .enumerate()
        .filter(|(position, _)| position % count == index)
        .map(|(_, test)| *test)
        .collect()
}

fn build_component(
    roots: &Roots,
    metadata: &Metadata,
    package_name: &str,
    target_name: &str,
) -> Result<BuiltArtifact> {
    let packages = metadata
        .packages
        .iter()
        .filter(|package| package.name == package_name)
        .collect::<Vec<_>>();
    ensure!(
        packages.len() == 1,
        "build phase: package `{package_name}` matched {} backend packages",
        packages.len()
    );
    let package = packages[0];
    let manifest = package.manifest_path.as_std_path();
    let args = [
        "build",
        "--manifest-path",
        manifest
            .to_str()
            .context("build phase: non-UTF-8 manifest path")?,
        "-p",
        package_name,
        "--target",
        COMPONENT_TARGET,
        "--release",
        "--message-format=json-render-diagnostics",
    ];
    let command_text = format!("cargo {}", args.join(" "));
    let mut child = cargo_command()
        .args(args)
        .current_dir(&roots.backend)
        .stdout(Stdio::piped())
        .stderr(Stdio::inherit())
        .spawn()
        .with_context(|| {
            format!(
                "build phase: fixture package `{package_name}` failed to start `{command_text}`"
            )
        })?;
    let stdout = child
        .stdout
        .take()
        .context("build phase: cargo stdout unavailable")?;
    let (candidates, finished) =
        collect_artifacts(BufReader::new(stdout), &package.id, target_name)?;
    let status = child
        .wait()
        .with_context(|| format!("build phase: failed waiting for `{command_text}`"))?;
    ensure!(
        status.success() && finished,
        "build phase: package `{package_name}` command `{command_text}` failed (status {status}, build-finished={finished})"
    );
    ensure!(
        candidates.len() == 1,
        "artifact phase: package `{package_name}` target `{target_name}` expected exactly one .wasm artifact, found {}",
        candidates.len()
    );
    let artifact = &candidates[0];
    Ok(BuiltArtifact {
        package_id: package.id.to_string(),
        package: package_name.into(),
        target: target_name.into(),
        path: artifact
            .filenames
            .iter()
            .find(|p| p.extension() == Some("wasm"))
            .unwrap()
            .as_std_path()
            .to_path_buf(),
        fresh: artifact.fresh,
    })
}

fn collect_artifacts(
    reader: impl std::io::BufRead,
    package_id: &PackageId,
    target: &str,
) -> Result<(Vec<Artifact>, bool)> {
    let mut artifacts = Vec::new();
    let mut finished = false;
    for message in Message::parse_stream(reader) {
        match message.context("build phase: invalid cargo JSON message")? {
            Message::CompilerArtifact(artifact)
                if artifact_candidate(&artifact, package_id, target) =>
            {
                artifacts.push(artifact)
            }
            Message::CompilerMessage(message) => {
                if let Some(rendered) = message.message.rendered {
                    eprint!("{rendered}");
                }
            }
            Message::BuildFinished(result) => finished = result.success,
            _ => {}
        }
    }
    Ok((artifacts, finished))
}

fn artifact_candidate(artifact: &Artifact, package_id: &PackageId, target: &str) -> bool {
    &artifact.package_id == package_id
        && artifact.target.name == target
        && artifact
            .filenames
            .iter()
            .filter(|path| path.extension() == Some("wasm"))
            .count()
            == 1
}

fn write_manifest(
    roots: &Roots,
    fixtures: &[&FixtureDescriptor],
    builds: &BTreeMap<(&str, &str), BuiltArtifact>,
) -> Result<PathBuf> {
    let run_id = format!(
        "{}-{}",
        SystemTime::now().duration_since(UNIX_EPOCH)?.as_nanos(),
        std::process::id()
    );
    let directory = roots.backend.join("target/component-tests/runs");
    fs::create_dir_all(&directory).context("manifest phase: create runs directory")?;
    let path = directory.join(format!("{run_id}.json"));
    let temp = directory.join(format!(".{run_id}.tmp"));
    ensure!(
        !path.exists(),
        "manifest phase: immutable run manifest already exists: {}",
        path.display()
    );
    let mut records = Vec::new();
    for fixture in fixtures {
        for component in fixture.components() {
            let built = &builds[&(component.package, component.target)];
            records.push(ArtifactRecord {
                fixture_id: fixture.id.into(),
                role: OwnedComponentRole::from(component.role),
                package_id: built.package_id.clone(),
                package: built.package.clone(),
                target_name: built.target.clone(),
                path: built.path.clone(),
                sha256: sha256(&built.path)?,
                fresh: built.fresh,
            });
        }
    }
    let manifest = RunManifest {
        schema_version: RUN_MANIFEST_SCHEMA_VERSION,
        run_id,
        workspace_root: roots.repository.clone(),
        backend_lock_sha256: sha256(&roots.backend.join("Cargo.lock"))?,
        test_lock_sha256: sha256(&roots.tests.join("Cargo.lock"))?,
        rustc_version: version("rustc")?,
        cargo_version: version("cargo")?,
        target: COMPONENT_TARGET.into(),
        profile: COMPONENT_PROFILE.into(),
        fixtures: fixtures.iter().map(|f| f.id.into()).collect(),
        artifacts: records,
    };
    let mut file = OpenOptions::new()
        .write(true)
        .create_new(true)
        .open(&temp)
        .context("manifest phase: create temporary manifest")?;
    serde_json::to_writer_pretty(&mut file, &manifest)?;
    file.write_all(b"\n")?;
    file.sync_all()?;
    fs::rename(&temp, &path).context("manifest phase: atomic rename")?;
    File::open(&directory)?.sync_all()?;
    Ok(path)
}

fn sha256(path: &Path) -> Result<String> {
    let bytes = fs::read(path).with_context(|| format!("hash phase: read {}", path.display()))?;
    Ok(format!("{:x}", Sha256::digest(bytes)))
}
fn version(program: &str) -> Result<String> {
    let output = Command::new(program)
        .arg("--version")
        .output()
        .with_context(|| format!("version phase: `{program} --version`"))?;
    ensure!(
        output.status.success(),
        "version phase: `{program} --version` failed"
    );
    Ok(String::from_utf8(output.stdout)?.trim().into())
}

fn run_tests(
    args: &Args,
    roots: &Roots,
    all_tests: &[&TestDescriptor],
    selected: &[&TestDescriptor],
    manifest: &Path,
) -> Result<i32> {
    verify_libtest_catalog(roots, all_tests, manifest, args.jobs)?;
    let selected_names = selected
        .iter()
        .map(|test| test.libtest_name())
        .collect::<BTreeSet<_>>();
    let manifest_path = roots.tests.join("Cargo.toml");
    let mut command = cargo_command();
    command
        .args(["test", "--manifest-path"])
        .arg(&manifest_path)
        .args(["-p", "typewriter-component-tests", "--lib"]);
    if let Some(jobs) = args.jobs {
        command.args(["--jobs", &jobs.to_string()]);
    }
    command.arg("--");
    for test in all_tests {
        if !selected_names.contains(test.libtest_name()) {
            command.args(["--skip", test.libtest_name()]);
        }
    }
    command.env("COMPONENT_TEST_RUN_MANIFEST", manifest);
    if let Some(jobs) = args.jobs {
        command.env("COMPONENT_TEST_JOBS", jobs.to_string());
    }
    command.env("COMPONENT_TEST_LIVE", if args.live { "1" } else { "0" });
    let status = command.current_dir(&roots.repository).status().context("test phase: failed command `cargo test --manifest-path backend/tests/component/Cargo.toml -p typewriter-component-tests --lib -- ...`")?;
    Ok(status.code().unwrap_or(1))
}

fn verify_libtest_catalog(
    roots: &Roots,
    registered: &[&TestDescriptor],
    manifest: &Path,
    jobs: Option<usize>,
) -> Result<()> {
    let mut command = cargo_command();
    command
        .args(["test", "--manifest-path"])
        .arg(roots.tests.join("Cargo.toml"))
        .args(["-p", "typewriter-component-tests", "--lib"]);
    if let Some(jobs) = jobs {
        command.args(["--jobs", &jobs.to_string()]);
    }
    let output = command
        .args(["--", "--list", "--format", "terse"])
        .env("COMPONENT_TEST_RUN_MANIFEST", manifest)
        .current_dir(&roots.repository)
        .output()
        .context("catalog phase: failed to list libtest tests")?;
    ensure!(
        output.status.success(),
        "catalog phase: libtest listing failed: {}",
        String::from_utf8_lossy(&output.stderr)
    );
    let listed = String::from_utf8(output.stdout)?
        .lines()
        .filter_map(|line| line.strip_suffix(": test"))
        .map(str::to_string)
        .collect::<BTreeSet<_>>();
    let expected = registered
        .iter()
        .map(|test| test.libtest_name().to_string())
        .collect::<BTreeSet<_>>();
    ensure!(
        listed == expected,
        "catalog phase: registered tests differ from libtest listing; missing from libtest: {:?}; missing from catalog: {:?}",
        expected.difference(&listed).collect::<Vec<_>>(),
        listed.difference(&expected).collect::<Vec<_>>()
    );
    Ok(())
}

#[cfg(test)]
mod tests {
    use super::*;
    use component_test_model::{ComponentBuild, FixtureDescriptor, TestDescriptor};
    const EMPTY: &[ComponentBuild] = &[];
    static F: FixtureDescriptor = FixtureDescriptor {
        id: "f",
        primary: ComponentBuild::primary("p", "p"),
        dependencies: EMPTY,
        affected_paths: &[],
    };
    static A: TestDescriptor = TestDescriptor {
        fixture_id: "f",
        module_path: "m",
        function: "a",
        case: Some("one"),
        exact_name: "m::a",
    };
    static B: TestDescriptor = TestDescriptor {
        fixture_id: "f",
        module_path: "m",
        function: "b",
        case: Some("two"),
        exact_name: "m::b",
    };

    #[test]
    fn selection_filters_case() {
        let args = Args {
            fixture: Some("f".into()),
            case_filter: Some("one".into()),
            all: false,
            affected: None,
            affected_paths_file: None,
            list: false,
            jobs: None,
            live: false,
            shard_index: None,
            shard_count: None,
        };
        assert_eq!(
            select_tests(&args, &[&F], &[&A, &B]).unwrap()[0].exact_name,
            "m::a"
        );
    }
    #[test]
    fn shards_are_complete_and_disjoint() {
        let tests = [&A, &B];
        let left = shard(&tests, 0, 2);
        let right = shard(&tests, 1, 2);
        assert_eq!(left.len() + right.len(), tests.len());
        assert!(left.iter().all(|test| !right.contains(test)));
    }
    #[test]
    fn validates_bad_shards() {
        let args = Args {
            fixture: None,
            case_filter: None,
            all: true,
            affected: None,
            affected_paths_file: None,
            list: false,
            jobs: None,
            live: false,
            shard_index: Some(2),
            shard_count: Some(2),
        };
        assert!(validate_args(&args).is_err());
    }
    #[test]
    fn artifact_candidate_matches_opaque_package_and_target() {
        let json = r#"{"reason":"compiler-artifact","package_id":"path+file:///tmp#p@0.1.0","manifest_path":"/tmp/Cargo.toml","target":{"kind":["cdylib"],"crate_types":["cdylib"],"name":"component","src_path":"/tmp/lib.rs","edition":"2021","doc":true,"doctest":false,"test":true},"profile":{"opt_level":"3","debuginfo":0,"debug_assertions":false,"overflow_checks":false,"test":false},"features":[],"filenames":["/tmp/component.wasm"],"executable":null,"fresh":true}"#;
        let Message::CompilerArtifact(artifact) = serde_json::from_str(json).unwrap() else {
            panic!("expected artifact")
        };
        assert!(artifact_candidate(
            &artifact,
            &artifact.package_id,
            "component"
        ));
        assert!(!artifact_candidate(
            &artifact,
            &artifact.package_id,
            "other"
        ));
    }

    #[test]
    fn immutable_manifest_path_shape() {
        let path =
            Path::new("backend/target/component-tests/runs").join(format!("{}-{}.json", 1, 2));
        assert!(path.ends_with("runs/1-2.json"));
    }
}
