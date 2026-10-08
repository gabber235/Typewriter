package com.typewritermc.loader

import com.typewritermc.imprint.ArtifactId
import com.typewritermc.imprint.ArtifactKind
import com.typewritermc.imprint.ArtifactVersion
import com.typewritermc.imprint.CommonExtensionSourcePart
import com.typewritermc.imprint.EngineManifest
import com.typewritermc.imprint.ExtensionManifest
import com.typewritermc.imprint.IMPRINT_MANIFEST_PATH
import com.typewritermc.imprint.ImprintManifest
import com.typewritermc.imprint.ImprintManifestCodec
import com.typewritermc.imprint.VersionConstraint
import com.typewritermc.loader.api.EngineImplementationArtifact
import com.typewritermc.loader.api.EngineImplementationTarget
import com.typewritermc.loader.api.HostedArtifact
import com.typewritermc.loader.api.HostedArtifactPackage
import com.typewritermc.loader.api.HostedDeploymentContext
import com.typewritermc.loader.api.HostedMessagingSession
import com.typewritermc.loader.api.HostedRuntimeEntrypoint
import com.typewritermc.loader.api.HostedRuntimeHost
import com.typewritermc.loader.api.RuntimeHealth
import com.typewritermc.loader.api.RuntimePlacement
import com.typewritermc.loader.api.SourcePartDisposition
import com.typewritermc.loader.api.StagedHostedRuntime
import com.typewritermc.loader.api.artifact.ArtifactDigest
import com.typewritermc.loader.artifact.ArtifactCoordinate
import com.typewritermc.loader.artifact.DeploymentArtifact
import com.typewritermc.loader.artifact.FileDigestBlobStore
import com.typewritermc.loader.deployment.DeploymentGeneration
import com.typewritermc.loader.deployment.HostDeploymentProjection
import com.typewritermc.loader.deployment.ProjectedExtension
import com.typewritermc.loader.deployment.ProjectedRuntime
import com.typewritermc.loader.deployment.ProjectedSourcePart
import com.typewritermc.loader.rollout.HostRolloutParticipant
import com.typewritermc.loader.rollout.ParticipantStateChanged
import com.typewritermc.loader.rollout.ParticipantStatus
import com.typewritermc.loader.rollout.ParticipantStatusContract
import com.typewritermc.loader.rollout.ParticipantStatusReply
import com.typewritermc.loader.rollout.PresenceReply
import com.typewritermc.loader.rollout.ProbeParticipantStatus
import com.typewritermc.loader.rollout.ProbeRealmHosts
import com.typewritermc.loader.rollout.ProbeRealmHostsContract
import com.typewritermc.loader.rollout.ProjectionReference
import com.typewritermc.loader.rollout.ProjectionSource
import com.typewritermc.loader.rollout.RealmBroadcastAddress
import com.typewritermc.loader.rollout.RealmId
import com.typewritermc.loader.rollout.RollbackTarget
import com.typewritermc.loader.rollout.RolloutAttempt
import com.typewritermc.loader.rollout.RolloutCommand
import com.typewritermc.loader.rollout.RolloutCommandContract
import com.typewritermc.loader.rollout.RolloutEnvelope
import com.typewritermc.loader.rollout.VerifiedArtifactSource
import com.typewritermc.loader.runtime.HostedRuntimeLoader
import com.typewritermc.loader.runtime.HostedRuntimeStager
import com.typewritermc.loader.runtime.LoadedHostedRuntime
import com.typewritermc.loader.shared.FileSharedArtifactRepository
import com.typewritermc.loader.shared.SharedArtifactService
import com.typewritermc.services.libs.communicator.address.MessageAddress
import com.typewritermc.services.libs.communicator.client.Communicator
import com.typewritermc.services.libs.communicator.contract.ResponseOutcome
import com.typewritermc.services.libs.communicator.router.RouterResult
import com.typewritermc.services.libs.communicator.router.RouterState
import com.typewritermc.services.libs.communicator.router.communicatorRoutes
import com.typewritermc.services.libs.communicator.testing.FakeMessageTransport
import com.typewritermc.services.libs.communicator.transport.InboundMessage
import com.typewritermc.services.libs.communicator.transport.TransportDelivery
import com.typewritermc.services.libs.registrar.ServiceId
import com.typewritermc.services.libs.telemetry.serviceTelemetry
import com.typewritermc.services.libs.utils.findExceptionalThrowable
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.assertions.throwables.shouldThrow
import io.kotest.matchers.collections.shouldContainExactly
import io.kotest.matchers.shouldBe
import io.opentelemetry.api.OpenTelemetry
import io.opentelemetry.context.propagation.ContextPropagators
import java.net.URLClassLoader
import java.nio.file.Files
import java.nio.file.Path
import java.util.concurrent.TimeoutException
import java.util.zip.ZipEntry
import java.util.zip.ZipOutputStream
import kotlin.time.Duration.Companion.milliseconds
import kotlin.time.Duration.Companion.seconds
import kotlinx.coroutines.CancellationException
import kotlinx.coroutines.ExperimentalCoroutinesApi
import kotlinx.coroutines.async
import kotlinx.coroutines.awaitCancellation
import kotlinx.coroutines.cancelAndJoin
import kotlinx.coroutines.currentCoroutineContext
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.isActive
import kotlinx.coroutines.test.TestScope
import kotlinx.coroutines.test.advanceTimeBy
import kotlinx.coroutines.test.runCurrent
import kotlinx.coroutines.test.runTest
import kotlinx.coroutines.withTimeout

@OptIn(ExperimentalCoroutinesApi::class)
val HostRolloutParticipantTest by testSuite {
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
            }
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
            ZipOutputStream(Files.newOutputStream(artifact)).use { }
            val manifest = fixture.engineManifest(ThrowingHostedRuntimeEntrypoint::class.qualifiedName!!)

            shouldThrow<IllegalStateException> {
                HostedRuntimeLoader(ThrowingHostedRuntimeEntrypoint::class.java.classLoader)
                    .stage(fixture.context(artifact, manifest))
            }
        }
    }

    test("participant status contract classifies its typed internal failure") {
        val policy = ParticipantStatusContract.responsePolicy
        policy.classify(policy.internalFailureResponse).outcome shouldBe ResponseOutcome.INTERNAL_ERROR
        policy
            .classify(
                ParticipantStatusReply.Status(
                    ServiceId("service"),
                    ParticipantStatus.Idle(RolloutAttempt(1, DeploymentGeneration(1)), ServiceId("service")),
                ),
            ).outcome shouldBe ResponseOutcome.SUCCESS
    }

    test("commands are serialized idempotent and projection specific") {
        runTest {
            val fixture = participantFixture(this)
            val attempt = RolloutAttempt(2, DeploymentGeneration(1))
            val reference = fixture.reference("first")
            val projection = fixture.projection(reference)
            fixture.projections[reference] = projection
            val stage = fixture.envelope(attempt, reference, RolloutCommand.Stage)
            val commit = fixture.envelope(attempt, reference, RolloutCommand.Commit)

            fixture.participant.handle(stage).accepted shouldBe true
            fixture.participant.handle(stage).accepted shouldBe true
            fixture.stagedContexts.size shouldBe 1
            fixture.stagedContexts.single().publicationTarget shouldBe projection.publicationTarget
            fixture.stagedContexts.single().engineImplementation shouldBe projection.runtimes.single().implementation

            fixture.participant.handle(commit).accepted shouldBe true
            fixture.participant.handle(commit).accepted shouldBe true
            fixture.runtimes.single().operations shouldContainExactly listOf("activate")

            fixture.participant.handle(fixture.envelope(attempt, reference, RolloutCommand.Abort)).accepted shouldBe true

            val conflictReference = fixture.reference("conflict")
            val conflict = fixture.participant.handle(fixture.envelope(attempt, conflictReference, RolloutCommand.Stage))
            conflict.accepted shouldBe false
            conflict.internalFailure shouldBe false

            val older =
                fixture.participant.handle(
                    fixture.envelope(RolloutAttempt(1, DeploymentGeneration(1)), reference, RolloutCommand.Stage),
                )
            older.accepted shouldBe false
            older.internalFailure shouldBe false
            fixture.participant.close()
        }
    }

    test("failed shutdown retains the participant for retry and closes each successful runtime once") {
        runTest {
            val fixture = participantFixture(this)
            val attempt = RolloutAttempt(2, DeploymentGeneration(1))
            val reference = fixture.reference("shutdown")
            fixture.projections[reference] = fixture.projection(reference)
            fixture.participant.handle(fixture.envelope(attempt, reference, RolloutCommand.Stage)).accepted shouldBe true
            fixture.participant.handle(fixture.envelope(attempt, reference, RolloutCommand.Commit)).accepted shouldBe true
            val runtime = fixture.runtimes.single()
            runtime.failOn += "close"
            shouldThrow<IllegalStateException> { fixture.participant.close() }
            (fixture.participant.currentStatus(attempt) is ParticipantStatus.Active) shouldBe true
            runtime.failOn.clear()
            fixture.participant.close()
            fixture.participant.close()
            runtime.operations.count { it == "close" } shouldBe 2
            (fixture.participant.currentStatus(attempt) is ParticipantStatus.Idle) shouldBe true
        }
    }

    test("runtime package preserves every source part disposition") {
        runTest {
            val fixture = participantFixture(this)
            val attempt = RolloutAttempt(2, DeploymentGeneration(2))
            val reference = fixture.reference("mixed")
            fixture.projections[reference] = fixture.projection(reference, includeExtension = true)

            fixture.participant.handle(fixture.envelope(attempt, reference, RolloutCommand.Stage)).accepted shouldBe true

            val context = fixture.stagedContexts.single()
            val extension = context.artifacts.extensions.single()
            context.artifacts.runtimeArtifact.manifest shouldBe
                EngineManifest(
                    id = ArtifactId("typewritermc:paper"),
                    version = ArtifactVersion("1.0.0"),
                    hostApi = VersionConstraint("^1"),
                    runtimeEntrypointClass = "fixture.Runtime",
                    directCapabilities = emptyList(),
                    resolvedCapabilities = emptyList(),
                    bundledComponents = emptyList(),
                    contributions = emptyList(),
                )
            extension.manifest.id shouldBe ArtifactId("typewritermc:extension")
            extension.sourceParts.map { it.name } shouldContainExactly listOf("paper", "panel")
            extension.sourceParts[0].disposition shouldBe SourcePartDisposition.Eligible(setOf(RuntimePlacement.PRIMARY_ENGINE))
            extension.sourceParts[1].disposition shouldBe
                SourcePartDisposition.Ineligible(listOf("Source part is not eligible for PRIMARY_ENGINE."))
            fixture.classPaths.single().size shouldBe 2
            fixture.participant.close()
        }
    }

    test("health changes are published after activation") {
        runTest {
            val fixture = participantFixture(this)
            val attempt = RolloutAttempt(3, DeploymentGeneration(3))
            val reference = fixture.reference("health")
            fixture.projections[reference] = fixture.projection(reference)

            fixture.participant.handle(fixture.envelope(attempt, reference, RolloutCommand.Stage))
            fixture.participant.handle(fixture.envelope(attempt, reference, RolloutCommand.Commit))
            fixture.runtimes
                .single()
                .healthState.value = RuntimeHealth.Unhealthy("fixture failure")
            runCurrent()

            val active =
                fixture.events
                    .map { it.status }
                    .filterIsInstance<ParticipantStatus.Active>()
                    .last()
            active.current.health shouldBe
                com.typewritermc.loader.rollout.RuntimeHealthSnapshot
                    .Unhealthy(listOf("fixture failure"))
            fixture.participant.close()
        }
    }

    test("owned activation timeout reports failure without cancelling its caller") {
        runTest {
            val fixture = participantFixture(this)
            val attempt = RolloutAttempt(1, DeploymentGeneration(1))
            val reference = fixture.reference("deadline")
            fixture.projections[reference] = fixture.projection(reference)
            fixture.participant.handle(fixture.envelope(attempt, reference, RolloutCommand.Stage))
            fixture.runtimes.single().suspendOn += "activate"
            try {
                val result = fixture.participant.handle(fixture.envelope(attempt, reference, RolloutCommand.Commit))
                result.accepted shouldBe false
                result.internalFailure shouldBe true
                (fixture.events.last().status is ParticipantStatus.Failed) shouldBe true
                currentCoroutineContext().isActive shouldBe true
                fixture.runtimes.single().operations shouldContainExactly listOf("activate", "close")
                fixture.participant.currentStatus(attempt) shouldBe ParticipantStatus.Idle(attempt, fixture.serviceId)
            } finally {
                fixture.participant.close()
            }
        }
    }

    test("caller cancellation during activation propagates and cleans up its candidate") {
        runTest {
            val fixture = participantFixture(this)
            val attempt = RolloutAttempt(1, DeploymentGeneration(1))
            val reference = fixture.reference("caller cancellation")
            fixture.projections[reference] = fixture.projection(reference)
            fixture.participant.handle(fixture.envelope(attempt, reference, RolloutCommand.Stage))
            fixture.runtimes.single().suspendOn += "activate"
            val command = async { fixture.participant.handle(fixture.envelope(attempt, reference, RolloutCommand.Commit)) }
            runCurrent()
            command.cancelAndJoin()
            shouldThrow<CancellationException> { command.await() }
            currentCoroutineContext().isActive shouldBe true
            fixture.runtimes.single().operations shouldContainExactly listOf("activate", "close")
            fixture.events.none { it.status is ParticipantStatus.Failed } shouldBe true
            fixture.participant.currentStatus(attempt) shouldBe ParticipantStatus.Idle(attempt, fixture.serviceId)
            fixture.participant.close()
        }
    }

    test("owned activation timeout preserves rollout status and presence routes") {
        runTest {
            val fixture = participantFixture(this)
            val attempt = RolloutAttempt(1, DeploymentGeneration(1))
            val reference = fixture.reference("router deadline")
            fixture.projections[reference] = fixture.projection(reference)
            fixture.participant.handle(fixture.envelope(attempt, reference, RolloutCommand.Stage))
            fixture.runtimes.single().suspendOn += "activate"
            val fake = FakeMessageTransport()
            val telemetry = OpenTelemetry.noop().serviceTelemetry("participant deadline test")
            val communicator = Communicator(fake, telemetry, ContextPropagators.noop())
            val address = RealmBroadcastAddress("organization", fixture.realmId)
            val routes = communicatorRoutes {
                scatterAt(RolloutCommandContract, address) { fixture.participant.handle(it.request) }
                scatterAt(ParticipantStatusContract, address) {
                    ParticipantStatusReply.Status(fixture.serviceId, fixture.participant.currentStatus(it.request.attempt))
                }
                scatterAt(ProbeRealmHostsContract, address) { PresenceReply.Failed("presence route responded") }
            }
            val router = communicator.createRouter(routes, backgroundScope)
            router.start() shouldBe RouterResult.Success
            try {
                val command = fixture.envelope(attempt, reference, RolloutCommand.Commit)
                fake.deliver(
                    TransportDelivery.Message(
                        InboundMessage(
                            RolloutCommandContract.requestAddress.render(address),
                            RolloutCommandContract.requestCodec.encode(command).toByteArray(),
                            MessageAddress.of("reply.command"),
                        ),
                    ),
                )
                runCurrent()
                advanceTimeBy(1000)
                runCurrent()
                router.state shouldBe RouterState.RUNNING
                (fixture.events.last().status is ParticipantStatus.Failed) shouldBe true
                fake.deliver(
                    TransportDelivery.Message(
                        InboundMessage(
                            ParticipantStatusContract.requestAddress.render(address),
                            ParticipantStatusContract.requestCodec.encode(ProbeParticipantStatus(fixture.realmId, attempt)).toByteArray(),
                            MessageAddress.of("reply.status"),
                        ),
                    ),
                )
                fake.deliver(
                    TransportDelivery.Message(
                        InboundMessage(
                            ProbeRealmHostsContract.requestAddress.render(address),
                            ProbeRealmHostsContract.requestCodec.encode(ProbeRealmHosts(fixture.realmId)).toByteArray(),
                            MessageAddress.of("reply.presence"),
                        ),
                    ),
                )
                runCurrent()
                fake.actions
                    .filterIsInstance<FakeMessageTransport.Action.Publish>()
                    .map { it.message.address.value }
                    .toSet() shouldBe setOf("reply.command", "reply.status", "reply.presence")
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
            val baselineAttempt = RolloutAttempt(1, DeploymentGeneration(1))
            val baseline = fixture.reference("deadline baseline")
            fixture.projections[baseline] = fixture.projection(baseline)
            fixture.participant.handle(fixture.envelope(baselineAttempt, baseline, RolloutCommand.Stage))
            fixture.participant.handle(fixture.envelope(baselineAttempt, baseline, RolloutCommand.Commit))
            val attempt = RolloutAttempt(2, DeploymentGeneration(2))
            val candidate = fixture.reference("deadline replacement")
            fixture.projections[candidate] = fixture.projection(candidate)
            fixture.participant.handle(fixture.envelope(attempt, candidate, RolloutCommand.Stage))
            fixture.runtimes[1].suspendOn += "activate"
            val result = fixture.participant.handle(fixture.envelope(attempt, candidate, RolloutCommand.Commit))
            result.accepted shouldBe false
            result.internalFailure shouldBe true
            (fixture.events.last().status is ParticipantStatus.Failed) shouldBe true
            (fixture.participant.currentStatus(attempt) as ParticipantStatus.Active).current.projection shouldBe baseline
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
                val projection = HostRolloutParticipant.LocalProjection(
                    listOf(LoadedHostedRuntime(runtime, URLClassLoader(emptyArray<java.net.URL>()))),
                    this,
                    1.seconds,
                )
                try {
                    val failure = shouldThrow<TimeoutException> {
                        when (operationName) {
                            "quiesce" -> projection.quiesce()
                            else -> projection.resume()
                        }
                    }
                    failure.message shouldBe "Hosted runtime $operationName exceeded lifecycle deadline of 1s"
                    failure.cause shouldBe null
                    failure.suppressed.size shouldBe 0
                    findExceptionalThrowable(failure) shouldBe null
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
            val projection = HostRolloutParticipant.LocalProjection(
                listOf(unfinished, finished).map { LoadedHostedRuntime(it, URLClassLoader(emptyArray<java.net.URL>())) },
                this,
                1.seconds,
            )
            val failure = shouldThrow<TimeoutException> { projection.close() }
            failure.message shouldBe "Hosted runtime close exceeded lifecycle deadline of 1s"
            findExceptionalThrowable(failure) shouldBe null
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
            val projection = HostRolloutParticipant.LocalProjection(
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
                findExceptionalThrowable(failure) shouldBe null
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
            val attempt = RolloutAttempt(1, DeploymentGeneration(1))
            val reference = fixture.reference("external deadline")
            fixture.projections[reference] = fixture.projection(reference)
            fixture.participant.handle(fixture.envelope(attempt, reference, RolloutCommand.Stage))
            fixture.runtimes.single().suspendOn += "activate"
            shouldThrow<kotlinx.coroutines.TimeoutCancellationException> {
                withTimeout(100.milliseconds) {
                    fixture.participant.handle(fixture.envelope(attempt, reference, RolloutCommand.Commit))
                }
            }
            fixture.events.none { it.status is ParticipantStatus.Failed } shouldBe true
            fixture.runtimes.single().operations shouldContainExactly listOf("activate", "close")
            fixture.participant.currentStatus(attempt) shouldBe ParticipantStatus.Idle(attempt, fixture.serviceId)
            currentCoroutineContext().isActive shouldBe true
            fixture.participant.close()
        }
    }

    test("failed candidate activation restores the complete baseline") {
        runTest {
            val fixture = participantFixture(this)
            val baselineAttempt = RolloutAttempt(1, DeploymentGeneration(1))
            val baseline = fixture.reference("baseline")
            fixture.projections[baseline] = fixture.projection(baseline)
            fixture.participant.handle(fixture.envelope(baselineAttempt, baseline, RolloutCommand.Stage))
            fixture.participant.handle(fixture.envelope(baselineAttempt, baseline, RolloutCommand.Commit))

            val candidateAttempt = RolloutAttempt(2, DeploymentGeneration(2))
            val candidate = fixture.reference("candidate")
            fixture.projections[candidate] = fixture.projection(candidate)
            fixture.participant.handle(fixture.envelope(candidateAttempt, candidate, RolloutCommand.Stage))
            fixture.runtimes[1].failOn += "activate"

            val result = fixture.participant.handle(fixture.envelope(candidateAttempt, candidate, RolloutCommand.Commit))

            result.accepted shouldBe false
            result.internalFailure shouldBe true
            fixture.runtimes[0].operations shouldContainExactly listOf("activate", "quiesce", "resume")
            fixture.runtimes[1].operations shouldContainExactly listOf("activate", "close")
            val status = fixture.participant.currentStatus(candidateAttempt) as ParticipantStatus.Active
            status.current.projection shouldBe baseline
            fixture.participant.close()
        }
    }

    test("unavailable rollback target preserves the active runtime and health reporting") {
        runTest {
            val fixture = participantFixture(this)
            val attempt = RolloutAttempt(1, DeploymentGeneration(1))
            val reference = fixture.reference("active")
            fixture.projections[reference] = fixture.projection(reference)
            fixture.participant.handle(fixture.envelope(attempt, reference, RolloutCommand.Stage))
            fixture.participant.handle(fixture.envelope(attempt, reference, RolloutCommand.Commit))
            runCurrent()
            val rollback =
                RolloutCommand.Rollback(mapOf(fixture.serviceId to RollbackTarget.Projection(fixture.reference("missing"))))

            val result = fixture.participant.handle(fixture.envelope(attempt, reference, rollback))

            result.accepted shouldBe false
            result.internalFailure shouldBe false
            fixture.runtimes.single().operations shouldContainExactly listOf("activate")
            fixture.runtimes
                .single()
                .healthState.value = RuntimeHealth.Unhealthy("still monitored")
            runCurrent()
            val status = fixture.events.last().status as ParticipantStatus.Active
            status.current.health shouldBe
                com.typewritermc.loader.rollout.RuntimeHealthSnapshot
                    .Unhealthy(listOf("still monitored"))
            fixture.participant.close()
        }
    }

    test("failed fresh activation leaves the host empty") {
        runTest {
            val fixture = participantFixture(this)
            val attempt = RolloutAttempt(1, DeploymentGeneration(1))
            val reference = fixture.reference("fresh failure")
            fixture.projections[reference] = fixture.projection(reference)
            fixture.participant.handle(fixture.envelope(attempt, reference, RolloutCommand.Stage))
            fixture.runtimes.single().failOn += "activate"

            fixture.participant.handle(fixture.envelope(attempt, reference, RolloutCommand.Commit)).accepted shouldBe false
            fixture.participant.currentStatus(attempt) shouldBe ParticipantStatus.Idle(attempt, fixture.serviceId)
            fixture.runtimes.single().operations shouldContainExactly listOf("activate", "close")
            fixture.stagedContexts.size shouldBe 1
            fixture.participant.close()
        }
    }

    test("rollback to empty closes a fresh host without loading an older runtime") {
        runTest {
            val fixture = participantFixture(this)
            val attempt = RolloutAttempt(1, DeploymentGeneration(1))
            val reference = fixture.reference("fresh")
            fixture.projections[reference] = fixture.projection(reference)
            fixture.participant.handle(fixture.envelope(attempt, reference, RolloutCommand.Stage))
            fixture.participant.handle(fixture.envelope(attempt, reference, RolloutCommand.Commit))
            val rollback = RolloutCommand.Rollback(mapOf(fixture.serviceId to RollbackTarget.Empty))

            fixture.participant.handle(fixture.envelope(attempt, reference, rollback)).accepted shouldBe true
            fixture.participant.currentStatus(attempt) shouldBe ParticipantStatus.Idle(attempt, fixture.serviceId)
            fixture.runtimes.single().operations shouldContainExactly listOf("activate", "quiesce", "close")
            fixture.stagedContexts.size shouldBe 1
            fixture.participant.close()
        }
    }

    test("rollback restores the exact retained projection") {
        runTest {
            val fixture = participantFixture(this)
            val baselineAttempt = RolloutAttempt(1, DeploymentGeneration(1))
            val baseline = fixture.reference("baseline")
            fixture.projections[baseline] = fixture.projection(baseline)
            fixture.participant.handle(fixture.envelope(baselineAttempt, baseline, RolloutCommand.Stage))
            fixture.participant.handle(fixture.envelope(baselineAttempt, baseline, RolloutCommand.Commit))

            val candidateAttempt = RolloutAttempt(2, DeploymentGeneration(2))
            val candidate = fixture.reference("candidate")
            fixture.projections[candidate] = fixture.projection(candidate)
            fixture.participant.handle(fixture.envelope(candidateAttempt, candidate, RolloutCommand.Stage))
            fixture.participant.handle(fixture.envelope(candidateAttempt, candidate, RolloutCommand.Commit))
            val rollback =
                RolloutCommand.Rollback(
                    mapOf(fixture.serviceId to RollbackTarget.Projection(baseline)),
                )

            fixture.participant.handle(fixture.envelope(candidateAttempt, candidate, rollback)).accepted shouldBe true
            fixture.participant.handle(fixture.envelope(candidateAttempt, candidate, rollback)).accepted shouldBe true

            fixture.runtimes[1].operations shouldContainExactly listOf("activate", "quiesce", "close")
            fixture.runtimes[0].operations shouldContainExactly listOf("activate", "quiesce", "resume")
            val status = fixture.participant.currentStatus(candidateAttempt) as ParticipantStatus.Active
            status.current.projection shouldBe baseline
            fixture.participant.close()
        }
    }
}

private class ParticipantFixture(
    val serviceId: ServiceId,
    val realmId: RealmId,
    val host: HostedRuntimeHost,
    val participant: HostRolloutParticipant,
    val projections: MutableMap<ProjectionReference, HostDeploymentProjection>,
    val stagedContexts: MutableList<HostedDeploymentContext>,
    val classPaths: MutableList<List<Path>>,
    val runtimes: MutableList<RecordingRuntime>,
    val events: MutableList<ParticipantStateChanged>,
    val root: Path,
) {
    fun reference(name: String) =
        ProjectionReference(
            realmId,
            DeploymentGeneration(name.length.toLong()),
            serviceId,
            ArtifactDigest.sha256(name.encodeToByteArray()),
        )

    fun engineManifest(entrypointClass: String) =
        EngineManifest(
            id = ArtifactId("typewritermc:paper"),
            version = ArtifactVersion("1.0.0"),
            hostApi = VersionConstraint("^1"),
            runtimeEntrypointClass = entrypointClass,
            directCapabilities = emptyList(),
            resolvedCapabilities = emptyList(),
            bundledComponents = emptyList(),
            contributions = emptyList(),
        )

    fun context(
        artifact: Path,
        manifest: EngineManifest,
    ) = HostedDeploymentContext(
        identity =
            com.typewritermc.loader.api.HostedRuntimeIdentity(
                serviceId.value,
                realmId.value,
                RuntimePlacement.PRIMARY_ENGINE,
            ),
        directories =
            com.typewritermc.loader.api.HostedRuntimeDirectories(
                root.resolve("state"),
                root.resolve("deployment"),
            ),
        artifacts = HostedArtifactPackage(HostedArtifact(artifact, manifest), emptyList(), emptyList()),
        publicationTarget = implementationTarget(manifest.id, manifest.version, ArtifactDigest.sha256("runtime".encodeToByteArray())),
        engineImplementation = implementationTarget(manifest.id, manifest.version, ArtifactDigest.sha256("runtime".encodeToByteArray())),
        facts = emptyMap(),
        host = host,
    )

    fun envelope(
        attempt: RolloutAttempt,
        reference: ProjectionReference,
        command: RolloutCommand,
    ) = RolloutEnvelope(realmId, attempt, setOf(serviceId), mapOf(serviceId to reference), command)

    fun projection(
        reference: ProjectionReference,
        includeExtension: Boolean = false,
    ): HostDeploymentProjection {
        val runtime = artifact("typewritermc:paper", ArtifactKind.ENGINE, "runtime")
        val extensions =
            if (includeExtension) {
                listOf(
                    ProjectedExtension(
                        artifact("typewritermc:extension", ArtifactKind.EXTENSION, "extension"),
                        listOf(
                            ProjectedSourcePart(
                                "paper",
                                SourcePartDisposition.Eligible(setOf(RuntimePlacement.PRIMARY_ENGINE)),
                            ),
                            ProjectedSourcePart(
                                "panel",
                                SourcePartDisposition.Eligible(setOf(RuntimePlacement.PANEL_ENGINE)),
                            ),
                        ),
                    ),
                )
            } else {
                emptyList()
            }
        val implementation = implementationTarget(runtime.coordinate.id, runtime.coordinate.version, runtime.digest)
        return HostDeploymentProjection(
            realmId.value,
            reference.generation,
            serviceId,
            listOf(ProjectedRuntime.primaryEngine(runtime).copy(implementation = implementation)),
            extensions,
            implementation,
            emptyMap(),
        )
    }

    private fun artifact(
        id: String,
        kind: ArtifactKind,
        content: String,
    ): DeploymentArtifact {
        val bytes = content.encodeToByteArray()
        return DeploymentArtifact(
            ArtifactCoordinate(ArtifactId(id), ArtifactVersion("1.0.0")),
            kind,
            ArtifactDigest.sha256(bytes),
            bytes.size.toLong(),
        )
    }
}

private fun implementationTarget(
    id: ArtifactId,
    version: ArtifactVersion,
    digest: ArtifactDigest,
) = EngineImplementationTarget(
    placement = RuntimePlacement.PRIMARY_ENGINE,
    engine =
        EngineImplementationArtifact(
            id,
            version,
            digest,
            emptyList(),
        ),
    extensions = emptyList(),
)

private fun participantFixture(scope: TestScope): ParticipantFixture {
    val root = Files.createTempDirectory("participant")
    val serviceId = ServiceId("service")
    val realmId = RealmId("realm")
    val projections = mutableMapOf<ProjectionReference, HostDeploymentProjection>()
    val contexts = mutableListOf<HostedDeploymentContext>()
    val classPaths = mutableListOf<List<Path>>()
    val runtimes = mutableListOf<RecordingRuntime>()
    val events = mutableListOf<ParticipantStateChanged>()
    val blobs = FileDigestBlobStore(root)
    val shared = SharedArtifactService(realmId.value, blobs, FileSharedArtifactRepository(root.resolve("shared.cbor")))
    val host =
        object : HostedRuntimeHost {
            override val messaging: StateFlow<HostedMessagingSession?> = MutableStateFlow(null)
            override val openTelemetry: OpenTelemetry = OpenTelemetry.noop()
            override val sharedArtifacts = shared
        }
    val stager =
        HostedRuntimeStager { context ->
            contexts += context
            classPaths += context.artifacts.executableArtifacts
            val runtime = RecordingRuntime()
            runtimes += runtime
            LoadedHostedRuntime(runtime, URLClassLoader(emptyArray<java.net.URL>()))
        }
    val participant =
        HostRolloutParticipant(
            realmId,
            serviceId,
            root,
            host,
            object : ProjectionSource {
                override suspend fun fetch(reference: ProjectionReference) = projections.getValue(reference)
            },
            object : VerifiedArtifactSource {
                override suspend fun fetch(digest: ArtifactDigest): Path =
                    root.resolve(digest.value).also { path ->
                        if (Files.notExists(path)) {
                            val manifest =
                                if (digest == ArtifactDigest.sha256("extension".encodeToByteArray())) {
                                    ExtensionManifest(
                                        id = ArtifactId("typewritermc:extension"),
                                        version = ArtifactVersion("1.0.0"),
                                        sourceParts = listOf(CommonExtensionSourcePart),
                                        buildProvenance = emptyList(),
                                        contributions = emptyList(),
                                    )
                                } else {
                                    EngineManifest(
                                        id = ArtifactId("typewritermc:paper"),
                                        version = ArtifactVersion("1.0.0"),
                                        hostApi = VersionConstraint("^1"),
                                        runtimeEntrypointClass = "fixture.Runtime",
                                        directCapabilities = emptyList(),
                                        resolvedCapabilities = emptyList(),
                                        bundledComponents = emptyList(),
                                        contributions = emptyList(),
                                    )
                                }
                            Files.createDirectories(path.parent)
                            ZipOutputStream(Files.newOutputStream(path)).use { archive ->
                                archive.putNextEntry(ZipEntry(IMPRINT_MANIFEST_PATH))
                                archive.write(ImprintManifestCodec.encode(manifest))
                                archive.closeEntry()
                            }
                        }
                    }
            },
            { event -> events += event },
            scope,
            stager,
            1.seconds,
        )
    return ParticipantFixture(serviceId, realmId, host, participant, projections, contexts, classPaths, runtimes, events, root)
}

class TestHostedRuntimeEntrypoint : HostedRuntimeEntrypoint {
    override suspend fun stage(context: HostedDeploymentContext): StagedHostedRuntime = RecordingRuntime().also { stagedRuntime = it }

    companion object {
        var stagedRuntime: StagedHostedRuntime? = null
    }
}

class NoZeroArgumentHostedRuntimeEntrypoint(
    private val marker: String,
) : HostedRuntimeEntrypoint {
    override suspend fun stage(context: HostedDeploymentContext): StagedHostedRuntime = error(marker)
}

class ThrowingHostedRuntimeEntrypoint : HostedRuntimeEntrypoint {
    override suspend fun stage(context: HostedDeploymentContext): StagedHostedRuntime = error("fixture stage failure")
}

private class RecordingRuntime : StagedHostedRuntime {
    val healthState = MutableStateFlow<RuntimeHealth>(RuntimeHealth.Staged)
    override val health: StateFlow<RuntimeHealth> = healthState
    val operations = mutableListOf<String>()
    val failOn = mutableSetOf<String>()
    val suspendOn = mutableSetOf<String>()

    override suspend fun activate() {
        operations += "activate"
        failIfRequested("activate")
        healthState.value = RuntimeHealth.Healthy
    }

    override suspend fun quiesce() {
        operations += "quiesce"
        failIfRequested("quiesce")
    }

    override suspend fun resume() {
        operations += "resume"
        failIfRequested("resume")
        healthState.value = RuntimeHealth.Healthy
    }

    override suspend fun close() {
        operations += "close"
        failIfRequested("close")
    }

    private suspend fun failIfRequested(operation: String) {
        if (operation in suspendOn) awaitCancellation()
        if (operation in failOn) error("Fixture $operation failure")
    }
}
