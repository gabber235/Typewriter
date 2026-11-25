//! `cargo xtask goldens approve`: records the frames a game run captured as the approved goldens,
//! from a local run or, with `--pr`, from the game results of a pull request's latest CI run.
//! A requirement that names a golden writes its frame as a PNG into its attempt's folder, beside a
//! `<name>.golden` candidate (a `GoldenCandidate`), which the run file lists as the attempt's golden
//! artifact, that says which golden file of the repository it belongs to, the frame's hash and size,
//! the renderer that drew it, and whether that is the pinned renderer, as the run judged it.
//! Approving writes the hash, size and renderer into that golden file (a `Golden`; both are readable
//! Skir JSON, declared in `skir-src/harness/v1/golden.skir`), keeps the PNG
//! among the local golden images under its hash, and pushes it to the evidence branch as
//! `goldens/<hash>.png`, beside `goldens/<hash>.approved-at`, the moment it was approved, which
//! the weekly prune reads to drop images no golden names any more; the repository holds only the
//! hash. Before a game run,
//! [`fetch_missing`] brings every golden's image the machine lacks, so a frame that differs from
//! its golden shows where while the framework stays offline. A golden is exact only for the
//! renderer that drew it, so approve refuses any frame the pinned renderer did not draw.

use std::collections::BTreeMap;
use std::fs;
use std::path::{Path, PathBuf};
use std::time::{SystemTime, UNIX_EPOCH};

use anyhow::{Context as _, Result, bail};

use crate::branch::{BranchCheckout, REPOSITORY};
use crate::results::{self, ArtifactKind};
use crate::skirout::base::harness::v1::golden::{Golden, GoldenCandidate};
use crate::{CommandExt as _, Context, evidence};

/// The local golden images, each named by its hash, relative to the repository root.
const IMAGES: &str = "services/build/playtest/goldens";

/// The folder of the golden images on the evidence branch, beside the pull requests' folders,
/// which pruning empties, never inside them.
const ON_BRANCH: &str = "goldens";

/// The suffix of the file beside each golden image on the evidence branch that holds the Unix
/// seconds it was approved.
const APPROVED_AT: &str = "approved-at";

/// The long lived branches, the ones the devenv action trusts a push to: an image a golden file on
/// any of them names stays on the evidence branch however old it is.
pub(crate) const LONG_LIVED: [&str; 2] = ["develop", "features/v1"];

/// The artifacts CI's game suites upload their staged results as: the product's and the framework's.
const GAME_ARTIFACTS: [&str; 2] = ["results-e2e-game", "results-e2e-playtest"];

/// Where `approve --pr` downloads a pull request's game frames, relative to the repository root.
const PULL_REQUEST_FRAMES: &str = ".xtask/state/goldens";

#[derive(clap::Subcommand)]
pub enum GoldensCommand {
    /// Records each golden a game run captured: its golden file takes the frame's hash, size and
    /// renderer, and the frame joins the local golden images.
    Approve {
        /// The folder of the runs to approve from; by default every local run, so the last
        /// `cargo xtask e2e game` and `cargo xtask e2e playtest` runs.
        from: Option<PathBuf>,
        /// Approves the frames the latest CI run of this pull request's head captured, which ran
        /// on the pinned runner, instead of a local run.
        #[arg(long, conflicts_with = "from")]
        pr: Option<u64>,
    },
}

pub fn run(ctx: &Context, command: &GoldensCommand) -> Result<()> {
    match command {
        GoldensCommand::Approve { from, pr } => {
            let from = match (from, pr) {
                (Some(from), _) => from.clone(),
                (None, Some(pr)) => pull_request_frames(
                    *pr,
                    &ctx.root.join(PULL_REQUEST_FRAMES).join(format!("pr-{pr}")),
                    |args| ctx.tool(".", "gh", args).output_text(),
                )?,
                (None, None) => ctx.root.join(evidence::RESULTS),
            };
            let approved = approve(&ctx.root, &from, &ctx.root.join(IMAGES))?;
            for golden in &approved {
                println!("goldens: approved {}", golden.golden);
            }
            let images: Vec<PathBuf> = approved.into_iter().map(|it| it.image).collect();
            publish(ctx, &images)?;
            println!(
                "goldens: pushed {} image(s) to the {} branch",
                images.len(),
                evidence::BRANCH
            );
            Ok(())
        }
    }
}

/// Downloads into `into` the results each game suite of the latest CI run of pull request `pr`'s
/// head staged, through `gh`, one folder per suite, and returns `into`, which approve reads as it
/// reads the local runs. A suite the run did not plan uploaded nothing; only a run of no game suite
/// fails.
fn pull_request_frames(
    pr: u64,
    into: &Path,
    gh: impl Fn(&[&str]) -> Result<String>,
) -> Result<PathBuf> {
    let pr_number = pr.to_string();
    let head = gh(&[
        "pr",
        "view",
        &pr_number,
        "--repo",
        REPOSITORY,
        "--json",
        "headRefOid",
        "--jq",
        ".headRefOid",
    ])?;
    let head = head.trim();
    let run = gh(&[
        "run",
        "list",
        "--repo",
        REPOSITORY,
        "--workflow",
        "ci.yml",
        "--commit",
        head,
        "--limit",
        "1",
        "--json",
        "databaseId",
        "--jq",
        ".[0].databaseId",
    ])?;
    let run = run.trim();
    if run.is_empty() {
        bail!("pull request {pr} has no CI run of its head {head} yet");
    }
    if into.exists() {
        fs::remove_dir_all(into).with_context(|| format!("cannot clear {}", into.display()))?;
    }
    let mut missing = Vec::new();
    for artifact in GAME_ARTIFACTS {
        let dir = into.join(artifact);
        let dir = dir.to_string_lossy();
        if let Err(error) = gh(&[
            "run", "download", run, "--repo", REPOSITORY, "--name", artifact, "--dir", &dir,
        ]) {
            missing.push(format!("{artifact}: {error:#}"));
        }
    }
    if missing.len() == GAME_ARTIFACTS.len() {
        bail!(
            "CI run {run} has no game results to approve from: {}",
            missing.join("; ")
        );
    }
    Ok(into.to_path_buf())
}

/// A golden [`approve`] wrote: its golden file, relative to the repository root, and the local image
/// it was approved from.
#[derive(Debug)]
struct Approved {
    golden: String,
    image: PathBuf,
}

/// Puts each of `images` into the evidence branch checked out at `branch`, as `goldens/<hash>.png`,
/// beside `goldens/<hash>.approved-at` holding `approved_at`, in Unix seconds.
fn place(images: &[PathBuf], branch: &Path, approved_at: u64) -> Result<()> {
    let folder = branch.join(ON_BRANCH);
    fs::create_dir_all(&folder).with_context(|| format!("cannot create {}", folder.display()))?;
    for image in images {
        let name = image.file_name().context("a golden image without a name")?;
        let hash = image.file_stem().context("a golden image without a name")?;
        fs::copy(image, folder.join(name))
            .with_context(|| format!("cannot copy {} onto the evidence branch", image.display()))?;
        let stamp = folder.join(format!("{}.{APPROVED_AT}", hash.to_string_lossy()));
        fs::write(&stamp, approved_at.to_string())
            .with_context(|| format!("cannot write {}", stamp.display()))?;
    }
    Ok(())
}

/// Drops from the evidence branch checked out at `branch` each golden image whose hash is not
/// among `used` and that was approved before `cutoff`, in Unix seconds, with its approval time. An
/// image without one counts as approved long ago.
pub(crate) fn drop_unused(branch: &Path, used: &[String], cutoff: u64) -> Result<()> {
    let folder = branch.join(ON_BRANCH);
    if !folder.exists() {
        return Ok(());
    }
    for entry in fs::read_dir(&folder)? {
        let image = entry?.path();
        if image.extension().is_none_or(|it| it != "png") {
            continue;
        }
        let hash = image
            .file_stem()
            .context("a golden image without a name")?
            .to_string_lossy()
            .into_owned();
        if used.contains(&hash) {
            continue;
        }
        let stamp = folder.join(format!("{hash}.{APPROVED_AT}"));
        let approved_at = fs::read_to_string(&stamp)
            .ok()
            .and_then(|text| text.trim().parse::<u64>().ok())
            .unwrap_or(0);
        if approved_at < cutoff {
            for path in [&image, &stamp] {
                if path.exists() {
                    fs::remove_file(path)
                        .with_context(|| format!("cannot remove {}", path.display()))?;
                }
            }
        }
    }
    Ok(())
}

/// Fetches into `images` the image of each golden in `hashes` it does not hold yet, through `fetch`,
/// which answers None for an image the evidence branch does not hold; returns each hash it got no
/// image of, with why. An image only draws a diff, so no failed fetch stops the others.
fn fetch_into(
    images: &Path,
    hashes: &[&str],
    fetch: impl Fn(&str) -> Result<Option<Vec<u8>>>,
) -> Result<Vec<(String, String)>> {
    fs::create_dir_all(images).with_context(|| format!("cannot create {}", images.display()))?;
    let mut unfetched = Vec::new();
    for hash in hashes {
        let image = images.join(format!("{hash}.png"));
        if image.exists() {
            continue;
        }
        let why = match fetch(hash) {
            Ok(Some(bytes)) => {
                fs::write(&image, bytes)
                    .with_context(|| format!("cannot write {}", image.display()))?;
                continue;
            }
            Ok(None) => "the evidence branch holds no image of it".to_owned(),
            Err(error) => format!("{error:#}"),
        };
        unfetched.push(((*hash).to_owned(), why));
    }
    Ok(unfetched)
}

/// Fetches the image of every golden the repository holds that the local golden images lack,
/// from the evidence branch, so a frame that differs from its golden shows where. A golden whose
/// image the branch does not hold, or that gh could not fetch, is said with why, and its frames fail
/// without a diff; the run goes on.
pub fn fetch_missing(ctx: &Context) -> Result<()> {
    let hashes = named(ctx)?;
    let hashes: Vec<&str> = hashes.iter().map(String::as_str).collect();
    for (hash, why) in fetch_into(&ctx.root.join(IMAGES), &hashes, |hash| {
        fetch_image(ctx, hash)
    })? {
        println!(
            "goldens: no image of golden {hash} ({why}); a frame that differs from it fails without a diff"
        );
    }
    Ok(())
}

/// The hash each golden file of the checkout names.
pub(crate) fn named(ctx: &Context) -> Result<Vec<String>> {
    let files = ctx
        .tool(".", "git", &["ls-files", "-z", "--", "*.golden"])
        .output_text()?;
    let mut hashes = Vec::new();
    for file in files.split('\0').filter(|it| !it.is_empty()) {
        let path = ctx.root.join(file);
        let text =
            fs::read_to_string(&path).with_context(|| format!("cannot read {}", path.display()))?;
        hashes.push(golden_in(file, &text)?.sha256);
    }
    Ok(hashes)
}

/// Fetches every long lived branch from origin, then returns the hash each golden file on any of
/// them names, once each.
pub(crate) fn named_on_long_lived(ctx: &Context) -> Result<Vec<String>> {
    let refs: Vec<String> = LONG_LIVED
        .iter()
        .map(|branch| format!("origin/{branch}"))
        .collect();
    for branch in LONG_LIVED {
        ctx.tool(
            ".",
            "git",
            &[
                "fetch",
                "--quiet",
                "--depth=1",
                "origin",
                &format!("+refs/heads/{branch}:refs/remotes/origin/{branch}"),
            ],
        )
        .output_text()
        .with_context(|| format!("cannot fetch {branch}, whose goldens keep their images"))?;
    }
    named_on(ctx, &refs.iter().map(String::as_str).collect::<Vec<_>>())
}

/// The hash each golden file at any of `refs` names, once each.
fn named_on(ctx: &Context, refs: &[&str]) -> Result<Vec<String>> {
    let mut hashes = Vec::new();
    for at in refs {
        let files = ctx
            .tool(".", "git", &["ls-tree", "-r", "-z", "--name-only", at])
            .output_text()?;
        for file in files.split('\0').filter(|it| it.ends_with(".golden")) {
            let text = ctx
                .tool(".", "git", &["show", &format!("{at}:{file}")])
                .output_text()?;
            let hash = golden_in(&format!("{at}:{file}"), &text)?.sha256;
            if !hashes.contains(&hash) {
                hashes.push(hash);
            }
        }
    }
    Ok(hashes)
}

/// The golden the golden file `file` holding `text` holds.
fn golden_in(file: &str, text: &str) -> Result<Golden> {
    Golden::serializer()
        .from_json(text, skir_client::UnrecognizedValues::Drop)
        .map_err(|error| anyhow::anyhow!("{file} is not a golden: {error:?}"))
}

/// The image of the golden `hash` from the evidence branch, or None when the branch holds none,
/// through GitHub's contents API, which serves a push at once.
fn fetch_image(ctx: &Context, hash: &str) -> Result<Option<Vec<u8>>> {
    let path = format!(
        "repos/{REPOSITORY}/contents/{ON_BRANCH}/{hash}.png?ref={}",
        evidence::BRANCH
    );
    let output = ctx
        .tool(
            ".",
            "gh",
            &["api", "-H", "Accept: application/vnd.github.raw", &path],
        )
        .output()
        .context("cannot start gh to fetch a golden image")?;
    if output.status.success() {
        return Ok(Some(output.stdout));
    }
    let error = String::from_utf8_lossy(&output.stderr);
    if error.contains("HTTP 404") {
        return Ok(None);
    }
    bail!("gh could not fetch golden image {hash}: {}", error.trim())
}

/// Pushes the approved `images` onto the evidence branch, where every machine's game run fetches
/// them; a push that lost a race with another job moves onto its commit.
fn publish(ctx: &Context, images: &[PathBuf]) -> Result<()> {
    let branch = BranchCheckout::clone_shallow(ctx, evidence::BRANCH, "Typewriter goldens")?;
    let now = SystemTime::now()
        .duration_since(UNIX_EPOCH)
        .expect("the system clock is after the Unix epoch");
    place(images, &branch.path(""), now.as_secs())?;
    branch.commit_and_push(ctx, &format!("goldens: {} approved", images.len()))
}

/// Approves every golden captured under `from` into its golden file below `root`, and copies each
/// frame into `images`; returns the goldens it wrote.
fn approve(root: &Path, from: &Path, images: &Path) -> Result<Vec<Approved>> {
    let mut chosen: BTreeMap<String, Captured> = BTreeMap::new();
    for captured in captured_under(from)? {
        let candidate = &captured.candidate;
        if !candidate.pinned {
            let renderer = &candidate.golden.renderer;
            bail!(
                "golden {}: its frame {} was drawn by {}, {}, {}, {}, {}, not the pinned renderer; \
                 goldens are approved only from frames the pinned runner drew",
                candidate.file,
                captured.png.display(),
                renderer.backend,
                renderer.device,
                renderer.driver,
                renderer.os,
                renderer.arch,
            );
        }
        match chosen.get(&candidate.file) {
            Some(earlier) if earlier.candidate.golden != candidate.golden => bail!(
                "the run captured golden {} as two different frames ({} and {}): a scene that \
                 changes between attempts cannot be a golden",
                candidate.file,
                earlier.png.display(),
                captured.png.display()
            ),
            Some(_) => {}
            None => {
                chosen.insert(candidate.file.clone(), captured);
            }
        }
    }
    if chosen.is_empty() {
        bail!("the run in {} captured no golden", from.display());
    }
    fs::create_dir_all(images).with_context(|| format!("cannot create {}", images.display()))?;
    let mut approved = Vec::new();
    for (golden_file, captured) in chosen {
        let file = root.join(&golden_file);
        let parent = file.parent().context("a golden file without a folder")?;
        fs::create_dir_all(parent)
            .with_context(|| format!("cannot create {}", parent.display()))?;
        let golden = &captured.candidate.golden;
        let text = Golden::serializer().to_json(golden, skir_client::JsonFlavor::Readable);
        fs::write(&file, text).with_context(|| format!("cannot write {}", file.display()))?;
        let image = images.join(format!("{}.png", golden.sha256));
        fs::copy(&captured.png, &image).with_context(|| {
            format!(
                "cannot copy {} to {}",
                captured.png.display(),
                image.display()
            )
        })?;
        approved.push(Approved {
            golden: golden_file,
            image,
        });
    }
    Ok(approved)
}

/// One frame a run captured: its candidate and its PNG, beside the candidate.
struct Captured {
    candidate: GoldenCandidate,
    png: PathBuf,
}

/// Every frame the verdict runs under `folder` captured, from the golden candidates their run files
/// list. A demo run's frames are evidence only: its clip draws frames between ticks, so they need not
/// match the verdict run's.
fn captured_under(folder: &Path) -> Result<Vec<Captured>> {
    let mut found = Vec::new();
    for (path, run) in results::read_all(folder)? {
        if run.evidence_only {
            continue;
        }
        let at = path.parent().context("a run file without a folder")?;
        for case in &run.cases {
            for (file, artifact) in results::artifacts(case) {
                if artifact.kind == ArtifactKind::Golden {
                    found.push(read_captured(&at.join(file))?);
                }
            }
        }
    }
    Ok(found)
}

fn read_captured(file: &Path) -> Result<Captured> {
    let text =
        fs::read_to_string(file).with_context(|| format!("cannot read {}", file.display()))?;
    let candidate = GoldenCandidate::serializer()
        .from_json(&text, skir_client::UnrecognizedValues::Drop)
        .map_err(|error| {
            anyhow::anyhow!("{} is not a golden candidate: {error:?}", file.display())
        })?;
    let png = file.with_file_name(&candidate.image);
    Ok(Captured { candidate, png })
}

#[cfg(test)]
mod tests {
    use std::fs;

    use std::cell::RefCell;

    use super::{Golden, approve, fetch_into, named_on, place, pull_request_frames};
    use crate::results::ArtifactKind;
    use crate::skirout::base::harness::v1::golden::Renderer;
    use crate::test_support::{TempRoot, captured_golden};

    /// A candidate as the framework writes it beside a captured frame.
    const SIDEBAR: &str = r#"{
  "file": "services/playtest/framework/src/gameTest/goldens/sidebar.golden",
  "image": "sidebar.png",
  "golden": {
    "sha256": "5e1d",
    "width": 854,
    "height": 480,
    "renderer": {
      "backend": "Vulkan",
      "device": "llvmpipe (LLVM 20.1.2, 256 bits)",
      "driver": "1.4.318 llvmpipe Mesa 26.2.5 (LLVM 20.1.2)",
      "os": "Linux",
      "arch": "amd64"
    }
  },
  "pinned": true
}"#;

    #[test]
    fn approve_writes_the_frames_hash_size_and_renderer_into_its_golden_file_and_keeps_the_frame() {
        let (root, run) = (TempRoot::new(), TempRoot::new());
        captured_golden(
            &run,
            "GOLDEN-1 a sidebar/attempt-1/sidebar",
            SIDEBAR,
            "png bytes",
        );

        let approved = approve(&root.ctx.root, &run.ctx.root, &root.path("images")).unwrap();

        let golden = "services/playtest/framework/src/gameTest/goldens/sidebar.golden";
        let goldens: Vec<_> = approved.iter().map(|it| it.golden.as_str()).collect();
        assert_eq!(goldens, [golden]);
        assert_eq!(approved[0].image, root.path("images/5e1d.png"));
        let written = fs::read_to_string(root.path(golden)).unwrap();
        assert_eq!(
            Golden::serializer()
                .from_json(&written, skir_client::UnrecognizedValues::Keep)
                .unwrap(),
            Golden {
                sha256: "5e1d".to_owned(),
                width: 854,
                height: 480,
                renderer: Renderer {
                    backend: "Vulkan".to_owned(),
                    device: "llvmpipe (LLVM 20.1.2, 256 bits)".to_owned(),
                    driver: "1.4.318 llvmpipe Mesa 26.2.5 (LLVM 20.1.2)".to_owned(),
                    os: "Linux".to_owned(),
                    arch: "amd64".to_owned(),
                    _unrecognized: None,
                },
                _unrecognized: None,
            }
        );
        // Readable, so a reviewer sees what a golden pins.
        assert!(written.contains(r#""sha256": "5e1d""#), "{written}");
        assert_eq!(
            fs::read_to_string(root.path("images/5e1d.png")).unwrap(),
            "png bytes"
        );
    }

    #[test]
    fn approve_takes_a_golden_every_attempt_captured_alike_once() {
        let (root, run) = (TempRoot::new(), TempRoot::new());
        for attempt in ["attempt-1", "attempt-2"] {
            captured_golden(
                &run,
                &format!("GOLDEN-1 a sidebar/{attempt}/sidebar"),
                SIDEBAR,
                "png bytes",
            );
        }

        let approved = approve(&root.ctx.root, &run.ctx.root, &root.path("images")).unwrap();

        assert_eq!(approved.len(), 1);
    }

    #[test]
    fn approve_takes_only_the_goldens_the_run_file_names() {
        let (root, run) = (TempRoot::new(), TempRoot::new());
        captured_golden(
            &run,
            "GOLDEN-1 a sidebar/attempt-1/sidebar",
            SIDEBAR,
            "png bytes",
        );
        run.write(
            "GOLDEN-1 a sidebar/attempt-1/hotbar.golden",
            &SIDEBAR.replace("sidebar", "hotbar"),
        );
        run.write("GOLDEN-1 a sidebar/attempt-1/hotbar.png", "png bytes");

        let approved = approve(&root.ctx.root, &run.ctx.root, &root.path("images")).unwrap();

        let goldens: Vec<_> = approved.iter().map(|it| it.golden.as_str()).collect();
        assert_eq!(
            goldens,
            ["services/playtest/framework/src/gameTest/goldens/sidebar.golden"]
        );
    }

    #[test]
    fn approve_refuses_a_golden_the_run_captured_as_two_different_frames_and_writes_nothing() {
        let (root, run) = (TempRoot::new(), TempRoot::new());
        captured_golden(
            &run,
            "GOLDEN-1 a sidebar/attempt-1/sidebar",
            SIDEBAR,
            "png bytes",
        );
        captured_golden(
            &run,
            "GOLDEN-1 a sidebar/attempt-2/sidebar",
            &SIDEBAR.replace("5e1d", "0bad"),
            "other",
        );

        let error = approve(&root.ctx.root, &run.ctx.root, &root.path("images")).unwrap_err();

        assert!(
            error.to_string().contains("two different frames"),
            "{error:#}"
        );
        assert!(!root.path("services").exists());
    }

    #[test]
    fn approve_takes_no_frame_from_a_demo_run_whose_clip_drew_extra_frames() {
        let (root, run) = (TempRoot::new(), TempRoot::new());
        captured_golden(
            &run,
            "GOLDEN-1 a sidebar/attempt-1/sidebar",
            SIDEBAR,
            "png bytes",
        );
        run.write(
            "playtest-demos/GOLDEN-1 a sidebar/demo/sidebar.golden",
            &SIDEBAR.replace("5e1d", "0bad"),
        );
        run.write(
            "playtest-demos/GOLDEN-1 a sidebar/demo/sidebar.png",
            "other",
        );
        let mut demo = crate::test_support::failed_attempt(
            (0, 1),
            &[(ArtifactKind::Golden, "sidebar.golden")],
        );
        demo.folder = "GOLDEN-1 a sidebar/demo".to_owned();
        let mut demos = crate::test_support::run_of("GOLDEN-1 a sidebar", vec![demo]);
        demos.evidence_only = true;
        crate::results::write(&demos, &run.path("playtest-demos/test_run.json")).unwrap();

        let approved = approve(&root.ctx.root, &run.ctx.root, &root.path("images")).unwrap();

        assert_eq!(approved.len(), 1);
        assert_eq!(approved[0].image, root.path("images/5e1d.png"));
    }

    #[test]
    fn approve_refuses_a_frame_another_renderer_drew_names_it_and_writes_nothing() {
        let (root, run) = (TempRoot::new(), TempRoot::new());
        captured_golden(
            &run,
            "GOLDEN-1 a sidebar/attempt-1/sidebar",
            &SIDEBAR
                .replace("Vulkan", "OpenGL")
                .replace("llvmpipe (LLVM 20.1.2, 256 bits)", "Apple M1 Max")
                .replace(
                    "1.4.318 llvmpipe Mesa 26.2.5 (LLVM 20.1.2)",
                    "4.1 Metal - 89.4",
                )
                .replace("Linux", "Mac OS X")
                .replace("amd64", "aarch64")
                .replace(r#""pinned": true"#, r#""pinned": false"#),
            "png bytes",
        );

        let error = approve(&root.ctx.root, &run.ctx.root, &root.path("images")).unwrap_err();

        assert!(
            error.to_string().contains(
                "was drawn by OpenGL, Apple M1 Max, 4.1 Metal - 89.4, Mac OS X, aarch64, \
                 not the pinned renderer"
            ),
            "{error:#}"
        );
        assert!(!root.path("services").exists());
        assert!(!root.path("images").exists());
    }

    #[test]
    fn approve_of_a_run_that_captured_no_golden_says_so() {
        let (root, run) = (TempRoot::new(), TempRoot::new());

        let error = approve(&root.ctx.root, &run.ctx.root, &root.path("images")).unwrap_err();

        assert!(
            error.to_string().contains("captured no golden"),
            "{error:#}"
        );
    }

    #[test]
    fn an_approved_image_goes_onto_the_evidence_branch_by_its_hash_with_when_it_was_approved() {
        let (images, branch) = (TempRoot::new(), TempRoot::new());
        images.write("5e1d.png", "png bytes");
        branch.write("pr/546/abc1234/frame.png", "a pull request's frame");

        place(&[images.path("5e1d.png")], &branch.ctx.root, 1_700_000_000).unwrap();

        assert_eq!(
            fs::read_to_string(branch.path("goldens/5e1d.png")).unwrap(),
            "png bytes"
        );
        assert_eq!(
            fs::read_to_string(branch.path("goldens/5e1d.approved-at")).unwrap(),
            "1700000000"
        );
        assert!(branch.path("pr/546/abc1234/frame.png").exists());
    }

    #[test]
    fn a_run_fetches_the_image_of_each_golden_it_lacks_and_none_it_holds() {
        let images = TempRoot::new();
        images.write("held.png", "held");
        let asked = RefCell::new(Vec::new());

        let unfetched = fetch_into(
            &images.ctx.root,
            &["held", "pushed", "never-pushed"],
            |hash| {
                asked.borrow_mut().push(hash.to_owned());
                Ok((hash == "pushed").then(|| b"png bytes".to_vec()))
            },
        )
        .unwrap();

        assert_eq!(asked.into_inner(), ["pushed", "never-pushed"]);
        assert_eq!(
            fs::read_to_string(images.path("pushed.png")).unwrap(),
            "png bytes"
        );
        assert_eq!(
            unfetched,
            [(
                "never-pushed".to_owned(),
                "the evidence branch holds no image of it".to_owned()
            )]
        );
        assert!(!images.path("never-pushed.png").exists());
    }

    #[test]
    fn a_golden_image_that_cannot_be_fetched_is_named_with_why_and_the_others_still_arrive() {
        let images = TempRoot::new();

        let unfetched = fetch_into(&images.ctx.root, &["unreachable", "pushed"], |hash| {
            if hash == "unreachable" {
                anyhow::bail!("gh could not fetch golden image unreachable: HTTP 502")
            }
            Ok(Some(b"png bytes".to_vec()))
        })
        .unwrap();

        assert_eq!(
            unfetched,
            [(
                "unreachable".to_owned(),
                "gh could not fetch golden image unreachable: HTTP 502".to_owned()
            )]
        );
        assert!(images.path("pushed.png").exists());
    }

    #[test]
    fn an_image_a_golden_file_on_any_long_lived_branch_names_is_in_use() {
        let root = TempRoot::new();
        root.git(&["init", "--quiet", "--initial-branch=develop"]);
        root.save(
            "framework/goldens/sidebar.golden",
            r#"{"sha256": "on-develop", "width": 4}"#,
        );
        root.git(&["update-ref", "refs/remotes/origin/develop", "HEAD"]);
        root.save(
            "framework/goldens/title.golden",
            r#"{"sha256": "on-features", "width": 4}"#,
        );
        root.save(
            "framework/goldens/notes.txt",
            r#"{"sha256": "not-a-golden"}"#,
        );
        root.git(&["update-ref", "refs/remotes/origin/features/v1", "HEAD"]);
        // The checkout itself names a golden no long lived branch holds yet.
        root.git(&["checkout", "--quiet", "-b", "feature"]);
        root.save(
            "framework/goldens/fresh.golden",
            r#"{"sha256": "only-here"}"#,
        );

        let mut used = named_on(&root.ctx, &["origin/develop", "origin/features/v1"]).unwrap();
        used.sort();

        assert_eq!(used, ["on-develop", "on-features"]);
    }

    #[test]
    fn approve_of_a_pull_request_downloads_the_game_frames_of_its_latest_ci_run() {
        let root = TempRoot::new();
        let asked = RefCell::new(Vec::new());

        let frames = pull_request_frames(546, &root.path("pr-546"), |args: &[&str]| {
            asked.borrow_mut().push(args.join(" "));
            Ok(match args[0] {
                "pr" => "4e61bf0971\n".to_owned(),
                "run" if args[1] == "list" => "44063821447\n".to_owned(),
                _ => String::new(),
            })
        })
        .unwrap();

        let asked = asked.into_inner();
        assert!(asked[0].starts_with("pr view 546 "), "{asked:?}");
        assert!(asked[1].contains("--workflow ci.yml"), "{asked:?}");
        assert!(asked[1].contains("--commit 4e61bf0971"), "{asked:?}");
        for (download, artifact) in asked[2..]
            .iter()
            .zip(["results-e2e-game", "results-e2e-playtest"])
        {
            assert!(
                download.starts_with("run download 44063821447 ")
                    && download.contains(&format!("--name {artifact}"))
                    && download.contains(&format!("pr-546/{artifact}")),
                "{asked:?}"
            );
        }
        assert_eq!(asked.len(), 4, "{asked:?}");
        assert_eq!(frames, root.path("pr-546"));
    }

    #[test]
    fn approve_of_a_pull_request_takes_the_suites_that_ran_and_fails_only_when_none_did() {
        let root = TempRoot::new();
        let ran = |artifact: &'static str| {
            move |args: &[&str]| -> anyhow::Result<String> {
                match args[0] {
                    "pr" => Ok("4e61bf0971\n".to_owned()),
                    "run" if args[1] == "list" => Ok("44063821447\n".to_owned()),
                    _ if args.contains(&artifact) => Ok(String::new()),
                    _ => anyhow::bail!("no artifact matches"),
                }
            }
        };

        assert!(pull_request_frames(546, &root.path("pr-546"), ran("results-e2e-game")).is_ok());
        let error = pull_request_frames(546, &root.path("pr-546"), ran("results-e2e-panel"))
            .unwrap_err()
            .to_string();
        assert!(error.contains("no game results"), "{error}");
    }

    #[test]
    fn approve_of_a_pull_request_without_a_ci_run_says_so() {
        let root = TempRoot::new();

        let error = pull_request_frames(546, &root.path("pr-546"), |args: &[&str]| {
            Ok(if args[0] == "pr" {
                "4e61bf0971\n"
            } else {
                "\n"
            }
            .to_owned())
        })
        .unwrap_err()
        .to_string();

        assert_eq!(
            error,
            "pull request 546 has no CI run of its head 4e61bf0971 yet"
        );
    }
}
