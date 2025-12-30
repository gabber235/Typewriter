use prost::Message;
use surrealdb_component::query;
use wasmcloud_component::info;

use crate::{
    authentik::{create_service_account, AuthentikError},
    typewriter::{
        api::v1::{
            get_sentinel_credentials_response, issue_service_identity_response,
            GetSentinelCredentialsResponse, IssueServiceIdentityRequest,
            IssueServiceIdentityResponse, SentinelCredentials, ServiceCredentials,
        },
        models::v1::ServiceType,
    },
};

// Word lists for generating friendly names
const ADJECTIVES: &[&str] = &[
    "swift", "bright", "calm", "bold", "keen", "warm", "cool", "wild", "soft", "quick", "brave",
    "clear", "crisp", "eager", "fair", "glad", "happy", "jolly", "kind", "lively", "merry",
    "noble", "proud", "quiet", "rapid", "sharp", "smart", "sunny", "tender", "vivid", "agile",
    "alert", "ample", "azure", "bliss", "breezy", "clever", "cosmic", "dapper", "daring",
    "elegant", "fancy", "gentle", "golden", "graceful", "humble", "ivory", "jade", "jovial",
    "lunar", "magic", "mystic", "nimble", "olive", "peaceful", "prime", "radiant", "rustic",
    "sage", "serene", "silver", "stellar", "sturdy", "teal", "tranquil", "unique", "velvet",
    "vibrant", "whimsy", "zesty",
];

const COLORS: &[&str] = &[
    "red", "orange", "yellow", "green", "blue", "purple", "pink", "brown", "black", "white",
    "gray", "gold", "silver", "bronze", "copper", "platinum", "crimson", "navy", "teal", "cyan",
    "lime", "violet", "magenta",
];

const NOUNS: &[&str] = &[
    "fox", "owl", "bear", "wolf", "deer", "hawk", "swan", "dove", "lynx", "seal", "pine", "oak",
    "fern", "moss", "reef", "dune", "peak", "vale", "cove", "glen", "star", "moon", "wave", "wind",
    "rain", "snow", "mist", "dew", "frost", "ember", "atlas", "beacon", "brook", "canyon", "cedar",
    "cliff", "coral", "crater", "delta", "falcon", "glacier", "grove", "harbor", "horizon",
    "island", "jasper", "lagoon", "meadow", "nebula", "oasis", "orchid", "pebble", "phoenix",
    "quartz", "rapids", "raven", "ridge", "river", "sage", "shadow", "sphinx", "summit", "thunder",
    "timber", "trail", "tulip", "valley", "willow", "zephyr", "zenith",
];

#[derive(Debug)]
pub enum HandlerError {
    InvalidServiceTypes(String),
    AuthentikError(String),
    DatabaseError(String),
    EncodeError(String),
    DecodeError(String),
    ConfigError(String),
}

impl std::fmt::Display for HandlerError {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        match self {
            HandlerError::InvalidServiceTypes(msg) => write!(f, "Invalid service types: {}", msg),
            HandlerError::AuthentikError(msg) => write!(f, "Authentik error: {}", msg),
            HandlerError::DatabaseError(msg) => write!(f, "Database error: {}", msg),
            HandlerError::EncodeError(msg) => write!(f, "Encode error: {}", msg),
            HandlerError::DecodeError(msg) => write!(f, "Decode error: {}", msg),
            HandlerError::ConfigError(msg) => write!(f, "Config error: {}", msg),
        }
    }
}

impl std::error::Error for HandlerError {}

impl From<AuthentikError> for HandlerError {
    fn from(error: AuthentikError) -> Self {
        HandlerError::AuthentikError(error.to_string())
    }
}

impl From<prost::DecodeError> for HandlerError {
    fn from(error: prost::DecodeError) -> Self {
        HandlerError::DecodeError(error.to_string())
    }
}

impl From<prost::EncodeError> for HandlerError {
    fn from(error: prost::EncodeError) -> Self {
        HandlerError::EncodeError(error.to_string())
    }
}

/// Generates a friendly service name in snake_case format.
/// Uses a deterministic selection based on the provided seed (typically the user_uid).
/// Format: {adjective}_{color}_{noun} (e.g., "swift_blue_fox")
fn generate_friendly_name(seed: &str) -> String {
    // Generate a 64-bit hash from the seed string
    let hash = seed
        .bytes()
        .fold(0u64, |acc, b| acc.wrapping_mul(31).wrapping_add(b as u64));

    let adj_len = ADJECTIVES.len() as u64;
    let color_len = COLORS.len() as u64;
    let noun_len = NOUNS.len() as u64;

    // Use division and modulo to extract three distinct indices from the hash
    let adj_idx = (hash % adj_len) as usize;
    let color_idx = ((hash / adj_len) % color_len) as usize;
    let noun_idx = ((hash / (adj_len * color_len)) % noun_len) as usize;

    format!(
        "{}_{}_{}",
        ADJECTIVES[adj_idx], COLORS[color_idx], NOUNS[noun_idx]
    )
}

/// Validates that the provided service types are acceptable for identity registration.
///
/// Use this before creating a service account to ensure the caller has specified
/// at least one valid, concrete service type. This prevents accidental registration
/// of services with no capabilities or with the placeholder `Unspecified` type.
///
/// Returns an error if the slice is empty, contains `SERVICE_TYPE_UNSPECIFIED`,
/// or contains any unrecognized service type values.
fn validate_service_types(service_types: &[i32]) -> Result<(), HandlerError> {
    if service_types.is_empty() {
        return Err(HandlerError::InvalidServiceTypes(
            "Service types cannot be empty".to_string(),
        ));
    }

    for &service_type in service_types {
        match ServiceType::try_from(service_type) {
            Ok(ServiceType::Unspecified) => {
                return Err(HandlerError::InvalidServiceTypes(
                    "SERVICE_TYPE_UNSPECIFIED is not allowed".to_string(),
                ));
            }
            Ok(ServiceType::Engine) | Ok(ServiceType::Realm) => {
                // Valid types
            }
            Err(_) => {
                return Err(HandlerError::InvalidServiceTypes(format!(
                    "Invalid service type: {}",
                    service_type
                )));
            }
        }
    }

    Ok(())
}

/// Converts service types from i32 to their string representations for storage
/// The database expects lowercase values: "engine" and "realm"
fn service_types_to_strings(service_types: &[i32]) -> Vec<String> {
    service_types
        .iter()
        .filter_map(|&st| ServiceType::try_from(st).ok())
        .filter_map(|st| match st {
            ServiceType::Engine => Some("engine".to_string()),
            ServiceType::Realm => Some("realm".to_string()),
            ServiceType::Unspecified => None,
        })
        .collect()
}

pub fn handle_register(body: &[u8]) -> Result<Vec<u8>, HandlerError> {
    let request = IssueServiceIdentityRequest::decode(body)?;

    validate_service_types(&request.service_types)?;

    let authentik_response = create_service_account()?;

    let friendly_name = generate_friendly_name(&authentik_response.user_uid);

    let service_type_strings = service_types_to_strings(&request.service_types);

    let metadata = request.metadata.unwrap_or_default();
    let engine_version = metadata.engine_version.unwrap_or_default();
    let realm_version = metadata.realm_version.unwrap_or_default();

    let result = query(
        r#"
        CREATE type::thing('service', $service_id) SET
            name = $name,
            service_types = $service_types,
            created_at = time::now(),
            metadata = {
                engine_version: $engine_version,
                realm_version: $realm_version
            }
        RETURN AFTER;
        "#,
    )
    .bind("service_id", &authentik_response.user_uid)
    .bind("name", &friendly_name)
    .bind("service_types", &service_type_strings)
    .bind("engine_version", &engine_version)
    .bind("realm_version", &realm_version)
    .execute()
    .map_err(|e| HandlerError::DatabaseError(format!("Failed to create service: {}", e)))?;

    let _service_record: serde_json::Value = result
        .parse(0)
        .map_err(|e| HandlerError::DatabaseError(format!("Failed to parse result: {}", e)))?;

    info!(
        "Created a new identity {} for {:?}",
        &authentik_response.user_uid, &service_type_strings
    );

    let credentials = ServiceCredentials {
        service_id: authentik_response.user_uid,
        username: authentik_response.username,
        token: authentik_response.token,
    };

    let response = IssueServiceIdentityResponse {
        result: Some(issue_service_identity_response::Result::Credentials(
            credentials,
        )),
    };

    Ok(response.encode_to_vec())
}

pub fn handle_get_sentinel_credentials() -> Result<Vec<u8>, HandlerError> {
    let jwt = std::env::var("NATS_SENTINEL_JWT")
        .map_err(|_| HandlerError::ConfigError("NATS_SENTINEL_JWT not found in environment".to_string()))?;

    let seed = std::env::var("NATS_SENTINEL_SEED")
        .map_err(|_| HandlerError::ConfigError("NATS_SENTINEL_SEED not found in environment".to_string()))?;

    let credentials = SentinelCredentials { jwt, seed };

    let response = GetSentinelCredentialsResponse {
        result: Some(get_sentinel_credentials_response::Result::Credentials(
            credentials,
        )),
    };

    Ok(response.encode_to_vec())
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_generate_friendly_name_format() {
        let name = generate_friendly_name("abc123def456");
        let parts: Vec<&str> = name.split('_').collect();

        assert_eq!(
            parts.len(),
            3,
            "Name should have exactly 3 parts separated by underscores"
        );
        assert!(
            ADJECTIVES.contains(&parts[0]),
            "First part '{}' should be a valid adjective",
            parts[0]
        );
        assert!(
            COLORS.contains(&parts[1]),
            "Second part '{}' should be a valid color",
            parts[1]
        );
        assert!(
            NOUNS.contains(&parts[2]),
            "Third part '{}' should be a valid noun",
            parts[2]
        );
    }

    #[test]
    fn test_generate_friendly_name_deterministic() {
        // Same seed must produce the exact same string
        let seed = "test-seed-123";
        let name1 = generate_friendly_name(seed);
        let name2 = generate_friendly_name(seed);
        assert_eq!(name1, name2);
    }

    #[test]
    fn test_generate_friendly_name_different_seeds() {
        // Different seeds should produce different names.
        // With 114k options, the chance of a collision here is ~0.0008%
        let name1 = generate_friendly_name("seed-one");
        let name2 = generate_friendly_name("seed-two");
        assert_ne!(name1, name2);
    }

    #[test]
    fn test_generate_friendly_name_valid_pattern() {
        let name = generate_friendly_name("12345678-1234-1234-1234-123456789abc");

        // Matches typical DB constraints: lowercase alphanumeric and underscores
        // pattern: ^[a-z0-9][a-z0-9_]{1,}[a-z0-9]$
        let regex = regex::Regex::new(r"^[a-z0-9][a-z0-9_]{1,}[a-z0-9]$").unwrap();
        assert!(
            regex.is_match(&name),
            "Name '{}' doesn't match the required database pattern",
            name
        );
    }

    #[test]
    fn test_validate_service_types_valid() {
        assert!(validate_service_types(&[ServiceType::Engine as i32]).is_ok());
        assert!(validate_service_types(&[ServiceType::Realm as i32]).is_ok());
        assert!(
            validate_service_types(&[ServiceType::Engine as i32, ServiceType::Realm as i32])
                .is_ok()
        );
    }

    #[test]
    fn test_validate_service_types_invalid() {
        // Empty
        assert!(validate_service_types(&[]).is_err());

        // Contains Unspecified
        assert!(validate_service_types(&[ServiceType::Unspecified as i32]).is_err());

        // Contains invalid type
        assert!(validate_service_types(&[999]).is_err());
    }

    #[test]
    fn test_service_types_to_strings() {
        let types = vec![ServiceType::Engine as i32, ServiceType::Realm as i32];
        let strings = service_types_to_strings(&types);
        assert_eq!(strings.len(), 2);
        assert!(strings.contains(&"engine".to_string()));
        assert!(strings.contains(&"realm".to_string()));
    }
}
