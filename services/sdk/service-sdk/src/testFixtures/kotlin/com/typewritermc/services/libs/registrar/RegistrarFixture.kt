@file:OptIn(kotlinx.coroutines.ExperimentalCoroutinesApi::class)

package com.typewritermc.services.libs.registrar

import com.typewritermc.services.libs.communicator.client.Communicator
import com.typewritermc.services.libs.communicator.testing.FakeMessageTransport
import com.typewritermc.services.libs.registrar.testing.FakeCredentialStorage
import com.typewritermc.services.libs.registrar.testing.FakeIdentityIssuer
import com.typewritermc.services.libs.registrar.testing.FakeRegistrarRuntime
import com.typewritermc.services.libs.registrar.testing.FakeRegistrarRuntimeFactory
import com.typewritermc.services.libs.registrar.testing.FakeRetryRandom
import com.typewritermc.services.libs.registrar.testing.RegistrarAction
import com.typewritermc.services.libs.registrar.testing.RegistrarActionLedger
import com.typewritermc.services.libs.telemetry.testing.TelemetryTestHarness
import com.typewritermc.services.libs.utils.FakeDelayScheduler
import com.typewritermc.services.libs.utils.RetryPolicy
import io.opentelemetry.context.propagation.ContextPropagators
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.cancel
import kotlinx.coroutines.test.TestScope
import kotlinx.coroutines.test.runCurrent
import java.net.URI
import kotlin.time.Duration
import kotlin.time.Duration.Companion.milliseconds
import kotlin.time.Duration.Companion.seconds
import kotlin.time.TestTimeSource

/** A registrar wired to fakes that share one ledger, with its telemetry harness; closing it stops the registrar scope. */
class RegistrarFixture(
    scope: kotlinx.coroutines.CoroutineScope,
    private val initial: CredentialLoadResult,
    holdDelays: Boolean,
) : AutoCloseable {
    private val registrarScope = kotlinx.coroutines.CoroutineScope(scope.coroutineContext + SupervisorJob())
    val harness = TelemetryTestHarness.create()
    val ledger = RegistrarActionLedger()
    val storage = FakeCredentialStorage(initial, ledger)
    val issuer = FakeIdentityIssuer(ledger)
    val runtime = FakeRegistrarRuntime(Communicator(FakeMessageTransport(), harness.telemetry, ContextPropagators.noop()), ledger)
    val factory = FakeRegistrarRuntimeFactory(ledger)
    val delays = FakeDelayScheduler(holdDelays) { ledger.record(RegistrarAction.Delay(it)) }
    val registrar =
        ServiceRegistrar(
            registrarConfiguration(),
            registrarScope,
            storage,
            issuer,
            factory,
            harness.telemetry,
            RetryPolicy.exponential(1.seconds, 8.seconds, jitterRatio = 0.0),
            delays,
            TestTimeSource(),
            FakeRetryRandom(listOf(.5), ledger),
        )
    val bindingCallCount get() =
        ledger.actions.count {
            it is RegistrarAction.WatchBinding || it == RegistrarAction.QueryBinding ||
                it == RegistrarAction.Reconnect
        }

    fun readyScript() {
        if (initialMissing()) issuer.enqueue(IdentityIssueResult.Success(registrarCredentials()))
        runtime.enqueueLease(RuntimeResult.Success(RegistrationLeaseResult.Issued(RegistrationToken("token"))))
        runtime.enqueueWatch(RuntimeResult.Success(BindingObservation.Initial(BindingStatus.Bound(registrarBinding()))))
        runtime.enqueueQuery(RuntimeResult.Success(BindingStatus.Bound(registrarBinding())))
        runtime.setConnectivity(RuntimeConnectivity.CONNECTED)
        factory.enqueue(RuntimeCreateResult.Success(runtime))
    }

    /** Starts the registrar to ready, then drops and restores its connection, so the second generation is ready. */
    suspend fun readyThenReconnected(test: TestScope) {
        readyScript()
        registrar.start()
        test.runCurrent()
        runtime.setConnectivity(RuntimeConnectivity.DISCONNECTED)
        test.runCurrent()
        runtime.setConnectivity(RuntimeConnectivity.CONNECTED)
        test.runCurrent()
    }

    fun runtime(runtimeLedger: RegistrarActionLedger): FakeRegistrarRuntime =
        FakeRegistrarRuntime(
            Communicator(
                FakeMessageTransport(),
                harness.telemetry,
                ContextPropagators.noop(),
            ),
            runtimeLedger,
        )

    /** Scripts the next runtime the factory creates as connected and bound, with its own ledger. */
    fun boundReplacement(): FakeRegistrarRuntime {
        val replacement = runtime(RegistrarActionLedger())
        replacement.setConnectivity(RuntimeConnectivity.CONNECTED)
        replacement.enqueueQuery(RuntimeResult.Success(BindingStatus.Bound(registrarBinding())))
        factory.enqueue(RuntimeCreateResult.Success(replacement))
        return replacement
    }

    private fun initialMissing() = initial is CredentialLoadResult.Missing

    override fun close() {
        registrarScope.cancel()
        harness.close()
    }
}

fun registrarFixture(
    scope: kotlinx.coroutines.CoroutineScope,
    initial: CredentialLoadResult = CredentialLoadResult.Missing,
    holdDelays: Boolean = false,
) = RegistrarFixture(scope, initial, holdDelays)

fun registrarIdentity() = ServiceIdentity(ServiceId("service"), "Service", "user", ServiceRole.Host("1"))

fun registrarCredentials() = IdentityCredentials(registrarIdentity(), RedactedSecret.AppPassword("password"))

fun registrarBinding() = OrganizationBinding("organization", "Organization")

/** A configuration with the test endpoints; the refresh, heartbeat and shutdown intervals default to 100 milliseconds. */
fun registrarConfiguration(
    role: ServiceRole = ServiceRole.Host("1"),
    identityUri: URI = URI("https://example.test/issue"),
    bindingRefresh: Duration = 100.milliseconds,
    heartbeat: Duration = 100.milliseconds,
    shutdown: Duration = 100.milliseconds,
) = RegistrarConfiguration(
    identityUri,
    URI("https://example.test/sentinel"),
    URI("https://example.test/token"),
    "client",
    setOf("openid"),
    URI("nats://example.test"),
    role,
    bindingRefreshInterval = bindingRefresh,
    heartbeatInterval = heartbeat,
    shutdownTimeout = shutdown,
)
