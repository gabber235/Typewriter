use std::collections::{HashMap, HashSet};

use indexmap::IndexMap;
use serde::Deserialize;

#[derive(Debug, Deserialize)]
#[serde(deny_unknown_fields)]
struct RawCapability {
    files: Vec<String>,
    #[serde(default)]
    depends_on: Vec<String>,
}

#[derive(Debug, Deserialize)]
#[serde(deny_unknown_fields)]
struct RawSelection {
    capabilities: Vec<String>,
}

#[derive(Debug, Deserialize)]
#[serde(deny_unknown_fields)]
struct RawManifest {
    schema: IndexMap<String, RawCapability>,
    preset: IndexMap<String, RawSelection>,
    deployment: RawSelection,
}

#[derive(Debug)]
pub(crate) struct Manifest {
    schema: IndexMap<String, RawCapability>,
    presets: IndexMap<String, RawSelection>,
    deployment: RawSelection,
}

impl Manifest {
    pub(crate) fn parse(
        contents: &str,
        mut file_exists: impl FnMut(&str) -> bool,
    ) -> Result<Self, String> {
        let raw: RawManifest = toml::from_str(contents)
            .map_err(|error| format!("decoding database capability manifest: {error}"))?;
        let manifest = Self {
            schema: raw.schema,
            presets: raw.preset,
            deployment: raw.deployment,
        };
        manifest.validate(&mut file_exists)?;
        Ok(manifest)
    }

    fn validate(&self, file_exists: &mut impl FnMut(&str) -> bool) -> Result<(), String> {
        if self.schema.is_empty() {
            return Err("manifest must declare at least one schema capability".into());
        }
        let mut owners = HashMap::new();
        for (name, capability) in &self.schema {
            if name.trim().is_empty() {
                return Err("schema capability identifier must not be blank".into());
            }
            if capability.files.is_empty() {
                return Err(format!(
                    "schema capability {name:?} must declare at least one file"
                ));
            }
            reject_duplicates(
                &capability.depends_on,
                &format!("dependencies of schema capability {name:?}"),
            )?;
            for dependency in &capability.depends_on {
                if !self.schema.contains_key(dependency) {
                    return Err(format!(
                        "schema capability {name:?} depends on unknown capability {dependency:?}"
                    ));
                }
            }
            for file in &capability.files {
                if file.is_empty()
                    || file.starts_with('/')
                    || file.starts_with("../")
                    || file.contains("/../")
                    || file.contains("//")
                {
                    return Err(format!(
                        "schema capability {name:?} contains invalid file {file:?}"
                    ));
                }
                if let Some(owner) = owners.insert(file.as_str(), name.as_str()) {
                    return Err(format!(
                        "schema file {file:?} is declared by both {owner:?} and {name:?}"
                    ));
                }
                if !file_exists(file) {
                    return Err(format!("schema file {file:?} does not exist"));
                }
            }
        }

        self.resolve(self.schema.keys().map(String::as_str))?;
        for (name, preset) in &self.presets {
            self.validate_selection(&format!("preset {name}"), &preset.capabilities)?;
        }
        self.validate_selection("deployment", &self.deployment.capabilities)?;
        let full = self
            .presets
            .get("full")
            .ok_or_else(|| "manifest must declare preset \"full\"".to_owned())?;
        let full_files = self.resolve(full.capabilities.iter().map(String::as_str))?;
        let deployed_files =
            self.resolve(self.deployment.capabilities.iter().map(String::as_str))?;
        if full_files.iter().collect::<HashSet<_>>()
            != deployed_files.iter().collect::<HashSet<_>>()
        {
            return Err(
                "preset \"full\" and deployment must resolve to the same schema files".into(),
            );
        }
        Ok(())
    }

    fn validate_selection(&self, label: &str, capabilities: &[String]) -> Result<(), String> {
        if capabilities.is_empty() {
            return Err(format!("{label} must select at least one capability"));
        }
        reject_duplicates(capabilities, &format!("{label} capabilities"))?;
        for capability in capabilities {
            if !self.schema.contains_key(capability) {
                return Err(format!("{label} selects unknown capability {capability:?}"));
            }
        }
        Ok(())
    }

    fn resolve<'a>(
        &'a self,
        roots: impl IntoIterator<Item = &'a str>,
    ) -> Result<Vec<&'a str>, String> {
        fn visit<'a>(
            manifest: &'a Manifest,
            name: &'a str,
            state: &mut HashMap<&'a str, u8>,
            stack: &mut Vec<&'a str>,
            files: &mut Vec<&'a str>,
        ) -> Result<(), String> {
            match state.get(name) {
                Some(1) => {
                    let start = stack.iter().position(|entry| *entry == name).unwrap_or(0);
                    let mut cycle = stack[start..].to_vec();
                    cycle.push(name);
                    return Err(format!(
                        "schema capability dependency cycle: {}",
                        cycle.join(" -> ")
                    ));
                }
                Some(2) => return Ok(()),
                _ => {}
            }
            let capability = manifest
                .schema
                .get(name)
                .ok_or_else(|| format!("unknown schema capability {name:?}"))?;
            state.insert(name, 1);
            stack.push(name);
            for dependency in &capability.depends_on {
                visit(manifest, dependency, state, stack, files)?;
            }
            stack.pop();
            state.insert(name, 2);
            files.extend(capability.files.iter().map(String::as_str));
            Ok(())
        }

        let mut state = HashMap::new();
        let mut stack = Vec::new();
        let mut files = Vec::new();
        for root in roots {
            visit(self, root, &mut state, &mut stack, &mut files)?;
        }
        Ok(files)
    }

    pub(crate) fn declared_files(&self) -> Vec<&str> {
        self.schema
            .values()
            .flat_map(|capability| capability.files.iter().map(String::as_str))
            .collect()
    }

    pub(crate) fn preset_files(&self, name: &str) -> Result<Vec<&str>, String> {
        let preset = self
            .presets
            .get(name)
            .ok_or_else(|| format!("unknown schema preset {name:?}"))?;
        self.resolve(preset.capabilities.iter().map(String::as_str))
    }
}

fn reject_duplicates(values: &[String], label: &str) -> Result<(), String> {
    let mut seen = HashSet::new();
    for value in values {
        if !seen.insert(value) {
            return Err(format!("{label} contains duplicate {value:?}"));
        }
    }
    Ok(())
}

#[cfg(test)]
mod tests {
    use super::*;

    const VALID: &str = r#"
[schema.kernel]
files = ["kernel.surql"]

[schema.application]
depends_on = ["kernel"]
files = ["application.surql"]

[preset.full]
capabilities = ["application"]

[deployment]
capabilities = ["application"]
"#;

    fn parse(contents: &str) -> Result<Manifest, String> {
        Manifest::parse(contents, |file| {
            matches!(file, "kernel.surql" | "application.surql")
        })
    }

    #[test]
    fn rejects_unknown_capability() {
        let contents = VALID.replacen(
            "capabilities = [\"application\"]",
            "capabilities = [\"missing\"]",
            1,
        );
        assert!(parse(&contents).unwrap_err().contains("unknown capability"));
    }

    #[test]
    fn rejects_dependency_cycle() {
        let contents = VALID.replacen(
            "[schema.kernel]\nfiles",
            "[schema.kernel]\ndepends_on = [\"application\"]\nfiles",
            1,
        );
        assert!(parse(&contents).unwrap_err().contains("dependency cycle"));
    }

    #[test]
    fn rejects_duplicate_file() {
        let contents = VALID.replacen(
            "files = [\"application.surql\"]",
            "files = [\"kernel.surql\"]",
            1,
        );
        assert!(parse(&contents).unwrap_err().contains("declared by both"));
    }

    #[test]
    fn rejects_missing_file() {
        let error = Manifest::parse(VALID, |file| file == "kernel.surql").unwrap_err();
        assert!(error.contains("does not exist"));
    }

    #[test]
    fn preserves_dependency_and_declaration_order() {
        assert_eq!(
            parse(VALID).unwrap().preset_files("full").unwrap(),
            ["kernel.surql", "application.surql"]
        );
    }

    #[test]
    fn rejects_deployment_and_full_preset_mismatch() {
        let contents = VALID.replacen(
            "[deployment]\ncapabilities = [\"application\"]",
            "[deployment]\ncapabilities = [\"kernel\"]",
            1,
        );
        assert!(parse(&contents).unwrap_err().contains("same schema files"));
    }
}
