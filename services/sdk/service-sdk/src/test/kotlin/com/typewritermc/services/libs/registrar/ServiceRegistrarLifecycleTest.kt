@file:OptIn(kotlinx.coroutines.ExperimentalCoroutinesApi::class)

package com.typewritermc.services.libs.registrar

import com.typewritermc.services.libs.communicator.client.Communicator
import com.typewritermc.services.libs.registrar.testing.RegistrarAction
import com.typewritermc.services.libs.registrar.testing.RegistrarActionLedger
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.matchers.collections.shouldContainInOrder
import io.kotest.matchers.collections.shouldHaveSize
import io.kotest.matchers.comparables.shouldBeGreaterThan
import io.kotest.matchers.comparables.shouldBeGreaterThanOrEqualTo
import io.kotest.matchers.shouldBe
import io.kotest.matchers.types.shouldBeInstanceOf
import io.kotest.matchers.types.shouldBeSameInstanceAs
import io.opentelemetry.api.trace.SpanId
import kotlinx.coroutines.async
import kotlinx.coroutines.cancel
import kotlinx.coroutines.cancelAndJoin
import kotlinx.coroutines.flow.collect
import kotlinx.coroutines.launch
import kotlinx.coroutines.test.UnconfinedTestDispatcher
import kotlinx.coroutines.test.advanceTimeBy
import kotlinx.coroutines.test.runCurrent
import kotlinx.coroutines.test.runTest
import kotlin.time.Duration.Companion.seconds

val ServiceRegistrarLifecycleTest by testSuite {
    val lifecycleLogs =
        setOf(
            "Loading the saved service identity",
            "Requesting a new service identity",
            "Service registration is ready",
            "Stopping service registration",
            "Service registration stopped",
        )

    test("concurrent start is idempotent and loads once") {
        runTest {
            registrarFixture(this).use { f ->
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
            registrarFixture(this).use { f ->
                f.registrar.stop() shouldBe RegistrarStopResult.Success
                f.registrar.start().shouldBeInstanceOf<RegistrarResult.Failure>()
            }
        }
    }
    test("a second stop after a ready stop succeeds without cleaning up again") {
        runTest {
            registrarFixture(this, CredentialLoadResult.Loaded(registrarCredentials())).use { f ->
                f.readyScript()
                f.registrar.start()
                runCurrent()

                f.registrar.stop() shouldBe RegistrarStopResult.Success
                f.registrar.stop() shouldBe RegistrarStopResult.Success

                f.ledger.actions.count { it == RegistrarAction.Shutdown } shouldBe 1
                f.ledger.actions.count { it == RegistrarAction.Close } shouldBe 1
            }
        }
    }
    test("concurrent stops clean up the runtime exactly once") {
        runTest {
            registrarFixture(this, CredentialLoadResult.Loaded(registrarCredentials())).use { f ->
                f.readyScript()
                f.registrar.start()
                runCurrent()

                List(10) { async { f.registrar.stop() } }.forEach { it.await() shouldBe RegistrarStopResult.Success }

                f.ledger.actions.count { it == RegistrarAction.Shutdown } shouldBe 1
                f.ledger.actions.count { it == RegistrarAction.Close } shouldBe 1
                f.registrar.states.value.state
                    .shouldBeInstanceOf<RegistrarState.Stopped>()
            }
        }
    }
    test("stored credentials skip identity issuance") {
        runTest {
            registrarFixture(this, CredentialLoadResult.Loaded(registrarCredentials())).use { f ->
                f.readyScript()
                f.registrar.start()
                runCurrent()
                f.ledger.actions.none { it is RegistrarAction.IssueIdentity } shouldBe true
            }
        }
    }
    test("missing credentials are issued once, stored and used to reach ready") {
        runTest {
            registrarFixture(this).use { f ->
                val issued = registrarCredentials()
                f.issuer.enqueue(IdentityIssueResult.Success(issued))
                f.readyScript()
                f.registrar.start()
                runCurrent()
                f.ledger.actions.count { it is RegistrarAction.IssueIdentity } shouldBe 1
                f.storage.stored.single() shouldBeSameInstanceAs issued
                f.registrar.states.value.state
                    .shouldBeInstanceOf<RegistrarState.Ready>()
                    .session.identity shouldBeSameInstanceAs issued.identity
            }
        }
    }
    test("ambiguous issuance is terminal and does not auto retry") {
        runTest {
            registrarFixture(this).use { f ->
                f.issuer.enqueue(IdentityIssueResult.Failure(IdentityIssueError.Unavailable(true)))
                f.registrar.start()
                runCurrent()
                advanceTimeBy(10_000)
                runCurrent()
                f.registrar.states.value.state
                    .shouldBeInstanceOf<RegistrarState.IdentityOutcomeUnknown>()
                f.ledger.actions.count { it is RegistrarAction.IssueIdentity } shouldBe 1
                f.harness
                    .finishedLogs()
                    .last()
                    .bodyValue
                    ?.asString() shouldBe "Service identity issuance outcome is unknown: identity_issuance: unavailable"
            }
        }
    }
    test("explicit retry issues after a terminal issue failure") {
        runTest {
            registrarFixture(this).use { f ->
                f.issuer.enqueue(IdentityIssueResult.Failure(IdentityIssueError.Rejected(IdentityRejectionReason.MALFORMED_REQUEST)))
                f.issuer.enqueue(IdentityIssueResult.Success(registrarCredentials()))
                f.readyScript()
                f.registrar.start()
                runCurrent()
                f.registrar.retry()
                runCurrent()
                f.ledger.actions.count { it is RegistrarAction.IssueIdentity } shouldBe 2
            }
        }
    }
    test("concurrent retry and stop serialize without restarting after stop") {
        runTest {
            registrarFixture(this).use { f ->
                f.issuer.enqueue(IdentityIssueResult.Failure(IdentityIssueError.Rejected(IdentityRejectionReason.MALFORMED_REQUEST)))
                f.issuer.enqueue(IdentityIssueResult.Success(registrarCredentials()))
                f.readyScript()
                f.registrar.start()
                runCurrent()

                val retry = async { f.registrar.retry() }
                val stop = async { f.registrar.stop() }
                retry.await()
                stop.await() shouldBe RegistrarStopResult.Success
                runCurrent()

                f.registrar.states.value.state
                    .shouldBeInstanceOf<RegistrarState.Stopped>()
                f.registrar.start().shouldBeInstanceOf<RegistrarResult.Failure>()
                (f.ledger.actions.count { it == RegistrarAction.Close } <= 1) shouldBe true
            }
        }
    }
    test("terminal store failure keeps the issued credentials for an explicit retry") {
        runTest {
            registrarFixture(this).use { f ->
                val issued = registrarCredentials()
                f.issuer.enqueue(IdentityIssueResult.Success(issued))
                f.storage.enqueueStore(CredentialStoreResult.Failure(CredentialStorageError.Corrupt("bad")))
                f.storage.enqueueStore(CredentialStoreResult.Success)
                f.readyScript()
                f.registrar.start()
                runCurrent()
                f.registrar.retry()
                runCurrent()
                f.storage.stored shouldHaveSize 2
                f.storage.stored.forEach { it shouldBeSameInstanceAs issued }
                f.ledger.actions.count { it is RegistrarAction.IssueIdentity } shouldBe 1
                f.registrar.states.value.state
                    .shouldBeInstanceOf<RegistrarState.Ready>()
            }
        }
    }
    test("recoverable store failure retains credentials and grows storage backoff") {
        runTest {
            registrarFixture(this).use { f ->
                f.issuer.enqueue(IdentityIssueResult.Success(registrarCredentials()))
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
    test("a corrupt credential file fails registration") {
        runTest {
            registrarFixture(this, CredentialLoadResult.Failure(CredentialStorageError.Corrupt("bad"))).use { f ->
                f.registrar.start()
                runCurrent()
                f.registrar.states.value.state shouldBe
                    RegistrarState.Failed(RegistrarFailure.CredentialStorage(CredentialStorageError.Corrupt("bad")))
                f.ledger.actions.none { it is RegistrarAction.Delay } shouldBe true
            }
        }
    }
    test("an unavailable credential file is loaded again after a delay and reaches ready") {
        runTest {
            registrarFixture(this, CredentialLoadResult.Failure(CredentialStorageError.Unavailable("down"))).use { f ->
                f.storage.enqueueLoad(CredentialLoadResult.Loaded(registrarCredentials()))
                f.readyScript()
                f.registrar.start()
                runCurrent()
                f.ledger.actions.count { it == RegistrarAction.LoadCredentials } shouldBe 2
                f.ledger.actions.filterIsInstance<RegistrarAction.Delay>() shouldHaveSize 1
                f.registrar.states.value.state
                    .shouldBeInstanceOf<RegistrarState.Ready>()
            }
        }
    }
    test("initial bound observation reaches ready and heartbeat is immediate") {
        runTest {
            registrarFixture(this, CredentialLoadResult.Loaded(registrarCredentials())).use { f ->
                f.readyScript()
                f.registrar.start()
                runCurrent()
                f.registrar.states.value.state
                    .shouldBeInstanceOf<RegistrarState.Ready>()
                f.ledger.actions.count { it == RegistrarAction.Heartbeat } shouldBe 1
            }
        }
    }
    test("lease command resolves a concurrent bind without opening a watch") {
        runTest {
            registrarFixture(this, CredentialLoadResult.Loaded(registrarCredentials())).use { f ->
                f.runtime.enqueueLease(RuntimeResult.Success(RegistrationLeaseResult.AlreadyBound(registrarBinding())))
                f.runtime.enqueueQuery(RuntimeResult.Success(BindingStatus.Bound(registrarBinding())))
                f.runtime.setConnectivity(RuntimeConnectivity.CONNECTED)
                f.factory.enqueue(RuntimeCreateResult.Success(f.runtime))

                f.registrar.start()
                runCurrent()

                f.registrar.states.value.state
                    .shouldBeInstanceOf<RegistrarState.Ready>()
                f.ledger.actions.count { it == RegistrarAction.EnsureRegistrationLease } shouldBe 1
                f.ledger.actions.none { it is RegistrarAction.WatchBinding } shouldBe true
            }
        }
    }
    test("attempt span inherits the start caller and ends when ready supervision begins") {
        runTest {
            registrarFixture(this, CredentialLoadResult.Loaded(registrarCredentials())).use { f ->
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
    test("pure unbound observation retains the issued lease token") {
        runTest {
            registrarFixture(this, CredentialLoadResult.Loaded(registrarCredentials())).use { f ->
                f.runtime.enqueueLease(RuntimeResult.Success(RegistrationLeaseResult.Issued(RegistrationToken("token"))))
                f.runtime.enqueueWatch(RuntimeResult.Success(BindingObservation.Initial(BindingStatus.Unbound)))
                f.runtime.setConnectivity(RuntimeConnectivity.CONNECTED)
                f.factory.enqueue(RuntimeCreateResult.Success(f.runtime))
                f.registrar.start()
                runCurrent()
                (f.registrar.states.value.state as RegistrarState.AwaitingBinding).registrationToken shouldBe RegistrationToken("token")
                f.runtime.activeWatchCount shouldBe 1
                f.ledger.actions.count { it is RegistrarAction.WatchBinding } shouldBe 1
            }
        }
    }
    test("binding notification reauthorizes and confirms binding") {
        runTest {
            registrarFixture(this, CredentialLoadResult.Loaded(registrarCredentials())).use { f ->
                f.runtime.enqueueLease(RuntimeResult.Success(RegistrationLeaseResult.Issued(RegistrationToken("token"))))
                f.runtime.enqueueWatch(
                    RuntimeResult.Success(BindingObservation.Initial(BindingStatus.Unbound)),
                )
                f.runtime.enqueueQuery(RuntimeResult.Success(BindingStatus.Bound(registrarBinding())))
                f.runtime.setConnectivity(RuntimeConnectivity.CONNECTED)
                f.factory.enqueue(RuntimeCreateResult.Success(f.runtime))
                f.registrar.start()
                runCurrent()
                f.runtime.emitBinding(RuntimeResult.Success(BindingObservation.Bound(registrarBinding())))
                runCurrent()
                f.ledger.actions.any { it == RegistrarAction.Reconnect } shouldBe true
                f.registrar.states.value.state
                    .shouldBeInstanceOf<RegistrarState.Ready>()
            }
        }
    }
    test("binding refresh explicitly renews the registration lease") {
        runTest {
            registrarFixture(this, CredentialLoadResult.Loaded(registrarCredentials())).use { f ->
                f.runtime.enqueueLease(
                    RuntimeResult.Success(RegistrationLeaseResult.Issued(RegistrationToken("initial"))),
                    RuntimeResult.Success(RegistrationLeaseResult.Issued(RegistrationToken("next"))),
                )
                f.runtime.enqueueWatch(
                    RuntimeResult.Success(BindingObservation.Initial(BindingStatus.Unbound)),
                )
                f.runtime.enqueueWatch()
                f.runtime.setConnectivity(RuntimeConnectivity.CONNECTED)
                f.factory.enqueue(RuntimeCreateResult.Success(f.runtime))
                f.registrar.start()
                runCurrent()

                advanceTimeBy(99)
                runCurrent()
                f.ledger.actions.count { it == RegistrarAction.EnsureRegistrationLease } shouldBe 1
                f.ledger.actions.count { it is RegistrarAction.WatchBinding } shouldBe 1

                advanceTimeBy(2)
                runCurrent()
                f.ledger.actions.count { it == RegistrarAction.EnsureRegistrationLease } shouldBe 2
                f.ledger.actions.none { it == RegistrarAction.QueryBinding } shouldBe true
                f.ledger.actions.count { it is RegistrarAction.WatchBinding } shouldBe 2
            }
        }
    }
    test("successful lease rounds reset watch failure backoff") {
        runTest {
            registrarFixture(this, CredentialLoadResult.Loaded(registrarCredentials())).use { f ->
                f.runtime.enqueueLease(
                    RuntimeResult.Success(RegistrationLeaseResult.Issued(RegistrationToken("first"))),
                    RuntimeResult.Success(RegistrationLeaseResult.Issued(RegistrationToken("second"))),
                    RuntimeResult.Success(RegistrationLeaseResult.Issued(RegistrationToken("third"))),
                )
                f.runtime.enqueueWatch(
                    RuntimeResult.Failure(RegistrarFailure.Messaging(MessagingOperation.BINDING_WATCH)),
                )
                f.runtime.enqueueWatch(
                    RuntimeResult.Failure(RegistrarFailure.Messaging(MessagingOperation.BINDING_WATCH)),
                )
                f.runtime.enqueueWatch()
                f.runtime.setConnectivity(RuntimeConnectivity.CONNECTED)
                f.factory.enqueue(RuntimeCreateResult.Success(f.runtime))

                f.registrar.start()
                runCurrent()

                f.ledger.actions
                    .filterIsInstance<RegistrarAction.Delay>()
                    .map { it.duration } shouldBe listOf(1.seconds, 1.seconds)
            }
        }
    }
    test("repeated unbound observations log waiting once") {
        runTest {
            registrarFixture(this, CredentialLoadResult.Loaded(registrarCredentials())).use { f ->
                f.runtime.enqueueLease(RuntimeResult.Success(RegistrationLeaseResult.Issued(RegistrationToken("first"))))
                f.runtime.enqueueWatch(
                    RuntimeResult.Success(BindingObservation.Initial(BindingStatus.Unbound)),
                    RuntimeResult.Success(BindingObservation.Initial(BindingStatus.Unbound)),
                )
                f.runtime.setConnectivity(RuntimeConnectivity.CONNECTED)
                f.factory.enqueue(RuntimeCreateResult.Success(f.runtime))

                f.registrar.start()
                runCurrent()

                f.harness
                    .finishedLogs()
                    .mapNotNull { it.bodyValue?.asString() }
                    .count { it == "Waiting for service binding in the Typewriter Panel" } shouldBe 1
                (f.registrar.states.value.state as RegistrarState.AwaitingBinding).registrationToken shouldBe
                    RegistrationToken("first")
                f.ledger.actions.count { it is RegistrarAction.WatchBinding } shouldBe 1
            }
        }
    }
    test("heartbeat is periodic and no binding calls occur after ready") {
        runTest {
            registrarFixture(this, CredentialLoadResult.Loaded(registrarCredentials())).use { f ->
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
            registrarFixture(this, CredentialLoadResult.Loaded(registrarCredentials())).use { f ->
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
    test("heartbeat failure degrades and recovers with the same session") {
        runTest {
            registrarFixture(this, CredentialLoadResult.Loaded(registrarCredentials()), holdDelays = true).use { f ->
                f.runtime.enqueueHeartbeat(RuntimeResult.Failure(RegistrarFailure.Messaging(MessagingOperation.HEARTBEAT)))
                f.readyScript()
                f.registrar.start()
                runCurrent()
                val degraded =
                    f.registrar.states.value.state
                        .shouldBeInstanceOf<RegistrarState.DegradedAfterReady>()

                f.delays.resume()
                runCurrent()

                f.registrar.states.value.state
                    .shouldBeInstanceOf<RegistrarState.Ready>()
                    .session shouldBe degraded.session
            }
        }
    }
    test("a communicator is refused for a generation that is no longer ready") {
        runTest {
            registrarFixture(this, CredentialLoadResult.Loaded(registrarCredentials())).use { f ->
                f.readyThenReconnected(this)

                f.registrar.communicatorFor(1) shouldBe RegistrarResult.Failure(RegistrarFailure.Internal("ready_generation_changed"))
                f.registrar.communicatorFor(2).shouldBeInstanceOf<RegistrarResult.Success<Communicator>>()
            }
        }
    }
    test("connectivity recovery increments generation") {
        runTest {
            registrarFixture(this, CredentialLoadResult.Loaded(registrarCredentials())).use { f ->
                f.readyThenReconnected(this)
                (f.registrar.states.value.state as RegistrarState.Ready).connectionGeneration shouldBe 2
            }
        }
    }
    test("authorization rotation serves the replacement while the current runtime stays open") {
        runTest {
            registrarFixture(this, CredentialLoadResult.Loaded(registrarCredentials())).use { f ->
                f.readyScript()
                f.registrar.start()
                runCurrent()
                val replacement = f.boundReplacement()

                f.registrar.rotateAuthorization() shouldBe RegistrarResult.Success(2L)

                f.ledger.actions.count { it == RegistrarAction.Close } shouldBe 0
                replacement.actions.count { it is RegistrarAction.Connect } shouldBe 1
                replacement.actions.count { it == RegistrarAction.Heartbeat } shouldBe 1
                f.registrar.communicatorFor(2) shouldBe RegistrarResult.Success(replacement.communicator)
            }
        }
    }
    test("a failed rotation release can be released again") {
        runTest {
            registrarFixture(this, CredentialLoadResult.Loaded(registrarCredentials())).use { f ->
                f.readyScript()
                f.registrar.start()
                runCurrent()
                f.boundReplacement()
                f.registrar.rotateAuthorization() shouldBe RegistrarResult.Success(2L)

                f.runtime.closeResult = RuntimeCloseResult.Failure(listOf(RegistrarStopFailure.Internal("close")))
                f.registrar.releaseAuthorizationRotation(2).shouldBeInstanceOf<RegistrarResult.Failure>()
                f.runtime.closeResult = RuntimeCloseResult.Success
                f.registrar.releaseAuthorizationRotation(2) shouldBe RegistrarResult.Success(Unit)

                f.ledger.actions.count { it == RegistrarAction.Close } shouldBe 2
            }
        }
    }
    test("releasing a rotation twice closes the previous runtime once") {
        runTest {
            registrarFixture(this, CredentialLoadResult.Loaded(registrarCredentials())).use { f ->
                f.readyScript()
                f.registrar.start()
                runCurrent()
                f.boundReplacement()
                f.registrar.rotateAuthorization() shouldBe RegistrarResult.Success(2L)

                f.registrar.releaseAuthorizationRotation(2) shouldBe RegistrarResult.Success(Unit)
                f.registrar.releaseAuthorizationRotation(2) shouldBe RegistrarResult.Success(Unit)

                f.ledger.actions.count { it == RegistrarAction.Close } shouldBe 1
            }
        }
    }
    test("failed authorization rotation preserves the current runtime") {
        runTest {
            registrarFixture(this, CredentialLoadResult.Loaded(registrarCredentials())).use { f ->
                f.readyScript()
                f.registrar.start()
                runCurrent()
                val replacementLedger = RegistrarActionLedger()
                val replacement = f.runtime(replacementLedger)
                replacement.enqueueConnect(RuntimeResult.Failure(RegistrarFailure.Messaging(MessagingOperation.CONNECT)))
                f.factory.enqueue(RuntimeCreateResult.Success(replacement))

                f.registrar.rotateAuthorization().shouldBeInstanceOf<RegistrarResult.Failure>()

                val ready = f.registrar.states.value.state as RegistrarState.Ready
                ready.connectionGeneration shouldBe 1
                f.ledger.actions.count { it == RegistrarAction.Close } shouldBe 0
                replacementLedger.actions.count { it == RegistrarAction.Close } shouldBe 1
                f.registrar.communicatorFor(1).shouldBeInstanceOf<RegistrarResult.Success<Communicator>>()
            }
        }
    }
    test("connectivity recovery is a bounded root span") {
        runTest {
            registrarFixture(this, CredentialLoadResult.Loaded(registrarCredentials())).use { f ->
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
            registrarFixture(this, CredentialLoadResult.Loaded(registrarCredentials())).use { f ->
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
            registrarFixture(this, CredentialLoadResult.Loaded(registrarCredentials()), holdDelays = true).use { f ->
                f.runtime.enqueueHeartbeat(RuntimeResult.Failure(RegistrarFailure.Messaging(MessagingOperation.HEARTBEAT)))
                f.readyScript()
                f.registrar.start()
                runCurrent()
                f.registrar.states.value.state
                    .shouldBeInstanceOf<RegistrarState.DegradedAfterReady>()

                val waiter = async { f.registrar.awaitReady() }
                runCurrent()
                waiter.isCompleted shouldBe false

                f.delays.resume()
                waiter.await().shouldBeInstanceOf<RegistrarResult.Success<ReadySession>>()
            }
        }
    }
    test("stop announces shutdown before closing the runtime") {
        runTest {
            registrarFixture(this, CredentialLoadResult.Loaded(registrarCredentials())).use { f ->
                f.readyScript()
                f.registrar.start()
                runCurrent()
                f.registrar.stop()
                f.ledger.actions.filter { it == RegistrarAction.Shutdown || it == RegistrarAction.Close } shouldBe
                    listOf(RegistrarAction.Shutdown, RegistrarAction.Close)
                f.harness.assertNoActiveSpans()
            }
        }
    }
    test("no heartbeat is sent after stop") {
        runTest {
            registrarFixture(this, CredentialLoadResult.Loaded(registrarCredentials())).use { f ->
                f.readyScript()
                f.registrar.start()
                runCurrent()
                f.registrar.stop()
                val heartbeats = f.ledger.actions.count { it == RegistrarAction.Heartbeat }
                advanceTimeBy(1_000)
                runCurrent()
                f.ledger.actions.count { it == RegistrarAction.Heartbeat } shouldBe heartbeats
            }
        }
    }
    test("stop aggregates shutdown and close failures") {
        runTest {
            registrarFixture(this, CredentialLoadResult.Loaded(registrarCredentials())).use { f ->
                f.runtime.enqueueShutdown(RuntimeResult.Failure(RegistrarFailure.Messaging(MessagingOperation.HEARTBEAT)))
                f.runtime.closeResult = RuntimeCloseResult.Failure(listOf(RegistrarStopFailure.Internal("close")))
                f.readyScript()
                f.registrar.start()
                runCurrent()
                f.registrar.stop() shouldBe
                    RegistrarStopResult.Failure(
                        listOf(
                            RegistrarStopFailure.Runtime(RuntimeStopOperation.SHUTDOWN_FAILED),
                            RegistrarStopFailure.Internal("close"),
                        ),
                    )
            }
        }
    }
    test("state sequences and retry attempts are monotonic") {
        runTest {
            registrarFixture(this).use { f ->
                f.issuer.enqueue(IdentityIssueResult.Success(registrarCredentials()))
                f.storage.enqueueStore(CredentialStoreResult.Failure(CredentialStorageError.Unavailable("x")))
                f.readyScript()
                val seen = mutableListOf<RegistrarSnapshot>()
                val collect = launch(UnconfinedTestDispatcher(testScheduler)) { f.registrar.states.collect { seen += it } }
                f.registrar.start()
                runCurrent()
                collect.cancelAndJoin()
                seen.map { it.state::class }.shouldContainInOrder(
                    RegistrarState.Idle::class,
                    RegistrarState.DegradedBeforeReady::class,
                    RegistrarState.Ready::class,
                )
                seen.zipWithNext().forEach { (before, after) ->
                    after.sequence shouldBeGreaterThan before.sequence
                    after.attempt shouldBeGreaterThanOrEqualTo before.attempt
                }
            }
        }
    }
    test("telemetry reports the lifecycle in order") {
        runTest {
            registrarFixture(this).use { f ->
                f.readyScript()
                f.registrar.start()
                runCurrent()
                f.registrar.stop()

                f.harness
                    .finishedLogs()
                    .mapNotNull { it.bodyValue?.asString() }
                    .filter { it in lifecycleLogs } shouldBe
                    listOf(
                        "Loading the saved service identity",
                        "Requesting a new service identity",
                        "Service registration is ready",
                        "Stopping service registration",
                        "Service registration stopped",
                    )
            }
        }
    }
    test("a terminal failure tells the operator its reason on the console") {
        runTest {
            registrarFixture(this).use { f ->
                f.issuer.enqueue(IdentityIssueResult.Failure(IdentityIssueError.Rejected(IdentityRejectionReason.MALFORMED_REQUEST)))
                f.registrar.start()
                runCurrent()

                f.harness
                    .finishedLogs()
                    .mapNotNull { it.bodyValue?.asString() }
                    .last() shouldBe "Service registration failed: identity_issuance: malformed_request"
            }
        }
    }
    test("exported logs never contain the registration token or app password") {
        runTest {
            registrarFixture(this).use { f ->
                f.runtime.enqueueLease(RuntimeResult.Success(RegistrationLeaseResult.Issued(RegistrationToken("registration-secret"))))
                f.runtime.enqueueWatch(
                    RuntimeResult.Success(
                        BindingObservation.Initial(BindingStatus.Unbound),
                    ),
                )
                f.runtime.setConnectivity(RuntimeConnectivity.CONNECTED)
                f.factory.enqueue(RuntimeCreateResult.Success(f.runtime))
                f.issuer.enqueue(IdentityIssueResult.Success(registrarCredentials()))
                f.registrar.start()
                runCurrent()

                val exported = f.harness.finishedLogs().joinToString { "${it.bodyValue} ${it.attributes.asMap()}" }
                exported.contains("registration-secret") shouldBe false
                exported.contains("password") shouldBe false
            }
        }
    }
}
