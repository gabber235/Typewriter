# Embedded component tests

This workspace executes compiled `wasm32-wasip2` components through the production `wash-runtime` host. Tests do not call component crate functions.

## Commands

Run the suite from the devenv shell at the repository root. This is the supported development and CI interface:

```console
cargo xtask check components
cargo xtask components service-identity
cargo xtask components synthetic-http case_000 --jobs 1
cargo xtask components --list
cargo xtask components service-identity engine_identity_persists_credentials_and_roles --jobs 1 --live
```

`cargo xtask check components` runs every fixture and writes the results as a `TestRun` (`skir-src/harness/v1/test_run.skir`) to `.xtask/results/components.json`. `cargo xtask components` runs one fixture, or the cases of one fixture matching a filter; `--results <path>` writes its `TestRun`. Either way a failed case is rerun once: passing on the rerun reports it as flaky without failing the run, and cases listed in `harness/quarantine.toml` are reported without gating. devenv provides the pinned Rust toolchain, the Wasm target and `nats-server`.

The runner reads the fixture catalog from the suite's `catalog` binary, checks that every deployable backend component has a fixture, asks Cargo to build the selected components, reads exact artifacts from Cargo JSON messages, hashes them, writes an immutable run manifest, then starts one library test process. Direct `cargo test` intentionally fails without that manifest because it cannot guarantee fresh Wasm artifacts.

`--live` streams redacted fixture diagnostics. Passing tests otherwise remain quiet.

## Writing a fixture

Fixtures live in `suite/src` and declare build identity once:

```rust
#[component_fixture(
    id = "example",
    primary(package = "example-component", target = "example_component"),
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

The test process starts one operator mode NATS server (`backend/testing/nats-broker`), and each fixture gets its own account on it, with JetStream, signing in with a user JWT. Accounts isolate subjects, inboxes and streams like separate servers, so fixtures stay independent while paying for one account instead of a server start. Each fixture deletes its account in teardown. The fixture uses the production `wasmcloud:nats` plugin. devenv supplies the pinned server binary through `NATS_SERVER_BIN`.

Tests inject through `context.messaging()?`. Guest publish and request traffic is verified through `context.messaging_mock()?`, including calls between real components. Injected input never satisfies outbound expectations. `wait_idle` fences broker subscriptions and waits for queued deliveries, running handlers, and observed output. It does not infer completion from a socket flush.

`expect_persisted_publish` observes an event accepted by the real `TYPEWRITER_MEMBERSHIP` JetStream stream. It does not fabricate an acknowledgement.

Use `context.wait_for_span(name, timeout).await` to assert completed guest telemetry. Capture belongs to the fixture and wakes when the span processor receives a span. This keeps trace assertions deterministic while export runs asynchronously.

## Typewriter helpers

`typewriter-component-test::prelude` provides:

- `SchemaPreset` and `TypewriterFixtureBuilderExt`.
- Unique in-memory SurrealDB per case.
- Bound Rust seed queries and typed/JSON assertions.
- `skir_record_id` for string keyed Skir record identifiers.
- `database_record_key` for extracting record keys from JSON query results.
- `SkirHttpExt` and `SkirMessagingExt` using explicit generated serializers.
- Typed Skir messaging expectation bodies and replies.

Raw byte APIs remain available for malformed payload and protocol tests.

## Failure behavior

The runner catches panics while polling the async body, drains messaging, verifies strict mocks, stops workload before host, cleans extensions in reverse order, prints one redacted report, then resumes the original panic. The report includes fixture/test/case identity, phase timings, artifacts and hashes, workload state, guest logs, mock transcripts, cleanup failures, and completed OpenTelemetry spans with their component resources, attributes, events, and links. Passing tests remain quiet.

Sensitive environment values and authorization/cookie headers are redacted before buffering.

## Parallelism

The framework admits as many fixtures at once as the machine has available parallelism. Pass `--jobs` to cap it.

The supported runner is ordinary Cargo libtest. Nextest runs each test in a separate process and therefore cannot share the engine or admission controller; it is not optimized or supported initially.

## Troubleshooting

### Missing run manifest

Run the matching `cargo xtask components` fixture or case command. Direct Cargo or IDE execution is not a freshness-safe path.

### Artifact hash mismatch

Rerun the matching `cargo xtask components` command. Never edit files under `backend/target/wasm32-wasip2` manually.

### Workload did not reach Running

The failure report includes the runtime state and message. Check fixture interfaces, component target name, explicit messaging subscriptions, and database preset.

### Outgoing request denied

Register the authority with `outgoing_http::<Marker>` or add an explicit allowed host to the correct component. An empty allowlist denies all outgoing traffic.

### Test appears stuck

Run one exact case with `cargo xtask components <fixture> <case> --jobs 1`. Lifecycle phases have bounded timeouts and the report identifies drain or stop failures.

## Architecture

- `component-test-model`: descriptors, run manifest, catalog.
- `component-test-core`: runtime lifecycle, builders, mocks, diagnostics.
- `component-test-macros`: fixture and test attributes.
- `component-test`: generic public facade.
- `typewriter-component-test`: SurrealDB (schema presets from `backend/database/schema`) and Skir extensions.
- `suite`: central fixture catalog and examples, plus the `catalog` binary the runner reads it from.
- `xtask/src/components.rs` (root harness): artifact builds, selection, manifests, execution and results.

The framework validates embedded runtime behavior only. OCI packaging, container images, Kubernetes, operator reconciliation, and ingress require separate coverage. Core NATS transport and membership persistence run against a real broker, isolated per fixture by account.
