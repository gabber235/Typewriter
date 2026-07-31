use std::{
    collections::HashMap,
    env, fs,
    path::{Path, PathBuf},
    sync::{Arc, Mutex, OnceLock},
};

use anyhow::{Context, Result, bail};
use component_test_model::{
    COMPONENT_PROFILE, COMPONENT_TARGET, ComponentRole, FixtureDescriptor, OwnedComponentRole,
    RunManifest,
};
use sha2::{Digest, Sha256};

#[derive(Clone)]
pub(crate) struct Artifact {
    pub bytes: Arc<[u8]>,
    pub digest: String,
    pub path: PathBuf,
}

static MANIFEST: OnceLock<Result<RunManifest, String>> = OnceLock::new();
static ARTIFACTS: OnceLock<Mutex<HashMap<(String, String), Artifact>>> = OnceLock::new();

fn command(fixture: &str) -> String {
    format!("cargo xtask component-test {fixture}")
}

pub(crate) fn artifacts(descriptor: &FixtureDescriptor) -> Result<HashMap<String, Artifact>> {
    let manifest = MANIFEST
        .get_or_init(load_manifest)
        .as_ref()
        .map_err(|error| anyhow::anyhow!(error.clone()))?;
    validate_manifest(manifest, descriptor)?;
    let cache = ARTIFACTS.get_or_init(|| Mutex::new(HashMap::new()));
    let mut output = HashMap::new();
    for component in descriptor.components() {
        let key = (component.package.to_string(), component.target.to_string());
        if let Some(value) = cache
            .lock()
            .map_err(|_| anyhow::anyhow!("validation phase: artifact cache lock poisoned"))?
            .get(&key)
            .cloned()
        {
            output.insert(component.package.to_string(), value);
            continue;
        }
        let expected_role = match component.role {
            ComponentRole::Primary => OwnedComponentRole::Primary,
            ComponentRole::Dependency => OwnedComponentRole::Dependency,
        };
        let records = manifest
            .artifacts
            .iter()
            .filter(|record| {
                record.fixture_id == descriptor.id && record.package == component.package
            })
            .collect::<Vec<_>>();
        if records.len() != 1 {
            bail!(
                "validation phase: expected exactly one artifact for package `{}`; run `{}`",
                component.package,
                command(descriptor.id)
            );
        }
        let record = records[0];
        if record.target_name != component.target || record.role != expected_role {
            bail!(
                "validation phase: artifact for package `{}` has wrong target or role; run `{}`",
                component.package,
                command(descriptor.id)
            );
        }
        let bytes = fs::read(&record.path).with_context(|| {
            format!(
                "validation phase: cannot read artifact `{}`; run `{}`",
                record.path.display(),
                command(descriptor.id)
            )
        })?;
        let digest = format!("sha256:{:x}", Sha256::digest(&bytes));
        let expected = record
            .sha256
            .strip_prefix("sha256:")
            .unwrap_or(&record.sha256);
        if digest.strip_prefix("sha256:") != Some(expected) {
            bail!(
                "validation phase: SHA-256 mismatch for artifact `{}`; run `{}`",
                record.path.display(),
                command(descriptor.id)
            );
        }
        let artifact = Artifact {
            bytes: bytes.into(),
            digest,
            path: record.path.clone(),
        };
        cache
            .lock()
            .map_err(|_| anyhow::anyhow!("validation phase: artifact cache lock poisoned"))?
            .insert(key, artifact.clone());
        output.insert(component.package.to_string(), artifact);
    }
    Ok(output)
}

fn load_manifest() -> Result<RunManifest, String> {
    let path = env::var_os("COMPONENT_TEST_RUN_MANIFEST").ok_or_else(|| "validation phase: COMPONENT_TEST_RUN_MANIFEST is missing; run `cargo xtask component-test <fixture>`".to_string())?;
    let bytes = fs::read(&path).map_err(|error| format!("validation phase: cannot read run manifest `{}`: {error}; run `cargo xtask component-test <fixture>`", PathBuf::from(path).display()))?;
    serde_json::from_slice(&bytes).map_err(|error| format!("validation phase: invalid run manifest: {error}; run `cargo xtask component-test <fixture>`"))
}

fn validate_manifest(manifest: &RunManifest, descriptor: &FixtureDescriptor) -> Result<()> {
    if manifest.target != COMPONENT_TARGET
        || manifest.profile != COMPONENT_PROFILE
        || manifest.schema_version != component_test_model::RUN_MANIFEST_SCHEMA_VERSION
    {
        bail!(
            "validation phase: run manifest target/profile/schema is incompatible; run `{}`",
            command(descriptor.id)
        );
    }
    let expected = Path::new(env!("CARGO_MANIFEST_DIR"))
        .ancestors()
        .nth(5)
        .ok_or_else(|| anyhow::anyhow!("validation phase: cannot determine workspace"))?;
    if manifest.workspace_root.canonicalize().ok().as_deref()
        != expected.canonicalize().ok().as_deref()
    {
        bail!(
            "validation phase: run manifest workspace does not match `{}`; run `{}`",
            expected.display(),
            command(descriptor.id)
        );
    }
    if !manifest
        .fixtures
        .iter()
        .any(|fixture| fixture == descriptor.id)
    {
        bail!(
            "validation phase: fixture `{}` is not in run manifest; run `{}`",
            descriptor.id,
            command(descriptor.id)
        );
    }
    Ok(())
}
