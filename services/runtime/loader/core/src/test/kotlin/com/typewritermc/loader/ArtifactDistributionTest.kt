@file:OptIn(kotlinx.coroutines.ExperimentalCoroutinesApi::class)

package com.typewritermc.loader

import com.typewritermc.imprint.ArtifactId
import com.typewritermc.imprint.ArtifactKind
import com.typewritermc.imprint.ArtifactRequirement
import com.typewritermc.imprint.ArtifactVersion
import com.typewritermc.imprint.CommonExtensionSourcePart
import com.typewritermc.imprint.EngineExtensionSourcePart
import com.typewritermc.imprint.ExtensionManifest
import com.typewritermc.imprint.RealmManifest
import com.typewritermc.imprint.ResolvedArtifact
import com.typewritermc.imprint.VersionConstraint
import com.typewritermc.loader.api.EngineImplementationArtifact
import com.typewritermc.loader.api.RuntimePlacement
import com.typewritermc.loader.api.artifact.PublishResult
import com.typewritermc.loader.artifact.ArtifactInboxReconciler
import com.typewritermc.loader.artifact.CommunicatorBlobEndpoint
import com.typewritermc.loader.artifact.FileCandidateRepository
import com.typewritermc.loader.artifact.FileDigestBlobStore
import com.typewritermc.loader.artifact.StableRealmArtifactRoutes
import com.typewritermc.loader.artifact.TRANSFERRED_BLOB_MAX_BYTES
import com.typewritermc.loader.artifact.toSkir
import com.typewritermc.loader.deployment.DeploymentContent
import com.typewritermc.loader.deployment.DeploymentContentCodec
import com.typewritermc.loader.deployment.DeploymentGeneration
import com.typewritermc.loader.deployment.DeploymentSnapshot
import com.typewritermc.loader.deployment.RealmDeploymentSelection
import com.typewritermc.loader.deployment.projectFor
import com.typewritermc.loader.rollout.RealmId
import com.typewritermc.loader.rollout.deploymentSelectionOrNull
import com.typewritermc.loader.rollout.testing.presence
import com.typewritermc.loader.rollout.toChildRuntimeState
import com.typewritermc.loader.rollout.toDesiredHostExecution
import com.typewritermc.loader.rollout.toSkir
import com.typewritermc.loader.shared.FileSharedArtifactRepository
import com.typewritermc.loader.shared.SharedArtifactService
import com.typewritermc.loader.testing.FetchForbiddenSharedArtifactAccess
import com.typewritermc.loader.testing.active
import com.typewritermc.loader.testing.deploymentArtifact
import com.typewritermc.loader.testing.engineManifest
import com.typewritermc.loader.testing.realmManifest
import com.typewritermc.loader.testing.record
import com.typewritermc.loader.testing.sharedPublication
import com.typewritermc.loader.testing.shouldSucceed
import com.typewritermc.loader.testing.status
import com.typewritermc.loader.testing.writeArtifactJar
import com.typewritermc.protocol.transport.RealmRouteScope
import com.typewritermc.protocol.transport.generated.TRANSPORT_LIMITS
import com.typewritermc.services.libs.communicator.client.Communicator
import com.typewritermc.services.libs.communicator.router.RouterResult
import com.typewritermc.services.libs.communicator.router.communicatorRoutes
import com.typewritermc.services.libs.communicator.testing.MemoryNatsBroker
import com.typewritermc.services.libs.filetransfer.blob.ArtifactDigest
import com.typewritermc.services.libs.filetransfer.blob.BlobMetadata
import com.typewritermc.services.libs.filetransfer.blob.BlobResult
import com.typewritermc.services.libs.filetransfer.blob.StoreResult
import com.typewritermc.services.libs.registrar.ServiceId
import com.typewritermc.services.libs.telemetry.testing.TelemetryTestHarness
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.matchers.collections.shouldContainExactly
import io.kotest.matchers.shouldBe
import io.kotest.matchers.shouldNotBe
import io.kotest.matchers.string.shouldContain
import io.opentelemetry.api.trace.propagation.W3CTraceContextPropagator
import io.opentelemetry.context.propagation.ContextPropagators
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.async
import kotlinx.coroutines.test.advanceTimeBy
import kotlinx.coroutines.test.runCurrent
import kotlinx.coroutines.test.runTest
import kotlinx.coroutines.withContext
import skirout.service.v1.rollout.ActiveProjection
import skirout.service.v1.rollout.ParticipantPhase
import skirout.service.v1.rollout.ProjectionHealth
import skirout.service.v1.rollout.ProjectionReference
import skirout.service.v1.rollout.RealmHostPresence
import skirout.service.v1.rollout.RolloutAttempt
import skirout.service.v1.rollout.RuntimeVersion
import skirout.service.v1.topology.ChildRuntimeState
import skirout.service.v1.topology.ChildRuntimeStatus
import skirout.service.v1.topology.EngineInstance
import skirout.service.v1.topology.EngineTarget
import skirout.service.v1.topology.OwnerHost
import skirout.service.v1.topology.RealmInfo
import skirout.service.v1.topology.RealmInstance
import skirout.service.v1.topology.WatchHostExecutionResponse
import java.nio.file.Files
import java.nio.file.attribute.FileTime
import java.time.Clock
import java.time.Instant
import java.time.ZoneOffset
import kotlin.time.Duration
import kotlin.time.Duration.Companion.milliseconds
import java.time.Duration as JavaDuration

val ArtifactDistributionTest by testSuite {
    test("Realm deployment selection requires one unambiguous Realm host and permits no primary engine") {
        val host = ServiceId("combined")
        val realmOnly = presence(host, setOf(RuntimePlacement.REALM))
        val combined = presence(host, RuntimePlacement.entries.toSet())

        emptyList<RealmHostPresence>().deploymentSelectionOrNull() shouldBe null
        listOf(realmOnly).deploymentSelectionOrNull() shouldBe
            RealmDeploymentSelection(host, emptySet(), mapOf(host to ArtifactVersion("1.0.0")))
        listOf(realmOnly, combined).deploymentSelectionOrNull() shouldBe null
        listOf(combined).deploymentSelectionOrNull() shouldBe
            RealmDeploymentSelection(host, setOf(host), mapOf(host to ArtifactVersion("1.0.0")))
    }

    test("distinct observed service identities remain distinct in deployment selection") {
        val standalone = ServiceId("standalone-service")
        val paper = ServiceId("paper-service")
        val selection =
            listOf(
                presence(standalone, setOf(RuntimePlacement.REALM)),
                presence(paper, setOf(RuntimePlacement.PRIMARY_ENGINE)),
            ).deploymentSelectionOrNull()

        selection shouldBe
            RealmDeploymentSelection(
                realmService = standalone,
                primaryEngineServices = setOf(paper),
                serviceApis = mapOf(standalone to ArtifactVersion("1.0.0"), paper to ArtifactVersion("1.0.0")),
            )
    }

    test("combined host receives Realm panel and primary runtimes as one projection") {
        val realm = deploymentArtifact("typewritermc:realm", ArtifactKind.REALM, "realm")
        val panel = deploymentArtifact("typewritermc:panel", ArtifactKind.ENGINE, "panel")
        val primary = deploymentArtifact("typewritermc:paper", ArtifactKind.ENGINE, "paper")
        val content = DeploymentContent(realm = realm, primaryEngine = primary, panelEngine = panel, extensions = emptyList())
        val snapshot = DeploymentSnapshot(DeploymentGeneration(1), DeploymentContentCodec.digest(content), content)
        val host = ServiceId("combined")
        val selection =
            RealmDeploymentSelection(
                realmService = host,
                primaryEngineServices = setOf(host),
                serviceApis = mapOf(host to ArtifactVersion("1.0.0")),
            )
        val manifests =
            mapOf(
                realm.coordinate.id to
                    RealmManifest(
                        id = realm.coordinate.id,
                        version = realm.coordinate.version,
                        hostApi = VersionConstraint("^1"),
                        runtimeEntrypointClass = "fixture.Runtime",
                        contributions = emptyList(),
                    ),
                panel.coordinate.id to engineManifest(panel),
                primary.coordinate.id to engineManifest(primary),
            )

        val projection = snapshot.projectFor("realm", selection, host, manifests)

        projection.serviceId shouldBe host
        projection.runtimes.map { it.placement } shouldContainExactly
            listOf(
                RuntimePlacement.PANEL_ENGINE,
                RuntimePlacement.PRIMARY_ENGINE,
                RuntimePlacement.REALM,
            )
        projection.publicationTarget.engine.id shouldBe primary.coordinate.id
        projection.publicationTarget.engine.digest shouldBe primary.digest
    }

    test("Realm and remote primary engine receive one exact implementation target") {
        val realm = deploymentArtifact("typewritermc:realm", ArtifactKind.REALM, "realm")
        val panel = deploymentArtifact("typewritermc:panel", ArtifactKind.ENGINE, "panel")
        val primary = deploymentArtifact("typewritermc:paper", ArtifactKind.ENGINE, "paper")
        val content = DeploymentContent(realm = realm, primaryEngine = primary, panelEngine = panel, extensions = emptyList())
        val snapshot = DeploymentSnapshot(DeploymentGeneration(1), DeploymentContentCodec.digest(content), content)
        val realmHost = ServiceId("realm")
        val engineHost = ServiceId("engine")
        val selection =
            RealmDeploymentSelection(
                realmService = realmHost,
                primaryEngineServices = setOf(engineHost),
                serviceApis =
                    mapOf(
                        realmHost to ArtifactVersion("1.0.0"),
                        engineHost to ArtifactVersion("1.0.0"),
                    ),
            )
        val manifests =
            mapOf(
                realm.coordinate.id to
                    RealmManifest(
                        id = realm.coordinate.id,
                        version = realm.coordinate.version,
                        hostApi = VersionConstraint("^1"),
                        runtimeEntrypointClass = "fixture.Runtime",
                        contributions = emptyList(),
                    ),
                panel.coordinate.id to engineManifest(panel),
                primary.coordinate.id to engineManifest(primary),
            )

        val realmProjection = snapshot.projectFor("realm", selection, realmHost, manifests)
        val engineProjection = snapshot.projectFor("realm", selection, engineHost, manifests)

        realmProjection.publicationTarget shouldBe engineProjection.publicationTarget
        realmProjection.publicationTarget.fingerprint() shouldBe engineProjection.publicationTarget.fingerprint()
        realmProjection.publicationTarget.engine.id shouldBe primary.coordinate.id
        engineProjection.runtimes.single().implementation shouldBe engineProjection.publicationTarget
        val panelImplementation =
            requireNotNull(realmProjection.runtimes.single { it.placement == RuntimePlacement.PANEL_ENGINE }.implementation)
        panelImplementation.engine.id shouldBe panel.coordinate.id
        panelImplementation.fingerprint() shouldNotBe realmProjection.publicationTarget.fingerprint()
        realmProjection.runtimes.single { it.placement == RuntimePlacement.REALM }.implementation shouldBe null

        val changedPrimary = deploymentArtifact("typewritermc:paper", ArtifactKind.ENGINE, "changed paper")
        val changedContent = content.copy(primaryEngine = changedPrimary)
        val changed = DeploymentSnapshot(DeploymentGeneration(2), DeploymentContentCodec.digest(changedContent), changedContent)
        changed.projectFor("realm", selection, realmHost, manifests).publicationTarget.fingerprint() shouldNotBe
            realmProjection.publicationTarget.fingerprint()
    }

    test("publication fingerprint includes only source parts eligible for the primary engine") {
        val realm = deploymentArtifact("typewritermc:realm", ArtifactKind.REALM, "realm")
        val panel = deploymentArtifact("typewritermc:panel", ArtifactKind.ENGINE, "panel")
        val primary = deploymentArtifact("typewritermc:paper", ArtifactKind.ENGINE, "paper")
        val extension = deploymentArtifact("typewritermc:extension", ArtifactKind.EXTENSION, "extension")
        val content =
            DeploymentContent(
                realm = realm,
                primaryEngine = primary,
                panelEngine = panel,
                extensions = listOf(extension),
            )
        val snapshot = DeploymentSnapshot(DeploymentGeneration(1), DeploymentContentCodec.digest(content), content)
        val realmHost = ServiceId("realm")
        val selection =
            RealmDeploymentSelection(
                realmService = realmHost,
                primaryEngineServices = emptySet(),
                serviceApis = mapOf(realmHost to ArtifactVersion("1.0.0")),
            )
        val manifests =
            mapOf(
                realm.coordinate.id to
                    RealmManifest(
                        id = realm.coordinate.id,
                        version = realm.coordinate.version,
                        hostApi = VersionConstraint("^1"),
                        runtimeEntrypointClass = "fixture.Runtime",
                        contributions = emptyList(),
                    ),
                panel.coordinate.id to engineManifest(panel),
                primary.coordinate.id to engineManifest(primary),
                extension.coordinate.id to
                    ExtensionManifest(
                        id = extension.coordinate.id,
                        version = extension.coordinate.version,
                        sourceParts =
                            listOf(
                                CommonExtensionSourcePart,
                                EngineExtensionSourcePart(
                                    name = "paper",
                                    requirement = ArtifactRequirement(primary.coordinate.id, VersionConstraint("^1")),
                                    resolved =
                                        ResolvedArtifact(
                                            primary.coordinate.id,
                                            primary.coordinate.version,
                                            ArtifactKind.ENGINE,
                                        ),
                                ),
                            ),
                        buildProvenance = emptyList(),
                        contributions = emptyList(),
                    ),
            )

        val projection = snapshot.projectFor("realm", selection, realmHost, manifests)
        val included = projection.publicationTarget.extensions.single()
        included.sourceParts shouldContainExactly listOf("common", "paper")
        val changedParts =
            projection.publicationTarget.copy(
                extensions =
                    listOf(
                        EngineImplementationArtifact(
                            included.id,
                            included.version,
                            included.digest,
                            listOf("common", "panel"),
                        ),
                    ),
            )
        changedParts.fingerprint() shouldNotBe projection.publicationTarget.fingerprint()
        val panelImplementation =
            requireNotNull(projection.runtimes.single { it.placement == RuntimePlacement.PANEL_ENGINE }.implementation)
        panelImplementation.extensions.single().sourceParts shouldContainExactly listOf("common")
    }

    test("a stored blob becomes visible only when its size and digest match") {
        runTest {
            val store = FileDigestBlobStore(Files.createTempDirectory("typewriter-blobs"))
            val bytes = "verified artifact content".encodeToByteArray()
            val expected = BlobMetadata(ArtifactDigest.sha256(bytes), bytes.size.toLong())

            (store.store(expected.copy(size = expected.size + 1), bytes) is StoreResult.Invalid) shouldBe true
            (store.store(expected, "forged artifact content!!".encodeToByteArray()) is StoreResult.Invalid) shouldBe true
            store.metadata(expected.digest) shouldBe BlobResult.NotFound

            store.store(expected, bytes) shouldBe StoreResult.Stored(expected)
            store.fetch(expected.digest).shouldSucceed() shouldBe bytes
            store.metadata(expected.digest) shouldBe BlobResult.Success(expected)
        }
    }

    test("storing content that is already present succeeds and refreshes it, so a lost reply can be retried") {
        runTest {
            val now = Instant.parse("2026-10-24T12:00:00Z")
            val store = FileDigestBlobStore(Files.createTempDirectory("typewriter-blobs-retry"), Clock.fixed(now, ZoneOffset.UTC))
            val bytes = "retried artifact content".encodeToByteArray()
            val expected = BlobMetadata(ArtifactDigest.sha256(bytes), bytes.size.toLong())
            store.store(expected, bytes) shouldBe StoreResult.Stored(expected)
            val path = store.pathFor(expected.digest)
            Files.setLastModifiedTime(path, FileTime.from(now.minus(JavaDuration.ofDays(30))))

            store.store(expected, bytes) shouldBe StoreResult.Stored(expected)

            // Collection counts the grace period from the latest store, so publication can still reference the blob.
            store.collectGarbage(emptySet())
            store.fetch(expected.digest).shouldSucceed() shouldBe bytes
        }
    }

    test("storing verified content over a corrupt blob repairs it, while unverified content leaves it") {
        runTest {
            val store = FileDigestBlobStore(Files.createTempDirectory("typewriter-blobs-repair"))
            val bytes = "content that is repaired".encodeToByteArray()
            val expected = BlobMetadata(ArtifactDigest.sha256(bytes), bytes.size.toLong())
            store.store(expected, bytes) shouldBe StoreResult.Stored(expected)
            val corrupt = "content that is r3paired".encodeToByteArray()
            Files.write(store.pathFor(expected.digest), corrupt)

            (store.store(expected, "forged content of the size".encodeToByteArray()) is StoreResult.Invalid) shouldBe true
            Files.readAllBytes(store.pathFor(expected.digest)) shouldBe corrupt

            store.store(expected, bytes) shouldBe StoreResult.Stored(expected)
            store.fetch(expected.digest).shouldSucceed() shouldBe bytes
        }
    }

    test("a blob corrupted on disk is reported invalid instead of served") {
        runTest {
            val store = FileDigestBlobStore(Files.createTempDirectory("typewriter-blobs-corrupt"))
            val bytes = "content that rots".encodeToByteArray()
            val expected = BlobMetadata(ArtifactDigest.sha256(bytes), bytes.size.toLong())
            store.store(expected, bytes) shouldBe StoreResult.Stored(expected)

            Files.write(store.pathFor(expected.digest), "content that rot!".encodeToByteArray())

            (store.fetch(expected.digest) is BlobResult.Invalid) shouldBe true
        }
    }

    test("a remote host stores and fetches a 40 MiB blob through the Realm host") {
        // Real time: the Realm host stores on the IO dispatcher, which virtual test time would outrun.
        withContext(Dispatchers.Default) {
            val broker = MemoryNatsBroker()
            val harness = TelemetryTestHarness.create()
            val propagators = ContextPropagators.create(W3CTraceContextPropagator.getInstance())
            val root = Files.createTempDirectory("typewriter-remote-blobs")
            val realmBlobs = FileDigestBlobStore(root)
            val shared = SharedArtifactService("quests", realmBlobs, FileSharedArtifactRepository(root.resolve("shared.cbor")))
            val address = RealmRouteScope(realmId = "quests", organizationId = "writers")
            val realmHost = Communicator(broker.transport(TRANSPORT_LIMITS), harness.telemetry, propagators)
            val router = realmHost.createRouter(communicatorRoutes { StableRealmArtifactRoutes(shared).register(this, address) }, this)
            try {
                router.start() shouldBe RouterResult.Success
                val remote =
                    CommunicatorBlobEndpoint(Communicator(broker.transport(TRANSPORT_LIMITS), harness.telemetry, propagators), address)
                val blob = java.util.Random(7).let { random -> ByteArray(40 * 1024 * 1024).also(random::nextBytes) }
                val expected = BlobMetadata(ArtifactDigest.sha256(blob), blob.size.toLong())

                remote.store(expected, blob) shouldBe StoreResult.Stored(expected)
                val fetched = remote.fetch(expected.digest).shouldSucceed()

                ArtifactDigest.sha256(fetched) shouldBe expected.digest
                realmBlobs.metadata(expected.digest) shouldBe BlobResult.Success(expected)
            } finally {
                router.stop()
                harness.close()
            }
        }
    }

    test("a blob above the transfer ceiling is answered invalid from its size without being read") {
        withContext(Dispatchers.Default) {
            val broker = MemoryNatsBroker()
            val harness = TelemetryTestHarness.create()
            val propagators = ContextPropagators.create(W3CTraceContextPropagator.getInstance())
            val root = Files.createTempDirectory("typewriter-oversized-blobs")
            val realmBlobs = FileDigestBlobStore(root)
            val digest = ArtifactDigest.sha256("an oversized realm jar".encodeToByteArray())
            // A sparse file: its size exceeds the ceiling without writing the bytes.
            val path = realmBlobs.pathFor(digest)
            Files.createDirectories(path.parent)
            java.io.RandomAccessFile(path.toFile(), "rw").use { it.setLength(TRANSFERRED_BLOB_MAX_BYTES + 1) }
            val service = SharedArtifactService("quests", realmBlobs, FileSharedArtifactRepository(root.resolve("shared.cbor")))
            val shared = FetchForbiddenSharedArtifactAccess(service)
            val address = RealmRouteScope(realmId = "quests", organizationId = "writers")
            val realmHost = Communicator(broker.transport(TRANSPORT_LIMITS), harness.telemetry, propagators)
            val router = realmHost.createRouter(communicatorRoutes { StableRealmArtifactRoutes(shared).register(this, address) }, this)
            try {
                router.start() shouldBe RouterResult.Success
                val remote =
                    CommunicatorBlobEndpoint(Communicator(broker.transport(TRANSPORT_LIMITS), harness.telemetry, propagators), address)

                val fetched = remote.fetch(digest)

                (fetched as BlobResult.Invalid).reason shouldContain "transfer ceiling"
            } finally {
                router.stop()
                harness.close()
            }
        }
    }

    test("publishing the same shared artifact again leaves it unchanged") {
        runTest {
            val shared = sharedPublication()
            val published = shared.service.publish(shared.command) as PublishResult.Published

            shared.service.publish(shared.command.copy(expectedRevision = published.descriptor.revision)) shouldBe
                PublishResult.Unchanged(published.descriptor)
            shared.service.publish(shared.command) shouldBe PublishResult.Unchanged(published.descriptor)
            shared.service.catalog().artifacts shouldContainExactly listOf(published.descriptor)
        }
    }

    test("publishing changed content against a stale revision is a conflict that changes nothing") {
        runTest {
            val shared = sharedPublication()
            val published = shared.service.publish(shared.command) as PublishResult.Published

            shared.service.publish(shared.command.copy(label = "Renamed road network")) shouldBe
                PublishResult.Conflict(published.descriptor)
            shared.service.catalog().artifacts shouldContainExactly listOf(published.descriptor)
        }
    }

    test("the shared catalog survives a restart") {
        runTest {
            val shared = sharedPublication()
            val published = shared.service.publish(shared.command) as PublishResult.Published

            shared.restartedCatalog().artifacts shouldContainExactly listOf(published.descriptor)
        }
    }

    test("deleting a shared artifact leaves a durable tombstone at the next catalog revision") {
        runTest {
            val shared = sharedPublication()
            val published = shared.service.publish(shared.command) as PublishResult.Published

            val deleted =
                shared.service.delete(
                    shared.command.id,
                    published.descriptor.revision,
                    shared.command.provenance,
                ) as PublishResult.Published

            deleted.catalogRevision.value shouldBe published.catalogRevision.value + 1
            deleted.descriptor.deleted shouldBe true
            val restarted = shared.restartedCatalog()
            restarted.revision shouldBe deleted.catalogRevision
            restarted.artifacts shouldContainExactly listOf(deleted.descriptor)
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

        val desired =
            WatchHostExecutionResponse
                .createDesired(topologyRevision = 1, realm = realm, engine = engine)
                .toDesiredHostExecution(panel, ServiceId("service-id"))

        val assignment = desired?.assignment
        assignment?.realmId shouldBe RealmId("realm")
        assignment?.roles shouldBe RuntimePlacement.entries.toSet()
        assignment?.primaryEngine?.id shouldBe ArtifactId("typewritermc:paper")
        assignment?.intent?.panelEngine shouldBe panel
        desired?.revision?.value shouldBe 1
        desired?.revision?.serviceId shouldBe ServiceId("service-id")
        val removal =
            WatchHostExecutionResponse
                .createDesired(topologyRevision = 2, realm = null, engine = null)
                .toDesiredHostExecution(panel, ServiceId("service-id"))
        removal?.assignment shouldBe null
        removal?.revision?.value shouldBe 2
        removal?.revision?.serviceId shouldBe ServiceId("service-id")
    }

    test("participant health maps to backend execution state") {
        val serviceId = ServiceId("service")
        val reference =
            ProjectionReference(
                realmId = "realm",
                generation = 1,
                serviceId = serviceId.value,
                blob = ArtifactDigest.sha256("projection".encodeToByteArray()).toSkir(),
                runtimeVersions = listOf(RuntimeVersion(placement = RuntimePlacement.PRIMARY_ENGINE.toSkir(), version = "1.2.3")),
            )
        val attempt = RolloutAttempt(ordinal = 1, generation = 1)
        val status = status(attempt, serviceId, active(reference))
        val now = Instant.parse("2026-09-02T00:00:00Z")

        status.toChildRuntimeState(now, RuntimePlacement.PRIMARY_ENGINE) shouldBe
            ChildRuntimeState(
                status = ChildRuntimeStatus.ACTIVE,
                activeArtifactVersion = "1.2.3",
                message = null,
                updatedAt = now,
            )
        val unhealthy =
            ActiveProjection(projection = reference, health = ProjectionHealth.createUnhealthy(reasons = listOf("probe failed")))
        status(attempt, serviceId, ParticipantPhase.createActive(current = unhealthy, retained = null))
            .toChildRuntimeState(now, RuntimePlacement.PRIMARY_ENGINE) shouldBe
            ChildRuntimeState(
                status = ChildRuntimeStatus.FAILED,
                activeArtifactVersion = "1.2.3",
                message = "probe failed",
                updatedAt = now,
            )
    }

    test("reconciling an unchanged inbox keeps the accepted import") {
        runTest {
            val root = Files.createTempDirectory("typewriter-inbox")
            val candidates = FileCandidateRepository(root)
            val reconciler = ArtifactInboxReconciler(root, FileDigestBlobStore(root), candidates, Duration.ZERO)
            writeArtifactJar(root.resolve("inbox/manual/realm.jar"), realmManifest())
            reconciler.reconcile()
            val accepted = candidates.candidates().single()

            reconciler.reconcile()

            candidates.candidates().single() shouldBe accepted
        }
    }

    test("a malformed inbox replacement keeps the accepted import and reports the file") {
        runTest {
            val root = Files.createTempDirectory("typewriter-inbox-malformed")
            val candidates = FileCandidateRepository(root)
            val reconciler = ArtifactInboxReconciler(root, FileDigestBlobStore(root), candidates, Duration.ZERO)
            val artifact = root.resolve("inbox/manual/realm.jar")
            writeArtifactJar(artifact, realmManifest())
            reconciler.reconcile()
            val accepted = candidates.candidates().single()

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
            val artifact = root.resolve("inbox/manual/realm.jar")
            writeArtifactJar(artifact, realmManifest())
            reconciler.reconcile()
            Files.delete(artifact)

            reconciler.reconcile()
            candidates.candidates().size shouldBe 1
            reconciler.reconcile()
            candidates.candidates().size shouldBe 0
        }
    }

    test("inbox reconciliation ignores artifacts outside the manual inbox") {
        runTest {
            val root = Files.createTempDirectory("typewriter-inbox-boundary")
            val candidates = FileCandidateRepository(root)
            val reconciler = ArtifactInboxReconciler(root, FileDigestBlobStore(root), candidates, Duration.ZERO)
            val manifest = realmManifest()
            writeArtifactJar(root.resolve("inbox/development/realm.jar"), manifest)
            writeArtifactJar(root.resolve("inbox/realm.jar"), manifest)

            reconciler.reconcile()

            candidates.candidates() shouldBe emptyList()
            candidates.diagnostics() shouldBe emptyList()
        }
    }

    test("unstable inbox replacement preserves the accepted candidate") {
        runTest {
            val root = Files.createTempDirectory("typewriter-inbox-unstable")
            val candidates = FileCandidateRepository(root)
            val blobs = FileDigestBlobStore(root)
            val artifact = root.resolve("inbox/manual/realm.jar")
            writeArtifactJar(artifact, realmManifest())
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
