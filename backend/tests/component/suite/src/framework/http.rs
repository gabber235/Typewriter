use component_test::{
    FixtureBuilder, FixtureSpec, TestContext, TestResult, component_fixture, component_test,
};

#[component_fixture(
    id = "synthetic-http",
    primary(package = "component-test-echo", target = "component_test_echo")
)]
pub struct SyntheticHttp;

impl FixtureSpec for SyntheticHttp {
    fn configure(builder: FixtureBuilder<Self>) -> FixtureBuilder<Self> {
        builder.http("synthetic-http.test")
    }
}

#[component_test(SyntheticHttp)]
async fn an_http_response_reaches_the_caller(
    context: &mut TestContext<SyntheticHttp>,
) -> TestResult {
    let response = context.http()?.get("/").send().await?;

    assert_eq!(response.status(), http::StatusCode::OK);
    assert_eq!(response.bytes().await?.as_ref(), b"ok");
    Ok(())
}
