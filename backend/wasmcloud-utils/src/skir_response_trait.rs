/// Runtime classification for a Skir response variant.
#[derive(Clone, Copy, Debug, Eq, PartialEq)]
pub enum SkirResponseOutcome {
    /// The operation completed successfully.
    Success,
    /// The operation produced an expected domain outcome.
    DomainError,
    /// The operation produced an unexpected/internal failure.
    InternalError,
}

impl SkirResponseOutcome {
    pub fn as_str(self) -> &'static str {
        match self {
            SkirResponseOutcome::Success => "success",
            SkirResponseOutcome::DomainError => "domain_error",
            SkirResponseOutcome::InternalError => "internal_error",
        }
    }
}

/// Trait implemented by skir response enums via the `skir_response!` proc macro.
///
/// Provides serialization, outcome classification, slug/message generation, and
/// internal error construction for typed skir response enums.
pub trait SkirResponse: Sized {
    /// Serialize this response to skir bytes.
    fn to_skir_bytes(&self) -> Vec<u8>;

    /// Returns the runtime outcome classification for this variant.
    fn outcome(&self) -> SkirResponseOutcome;

    /// Returns a kebab-case slug for this variant (e.g. `"invalid-credentials"`).
    fn variant_slug(&self) -> &'static str;

    /// Returns a human-readable message for this variant.
    fn variant_message(&self) -> String;

    /// Construct the generic internal error variant for this response enum.
    fn internal_error() -> Self;

    /// Construct a default domain-error response for a known slug.
    ///
    /// Response variants that need payload data should return `None` here and be
    /// constructed by call-site overrides in `skir_domain_result!`.
    fn domain_error_from_slug(_slug: &str) -> Option<Self> {
        None
    }
}

/// Result of converting a transaction-domain result into a typed SKIR response flow.
#[derive(Debug)]
pub enum SkirDomainResult<T, R> {
    /// The transaction succeeded and produced a value.
    Value(T),
    /// The transaction produced a known domain-error response.
    Response(R),
}

/// Extension helpers for SurrealDB transaction results that carry domain slugs.
pub trait SkirDomainResultExt<T>: Sized {
    /// Convert an inner transaction result into either a value or a typed domain response.
    fn into_skir_domain_result<R>(self) -> Result<SkirDomainResult<T, R>, otel_wasi::Error>
    where
        R: SkirResponse;

    /// Convert an inner transaction result, allowing the call site to construct
    /// payloadful domain-error responses for matching slugs.
    fn into_skir_domain_result_with<R, F>(
        self,
        override_constructor: F,
    ) -> Result<SkirDomainResult<T, R>, otel_wasi::Error>
    where
        R: SkirResponse,
        F: FnOnce(&str) -> Option<R>;
}

impl<T> SkirDomainResultExt<T> for Result<T, String> {
    fn into_skir_domain_result<R>(self) -> Result<SkirDomainResult<T, R>, otel_wasi::Error>
    where
        R: SkirResponse,
    {
        self.into_skir_domain_result_with(|_| None)
    }

    fn into_skir_domain_result_with<R, F>(
        self,
        override_constructor: F,
    ) -> Result<SkirDomainResult<T, R>, otel_wasi::Error>
    where
        R: SkirResponse,
        F: FnOnce(&str) -> Option<R>,
    {
        match self {
            Ok(value) => Ok(SkirDomainResult::Value(value)),
            Err(slug) => {
                if let Some(response) =
                    override_constructor(&slug).or_else(|| R::domain_error_from_slug(&slug))
                {
                    return Ok(SkirDomainResult::Response(response));
                }

                Err(otel_wasi::Error::new(
                    "skir-domain-error-unknown",
                    format!("unknown SKIR domain error slug `{slug}`"),
                ))
            }
        }
    }
}
