@file:OptIn(kotlinx.coroutines.ExperimentalCoroutinesApi::class)

package com.typewritermc.services.libs.registrar

import com.typewritermc.services.libs.communicator.client.Communicator
import com.typewritermc.services.libs.communicator.testing.FakeMessageTransport
import com.typewritermc.services.libs.registrar.testing.FakeCredentialStorage
import com.typewritermc.services.libs.registrar.testing.FakeIdentityIssuer
import com.typewritermc.services.libs.registrar.testing.FakeRegistrarDelay
import com.typewritermc.services.libs.registrar.testing.FakeRegistrarRuntime
import com.typewritermc.services.libs.registrar.testing.FakeRegistrarRuntimeFactory
import com.typewritermc.services.libs.registrar.testing.FakeRetryRandom
import com.typewritermc.services.libs.registrar.testing.RegistrarAction
import com.typewritermc.services.libs.registrar.testing.RegistrarActionLedger
import com.typewritermc.services.libs.telemetry.testing.TelemetryTestHarness
import com.typewritermc.services.libs.utils.RetryPolicy
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.matchers.shouldBe
import io.kotest.matchers.types.shouldBeInstanceOf
import io.opentelemetry.api.trace.SpanId
import io.opentelemetry.context.propagation.ContextPropagators
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.async
import kotlinx.coroutines.cancel
import kotlinx.coroutines.cancelAndJoin
import kotlinx.coroutines.flow.collect
import kotlinx.coroutines.launch
import kotlinx.coroutines.test.advanceTimeBy
import kotlinx.coroutines.test.runCurrent
import kotlinx.coroutines.test.runTest
import java.net.URI
import kotlin.time.Duration.Companion.milliseconds
import kotlin.time.Duration.Companion.seconds

val ServiceRegistrarLifecycleTest by testSuite {
    test("concurrent start is idempotent and loads once") {
        runTest {
            fixture(this).use { f ->
                f.readyScript()
                val starts = List(10) { async { f.registrar.start() } }
                starts.forEach { it.await().shouldBeInstanceOf<RegistrarResult.Success<Unit>>() }
                runCurrent()
                f.ledger.actions.count { it == RegistrarAction.LoadCredentials } shouldBe 1
            }
        }
    }
    test("stop before start is successful and restart is rejected") {
        runTest {
            fixture(this).use { f ->
                f.registrar.stop() shouldBe RegistrarStopResult.Success
                f.registrar.start().shouldBeInstanceOf<RegistrarResult.Failure>()
            }
        }
    }
    test("repeated stop returns the exact idempotent result") {
        runTest {
            fixture(this).use { f ->
                val first = f.registrar.stop()
                (f.registrar.stop() === first) shouldBe true
            }
        }
    }
    test("stored credentials skip identity issuance") {
        runTest {
            fixture(this, CredentialLoadResult.Loaded(credentials())).use { f ->
                f.readyScript()
                f.registrar.start()
                runCurrent()
                f.ledger.actions.none { it is RegistrarAction.IssueIdentity } shouldBe true
            }
        }
    }
    test("missing credentials issue and store once with immutable reference evidence") {
        runTest {
            fixture(this).use { f ->
                val value = credentials()
                f.issuer.enqueue(IdentityIssueResult.Success(value))
                f.readyScript()
                f.registrar.start()
                runCurrent()
                f.ledger.actions.count { it is RegistrarAction.IssueIdentity } shouldBe 1
                val store =
                    f.ledger.actions
                        .filterIsInstance<RegistrarAction.StoreCredentials>()
                        .single()
                val create =
                    f.ledger.actions
                        .filterIsInstance<RegistrarAction.CreateRuntime>()
                        .single()
                store.referenceId shouldBe create.credentialReferenceId
                val bodies = f.harness.finishedLogs().mapNotNull { it.bodyValue?.asString() }
                bodies.contains("Loading the saved service identity") shouldBe true
                bodies.contains("Requesting a new service identity") shouldBe true
                bodies.contains("Service registration is ready") shouldBe true
            }
        }
    }
    test("ambiguous issuance is terminal and does not auto retry") {
        runTest {
            fixture(this).use { f ->
                f.issuer.enqueue(IdentityIssueResult.Failure(IdentityIssueError.Unavailable(true)))
                f.registrar.start()
                runCurrent()
                advanceTimeBy(10_000)
                runCurrent()
                (f.registrar.states.value.state as RegistrarState.Failed).identityOutcomeMayBeAmbiguous shouldBe true
                f.ledger.actions.count { it is RegistrarAction.IssueIdentity } shouldBe 1
                f.harness
                    .finishedLogs()
                    .last()
                    .bodyValue
                    ?.asString() shouldBe "Service registration failed"
            }
        }
    }
    test("explicit retry issues after a terminal issue failure") {
        runTest {
            fixture(this).use { f ->
                f.issuer.enqueue(IdentityIssueResult.Failure(IdentityIssueError.Rejected(IdentityRejectionReason.MALFORMED_REQUEST)))
                f.issuer.enqueue(IdentityIssueResult.Success(credentials()))
                f.readyScript()
                f.registrar.start()
                runCurrent()
                f.registrar.retry()
                runCurrent()
                f.ledger.actions.count { it is RegistrarAction.IssueIdentity } shouldBe 2
            }
        }
    }
    test("terminal store failure retains exact credentials for explicit retry") {
        runTest {
            fixture(this).use { f ->
                val value = credentials()
                f.issuer.enqueue(IdentityIssueResult.Success(value))
                f.storage.enqueueStore(CredentialStoreResult.Failure(CredentialStorageError.Corrupt("bad")))
                f.storage.enqueueStore(CredentialStoreResult.Success)
                f.readyScript()
                f.registrar.start()
                runCurrent()
                f.registrar.retry()
                runCurrent()
                f.ledger.actions
                    .filterIsInstance<RegistrarAction.StoreCredentials>()
                    .map { it.referenceId }
                    .distinct()
                    .size shouldBe 1
                f.ledger.actions.count { it is RegistrarAction.IssueIdentity } shouldBe 1
            }
        }
    }
    test("recoverable store failure retains credentials and grows storage backoff") {
        runTest {
            fixture(this).use { f ->
                f.issuer.enqueue(IdentityIssueResult.Success(credentials()))
                f.storage.enqueueStore(CredentialStoreResult.Failure(CredentialStorageError.Unavailable("one")))
                f.storage.enqueueStore(CredentialStoreResult.Failure(CredentialStorageError.Unavailable("two")))
                f.storage.enqueueStore(CredentialStoreResult.Success)
                f.readyScript()
                f.registrar.start()
                runCurrent()
                f.ledger.actions
                    .filterIsInstance<RegistrarAction.Delay>()
                    .map { it.duration } shouldBe listOf(1.seconds, 2.seconds)
                f.harness
                    .finishedLogs()
                    .mapNotNull { it.bodyValue?.asString() }
                    .count { it.startsWith("Service registration is unavailable") } shouldBe 2
            }
        }
    }
    test("corrupt load is terminal while unavailable load retries") {
        runTest {
            fixture(this, CredentialLoadResult.Failure(CredentialStorageError.Corrupt("bad"))).use { f ->
                f.registrar.start()
                runCurrent()
                f.registrar.states.value.state
                    .shouldBeInstanceOf<RegistrarState.Failed>()
            }
            fixture(this, CredentialLoadResult.Failure(CredentialStorageError.Unavailable("down"))).use { f ->
                f.storage.enqueueLoad(CredentialLoadResult.Loaded(credentials()))
                f.readyScript()
                f.registrar.start()
                runCurrent()
                f.ledger.actions.any { it is RegistrarAction.Delay } shouldBe true
            }
        }
    }
    test("initial bound observation reaches ready and heartbeat is immediate") {
        runTest {
            fixture(this, CredentialLoadResult.Loaded(credentials())).use { f ->
                f.readyScript()
                f.registrar.start()
                runCurrent()
                f.registrar.states.value.state
                    .shouldBeInstanceOf<RegistrarState.Ready>()
                f.ledger.actions.count { it == RegistrarAction.Heartbeat } shouldBe 1
            }
        }
    }
    test("attempt span inherits the start caller and ends when ready supervision begins") {
        runTest {
            fixture(this, CredentialLoadResult.Loaded(credentials())).use { f ->
                f.readyScript()
                val parent =
                    f.harness.openTelemetry.tracerProvider
                        .get("test")
                        .spanBuilder("realm.start")
                        .startSpan()
                parent.makeCurrent().use { f.registrar.start() }
                runCurrent()
                parent.end()

                val attempt = f.harness.finishedSpans().single { it.name == "registrar.attempt" }
                attempt.parentSpanId shouldBe parent.spanContext.spanId
                attempt.spanContext.traceId shouldBe parent.spanContext.traceId
                f.harness.activeSpanCount() shouldBe 0
                f.registrar.states.value.state
                    .shouldBeInstanceOf<RegistrarState.Ready>()
            }
        }
    }
    test("initial unbound null token is defensively published") {
        runTest {
            fixture(this, CredentialLoadResult.Loaded(credentials())).use { f ->
                f.runtime.enqueueWatch(RuntimeResult.Success(BindingObservation.Initial(BindingStatus.Unbound(null))))
                f.runtime.setConnectivity(RuntimeConnectivity.CONNECTED)
                f.factory.enqueue(RuntimeCreateResult.Success(f.runtime))
                f.registrar.start()
                runCurrent()
                (f.registrar.states.value.state as RegistrarState.AwaitingBinding).registrationToken shouldBe null
            }
        }
    }
    test("binding notification reauthorizes and confirms binding") {
        runTest {
            fixture(this, CredentialLoadResult.Loaded(credentials())).use { f ->
                f.runtime.enqueueWatch(RuntimeResult.Success(BindingObservation.Bound(binding())))
                f.runtime.enqueueQuery(RuntimeResult.Success(BindingStatus.Bound(binding())))
                f.runtime.setConnectivity(RuntimeConnectivity.CONNECTED)
                f.factory.enqueue(RuntimeCreateResult.Success(f.runtime))
                f.registrar.start()
                runCurrent()
                f.ledger.actions.any { it == RegistrarAction.Reconnect } shouldBe true
                f.registrar.states.value.state
                    .shouldBeInstanceOf<RegistrarState.Ready>()
            }
        }
    }
    test("binding refresh queries while awaiting notification") {
        runTest {
            fixture(this, CredentialLoadResult.Loaded(credentials())).use { f ->
                f.runtime.enqueueWatch()
                f.runtime.enqueueQuery(RuntimeResult.Success(BindingStatus.Unbound(RegistrationToken("next"))))
                f.runtime.setConnectivity(RuntimeConnectivity.CONNECTED)
                f.factory.enqueue(RuntimeCreateResult.Success(f.runtime))
                f.registrar.start()
                runCurrent()
                advanceTimeBy(101)
                runCurrent()
                f.ledger.actions.any { it == RegistrarAction.QueryBinding } shouldBe true
            }
        }
    }
    test("heartbeat is periodic and no binding calls occur after ready") {
        runTest {
            fixture(this, CredentialLoadResult.Loaded(credentials())).use { f ->
                f.readyScript()
                f.registrar.start()
                runCurrent()
                val bindingCalls = f.bindingCallCount
                advanceTimeBy(101)
                runCurrent()
                f.ledger.actions.count { it == RegistrarAction.Heartbeat } shouldBe 2
                f.bindingCallCount shouldBe bindingCalls
            }
        }
    }
    test("periodic heartbeat is a bounded root span") {
        runTest {
            fixture(this, CredentialLoadResult.Loaded(credentials())).use { f ->
                f.readyScript()
                f.registrar.start()
                runCurrent()
                f.harness.clear()

                advanceTimeBy(101)
                runCurrent()

                val heartbeat = f.harness.finishedSpans().single { it.name == "registrar.heartbeat" }
                heartbeat.parentSpanId shouldBe SpanId.getInvalid()
                f.harness.activeSpanCount() shouldBe 0
            }
        }
    }
    test("heartbeat failure degrades with the same session") {
        runTest {
            fixture(this, CredentialLoadResult.Loaded(credentials())).use { f ->
                f.runtime.enqueueHeartbeat(RuntimeResult.Failure(RegistrarFailure.Messaging(MessagingOperation.HEARTBEAT)))
                f.readyScript()
                f.registrar.start()
                runCurrent()
                f.ledger.actions.any { it is RegistrarAction.Delay } shouldBe true
                val ready = f.registrar.states.value.state as RegistrarState.Ready
                ready.session.shouldBeInstanceOf<ReadySession>()
            }
        }
    }
    test("connectivity recovery increments generation") {
        runTest {
            fixture(this, CredentialLoadResult.Loaded(credentials())).use { f ->
                f.readyScript()
                f.registrar.start()
                runCurrent()
                f.runtime.setConnectivity(RuntimeConnectivity.DISCONNECTED)
                runCurrent()
                f.runtime.setConnectivity(RuntimeConnectivity.CONNECTED)
                runCurrent()
                (f.registrar.states.value.state as RegistrarState.Ready).connectionGeneration shouldBe 2
            }
        }
    }
    test("connectivity recovery is a bounded root span") {
        runTest {
            fixture(this, CredentialLoadResult.Loaded(credentials())).use { f ->
                f.readyScript()
                f.registrar.start()
                runCurrent()
                f.harness.clear()

                f.runtime.setConnectivity(RuntimeConnectivity.DISCONNECTED)
                runCurrent()
                f.runtime.setConnectivity(RuntimeConnectivity.CONNECTED)
                runCurrent()

                val recovery = f.harness.finishedSpans().single { it.name == "registrar.recovery" }
                recovery.parentSpanId shouldBe SpanId.getInvalid()
                f.harness.activeSpanCount() shouldBe 0
            }
        }
    }
    test("multiple awaiters share session and cancelling one does not cancel supervisor") {
        runTest {
            fixture(this, CredentialLoadResult.Loaded(credentials())).use { f ->
                val cancelled = launch { f.registrar.awaitReady() }
                val survivor = async { f.registrar.awaitReady() }
                cancelled.cancelAndJoin()
                f.readyScript()
                f.registrar.start()
                runCurrent()
                survivor.await().shouldBeInstanceOf<RegistrarResult.Success<ReadySession>>()
                f.registrar.states.value.state
                    .shouldBeInstanceOf<RegistrarState.Ready>()
            }
        }
    }
    test("await during degraded waits for recovery") {
        runTest {
            fixture(this, CredentialLoadResult.Loaded(credentials())).use { f ->
                f.runtime.enqueueHeartbeat(RuntimeResult.Failure(RegistrarFailure.Messaging(MessagingOperation.HEARTBEAT)))
                f.readyScript()
                f.registrar.start()
                runCurrent()
                val waiter = async { f.registrar.awaitReady() }
                waiter.isCompleted shouldBe false
                runCurrent()
                waiter.await().shouldBeInstanceOf<RegistrarResult.Success<ReadySession>>()
            }
        }
    }
    test("stop orders shutdown before close and prevents further heartbeat") {
        runTest {
            fixture(this, CredentialLoadResult.Loaded(credentials())).use { f ->
                f.readyScript()
                f.registrar.start()
                runCurrent()
                f.registrar.stop()
                val count =
                    f.ledger.actions.count {
                        it ==
                            RegistrarAction.Heartbeat
                    }
                advanceTimeBy(1_000)
                runCurrent()
                f.ledger.actions.count { it == RegistrarAction.Heartbeat } shouldBe count
                (f.ledger.actions.indexOf(RegistrarAction.Shutdown) < f.ledger.actions.indexOf(RegistrarAction.Close)) shouldBe true
                f.harness.assertNoActiveSpans()
            }
        }
    }
    test("stop aggregates shutdown and close failures") {
        runTest {
            fixture(this, CredentialLoadResult.Loaded(credentials())).use { f ->
                f.runtime.enqueueShutdown(RuntimeResult.Failure(RegistrarFailure.Messaging(MessagingOperation.HEARTBEAT)))
                f.runtime.closeResult = RuntimeCloseResult.Failure(listOf(RegistrarStopFailure.Internal("close")))
                f.readyScript()
                f.registrar.start()
                runCurrent()
                val result = f.registrar.stop() as RegistrarStopResult.Failure
                result.failures.size shouldBe 2
            }
        }
    }
    test("state sequences and retry attempts are monotonic") {
        runTest {
            fixture(this).use { f ->
                f.issuer.enqueue(IdentityIssueResult.Success(credentials()))
                f.storage.enqueueStore(CredentialStoreResult.Failure(CredentialStorageError.Unavailable("x")))
                f.readyScript()
                val seen = mutableListOf<RegistrarSnapshot>()
                val collect = launch { f.registrar.states.collect { seen += it } }
                f.registrar.start()
                runCurrent()
                collect.cancelAndJoin()
                seen.zipWithNext().all { (a, b) -> b.sequence > a.sequence && b.attempt >= a.attempt } shouldBe true
            }
        }
    }
    test("public diagnostics redact tokens and credential secrets") {
        runTest {
            credentials().toString().contains("password") shouldBe false
            RegistrarState.AwaitingBinding(identity(), RegistrationToken("secret")).toString().contains("secret") shouldBe false
            fixture(this).use { f ->
                f.runtime.enqueueWatch(
                    RuntimeResult.Success(
                        BindingObservation.Initial(BindingStatus.Unbound(RegistrationToken("registration-secret"))),
                    ),
                )
                f.runtime.setConnectivity(RuntimeConnectivity.CONNECTED)
                f.factory.enqueue(RuntimeCreateResult.Success(f.runtime))
                f.issuer.enqueue(IdentityIssueResult.Success(credentials()))
                f.registrar.start()
                runCurrent()

                val exported = f.harness.finishedLogs().joinToString { "${it.bodyValue} ${it.attributes.asMap()}" }
                exported.contains("registration-secret") shouldBe false
                exported.contains("password") shouldBe false
            }
        }
    }
}

private class Fixture(
    scope: kotlinx.coroutines.CoroutineScope,
    private val initial: CredentialLoadResult,
) : AutoCloseable {
    private val registrarScope = kotlinx.coroutines.CoroutineScope(scope.coroutineContext + SupervisorJob())
    val harness = TelemetryTestHarness.create()
    val ledger = RegistrarActionLedger()
    val storage = FakeCredentialStorage(initial, ledger)
    val issuer = FakeIdentityIssuer(ledger)
    val runtime = FakeRegistrarRuntime(Communicator(FakeMessageTransport(), harness.telemetry, ContextPropagators.noop()), ledger)
    val factory = FakeRegistrarRuntimeFactory(ledger)
    val registrar =
        ServiceRegistrar(
            configuration(),
            registrarScope,
            storage,
            issuer,
            factory,
            harness.telemetry,
            FakeRetryRandom(listOf(.5), ledger),
            FakeRegistrarDelay(ledger = ledger),
        )
    val bindingCallCount get() =
        ledger.actions.count {
            it is RegistrarAction.WatchBinding || it == RegistrarAction.QueryBinding ||
                it == RegistrarAction.Reconnect
        }

    fun readyScript() {
        if (initialMissing()) issuer.enqueue(IdentityIssueResult.Success(credentials()))
        runtime.enqueueWatch(RuntimeResult.Success(BindingObservation.Initial(BindingStatus.Bound(binding()))))
        runtime.enqueueQuery(RuntimeResult.Success(BindingStatus.Bound(binding())))
        runtime.setConnectivity(RuntimeConnectivity.CONNECTED)
        factory.enqueue(RuntimeCreateResult.Success(runtime))
    }

    private fun initialMissing() = initial is CredentialLoadResult.Missing

    override fun close() {
        registrarScope.cancel()
        harness.close()
    }
}

private fun fixture(
    scope: kotlinx.coroutines.CoroutineScope,
    initial: CredentialLoadResult = CredentialLoadResult.Missing,
) = Fixture(scope, initial)

private fun identity() = ServiceIdentity("service", "Service", "user", listOf(ServiceRole.Engine("1")))

private fun credentials() = IdentityCredentials(identity(), RedactedSecret.AppPassword("password"))

private fun binding() = OrganizationBinding("organization", "Organization")

private fun configuration() =
    RegistrarConfiguration(
        URI("https://example.test/issue"),
        URI("https://example.test/sentinel"),
        URI("https://example.test/token"),
        "client",
        setOf("openid"),
        URI("nats://example.test"),
        listOf(ServiceRole.Engine("1")),
        bindingRefreshInterval = 100.milliseconds,
        heartbeatInterval = 100.milliseconds,
        shutdownTimeout = 100.milliseconds,
        retryPolicy = RetryPolicy.exponential(1.seconds, 8.seconds, jitterRatio = 0.0),
    )
