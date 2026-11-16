//! `cargo xtask goldens approve`: records the frames a game run captured as the approved goldens.
//! A requirement that names a golden writes its frame as a PNG into its attempt's folder, beside a
//! `<name>.golden` file that says which golden file of the repository it belongs to, the frame's
//! hash and size, the renderer that drew it, and whether that is the pinned renderer, as the run
//! judged it. Approving writes the hash, size and renderer into that golden file, keeps the PNG
//! among the local golden images under its hash, and pushes it to the evidence branch as
//! `goldens/<hash>.png`; the repository holds only the hash. Before a game run,
//! [`fetch_missing`] brings every golden's image the machine lacks, so a frame that differs from
//! its golden shows where while the framework stays offline. A golden is exact only for the
//! renderer that drew it, so approve refuses any frame the pinned renderer did not draw.

use std::collections::BTreeMap;
use std::fs;
use std::path::{Path, PathBuf};

use anyhow::{Context as _, Result, bail};

use crate::branch::{BranchCheckout, REPOSITORY};
use crate::{CommandExt as _, Context, evidence};

/// The local golden images, each named by its hash, relative to the repository root.
const IMAGES: &str = "services/build/playtest/goldens";

/// The folder of the golden images on the evidence branch, beside the pull requests' folders,
/// which pruning empties, never inside them.
const ON_BRANCH: &str = "goldens";

/// The keys a golden file holds, in the order it holds them.
const GOLDEN_KEYS: [&str; 8] = [
    "sha256", "width", "height", "backend", "device", "driver", "os", "arch",
];

#[derive(clap::Subcommand)]
pub enum GoldensCommand {
    /// Records each golden a game run captured: its golden file takes the frame's hash, size and
    /// renderer, and the frame joins the local golden images.
    Approve {
        /// The run's folder; the last `cargo xtask e2e game` run's by default.
        from: Option<PathBuf>,
    },
}

pub fn run(ctx: &Context, command: &GoldensCommand) -> Result<()> {
    match command {
        GoldensCommand::Approve { from } => {
            let from = from
                .clone()
                .unwrap_or_else(|| ctx.root.join(evidence::RESULTS).join("game"));
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

/// A golden [`approve`] wrote: its golden file, relative to the repository root, and the local image
/// it was approved from.
#[derive(Debug)]
struct Approved {
    golden: String,
    image: PathBuf,
}

/// Puts each of `images` into the evidence branch checked out at `branch`, as `goldens/<hash>.png`.
fn place(images: &[PathBuf], branch: &Path) -> Result<()> {
    let folder = branch.join(ON_BRANCH);
    fs::create_dir_all(&folder).with_context(|| format!("cannot create {}", folder.display()))?;
    for image in images {
        let name = image.file_name().context("a golden image without a name")?;
        fs::copy(image, folder.join(name))
            .with_context(|| format!("cannot copy {} onto the evidence branch", image.display()))?;
    }
    Ok(())
}

/// Fetches into `images` the image of each golden in `hashes` it does not hold yet, through `fetch`,
/// which answers None for an image the evidence branch does not hold; returns those hashes.
fn fetch_into(
    images: &Path,
    hashes: &[&str],
    fetch: impl Fn(&str) -> Result<Option<Vec<u8>>>,
) -> Result<Vec<String>> {
    fs::create_dir_all(images).with_context(|| format!("cannot create {}", images.display()))?;
    let mut absent = Vec::new();
    for hash in hashes {
        let image = images.join(format!("{hash}.png"));
        if image.exists() {
            continue;
        }
        match fetch(hash)? {
            Some(bytes) => fs::write(&image, bytes)
                .with_context(|| format!("cannot write {}", image.display()))?,
            None => absent.push((*hash).to_owned()),
        }
    }
    Ok(absent)
}

/// Fetches the image of every golden the repository holds that the local golden images lack,
/// from the evidence branch, so a frame that differs from its golden shows where. A golden whose
/// image the branch does not hold yet is said, and its frames fail without a diff.
pub fn fetch_missing(ctx: &Context) -> Result<()> {
    let files = ctx
        .tool(".", "git", &["ls-files", "-z", "--", "*.golden"])
        .output_text()?;
    let mut hashes = Vec::new();
    for file in files.split('\0').filter(|it| !it.is_empty()) {
        let path = ctx.root.join(file);
        let text =
            fs::read_to_string(&path).with_context(|| format!("cannot read {}", path.display()))?;
        let hash = text
            .lines()
            .find_map(|line| line.strip_prefix("sha256="))
            .with_context(|| format!("{file} holds no sha256"))?;
        hashes.push(hash.to_owned());
    }
    let hashes: Vec<&str> = hashes.iter().map(String::as_str).collect();
    for hash in fetch_into(&ctx.root.join(IMAGES), &hashes, |hash| {
        fetch_image(ctx, hash)
    })? {
        println!(
            "goldens: the evidence branch holds no image of golden {hash}; a frame that differs from it fails without a diff"
        );
    }
    Ok(())
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
    place(images, &branch.path(""))?;
    branch.commit_and_push(ctx, &format!("goldens: {} approved", images.len()))
}

/// Approves every golden captured under `from` into its golden file below `root`, and copies each
/// frame into `images`; returns the goldens it wrote.
fn approve(root: &Path, from: &Path, images: &Path) -> Result<Vec<Approved>> {
    let mut chosen: BTreeMap<String, Captured> = BTreeMap::new();
    for captured in captured_under(from)? {
        if !captured.pinned {
            let renderer =
                ["backend", "device", "driver", "os", "arch"].map(|key| &captured.keys[key]);
            bail!(
                "golden {}: its frame {} was drawn by {}, not the pinned renderer; goldens are \
                 approved only from frames the pinned runner drew",
                captured.golden,
                captured.png.display(),
                renderer
                    .iter()
                    .map(|it| it.as_str())
                    .collect::<Vec<_>>()
                    .join(", ")
            );
        }
        match chosen.get(&captured.golden) {
            Some(earlier) if earlier.keys != captured.keys => bail!(
                "the run captured golden {} as two different frames ({} and {}): a scene that \
                 changes between attempts cannot be a golden",
                captured.golden,
                earlier.png.display(),
                captured.png.display()
            ),
            Some(_) => {}
            None => {
                chosen.insert(captured.golden.clone(), captured);
            }
        }
    }
    if chosen.is_empty() {
        bail!("the run in {} captured no golden", from.display());
    }
    fs::create_dir_all(images).with_context(|| format!("cannot create {}", images.display()))?;
    let mut approved = Vec::new();
    for (golden, captured) in chosen {
        let file = root.join(&golden);
        let parent = file.parent().context("a golden file without a folder")?;
        fs::create_dir_all(parent)
            .with_context(|| format!("cannot create {}", parent.display()))?;
        let mut text = String::from(
            "# Approved by `cargo xtask goldens approve`; exact only on the renderer named below.\n",
        );
        for key in GOLDEN_KEYS {
            text.push_str(&format!("{key}={}\n", captured.keys[key]));
        }
        fs::write(&file, text).with_context(|| format!("cannot write {}", file.display()))?;
        let image = images.join(format!("{}.png", captured.keys["sha256"]));
        fs::copy(&captured.png, &image).with_context(|| {
            format!(
                "cannot copy {} to {}",
                captured.png.display(),
                image.display()
            )
        })?;
        approved.push(Approved { golden, image });
    }
    Ok(approved)
}

/// One frame a run captured: the golden file it is for, its PNG, its hash, size and renderer, and
/// whether the run found that renderer to be the pinned one.
struct Captured {
    golden: String,
    png: PathBuf,
    keys: BTreeMap<String, String>,
    pinned: bool,
}

/// Every frame captured under `folder`, from the `<name>.golden` files beside the frames.
fn captured_under(folder: &Path) -> Result<Vec<Captured>> {
    let mut found = Vec::new();
    let entries =
        fs::read_dir(folder).with_context(|| format!("cannot read {}", folder.display()))?;
    let mut paths = entries
        .map(|entry| entry.map(|it| it.path()))
        .collect::<Result<Vec<_>, _>>()?;
    paths.sort();
    for path in paths {
        if path.is_dir() {
            found.extend(captured_under(&path)?);
        } else if path.extension().is_some_and(|it| it == "golden") {
            found.push(read_captured(&path)?);
        }
    }
    Ok(found)
}

fn read_captured(file: &Path) -> Result<Captured> {
    let text =
        fs::read_to_string(file).with_context(|| format!("cannot read {}", file.display()))?;
    let mut keys: BTreeMap<String, String> = text
        .lines()
        .filter(|line| !line.is_empty() && !line.starts_with('#'))
        .filter_map(|line| line.split_once('='))
        .map(|(key, value)| (key.to_owned(), value.to_owned()))
        .collect();
    let golden = keys
        .remove("golden")
        .with_context(|| format!("{} names no golden file", file.display()))?;
    let image = keys
        .remove("image")
        .with_context(|| format!("{} names no image", file.display()))?;
    let pinned = keys.remove("pinned").with_context(|| {
        format!(
            "{} does not say whether the pinned renderer drew it",
            file.display()
        )
    })? == "true";
    if let Some(missing) = GOLDEN_KEYS.iter().find(|key| !keys.contains_key(**key)) {
        bail!("{} holds no {missing}", file.display());
    }
    let png = file.with_file_name(image);
    Ok(Captured {
        golden,
        png,
        keys,
        pinned,
    })
}

#[cfg(test)]
mod tests {
    use std::fs;

    use std::cell::RefCell;

    use super::{approve, fetch_into, place};
    use crate::test_support::{TempRoot, captured_golden};

    const SIDEBAR: &str = "golden=services/playtest/framework/src/gameTest/goldens/sidebar.golden
image=sidebar.png
sha256=5e1d
width=854
height=480
backend=Vulkan
device=llvmpipe (LLVM 20.1.2, 256 bits)
driver=1.4.318 llvmpipe Mesa 26.2.5 (LLVM 20.1.2)
os=Linux
arch=amd64
pinned=true
";

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
        assert!(written.ends_with(
            "sha256=5e1d\nwidth=854\nheight=480\nbackend=Vulkan\n\
             device=llvmpipe (LLVM 20.1.2, 256 bits)\n\
             driver=1.4.318 llvmpipe Mesa 26.2.5 (LLVM 20.1.2)\nos=Linux\narch=amd64\n"
        ));
        assert!(!written.contains("image="), "{written}");
        assert!(!written.contains("pinned="), "{written}");
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
    fn approve_refuses_a_frame_another_renderer_drew_names_it_and_writes_nothing() {
        let (root, run) = (TempRoot::new(), TempRoot::new());
        captured_golden(
            &run,
            "GOLDEN-1 a sidebar/attempt-1/sidebar",
            &SIDEBAR
                .replace("backend=Vulkan", "backend=OpenGL")
                .replace(
                    "device=llvmpipe (LLVM 20.1.2, 256 bits)",
                    "device=Apple M1 Max",
                )
                .replace(
                    "driver=1.4.318 llvmpipe Mesa 26.2.5 (LLVM 20.1.2)",
                    "driver=4.1 Metal - 89.4",
                )
                .replace("os=Linux", "os=Mac OS X")
                .replace("arch=amd64", "arch=aarch64")
                .replace("pinned=true", "pinned=false"),
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
    fn an_approved_image_goes_onto_the_evidence_branch_by_its_hash_beside_the_pull_requests() {
        let (images, branch) = (TempRoot::new(), TempRoot::new());
        images.write("5e1d.png", "png bytes");
        branch.write("pr/546/abc1234/frame.png", "a pull request's frame");

        place(&[images.path("5e1d.png")], &branch.ctx.root).unwrap();

        assert_eq!(
            fs::read_to_string(branch.path("goldens/5e1d.png")).unwrap(),
            "png bytes"
        );
        assert!(branch.path("pr/546/abc1234/frame.png").exists());
    }

    #[test]
    fn a_run_fetches_the_image_of_each_golden_it_lacks_and_none_it_holds() {
        let images = TempRoot::new();
        images.write("held.png", "held");
        let asked = RefCell::new(Vec::new());

        let absent = fetch_into(
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
        assert_eq!(absent, ["never-pushed"]);
        assert!(!images.path("never-pushed.png").exists());
    }
}
