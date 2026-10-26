//! Validates the GitOps manifests. Clusters are discovered, not named, so a new folder in
//! backend/_clusters is checked without touching the harness.

use std::fs::{self, File};
use std::io::Write;
use std::process::Stdio;

use anyhow::{Context as _, Result, bail};

use crate::{CommandExt, Context};

pub const DESCRIBE: &str = "for each backend/_clusters/<cluster>: kustomize build <cluster> | kubeconform; \
                            then yamllint over the tracked backend YAML";

/// Kubernetes schemas first, then the community catalog that covers Flux and other CRDs.
const KUBECONFORM: &[&str] = &[
    "-strict",
    "-summary",
    "-ignore-missing-schemas",
    "-skip",
    "CustomResourceDefinition",
    "-schema-location",
    "default",
    "-schema-location",
    "https://raw.githubusercontent.com/datreeio/CRDs-catalog/main/{{.Group}}/{{.ResourceKind}}_{{.ResourceAPIVersion}}.json",
];

/// Long generated lines (subscriptions, inline policies) and Kubernetes' `on`/`off` style keys are
/// valid; everything else is yamllint's default.
const YAMLLINT_CONFIG: &str = "{extends: default, rules: \
                               {line-length: {max: 700, allow-non-breakable-inline-mappings: true}, \
                               document-start: disable, truthy: {check-keys: false}}}";

pub fn gitops(ctx: &Context, log: &File) -> Result<()> {
    let clusters = ctx.root.join("backend/_clusters");
    let mut folders = fs::read_dir(&clusters)
        .with_context(|| format!("cannot read {}", clusters.display()))?
        .map(|entry| entry.map(|entry| (entry.path(), entry.file_name())))
        .collect::<Result<Vec<_>, _>>()?;
    folders.retain(|(path, _)| path.is_dir());
    folders.sort();
    for (cluster, name) in folders {
        let name = name.to_string_lossy();
        writeln!(&*log, "$ kustomize build {name} | kubeconform")?;
        let rendered = ctx
            .tool(".", "kustomize", &["build"])
            .arg(&cluster)
            .stderr(log.try_clone()?)
            .output_text()
            .with_context(|| format!("cluster {name} does not render"))?;
        let mut validate = ctx
            .tool(".", "kubeconform", KUBECONFORM)
            .stdin(Stdio::piped())
            .stdout(log.try_clone()?)
            .stderr(log.try_clone()?)
            .spawn()
            .context("cannot start kubeconform")?;
        validate
            .stdin
            .take()
            .expect("stdin is piped")
            .write_all(rendered.as_bytes())?;
        let status = validate.wait()?;
        if !status.success() {
            bail!("cluster {name} does not validate");
        }
    }
    // Tracked files only, so build output and local state never fail the lint.
    let tracked = ctx
        .tool("backend", "git", &["ls-files", "*.yaml", "*.yml"])
        .output_text()?;
    writeln!(&*log, "$ yamllint <tracked backend YAML>")?;
    ctx.tool("backend", "yamllint", &["-d", YAMLLINT_CONFIG])
        .args(tracked.lines())
        .stdout(log.try_clone()?)
        .stderr(log.try_clone()?)
        .run()
        .context("backend YAML does not lint")
}
