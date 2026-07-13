use serde::Serialize;
use surrealdb_component_sdk::RecordId;
use wasmcloud_utils::skir::base::service::v1::identity::*;
use wasmcloud_utils::{SkirDomainResult, SkirDomainResultExt, skir_variant};

#[derive(Clone, Debug, PartialEq, Serialize)]
pub struct ServiceRoleRecord {
    #[serde(rename = "type")]
    pub role_type: &'static str,
    pub version: String,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub name: Option<String>,
}

pub struct ProvisionedAccount {
    pub username: String,
    pub token: String,
    pub user_uid: String,
    pub user_pk: i64,
}

pub struct NewIdentity {
    pub service_id: String,
    pub display_name: String,
    pub roles: Vec<ServiceRoleRecord>,
}

#[derive(Debug)]
pub enum ProviderError {
    Unavailable,
    Internal,
}
#[derive(Debug)]
pub struct RepositoryError(pub String);

impl std::fmt::Display for RepositoryError {
    fn fmt(&self, formatter: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        formatter.write_str(&self.0)
    }
}

#[derive(Debug)]
pub struct NamingError;

pub trait AccountProvider {
    async fn create_account(&self, username: &str) -> Result<ProvisionedAccount, ProviderError>;
    async fn delete_account(&self, user_pk: i64) -> Result<(), ProviderError>;
}

pub trait IdentityRepository {
    async fn validate_roles(
        &self,
        roles: &[ServiceRoleRecord],
    ) -> Result<Result<bool, String>, RepositoryError>;

    async fn create_identity(
        &self,
        identity: &NewIdentity,
    ) -> Result<Result<RecordId, String>, RepositoryError>;
}

pub trait NameSource {
    fn generate(&self) -> Result<crate::names::GeneratedNames, NamingError>;
}

pub fn role_records(roles: Vec<ServiceRole>) -> Result<Vec<ServiceRoleRecord>, ()> {
    roles
        .into_iter()
        .map(|role| match role {
            ServiceRole::Engine(role) => Ok(ServiceRoleRecord {
                role_type: "engine",
                version: role.version,
                name: None,
            }),
            ServiceRole::Realm(role) => Ok(ServiceRoleRecord {
                role_type: "realm",
                version: role.version,
                name: None,
            }),
            ServiceRole::Custom(role) => Ok(ServiceRoleRecord {
                role_type: "custom",
                version: role.version,
                name: Some(role.name),
            }),
            ServiceRole::Unknown(_) => Err(()),
        })
        .collect()
}

#[tracing::instrument(skip_all)]
pub async fn issue_identity<P: AccountProvider, R: IdentityRepository, N: NameSource>(
    provider: &P,
    repository: &R,
    name_source: &N,
    request: IssueServiceIdentityRequest,
) -> Result<IssueServiceIdentityResponse, otel_wasi::Error> {
    let roles = match role_records(request.roles) {
        Ok(roles) => roles,
        Err(()) => {
            otel_wasi::main_attribute!("identity.outcome" = "unknown-role-error");
            return Ok(skir_variant!(
                IssueServiceIdentityResponse::UnknownRoleError {}
            ));
        }
    };
    let engine_roles = roles.iter().filter(|r| r.role_type == "engine").count();
    let realm_roles = roles.iter().filter(|r| r.role_type == "realm").count();
    let custom_roles = roles.iter().filter(|r| r.role_type == "custom").count();
    otel_wasi::main_attribute!(
        "identity.roles.count" = roles.len() as i64,
        "identity.roles.engine.count" = engine_roles as i64,
        "identity.roles.realm.count" = realm_roles as i64,
        "identity.roles.custom.count" = custom_roles as i64,
    );

    let validated = match repository.validate_roles(&roles).await {
        Ok(result) => result,
        Err(_) => {
            otel_wasi::main_attribute!(
                "error" = true,
                "exception.slug" = "service-identity-role-validation-failed",
                "identity.validation.outcome" = "infrastructure_error",
                "identity.outcome" = "internal_error",
            );
            return Ok(skir_variant!(
                IssueServiceIdentityResponse::InternalError {}
            ));
        }
    };

    if let Err(slug) = &validated {
        otel_wasi::main_attribute!(
            "identity.validation.outcome" = slug.clone(),
            "identity.outcome" = slug.clone(),
        );
    }

    let validated = match validated.into_skir_domain_result()? {
        SkirDomainResult::Value(value) => value,
        SkirDomainResult::Response(response) => return Ok(response),
    };

    let _ = validated;
    otel_wasi::main_attribute!("identity.validation.outcome" = "success");

    let names = match name_source.generate() {
        Ok(names) => names,
        Err(_) => {
            otel_wasi::main_attribute!(
                "error" = true,
                "exception.slug" = "service-identity-name-generation-failed",
                "identity.outcome" = "internal_error",
            );
            return Ok(skir_variant!(
                IssueServiceIdentityResponse::InternalError {}
            ));
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
            return Ok(skir_variant!(
                IssueServiceIdentityResponse::InternalError {}
            ));
        }
    };

    let identity = NewIdentity {
        service_id: account.user_uid.clone(),
        display_name: names.display_name.clone(),
        roles,
    };

    let created = repository.create_identity(&identity).await;
    if matches!(created, Ok(Ok(_))) {
        otel_wasi::main_attribute!(
            "identity.persistence.outcome" = "success",
            "identity.compensation.outcome" = "not_required",
            "identity.outcome" = "success",
            "identity.service.id" = account.user_uid.clone(),
        );
        return Ok(IssueServiceIdentityResponse::Success(Box::new(
            IssueServiceIdentityResponse_Success {
                service_id: account.user_uid,
                display_name: names.display_name,
                username: account.username,
                token: account.token,
                _unrecognized: None,
            },
        )));
    }

    if let Ok(Err(slug)) = &created {
        otel_wasi::main_attribute!(
            "identity.persistence.outcome" = slug.clone(),
            "identity.outcome" = slug.clone(),
        );
    }

    let compensation = provider.delete_account(account.user_pk).await;
    match compensation {
        Ok(()) => {
            otel_wasi::main_attribute!("identity.compensation.outcome" = "success");
        }
        Err(_) => {
            otel_wasi::main_attribute!(
                "error" = true,
                "exception.slug" = "service-identity-compensation-failed",
                "identity.compensation.outcome" = "failed",
            );
        }
    }

    match created {
        Ok(result) => match result.into_skir_domain_result()? {
            SkirDomainResult::Value(_) => unreachable!(),
            SkirDomainResult::Response(response) => Ok(response),
        },
        Err(_) => {
            otel_wasi::main_attribute!(
                "error" = true,
                "exception.slug" = "service-identity-persistence-create-failed",
                "identity.persistence.outcome" = "infrastructure_error",
                "identity.outcome" = "internal_error",
            );
            Ok(skir_variant!(
                IssueServiceIdentityResponse::InternalError {}
            ))
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use std::cell::RefCell;

    #[derive(Clone, Copy)]
    enum RepoMode {
        Valid,
        ValidationDomain,
        ValidationInfra,
        ValidationUnknownDomain,
        CreateDomain,
        CreateUnknownDomain,
        CreateInfra,
    }
    struct MockRepo {
        mode: RepoMode,
        validation_calls: RefCell<usize>,
        create_calls: RefCell<usize>,
    }
    impl IdentityRepository for MockRepo {
        async fn validate_roles(
            &self,
            _: &[ServiceRoleRecord],
        ) -> Result<Result<bool, String>, RepositoryError> {
            *self.validation_calls.borrow_mut() += 1;
            match self.mode {
                RepoMode::ValidationDomain => Ok(Err("roles-required-error".into())),
                RepoMode::ValidationInfra => Err(RepositoryError("mock repository failure".into())),
                RepoMode::ValidationUnknownDomain => Ok(Err("future-error".into())),
                _ => Ok(Ok(true)),
            }
        }
        async fn create_identity(
            &self,
            _: &NewIdentity,
        ) -> Result<Result<RecordId, String>, RepositoryError> {
            *self.create_calls.borrow_mut() += 1;
            match self.mode {
                RepoMode::CreateDomain => Ok(Err("role-version-blank-error".into())),
                RepoMode::CreateUnknownDomain => Ok(Err("future-error".into())),
                RepoMode::CreateInfra => Err(RepositoryError("mock repository failure".into())),
                _ => Ok(Ok(RecordId {
                    table: "service".into(),
                    key: "uid".into(),
                })),
            }
        }
    }
    #[derive(Clone, Copy)]
    enum ProviderMode {
        Valid,
        Unavailable,
        DeleteFails,
    }
    struct MockProvider {
        mode: ProviderMode,
        creates: RefCell<usize>,
        deletes: RefCell<usize>,
    }
    impl AccountProvider for MockProvider {
        async fn create_account(&self, _: &str) -> Result<ProvisionedAccount, ProviderError> {
            *self.creates.borrow_mut() += 1;
            if matches!(self.mode, ProviderMode::Unavailable) {
                return Err(ProviderError::Unavailable);
            }
            Ok(ProvisionedAccount {
                username: "service-test".into(),
                token: "token".into(),
                user_uid: "uid".into(),
                user_pk: 7,
            })
        }
        async fn delete_account(&self, _: i64) -> Result<(), ProviderError> {
            *self.deletes.borrow_mut() += 1;
            if matches!(self.mode, ProviderMode::DeleteFails) {
                Err(ProviderError::Internal)
            } else {
                Ok(())
            }
        }
    }
    struct MockNames {
        calls: RefCell<usize>,
    }
    impl NameSource for MockNames {
        fn generate(&self) -> Result<crate::names::GeneratedNames, NamingError> {
            *self.calls.borrow_mut() += 1;
            Ok(crate::names::generate_names([1; 16]))
        }
    }
    fn request() -> IssueServiceIdentityRequest {
        IssueServiceIdentityRequest {
            roles: vec![ServiceRole::Engine(Box::new(ServiceRole_Engine {
                version: "1".into(),
                _unrecognized: None,
            }))],
            _unrecognized: None,
        }
    }
    fn setup(
        repo_mode: RepoMode,
        provider_mode: ProviderMode,
    ) -> (MockRepo, MockProvider, MockNames) {
        (
            MockRepo {
                mode: repo_mode,
                validation_calls: RefCell::new(0),
                create_calls: RefCell::new(0),
            },
            MockProvider {
                mode: provider_mode,
                creates: RefCell::new(0),
                deletes: RefCell::new(0),
            },
            MockNames {
                calls: RefCell::new(0),
            },
        )
    }
    fn run(
        repo: &MockRepo,
        provider: &MockProvider,
        names: &MockNames,
        req: IssueServiceIdentityRequest,
    ) -> Result<IssueServiceIdentityResponse, otel_wasi::Error> {
        use std::future::Future;
        use std::pin::pin;
        use std::task::{Context, Poll, Waker};
        let span = tracing::info_span!("service_identity_test");
        let _main_guard = otel_wasi::enter_main_span(span.clone());
        let _span_guard = span.enter();
        let mut future = pin!(issue_identity(provider, repo, names, req));
        let waker = Waker::noop();
        let mut context = Context::from_waker(waker);
        match Future::poll(future.as_mut(), &mut context) {
            Poll::Ready(value) => value,
            Poll::Pending => panic!("mock workflow unexpectedly pending"),
        }
    }

    #[test]
    fn unknown_role_has_no_side_effects() {
        let (repo, provider, names) = setup(RepoMode::Valid, ProviderMode::Valid);
        assert!(matches!(
            run(
                &repo,
                &provider,
                &names,
                IssueServiceIdentityRequest {
                    roles: vec![ServiceRole::Unknown(None)],
                    _unrecognized: None
                }
            )
            .unwrap(),
            IssueServiceIdentityResponse::UnknownRoleError(_)
        ));
        assert_eq!(
            (
                *repo.validation_calls.borrow(),
                *provider.creates.borrow(),
                *names.calls.borrow()
            ),
            (0, 0, 0)
        );
    }
    #[test]
    fn validation_domain_maps_without_provider_or_create() {
        let (repo, provider, names) = setup(RepoMode::ValidationDomain, ProviderMode::Valid);
        assert!(matches!(
            run(&repo, &provider, &names, request()).unwrap(),
            IssueServiceIdentityResponse::RolesRequiredError(_)
        ));
        assert_eq!(
            (
                *provider.creates.borrow(),
                *repo.create_calls.borrow(),
                *names.calls.borrow()
            ),
            (0, 0, 0)
        );
    }
    #[test]
    fn unknown_validation_slug_preserves_domain_mapping_error() {
        let (repo, provider, names) = setup(RepoMode::ValidationUnknownDomain, ProviderMode::Valid);
        let error = run(&repo, &provider, &names, request()).unwrap_err();
        assert!(format!("{error:?}").contains("skir-domain-error-unknown"));
        assert_eq!(*provider.creates.borrow(), 0);
    }

    #[test]
    fn validation_infrastructure_stops_workflow() {
        let (repo, provider, names) = setup(RepoMode::ValidationInfra, ProviderMode::Valid);
        assert!(matches!(
            run(&repo, &provider, &names, request()).unwrap(),
            IssueServiceIdentityResponse::InternalError(_)
        ));
        assert_eq!((*provider.creates.borrow(), *names.calls.borrow()), (0, 0));
    }
    #[test]
    fn success_runs_in_order_and_returns_credentials() {
        let (repo, provider, names) = setup(RepoMode::Valid, ProviderMode::Valid);
        assert!(matches!(
            run(&repo, &provider, &names, request()).unwrap(),
            IssueServiceIdentityResponse::Success(_)
        ));
        assert_eq!(
            (
                *repo.validation_calls.borrow(),
                *names.calls.borrow(),
                *provider.creates.borrow(),
                *repo.create_calls.borrow()
            ),
            (1, 1, 1, 1)
        );
    }
    #[test]
    fn provider_unavailable_does_not_persist() {
        let (repo, provider, names) = setup(RepoMode::Valid, ProviderMode::Unavailable);
        assert!(matches!(
            run(&repo, &provider, &names, request()).unwrap(),
            IssueServiceIdentityResponse::IdentityProviderUnavailableError(_)
        ));
        assert_eq!(*repo.create_calls.borrow(), 0);
    }
    #[test]
    fn create_domain_compensates_and_preserves_slug() {
        let (repo, provider, names) = setup(RepoMode::CreateDomain, ProviderMode::Valid);
        assert!(matches!(
            run(&repo, &provider, &names, request()).unwrap(),
            IssueServiceIdentityResponse::RoleVersionBlankError(_)
        ));
        assert_eq!(*provider.deletes.borrow(), 1);
    }
    #[test]
    fn unknown_create_slug_compensates_before_preserving_mapping_error() {
        let (repo, provider, names) = setup(RepoMode::CreateUnknownDomain, ProviderMode::Valid);
        let error = run(&repo, &provider, &names, request()).unwrap_err();
        assert!(format!("{error:?}").contains("skir-domain-error-unknown"));
        assert_eq!(*provider.deletes.borrow(), 1);
    }

    #[test]
    fn create_infrastructure_compensates_and_returns_internal() {
        let (repo, provider, names) = setup(RepoMode::CreateInfra, ProviderMode::Valid);
        assert!(matches!(
            run(&repo, &provider, &names, request()).unwrap(),
            IssueServiceIdentityResponse::InternalError(_)
        ));
        assert_eq!(*provider.deletes.borrow(), 1);
    }
    #[test]
    fn compensation_failure_preserves_original() {
        let (repo, provider, names) = setup(RepoMode::CreateDomain, ProviderMode::DeleteFails);
        assert!(matches!(
            run(&repo, &provider, &names, request()).unwrap(),
            IssueServiceIdentityResponse::RoleVersionBlankError(_)
        ));
        assert_eq!(*provider.deletes.borrow(), 1);
    }
}
