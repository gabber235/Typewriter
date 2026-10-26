//! The documentation site in documentation/: its check, and the previews of branches and pull
//! requests on `gh-pages`, which GitHub Pages serves at [`SITE`].

use std::fs::{self, File};
use std::io::Write as _;
use std::path::Path;

use anyhow::{Context as _, Result, bail};
use clap::{Args, Subcommand};

use crate::branch::{BranchCheckout, REPOSITORY};
use crate::{CommandExt, Context};

pub const DESCRIBE: &str = "cd documentation && bun install --frozen-lockfile && bun run validate \
                            && bun run build";

/// The site folder, relative to the repository root.
const SITE_DIR: &str = "documentation";
/// Where `gh-pages` is served; previews live below it at `branches/<name>/`.
const SITE: &str = "https://docs.typewritermc.com";
/// The published branch.
const PAGES: &str = "gh-pages";
/// Marks the preview comment on a pull request, so a later push edits it instead of adding one.
const COMMENT_MARKER: &str = "<!-- typewriter-docs-preview -->";

#[derive(Subcommand)]
pub enum DocsCommand {
    /// Builds the site for a branch or pull request and publishes it as a preview.
    Preview(Target),
    /// Removes a preview, for example once its pull request closed or its branch was deleted.
    Unpublish(Target),
}

/// Which preview a command means.
#[derive(Args)]
#[group(required = true, multiple = false)]
pub struct Target {
    /// A pull request; its preview is `branches/pr-<number>`. Previewing also comments the link.
    #[arg(long)]
    pr: Option<u64>,
    /// A branch; its preview is `branches/<branch>`.
    #[arg(long)]
    branch: Option<String>,
}

impl Target {
    /// The preview's folder on [`PAGES`].
    fn folder(&self) -> String {
        match (&self.pr, &self.branch) {
            (Some(pr), _) => format!("branches/pr-{pr}"),
            (None, Some(branch)) => format!("branches/{branch}"),
            (None, None) => unreachable!("clap requires one target"),
        }
    }
}

pub fn run(ctx: &Context, command: DocsCommand) -> Result<()> {
    match command {
        DocsCommand::Preview(target) => preview(ctx, &target),
        DocsCommand::Unpublish(target) => unpublish(ctx, &target),
    }
}

/// The `docs` check step: the same install and build a preview runs, plus Biome and `astro check`.
pub fn check(ctx: &Context, log: &File) -> Result<()> {
    for args in [
        &["install", "--frozen-lockfile"][..],
        &["run", "validate"],
        &["run", "build"],
    ] {
        writeln!(&*log, "$ bun {}", args.join(" "))?;
        ctx.tool(SITE_DIR, "bun", args)
            .log_output(Some(log))?
            .run()?;
    }
    Ok(())
}

fn preview(ctx: &Context, target: &Target) -> Result<()> {
    let folder = target.folder();
    ctx.tool(SITE_DIR, "bun", &["install", "--frozen-lockfile"])
        .run()?;
    ctx.tool(SITE_DIR, "bun", &["run", "build"])
        .env("DOCS_BASE_PATH", format!("/{folder}/"))
        .run()?;
    let pages = BranchCheckout::clone_shallow(ctx, PAGES, "Typewriter docs")?;
    let destination = pages.path(&folder);
    remove(&destination)?;
    copy_dir(&ctx.root.join(SITE_DIR).join("dist"), &destination)?;
    // GitHub Pages reads the custom domain from the branch, so every publish keeps it.
    fs::write(pages.path("CNAME"), "docs.typewritermc.com\n")?;
    pages.commit_and_push(ctx, &format!("docs: preview {folder}"))?;
    let url = format!("{SITE}/{folder}/");
    if let Some(pr) = target.pr {
        comment(ctx, pr, &url)?;
    }
    println!("preview published at {url}");
    Ok(())
}

fn unpublish(ctx: &Context, target: &Target) -> Result<()> {
    let folder = target.folder();
    let pages = BranchCheckout::clone_shallow(ctx, PAGES, "Typewriter docs")?;
    remove(&pages.path(&folder))?;
    pages.commit_and_push(ctx, &format!("docs: remove preview {folder}"))
}

/// Points the pull request at its preview: edits the comment an earlier push left, or adds one.
fn comment(ctx: &Context, pr: u64, url: &str) -> Result<()> {
    let body = format!("{COMMENT_MARKER}\n**Documentation preview:** {url}");
    let query = format!(".[] | select(.body | startswith(\"{COMMENT_MARKER}\")) | .id");
    let existing = ctx
        .tool(
            ".",
            "gh",
            &[
                "api",
                "--paginate",
                &format!("repos/{REPOSITORY}/issues/{pr}/comments"),
                "--jq",
                &query,
            ],
        )
        .output_text()?;
    let field = format!("body={body}");
    let mut request = match existing.lines().next() {
        Some(id) => ctx.tool(
            ".",
            "gh",
            &[
                "api",
                "--method",
                "PATCH",
                &format!("repos/{REPOSITORY}/issues/comments/{id}"),
                "-f",
                &field,
            ],
        ),
        None => ctx.tool(
            ".",
            "gh",
            &[
                "api",
                &format!("repos/{REPOSITORY}/issues/{pr}/comments"),
                "-f",
                &field,
            ],
        ),
    };
    request.output_text().map(drop)
}

fn remove(path: &Path) -> Result<()> {
    if path.exists() {
        fs::remove_dir_all(path).with_context(|| format!("cannot remove {}", path.display()))?;
    }
    Ok(())
}

fn copy_dir(from: &Path, to: &Path) -> Result<()> {
    if !from.is_dir() {
        bail!("{} does not exist; the build wrote nothing", from.display());
    }
    fs::create_dir_all(to).with_context(|| format!("cannot create {}", to.display()))?;
    for entry in fs::read_dir(from).with_context(|| format!("cannot read {}", from.display()))? {
        let entry = entry?;
        let target = to.join(entry.file_name());
        if entry.file_type()?.is_dir() {
            copy_dir(&entry.path(), &target)?;
        } else {
            fs::copy(entry.path(), &target)
                .with_context(|| format!("cannot copy {}", entry.path().display()))?;
        }
    }
    Ok(())
}
