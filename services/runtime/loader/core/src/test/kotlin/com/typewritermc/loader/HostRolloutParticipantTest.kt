package com.typewritermc.loader

import com.typewritermc.imprint.ArtifactId
import com.typewritermc.imprint.ArtifactVersion
import com.typewritermc.imprint.EngineManifest
import com.typewritermc.imprint.VersionConstraint
import com.typewritermc.loader.api.HostedRuntimeEntrypoint
import com.typewritermc.loader.api.RuntimeHealth
import com.typewritermc.loader.api.RuntimePlacement
import com.typewritermc.loader.api.SourcePartDisposition
import com.typewritermc.loader.rollout.HostRolloutParticipant
import com.typewritermc.loader.runtime.HostedRuntimeLoader
import com.typewritermc.loader.runtime.LoadedHostedRuntime
import com.typewritermc.loader.testing.NoZeroArgumentHostedRuntimeEntrypoint
import com.typewritermc.loader.testing.ParentHiding
import com.typewritermc.loader.testing.RUNTIME_MARKER
import com.typewritermc.loader.testing.RecordingRuntime
import com.typewritermc.loader.testing.StagingLoaders
import com.typewritermc.loader.testing.TestHostedRuntimeEntrypoint
import com.typewritermc.loader.testing.ThrowingHostedRuntimeEntrypoint
import com.typewritermc.loader.testing.activeProjection
import com.typewritermc.loader.testing.attempt
import com.typewritermc.loader.testing.participantFixture
import com.typewritermc.loader.testing.writeRuntimeJar
import com.typewritermc.protocol.transport.RealmRouteScope
import com.typewritermc.protocol.transport.generated.rolloutCommand
import com.typewritermc.protocol.transport.generated.rolloutProbe
import com.typewritermc.protocol.transport.generated.rolloutStatus
import com.typewritermc.protocol.transport.generated.serviceReplyInboxPrefix
import com.typewritermc.services.libs.communicator.address.MessageAddress
import com.typewritermc.services.libs.communicator.client.Communicator
import com.typewritermc.services.libs.communicator.router.RouterResult
import com.typewritermc.services.libs.communicator.router.RouterState
import com.typewritermc.services.libs.communicator.router.communicatorRoutes
import com.typewritermc.services.libs.communicator.testing.FakeMessageTransport
import com.typewritermc.services.libs.communicator.transport.InboundMessage
import com.typewritermc.services.libs.communicator.transport.TransportDelivery
import com.typewritermc.services.libs.telemetry.serviceTelemetry
import com.typewritermc.services.libs.utils.findExceptional
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.assertions.throwables.shouldThrow
import io.kotest.matchers.collections.shouldContainExactly
import io.kotest.matchers.shouldBe
import io.kotest.matchers.types.shouldBeInstanceOf
import io.opentelemetry.api.OpenTelemetry
import io.opentelemetry.context.propagation.ContextPropagators
import kotlinx.coroutines.CancellationException
import kotlinx.coroutines.ExperimentalCoroutinesApi
import kotlinx.coroutines.async
import kotlinx.coroutines.cancelAndJoin
import kotlinx.coroutines.currentCoroutineContext
import kotlinx.coroutines.isActive
import kotlinx.coroutines.test.advanceTimeBy
import kotlinx.coroutines.test.runCurrent
import kotlinx.coroutines.test.runTest
import kotlinx.coroutines.withTimeout
import skirout.service.v1.rollout.ApplyRolloutCommandRequest
import skirout.service.v1.rollout.ApplyRolloutCommandResponse
import skirout.service.v1.rollout.ParticipantPhase
import skirout.service.v1.rollout.ParticipantProjection
import skirout.service.v1.rollout.ProbeRealmHostsRequest
import skirout.service.v1.rollout.ProbeRealmHostsResponse
import skirout.service.v1.rollout.ProjectionHealth
import skirout.service.v1.rollout.QueryParticipantStatusRequest
import skirout.service.v1.rollout.QueryParticipantStatusResponse
import skirout.service.v1.rollout.RollbackTarget
import skirout.service.v1.rollout.RolloutCommand
import java.net.URLClassLoader
import java.nio.file.Files
import java.util.concurrent.TimeoutException
import java.util.zip.ZipEntry
import java.util.zip.ZipOutputStream
import kotlin.time.Duration.Companion.milliseconds
import kotlin.time.Duration.Companion.seconds

@OptIn(ExperimentalCoroutinesApi::class)
val HostRolloutParticipantTest by testSuite {
    /** The reply inbox prefix of the rollout coordinator whose requests the tests deliver. */
    val coordinatorReplyInbox = serviceReplyInboxPrefix("coordinator")

    test("manifest selects the hosted entrypoint without scanning extension services") {
        runTest {
            val fixture = participantFixture(this)
            val artifact = fixture.root.resolve("runtime.jar")
            ZipOutputStream(Files.newOutputStream(artifact)).use { archive ->
                archive.putNextEntry(ZipEntry("META-INF/services/com.typewritermc.loader.api.HostedRuntimeEntrypoint"))
                archive.write("missing.ServiceDescriptor".encodeToByteArray())
                archive.closeEntry()
            }
            val manifest =
                EngineManifest(
                    id = ArtifactId("typewritermc:paper"),
                    version = ArtifactVersion("1.0.0"),
                    hostApi = VersionConstraint("^1"),
                    runtimeEntrypointClass = TestHostedRuntimeEntrypoint::class.qualifiedName!!,
                    directCapabilities = emptyList(),
                    resolvedCapabilities = emptyList(),
                    bundledComponents = emptyList(),
                    contributions = emptyList(),
                )
            val context = fixture.context(artifact, manifest)

            val loaded = HostedRuntimeLoader(TestHostedRuntimeEntrypoint::class.java.classLoader).stage(context)
            loaded.runtime shouldBe TestHostedRuntimeEntrypoint.stagedRuntime
            loaded.close()
        }
    }

    test("rejects a manifest entrypoint that does not implement the runtime contract") {
        runTest {
            val fixture = participantFixture(this)
            val artifact = fixture.root.resolve("runtime.jar")
            ZipOutputStream(Files.newOutputStream(artifact)).use { }
            val manifest = fixture.engineManifest("java.lang.String")

            shouldThrow<IllegalArgumentException> {
                HostedRuntimeLoader(HostedRuntimeEntrypoint::class.java.classLoader)
                    .stage(fixture.context(artifact, manifest))
            }.message shouldBe "Hosted runtime entrypoint java.lang.String does not implement HostedRuntimeEntrypoint."
        }
    }

    test("rejects a manifest entrypoint without a public zero argument constructor") {
        runTest {
            val fixture = participantFixture(this)
            val artifact = fixture.root.resolve("runtime.jar")
            ZipOutputStream(Files.newOutputStream(artifact)).use { }
            val manifest = fixture.engineManifest(NoZeroArgumentHostedRuntimeEntrypoint::class.qualifiedName!!)

            shouldThrow<NoSuchMethodException> {
                HostedRuntimeLoader(NoZeroArgumentHostedRuntimeEntrypoint::class.java.classLoader)
                    .stage(fixture.context(artifact, manifest))
            }
        }
    }

    test("closes the new loader when entrypoint staging fails") {
        runTest {
            val fixture = participantFixture(this)
            val artifact = fixture.root.resolve("runtime.jar")
            writeRuntimeJar(artifact, ThrowingHostedRuntimeEntrypoint::class.java)
            val manifest = fixture.engineManifest(ThrowingHostedRuntimeEntrypoint::class.qualifiedName!!)
            StagingLoaders.last = null

            shouldThrow<IllegalStateException> {
                HostedRuntimeLoader(ParentHiding(ThrowingHostedRuntimeEntrypoint::class.java))
                    .stage(fixture.context(artifact, manifest))
            }.message shouldBe "fixture stage failure"

            // The entrypoint was defined from the runtime JAR, and that loader no longer reads it once closed.
            val loader = StagingLoaders.last.shouldBeInstanceOf<URLClassLoader>()
            loader.getResource(RUNTIME_MARKER) shouldBe null
        }
    }

    test("hosts that a command does not list stay silent") {
        runTest {
            val fixture = participantFixture(this)
            val reference = fixture.reference("other host")
            val other = ParticipantProjection(serviceId = "other", projection = reference.copy(serviceId = "other"))
            val request =
                ApplyRolloutCommandRequest(attempt = attempt(1, 1), command = RolloutCommand.createStage(participants = listOf(other)))

            fixture.participant.apply(request) shouldBe null
            fixture.stagedContexts.size shouldBe 0
            fixture.events.size shouldBe 0
            fixture.participant.close()
        }
    }

    test("rejects an attempt without a positive ordinal") {
        runTest {
            val fixture = participantFixture(this)
            val reference = fixture.reference("invalid")
            shouldThrow<IllegalArgumentException> { fixture.participant.apply(fixture.stage(attempt(0, 1), reference)) }
            shouldThrow<IllegalArgumentException> { fixture.participant.status(attempt(0, 1)) }
            fixture.participant.close()
        }
    }

    test("a repeated stage is accepted again and stages its projection once") {
        runTest {
            val fixture = participantFixture(this)
            val attempt = attempt(2, 1)
            val reference = fixture.reference("first")
            val projection = fixture.projection(reference)
            fixture.projections[reference] = projection
            val stage = fixture.stage(attempt, reference)

            fixture.participant.apply(stage) shouldBe fixture.accepted
            fixture.participant.apply(stage) shouldBe fixture.accepted

            val staged = fixture.stagedContexts.single()
            staged.publicationTarget shouldBe projection.publicationTarget
            staged.engineImplementation shouldBe projection.runtimes.single().implementation
            fixture.participant.close()
        }
    }

    test("a repeated commit is accepted again and activates the runtime once") {
        runTest {
            val fixture = participantFixture(this)
            val attempt = attempt(2, 1)
            val reference = fixture.reference("first")
            fixture.projections[reference] = fixture.projection(reference)
            fixture.participant.apply(fixture.stage(attempt, reference))
            val commit = fixture.commit(attempt, reference)

            fixture.participant.apply(commit) shouldBe fixture.accepted
            fixture.participant.apply(commit) shouldBe fixture.accepted

            fixture.runtimes.single().operations shouldContainExactly listOf("activate")
            fixture.participant.close()
        }
    }

    test("an abort of the active attempt is accepted") {
        runTest {
            val fixture = participantFixture(this)
            val attempt = attempt(2, 1)
            val reference = fixture.reference("first")
            fixture.projections[reference] = fixture.projection(reference)
            fixture.participant.apply(fixture.stage(attempt, reference))

            fixture.participant.apply(fixture.abort(attempt, reference)) shouldBe fixture.accepted
            fixture.participant.close()
        }
    }

    test("staging another projection in the same attempt is answered with an attempt conflict") {
        runTest {
            val fixture = participantFixture(this)
            val attempt = attempt(2, 1)
            val reference = fixture.reference("first")
            fixture.projections[reference] = fixture.projection(reference)
            fixture.participant.apply(fixture.stage(attempt, reference))

            fixture.participant.apply(fixture.stage(attempt, fixture.reference("conflict"))) shouldBe
                ApplyRolloutCommandResponse.createAttemptConflictError(serviceId = "service")
            fixture.stagedContexts.size shouldBe 1
            fixture.participant.close()
        }
    }

    test("a command of an older attempt is answered as stale") {
        runTest {
            val fixture = participantFixture(this)
            val reference = fixture.reference("first")
            fixture.projections[reference] = fixture.projection(reference)
            fixture.participant.apply(fixture.stage(attempt(2, 1), reference))

            fixture.participant.apply(fixture.stage(attempt(1, 1), reference)) shouldBe
                ApplyRolloutCommandResponse.createStaleAttemptError(serviceId = "service")
            fixture.participant.close()
        }
    }

    test("failed shutdown retains the participant for retry and closes each successful runtime once") {
        runTest {
            val fixture = participantFixture(this)
            val attempt = attempt(2, 1)
            val reference = fixture.reference("shutdown")
            fixture.projections[reference] = fixture.projection(reference)
            fixture.participant.apply(fixture.stage(attempt, reference)) shouldBe fixture.accepted
            fixture.participant.apply(fixture.commit(attempt, reference)) shouldBe fixture.accepted
            val runtime = fixture.runtimes.single()
            runtime.failOn += "close"
            shouldThrow<IllegalStateException> { fixture.participant.close() }
            (fixture.participant.status(attempt).phase is ParticipantPhase.ActiveWrapper) shouldBe true
            runtime.failOn.clear()
            fixture.participant.close()
            fixture.participant.close()
            runtime.operations.count { it == "close" } shouldBe 2
            fixture.participant.status(attempt).phase shouldBe ParticipantPhase.IDLE
        }
    }

    test("runtime package preserves every source part disposition") {
        runTest {
            val fixture = participantFixture(this)
            val attempt = attempt(2, 2)
            val reference = fixture.reference("mixed")
            fixture.projections[reference] = fixture.projection(reference, includeExtension = true)

            fixture.participant.apply(fixture.stage(attempt, reference)) shouldBe fixture.accepted

            val extension =
                fixture.stagedContexts
                    .single()
                    .artifacts.extensions
                    .single()
            extension.manifest.id shouldBe ArtifactId("typewritermc:extension")
            extension.sourceParts.map { it.name } shouldContainExactly listOf("paper", "panel")
            extension.sourceParts[0].disposition shouldBe SourcePartDisposition.Eligible(setOf(RuntimePlacement.PRIMARY_ENGINE))
            extension.sourceParts[1].disposition shouldBe
                SourcePartDisposition.Ineligible(listOf("Source part is not eligible for PRIMARY_ENGINE."))
            fixture.participant.close()
        }
    }

    test("health changes are published after activation") {
        runTest {
            val fixture = participantFixture(this)
            val attempt = attempt(3, 3)
            val reference = fixture.reference("health")
            fixture.projections[reference] = fixture.projection(reference)

            fixture.participant.apply(fixture.stage(attempt, reference))
            fixture.participant.apply(fixture.commit(attempt, reference))
            fixture.runtimes
                .single()
                .healthState.value = RuntimeHealth.Unhealthy("fixture failure")
            runCurrent()

            val active =
                fixture.events
                    .map { it.phase }
                    .filterIsInstance<ParticipantPhase.ActiveWrapper>()
                    .last()
            active.value.current.health shouldBe ProjectionHealth.createUnhealthy(reasons = listOf("fixture failure"))
            fixture.participant.close()
        }
    }

    test("owned activation timeout reports failure without cancelling its caller") {
        runTest {
            val fixture = participantFixture(this)
            val attempt = attempt(1, 1)
            val reference = fixture.reference("deadline")
            fixture.projections[reference] = fixture.projection(reference)
            fixture.participant.apply(fixture.stage(attempt, reference))
            fixture.runtimes.single().suspendOn += "activate"
            try {
                val result = fixture.participant.apply(fixture.commit(attempt, reference))
                (result is ApplyRolloutCommandResponse.CommandFailedErrorWrapper) shouldBe true
                (fixture.events.last().phase is ParticipantPhase.FailedWrapper) shouldBe true
                currentCoroutineContext().isActive shouldBe true
                fixture.runtimes.single().operations shouldContainExactly listOf("activate", "close")
                fixture.participant.status(attempt) shouldBe fixture.idle(attempt)
            } finally {
                fixture.participant.close()
            }
        }
    }

    test("caller cancellation during activation propagates and cleans up its candidate") {
        runTest {
            val fixture = participantFixture(this)
            val attempt = attempt(1, 1)
            val reference = fixture.reference("caller cancellation")
            fixture.projections[reference] = fixture.projection(reference)
            fixture.participant.apply(fixture.stage(attempt, reference))
            fixture.runtimes.single().suspendOn += "activate"
            val command = async { fixture.participant.apply(fixture.commit(attempt, reference)) }
            runCurrent()
            command.cancelAndJoin()
            shouldThrow<CancellationException> { command.await() }
            currentCoroutineContext().isActive shouldBe true
            fixture.runtimes.single().operations shouldContainExactly listOf("activate", "close")
            fixture.events.none { it.phase is ParticipantPhase.FailedWrapper } shouldBe true
            fixture.participant.status(attempt) shouldBe fixture.idle(attempt)
            fixture.participant.close()
        }
    }

    test("owned activation timeout preserves rollout status and presence routes") {
        runTest {
            val fixture = participantFixture(this)
            val attempt = attempt(1, 1)
            val reference = fixture.reference("router deadline")
            fixture.projections[reference] = fixture.projection(reference)
            fixture.participant.apply(fixture.stage(attempt, reference))
            fixture.runtimes.single().suspendOn += "activate"
            val fake = FakeMessageTransport()
            val telemetry = OpenTelemetry.noop().serviceTelemetry("participant deadline test")
            val communicator = Communicator(fake, telemetry, ContextPropagators.noop())
            val address = RealmRouteScope(organizationId = "organization", realmId = fixture.realmId.value)
            val commandContract = address.rolloutCommand
            val statusContract = address.rolloutStatus
            val probeContract = address.rolloutProbe
            val routes =
                communicatorRoutes {
                    scatterAt(commandContract, address) { fixture.participant.apply(it.request) }
                    scatterAt(statusContract, address) {
                        QueryParticipantStatusResponse.StatusWrapper(fixture.participant.status(it.request.attempt))
                    }
                    scatterAt(probeContract, address) { ProbeRealmHostsResponse.createInternalError() }
                }
            val router = communicator.createRouter(routes, backgroundScope)
            router.start() shouldBe RouterResult.Success
            try {
                val command = fixture.commit(attempt, reference)
                fake.deliver(
                    TransportDelivery.Message(
                        InboundMessage(
                            commandContract.requestAddress.render(address),
                            commandContract.requestCodec.encode(command).toByteArray(),
                            MessageAddress.of("$coordinatorReplyInbox.command"),
                        ),
                    ),
                )
                runCurrent()
                advanceTimeBy(1000)
                runCurrent()
                router.state shouldBe RouterState.RUNNING
                (fixture.events.last().phase is ParticipantPhase.FailedWrapper) shouldBe true
                fake.deliver(
                    TransportDelivery.Message(
                        InboundMessage(
                            statusContract.requestAddress.render(address),
                            statusContract.requestCodec.encode(QueryParticipantStatusRequest(attempt = attempt)).toByteArray(),
                            MessageAddress.of("$coordinatorReplyInbox.status"),
                        ),
                    ),
                )
                fake.deliver(
                    TransportDelivery.Message(
                        InboundMessage(
                            probeContract.requestAddress.render(address),
                            probeContract.requestCodec.encode(ProbeRealmHostsRequest.partial()).toByteArray(),
                            MessageAddress.of("$coordinatorReplyInbox.presence"),
                        ),
                    ),
                )
                runCurrent()
                fake.actions
                    .filterIsInstance<FakeMessageTransport.Action.Publish>()
                    .map { it.message.address.value }
                    .toSet() shouldBe
                    setOf("$coordinatorReplyInbox.command", "$coordinatorReplyInbox.status", "$coordinatorReplyInbox.presence")
            } finally {
                router.stop()
                fixture.participant.close()
                fake.close()
            }
        }
    }

    test("owned activation timeout restores the baseline and reports failure") {
        runTest {
            val fixture = participantFixture(this)
            val baselineAttempt = attempt(1, 1)
            val baseline = fixture.reference("deadline baseline")
            fixture.projections[baseline] = fixture.projection(baseline)
            fixture.participant.apply(fixture.stage(baselineAttempt, baseline))
            fixture.participant.apply(fixture.commit(baselineAttempt, baseline))
            val attempt = attempt(2, 2)
            val candidate = fixture.reference("deadline replacement")
            fixture.projections[candidate] = fixture.projection(candidate)
            fixture.participant.apply(fixture.stage(attempt, candidate))
            fixture.runtimes[1].suspendOn += "activate"
            val result = fixture.participant.apply(fixture.commit(attempt, candidate))
            (result is ApplyRolloutCommandResponse.CommandFailedErrorWrapper) shouldBe true
            (fixture.events.last().phase is ParticipantPhase.FailedWrapper) shouldBe true
            fixture.participant.status(attempt).activeProjection shouldBe baseline
            fixture.runtimes[0].operations shouldContainExactly listOf("activate", "quiesce", "resume")
            fixture.runtimes[1].operations shouldContainExactly listOf("activate", "close")
            currentCoroutineContext().isActive shouldBe true
            fixture.participant.close()
        }
    }

    for (operationName in listOf("quiesce", "resume")) {
        test("owned $operationName deadline is an ordinary lifecycle failure") {
            runTest {
                val runtime = RecordingRuntime()
                runtime.suspendOn += operationName
                val projection =
                    HostRolloutParticipant.LocalProjection(
                        listOf(LoadedHostedRuntime(runtime, URLClassLoader(emptyArray<java.net.URL>()))),
                        this,
                        1.seconds,
                    )
                try {
                    val failure =
                        shouldThrow<TimeoutException> {
                            when (operationName) {
                                "quiesce" -> projection.quiesce()
                                else -> projection.resume()
                            }
                        }
                    failure.message shouldBe "Hosted runtime $operationName exceeded lifecycle deadline of 1s"
                    failure.cause shouldBe null
                    failure.suppressed.size shouldBe 0
                    failure.findExceptional() shouldBe null
                    currentCoroutineContext().isActive shouldBe true
                } finally {
                    projection.close()
                }
            }
        }
    }

    test("owned close deadline preserves unfinished runtime ownership for retry") {
        runTest {
            val unfinished = RecordingRuntime()
            val finished = RecordingRuntime()
            unfinished.suspendOn += "close"
            val projection =
                HostRolloutParticipant.LocalProjection(
                    listOf(unfinished, finished).map { LoadedHostedRuntime(it, URLClassLoader(emptyArray<java.net.URL>())) },
                    this,
                    1.seconds,
                )
            val failure = shouldThrow<TimeoutException> { projection.close() }
            failure.message shouldBe "Hosted runtime close exceeded lifecycle deadline of 1s"
            failure.findExceptional() shouldBe null
            unfinished.suspendOn.clear()
            projection.close()
            projection.close()
            unfinished.operations shouldContainExactly listOf("close", "close")
            finished.operations shouldContainExactly listOf("close")
            currentCoroutineContext().isActive shouldBe true
        }
    }

    test("owned compensation deadline remains an ordinary suppressed failure") {
        runTest {
            val completed = RecordingRuntime()
            val failing = RecordingRuntime()
            completed.suspendOn += "quiesce"
            failing.failOn += "activate"
            val projection =
                HostRolloutParticipant.LocalProjection(
                    listOf(completed, failing).map { LoadedHostedRuntime(it, URLClassLoader(emptyArray<java.net.URL>())) },
                    this,
                    1.seconds,
                )
            try {
                val failure = shouldThrow<IllegalStateException> { projection.activate() }
                failure.message shouldBe "Fixture activate failure"
                failure.suppressed.size shouldBe 1
                (failure.suppressed.single() is TimeoutException) shouldBe true
                failure.suppressed.single().message shouldBe "Hosted runtime quiesce compensation exceeded lifecycle deadline of 1s"
                failure.findExceptional() shouldBe null
                completed.operations shouldContainExactly listOf("activate", "quiesce")
                failing.operations shouldContainExactly listOf("activate")
                currentCoroutineContext().isActive shouldBe true
            } finally {
                projection.close()
            }
        }
    }

    test("external caller deadline remains cancellation rather than lifecycle failure") {
        runTest {
            val fixture = participantFixture(this)
            val attempt = attempt(1, 1)
            val reference = fixture.reference("external deadline")
            fixture.projections[reference] = fixture.projection(reference)
            fixture.participant.apply(fixture.stage(attempt, reference))
            fixture.runtimes.single().suspendOn += "activate"
            shouldThrow<kotlinx.coroutines.TimeoutCancellationException> {
                withTimeout(100.milliseconds) {
                    fixture.participant.apply(fixture.commit(attempt, reference))
                }
            }
            fixture.events.none { it.phase is ParticipantPhase.FailedWrapper } shouldBe true
            fixture.runtimes.single().operations shouldContainExactly listOf("activate", "close")
            fixture.participant.status(attempt) shouldBe fixture.idle(attempt)
            currentCoroutineContext().isActive shouldBe true
            fixture.participant.close()
        }
    }

    test("failed candidate activation restores the complete baseline") {
        runTest {
            val fixture = participantFixture(this)
            val baselineAttempt = attempt(1, 1)
            val baseline = fixture.reference("baseline")
            fixture.projections[baseline] = fixture.projection(baseline)
            fixture.participant.apply(fixture.stage(baselineAttempt, baseline))
            fixture.participant.apply(fixture.commit(baselineAttempt, baseline))

            val candidateAttempt = attempt(2, 2)
            val candidate = fixture.reference("candidate")
            fixture.projections[candidate] = fixture.projection(candidate)
            fixture.participant.apply(fixture.stage(candidateAttempt, candidate))
            fixture.runtimes[1].failOn += "activate"

            val result = fixture.participant.apply(fixture.commit(candidateAttempt, candidate))

            (result is ApplyRolloutCommandResponse.CommandFailedErrorWrapper) shouldBe true
            fixture.runtimes[0].operations shouldContainExactly listOf("activate", "quiesce", "resume")
            fixture.runtimes[1].operations shouldContainExactly listOf("activate", "close")
            fixture.participant.status(candidateAttempt).activeProjection shouldBe baseline
            fixture.participant.close()
        }
    }

    test("unavailable rollback target preserves the active runtime and health reporting") {
        runTest {
            val fixture = participantFixture(this)
            val attempt = attempt(1, 1)
            val reference = fixture.reference("active")
            fixture.projections[reference] = fixture.projection(reference)
            fixture.participant.apply(fixture.stage(attempt, reference))
            fixture.participant.apply(fixture.commit(attempt, reference))
            runCurrent()
            val rollback = RollbackTarget.ProjectionWrapper(fixture.reference("missing"))

            val result = fixture.participant.apply(fixture.rollback(attempt, reference, rollback))

            result shouldBe
                ApplyRolloutCommandResponse.createCommandRejectedError(
                    serviceId = "service",
                    reason = "The requested rollback projection is not retained.",
                )
            fixture.runtimes.single().operations shouldContainExactly listOf("activate")
            fixture.runtimes
                .single()
                .healthState.value = RuntimeHealth.Unhealthy("still monitored")
            runCurrent()
            val status = fixture.events.last().phase as ParticipantPhase.ActiveWrapper
            status.value.current.health shouldBe ProjectionHealth.createUnhealthy(reasons = listOf("still monitored"))
            fixture.participant.close()
        }
    }

    test("failed fresh activation leaves the host empty") {
        runTest {
            val fixture = participantFixture(this)
            val attempt = attempt(1, 1)
            val reference = fixture.reference("fresh failure")
            fixture.projections[reference] = fixture.projection(reference)
            fixture.participant.apply(fixture.stage(attempt, reference))
            fixture.runtimes.single().failOn += "activate"

            fixture.participant.apply(fixture.commit(attempt, reference)) shouldBe fixture.failed("Fixture activate failure")
            fixture.participant.status(attempt) shouldBe fixture.idle(attempt)
            fixture.runtimes.single().operations shouldContainExactly listOf("activate", "close")
            fixture.stagedContexts.size shouldBe 1
            fixture.participant.close()
        }
    }

    test("rollback to empty closes a fresh host without loading an older runtime") {
        runTest {
            val fixture = participantFixture(this)
            val attempt = attempt(1, 1)
            val reference = fixture.reference("fresh")
            fixture.projections[reference] = fixture.projection(reference)
            fixture.participant.apply(fixture.stage(attempt, reference))
            fixture.participant.apply(fixture.commit(attempt, reference))
            val rollback = RollbackTarget.EMPTY

            fixture.participant.apply(fixture.rollback(attempt, reference, rollback)) shouldBe fixture.accepted
            fixture.participant.status(attempt) shouldBe fixture.idle(attempt)
            fixture.runtimes.single().operations shouldContainExactly listOf("activate", "quiesce", "close")
            fixture.stagedContexts.size shouldBe 1
            fixture.participant.close()
        }
    }

    test("rollback restores the exact retained projection") {
        runTest {
            val fixture = participantFixture(this)
            val baselineAttempt = attempt(1, 1)
            val baseline = fixture.reference("baseline")
            fixture.projections[baseline] = fixture.projection(baseline)
            fixture.participant.apply(fixture.stage(baselineAttempt, baseline))
            fixture.participant.apply(fixture.commit(baselineAttempt, baseline))

            val candidateAttempt = attempt(2, 2)
            val candidate = fixture.reference("candidate")
            fixture.projections[candidate] = fixture.projection(candidate)
            fixture.participant.apply(fixture.stage(candidateAttempt, candidate))
            fixture.participant.apply(fixture.commit(candidateAttempt, candidate))
            val rollback = RollbackTarget.ProjectionWrapper(baseline)

            fixture.participant.apply(fixture.rollback(candidateAttempt, candidate, rollback)) shouldBe fixture.accepted
            fixture.participant.apply(fixture.rollback(candidateAttempt, candidate, rollback)) shouldBe fixture.accepted

            fixture.runtimes[1].operations shouldContainExactly listOf("activate", "quiesce", "close")
            fixture.runtimes[0].operations shouldContainExactly listOf("activate", "quiesce", "resume")
            fixture.participant.status(candidateAttempt).activeProjection shouldBe baseline
            fixture.participant.close()
        }
    }
}
