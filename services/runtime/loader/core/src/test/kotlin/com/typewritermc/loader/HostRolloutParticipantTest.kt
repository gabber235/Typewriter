package com.typewritermc.loader

import com.typewritermc.imprint.ArtifactId
import com.typewritermc.imprint.ArtifactKind
import com.typewritermc.imprint.ArtifactVersion
import com.typewritermc.loader.api.HostedDeploymentContext
import com.typewritermc.loader.api.HostedMessagingSession
import com.typewritermc.loader.api.HostedRuntimeHost
import com.typewritermc.loader.api.RuntimeHealth
import com.typewritermc.loader.api.RuntimePlacement
import com.typewritermc.loader.api.SourcePartDisposition
import com.typewritermc.loader.api.StagedHostedRuntime
import com.typewritermc.loader.artifact.ArtifactCoordinate
import com.typewritermc.loader.artifact.ArtifactDigest
import com.typewritermc.loader.artifact.DeploymentArtifact
import com.typewritermc.loader.artifact.FileDigestBlobStore
import com.typewritermc.loader.deployment.DeploymentGeneration
import com.typewritermc.loader.deployment.HostDeploymentProjection
import com.typewritermc.loader.deployment.HostId
import com.typewritermc.loader.deployment.ProjectedExtension
import com.typewritermc.loader.deployment.ProjectedRuntime
import com.typewritermc.loader.deployment.ProjectedSourcePart
import com.typewritermc.loader.rollout.HostRolloutParticipant
import com.typewritermc.loader.rollout.ParticipantStateChanged
import com.typewritermc.loader.rollout.ParticipantStatus
import com.typewritermc.loader.rollout.ProjectionReference
import com.typewritermc.loader.rollout.ProjectionSource
import com.typewritermc.loader.rollout.RealmId
import com.typewritermc.loader.rollout.RollbackTarget
import com.typewritermc.loader.rollout.RolloutAttempt
import com.typewritermc.loader.rollout.RolloutCommand
import com.typewritermc.loader.rollout.RolloutEnvelope
import com.typewritermc.loader.rollout.VerifiedArtifactSource
import com.typewritermc.loader.runtime.HostedRuntimeStager
import com.typewritermc.loader.runtime.LoadedHostedRuntime
import com.typewritermc.loader.shared.FileSharedArtifactRepository
import com.typewritermc.loader.shared.SharedArtifactService
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.matchers.collections.shouldContainExactly
import io.kotest.matchers.shouldBe
import io.opentelemetry.api.OpenTelemetry
import kotlinx.coroutines.ExperimentalCoroutinesApi
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.test.TestScope
import kotlinx.coroutines.test.runCurrent
import kotlinx.coroutines.test.runTest
import java.net.URLClassLoader
import java.nio.file.Files
import java.nio.file.Path
import kotlin.time.Duration.Companion.seconds

@OptIn(ExperimentalCoroutinesApi::class)
val HostRolloutParticipantTest by testSuite {
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

    test("runtime package preserves every source part disposition") {
        runTest {
            val fixture = participantFixture(this)
            val attempt = RolloutAttempt(2, DeploymentGeneration(2))
            val reference = fixture.reference("mixed")
            fixture.projections[reference] = fixture.projection(reference, includeExtension = true)

            fixture.participant.handle(fixture.envelope(attempt, reference, RolloutCommand.Stage)).accepted shouldBe true

            val context = fixture.stagedContexts.single()
            val extension = context.artifacts.extensions.single()
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
                    mapOf(fixture.hostId to RollbackTarget.Projection(baseline)),
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
    val hostId: HostId,
    val realmId: RealmId,
    val participant: HostRolloutParticipant,
    val projections: MutableMap<ProjectionReference, HostDeploymentProjection>,
    val stagedContexts: MutableList<HostedDeploymentContext>,
    val classPaths: MutableList<List<Path>>,
    val runtimes: MutableList<RecordingRuntime>,
    val events: MutableList<ParticipantStateChanged>,
    private val root: Path,
) {
    fun reference(name: String) =
        ProjectionReference(
            realmId,
            DeploymentGeneration(name.length.toLong()),
            hostId,
            ArtifactDigest.sha256(name.encodeToByteArray()),
        )

    fun envelope(
        attempt: RolloutAttempt,
        reference: ProjectionReference,
        command: RolloutCommand,
    ) = RolloutEnvelope(realmId, attempt, setOf(hostId), mapOf(hostId to reference), command)

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
        return HostDeploymentProjection(
            realmId.value,
            reference.generation,
            hostId,
            listOf(ProjectedRuntime.primaryEngine(runtime)),
            extensions,
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

private fun participantFixture(scope: TestScope): ParticipantFixture {
    val root = Files.createTempDirectory("participant")
    val hostId = HostId("host")
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
        HostedRuntimeStager { context, classPath ->
            contexts += context
            classPaths += classPath
            val runtime = RecordingRuntime()
            runtimes += runtime
            LoadedHostedRuntime(runtime, URLClassLoader(emptyArray<java.net.URL>()))
        }
    val participant =
        HostRolloutParticipant(
            realmId,
            hostId,
            root,
            host,
            object : ProjectionSource {
                override suspend fun fetch(reference: ProjectionReference) = projections.getValue(reference)
            },
            object : VerifiedArtifactSource {
                override suspend fun fetch(digest: ArtifactDigest): Path =
                    root.resolve(digest.value).also { Files.write(it, byteArrayOf()) }
            },
            { event -> events += event },
            scope,
            stager,
            1.seconds,
        )
    return ParticipantFixture(hostId, realmId, participant, projections, contexts, classPaths, runtimes, events, root)
}

private class RecordingRuntime : StagedHostedRuntime {
    val healthState = MutableStateFlow<RuntimeHealth>(RuntimeHealth.Staged)
    override val health: StateFlow<RuntimeHealth> = healthState
    val operations = mutableListOf<String>()
    val failOn = mutableSetOf<String>()

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

    private fun failIfRequested(operation: String) {
        if (operation in failOn) error("Fixture $operation failure")
    }
}
