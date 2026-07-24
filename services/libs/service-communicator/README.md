# Service communicator

Typed, coroutine-based service messaging with explicit transport and lifecycle ownership.

## Artifacts

- `service-communicator-core`: contracts, addresses, client, router, results, and transport SPI. It has no NATS, Skir, Koin, or Protokt dependency.
- `service-communicator-nats`: core-NATS connection and transport adapter.
- `service-communicator-skir`: `PayloadCodec` adapters and generated Skir models.
- `service-communicator-koin`: optional thin NATS wiring.
- `service-communicator-testing`: fake transport for consumers' tests.

```kotlin
dependencies {
    implementation("com.typewritermc:service-communicator-core")
    implementation("com.typewritermc:service-communicator-nats")
}
```

The Koin module requires application bindings for `OpenTelemetry`, `ServiceTelemetry`, `NatsConfigurationProvider`, and `NatsAuthenticationProvider`:

```kotlin
modules(applicationModule, communicatorModule(RouterOptions(maxInFlight = 32)))
```

It binds singleton `NatsConnection`, `MessageTransport` (`NatsMessageTransport`), `Communicator`, and `RouterOptions`. It does not bind routes, a router, scopes, no-op/global telemetry, close hooks, or SDK shutdown. The lifecycle owner explicitly calls `connect()`, `CommunicatorRouter.stop()`, and `NatsConnection.shutdown()`.

## Typed usage

```kotlin
data class Lookup(val serviceId: String)
data class Request(val name: String)
data class Response(val value: String)

val lookup = addressTemplate(
    "service.{serviceId}.lookup",
    { addressValuesOf("serviceId" to it.serviceId) },
    { Lookup(it.require("serviceId")) },
)
val contract = UnaryContract(
    name = OperationName.of("lookup"),
    requestAddress = lookup,
    requestCodec = requestCodec,
    responseCodec = responseCodec,
    responsePolicy = responsePolicy,
    timeout = 5.seconds,
    failureSlug = ErrorSlug.of("lookup-failed"),
)

when (val result = communicator.request(contract, Lookup("realm"), Request("key"))) {
    is CommunicationResult.Success -> use(result.value)
    is CommunicationResult.Failure -> handle(result.error)
}

val routes = communicatorRoutes {
    unary(contract, parallelism = 8) { call -> Response(find(call.request.name)) }
}
val router = CommunicatorRouter(transport, routes, communicator, telemetry, propagators, scope)
router.start()
```

Events use `EventContract` with `publish`; watches use `WatchContract` with `watch`. A watch is cold: every collector creates and owns an independent subscription. Canceling a caller cancels the operation rather than converting cancellation into a typed failure. Expected encode, decode, timeout, unavailable, no-responder, and transport failures are returned as `CommunicationResult.Failure`; fatal JVM errors and unexpected programming failures escape.

Telemetry is mandatory and application-owned. Communicator creates messaging spans and propagates the application's OpenTelemetry context but never installs globals, creates no-op telemetry, or shuts down an SDK/provider.

Routers bound accepted work globally (`maxInFlight`, default 16) and per route (`defaultRouteParallelism`, default 16). Shutdown closes subscriptions and drains accepted work for 30 seconds by default. Applications own router scope, routes, startup, and shutdown.

## NATS delivery semantics and reconnect limitation

The adapter uses core NATS with at-most-once delivery. Publish and request operations are not retried, and it does not use JetStream, persistence, acknowledgements, or replay.

NATS.kt 0.9.1 retains local `Subscription` objects during its reconnect loop but creates a new protocol engine without reissuing their `SUB` operations. A subscription can therefore appear active while receiving nothing after reconnect. Running routers and watches are not reconnect-safe. Fix and integration coverage belong upstream; communicator intentionally contains no parallel workaround.

## Registrar and Realm migration ledger

The legacy communicator monolith and compatibility APIs were removed. Registrar now owns HTTP concerns and must own NATS configuration/authentication, Sentinel credentials, JWT/token contracts, registration protocol clients, and any temporary reconnect contract. Its remaining Protokt-based protocol clients must be migrated separately to typed Skir contracts; communicator will not add Protokt or parse JWT payloads to bridge them.

Registrar compilation is currently informative, not a communicator build gate. Dependency resolution succeeds; remaining failures are source-level legacy usage: removed communicator APIs (`NatsCommunicator`, `CommunicatorQualifier`, `MessageBus`, `RegistrationClient`, `Reconnector`, and `JwtProvider`), removed telemetry span helpers, and Protokt-generated registration models. Replace these with registrar-owned contracts and typed communicator calls without changing payload protocols.

Realm migration remains outstanding and Realm is intentionally unchanged. It must move legacy route construction and communicator qualifiers to application-owned `CommunicatorRoutes`, `CommunicatorRouter`, lifecycle scope, and explicit NATS providers before it can consume the split artifacts.
