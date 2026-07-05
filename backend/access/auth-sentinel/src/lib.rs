mod bindings {
    wit_bindgen::generate!({
        world: "component",
        path: "wit",
        generate_all,
    });
}

use bindings::exports::wasi::http::handler::Guest as Handler;
use bindings::wasi::http::types::{ErrorCode, Fields, Method, Request, Response};
use wasmcloud_utils::skir::base::access::v1::sentinel::{
    GetSentinelCredentialsResponse, GetSentinelCredentialsResponse_ConfigurationError,
    GetSentinelCredentialsResponse_InvalidCredentials, GetSentinelCredentialsResponse_Success,
};
use wit_bindgen::spawn_local;

struct Component;

#[derive(Debug, Clone, Copy)]
enum SentinelError {
    MissingConfig,
    InvalidCredentials,
}

impl Handler for Component {
    async fn handle(request: Request) -> Result<Response, ErrorCode> {
        let method = request.get_method();
        let path_with_query = request.get_path_with_query().unwrap_or_default();
        let path = path_with_query.split('?').next().unwrap_or_default();

        otel_wasi::attribute!("http.route" = path.to_string());

        if path != "/auth/sentinel" {
            otel_wasi::attribute!("http.response.status_code" = 404i64);
            return plain_response(404, b"not found\n".to_vec());
        }

        if !matches!(method, Method::Get) {
            otel_wasi::attribute!("http.response.status_code" = 405i64);
            return plain_response(405, b"method not allowed\n".to_vec());
        }

        match sentinel_response_bytes() {
            Ok(bytes) => {
                otel_wasi::attribute!(
                    "auth.sentinel.outcome" = "success",
                    "http.response.status_code" = 200i64,
                );
                skir_response(200, bytes)
            }
            Err(SentinelError::MissingConfig) => {
                otel_wasi::attribute!(
                    "auth.sentinel.outcome" = "configuration_error",
                    "http.response.status_code" = 500i64,
                );
                skir_response(500, configuration_error_bytes())
            }
            Err(SentinelError::InvalidCredentials) => {
                otel_wasi::attribute!(
                    "auth.sentinel.outcome" = "invalid_credentials",
                    "http.response.status_code" = 500i64,
                );
                skir_response(500, invalid_credentials_bytes())
            }
        }
    }
}

fn sentinel_response_bytes() -> Result<Vec<u8>, SentinelError> {
    let creds = std::env::var("NATS_SENTINEL_CREDS").map_err(|_| SentinelError::MissingConfig)?;

    let jwt = extract_from_creds(
        &creds,
        "-----BEGIN NATS USER JWT-----",
        "------END NATS USER JWT------",
    )
    .ok_or(SentinelError::InvalidCredentials)?;

    let seed = extract_from_creds(
        &creds,
        "-----BEGIN USER NKEY SEED-----",
        "------END USER NKEY SEED------",
    )
    .ok_or(SentinelError::InvalidCredentials)?;

    let response =
        GetSentinelCredentialsResponse::Success(Box::new(GetSentinelCredentialsResponse_Success {
            jwt,
            seed,
            ..Default::default()
        }));

    Ok(GetSentinelCredentialsResponse::serializer().to_bytes(&response))
}

fn configuration_error_bytes() -> Vec<u8> {
    let response = GetSentinelCredentialsResponse::ConfigurationError(Box::new(
        GetSentinelCredentialsResponse_ConfigurationError::default(),
    ));
    GetSentinelCredentialsResponse::serializer().to_bytes(&response)
}

fn invalid_credentials_bytes() -> Vec<u8> {
    let response = GetSentinelCredentialsResponse::InvalidCredentials(Box::new(
        GetSentinelCredentialsResponse_InvalidCredentials::default(),
    ));
    GetSentinelCredentialsResponse::serializer().to_bytes(&response)
}

fn extract_from_creds(creds: &str, begin_marker: &str, end_marker: &str) -> Option<String> {
    let start = creds.find(begin_marker)? + begin_marker.len();
    let end = creds[start..].find(end_marker)? + start;
    Some(creds[start..end].trim().to_string())
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
        .set(
            &"content-type".to_string(),
            &[content_type.as_bytes().to_vec()],
        )
        .map_err(|_| internal_error("failed to set content-type header"))?;

    if let Some(typewriter_format) = typewriter_format {
        headers
            .set(
                &"x-typewriter-format".to_string(),
                &[typewriter_format.as_bytes().to_vec()],
            )
            .map_err(|_| internal_error("failed to set x-typewriter-format header"))?;
    }

    let (mut tx, rx) = bindings::wit_stream::new();
    let (trailers_tx, trailers_rx) = bindings::wit_future::new(|| todo!());

    spawn_local(async move {
        tx.write_all(body_bytes).await;
        drop(tx);
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

bindings::export!(Component with_types_in bindings);

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
}
