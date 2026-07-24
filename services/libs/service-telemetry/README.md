# Service Telemetry

Kotlin-first OpenTelemetry instrumentation primitives for Typewriter services. The library owns span instrumentation and context propagation; applications own the OpenTelemetry SDK, resources, sampling, exporters, global registration, and shutdown.

## Artifacts

```kotlin
dependencies {
    implementation("com.typewritermc:service-telemetry-core")
    implementation("com.typewritermc:service-telemetry-koin") // optional
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

`main.annotate` always enriches the stable unit-of-work span. `child.annotate` is for operation detail. Successful and expected-domain outcomes remain OTel `UNSET`; escaping classified failures become `ERROR`. Cancellation is ended and rethrown without being classified as an application error.

Define service-specific vocabulary as typed extensions:

```kotlin
fun MainAttributes.identityOutcome(outcome: IdentityOutcome) {
    attribute("identity.outcome", outcome.wireValue)
}
```

## Error classification

`withErrorSlug` and `withErrorSlugSuspending` wrap ordinary failures in `SluggedException`. Existing slugged failures are rethrown unchanged, so nested layers do not double-wrap or replace the source classification. Main boundaries require an `unhandledFailureSlug` for otherwise unclassified failures.

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

`TelemetryTestHarness` creates an isolated, non-global in-memory SDK:

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
