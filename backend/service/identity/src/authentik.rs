use std::io::{Read as _, Write as _};
use wasmcloud_component::{
    debug, error, info, trace,
    wasi::http::{
        outgoing_handler::{handle, OutgoingRequest, RequestOptions},
        types::{Fields, Method, Scheme},
    },
};

#[derive(Debug, serde::Serialize)]
struct CreateServiceAccountRequest {
    name: String,
    create_group: bool,
    expiring: bool,
}

#[derive(Debug, serde::Deserialize)]
pub struct ServiceAccountResponse {
    pub username: String,
    pub token: String,
    pub user_uid: String,
    #[allow(dead_code)]
    pub user_pk: i64,
}

#[derive(Debug)]
pub enum AuthentikError {
    EnvVarMissing(String),
    HttpError(String),
    ParseError(String),
    ApiError { status: u16, message: String },
}

impl std::fmt::Display for AuthentikError {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        match self {
            AuthentikError::EnvVarMissing(var) => {
                write!(f, "Missing environment variable: {}", var)
            }
            AuthentikError::HttpError(msg) => write!(f, "HTTP error: {}", msg),
            AuthentikError::ParseError(msg) => write!(f, "Parse error: {}", msg),
            AuthentikError::ApiError { status, message } => {
                write!(f, "API error (status {}): {}", status, message)
            }
        }
    }
}

impl std::error::Error for AuthentikError {}

pub fn create_service_account() -> Result<ServiceAccountResponse, AuthentikError> {
    debug!("Creating service account");

    let api_url = std::env::var("AUTHENTIK_URL")
        .map_err(|_| AuthentikError::EnvVarMissing("AUTHENTIK_URL not set".to_string()))?;

    let api_token = std::env::var("AUTHENTIK_TOKEN")
        .map_err(|_| AuthentikError::EnvVarMissing("AUTHENTIK_TOKEN not set".to_string()))?;

    debug!("Using Authentik API URL: {}", api_url);

    let url = parse_url(&api_url)?;

    let unique_id = uuid::Uuid::new_v4().to_string();
    let service_name = format!("service-{}", &unique_id);

    let request_body = CreateServiceAccountRequest {
        name: service_name,
        create_group: false,
        expiring: false,
    };

    let body_json = serde_json::to_string(&request_body)
        .map_err(|e| AuthentikError::ParseError(format!("Failed to serialize request: {}", e)))?;

    let body_bytes = body_json.as_bytes();
    let content_length = body_bytes.len();

    debug!("Request body: {}", body_json);
    trace!("Request body length: {} bytes", content_length);

    let headers = Fields::new();
    headers
        .set(&"content-type".to_string(), &[b"application/json".to_vec()])
        .map_err(|_| AuthentikError::HttpError("Failed to set content-type header".to_string()))?;

    headers
        .set(
            &"content-length".to_string(),
            &[content_length.to_string().into_bytes()],
        )
        .map_err(|_| {
            AuthentikError::HttpError("Failed to set content-length header".to_string())
        })?;

    let auth_header = format!("Bearer {}", api_token);
    headers
        .set(
            &"authorization".to_string(),
            &[auth_header.as_bytes().to_vec()],
        )
        .map_err(|_| AuthentikError::HttpError("Failed to set authorization header".to_string()))?;

    trace!(
        "Request headers: content-type=application/json, content-length={}, authorization=Bearer ***",
        content_length
    );

    let request = OutgoingRequest::new(headers);

    request
        .set_method(&Method::Post)
        .map_err(|_| AuthentikError::HttpError("Failed to set POST method".to_string()))?;

    request
        .set_scheme(Some(&url.scheme))
        .map_err(|_| AuthentikError::HttpError("Failed to set scheme".to_string()))?;

    request
        .set_authority(Some(&url.authority))
        .map_err(|_| AuthentikError::HttpError("Failed to set authority".to_string()))?;

    let path = "/api/v3/core/users/service_account/";
    request
        .set_path_with_query(Some(path))
        .map_err(|_| AuthentikError::HttpError("Failed to set path".to_string()))?;

    trace!(
        "Request: POST {}://{}{} (body: {} bytes)",
        match url.scheme {
            Scheme::Https => "https",
            Scheme::Http => "http",
            _ => "unknown",
        },
        url.authority,
        path,
        content_length
    );

    let request_body_resource = request
        .body()
        .map_err(|_| AuthentikError::HttpError("Failed to get request body".to_string()))?;

    let mut output_stream = request_body_resource
        .write()
        .map_err(|_| AuthentikError::HttpError("Failed to get output stream".to_string()))?;

    output_stream
        .write_all(body_bytes)
        .map_err(|e| AuthentikError::HttpError(format!("Failed to write request body: {}", e)))?;

    trace!("Wrote {} bytes to request body", content_length);

    output_stream
        .flush()
        .map_err(|e| AuthentikError::HttpError(format!("Failed to flush output stream: {}", e)))?;

    trace!("Flushed output stream");

    drop(output_stream);
    trace!("Dropped output stream, finishing request body");

    wasmcloud_component::wasi::http::types::OutgoingBody::finish(request_body_resource, None)
        .map_err(|_| AuthentikError::HttpError("Failed to finish request body".to_string()))?;

    trace!("Request body finished, sending request");

    let options = RequestOptions::new();
    let future_response = handle(request, Some(options))
        .map_err(|e| AuthentikError::HttpError(format!("Failed to send request: {:?}", e)))?;

    trace!("Request sent, waiting for response");

    // TODO: with wasi preview 3 we should be able to make this a proper async call
    future_response.subscribe().block();

    let incoming_response = future_response
        .get()
        .ok_or_else(|| AuthentikError::HttpError("Failed to get response future".to_string()))?
        .map_err(|e| AuthentikError::HttpError(format!("Request failed: {:?}", e)))?
        .map_err(|e| AuthentikError::HttpError(format!("Request error: {:?}", e)))?;

    let status = incoming_response.status();
    debug!("Received response with status: {}", status);

    let body_stream = incoming_response
        .consume()
        .map_err(|_| AuthentikError::HttpError("Failed to consume response body".to_string()))?;

    let mut input_stream = body_stream
        .stream()
        .map_err(|_| AuthentikError::HttpError("Failed to get input stream".to_string()))?;

    let mut response_text = String::new();
    input_stream
        .read_to_string(&mut response_text)
        .map_err(|e| AuthentikError::HttpError(format!("Failed to read response body: {}", e)))?;

    debug!("Response body: '{}'", response_text);

    if status < 200 || status >= 300 {
        error!(
            "Authentik API returned status code {}: '{}'",
            status, response_text
        );
        return Err(AuthentikError::ApiError {
            status,
            message: response_text,
        });
    }

    let response: ServiceAccountResponse = serde_json::from_str(&response_text)
        .map_err(|e| AuthentikError::ParseError(format!("Failed to parse response: {}", e)))?;

    info!(
        "Successfully created service account: {}",
        response.username
    );

    Ok(response)
}

struct ParsedUrl {
    scheme: Scheme,
    authority: String,
}

fn parse_url(url: &str) -> Result<ParsedUrl, AuthentikError> {
    let url = url.trim_end_matches('/');

    let (scheme_str, rest) = if let Some(rest) = url.strip_prefix("https://") {
        ("https", rest)
    } else if let Some(rest) = url.strip_prefix("http://") {
        ("http", rest)
    } else {
        return Err(AuthentikError::ParseError(
            "URL must start with http:// or https://".to_string(),
        ));
    };

    let scheme = if scheme_str == "https" {
        Scheme::Https
    } else {
        Scheme::Http
    };

    let authority = if let Some(idx) = rest.find('/') {
        let (auth, _) = rest.split_at(idx);
        auth.to_string()
    } else {
        rest.to_string()
    };

    Ok(ParsedUrl { scheme, authority })
}
