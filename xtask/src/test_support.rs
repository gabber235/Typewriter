//! Builders, fakes and assertions the harness's unit tests share. Test modules hold only their
//! test cases; every piece of setup they need lives here.

use std::collections::BTreeSet;
use std::fs;
use std::io::{Read as _, Write as _};
use std::net::{Ipv4Addr, TcpListener};
use std::os::unix::process::ExitStatusExt as _;
use std::path::{Path, PathBuf};
use std::process::{Command, ExitStatus};
use std::thread;
use std::time::Duration;

use anyhow::Result;
use clap::ValueEnum as _;

use crate::cluster::{CiClients, CiCluster};
use crate::e2e::E2eArgs;
use crate::graph::{Area, Run, Step};
use crate::hooks::commit_msg::Scopes;
use crate::results::{
    Artifact, ArtifactKind, Attempt, AttemptPolicy, Failure, Outcome, Quarantine, TestCase, TestRun,
};
use crate::skirout::base::harness::v1::test_run::{Runner, Span, Step as ScenarioStep};
use crate::stack::StackRecord;
use crate::stack::spec::{PortLease, StackContext};
use crate::{CommandExt as _, Context};

/// A throwaway repository root: a temporary directory and the [`Context`] that resolves against
/// it. The directory is removed when the root is dropped.
pub struct TempRoot {
    dir: tempfile::TempDir,
    pub ctx: Context,
}

impl TempRoot {
    /// An empty root, not yet a Git repository.
    pub fn new() -> Self {
        let dir = tempfile::tempdir().unwrap();
        let ctx = Context {
            root: dir.path().to_owned(),
        };
        Self { dir, ctx }
    }

    /// The absolute path of `relative` inside the root.
    pub fn path(&self, relative: &str) -> PathBuf {
        self.dir.path().join(relative)
    }

    /// Creates the directory `relative`, with its parents, and returns its path.
    pub fn dir(&self, relative: &str) -> PathBuf {
        let path = self.path(relative);
        fs::create_dir_all(&path).unwrap();
        path
    }

    /// Writes `contents` to the file `relative`, creating its parent directories.
    pub fn write(&self, relative: &str, contents: &str) {
        let path = self.path(relative);
        fs::create_dir_all(path.parent().unwrap()).unwrap();
        fs::write(path, contents).unwrap();
    }

    /// Writes `relative` and commits it.
    pub fn save(&self, relative: &str, contents: &str) {
        self.write(relative, contents);
        self.git(&["add", "."]);
        self.git(&["commit", "--quiet", "-m", relative]);
    }

    /// Runs `git args` in the root under a fixed identity without signing, and returns its
    /// output. Panics when Git fails.
    pub fn git(&self, args: &[&str]) -> String {
        self.ctx
            .tool(
                ".",
                "git",
                &[
                    "-c",
                    "user.name=t",
                    "-c",
                    "user.email=t@t",
                    "-c",
                    "commit.gpgsign=false",
                ],
            )
            .args(args)
            .output_text()
            .unwrap()
    }

    /// Records an empty commit with `message` on the checked out branch.
    pub fn commit(&self, message: &str) {
        self.git(&["commit", "--quiet", "--allow-empty", "-m", message]);
    }
}

/// A complete clients.json, with values of its own, for tests to change one fact of.
pub fn ci_clients() -> serde_json::Value {
    serde_json::json!({
        "context": "k3d-example",
        "faults_url": "https://faults.example",
        "links": { "nats": 1, "nats_web": 2, "realm_nats": 3 },
        "test_users": { "namespace": "users", "name": "users" },
        "panel_origin": "http://localhost:1000",
        "registry": {
            "host": "registry.example",
            "user": "pusher",
            "password": { "namespace": "registry", "name": "pusher", "key": "password" }
        },
        "tenant": { "source": "source", "kustomizations": ["first", "second"] }
    })
}

/// A CI cluster with [`ci_clients`]' facts, for tests that need one without a checkout.
pub fn ci_cluster() -> CiCluster {
    CiCluster {
        clients: CiClients::parse(&ci_clients().to_string()).unwrap(),
    }
}

/// What services of a stack in `root` see while it starts, on port block 20000 with its state
/// directory created and nothing published yet.
pub fn stack_context(root: &TempRoot) -> StackContext<'_> {
    let ports = PortLease {
        base: 20000,
        record: root.path("registry/stack.json"),
    };
    let ctx = StackContext::new(&root.ctx, ports);
    fs::create_dir_all(ctx.state()).unwrap();
    ctx
}

/// The message of `result`'s error. Panics when `result` succeeded.
pub fn refusal<T>(result: Result<T>) -> String {
    match result {
        Ok(_) => panic!("expected a refusal, but it succeeded"),
        Err(error) => error.to_string(),
    }
}

/// A components run with one attempt of each of `cases`, as a runner reports one attempt.
pub fn run(cases: &[(&str, Outcome)]) -> TestRun {
    TestRun {
        runner: Runner::Components,
        attempt_policy: AttemptPolicy::Exactly(1),
        cases: cases
            .iter()
            .map(|(id, outcome)| case(id, std::slice::from_ref(outcome)))
            .collect(),
        ..TestRun::default()
    }
}

/// A run reporting one attempt of the case `id`, which proves `requirement`, with `outcome`.
pub fn requirement_run(requirement: &str, id: &str, outcome: Outcome) -> TestRun {
    let mut reported = run(&[(id, outcome)]);
    reported.cases[0].requirement = Some(requirement.to_owned());
    reported
}

/// A components run under `policy` whose cases made `attempts`, in order.
pub fn attempted(policy: AttemptPolicy, attempts: &[Outcome]) -> TestRun {
    TestRun {
        runner: Runner::Components,
        attempt_policy: policy,
        cases: vec![case("a", attempts)],
        ..TestRun::default()
    }
}

/// The case `id` with one attempt per outcome, in order.
pub fn case(id: &str, outcomes: &[Outcome]) -> TestCase {
    TestCase {
        id: id.to_owned(),
        attempts: outcomes
            .iter()
            .map(|outcome| Attempt {
                outcome: outcome.clone(),
                ..Attempt::default()
            })
            .collect(),
        ..TestCase::default()
    }
}

/// The outcomes of the attempts of `run`'s case `id`. Panics when the run has no such case.
pub fn outcomes(run: &TestRun, id: &str) -> Vec<Outcome> {
    let case = run.cases.iter().find(|case| case.id == id).unwrap();
    case.attempts.iter().map(|a| a.outcome.clone()).collect()
}

/// An outcome a newer runner wrote that this build does not know.
pub fn unknown() -> Outcome {
    Outcome::Unknown(Default::default())
}

/// What [`report`](crate::results::report) writes for `run`, pointing at `results/panel`, and
/// whether it passed.
pub fn report_text(run: &TestRun, quarantine: &Quarantine) -> (Result<()>, String) {
    let mut out = Vec::new();
    let result =
        crate::results::report(run, quarantine, Some(Path::new("results/panel")), &mut out);
    (result, String::from_utf8(out).unwrap())
}

/// `cargo xtask e2e args` as the command line parses it.
pub fn e2e_args(args: &[&str]) -> Result<E2eArgs, clap::Error> {
    #[derive(clap::Parser)]
    struct Command {
        #[command(flatten)]
        args: E2eArgs,
    }
    let line = std::iter::once("e2e").chain(args.iter().copied());
    <Command as clap::Parser>::try_parse_from(line).map(|command| command.args)
}

/// A repository whose `base` branch gained a commit after `feature` left it.
pub fn diverged_branches() -> TempRoot {
    let root = TempRoot::new();
    root.git(&["init", "--quiet", "--initial-branch=base"]);
    root.save("shared.txt", "one\n");
    root.git(&["checkout", "--quiet", "-b", "feature"]);
    root.save("feature.txt", "reviewed\n");
    root.git(&["checkout", "--quiet", "base"]);
    root.save("other.txt", "from the base\n");
    root
}

/// A step `actor` took at `at_millis`.
pub fn scenario_step(at_millis: i64, actor: Option<&str>, says: &str) -> ScenarioStep {
    ScenarioStep {
        at_millis,
        actor: actor.map(str::to_owned),
        says: says.to_owned(),
        _unrecognized: None,
    }
}

/// `cargo xtask review report --json` for a change with nothing to say.
pub fn empty_change_report() -> serde_json::Value {
    serde_json::json!({
        "base": "base",
        "findings": [],
        "tests": {
            "added": [], "deleted": [], "weakened": [], "disabled": [],
            "expectations_rewritten": [], "harness_edits": [],
        },
        "change_map": [],
        "coverage": { "areas": [] },
    })
}

/// A failure with `message`.
pub fn failed(message: &str) -> Outcome {
    Outcome::Failed(Box::new(Failure {
        message: message.to_owned(),
        ..Failure::default()
    }))
}

/// The message of a failed `outcome`. Panics on any other outcome.
pub fn failure_message(outcome: &Outcome) -> &str {
    match outcome {
        Outcome::Failed(failure) => &failure.message,
        _ => panic!("the case did not fail"),
    }
}

/// A quarantine holding the case `id`.
pub fn quarantining(id: &str) -> Quarantine {
    toml::from_str(&format!(
        "[[case]]\nid = \"{id}\"\nreason = \"times out on CI\"\nissue = 7\n"
    ))
    .unwrap()
}

/// A runner whose first attempt reports `first` and that must never run a second attempt.
pub fn once(first: TestRun) -> impl FnMut(u32, &[String]) -> Result<TestRun> {
    move |n, _| {
        assert_eq!(n, 1, "nothing should run again");
        Ok(first.clone())
    }
}

/// A run of the one case `id` with `attempts`.
pub fn run_of(id: &str, attempts: Vec<Attempt>) -> TestRun {
    TestRun {
        runner: Runner::Panel,
        cases: vec![TestCase {
            id: id.to_owned(),
            attempts,
            ..TestCase::default()
        }],
        ..TestRun::default()
    }
}

/// A failed attempt over `span` (Unix milliseconds) with `artifacts` of these kinds and paths.
pub fn failed_attempt(span: (i64, i64), artifacts: &[(ArtifactKind, &str)]) -> Attempt {
    Attempt {
        outcome: failed("boom"),
        span: Some(Span {
            start_millis: span.0,
            end_millis: span.1,
            ..Span::default()
        }),
        artifacts: artifacts
            .iter()
            .map(|(kind, path)| Artifact {
                kind: kind.clone(),
                path: (*path).to_owned(),
                ..Artifact::default()
            })
            .collect(),
        ..Attempt::default()
    }
}

/// Writes a failed panel run's raw results under `<root>/<at>/`, as a suite leaves them: the run
/// file, and in its attempt folder `attempts/1` the drive log, the whole recording, a clip with its
/// preview, a screenshot, a panel log and a failure folder's cut log and spans, each listed as an
/// artifact where it is one; plus coverage beside the run's folder.
pub fn raw_failed_run(root: &TempRoot, at: &str) {
    let attempt_folder = format!("{at}/attempts/1");
    for (file, contents) in [
        ("drive.log", "flutter drive"),
        ("run.mp4", "video"),
        ("clips/conn.mp4", "clip"),
        ("clips/conn.webp", "preview"),
        ("screenshots/CONN-1/failure.png", "png"),
        ("logs/CONN-1/panel.log", "panel"),
        ("failures/conn/backend.log", "backend"),
        ("failures/conn/spans.otlp.jsonl", "{}"),
    ] {
        root.write(&format!("{attempt_folder}/{file}"), contents);
    }
    let coverage = Path::new(at).parent().unwrap().join("coverage");
    root.write(&format!("{}/panel.lcov", coverage.display()), "SF:a.dart");
    root.write(
        &format!("{}/panel.lcov.commit", coverage.display()),
        "abc123",
    );
    let mut attempt = failed_attempt(
        (0, 1),
        &[
            (ArtifactKind::Clip, "clips/conn.mp4"),
            (ArtifactKind::Screenshot, "screenshots/CONN-1/failure.png"),
            (ArtifactKind::LogExcerpt, "logs/CONN-1/panel.log"),
            (ArtifactKind::LogExcerpt, "failures/conn/backend.log"),
            (ArtifactKind::Spans, "failures/conn/spans.otlp.jsonl"),
        ],
    );
    attempt.folder = "attempts/1".to_owned();
    let mut run = run_of("[CONN-1] Reconnects", vec![attempt]);
    run.cases[0].requirement = Some("CONN-1".to_owned());
    crate::results::write(&run, &root.path(&format!("{at}/test_run.json"))).unwrap();
}

/// Every file below `dir`, relative to it and sorted; empty when `dir` is absent.
pub fn files_below(dir: &Path) -> Vec<String> {
    let mut files: Vec<String> = crate::review::files_in(dir)
        .unwrap()
        .iter()
        .map(|path| path.strip_prefix(dir).unwrap().display().to_string())
        .collect();
    files.sort();
    files
}

/// A passing attempt over `span` (Unix milliseconds) without artifacts.
pub fn passed_attempt(span: (i64, i64)) -> Attempt {
    Attempt {
        outcome: Outcome::Passed,
        ..failed_attempt(span, &[])
    }
}

/// One OTLP JSON export request from `service` holding `spans`, each
/// `(trace id, span id, parent span id, start in Unix nanoseconds)`, in the collector's shape.
pub fn otlp_request(service: &str, spans: &[(&str, &str, &str, i64)]) -> serde_json::Value {
    let spans: Vec<_> = spans
        .iter()
        .map(|(trace, span, parent, start)| {
            serde_json::json!({
                "traceId": trace,
                "spanId": span,
                "parentSpanId": parent,
                "name": "work",
                "startTimeUnixNano": start.to_string(),
            })
        })
        .collect();
    serde_json::json!({ "resourceSpans": [{
        "resource": { "attributes": [
            { "key": "service.name", "value": { "stringValue": service } },
        ] },
        "scopeSpans": [{ "scope": { "name": "test" }, "spans": spans }],
    }] })
}

/// Every span in `jsonl` (OTLP JSON export requests, one per line) as `<service>/<span id>`, in
/// file order.
pub fn otlp_spans(jsonl: &str) -> Vec<String> {
    let mut spans = Vec::new();
    for line in jsonl.lines() {
        let request: serde_json::Value = serde_json::from_str(line).unwrap();
        for resource in request["resourceSpans"].as_array().unwrap() {
            let service = resource["resource"]["attributes"][0]["value"]["stringValue"]
                .as_str()
                .unwrap();
            for scope in resource["scopeSpans"].as_array().unwrap() {
                for span in scope["spans"].as_array().unwrap() {
                    spans.push(format!("{service}/{}", span["spanId"].as_str().unwrap()));
                }
            }
        }
    }
    spans
}

/// The names of the entries in `dir`, sorted.
pub fn file_names(dir: &Path) -> Vec<String> {
    let mut names: Vec<String> = fs::read_dir(dir)
        .unwrap()
        .map(|entry| entry.unwrap().file_name().to_string_lossy().into_owned())
        .collect();
    names.sort();
    names
}

/// The exit status of a process that exited with `code`.
pub fn exited(code: i32) -> ExitStatus {
    ExitStatus::from_raw(code << 8)
}

/// The pid of a process that has exited and been reaped.
pub fn dead_pid() -> u32 {
    let mut child = Command::new("true").spawn().unwrap();
    let pid = child.id();
    child.wait().unwrap();
    pid
}

/// The port of a local server answering every request with `status`.
pub fn answering(status: &'static str) -> u16 {
    let listener = TcpListener::bind((Ipv4Addr::LOCALHOST, 0)).unwrap();
    let port = listener.local_addr().unwrap().port();
    thread::spawn(move || {
        for stream in listener.incoming() {
            let mut stream = stream.unwrap();
            // The whole request head, so closing never resets the connection under the reply.
            let mut request = Vec::new();
            let mut byte = [0];
            while !request.ends_with(b"\r\n\r\n") && stream.read(&mut byte).unwrap_or(0) == 1 {
                request.push(byte[0]);
            }
            let _ = write!(stream, "HTTP/1.1 {status}\r\nContent-Length: 0\r\n\r\n");
        }
    });
    port
}

/// The record of a stack `name` that `owner` supervises with process `groups`, written into
/// `registry` on port block 20000.
pub fn stack_record(registry: &Path, name: &str, owner: u32, groups: Vec<u32>) -> StackRecord {
    let record = StackRecord {
        path: registry.join(format!("{name}.json")),
        worktree: PathBuf::from(format!("/worktrees/{name}")),
        owner,
        base: 20000,
        groups,
    };
    record.write().unwrap();
    record
}

/// A step of the xtask area running `sh -c script` within `budget`.
pub fn shell(name: &'static str, script: &'static str, budget: Duration) -> Step {
    Step {
        name,
        area: Area::Xtask,
        run: Run::Program {
            cwd: ".",
            program: "sh",
            args: Box::leak(Box::new(["-c", script])),
        },
        heavy: false,
        budget,
        needs_generate: false,
        coverage: None,
        junit: None,
    }
}

/// The command line names of the areas `steps` belong to.
pub fn area_names(steps: &[&Step]) -> BTreeSet<String> {
    steps
        .iter()
        .map(|step| step.area.to_possible_value().unwrap().get_name().to_owned())
        .collect()
}

/// Commit scopes allowing `scopes` and requiring one for `feat`, loaded from a
/// `commit-scopes.json` the way the hook loads it.
pub fn scopes(scopes: &[&str]) -> Scopes {
    let root = TempRoot::new();
    let json = serde_json::json!({ "scopes": scopes, "scopeRequiredForTypes": ["feat"] });
    root.write("commit-scopes.json", &json.to_string());
    Scopes::load(&root.ctx).unwrap()
}

/// Declares a fake stack service `$name` that only names the services it needs, optionally
/// followed by `; provides ROLE, ...` and `; needs_roles ROLE, ...`: its command does nothing and
/// it is ready once that command exits.
macro_rules! fake_service {
    ($name:ident, $($need:ident),*
        $(; provides $($provided:path),+)?
        $(; needs_roles $($role:path),+)?) => {
        pub struct $name;
        impl $crate::stack::spec::Service for $name {
            const ID: $crate::stack::spec::ServiceId =
                $crate::stack::spec::ServiceId(stringify!($name));
            fn needs(&self) -> &'static [$crate::stack::spec::ServiceId] {
                &[$(<$need as $crate::stack::spec::Service>::ID),*]
            }
            fn provides(&self) -> &'static [$crate::stack::spec::Role] {
                &[$($($provided),+)?]
            }
            fn needs_roles(&self) -> &'static [$crate::stack::spec::Role] {
                &[$($($role),+)?]
            }
            fn command(
                &self,
                _: &$crate::stack::spec::StackContext,
            ) -> ::anyhow::Result<::std::process::Command> {
                Ok(::std::process::Command::new("true"))
            }
            fn ready(&self, _: &$crate::stack::spec::StackContext) -> $crate::stack::spec::Probe {
                $crate::stack::spec::Probe::ExitSuccess
            }
        }
    };
}
pub(crate) use fake_service;

/// The ids of `services`, in their order.
pub fn ids(services: &[&dyn crate::stack::spec::DynService]) -> Vec<&'static str> {
    services.iter().map(|service| service.id().0).collect()
}

/// Each drive an attempt made, in order: its folder below the suite folder and the ids it was
/// handed.
pub type Drove = Vec<(String, Vec<String>)>;

/// The drives `drives` names, as [`drive_attempts`] returns them: (folder, ids) each.
pub fn drove(drives: &[(&str, &[&str])]) -> Drove {
    drives
        .iter()
        .map(|(folder, ids)| {
            (
                (*folder).to_owned(),
                ids.iter().map(|id| (*id).to_owned()).collect(),
            )
        })
        .collect()
}

/// Folds the attempts of `args` on target `T`, where every drive reports
/// `reply(drive folder, attempt)` and exits 0, the folder `None` for the attempt folder itself. Returns the folded run and each drive made, in
/// order, as (its folder below the suite folder, the ids it was handed).
pub fn drive_attempts<T: crate::e2e::Target>(
    args: &E2eArgs,
    reply: impl Fn(Option<&str>, u32) -> TestRun,
) -> Result<(TestRun, Drove)> {
    let evidence = Path::new("results/suite");
    let drove = std::cell::RefCell::new(Vec::new());
    let folded = crate::results::attempts(
        args.policy(),
        &args.only,
        &Quarantine::default(),
        |n, ids| {
            crate::e2e::attempt::<T>(evidence, n, ids, |drive, out, ids| {
                let folder = out.strip_prefix(evidence).unwrap().display().to_string();
                drove.borrow_mut().push((folder, ids.to_vec()));
                Ok((reply(drive.folder, n), exited(0)))
            })
        },
    )?;
    Ok((folded, drove.into_inner()))
}
