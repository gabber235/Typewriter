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
    /// Returns the stable telemetry label for this outcome.
    pub fn as_str(self) -> &'static str {
        match self {
            SkirResponseOutcome::Success => "success",
            SkirResponseOutcome::DomainError => "domain_error",
            SkirResponseOutcome::InternalError => "internal_error",
        }
    }
}

/// Contract shared by every typed SKIR response enum.
///
/// The transport generator implements it for every Skir method response from the variant
/// names: `internal_error` and the unknown variant are internal errors, a name ending in
/// `_error` is a domain error, and any other variant is a success. Response handlers use
/// this trait to serialize replies, classify telemetry, expose a stable variant slug, and
/// construct the fallback response used when a handler fails before producing a domain
/// result.
pub trait SkirResponse: Sized {
    /// Serialize the response using its generated SKIR serializer.
    ///
    /// The bytes are the wire payload for messaging replies and do not include a
    /// transport envelope.
    fn to_skir_bytes(&self) -> Vec<u8>;

    /// Classify this variant for handler control flow and telemetry.
    fn outcome(&self) -> SkirResponseOutcome;

    /// Return the stable slug used in telemetry and internal error values.
    fn variant_slug(&self) -> &'static str;

    /// Return the caller facing message for this variant.
    ///
    /// The message is the variant's Skir doc comment, or its slug when the variant is
    /// undocumented. Payloads never contribute, so the message carries no request data.
    fn variant_message(&self) -> String;

    /// Construct the generic internal error sent when a handler returns an error.
    ///
    /// The original error remains the handler result, while this value is sent to the
    /// caller as the typed response.
    fn internal_error() -> Self;

    /// Construct a domain error response with a default payload for a known slug.
    ///
    /// Every domain error variant is known. Variants whose payload carries call site data
    /// are filled by the overrides of `skir_domain_result!`, which take precedence.
    fn domain_error_from_slug(_slug: &str) -> Option<Self> {
        None
    }
}

/// Result of converting a database operation into the response flow used by handlers.
///
/// `Value` continues the success path. `Response` is an expected domain outcome and
/// must be returned to the caller without being treated as infrastructure failure.
#[derive(Debug)]
pub enum SkirDomainResult<T, R> {
    /// The transaction succeeded and produced a value.
    Value(T),
    /// The transaction produced a known domain-error response.
    Response(R),
}

/// Converts database outcomes carrying domain slugs into typed SKIR responses.
///
/// Unknown slugs are infrastructure errors because the response enum does not define
/// a safe wire representation for them.
pub trait SkirDomainResultExt<T>: Sized {
    /// Convert a result into either its value or the response enum's default domain variant.
    fn into_skir_domain_result<R>(self) -> Result<SkirDomainResult<T, R>, otel_wasi::Error>
    where
        R: SkirResponse;

    /// Convert a result while allowing the caller to construct payloadful domain variants
    /// for matching slugs before the enum's default constructor is tried.
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
            Err(slug) => domain_response(slug.as_str(), override_constructor),
        }
    }
}

impl<T> SkirDomainResultExt<T> for surrealdb_component_sdk::TransactionOutcome<T> {
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
            surrealdb_component_sdk::TransactionOutcome::Committed(value) => {
                Ok(SkirDomainResult::Value(value))
            }
            surrealdb_component_sdk::TransactionOutcome::Rejected(error) => {
                domain_response(database_domain_slug(error.message()), override_constructor)
            }
        }
    }
}

fn domain_response<T, R, F>(
    slug: &str,
    override_constructor: F,
) -> Result<SkirDomainResult<T, R>, otel_wasi::Error>
where
    R: SkirResponse,
    F: FnOnce(&str) -> Option<R>,
{
    if let Some(response) = override_constructor(slug).or_else(|| R::domain_error_from_slug(slug)) {
        return Ok(SkirDomainResult::Response(response));
    }

    Err(otel_wasi::Error::new(
        "skir-domain-error-unknown",
        format!("unknown SKIR domain error slug `{slug}`"),
    ))
}

/// Remove the prefix SurrealDB adds when a structured `THROW` crosses a query block.
///
/// Only this known wrapper is removed. Other messages remain unchanged so unknown
/// database failures are not mistaken for domain slugs.
fn database_domain_slug(message: &str) -> &str {
    message.trim_start_matches("An error occurred: ")
}

#[cfg(test)]
mod tests {
    use super::database_domain_slug;

    #[test]
    fn nested_database_rejections_keep_the_original_domain_slug() {
        for message in [
            "founder-cannot-be-removed-error",
            "An error occurred: founder-cannot-be-removed-error",
            "An error occurred: An error occurred: founder-cannot-be-removed-error",
        ] {
            assert_eq!(
                database_domain_slug(message),
                "founder-cannot-be-removed-error"
            );
        }
        assert_eq!(
            database_domain_slug("unknown database failure"),
            "unknown database failure"
        );
    }
}
