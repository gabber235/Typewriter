use surrealdb_component_sdk::{RecordId, query};

use crate::identity::{IdentityRepository, NewIdentity, RepositoryError};
use wasmcloud_utils::database::service::ServiceRoleRecord;

pub struct SurrealIdentityRepository;

impl IdentityRepository for SurrealIdentityRepository {
    #[tracing::instrument(skip_all)]
    async fn validate_roles(
        &self,
        roles: &[ServiceRoleRecord],
    ) -> Result<Result<bool, String>, RepositoryError> {
        otel_wasi::attribute!("persistence.operation" = "validate_roles");

        query("RETURN fn::service::valid_roles($roles);")
            .bind("roles", roles.to_vec())
            .execute()
            .await
            .map_err(|error| RepositoryError(error.to_string()))?
            .parse_result(0)
            .map_err(|error| RepositoryError(error.to_string()))
    }

    #[tracing::instrument(skip_all)]
    async fn create_identity(
        &self,
        identity: &NewIdentity,
    ) -> Result<Result<RecordId, String>, RepositoryError> {
        otel_wasi::attribute!("persistence.operation" = "create_identity");

        query(
            r#"
            CREATE ONLY type::record('service', $service_id)
            SET
                name = $display_name,
                roles = $roles
            RETURN VALUE id;
            "#,
        )
        .bind("service_id", &identity.service_id)
        .bind("display_name", &identity.display_name)
        .bind("roles", &identity.roles)
        .execute()
        .await
        .map_err(|error| RepositoryError(error.to_string()))?
        .parse_result(0)
        .map_err(|error| RepositoryError(error.to_string()))
    }
}
