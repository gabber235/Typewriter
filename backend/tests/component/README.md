# Embedded component tests

This workspace executes compiled `wasm32-wasip2` components through the production `wash-runtime` host. Tests do not call component crate functions.

## Commands

Run from repository root:

```console
cargo xtask component-test --list
cargo xtask component-test service-identity
cargo xtask component-test service-identity issue_identity__engine_role
cargo xtask component-test --affected origin/main
cargo xtask component-test --all
cargo xtask component-test --all --jobs 4
```

The xtask always asks Cargo to build selected components, reads exact artifacts from Cargo JSON messages, hashes them, writes an immutable run manifest, then starts one library test process. Direct `cargo test` intentionally fails without that manifest because it cannot guarantee fresh Wasm artifacts.

`--live` streams redacted fixture diagnostics. Passing tests otherwise remain quiet.

## Dagger and CI

CI invokes dedicated Dagger functions rather than running Cargo directly. These functions are intentionally not annotated with `+check`, so the component suite is not part of the general `dagger check` command:

```console
dagger call component-test stdout
dagger call component-test-fixture --fixture service-identity stdout
dagger call component-test-case --fixture synthetic-http --filter case_000 stdout
dagger call component-test-shard --index 0 --count 2 stdout
dagger call component-test-affected \
  --repository https://github.com/Seamlezz/Typewriter.git \
  --base <commit> stdout
dagger call component-test-performance stdout
```

The GitHub workflow only selects the appropriate Dagger function. Other CI systems can invoke the same functions without reproducing Rust setup, caching, artifact selection, or test commands.

## Writing a fixture

Fixtures live in `suite/src` and declare build identity once:

```rust
#[component_fixture(
    id = "example",
    primary(package = "example-component", target = "example_component"),
    affected_paths("backend/example/")
)]
pub struct Example;

impl FixtureSpec for Example {
    fn configure(builder: FixtureBuilder<Self>) -> FixtureBuilder<Self> {
        builder
            .http("example.test")
            .otel()
            .typewriter_database(SchemaPreset::Service)
    }
}
```

The primary component is always explicit. Add real dependencies through repeated `dependency(package = ..., target = ...)` declarations and configure them with `builder.dependency(...)`. All real components share one workload, so their workload-level interfaces must be compatible.

Each case gets a fresh host, workload, plugins, database, mocks, ports, IDs, and temporary resources. Only the Wasmtime engine, verified artifact bytes, and compiled-component cache are shared.

## Writing tests

```rust
#[component_test(Example)]
#[case::empty(Vec::new())]
#[case::one(vec![value()])]
async fn behavior(
    context: &mut TestContext<Example>,
    values: Vec<Value>,
) -> TestResult {
    let response = context.http()?.post("/example", payload).send().await?;
    assert_eq!(response.status(), 200);
    Ok(())
}
```

`#[component_test]` must appear before repeated named `#[case::name(...)]` attributes. Every case becomes an independently listed and filterable ordinary Rust test while sharing one test process.

Component tests may return `()` or `Result<(), E>` where `E` converts to `anyhow::Error`. Do not combine `component_test` with `tokio::test`, `rstest`, `test`, or `should_panic`.

## Outgoing HTTP mocks

Register a typed dependency in fixture setup:

```rust
builder
    .outgoing_http::<Authentik>("http://authentik.test")
    .primary(|component| {
        component.environment("AUTHENTIK_URL", "http://authentik.test")
    })
```

Declare strict expectations before triggering behavior:

```rust
context
    .http_mock::<Authentik>()?
    .expect()
    .post()
    .path_query("/api/v3/users/")
    .header(AUTHORIZATION, HeaderValue::from_static("Bearer token"))
    .body_matches(|body| valid_json(body))
    .times(1)
    .response_json(&json!({"id": "fixture"}))?
    .register()?;
```

Unexpected requests and unmet cardinality fail automatically, including when the test body fails. Exact bytes, semantic JSON, predicates, header subsets, delays, transport failures, optional/ranged counts, transcripts, and scoped async handlers are available. Runtime allowed-host policy executes before the mock.

## Messaging

Every messaging component declares subscriptions explicitly:

```rust
builder
    .messaging_subscription("typewriter.from.service.*.heartbeat")
    .messaging_with(|mock| {
        mock.expect_publish("typewriter.to.>").times(1);
        mock.expect_request("dependency.lookup").reply(bytes);
    })
```

Tests inject through `context.messaging()?`. Component-originated publish/request traffic is verified through `context.messaging_mock()?`. Host-injected traffic never satisfies outbound expectations. `wait_idle` includes queued and running component handlers.

## Typewriter helpers

`typewriter-component-test::prelude` provides:

- `SchemaPreset` and `TypewriterFixtureBuilderExt`.
- Unique in-memory SurrealDB per case.
- Bound Rust seed queries and typed/JSON assertions.
- `SkirHttpExt` and `SkirMessagingExt` using explicit generated serializers.
- Typed Skir messaging expectation bodies and replies.

Raw byte APIs remain available for malformed payload and protocol tests.

## Failure behavior

The runner catches panics while polling the async body, drains messaging, verifies strict mocks, stops workload before host, cleans extensions in reverse order, prints one redacted report, then resumes the original panic. The report includes fixture/test/case identity, phase timings, artifacts and hashes, workload state, guest logs, mock transcripts, and cleanup failures.

Sensitive environment values and authorization/cookie headers are redacted before buffering.

## Parallelism

The framework admits a conservative number of isolated fixtures based on available CPUs, capped at two by default. Override with `--jobs` or `COMPONENT_TEST_JOBS`.

The supported runner is ordinary Cargo libtest. Nextest runs each test in a separate process and therefore cannot share the engine or admission controller; it is not optimized or supported initially.

## Troubleshooting

### Missing run manifest

Use the exact xtask command printed by the error. Direct Cargo or IDE execution is not a freshness-safe path.

### Artifact hash mismatch

Rerun xtask. Never edit files under `backend/target/wasm32-wasip2` manually.

### Workload did not reach Running

The failure report includes the runtime state and message. Check fixture interfaces, component target name, explicit messaging subscriptions, and database preset.

### Outgoing request denied

Register the authority with `outgoing_http::<Marker>` or add an explicit allowed host to the correct component. An empty allowlist denies all outgoing traffic.

### Test appears stuck

Run one exact case with `--jobs 1 --live`. Lifecycle phases have bounded timeouts and the report identifies drain or stop failures.

## Architecture

- `component-test-model`: descriptors, run manifest, catalog, affected selection.
- `component-test-core`: runtime lifecycle, builders, mocks, diagnostics.
- `component-test-macros`: fixture and test attributes.
- `component-test`: generic public facade.
- `typewriter-component-test`: SurrealDB and Skir extensions.
- `suite`: central fixture catalog and examples.
- `xtask`: artifact builds, selection, manifests, sharding, and execution.

The framework validates embedded runtime behavior only. OCI packaging, NATS transport, containers, Kubernetes, operator reconciliation, and ingress require separate coverage.
