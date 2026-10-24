use crate::identity::{IdentityRepository, IdentityRepositoryError, NewIdentity, RepositoryError};
use wasmcloud_utils::database::service::ServiceRoleRecord;
use wasmcloud_utils::database::{RecordId, TransactionOutcome, read_query, transaction_query};

/// Identity repository backed by SurrealDB service records.
///
/// Role validation delegates policy to the database function. Record creation uses a
/// database transaction, so the service record mutation is atomic within SurrealDB. This
/// repository cannot make that transaction atomic with the external account provider.
pub struct SurrealIdentityRepository;

/// Role value admitted by repository policy.
pub struct ValidatedServiceRole(ServiceRoleRecord);

impl ValidatedServiceRole {
    pub fn as_record(&self) -> &ServiceRoleRecord {
        &self.0
    }

    #[cfg(test)]
    pub(crate) fn admit_for_test(role: ServiceRoleRecord) -> Self {
        Self(role)
    }
}

impl IdentityRepository for SurrealIdentityRepository {
    #[tracing::instrument(skip_all)]
    async fn validate_role(
        &self,
        role: ServiceRoleRecord,
    ) -> Result<ValidatedServiceRole, IdentityRepositoryError> {
        otel_wasi::attribute!("persistence.operation" = "validate_role");

        let outcome = read_query!("RETURN fn::service::valid_role($role);")
            .bind("role", &role)
            .execute()
            .await
            .map_err(|error| {
                IdentityRepositoryError::Infrastructure(RepositoryError(error.to_string()))
            })?
            .transaction()
            .map_err(|error| {
                IdentityRepositoryError::Infrastructure(RepositoryError(error.to_string()))
            })?;
        match outcome {
            TransactionOutcome::Committed(true) => Ok(ValidatedServiceRole(role)),
            TransactionOutcome::Committed(false) => Err(IdentityRepositoryError::Infrastructure(
                RepositoryError("role policy returned false without a domain rejection".to_owned()),
            )),
            TransactionOutcome::Rejected(error) => {
                Err(IdentityRepositoryError::rejected(error.message()))
            }
        }
    }

    #[tracing::instrument(skip_all)]
    async fn create_identity(
        &self,
        identity: &NewIdentity,
    ) -> Result<RecordId, IdentityRepositoryError> {
        otel_wasi::attribute!("persistence.operation" = "create_identity");

        let service_id = RecordId::new("service", identity.service_id.as_str());
        let outcome = transaction_query!(
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
        .bind("role", identity.role.as_record())
        .execute()
        .await
        .map_err(|error| {
            IdentityRepositoryError::Infrastructure(RepositoryError(error.to_string()))
        })?
        .decode()
        .map_err(|error| {
            IdentityRepositoryError::Infrastructure(RepositoryError(error.to_string()))
        })?;
        match outcome {
            TransactionOutcome::Committed(value) => Ok(value),
            TransactionOutcome::Rejected(error) => {
                Err(IdentityRepositoryError::rejected(error.message()))
            }
        }
    }
}
