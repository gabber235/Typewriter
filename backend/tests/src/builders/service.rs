//! Service builder for seeding test data.

use anyhow::{Context, Result};
use chrono::{Duration, Utc};
use serde::{Deserialize, Serialize};
use surrealdb::engine::any::Any;
use surrealdb::{RecordId, Surreal};
use uuid::Uuid;

use crate::Organization;

/// A service record created in the database.
#[derive(Debug, Clone, Deserialize)]
pub struct Service {
    pub id: String,
    pub name: String,
    pub service_types: Vec<String>,
}

/// Metadata stored for a service.
#[derive(Debug, Serialize)]
struct ServiceMetadata {
    engine_version: Option<String>,
    realm_version: Option<String>,
}

/// Registration data stored for a service.
#[derive(Debug, Serialize)]
struct RegistrationData {
    token: String,
    expires_at: surrealdb::sql::Datetime,
}

/// Data to be stored for a service record.
#[derive(Debug, Serialize)]
struct ServiceData {
    name: String,
    service_types: Vec<String>,
    created_at: surrealdb::sql::Datetime,
    metadata: ServiceMetadata,
    organization: Option<surrealdb::sql::Thing>,
    registration: Option<RegistrationData>,
}

/// Record returned from SurrealDB create operation.
#[derive(Debug, Deserialize)]
struct ServiceRecord {
    id: RecordId,
    name: String,
    service_types: Vec<String>,
}

/// Builder for creating test services.
pub struct ServiceBuilder {
    name: String,
    service_types: Vec<String>,
    organization_id: Option<String>,
    registration_token: Option<String>,
    registration_expired: bool,
}

impl ServiceBuilder {
    /// Create a new service builder with a name.
    pub fn new(name: impl Into<String>) -> Self {
        Self {
            name: name.into(),
            service_types: vec![],
            organization_id: None,
            registration_token: None,
            registration_expired: false,
        }
    }

    /// Add a service type ("engine" or "realm").
    pub fn service_type(mut self, t: impl Into<String>) -> Self {
        self.service_types.push(t.into());
        self
    }

    /// Bind this service to an organization.
    pub fn organization(mut self, org: &Organization) -> Self {
        self.organization_id = Some(org.id.clone());
        self
    }

    /// Set a registration token (creates valid, non-expired registration).
    pub fn registration_token(mut self, token: impl Into<String>) -> Self {
        self.registration_token = Some(token.into());
        self.registration_expired = false;
        self
    }

    /// Set an expired registration token.
    pub fn registration_token_expired(mut self, token: impl Into<String>) -> Self {
        self.registration_token = Some(token.into());
        self.registration_expired = true;
        self
    }

    /// Create the service in the database.
    pub async fn create(self, db: &Surreal<Any>) -> Result<Service> {
        let id = Uuid::new_v4().to_string();

        let organization = self.organization_id.map(|oid| {
            surrealdb::sql::Thing::from(("organization", oid.as_str()))
        });

        let registration = self.registration_token.map(|token| {
            let expires_at = if self.registration_expired {
                Utc::now() - Duration::minutes(5)
            } else {
                Utc::now() + Duration::minutes(5)
            };
            RegistrationData {
                token,
                expires_at: surrealdb::sql::Datetime::from(expires_at),
            }
        });

        let service_types = if self.service_types.is_empty() {
            vec!["engine".to_string()]
        } else {
            self.service_types
        };

        let data = ServiceData {
            name: self.name.clone(),
            service_types: service_types.clone(),
            created_at: surrealdb::sql::Datetime::from(Utc::now()),
            metadata: ServiceMetadata {
                engine_version: Some("1.0.0".to_string()),
                realm_version: Some("0.5.0".to_string()),
            },
            organization,
            registration,
        };

        let _record: Option<ServiceRecord> = db
            .create(("service", &id))
            .content(data)
            .await
            .context("Failed to create service")?;

        Ok(Service {
            id,
            name: self.name,
            service_types,
        })
    }
}
