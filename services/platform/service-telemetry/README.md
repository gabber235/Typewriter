# Service Telemetry

OpenTelemetry instrumentation primitives for Typewriter services. OpenTelemetry spans and span events are the source of truth. Selected events are also emitted as correlated OpenTelemetry log records. Applications own the SDK, resources, sampling, exporters, global registration, and shutdown.

## Artifacts

```kotlin
dependencies {
    implementation("com.typewritermc:service-telemetry-core")
    implementation("com.typewritermc:service-telemetry-koin") // optional
    implementation("com.typewritermc:service-telemetry-console") // application shells only
    testImplementation("com.typewritermc:service-telemetry-testing")
}
```

The previous `com.typewritermc:service-telemetry` artifact and its APIs were removed. Realm, service-communicator, and service-registrar require a separate migration to the new coordinates.

## Core usage

```kotlin
val telemetry = openTelemetry.serviceTelemetry(
    name = "com.typewritermc.realm",
    version = REALM_VERSION,
)

suspend fun consume(message: Message) = telemetry.consumerSpan(
    name = "registration.process",
    unhandledFailureSlug = ErrorSlug.of("registration-process-failed"),
) { main ->
    main.annotate {
        messagingSystem("nats")
        messagingDestinationName(message.subject)
    }
    handle(message)
}

context(main: MainSpanScope)
suspend fun handle(message: Message) {
    main.annotate { attribute("service.id", message.serviceId) }

    childSpan("repository.service.load") { child ->
        child.annotate { dbOperationName("select") }
        withErrorSlugSuspending(ErrorSlug.of("service-load-failed")) {
            repository.load(message.serviceId)
        }
    }
}
```

`main.annotate` always enriches the stable operation span. `child.annotate` is for operation detail. Successful and expected domain outcomes remain OTel `UNSET`; escaping classified failures become `ERROR`. Cancellation is ended and rethrown without being classified as an application error.

Define service-specific vocabulary as typed extensions:

```kotlin
fun MainAttributes.identityOutcome(outcome: IdentityOutcome) {
    attribute("identity.outcome", outcome.wireValue)
}
```

## Error classification

`withErrorSlug` and `withErrorSlugSuspending` wrap ordinary failures in `SluggedException`. Existing slugged failures are rethrown unchanged, so nested layers do not wrap twice or replace the source classification. Main boundaries require an `unhandledFailureSlug` for otherwise unclassified failures.

## Operational events

Mark a main span with a presentation only when its lifecycle should be visible to an operator. The boundary adds `operation.started`, `operation.completed`, `operation.cancelled`, or `operation.failed` events and projects them into logs.

```kotlin
telemetry.mainSpan(
    name = "realm.start",
    unhandledFailureSlug = ErrorSlug.of("realm-start-failed"),
    presentation = SpanPresentation("Realm startup"),
) {
    startRealm()
}
```

Add progress to the active span. The event is always trace data. A projection also makes it a correlated log record and a concise console line.

```kotlin
main.event(
    name = "workflow.stage.started",
    projection = EventProjection.log(
        severity = LogSeverity.INFO,
        body = "Connecting to the Realm database",
    ),
) {
    attribute("workflow.stage", "database")
}
```

The default projection is `TraceOnly`:

```kotlin
main.event("realm.schema.migration.applied") {
    attribute("realm.schema.version", version)
}
```

Build the event once through this API. First party service code must not call `Span.addEvent`, the OpenTelemetry Logs API, SLF4J, `println`, `System.out`, or `System.err` directly.

## Choosing a signal

| Need | Instrument |
| --- | --- |
| Work with duration | Main span or child span |
| Queryable context learned during work | Span attribute |
| Meaningful moment inside work | Span event |
| Moment needed for search, alerts, or operators | Projected span event |
| Escaping failure | Standard exception event through a span boundary |
| Numeric trend or distribution | Metric |
| Warning from a dependency | Third party diagnostic bridge |

Repeated healthy checks and unchanged states should stay trace only or be omitted. Never record credentials, authorization values, request bodies, registration tokens, or URI queries.

## Application SDK wiring

Applications use one `SdkTracerProvider` and one `SdkLoggerProvider`. Traces use the OTLP trace exporter. Logs use an immediate console processor and a batch OTLP processor. A projected event remains available when trace sampling is disabled because log sampling is independent.

The console exporter renders only timestamp, severity, body, and a warning or error reference. It never renders attribute maps or stack traces. Application shells provide a `ConsoleLogOutput` so interactive shells can print above the active prompt.

Dependency diagnostics use `OpenTelemetryLogbackAppender`. The default level is `WARN`. Applications may expose a diagnostic level setting for temporary investigation. Dependency records remain logs and are not converted into span events.

OpenTelemetry SDK self diagnostics use `installOpenTelemetrySdkDiagnostics`. They write concise warning and error lines directly through `ConsoleLogOutput`. They never enter the OpenTelemetry logs pipeline because an exporter failure must not recursively generate another export attempt.

## Koin

Bind an application-owned `OpenTelemetry`, then install the adapter:

```kotlin
modules(
    module { single<OpenTelemetry> { applicationOpenTelemetry } },
    serviceTelemetryModule("com.typewritermc.realm", REALM_VERSION),
)
```

Closing Koin does not close the SDK.

## Testing

`TelemetryTestHarness` creates an isolated in memory SDK:

```kotlin
TelemetryTestHarness.create().use { harness ->
    // invoke instrumented code with harness.telemetry
    harness.assertNoActiveSpans()
    harness.spans {
        main("registration.process") {
            attribute("registration.outcome", "bound")
            child("repository.service.load")
        }
    }
}
```
