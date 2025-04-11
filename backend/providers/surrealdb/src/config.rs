use std::collections::HashMap;

use serde::{Deserialize, Serialize};
use tracing::info;

#[derive(Debug, Default, Clone, Serialize, Deserialize, PartialEq)]
pub struct ProviderConfig {
    pub url: String,
    pub namespace: String,
    pub database: String,
    pub auth: Auth,
}

#[derive(Debug, Clone, Serialize, Deserialize, PartialEq)]
pub enum Auth {
    Root { username: String, password: String },
    Namespace { username: String, password: String },
    Database { username: String, password: String },
}

impl Default for Auth {
    fn default() -> Self {
        Auth::Root {
            username: "root".to_string(),
            password: "root".to_string(),
        }
    }
}

impl TryFrom<&HashMap<String, String>> for ProviderConfig {
    type Error = anyhow::Error;

    fn try_from(values: &HashMap<String, String>) -> Result<Self, Self::Error> {
        let url = get_value(values, "url")?;
        let namespace = get_value(values, "namespace")?;
        let database = get_value(values, "database")?;
        let auth_type = get_value(values, "auth")?;
        let username = get_value(values, "username")?;
        let password = get_value(values, "password")?;
        let auth = match auth_type.as_str() {
            "root" => {
                info!("Using root auth");
                Auth::Root { username, password }
            }
            "namespace" => {
                info!("Using namespace auth");
                Auth::Namespace { username, password }
            }
            "database" => {
                info!("Using database auth");
                Auth::Database { username, password }
            }
            _ => return Err(anyhow::anyhow!("Unknown auth type")),
        };

        Ok(ProviderConfig {
            url,
            namespace,
            database,
            auth,
        })
    }
}

fn get_value(values: &HashMap<String, String>, key: &str) -> Result<String, anyhow::Error> {
    values
        .get(key)
        .ok_or_else(|| anyhow::anyhow!("{} is required", key))
        .map(|v| v.to_string())
}
