use crate::identity::{IdentityRepository, NewIdentity, RepositoryError};
use wasmcloud_utils::database::service::ServiceRoleRecord;
use wasmcloud_utils::database::{RecordId, TransactionOutcome, read_query, transaction_query};

pub struct SurrealIdentityRepository;

impl IdentityRepository for SurrealIdentityRepository {
    #[tracing::instrument(skip_all)]
    async fn validate_role(
        &self,
        role: &ServiceRoleRecord,
    ) -> Result<Result<bool, String>, RepositoryError> {
        otel_wasi::attribute!("persistence.operation" = "validate_role");

        read_query!("RETURN fn::service::valid_role($role);")
            .bind("role", role)
            .execute()
            .await
            .map_err(|error| RepositoryError(error.to_string()))?
            .transaction()
            .map(|outcome| match outcome {
                TransactionOutcome::Committed(value) => Ok(value),
                TransactionOutcome::Rejected(error) => Err(error.message().to_owned()),
            })
            .map_err(|error| RepositoryError(error.to_string()))
    }

    #[tracing::instrument(skip_all)]
    async fn create_identity(
        &self,
        identity: &NewIdentity,
    ) -> Result<Result<RecordId, String>, RepositoryError> {
        otel_wasi::attribute!("persistence.operation" = "create_identity");

        let service_id = RecordId::new("service", identity.service_id.as_str());
        transaction_query!(
            RecordId,
            r#"
            BEGIN TRANSACTION;

            LET $identity = CREATE ONLY $service_id
            SET
                name = $display_name,
                role = $role
            RETURN VALUE id;

            RETURN $identity;

            COMMIT TRANSACTION;
            "#,
        )
        .bind("service_id", service_id)
        .bind("display_name", &identity.display_name)
        .bind("role", &identity.role)
        .execute()
        .await
        .map_err(|error| RepositoryError(error.to_string()))?
        .decode()
        .map(|outcome| match outcome {
            TransactionOutcome::Committed(value) => Ok(value),
            TransactionOutcome::Rejected(error) => Err(error.message().to_owned()),
        })
        .map_err(|error| RepositoryError(error.to_string()))
    }
}
