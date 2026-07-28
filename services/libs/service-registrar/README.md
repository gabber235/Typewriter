# Service registrar

Reusable Typewriter service identity, binding, and messaging bootstrap.

## Artifacts

- `service-registrar-core`: lifecycle supervisor, state, results, configuration, domain types, and ports.
- `service-registrar-runtime`: canonical Skir HTTP/NATS adapters and authenticated communicator session.
- `service-registrar-storage-file`: optional versioned plaintext file credential storage.
- `service-registrar-console`: optional operator binding-token output.
- `service-registrar-koin`: thin optional composition.
- `service-registrar-testing`: deterministic lifecycle fakes.

The root project is aggregation-only. Core has no NATS.kt, Skir, JDK HTTP adapter, JSON, Mordant, or Koin dependency.

## Lifecycle

```kotlin
registrar.start()

when (val result = registrar.awaitReady()) {
    is RegistrarResult.Success -> {
        val session = result.value
        use(session.identity, session.binding, session.communicator)
    }
    is RegistrarResult.Failure -> report(result.failure)
}
```

Registrar is single-run. The application supplies its lifecycle scope and calls suspending `stop()`. Caller cancellation of `awaitReady()` does not cancel registration. Expected failures are typed; cancellation, fatal JVM failures, and unexpected programming failures escape.

`states` exposes detailed loading, issuance, persistence, authentication, connection, binding, reauthorization, Ready, Degraded, failure, and shutdown phases. A call to `awaitReady()` made during Degraded waits for current connectivity to recover. Ready sessions expose only public identity, organization binding, and `Communicator`; credentials and raw NATS lifecycle objects remain private.

## Identity safety

Identity issuance uses canonical Skir at `POST /service/identity/issue` and supports Engine, Realm, and Custom roles. Issuance never retries automatically because the backend has no idempotency key or credential-recovery endpoint. An explicit retry after an ambiguous timeout can create a second active identity.

A successful issued credential is retained before persistence. Storage retries reuse that exact credential and never issue another identity in the same registrar run. There is no credential reset/delete API until the backend can revoke old identities safely.

`service-registrar-storage-file` stores a versioned JSON document in plaintext, writes through a temporary file, forces it, and replaces the target atomically when supported. Permissions are best effort. Use a custom `CredentialStorage` for a platform secret manager.

## Binding and delivery

Registrar subscribes and flushes the bound-notification subject before requesting service status. While unbound, `AwaitingBinding` exposes a redacted registration-token value for an application UI or the optional console observer. Core never logs the token. Periodic status refresh renews the token lease and recovers lost at-most-once bound notifications.

After binding, registrar reconnects NATS so the auth callout grants organization permissions, confirms bound status, starts an immediate heartbeat, and enters Ready. Binding is not polled after first Ready. Connectivity remains dynamic through Ready and Degraded states.

NATS.kt 0.9.1 does not replay subscriptions after reconnect. Registrar recreates only its own pending-binding watch. Applications must rebuild generation-bound routers and watches after registrar connection-generation changes. See [`../service-communicator/NATS_KT_FOLLOW_UP.md`](../service-communicator/NATS_KT_FOLLOW_UP.md).

## Authentication

The runtime:

1. exchanges the issued Authentik username/app password through `client_credentials`;
2. caches the access token in memory until its refresh skew;
3. fetches and age-caches Sentinel JWT/seed credentials;
4. sends the access JWT in NATS CONNECT `pass`;
5. sends standard-Base64 Skir `EntityPermissionQualifier.service` in CONNECT `nkey`; and
6. sends the Sentinel JWT and nonce signature in `jwt` and `sig`.

Secrets, authorization headers, HTTP bodies, provider responses, and URI queries are excluded from diagnostics and telemetry.

## Koin

```kotlin
modules(
    applicationTelemetryModule,
    applicationStorageModule,
    registrarModule(configuration, applicationScope),
)
```

The application must bind `OpenTelemetry`, `ServiceTelemetry`, and `CredentialStorage`. The module does not start or stop registrar, create an application scope, install global/no-op telemetry, render tokens, or call `runBlocking` during close. The application owns `JdkHttpTransport` closure with the rest of its composition lifecycle.

## Realm migration

The old registrar APIs and compatibility qualifiers were removed. Realm is intentionally unchanged and must migrate separately to `RegistrarConfiguration`, `states`, `awaitReady()`, `ReadySession.communicator`, explicit lifecycle ownership, and per-connection-generation router recreation.
