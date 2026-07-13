use crate::bindings;
use bindings::wasi::http::types::{ErrorCode, Fields, Method, Request, Response};
use otel_wasi::{ResultWithSlug, WasiError};
use wasmcloud_utils::{SkirResponse, skir::base::service::v1::identity::*};
use wit_bindgen::spawn_local;

const PATH: &str = "/service/identity/issue";
const MAX_BODY: usize = 64 * 1024;

pub async fn handle(request: Request) -> Result<Response, otel_wasi::Error<ErrorCode>> {
    let method = request.get_method();
    let path = request
        .get_path_with_query()
        .unwrap_or_default()
        .split('?')
        .next()
        .unwrap_or_default()
        .to_owned();
    otel_wasi::main_attribute!(
        "http.route" = path.clone(),
        "http.method" = method_name(&method),
    );

    if path != PATH {
        otel_wasi::main_attribute!(
            "http.response.status_code" = 404i64,
            "identity.outcome" = "not_found",
        );
        return response(404, b"not found\n".to_vec(), false, None)
            .error_with_typed_slug("service-identity-not-found");
    }

    if !matches!(method, Method::Post) {
        otel_wasi::main_attribute!(
            "http.response.status_code" = 405i64,
            "identity.outcome" = "method_not_allowed",
        );
        return response(
            405,
            b"method not allowed\n".to_vec(),
            false,
            Some(("allow", "POST")),
        )
        .error_with_typed_slug("service-identity-method-not-allowed");
    }

    let headers = request.get_headers();
    let valid_media = headers
        .get("content-type")
        .iter()
        .any(|v| v == b"application/octet-stream")
        && headers
            .get("x-typewriter-format")
            .iter()
            .any(|v| v == b"skir-binary");

    drop(headers);

    otel_wasi::main_attribute!("identity.request.media.valid" = valid_media);
    if !valid_media {
        otel_wasi::main_attribute!(
            "http.response.status_code" = 415i64,
            "identity.outcome" = "unsupported_media_type",
        );
        return skir_error(415);
    }

    let (done_tx, done_rx) = bindings::wit_future::new(|| todo!());
    let (mut body, trailers) = Request::consume_body(request, done_rx);
    let mut bytes = Vec::new();
    while let Some(byte) = body.next().await {
        bytes.push(byte);
        if bytes.len() > MAX_BODY {
            break;
        }
    }

    let body_bounded = bytes.len() <= MAX_BODY;
    otel_wasi::main_attribute!(
        "identity.request.body.size" = bytes.len() as i64,
        "identity.request.body.bounded" = body_bounded,
    );
    if !body_bounded {
        drop(body);
        done_tx
            .write(Err(ErrorCode::HttpRequestBodySize(Some(MAX_BODY as u64))))
            .await
            .map_err(|_| ErrorCode::InternalError(None))
            .error_with_typed_slug("service-identity-request-body-result-failed")?;
        drop(trailers);
        otel_wasi::main_attribute!(
            "http.response.status_code" = 413i64,
            "identity.outcome" = "request_body_too_large",
        );
        return skir_error(413);
    }

    drop(body);
    done_tx
        .write(Ok(()))
        .await
        .map_err(|_| ErrorCode::InternalError(None))
        .error_with_typed_slug("service-identity-request-body-result-failed")?;
    trailers
        .await
        .error_with_typed_slug("service-identity-request-trailers-failed")?;

    let request = match IssueServiceIdentityRequest::serializer().from_bytes(
        &bytes,
        wasmcloud_utils::skir_client::UnrecognizedValues::Drop,
    ) {
        Ok(request) => {
            otel_wasi::main_attribute!("identity.request.decode.success" = true);
            request
        }
        Err(_) => {
            otel_wasi::main_attribute!(
                "identity.request.decode.success" = false,
                "http.response.status_code" = 400i64,
                "identity.outcome" = "malformed_request",
            );
            return skir_error(400);
        }
    };

    let result = match crate::identity::issue_identity(
        &crate::authentik::AuthentikClient,
        &crate::repository::SurrealIdentityRepository,
        &crate::names::WasiNameSource,
        request,
    )
    .await
    {
        Ok(result) => result,
        Err(error) => {
            otel_wasi::main_attribute!(
                "error" = true,
                "exception.slug" = error.slug().to_string(),
                "exception.message" = error.message().to_string(),
                "identity.outcome" = "internal_error",
            );
            IssueServiceIdentityResponse::internal_error()
        }
    };

    let status = status(&result);
    otel_wasi::main_attribute!(
        "http.response.status_code" = status as i64,
        "identity.response.variant" = result.variant_slug().to_string(),
        "identity.outcome" = result.variant_slug().to_string(),
    );
    response(
        status,
        IssueServiceIdentityResponse::serializer().to_bytes(&result),
        true,
        None,
    )
    .error_with_typed_slug("service-identity-response-build-failed")
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

fn skir_error(status: u16) -> Result<Response, otel_wasi::Error<ErrorCode>> {
    let value =
        wasmcloud_utils::skir_variant!(IssueServiceIdentityResponse::MalformedRequestError {});
    response(
        status,
        IssueServiceIdentityResponse::serializer().to_bytes(&value),
        true,
        None,
    )
    .error_with_typed_slug("service-identity-response-build-failed")
}

fn status(value: &IssueServiceIdentityResponse) -> u16 {
    match value {
        IssueServiceIdentityResponse::Success(_) => 200,
        IssueServiceIdentityResponse::MalformedRequestError(_)
        | IssueServiceIdentityResponse::UnknownRoleError(_)
        | IssueServiceIdentityResponse::RolesRequiredError(_)
        | IssueServiceIdentityResponse::RoleUnknownPropertyError(_)
        | IssueServiceIdentityResponse::RoleTypeInvalidError(_)
        | IssueServiceIdentityResponse::RoleVersionBlankError(_)
        | IssueServiceIdentityResponse::RoleInvalidError(_)
        | IssueServiceIdentityResponse::CustomRoleNameRequiredError(_)
        | IssueServiceIdentityResponse::CustomRoleNameInvalidError(_)
        | IssueServiceIdentityResponse::BuiltinRoleNameForbiddenError(_)
        | IssueServiceIdentityResponse::EngineRoleDuplicateError(_)
        | IssueServiceIdentityResponse::RealmRoleDuplicateError(_)
        | IssueServiceIdentityResponse::CustomRoleDuplicateError(_) => 400,
        IssueServiceIdentityResponse::IdentityProviderUnavailableError(_) => 503,
        IssueServiceIdentityResponse::InternalError(_)
        | IssueServiceIdentityResponse::Unknown(_) => 500,
    }
}

fn response(
    status: u16,
    bytes: Vec<u8>,
    skir: bool,
    extra: Option<(&str, &str)>,
) -> Result<Response, ErrorCode> {
    let headers = Fields::new();
    headers
        .set(
            "content-type",
            &[if skir {
                b"application/octet-stream".to_vec()
            } else {
                b"text/plain".to_vec()
            }],
        )
        .map_err(|_| ErrorCode::InternalError(None))?;
    if skir {
        headers
            .set("x-typewriter-format", &[b"skir-binary".to_vec()])
            .map_err(|_| ErrorCode::InternalError(None))?;
    }
    if let Some((key, value)) = extra {
        headers
            .set(key, &[value.as_bytes().to_vec()])
            .map_err(|_| ErrorCode::InternalError(None))?;
    }
    let (mut tx, rx) = bindings::wit_stream::new();
    let (trailers_tx, trailers_rx) = bindings::wit_future::new(|| todo!());
    spawn_local(async move {
        tx.write_all(bytes).await;
        drop(tx);
        let _ = trailers_tx.write(Ok(None)).await;
    });
    let (response, _) = Response::new(headers, Some(rx), trailers_rx);
    response
        .set_status_code(status)
        .map_err(|_| ErrorCode::InternalError(None))?;
    Ok(response)
}

#[cfg(test)]
mod tests {
    use super::*;
    use wasmcloud_utils::skir_variant;

    #[test]
    fn every_response_variant_has_expected_status() {
        let success =
            IssueServiceIdentityResponse::Success(Box::new(IssueServiceIdentityResponse_Success {
                service_id: String::new(),
                display_name: String::new(),
                username: String::new(),
                token: String::new(),
                _unrecognized: None,
            }));
        assert_eq!(status(&success), 200);
        let bad_requests = [
            skir_variant!(IssueServiceIdentityResponse::MalformedRequestError {}),
            skir_variant!(IssueServiceIdentityResponse::UnknownRoleError {}),
            skir_variant!(IssueServiceIdentityResponse::RolesRequiredError {}),
            skir_variant!(IssueServiceIdentityResponse::RoleUnknownPropertyError {}),
            skir_variant!(IssueServiceIdentityResponse::RoleTypeInvalidError {}),
            skir_variant!(IssueServiceIdentityResponse::RoleVersionBlankError {}),
            skir_variant!(IssueServiceIdentityResponse::RoleInvalidError {}),
            skir_variant!(IssueServiceIdentityResponse::CustomRoleNameRequiredError {}),
            skir_variant!(IssueServiceIdentityResponse::CustomRoleNameInvalidError {}),
            skir_variant!(IssueServiceIdentityResponse::BuiltinRoleNameForbiddenError {}),
            skir_variant!(IssueServiceIdentityResponse::EngineRoleDuplicateError {}),
            skir_variant!(IssueServiceIdentityResponse::RealmRoleDuplicateError {}),
            skir_variant!(IssueServiceIdentityResponse::CustomRoleDuplicateError {}),
        ];
        assert!(bad_requests.iter().all(|response| status(response) == 400));
        assert_eq!(
            status(&skir_variant!(
                IssueServiceIdentityResponse::IdentityProviderUnavailableError {}
            )),
            503
        );
        assert_eq!(
            status(&skir_variant!(
                IssueServiceIdentityResponse::InternalError {}
            )),
            500
        );
        assert_eq!(status(&IssueServiceIdentityResponse::Unknown(None)), 500);
    }
}
