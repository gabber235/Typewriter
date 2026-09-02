@file:OptIn(kotlinx.coroutines.ExperimentalCoroutinesApi::class)

package com.typewritermc.loader

import com.typewritermc.imprint.ArtifactId
import com.typewritermc.imprint.ArtifactKind
import com.typewritermc.imprint.ArtifactRequirement
import com.typewritermc.imprint.ArtifactVersion
import com.typewritermc.imprint.EngineManifest
import com.typewritermc.imprint.IMPRINT_MANIFEST_PATH
import com.typewritermc.imprint.ImprintManifestCodec
import com.typewritermc.imprint.RealmManifest
import com.typewritermc.imprint.VersionConstraint
import com.typewritermc.loader.api.RealmServiceAddress
import com.typewritermc.loader.api.RuntimePlacement
import com.typewritermc.loader.api.artifact.BlobResult
import com.typewritermc.loader.api.artifact.ProducerMetadata
import com.typewritermc.loader.api.artifact.PublishResult
import com.typewritermc.loader.api.artifact.PublishSharedArtifact
import com.typewritermc.loader.api.artifact.SharedArtifactId
import com.typewritermc.loader.api.artifact.SharedArtifactProvenance
import com.typewritermc.loader.artifact.ArtifactCoordinate
import com.typewritermc.loader.artifact.ArtifactDigest
import com.typewritermc.loader.artifact.ArtifactInboxReconciler
import com.typewritermc.loader.artifact.BlobMetadata
import com.typewritermc.loader.artifact.DeploymentArtifact
import com.typewritermc.loader.artifact.FileCandidateRepository
import com.typewritermc.loader.artifact.FileDigestBlobStore
import com.typewritermc.loader.artifact.TransferId
import com.typewritermc.loader.deployment.DeploymentContent
import com.typewritermc.loader.deployment.DeploymentContentCodec
import com.typewritermc.loader.deployment.DeploymentGeneration
import com.typewritermc.loader.deployment.DeploymentSnapshot
import com.typewritermc.loader.deployment.HostId
import com.typewritermc.loader.deployment.RealmTopology
import com.typewritermc.loader.deployment.projectFor
import com.typewritermc.loader.rollout.ActiveBaseline
import com.typewritermc.loader.rollout.ActiveProjectionReference
import com.typewritermc.loader.rollout.BlobProjectionRepository
import com.typewritermc.loader.rollout.CommandAcceptance
import com.typewritermc.loader.rollout.CoordinatedRollout
import com.typewritermc.loader.rollout.FileRolloutStateRepository
import com.typewritermc.loader.rollout.ParticipantStateChanged
import com.typewritermc.loader.rollout.ParticipantStatus
import com.typewritermc.loader.rollout.ProbeParticipantStatus
import com.typewritermc.loader.rollout.ProbeRealmHosts
import com.typewritermc.loader.rollout.ProjectionReference
import com.typewritermc.loader.rollout.RealmHostPresence
import com.typewritermc.loader.rollout.RealmId
import com.typewritermc.loader.rollout.RetainedProjection
import com.typewritermc.loader.rollout.RolloutAttempt
import com.typewritermc.loader.rollout.RolloutCommand
import com.typewritermc.loader.rollout.RolloutEnvelope
import com.typewritermc.loader.rollout.RolloutMessenger
import com.typewritermc.loader.rollout.RuntimeHealthSnapshot
import com.typewritermc.loader.rollout.toArtifactHostAssignment
import com.typewritermc.loader.rollout.toChildRuntimeState
import com.typewritermc.loader.shared.FileSharedArtifactRepository
import com.typewritermc.loader.shared.SharedArtifactService
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.assertions.throwables.shouldThrow
import io.kotest.matchers.collections.shouldContainExactly
import io.kotest.matchers.shouldBe
import kotlinx.coroutines.async
import kotlinx.coroutines.test.advanceTimeBy
import kotlinx.coroutines.test.runCurrent
import kotlinx.coroutines.test.runTest
import skirout.kernel.v1.record_id.RecordId
import skirout.kernel.v1.record_id.RecordIdKey
import skirout.service.v1.topology.ChildRuntimeState
import skirout.service.v1.topology.ChildRuntimeStatus
import skirout.service.v1.topology.EngineInstance
import skirout.service.v1.topology.EngineTarget
import skirout.service.v1.topology.OwnerHost
import skirout.service.v1.topology.RealmInfo
import skirout.service.v1.topology.RealmInstance
import skirout.service.v1.topology.WatchHostExecutionResponse
import java.nio.file.Files
import java.nio.file.Path
import java.time.Instant
import java.util.zip.ZipEntry
import java.util.zip.ZipOutputStream
import kotlin.time.Duration
import kotlin.time.Duration.Companion.milliseconds
import kotlin.time.Duration.Companion.seconds
import kotlin.time.TestTimeSource

val ArtifactDistributionTest by testSuite {
    test("Realm service addresses preserve the established authority family") {
        val address = RealmServiceAddress(realmId = "quests", organizationId = "writers")

        address.request("shared.publish") shouldBe
            "service.to.quests.organization.writers.realm.shared.publish"
        address.event("catalog.invalidate") shouldBe
            "service.from.quests.organization.writers.realm.catalog.invalidate"
        shouldThrow<IllegalArgumentException> {
            address.request("shared.*")
        }
    }

    test("combined host receives Realm panel and primary runtimes as one projection") {
        val realm = artifact("typewritermc:realm", ArtifactKind.REALM, "realm")
        val panel = artifact("typewritermc:panel", ArtifactKind.ENGINE, "panel")
        val primary = artifact("typewritermc:paper", ArtifactKind.ENGINE, "paper")
        val content = DeploymentContent(realm = realm, primaryEngine = primary, panelEngine = panel, extensions = emptyList())
        val snapshot = DeploymentSnapshot(DeploymentGeneration(1), DeploymentContentCodec.digest(content), content)
        val host = HostId("combined")
        val topology =
            RealmTopology(
                realmHost = host,
                primaryEngineHosts = setOf(host),
                hostApis = mapOf(host to ArtifactVersion("1.0.0")),
            )
        val manifests =
            mapOf(
                realm.coordinate.id to
                    RealmManifest(
                        id = realm.coordinate.id,
                        version = realm.coordinate.version,
                        hostApi = VersionConstraint("^1"),
                        contributions = emptyList(),
                    ),
                panel.coordinate.id to engineManifest(panel),
                primary.coordinate.id to engineManifest(primary),
            )

        val projection = snapshot.projectFor("realm", topology, host, manifests)

        projection.hostId shouldBe host
        projection.runtimes.map { it.placement } shouldContainExactly
            listOf(
                RuntimePlacement.PANEL_ENGINE,
                RuntimePlacement.PRIMARY_ENGINE,
                RuntimePlacement.REALM,
            )
    }

    test("blob completion verifies bytes and supports ranged reads") {
        runTest {
            val root = Files.createTempDirectory("typewriter-blobs")
            val store = FileDigestBlobStore(root)
            val bytes = "verified artifact content".encodeToByteArray()
            val expected = BlobMetadata(ArtifactDigest.sha256(bytes), bytes.size.toLong())
            val transfer = TransferId.create()

            store.beginWrite(transfer, expected).shouldSucceed().offset shouldBe 0
            store.write(transfer, 0, bytes.copyOfRange(0, 8)).shouldSucceed() shouldBe 8
            store.write(transfer, 8, bytes.copyOfRange(8, bytes.size)).shouldSucceed() shouldBe bytes.size.toLong()
            store.complete(transfer).shouldSucceed() shouldBe expected
            val chunk = store.read(expected.digest, 3, 7).shouldSucceed()
            chunk.bytes shouldBe bytes.copyOfRange(3, 10)
            chunk.complete shouldBe false
        }
    }

    test("projection references persist canonical verified bytes") {
        runTest {
            val realm = artifact("typewritermc:realm", ArtifactKind.REALM, "realm")
            val panel = artifact("typewritermc:panel", ArtifactKind.ENGINE, "panel")
            val primary = artifact("typewritermc:paper", ArtifactKind.ENGINE, "paper")
            val content = DeploymentContent(realm = realm, primaryEngine = primary, panelEngine = panel, extensions = emptyList())
            val snapshot = DeploymentSnapshot(DeploymentGeneration(1), DeploymentContentCodec.digest(content), content)
            val host = HostId("combined")
            val projection =
                snapshot.projectFor(
                    "realm",
                    RealmTopology(host, setOf(host), mapOf(host to ArtifactVersion("1.0.0"))),
                    host,
                    mapOf(
                        realm.coordinate.id to
                            RealmManifest(
                                id = realm.coordinate.id,
                                version = realm.coordinate.version,
                                hostApi = VersionConstraint("^1"),
                                contributions = emptyList(),
                            ),
                        panel.coordinate.id to engineManifest(panel),
                        primary.coordinate.id to engineManifest(primary),
                    ),
                )
            val repository = BlobProjectionRepository(FileDigestBlobStore(Files.createTempDirectory("typewriter-projections")))

            val reference = repository.publish(projection)

            repository.fetch(reference) shouldBe projection
            shouldThrow<IllegalArgumentException> {
                repository.fetch(reference.copy(hostId = HostId("another")))
            }
        }
    }

    test("combined host participates once in a coordinated rollout") {
        runTest {
            val root = Files.createTempDirectory("typewriter-rollout")
            val realmId = RealmId("realm")
            val host = HostId("combined")
            val topology = RealmTopology(host, setOf(host), mapOf(host to ArtifactVersion("1.0.0")))
            val realm = artifact("typewritermc:realm", ArtifactKind.REALM, "realm")
            val panel = artifact("typewritermc:panel", ArtifactKind.ENGINE, "panel")
            val primary = artifact("typewritermc:paper", ArtifactKind.ENGINE, "paper")
            val content = DeploymentContent(realm = realm, primaryEngine = primary, panelEngine = panel, extensions = emptyList())
            val snapshot = DeploymentSnapshot(DeploymentGeneration(1), DeploymentContentCodec.digest(content), content)
            val manifests =
                mapOf(
                    realm.coordinate.id to
                        RealmManifest(
                            id = realm.coordinate.id,
                            version = realm.coordinate.version,
                            hostApi = VersionConstraint("^1"),
                            contributions = emptyList(),
                        ),
                    panel.coordinate.id to engineManifest(panel),
                    primary.coordinate.id to engineManifest(primary),
                )
            val state = FileRolloutStateRepository(realmId, root)
            val commands = mutableListOf<RolloutEnvelope>()
            var currentStatus: ParticipantStatus? = null
            var activeProjection: ActiveProjectionReference? = null
            val messenger =
                object : RolloutMessenger {
                    override suspend fun discover(
                        probe: ProbeRealmHosts,
                        expected: Set<HostId>,
                        timeout: Duration,
                    ) = listOf(
                        RealmHostPresence(
                            probe.probeId,
                            host,
                            ArtifactVersion("1.0.0"),
                            RuntimePlacement.entries.toSet(),
                            activeProjection,
                        ),
                    )

                    override suspend fun command(
                        envelope: RolloutEnvelope,
                        timeout: Duration,
                    ): List<CommandAcceptance> {
                        commands += envelope
                        val reference = envelope.projections.getValue(host)
                        currentStatus =
                            when (envelope.command) {
                                RolloutCommand.Stage -> {
                                    ParticipantStatus.Staged(
                                        envelope.attempt,
                                        host,
                                        reference,
                                        activeProjection?.let(ActiveBaseline::Present) ?: ActiveBaseline.Empty,
                                    )
                                }

                                RolloutCommand.Commit -> {
                                    ParticipantStatus
                                        .Active(
                                            envelope.attempt,
                                            host,
                                            ActiveProjectionReference(reference, RuntimeHealthSnapshot.Healthy),
                                            RetainedProjection.None,
                                        ).also { activeProjection = it.current }
                                }

                                RolloutCommand.Abort -> {
                                    ParticipantStatus.Idle(envelope.attempt, host)
                                }

                                is RolloutCommand.Rollback -> {
                                    when (val target = envelope.command.targets.getValue(host)) {
                                        com.typewritermc.loader.rollout.RollbackTarget.Empty -> {
                                            activeProjection = null
                                            ParticipantStatus.Idle(envelope.attempt, host)
                                        }

                                        is com.typewritermc.loader.rollout.RollbackTarget.Projection -> {
                                            ParticipantStatus
                                                .Active(
                                                    envelope.attempt,
                                                    host,
                                                    ActiveProjectionReference(target.reference, RuntimeHealthSnapshot.Healthy),
                                                    RetainedProjection.None,
                                                ).also { activeProjection = it.current }
                                        }
                                    }
                                }
                            }
                        state.record(ParticipantStateChanged(realmId, requireNotNull(currentStatus)))
                        return listOf(CommandAcceptance(host, true))
                    }

                    override suspend fun statuses(
                        probe: ProbeParticipantStatus,
                        expected: Set<HostId>,
                        timeout: Duration,
                    ): Map<HostId, ParticipantStatus> = currentStatus?.let { mapOf(host to it) }.orEmpty()
                }
            val blobs = FileDigestBlobStore(root)

            val rollout =
                CoordinatedRollout(
                    realmId,
                    topology,
                    manifests,
                    messenger,
                    BlobProjectionRepository(blobs),
                    state,
                    requestTimeout = 1.seconds,
                    participantDeadline = 1.seconds,
                    healthyDuration = Duration.ZERO,
                )

            rollout.rollOut(snapshot)

            val committed = requireNotNull(state.current())
            committed.snapshot shouldBe snapshot
            commands.map { it.command } shouldContainExactly listOf(RolloutCommand.Stage, RolloutCommand.Commit)
            commands.forEach { it.participants shouldBe setOf(host) }

            commands.clear()
            activeProjection = null
            rollout.reconcileCommitted(committed)

            commands.map { it.command } shouldContainExactly listOf(RolloutCommand.Stage, RolloutCommand.Commit)
            commands.forEach { it.participants shouldBe setOf(host) }
        }
    }

    test("shared publication is optimistic durable and content addressed") {
        runTest {
            val root = Files.createTempDirectory("typewriter-shared")
            val blobs = FileDigestBlobStore(root)
            val repository = FileSharedArtifactRepository(root.resolve("shared.cbor"))
            val service = SharedArtifactService("realm", blobs, repository)
            val bytes = "road network".encodeToByteArray()
            val metadata = BlobMetadata(ArtifactDigest.sha256(bytes), bytes.size.toLong())
            val transfer = TransferId.create()
            blobs.beginWrite(transfer, metadata).shouldSucceed()
            blobs.write(transfer, 0, bytes).shouldSucceed()
            blobs.complete(transfer).shouldSucceed()
            val command =
                PublishSharedArtifact(
                    SharedArtifactId("019d1f6c-1d2e-7249-9fa3-86964e89721d"),
                    null,
                    "Road network",
                    "application/vnd.typewriter.road-network",
                    metadata,
                    ProducerMetadata(mapOf("world" to "main")),
                    SharedArtifactProvenance.HostedRuntime("paper", "primary"),
                )

            val published = service.publish(command) as PublishResult.Published

            service.publish(command.copy(expectedRevision = published.descriptor.revision)) shouldBe
                PublishResult.Unchanged(published.descriptor)
            service.publish(command) shouldBe PublishResult.Unchanged(published.descriptor)
            service.catalog().artifacts shouldContainExactly listOf(published.descriptor)
            FileSharedArtifactRepository(root.resolve("shared.cbor")).catalog().artifacts shouldContainExactly
                listOf(published.descriptor)
        }
    }

    test("stabilization restarts after an incomplete authoritative status snapshot") {
        runTest {
            val root = Files.createTempDirectory("typewriter-stabilization")
            val realmId = RealmId("realm")
            val host = HostId("combined")
            val topology = RealmTopology(host, setOf(host), mapOf(host to ArtifactVersion("1.0.0")))
            val realm = artifact("typewritermc:realm", ArtifactKind.REALM, "realm")
            val panel = artifact("typewritermc:panel", ArtifactKind.ENGINE, "panel")
            val primary = artifact("typewritermc:paper", ArtifactKind.ENGINE, "paper")
            val content = DeploymentContent(realm = realm, primaryEngine = primary, panelEngine = panel, extensions = emptyList())
            val snapshot = DeploymentSnapshot(DeploymentGeneration(1), DeploymentContentCodec.digest(content), content)
            val manifests =
                mapOf(
                    realm.coordinate.id to
                        RealmManifest(
                            id = realm.coordinate.id,
                            version = realm.coordinate.version,
                            hostApi = VersionConstraint("^1"),
                            contributions = emptyList(),
                        ),
                    panel.coordinate.id to engineManifest(panel),
                    primary.coordinate.id to engineManifest(primary),
                )
            val state = FileRolloutStateRepository(realmId, root)
            var status: ParticipantStatus? = null
            var activeStatusCalls = 0
            val timeSource = TestTimeSource()
            val messenger =
                object : RolloutMessenger {
                    override suspend fun discover(
                        probe: ProbeRealmHosts,
                        expected: Set<HostId>,
                        timeout: Duration,
                    ) = listOf(
                        RealmHostPresence(
                            probe.probeId,
                            host,
                            ArtifactVersion("1.0.0"),
                            RuntimePlacement.entries.toSet(),
                            null,
                        ),
                    )

                    override suspend fun command(
                        envelope: RolloutEnvelope,
                        timeout: Duration,
                    ): List<CommandAcceptance> {
                        val reference = envelope.projections.getValue(host)
                        status =
                            when (envelope.command) {
                                RolloutCommand.Stage -> {
                                    ParticipantStatus.Staged(envelope.attempt, host, reference, ActiveBaseline.Empty)
                                }

                                RolloutCommand.Commit -> {
                                    ParticipantStatus.Active(
                                        envelope.attempt,
                                        host,
                                        ActiveProjectionReference(reference, RuntimeHealthSnapshot.Healthy),
                                        RetainedProjection.None,
                                    )
                                }

                                RolloutCommand.Abort -> {
                                    ParticipantStatus.Idle(envelope.attempt, host)
                                }

                                is RolloutCommand.Rollback -> {
                                    ParticipantStatus.Idle(envelope.attempt, host)
                                }
                            }
                        return listOf(CommandAcceptance(host, true))
                    }

                    override suspend fun statuses(
                        probe: ProbeParticipantStatus,
                        expected: Set<HostId>,
                        timeout: Duration,
                    ): Map<HostId, ParticipantStatus> {
                        val current = status ?: return emptyMap()
                        if (current is ParticipantStatus.Active) {
                            activeStatusCalls++
                            timeSource += 100.milliseconds
                            if (activeStatusCalls == 2) return emptyMap()
                        }
                        return mapOf(host to current)
                    }
                }
            val rollout =
                CoordinatedRollout(
                    realmId,
                    topology,
                    manifests,
                    messenger,
                    BlobProjectionRepository(FileDigestBlobStore(root)),
                    state,
                    requestTimeout = 1.seconds,
                    participantDeadline = 2.seconds,
                    healthyDuration = 150.milliseconds,
                    timeSource = timeSource,
                )

            rollout.rollOut(snapshot)

            activeStatusCalls shouldBe 5
            state.current()?.snapshot shouldBe snapshot
        }
    }

    test("backend execution assignments preserve combined host roles and artifact coordinates") {
        val host = OwnerHost(id = record("service_host", "combined"), name = "Combined")
        val realmId = record("realm_instance", "realm")
        val target = EngineTarget(engineId = "typewritermc:paper", versionConstraint = "^1")
        val state =
            ChildRuntimeState(
                status = ChildRuntimeStatus.ABSENT,
                activeArtifactVersion = null,
                message = null,
                updatedAt = Instant.EPOCH,
            )
        val realm = RealmInstance(realmId = realmId, ownerHost = host, revision = 1, targetEngine = target, state = state)
        val engine =
            EngineInstance(
                engineId = record("engine_instance", "engine"),
                ownerHost = host,
                realm = RealmInfo(realmId = realmId, ownerHost = host),
                revision = 1,
                target = target,
                state = state,
            )
        val panel = ArtifactRequirement(ArtifactId("typewritermc:panel"), VersionConstraint("^1"))

        val assignment =
            WatchHostExecutionResponse
                .createDesired(topologyRevision = 1, realm = realm, engine = engine)
                .toArtifactHostAssignment(panel, "service-id")

        assignment?.realmId shouldBe RealmId("realm")
        assignment?.roles shouldBe RuntimePlacement.entries.toSet()
        assignment?.primaryEngine?.id shouldBe ArtifactId("typewritermc:paper")
        assignment?.intent?.panelEngine shouldBe panel
        assignment?.topologyRevision shouldBe 1
        assignment?.serviceId shouldBe "service-id"
        WatchHostExecutionResponse
            .createDesired(topologyRevision = 2, realm = null, engine = null)
            .toArtifactHostAssignment(panel) shouldBe null
    }

    test("participant health maps to backend execution state") {
        val hostId = HostId("host")
        val generation = DeploymentGeneration(1)
        val reference =
            ProjectionReference(
                realmId = RealmId("realm"),
                generation = generation,
                hostId = hostId,
                blob = ArtifactDigest.sha256("projection".encodeToByteArray()),
                runtimeVersions = mapOf(RuntimePlacement.PRIMARY_ENGINE to ArtifactVersion("1.2.3")),
            )
        val status =
            ParticipantStatus.Active(
                attempt = RolloutAttempt(1, generation),
                hostId = hostId,
                current = ActiveProjectionReference(reference, RuntimeHealthSnapshot.Healthy),
                retained = RetainedProjection.None,
            )
        val now = Instant.parse("2026-09-02T00:00:00Z")

        status.toChildRuntimeState(now, RuntimePlacement.PRIMARY_ENGINE) shouldBe
            ChildRuntimeState(
                status = ChildRuntimeStatus.ACTIVE,
                activeArtifactVersion = "1.2.3",
                message = null,
                updatedAt = now,
            )
        status
            .copy(current = status.current.copy(health = RuntimeHealthSnapshot.Unhealthy(listOf("probe failed"))))
            .toChildRuntimeState(now, RuntimePlacement.PRIMARY_ENGINE) shouldBe
            ChildRuntimeState(
                status = ChildRuntimeStatus.FAILED,
                activeArtifactVersion = "1.2.3",
                message = "probe failed",
                updatedAt = now,
            )
    }

    test("inbox reconciliation preserves accepted content across unstable and malformed replacements") {
        runTest {
            val root = Files.createTempDirectory("typewriter-inbox")
            val candidates = FileCandidateRepository(root)
            val reconciler = ArtifactInboxReconciler(root, FileDigestBlobStore(root), candidates, Duration.ZERO)
            val artifact = root.resolve("inbox/manual/realm.jar")
            writeArtifactJar(
                artifact,
                RealmManifest(
                    id = ArtifactId("typewritermc:realm"),
                    version = ArtifactVersion("1.0.0"),
                    hostApi = VersionConstraint("^1"),
                    contributions = emptyList(),
                ),
            )

            reconciler.reconcile()
            val accepted = candidates.candidates().single()
            reconciler.reconcile()
            candidates.candidates().single().importRevision shouldBe accepted.importRevision

            Files.write(artifact, "malformed replacement".encodeToByteArray())
            reconciler.reconcile()

            candidates.candidates().single() shouldBe accepted
            candidates.diagnostics().single().relativePath shouldBe "manual/realm.jar"
        }
    }

    test("inbox deletion requires two complete missing passes") {
        runTest {
            val root = Files.createTempDirectory("typewriter-inbox-removal")
            val candidates = FileCandidateRepository(root)
            val reconciler = ArtifactInboxReconciler(root, FileDigestBlobStore(root), candidates, Duration.ZERO)
            val artifact = root.resolve("inbox/development/realm.jar")
            writeArtifactJar(
                artifact,
                RealmManifest(
                    id = ArtifactId("typewritermc:realm"),
                    version = ArtifactVersion("1.0.0"),
                    hostApi = VersionConstraint("^1"),
                    contributions = emptyList(),
                ),
            )
            reconciler.reconcile()
            Files.delete(artifact)

            reconciler.reconcile()
            candidates.candidates().size shouldBe 1
            reconciler.reconcile()
            candidates.candidates().size shouldBe 0
        }
    }

    test("unstable inbox replacement preserves the accepted candidate") {
        runTest {
            val root = Files.createTempDirectory("typewriter-inbox-unstable")
            val candidates = FileCandidateRepository(root)
            val blobs = FileDigestBlobStore(root)
            val artifact = root.resolve("inbox/manual/realm.jar")
            writeArtifactJar(
                artifact,
                RealmManifest(
                    id = ArtifactId("typewritermc:realm"),
                    version = ArtifactVersion("1.0.0"),
                    hostApi = VersionConstraint("^1"),
                    contributions = emptyList(),
                ),
            )
            ArtifactInboxReconciler(root, blobs, candidates, Duration.ZERO).reconcile()
            val accepted = candidates.candidates().single()
            val reconcile =
                async {
                    ArtifactInboxReconciler(root, blobs, candidates, 50.milliseconds).reconcile()
                }
            runCurrent()
            Files.write(artifact, "replacement in progress".encodeToByteArray())
            advanceTimeBy(51)
            reconcile.await()

            candidates.candidates().single() shouldBe accepted
            candidates.diagnostics().size shouldBe 0
        }
    }
}

private fun record(
    table: String,
    key: String,
): RecordId = RecordId(table = table, key = RecordIdKey.StringWrapper(key))

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

private fun engineManifest(artifact: DeploymentArtifact): EngineManifest =
    EngineManifest(
        id = artifact.coordinate.id,
        version = artifact.coordinate.version,
        hostApi = VersionConstraint("^1"),
        directCapabilities = emptyList(),
        resolvedCapabilities = emptyList(),
        bundledComponents = emptyList(),
        contributions = emptyList(),
    )

private fun <Value> BlobResult<Value>.shouldSucceed(): Value =
    when (this) {
        is BlobResult.Success -> value
        else -> error("Expected a successful blob result but received $this.")
    }

private fun writeArtifactJar(
    path: Path,
    manifest: com.typewritermc.imprint.ImprintManifest,
) {
    Files.createDirectories(path.parent)
    ZipOutputStream(Files.newOutputStream(path)).use { archive ->
        archive.putNextEntry(ZipEntry(IMPRINT_MANIFEST_PATH))
        archive.write(ImprintManifestCodec.encode(manifest))
        archive.closeEntry()
    }
}
