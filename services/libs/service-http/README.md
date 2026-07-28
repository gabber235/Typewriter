# service-http

A bounded, suspending HTTP client for service integrations.

`service-http-core` owns immutable requests, responses, multi-value headers, typed outcomes, the transport SPI, propagation, and telemetry. `service-http-jdk` provides the Java 21 asynchronous transport. `service-http-testing` provides a deterministic scripted fake.

```kotlin
val result = ServiceHttpClient(transport, telemetry, propagators).execute(
    HttpRequest(operation, failureSlug, HttpMethod.GET, URI("https://example.test/status"))
)
```

Requests and responses defensively copy byte arrays. Reading `body` returns a new copy. Header names are case-insensitive and duplicate values are preserved. Request and response bounds are enforced before sending and while receiving respectively.

Every operation creates one client span and replaces all configured propagation fields before injecting the current context. Telemetry includes only safe method, scheme, host, sizes, operation, and outcome data. Headers, URI queries, bodies, credentials, and response bodies are never recorded.

Cancellation cancels the Java future and escapes to the caller. Fatal and programming failures are not operational HTTP outcomes. HTTP status codes, including non-2xx codes, remain successful HTTP responses for domain-level classification.

The client never retries. Callers own retry and idempotency policy. Close `JdkHttpTransport` to release its executor. Redirects are disabled.
