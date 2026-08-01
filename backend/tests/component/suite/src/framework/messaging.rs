use component_test::{
    FixtureBuilder, FixtureSpec, TestContext, TestResult, component_fixture, component_test,
};

#[component_fixture(
    id = "synthetic-messaging",
    primary(
        package = "component-test-messaging",
        target = "component_test_messaging"
    ),
    affected_paths("backend/testing/component-test-messaging/")
)]
pub struct SyntheticMessaging;

impl FixtureSpec for SyntheticMessaging {
    fn configure(builder: FixtureBuilder<Self>) -> FixtureBuilder<Self> {
        builder
            .messaging_with(|mock| {
                mock.expect_publish("component.out")
                    .body(b"payload".to_vec());
            })
            .messaging_subscription("test.publish")
    }
}

#[component_test(SyntheticMessaging)]
async fn host_publish_invokes_component(
    context: &mut TestContext<SyntheticMessaging>,
) -> TestResult {
    context
        .messaging()?
        .publish("test.publish", b"payload".to_vec())
        .await?;
    context.messaging()?.wait_idle().await
}

#[component_fixture(
    id = "synthetic-messaging-request",
    primary(
        package = "component-test-messaging",
        target = "component_test_messaging"
    ),
    affected_paths("backend/testing/component-test-messaging/")
)]
pub struct SyntheticMessagingRequest;

impl FixtureSpec for SyntheticMessagingRequest {
    fn configure(builder: FixtureBuilder<Self>) -> FixtureBuilder<Self> {
        builder
            .messaging_with(|mock| {
                mock.expect_request("dependency.echo")
                    .body(b"question".to_vec())
                    .reply(b"answer".to_vec());
                mock.expect_publish("component.result")
                    .body(b"answer".to_vec());
            })
            .messaging_subscription("test.request")
    }
}

#[component_test(SyntheticMessagingRequest)]
async fn component_request_uses_scripted_reply(
    context: &mut TestContext<SyntheticMessagingRequest>,
) -> TestResult {
    context
        .messaging()?
        .publish("test.request", b"question".to_vec())
        .await?;
    context.messaging()?.wait_idle().await
}

#[component_fixture(
    id = "synthetic-composed",
    primary(
        package = "component-test-messaging",
        target = "component_test_messaging"
    ),
    dependency(
        package = "component-test-responder",
        target = "component_test_responder"
    ),
    affected_paths(
        "backend/testing/component-test-messaging/",
        "backend/testing/component-test-responder/"
    )
)]
pub struct SyntheticComposed;

impl FixtureSpec for SyntheticComposed {
    fn configure(builder: FixtureBuilder<Self>) -> FixtureBuilder<Self> {
        builder
            .messaging_with(|mock| {
                mock.expect_request("dependency.echo")
                    .body(b"composed".to_vec());
                mock.expect_publish("component.result")
                    .body(b"composed".to_vec());
            })
            .primary(|component| component.subscription("test.request"))
            .dependency("component-test-responder", |component| {
                component.subscription("dependency.echo")
            })
    }
}

#[component_test(SyntheticComposed)]
async fn optional_component_replies(context: &mut TestContext<SyntheticComposed>) -> TestResult {
    context
        .messaging()?
        .publish("test.request", b"composed".to_vec())
        .await?;
    context.messaging()?.wait_idle().await
}
