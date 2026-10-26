//! Unauthenticated bootstrap endpoint for the NATS authentication flow.
//!
//! Before NATS has an authenticated user identity, the service registrar cannot use the normal
//! authenticated request path. This crate exposes only the Skir
//! `GetSentinelCredentialsResponse` at `/auth/sentinel`, allowing the registrar to obtain the
//! configured sentinel credentials and connect with an identity that has no application policy.
//! NATS then uses its authorization callout to validate each real external JWT and obtain scoped
//! permissions from `auth-typewriter-permissions`.
//!
//! The HTTP boundary is intentionally narrow and unauthenticated. Its trust boundary is the
//! deployment secret, which is read at request time.
//! Missing configuration or credential markers, unknown paths, and wrong methods fail
//! explicitly. Enclosed JWT and seed contents are not validated here. The endpoint must not
//! become a general credential or policy service.

mod bindings {
    use crate::Component;

    wit_bindgen::generate!({
        world: "component",
        path: "wit",
        generate_all,
    });
    export!(Component);
}

use bindings::exports::wasi::http::handler::Guest as Handler;
use bindings::wasi::http::types::{ErrorCode, Fields, Method, Request, Response};
use otel_wasi::{ResultWithSlug, WithSlug};
use tracing::instrument;
use wasmcloud_utils::skir::base::access::v1::sentinel::{
    GetSentinelCredentialsResponse, GetSentinelCredentialsResponse_Success,
};
use wasmcloud_utils::skir_variant;
use wit_bindgen::spawn_local;

struct Component;

impl Handler for Component {
    #[otel_wasi::wasi_instrument(
        service = "auth-sentinel",
        export,
        attributes(
            "http.route" = "/auth/sentinel",
            "http.method" = "GET",
        )
    )]
    async fn handle(request: Request) -> Result<Response, otel_wasi::Error<ErrorCode>> {
        let method = request.get_method();
        let path_with_query = request.get_path_with_query().unwrap_or_default();
        let path = path_with_query.split('?').next().unwrap_or_default();

        otel_wasi::main_attribute!("http.route" = path.to_string());

        if path != "/auth/sentinel" {
            otel_wasi::main_attribute!(
                "http.response.status_code" = 404i64,
                "auth.sentinel.outcome" = "not_found",
            );
            return plain_response(404, b"not found\n".to_vec())
                .error_with_typed_slug("auth-sentinel-not-found");
        }

        if !matches!(method, Method::Get) {
            otel_wasi::main_attribute!(
                "http.response.status_code" = 405i64,
                "auth.sentinel.outcome" = "method_not_allowed",
            );
            return plain_response(405, b"method not allowed\n".to_vec())
                .error_with_typed_slug("auth-sentinel-method-not-allowed");
        }

        let bytes = sentinel_response_bytes()?;

        otel_wasi::main_attribute!(
            "auth.sentinel.outcome" = "success",
            "http.response.status_code" = 200i64,
        );
        skir_response(200, bytes).error_with_typed_slug("auth-sentinel-response-build-failed")
    }
}

#[instrument]
/// Build the bootstrap response from the deployment credential bundle.
///
/// This is the only point where the sentinel secret crosses into the Skir response. Both required
/// credential marker pairs must be present. Extraction failure is reported as an internal error,
/// never as a partial success. The returned contents still require validation by their consumers.
fn sentinel_response_bytes() -> Result<Vec<u8>, otel_wasi::Error<ErrorCode>> {
    let creds = std::env::var("NATS_SENTINEL_CREDS").map_err(|_| {
        ErrorCode::InternalError(Some("NATS_SENTINEL_CREDS not set".to_string()))
            .with_typed_slug("auth-sentinel-missing-config")
    })?;

    let jwt = extract_from_creds(
        &creds,
        "-----BEGIN NATS USER JWT-----",
        "------END NATS USER JWT------",
    )
    .ok_or_else(|| {
        ErrorCode::InternalError(Some("JWT missing from creds".to_string()))
            .with_typed_slug("auth-sentinel-invalid-credentials")
    })?;

    let seed = extract_from_creds(
        &creds,
        "-----BEGIN USER NKEY SEED-----",
        "------END USER NKEY SEED------",
    )
    .ok_or_else(|| {
        ErrorCode::InternalError(Some("seed missing from creds".to_string()))
            .with_typed_slug("auth-sentinel-invalid-credentials")
    })?;

    otel_wasi::attribute!(
        "auth.sentinel.creds.jwt.present" = true,
        "auth.sentinel.creds.seed.present" = true,
    );

    let response = skir_variant!(GetSentinelCredentialsResponse::Success { jwt, seed });

    Ok(GetSentinelCredentialsResponse::serializer().to_bytes(&response))
}

#[instrument(skip(creds))]
/// Extracts text between credential markers without validating the enclosed JWT or seed.
fn extract_from_creds(creds: &str, begin_marker: &str, end_marker: &str) -> Option<String> {
    let start = creds.find(begin_marker)? + begin_marker.len();
    let end = creds[start..].find(end_marker)? + start;
    let value = creds[start..end].trim().to_string();
    otel_wasi::attribute!(
        "auth.sentinel.creds.extract.marker" = begin_marker.to_string(),
        "auth.sentinel.creds.extract.value.length" = value.len() as i64,
    );
    Some(value)
}

fn plain_response(status: u16, body_bytes: Vec<u8>) -> Result<Response, ErrorCode> {
    response(status, body_bytes, "text/plain", None)
}

fn skir_response(status: u16, body_bytes: Vec<u8>) -> Result<Response, ErrorCode> {
    response(
        status,
        body_bytes,
        "application/octet-stream",
        Some("skir-binary"),
    )
}

fn response(
    status: u16,
    body_bytes: Vec<u8>,
    content_type: &str,
    typewriter_format: Option<&str>,
) -> Result<Response, ErrorCode> {
    let headers = Fields::new();
    headers
        .set("content-type", &[content_type.as_bytes().to_vec()])
        .map_err(|_| internal_error("failed to set content-type header"))?;

    if let Some(typewriter_format) = typewriter_format {
        headers
            .set(
                "x-typewriter-format",
                &[typewriter_format.as_bytes().to_vec()],
            )
            .map_err(|_| internal_error("failed to set x-typewriter-format header"))?;
    }

    let (mut tx, rx) = bindings::wit_stream::new();
    let (trailers_tx, trailers_rx) = bindings::wit_future::new(|| todo!());

    spawn_local(async move {
        tx.write_all(body_bytes).await;
        drop(tx);
        #[expect(
            clippy::let_underscore_must_use,
            reason = "the trailers have no content; a reader that already dropped the future needs nothing more"
        )]
        let _ = trailers_tx.write(Ok(None)).await;
    });

    let (response, _result) = Response::new(headers, Some(rx), trailers_rx);
    response
        .set_status_code(status)
        .map_err(|()| internal_error("failed to set response status"))?;

    Ok(response)
}

fn internal_error(error: impl std::fmt::Display) -> ErrorCode {
    ErrorCode::InternalError(Some(error.to_string()))
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn extracts_jwt_and_seed_from_creds() {
        let creds = "-----BEGIN NATS USER JWT-----\nabc.def.ghi\n------END NATS USER JWT------\n-----BEGIN USER NKEY SEED-----\nSU123\n------END USER NKEY SEED------";

        assert_eq!(
            extract_from_creds(
                creds,
                "-----BEGIN NATS USER JWT-----",
                "------END NATS USER JWT------"
            ),
            Some("abc.def.ghi".to_string())
        );
        assert_eq!(
            extract_from_creds(
                creds,
                "-----BEGIN USER NKEY SEED-----",
                "------END USER NKEY SEED------"
            ),
            Some("SU123".to_string())
        );
    }

    #[test]
    fn missing_marker_returns_none() {
        assert_eq!(extract_from_creds("", "begin", "end"), None);
    }

    #[test]
    fn extraction_tracing_omits_the_credential_bundle() {
        let jwt = "synthetic.jwt.credential";
        let seed = "SYNTHETIC_PRIVATE_SEED";
        let creds = format!(
            "-----BEGIN NATS USER JWT-----\n{jwt}\n------END NATS USER JWT------\n\
             -----BEGIN USER NKEY SEED-----\n{seed}\n------END USER NKEY SEED------"
        );
        let recorder = CapturedTracing::default();
        tracing::subscriber::with_default(recorder.clone(), || {
            assert_eq!(
                extract_from_creds(
                    &creds,
                    "-----BEGIN NATS USER JWT-----",
                    "------END NATS USER JWT------",
                )
                .as_deref(),
                Some(jwt)
            );
            assert_eq!(
                extract_from_creds(
                    &creds,
                    "-----BEGIN USER NKEY SEED-----",
                    "------END USER NKEY SEED------",
                )
                .as_deref(),
                Some(seed)
            );
        });
        let fields = recorder.fields.lock().unwrap();
        assert!(fields.iter().any(|(name, _)| name == "begin_marker"));
        assert!(!fields.iter().any(|(name, _)| name == "creds"));
        for (_, value) in fields.iter() {
            assert!(!value.contains(jwt));
            assert!(!value.contains(seed));
        }
    }

    #[derive(Clone, Default)]
    struct CapturedTracing {
        fields: std::sync::Arc<std::sync::Mutex<Vec<(String, String)>>>,
        next_id: std::sync::Arc<std::sync::atomic::AtomicU64>,
    }

    struct FieldVisitor<'a>(&'a mut Vec<(String, String)>);

    impl tracing::field::Visit for FieldVisitor<'_> {
        fn record_debug(&mut self, field: &tracing::field::Field, value: &dyn std::fmt::Debug) {
            self.0.push((field.name().to_owned(), format!("{value:?}")));
        }
    }

    impl tracing::Subscriber for CapturedTracing {
        fn enabled(&self, _: &tracing::Metadata<'_>) -> bool {
            true
        }

        fn new_span(&self, attrs: &tracing::span::Attributes<'_>) -> tracing::span::Id {
            attrs.record(&mut FieldVisitor(&mut self.fields.lock().unwrap()));
            let id = self
                .next_id
                .fetch_add(1, std::sync::atomic::Ordering::Relaxed)
                + 1;
            tracing::span::Id::from_u64(id)
        }

        fn record(&self, _: &tracing::span::Id, values: &tracing::span::Record<'_>) {
            values.record(&mut FieldVisitor(&mut self.fields.lock().unwrap()));
        }

        fn record_follows_from(&self, _: &tracing::span::Id, _: &tracing::span::Id) {}

        fn event(&self, event: &tracing::Event<'_>) {
            event.record(&mut FieldVisitor(&mut self.fields.lock().unwrap()));
        }

        fn enter(&self, _: &tracing::span::Id) {}
        fn exit(&self, _: &tracing::span::Id) {}
    }
}
