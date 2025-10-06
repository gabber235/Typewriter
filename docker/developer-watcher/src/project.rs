use crate::config::{COMPONENT_SUFFIX, PROVIDER_SUFFIX};
use heck::ToSnakeCase;
use std::fmt as std_fmt;
use std::path::PathBuf;

#[derive(Debug, Clone, PartialEq, Eq, PartialOrd, Ord)]
pub enum Project {
    Component {
        name: String,
        version: String,
        directory: PathBuf,
    },
    Provider {
        name: String,
        version: String,
        directory: PathBuf,
    },
}

impl std_fmt::Display for Project {
    fn fmt(&self, f: &mut std_fmt::Formatter<'_>) -> std_fmt::Result {
        match self {
            Project::Component {
                name,
                version,
                directory,
            } => {
                write!(
                    f,
                    "Component {} (version: {}) in {}",
                    name,
                    version,
                    directory.display()
                )
            }
            Project::Provider {
                name,
                version,
                directory,
            } => {
                write!(
                    f,
                    "Provider {} (version: {}) in {}",
                    name,
                    version,
                    directory.display()
                )
            }
        }
    }
}

impl Project {
    pub fn name(&self) -> &str {
        match self {
            Project::Component { name, .. } => name,
            Project::Provider { name, .. } => name,
        }
    }

    pub fn version(&self) -> &str {
        match self {
            Project::Component { version, .. } => version,
            Project::Provider { version, .. } => version,
        }
    }

    pub fn directory(&self) -> &PathBuf {
        match self {
            Project::Component { directory, .. } => directory,
            Project::Provider { directory, .. } => directory,
        }
    }

    pub fn get_image_reference(&self, registry_url: &str, file_name: &str) -> Option<String> {
        let snake_name = self.name().to_snake_case();
        match self {
            Project::Component { .. } if file_name.ends_with(COMPONENT_SUFFIX) => Some(format!(
                "{}/{}:{}",
                registry_url,
                snake_name,
                self.version()
            )),
            Project::Provider { .. } if file_name.ends_with(PROVIDER_SUFFIX) => Some(format!(
                "{}/{}:{}",
                registry_url,
                snake_name,
                self.version()
            )),
            _ => None,
        }
    }
}
