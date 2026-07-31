//! Dependency-light descriptors shared by the component test macros, runner, and xtask.

#![forbid(unsafe_code)]

use std::collections::{BTreeMap, BTreeSet};
use std::path::{Path, PathBuf};

use serde::{Deserialize, Serialize};
use thiserror::Error;

pub const RUN_MANIFEST_SCHEMA_VERSION: u32 = 1;
pub const COMPONENT_TARGET: &str = "wasm32-wasip2";
pub const COMPONENT_PROFILE: &str = "release";

#[derive(Clone, Copy, Debug, Eq, PartialEq, Serialize)]
#[serde(rename_all = "snake_case")]
pub enum ComponentRole {
    Primary,
    Dependency,
}

#[derive(Clone, Copy, Debug, Eq, PartialEq, Serialize)]
pub struct ComponentBuild {
    pub package: &'static str,
    pub target: &'static str,
    pub role: ComponentRole,
}

impl ComponentBuild {
    pub const fn primary(package: &'static str, target: &'static str) -> Self {
        Self {
            package,
            target,
            role: ComponentRole::Primary,
        }
    }

    pub const fn dependency(package: &'static str, target: &'static str) -> Self {
        Self {
            package,
            target,
            role: ComponentRole::Dependency,
        }
    }
}

#[derive(Clone, Copy, Debug, Eq, PartialEq, Serialize)]
pub struct FixtureDescriptor {
    pub id: &'static str,
    pub primary: ComponentBuild,
    pub dependencies: &'static [ComponentBuild],
    pub affected_paths: &'static [&'static str],
}

impl FixtureDescriptor {
    pub fn components(&self) -> impl Iterator<Item = ComponentBuild> + '_ {
        std::iter::once(self.primary).chain(self.dependencies.iter().copied())
    }
}

#[derive(Clone, Copy, Debug)]
pub struct FixtureRegistration {
    pub descriptor: &'static FixtureDescriptor,
}

#[derive(Clone, Copy, Debug, Eq, PartialEq, Serialize)]
pub struct TestDescriptor {
    pub fixture_id: &'static str,
    pub module_path: &'static str,
    pub function: &'static str,
    pub case: Option<&'static str>,
    pub exact_name: &'static str,
}

impl TestDescriptor {
    pub fn libtest_name(&self) -> &str {
        self.exact_name
            .split_once("::")
            .map_or(self.exact_name, |(_, name)| name)
    }
}

#[derive(Clone, Copy, Debug)]
pub struct TestRegistration {
    pub descriptor: &'static TestDescriptor,
}

inventory::collect!(FixtureRegistration);
inventory::collect!(TestRegistration);

#[derive(Clone, Debug, Eq, PartialEq, Serialize, Deserialize)]
pub struct RunManifest {
    pub schema_version: u32,
    pub run_id: String,
    pub workspace_root: PathBuf,
    pub backend_lock_sha256: String,
    pub test_lock_sha256: String,
    pub rustc_version: String,
    pub cargo_version: String,
    pub target: String,
    pub profile: String,
    pub fixtures: Vec<String>,
    pub artifacts: Vec<ArtifactRecord>,
}

#[derive(Clone, Debug, Eq, PartialEq, Serialize, Deserialize)]
pub struct ArtifactRecord {
    pub fixture_id: String,
    pub role: OwnedComponentRole,
    pub package_id: String,
    pub package: String,
    pub target_name: String,
    pub path: PathBuf,
    pub sha256: String,
    pub fresh: bool,
}

#[derive(Clone, Copy, Debug, Eq, PartialEq, Serialize, Deserialize)]
#[serde(rename_all = "snake_case")]
pub enum OwnedComponentRole {
    Primary,
    Dependency,
}

impl From<ComponentRole> for OwnedComponentRole {
    fn from(value: ComponentRole) -> Self {
        match value {
            ComponentRole::Primary => Self::Primary,
            ComponentRole::Dependency => Self::Dependency,
        }
    }
}

#[derive(Debug, Error, Eq, PartialEq)]
pub enum ModelError {
    #[error("fixture ID cannot be empty")]
    EmptyFixtureId,
    #[error("fixture ID `{0}` is registered more than once")]
    DuplicateFixture(String),
    #[error("test name `{0}` is registered more than once")]
    DuplicateTest(String),
    #[error("test `{test}` references unknown fixture `{fixture}`")]
    UnknownTestFixture { test: String, fixture: String },
    #[error("fixture `{fixture}` contains duplicate component package `{package}`")]
    DuplicateComponent { fixture: String, package: String },
    #[error("fixture `{fixture}` primary component must have primary role")]
    InvalidPrimaryRole { fixture: String },
    #[error("fixture `{fixture}` dependency `{package}` must have dependency role")]
    InvalidDependencyRole { fixture: String, package: String },
    #[error("run manifest schema {actual} is unsupported; expected {expected}")]
    ManifestSchema { actual: u32, expected: u32 },
    #[error("run manifest target `{actual}` does not match `{expected}`")]
    ManifestTarget { actual: String, expected: String },
    #[error("run manifest profile `{actual}` does not match `{expected}`")]
    ManifestProfile { actual: String, expected: String },
    #[error("run manifest workspace `{actual}` does not match `{expected}`")]
    ManifestWorkspace { actual: String, expected: String },
    #[error("run manifest has no artifact for fixture `{fixture}` package `{package}`")]
    MissingArtifact { fixture: String, package: String },
}

pub fn validate_catalog<'a>(
    fixtures: impl IntoIterator<Item = &'a FixtureDescriptor>,
    tests: impl IntoIterator<Item = &'a TestDescriptor>,
) -> Result<(), ModelError> {
    let mut fixture_ids = BTreeSet::new();
    for fixture in fixtures {
        if fixture.id.is_empty() {
            return Err(ModelError::EmptyFixtureId);
        }
        if !fixture_ids.insert(fixture.id) {
            return Err(ModelError::DuplicateFixture(fixture.id.to_string()));
        }
        if fixture.primary.role != ComponentRole::Primary {
            return Err(ModelError::InvalidPrimaryRole {
                fixture: fixture.id.to_string(),
            });
        }
        let mut packages = BTreeSet::new();
        packages.insert(fixture.primary.package);
        for dependency in fixture.dependencies {
            if dependency.role != ComponentRole::Dependency {
                return Err(ModelError::InvalidDependencyRole {
                    fixture: fixture.id.to_string(),
                    package: dependency.package.to_string(),
                });
            }
            if !packages.insert(dependency.package) {
                return Err(ModelError::DuplicateComponent {
                    fixture: fixture.id.to_string(),
                    package: dependency.package.to_string(),
                });
            }
        }
    }

    let mut names = BTreeSet::new();
    for test in tests {
        if !names.insert(test.exact_name) {
            return Err(ModelError::DuplicateTest(test.exact_name.to_string()));
        }
        if !fixture_ids.contains(test.fixture_id) {
            return Err(ModelError::UnknownTestFixture {
                test: test.exact_name.to_string(),
                fixture: test.fixture_id.to_string(),
            });
        }
    }
    Ok(())
}

impl RunManifest {
    pub fn validate_for(&self, workspace_root: &Path) -> Result<(), ModelError> {
        if self.schema_version != RUN_MANIFEST_SCHEMA_VERSION {
            return Err(ModelError::ManifestSchema {
                actual: self.schema_version,
                expected: RUN_MANIFEST_SCHEMA_VERSION,
            });
        }
        if self.target != COMPONENT_TARGET {
            return Err(ModelError::ManifestTarget {
                actual: self.target.clone(),
                expected: COMPONENT_TARGET.to_string(),
            });
        }
        if self.profile != COMPONENT_PROFILE {
            return Err(ModelError::ManifestProfile {
                actual: self.profile.clone(),
                expected: COMPONENT_PROFILE.to_string(),
            });
        }
        if self.workspace_root != workspace_root {
            return Err(ModelError::ManifestWorkspace {
                actual: self.workspace_root.display().to_string(),
                expected: workspace_root.display().to_string(),
            });
        }
        Ok(())
    }

    pub fn artifact(&self, fixture_id: &str, package: &str) -> Result<&ArtifactRecord, ModelError> {
        self.artifacts
            .iter()
            .find(|artifact| artifact.fixture_id == fixture_id && artifact.package == package)
            .ok_or_else(|| ModelError::MissingArtifact {
                fixture: fixture_id.to_string(),
                package: package.to_string(),
            })
    }
}

#[derive(Clone, Debug, Default, Eq, PartialEq)]
pub struct AffectedSelection {
    pub all: bool,
    pub fixture_ids: BTreeSet<String>,
    pub reasons: BTreeMap<String, BTreeSet<String>>,
}

impl AffectedSelection {
    pub fn select_all(reason: impl Into<String>) -> Self {
        let mut selection = Self {
            all: true,
            ..Self::default()
        };
        selection
            .reasons
            .entry("*".to_string())
            .or_default()
            .insert(reason.into());
        selection
    }

    pub fn include(&mut self, fixture_id: &str, reason: impl Into<String>) {
        self.fixture_ids.insert(fixture_id.to_string());
        self.reasons
            .entry(fixture_id.to_string())
            .or_default()
            .insert(reason.into());
    }
}

pub fn select_affected(
    fixtures: &[&FixtureDescriptor],
    changed_paths: impl IntoIterator<Item = impl AsRef<Path>>,
) -> AffectedSelection {
    let mut selection = AffectedSelection::default();
    for path in changed_paths {
        let normalized = path.as_ref().to_string_lossy().replace('\\', "/");
        if is_global_component_test_path(&normalized) {
            return AffectedSelection::select_all(normalized);
        }

        let mut matched = false;
        for fixture in fixtures {
            let package_marker = format!("/{}/", fixture.primary.package);
            let uses_component = fixture.components().any(|component| {
                normalized.contains(&format!("/{}/", component.package))
                    || normalized.ends_with(&format!("/{}", component.package))
            });
            let explicit = fixture
                .affected_paths
                .iter()
                .any(|prefix| normalized.starts_with(prefix));
            if uses_component || normalized.contains(&package_marker) || explicit {
                selection.include(fixture.id, normalized.clone());
                matched = true;
            }
        }

        if normalized.starts_with("backend/") && !matched {
            return AffectedSelection::select_all(format!("unmapped backend change: {normalized}"));
        }
    }
    selection
}

fn is_global_component_test_path(path: &str) -> bool {
    path.starts_with("backend/tests/component/crates/")
        || path == "backend/Cargo.lock"
        || path == "backend/Cargo.toml"
        || path.starts_with(".cargo/")
        || path == ".github/workflows/ci-component-tests.yml"
}

#[cfg(test)]
mod tests {
    use super::*;

    const NO_DEPS: &[ComponentBuild] = &[];
    const SERVICE: FixtureDescriptor = FixtureDescriptor {
        id: "service-identity",
        primary: ComponentBuild::primary("service-identity", "service_identity"),
        dependencies: NO_DEPS,
        affected_paths: &["backend/database/schema/service/"],
    };

    fn test_descriptor() -> TestDescriptor {
        TestDescriptor {
            fixture_id: "service-identity",
            module_path: "service_identity",
            function: "issue_identity",
            case: Some("empty_roles"),
            exact_name: "service_identity::issue_identity__empty_roles",
        }
    }

    #[test]
    fn validates_catalog() {
        assert_eq!(validate_catalog([&SERVICE], [&test_descriptor()]), Ok(()));
    }

    #[test]
    fn rejects_duplicate_fixture() {
        assert_eq!(
            validate_catalog([&SERVICE, &SERVICE], std::iter::empty()),
            Err(ModelError::DuplicateFixture("service-identity".into()))
        );
    }

    #[test]
    fn selects_component_and_schema_changes() {
        let fixtures = [&SERVICE];
        let source = select_affected(&fixtures, ["backend/service/service-identity/src/lib.rs"]);
        assert!(source.fixture_ids.contains("service-identity"));

        let schema = select_affected(&fixtures, ["backend/database/schema/service/service.surql"]);
        assert!(schema.fixture_ids.contains("service-identity"));
    }

    #[test]
    fn unknown_backend_change_fails_safe() {
        let selection = select_affected([&SERVICE].as_slice(), ["backend/new-area/file.rs"]);
        assert!(selection.all);
    }
}
