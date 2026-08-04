use serde::{Deserialize, Serialize};
use url::Url;
use wit_bindgen::spawn_local;

use crate::bindings;
use crate::bindings::wasi::http::types::{
    Fields, Method, Request, RequestOptions, Response, Scheme,
};
use crate::identity::{AccountProvider, ProviderError, ProvisionedAccount};

const MAX_RESPONSE_BODY: usize = 64 * 1024;
const MAX_ERROR_FIELDS: usize = 16;

pub struct AuthentikClient;

struct Config {
    base_url: Url,
    token: String,
}

#[derive(Serialize)]
struct CreateRequest<'a> {
    name: &'a str,
    create_group: bool,
    expiring: bool,
}

#[derive(Deserialize, Debug, PartialEq)]
struct CreateResponse {
    username: String,
    token: String,
    user_uid: String,
    user_pk: i64,
}

impl Config {
    fn load() -> Result<Self, ProviderError> {
        let base_url =
            Url::parse(&std::env::var("AUTHENTIK_URL").map_err(|_| ProviderError::Internal)?)
                .map_err(|_| ProviderError::Internal)?;

        if !matches!(base_url.scheme(), "http" | "https") || base_url.host_str().is_none() {
            return Err(ProviderError::Internal);
        }

        let token = std::env::var("AUTHENTIK_TOKEN").map_err(|_| ProviderError::Internal)?;
        if token.is_empty() {
            return Err(ProviderError::Internal);
        }

        Ok(Self { base_url, token })
    }
}

impl AccountProvider for AuthentikClient {
    #[tracing::instrument(skip(self, username))]
    async fn create_account(&self, username: &str) -> Result<ProvisionedAccount, ProviderError> {
        otel_wasi::attribute!("provider.operation" = "create");
        let config = Config::load()?;
        let body = create_request_json(username)?;
        let response = send(
            &config,
            Method::Post,
            "/api/v3/core/users/service_account/",
            Some(body),
        )
        .await?;
        let status = response.get_status_code();
        otel_wasi::attribute!("provider.response.status_code" = status as i64);
        otel_wasi::main_attribute!("identity.provider.create.status_code" = status as i64);
        let body = complete_response(response, classify_create_status(status)).await?;
        let result = parse_create_response(&body)?;
        Ok(ProvisionedAccount {
            username: result.username,
            token: result.token,
            user_uid: result.user_uid,
            user_pk: result.user_pk,
        })
    }

    #[tracing::instrument(skip_all)]
    async fn delete_account(&self, user_pk: i64) -> Result<(), ProviderError> {
        otel_wasi::attribute!("provider.operation" = "delete");
        let config = Config::load()?;
        let response = send(
            &config,
            Method::Delete,
            &format!("/api/v3/core/users/{user_pk}/"),
            None,
        )
        .await?;

        let status = response.get_status_code();
        otel_wasi::attribute!("provider.response.status_code" = status as i64);
        otel_wasi::main_attribute!("identity.provider.delete.status_code" = status as i64);

        complete_response(response, classify_delete_status(status)).await?;
        Ok(())
    }
}

fn create_request_json(name: &str) -> Result<Vec<u8>, ProviderError> {
    serde_json::to_vec(&CreateRequest {
        name,
        create_group: false,
        expiring: false,
    })
    .map_err(|_| ProviderError::Internal)
}

fn classify_create_status(status: u16) -> Result<(), ProviderError> {
    match status {
        200 => Ok(()),
        500..=599 => Err(ProviderError::Unavailable),
        _ => Err(ProviderError::Internal),
    }
}

fn classify_delete_status(status: u16) -> Result<(), ProviderError> {
    match status {
        204 => Ok(()),
        500..=599 => Err(ProviderError::Unavailable),
        _ => Err(ProviderError::Internal),
    }
}

fn parse_create_response(body: &[u8]) -> Result<CreateResponse, ProviderError> {
    serde_json::from_slice(body).map_err(|_| ProviderError::Internal)
}

#[tracing::instrument(skip_all)]
async fn send(
    config: &Config,
    method: Method,
    path: &str,
    body: Option<Vec<u8>>,
) -> Result<Response, ProviderError> {
    otel_wasi::attribute!(
        "provider.operation" = "send",
        "http.request.method" = method_name(&method),
        "http.route" = path.to_string(),
        "http.request.body.size" = body.as_ref().map_or(0, Vec::len) as i64,
    );

    let headers = Fields::new();
    for (name, value) in wasmcloud_utils::http::propagation_headers() {
        headers
            .set(&name, &[value])
            .map_err(|_| ProviderError::Internal)?;
    }
    headers
        .set(
            "authorization",
            &[format!("Bearer {}", config.token).into_bytes()],
        )
        .map_err(|_| ProviderError::Internal)?;
    headers
        .set("content-type", &[b"application/json".to_vec()])
        .map_err(|_| ProviderError::Internal)?;

    if let Some(length) = content_length_header(body.as_deref()) {
        headers
            .set("content-length", &[length])
            .map_err(|_| ProviderError::Internal)?;
    }

    let (stream, body_result) = if let Some(bytes) = body {
        let (mut tx, rx) = bindings::wit_stream::new();
        let (tx_done, rx_done) = bindings::wit_future::new(|| todo!());
        spawn_local(async move {
            tx.write_all(bytes).await;
            drop(tx);
            let _ = tx_done.write(Ok(None)).await;
        });
        (Some(rx), rx_done)
    } else {
        let (tx_done, rx_done) = bindings::wit_future::new(|| todo!());
        spawn_local(async move {
            let _ = tx_done.write(Ok(None)).await;
        });
        (None, rx_done)
    };

    let options = RequestOptions::new();
    options
        .set_connect_timeout(Some(5_000_000_000))
        .map_err(|_| ProviderError::Internal)?;
    options
        .set_first_byte_timeout(Some(10_000_000_000))
        .map_err(|_| ProviderError::Internal)?;
    options
        .set_between_bytes_timeout(Some(5_000_000_000))
        .map_err(|_| ProviderError::Internal)?;

    let (request, transmission) = Request::new(headers, stream, body_result, Some(options));
    request
        .set_method(&method)
        .map_err(|_| ProviderError::Internal)?;
    request
        .set_path_with_query(Some(path))
        .map_err(|_| ProviderError::Internal)?;

    let scheme = if config.base_url.scheme() == "https" {
        Scheme::Https
    } else {
        Scheme::Http
    };

    request
        .set_scheme(Some(&scheme))
        .map_err(|_| ProviderError::Internal)?;
    request
        .set_authority(Some(config.base_url.authority()))
        .map_err(|_| ProviderError::Internal)?;

    let response = bindings::wasi::http::client::send(request)
        .await
        .map_err(|_| ProviderError::Unavailable)?;

    transmission.await.map_err(|_| ProviderError::Unavailable)?;

    Ok(response)
}

fn method_name(method: &Method) -> String {
    match method {
        Method::Get => "GET".to_string(),
        Method::Head => "HEAD".to_string(),
        Method::Post => "POST".to_string(),
        Method::Put => "PUT".to_string(),
        Method::Delete => "DELETE".to_string(),
        Method::Connect => "CONNECT".to_string(),
        Method::Options => "OPTIONS".to_string(),
        Method::Trace => "TRACE".to_string(),
        Method::Patch => "PATCH".to_string(),
        Method::Other(value) => value.clone(),
    }
}

fn content_length_header(body: Option<&[u8]>) -> Option<Vec<u8>> {
    body.map(|bytes| bytes.len().to_string().into_bytes())
}

fn push_bounded(body: &mut Vec<u8>, byte: u8, limit: usize) -> Result<(), ()> {
    if body.len() >= limit {
        return Err(());
    }
    body.push(byte);
    Ok(())
}

#[tracing::instrument(skip_all)]
async fn response_body(response: Response) -> Result<Vec<u8>, ProviderError> {
    otel_wasi::attribute!("provider.operation" = "read_response_body");

    let (done_tx, done_rx) = bindings::wit_future::new(|| todo!());
    let (mut stream, trailers) = Response::consume_body(response, done_rx);
    let mut body = Vec::new();

    while let Some(byte) = stream.next().await {
        if push_bounded(&mut body, byte, MAX_RESPONSE_BODY).is_err() {
            drop(stream);
            done_tx
                .write(Err(
                    crate::bindings::wasi::http::types::ErrorCode::HttpResponseBodySize(Some(
                        MAX_RESPONSE_BODY as u64,
                    )),
                ))
                .await
                .map_err(|_| ProviderError::Unavailable)?;
            drop(trailers);
            return Err(ProviderError::Internal);
        }
    }

    drop(stream);
    done_tx
        .write(Ok(()))
        .await
        .map_err(|_| ProviderError::Unavailable)?;

    trailers.await.map_err(|_| ProviderError::Unavailable)?;
    otel_wasi::attribute!("http.response.body.size" = body.len() as i64);

    Ok(body)
}

async fn complete_response(
    response: Response,
    classification: Result<(), ProviderError>,
) -> Result<Vec<u8>, ProviderError> {
    let body = response_body(response).await;
    if classification.is_err() {
        if let Ok(response_body) = body.as_deref() {
            record_rejection(response_body);
        }
    }
    classification?;
    body
}

fn record_rejection(body: &[u8]) {
    let (valid_json, fields) = rejection_metadata(body);
    otel_wasi::attribute!("provider.response.error_body.valid_json" = valid_json);
    if let Some(fields) = fields {
        otel_wasi::attribute!("provider.response.error_fields" = fields);
    }
}

fn rejection_metadata(body: &[u8]) -> (bool, Option<String>) {
    let Ok(value) = serde_json::from_slice::<serde_json::Value>(body) else {
        return (false, None);
    };
    let serde_json::Value::Object(object) = value else {
        return (true, None);
    };
    let mut fields = object
        .keys()
        .filter(|field| field.len() <= 64)
        .cloned()
        .collect::<Vec<_>>();
    fields.sort_unstable();
    fields.truncate(MAX_ERROR_FIELDS);
    (true, (!fields.is_empty()).then(|| fields.join(",")))
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn create_json_matches_authentik_contract() {
        let body = create_request_json("service-abc").unwrap();
        let value: serde_json::Value = serde_json::from_slice(&body).unwrap();
        assert_eq!(
            value,
            serde_json::json!({"name":"service-abc","create_group":false,"expiring":false})
        );
        assert_eq!(
            content_length_header(Some(&body)),
            Some(body.len().to_string().into_bytes())
        );
    }

    #[test]
    fn parses_success_response() {
        let parsed = parse_create_response(
            br#"{"username":"service-a","token":"secret","user_uid":"uid","user_pk":42}"#,
        )
        .unwrap();
        assert_eq!(parsed.username, "service-a");
        assert_eq!(parsed.user_uid, "uid");
        assert_eq!(parsed.user_pk, 42);
    }

    #[test]
    fn bounded_body_rejects_first_byte_past_limit() {
        let mut body = Vec::new();
        assert!(push_bounded(&mut body, 1, 1).is_ok());
        assert!(push_bounded(&mut body, 2, 1).is_err());
        assert_eq!(body, vec![1]);
    }

    #[test]
    fn rejection_metadata_records_only_sorted_field_names() {
        let body = br#"{"name":["required"],"non_field_errors":["invalid"]}"#;
        assert_eq!(
            rejection_metadata(body),
            (true, Some("name,non_field_errors".to_string()))
        );
        assert_eq!(rejection_metadata(b"not json"), (false, None));
    }

    #[test]
    fn classifies_every_status_class() {
        assert!(classify_create_status(200).is_ok());
        for status in [100, 199, 201, 299, 300, 399, 400, 499] {
            assert!(matches!(
                classify_create_status(status),
                Err(ProviderError::Internal)
            ));
        }
        for status in 500..=599 {
            assert!(matches!(
                classify_create_status(status),
                Err(ProviderError::Unavailable)
            ));
        }
    }

    #[test]
    fn classifies_delete_statuses() {
        assert!(classify_delete_status(204).is_ok());
        for status in [100, 199, 200, 203, 205, 299, 300, 399, 400, 499] {
            assert!(matches!(
                classify_delete_status(status),
                Err(ProviderError::Internal)
            ));
        }
        for status in 500..=599 {
            assert!(matches!(
                classify_delete_status(status),
                Err(ProviderError::Unavailable)
            ));
        }
    }
}
