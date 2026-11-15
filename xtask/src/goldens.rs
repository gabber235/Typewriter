//! `cargo xtask goldens approve`: records the frames a game run captured as the approved goldens.
//! A requirement that names a golden writes its frame as a PNG into its attempt's folder, beside a
//! `<name>.golden` file that says which golden file of the repository it belongs to, the frame's
//! hash and size, the renderer that drew it, and whether that is the pinned renderer, as the run
//! judged it. Approving writes the hash, size and renderer into that golden file and keeps the PNG
//! among the local golden images under its hash, where a later run finds the golden's image to draw
//! a diff against. A golden is exact only for the renderer that drew it, so approve refuses any
//! frame the pinned renderer did not draw.

use std::collections::BTreeMap;
use std::fs;
use std::path::{Path, PathBuf};

use anyhow::{Context as _, Result, bail};

use crate::{Context, evidence};

/// The local golden images, each named by its hash, relative to the repository root.
const IMAGES: &str = "services/build/playtest/goldens";

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
            for approved in approve(&ctx.root, &from, &ctx.root.join(IMAGES))? {
                println!("goldens: approved {approved}");
            }
            Ok(())
        }
    }
}

/// Approves every golden captured under `from` into its golden file below `root`, and copies each
/// frame into `images`; returns the golden files it wrote, relative to `root`.
fn approve(root: &Path, from: &Path, images: &Path) -> Result<Vec<String>> {
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
    for (golden, captured) in &chosen {
        let file = root.join(golden);
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
    }
    Ok(chosen.into_keys().collect())
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

    use super::approve;
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
        assert_eq!(approved, vec![golden.to_owned()]);
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
}
