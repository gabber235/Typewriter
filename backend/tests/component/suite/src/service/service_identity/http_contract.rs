use component_test::{TestContext, TestResult, component_test};
use wasmcloud_utils::skir::base::service::v1::identity::IssueServiceIdentityResponse;

use super::ServiceIdentity;

#[component_test(ServiceIdentity)]
async fn unknown_route_returns_plain_not_found(
    context: &mut TestContext<ServiceIdentity>,
) -> TestResult {
    let response = context
        .http()?
        .get("/service/identity/missing")
        .send()
        .await?;

    assert_eq!(response.status(), http::StatusCode::NOT_FOUND);
    assert_eq!(
        response.headers().get(http::header::CONTENT_TYPE).unwrap(),
        "text/plain"
    );
    assert_eq!(response.bytes().await?.as_ref(), b"not found\n");
    Ok(())
}

#[component_test(ServiceIdentity)]
async fn unsupported_method_returns_allow_header(
    context: &mut TestContext<ServiceIdentity>,
) -> TestResult {
    let response = context
        .http()?
        .get("/service/identity/issue")
        .send()
        .await?;

    assert_eq!(response.status(), http::StatusCode::METHOD_NOT_ALLOWED);
    assert_eq!(response.headers().get(http::header::ALLOW).unwrap(), "POST");
    assert_eq!(response.bytes().await?.as_ref(), b"method not allowed\n");
    Ok(())
}

#[component_test(ServiceIdentity)]
async fn unsupported_media_type_returns_typed_error(
    context: &mut TestContext<ServiceIdentity>,
) -> TestResult {
    let response = context
        .http()?
        .post("/service/identity/issue", Vec::new())
        .send()
        .await?;
    let status = response.status();
    let headers = response.headers().clone();
    let body = response.bytes().await?;
    let decoded = IssueServiceIdentityResponse::serializer().from_bytes(
        &body,
        wasmcloud_utils::skir_client::UnrecognizedValues::Drop,
    )?;

    assert_eq!(status, http::StatusCode::UNSUPPORTED_MEDIA_TYPE);
    assert_eq!(
        headers.get(http::header::CONTENT_TYPE).unwrap(),
        "application/octet-stream"
    );
    assert_eq!(headers.get("x-typewriter-format").unwrap(), "skir-binary");
    assert!(matches!(
        decoded,
        IssueServiceIdentityResponse::MalformedRequestError(_)
    ));
    Ok(())
}

#[component_test(ServiceIdentity)]
async fn malformed_skir_body_returns_bad_request(
    context: &mut TestContext<ServiceIdentity>,
) -> TestResult {
    let response = context
        .http()?
        .post("/service/identity/issue", b"not skir".to_vec())
        .header(http::header::CONTENT_TYPE, "application/octet-stream")
        .header("x-typewriter-format", "skir-binary")
        .send()
        .await?;
    let status = response.status();
    let body = response.bytes().await?;
    let decoded = IssueServiceIdentityResponse::serializer().from_bytes(
        &body,
        wasmcloud_utils::skir_client::UnrecognizedValues::Drop,
    )?;

    assert_eq!(status, http::StatusCode::BAD_REQUEST);
    assert!(matches!(
        decoded,
        IssueServiceIdentityResponse::MalformedRequestError(_)
    ));
    Ok(())
}
