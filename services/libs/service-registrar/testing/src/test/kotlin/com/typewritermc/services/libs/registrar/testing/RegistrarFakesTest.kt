@file:OptIn(kotlinx.coroutines.ExperimentalCoroutinesApi::class)

package com.typewritermc.services.libs.registrar.testing

import com.typewritermc.services.libs.communicator.client.Communicator
import com.typewritermc.services.libs.communicator.testing.FakeMessageTransport
import com.typewritermc.services.libs.registrar.BindingObservation
import com.typewritermc.services.libs.registrar.RuntimeResult
import com.typewritermc.services.libs.telemetry.testing.TelemetryTestHarness
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.matchers.shouldBe
import io.opentelemetry.context.propagation.ContextPropagators
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.launch
import kotlinx.coroutines.test.runCurrent
import kotlinx.coroutines.test.runTest

val RegistrarFakesTest by testSuite {
    test("binding watches are independent cold collections with cancellation evidence") {
        runTest {
            TelemetryTestHarness.create().use { harness ->
                val runtime = FakeRegistrarRuntime(
                    Communicator(FakeMessageTransport(), harness.telemetry, ContextPropagators.noop()),
                )
                runtime.enqueueWatch(RuntimeResult.Success(BindingObservation.Initial(com.typewritermc.services.libs.registrar.BindingStatus.Unbound(null))))
                val cold = runtime.watchBinding()
                runtime.actions shouldBe emptyList()
                val collector = launch { cold.first() }
                runCurrent()
                runtime.activeWatchCount shouldBe 0
                runtime.actions.map { it::class } shouldBe listOf(
                    RegistrarAction.WatchBinding::class,
                    RegistrarAction.CancelBindingWatch::class,
                )
                collector.join()
            }
        }
    }

    test("all fakes can record in one thread-safe ordered ledger") {
        runTest {
            val ledger = RegistrarActionLedger()
            FakeCredentialStorage(ledger = ledger).load()
            FakeRegistrarDelay(ledger = ledger).delay(kotlin.time.Duration.ZERO)
            ledger.actions shouldBe listOf(RegistrarAction.LoadCredentials, RegistrarAction.Delay(kotlin.time.Duration.ZERO))
            val snapshot = ledger.actions
            FakeCredentialStorage(ledger = ledger).load()
            snapshot.size shouldBe 2
        }
    }
}
