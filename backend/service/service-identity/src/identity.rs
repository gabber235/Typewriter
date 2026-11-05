use wasmcloud_utils::database::RecordId;
use wasmcloud_utils::skir::base::service::v1::identity::*;
use wasmcloud_utils::{
    SkirResponse,
    database::service::{ServiceRoleRecord, ServiceRoleTypeRecord},
    database_domain_slug, skir_variant,
};

pub use crate::repository::ValidatedServiceRole;

/// Credentials and provider identifier returned after an external account is provisioned.
///
/// The provider owns these values. The workflow uses `user_uid` as the durable service
/// identifier and retains `user_pk` only to address compensation if database persistence
/// fails.
pub struct ProvisionedAccount {
    pub username: String,
    pub token: String,
    pub user_uid: String,
    pub user_pk: i64,
}

/// The service record to persist after role validation and account provisioning succeed.
///
/// This value carries the provider UID, generated display name, and validated role into
/// the repository boundary. It does not represent organization membership or liveness.
pub struct NewIdentity {
    pub service_id: String,
    pub display_name: String,
    pub role: ValidatedServiceRole,
}

/// Repository failures preserve domain rejection identity through compensation.
///
/// A domain rejection holds the response variant its database slug names, so the workflow
/// returns it unchanged after compensation.
pub enum IdentityRepositoryError {
    Domain(IssueServiceIdentityResponse),
    Infrastructure(RepositoryError),
    UnrecognizedDomain(String),
}

impl IdentityRepositoryError {
    /// Maps a database rejection message to the domain error variant its slug names.
    pub(crate) fn rejected(message: &str) -> Self {
        let slug = database_domain_slug(message);
        match IssueServiceIdentityResponse::domain_error_from_slug(slug) {
            Some(response) => Self::Domain(response),
            None => Self::UnrecognizedDomain(slug.to_owned()),
        }
    }

    fn into_response(self) -> Result<IssueServiceIdentityResponse, otel_wasi::Error> {
        match self {
            Self::Domain(response) => Ok(response),
            Self::Infrastructure(error) => {
                // An `error` event becomes the span's status, the one part of a span a host's log
                // prints, so the reason is readable where no trace backend runs.
                tracing::error!(error = %error);
                otel_wasi::main_attribute!(
                    "error" = true,
                    "exception.slug" = "service-identity-repository-failed",
                    "exception.message" = error.to_string(),
                    "identity.persistence.outcome" = "infrastructure_error",
                    "identity.outcome" = "internal_error",
                );
                Ok(IssueServiceIdentityResponse::internal_error())
            }
            Self::UnrecognizedDomain(slug) => Err(otel_wasi::Error::new(
                "skir-domain-error-unknown",
                format!("unknown SKIR domain error slug `{slug}`"),
            )),
        }
    }
}

/// Failure categories exposed by the external account boundary.
///
/// `Unavailable` means the provider could not serve the operation. `Internal` covers
/// configuration, protocol, parsing, and other failures that cannot be returned as a
/// domain response. A successful create call may have caused an account side effect even
/// when a later operation fails.
#[derive(Debug)]
pub enum ProviderError {
    Unavailable,
    Internal,
}
/// Infrastructure failure while talking to the identity repository.
///
/// Database domain rejections are kept separate from this error so the workflow can map
/// their known slugs into the public Skir response.
#[derive(Debug)]
pub struct RepositoryError(pub String);

impl std::fmt::Display for RepositoryError {
    fn fmt(&self, formatter: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        formatter.write_str(&self.0)
    }
}

/// Failure to obtain enough random input for generated account names.
#[derive(Debug)]
pub struct NamingError;

/// Boundary for creating an external account and compensating for failed persistence.
///
/// Creation happens before the service record exists. Deletion is therefore a best effort
/// compensation operation, and its failure is recorded without replacing the original
/// persistence failure.
pub trait AccountProvider {
    /// Creates the provider account whose UID becomes the service identity.
    async fn create_account(&self, username: &str) -> Result<ProvisionedAccount, ProviderError>;

    /// Attempts to remove an account that this workflow provisioned but could not persist.
    async fn delete_account(&self, user_pk: i64) -> Result<(), ProviderError>;
}

/// Boundary for role policy evaluation and durable service record creation.
///
/// The implementation keeps database domain rejection distinct from repository
/// infrastructure failure. Record creation is atomic within the database transaction,
/// but it is not atomic with the external account provider.
pub trait IdentityRepository {
    /// Applies database role policy before any account is provisioned.
    async fn validate_role(
        &self,
        role: ServiceRoleRecord,
    ) -> Result<ValidatedServiceRole, IdentityRepositoryError>;

    /// Atomically creates the service record inside the repository database.
    async fn create_identity(
        &self,
        identity: &NewIdentity,
    ) -> Result<RecordId, IdentityRepositoryError>;
}

/// Boundary for obtaining the names used by the provider and service record.
///
/// Implementations supply nondeterminism. The workflow does not use a generated name
/// until role validation has succeeded.
pub trait NameSource {
    /// Produces a provider username and a human readable service name.
    fn generate(&self) -> Result<crate::names::GeneratedNames, NamingError>;
}

/// Coordinates issuance of a service identity across policy, naming, provider, and storage boundaries.
///
/// Role validation runs first. After valid names are generated, the workflow provisions an
/// external account and then creates the service record. Known policy and persistence
/// rejection slugs are returned through the contract. Infrastructure failures become
/// `internal_error`, and provider creation unavailability becomes
/// `identity_provider_unavailable_error`.
///
/// The database create transaction is atomic only inside the repository. If it rejects or
/// fails after account creation, this function attempts provider deletion before mapping
/// the original failure. Compensation failure does not prove the account was deleted and
/// does not replace the original domain or infrastructure result.
#[tracing::instrument(skip_all)]
pub async fn issue_identity<P: AccountProvider, R: IdentityRepository, N: NameSource>(
    provider: &P,
    repository: &R,
    name_source: &N,
    request: IssueServiceIdentityRequest,
) -> Result<IssueServiceIdentityResponse, otel_wasi::Error> {
    let role = match ServiceRoleRecord::try_from(request.role) {
        Ok(role) => role,
        Err(_) => {
            otel_wasi::main_attribute!("identity.outcome" = "unknown-role-error");
            return Ok(skir_variant!(
                IssueServiceIdentityResponse::UnknownRoleError {}
            ));
        }
    };
    otel_wasi::main_attribute!(
        "identity.role.type" = match role.role_type {
            ServiceRoleTypeRecord::Host => "host",
            ServiceRoleTypeRecord::Custom => "custom",
        },
    );

    let admitted = match repository.validate_role(role).await {
        Ok(admitted) => admitted,
        Err(error) => return error.into_response(),
    };
    otel_wasi::main_attribute!("identity.validation.outcome" = "success");

    let names = match name_source.generate() {
        Ok(names) => names,
        Err(_) => {
            otel_wasi::main_attribute!(
                "error" = true,
                "exception.slug" = "service-identity-name-generation-failed",
                "identity.outcome" = "internal_error",
            );
            return Ok(IssueServiceIdentityResponse::internal_error());
        }
    };

    let account = match provider.create_account(&names.authentik_username).await {
        Ok(account) => {
            otel_wasi::main_attribute!("identity.provider.create.outcome" = "success");
            account
        }
        Err(ProviderError::Unavailable) => {
            otel_wasi::main_attribute!(
                "identity.provider.create.outcome" = "unavailable",
                "identity.outcome" = "identity-provider-unavailable-error",
            );
            return Ok(skir_variant!(
                IssueServiceIdentityResponse::IdentityProviderUnavailableError {}
            ));
        }
        Err(ProviderError::Internal) => {
            otel_wasi::main_attribute!(
                "error" = true,
                "exception.slug" = "service-identity-provider-create-failed",
                "identity.provider.create.outcome" = "internal_error",
                "identity.outcome" = "internal_error",
            );
            return Ok(IssueServiceIdentityResponse::internal_error());
        }
    };

    let identity = NewIdentity {
        service_id: account.user_uid.clone(),
        display_name: names.display_name.clone(),
        role: admitted,
    };

    match repository.create_identity(&identity).await {
        Ok(_) => {
            otel_wasi::main_attribute!(
                "identity.persistence.outcome" = "success",
                "identity.compensation.outcome" = "not_required",
                "identity.outcome" = "success",
                "identity.service.id" = account.user_uid.clone(),
            );
            Ok(skir_variant!(IssueServiceIdentityResponse::Success {
                service_id: account.user_uid,
                display_name: names.display_name,
                username: account.username,
                token: account.token,
            }))
        }
        Err(original) => {
            match provider.delete_account(account.user_pk).await {
                Ok(()) => otel_wasi::main_attribute!("identity.compensation.outcome" = "success"),
                Err(_) => otel_wasi::main_attribute!(
                    "error" = true,
                    "exception.slug" = "service-identity-compensation-failed",
                    "identity.compensation.outcome" = "failed",
                ),
            }
            original.into_response()
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn a_database_rejection_answers_with_the_response_its_slug_names() {
        let error =
            IdentityRepositoryError::rejected("An error occurred: role-version-invalid-error");

        assert!(matches!(
            error.into_response(),
            Ok(IssueServiceIdentityResponse::RoleVersionInvalidError(_))
        ));
    }

    #[test]
    fn a_database_rejection_with_an_unknown_slug_fails_instead_of_answering() {
        let error = IdentityRepositoryError::rejected("future-error");

        let failure = error
            .into_response()
            .expect_err("an unknown slug has no response");
        assert!(format!("{failure:?}").contains("skir-domain-error-unknown"));
    }
}
