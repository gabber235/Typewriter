@file:OptIn(kotlinx.coroutines.ExperimentalCoroutinesApi::class)

package com.typewritermc.loader

import com.typewritermc.imprint.ArtifactId
import com.typewritermc.imprint.ArtifactKind
import com.typewritermc.imprint.ArtifactRequirement
import com.typewritermc.imprint.ArtifactVersion
import com.typewritermc.imprint.CommonExtensionSourcePart
import com.typewritermc.imprint.EngineExtensionSourcePart
import com.typewritermc.imprint.EngineManifest
import com.typewritermc.imprint.ExtensionManifest
import com.typewritermc.imprint.IMPRINT_MANIFEST_PATH
import com.typewritermc.imprint.ImprintManifestCodec
import com.typewritermc.imprint.RealmManifest
import com.typewritermc.imprint.ResolvedArtifact
import com.typewritermc.imprint.VersionConstraint
import com.typewritermc.loader.api.EngineImplementationArtifact
import com.typewritermc.loader.api.RuntimePlacement
import com.typewritermc.loader.api.artifact.ProducerMetadata
import com.typewritermc.loader.api.artifact.PublishResult
import com.typewritermc.loader.api.artifact.PublishSharedArtifact
import com.typewritermc.loader.api.artifact.SharedArtifactId
import com.typewritermc.loader.api.artifact.SharedArtifactProvenance
import com.typewritermc.loader.artifact.ArtifactCoordinate
import com.typewritermc.loader.artifact.ArtifactInboxReconciler
import com.typewritermc.loader.artifact.DeploymentArtifact
import com.typewritermc.loader.artifact.FileCandidateRepository
import com.typewritermc.loader.artifact.FileDigestBlobStore
import com.typewritermc.loader.artifact.toApi
import com.typewritermc.loader.artifact.toSkir
import com.typewritermc.loader.deployment.DeploymentContent
import com.typewritermc.loader.deployment.DeploymentContentCodec
import com.typewritermc.loader.deployment.DeploymentGeneration
import com.typewritermc.loader.deployment.DeploymentSnapshot
import com.typewritermc.loader.deployment.RealmDeploymentSelection
import com.typewritermc.loader.deployment.projectFor
import com.typewritermc.loader.rollout.BlobProjectionRepository
import com.typewritermc.loader.rollout.CoordinatedRollout
import com.typewritermc.loader.rollout.FileRolloutStateRepository
import com.typewritermc.loader.rollout.RealmId
import com.typewritermc.loader.rollout.RolloutMessenger
import com.typewritermc.loader.rollout.commandKind
import com.typewritermc.loader.rollout.deploymentSelectionOrNull
import com.typewritermc.loader.rollout.projectionOf
import com.typewritermc.loader.rollout.serviceIds
import com.typewritermc.loader.rollout.toApi
import com.typewritermc.loader.rollout.toChildRuntimeState
import com.typewritermc.loader.rollout.toDesiredHostExecution
import com.typewritermc.loader.rollout.toSkir
import com.typewritermc.loader.shared.FileSharedArtifactRepository
import com.typewritermc.loader.shared.SharedArtifactService
import com.typewritermc.protocol.transport.RealmRouteScope
import com.typewritermc.protocol.transport.ServiceRouteScope
import com.typewritermc.protocol.transport.generated.authoringCompiledChanged
import com.typewritermc.protocol.transport.generated.hostExecutionReport
import com.typewritermc.protocol.transport.generated.hostExecutionWatch
import com.typewritermc.protocol.transport.generated.serviceHostRegister
import com.typewritermc.protocol.transport.generated.sharedBlobBegin
import com.typewritermc.protocol.transport.generated.sharedBlobComplete
import com.typewritermc.protocol.transport.generated.sharedBlobMetadata
import com.typewritermc.protocol.transport.generated.sharedBlobRead
import com.typewritermc.protocol.transport.generated.sharedBlobWrite
import com.typewritermc.protocol.transport.generated.sharedCatalogFetch
import com.typewritermc.protocol.transport.generated.sharedPublish
import com.typewritermc.services.libs.filetransfer.blob.ArtifactDigest
import com.typewritermc.services.libs.filetransfer.blob.BlobMetadata
import com.typewritermc.services.libs.filetransfer.blob.BlobResult
import com.typewritermc.services.libs.filetransfer.blob.TransferId
import com.typewritermc.services.libs.registrar.ServiceId
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.assertions.throwables.shouldThrow
import io.kotest.matchers.collections.shouldContainExactly
import io.kotest.matchers.shouldBe
import io.kotest.matchers.shouldNotBe
import kotlinx.coroutines.async
import kotlinx.coroutines.delay
import kotlinx.coroutines.test.advanceTimeBy
import kotlinx.coroutines.test.runCurrent
import kotlinx.coroutines.test.runTest
import kotlinx.coroutines.withTimeout
import skirout.kernel.v1.record_id.RecordId
import skirout.kernel.v1.record_id.RecordIdKey
import skirout.service.v1.rollout.ActiveProjection
import skirout.service.v1.rollout.ApplyRolloutCommandRequest
import skirout.service.v1.rollout.ApplyRolloutCommandResponse
import skirout.service.v1.rollout.ParticipantPhase
import skirout.service.v1.rollout.ParticipantStatus
import skirout.service.v1.rollout.ProjectionHealth
import skirout.service.v1.rollout.ProjectionReference
import skirout.service.v1.rollout.QueryParticipantStatusRequest
import skirout.service.v1.rollout.RealmHostPresence
import skirout.service.v1.rollout.RollbackTarget
import skirout.service.v1.rollout.RolloutAttempt
import skirout.service.v1.rollout.RolloutCommand
import skirout.service.v1.rollout.RolloutCommandKind
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
import java.nio.file.Path
import java.time.Instant
import java.util.zip.ZipEntry
import java.util.zip.ZipOutputStream
import kotlin.time.Duration
import kotlin.time.Duration.Companion.milliseconds
import kotlin.time.Duration.Companion.seconds
import kotlin.time.TestTimeSource

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

    test("shared artifact contracts use valid telemetry slugs") {
        val scope = RealmRouteScope(organizationId = "writers", realmId = "quests")
        scope.sharedCatalogFetch.failureSlug.value shouldBe "shared-catalog-fetch-failed"
        scope.sharedPublish.failureSlug.value shouldBe "shared-publish-failed"
    }

    test("blob contracts use valid telemetry slugs") {
        val scope = RealmRouteScope(organizationId = "writers", realmId = "quests")
        scope.sharedBlobMetadata.failureSlug.value shouldBe "shared-blob-metadata-failed"
        scope.sharedBlobRead.failureSlug.value shouldBe "shared-blob-read-failed"
        scope.sharedBlobBegin.failureSlug.value shouldBe "shared-blob-begin-failed"
        scope.sharedBlobWrite.failureSlug.value shouldBe "shared-blob-write-failed"
        scope.sharedBlobComplete.failureSlug.value shouldBe "shared-blob-complete-failed"
    }

    test("generated Realm routes preserve the established authority family") {
        val address = RealmRouteScope(realmId = "quests", organizationId = "writers")
        val shared = address.sharedPublish

        shared.requestAddress.render(address).value shouldBe
            "service.to.quests.organization.writers.realm.shared.publish"
        address.authoringCompiledChanged.address
            .render(address)
            .value shouldBe
            "service.from.quests.organization.writers.realm.editor.authoring.compiled.changed"
    }

    test("generated host execution routes preserve the service authority family") {
        val scope = ServiceRouteScope("host")
        val registration = scope.serviceHostRegister
        val watch = scope.hostExecutionWatch
        val report = scope.hostExecutionReport

        registration.requestAddress.render(scope).value shouldBe "cloud.to.service.host.execution.register"
        watch.requestAddress.render(scope).value shouldBe "cloud.to.service.host.execution.watch"
        watch.updateAddress.render(scope).value shouldBe "cloud.from.service.host.execution.watch"
        report.requestAddress.render(scope).value shouldBe "cloud.to.service.host.execution.report"
    }

    test("combined host receives Realm panel and primary runtimes as one projection") {
        val realm = artifact("typewritermc:realm", ArtifactKind.REALM, "realm")
        val panel = artifact("typewritermc:panel", ArtifactKind.ENGINE, "panel")
        val primary = artifact("typewritermc:paper", ArtifactKind.ENGINE, "paper")
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
        val realm = artifact("typewritermc:realm", ArtifactKind.REALM, "realm")
        val panel = artifact("typewritermc:panel", ArtifactKind.ENGINE, "panel")
        val primary = artifact("typewritermc:paper", ArtifactKind.ENGINE, "paper")
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

        val changedPrimary = artifact("typewritermc:paper", ArtifactKind.ENGINE, "changed paper")
        val changedContent = content.copy(primaryEngine = changedPrimary)
        val changed = DeploymentSnapshot(DeploymentGeneration(2), DeploymentContentCodec.digest(changedContent), changedContent)
        changed.projectFor("realm", selection, realmHost, manifests).publicationTarget.fingerprint() shouldNotBe
            realmProjection.publicationTarget.fingerprint()
    }

    test("publication fingerprint includes only source parts eligible for the primary engine") {
        val realm = artifact("typewritermc:realm", ArtifactKind.REALM, "realm")
        val panel = artifact("typewritermc:panel", ArtifactKind.ENGINE, "panel")
        val primary = artifact("typewritermc:paper", ArtifactKind.ENGINE, "paper")
        val extension = artifact("typewritermc:extension", ArtifactKind.EXTENSION, "extension")
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
            val host = ServiceId("combined")
            val projection =
                snapshot.projectFor(
                    "realm",
                    RealmDeploymentSelection(host, setOf(host), mapOf(host to ArtifactVersion("1.0.0"))),
                    host,
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
                    ),
                )
            val repository = BlobProjectionRepository(FileDigestBlobStore(Files.createTempDirectory("typewriter-projections")))

            val reference = repository.publish(projection)

            repository.fetch(reference) shouldBe projection
            shouldThrow<IllegalArgumentException> {
                repository.fetch(reference.copy(serviceId = "another"))
            }
        }
    }

    listOf(false, true).forEach { absentEngineSelected ->
        test(
            if (absentEngineSelected) {
                "an absent selected engine does not block responding Realm participants"
            } else {
                "Realm and panel roll out without a primary engine host"
            },
        ) {
            runTest {
                val root = Files.createTempDirectory("typewriter-realm-only-rollout")
                val realmId = RealmId("realm")
                val host = ServiceId("realm-service")
                val hostApi = ArtifactVersion("1.0.0")
                val assignedRoles = setOf(RuntimePlacement.REALM, RuntimePlacement.PANEL_ENGINE)
                val presence = presence(host, assignedRoles)
                val observedSelection = requireNotNull(listOf(presence).deploymentSelectionOrNull())
                val absentEngine = ServiceId("absent-engine")
                val selection =
                    if (absentEngineSelected) {
                        observedSelection.copy(
                            primaryEngineServices = setOf(absentEngine),
                            serviceApis = observedSelection.serviceApis + (absentEngine to hostApi),
                        )
                    } else {
                        observedSelection
                    }
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
                                runtimeEntrypointClass = "fixture.Runtime",
                                contributions = emptyList(),
                            ),
                        panel.coordinate.id to engineManifest(panel),
                        primary.coordinate.id to engineManifest(primary),
                    )
                val state = FileRolloutStateRepository(realmId, root)
                val commands = mutableListOf<ApplyRolloutCommandRequest>()
                var currentStatus: ParticipantStatus? = null
                var realmResponding = true
                val messenger =
                    object : RolloutMessenger {
                        override suspend fun discover(
                            expected: Set<ServiceId>,
                            timeout: Duration,
                        ) = if (realmResponding) listOf(presence) else emptyList()

                        override suspend fun command(
                            request: ApplyRolloutCommandRequest,
                            timeout: Duration,
                        ): List<ApplyRolloutCommandResponse> {
                            commands += request
                            val reference = request.projectionFor(host)
                            currentStatus =
                                when (request.command) {
                                    is RolloutCommand.StageWrapper -> status(request.attempt, host, staged(reference))
                                    is RolloutCommand.CommitWrapper -> status(request.attempt, host, active(reference))
                                    is RolloutCommand.AbortWrapper -> status(request.attempt, host, ParticipantPhase.IDLE)
                                    else -> error("Rollback was not expected.")
                                }
                            return listOf(accepted(host))
                        }

                        override suspend fun statuses(
                            request: QueryParticipantStatusRequest,
                            expected: Set<ServiceId>,
                            timeout: Duration,
                        ): Map<ServiceId, ParticipantStatus> = currentStatus?.let { mapOf(host to it) }.orEmpty()
                    }
                val projectionRepository = BlobProjectionRepository(FileDigestBlobStore(root))
                val rollout =
                    CoordinatedRollout(
                        realmId,
                        selection,
                        manifests,
                        messenger,
                        projectionRepository,
                        state,
                        requestTimeout = 1.seconds,
                        participantDeadline = 1.seconds,
                        healthyDuration = Duration.ZERO,
                    )

                rollout.rollOut(snapshot)

                val committed = requireNotNull(state.current())
                val reference = commands.first().projectionFor(host)
                committed.projections shouldBe mapOf(host to reference.blob.toApi())
                val projection = projectionRepository.fetch(reference)
                commands.map { it.command.commandKind } shouldContainExactly listOf(RolloutCommandKind.STAGE, RolloutCommandKind.COMMIT)
                commands.forEach { it.command.serviceIds shouldBe setOf(host.value) }
                projection.runtimes.map { it.placement } shouldContainExactly
                    listOf(RuntimePlacement.PANEL_ENGINE, RuntimePlacement.REALM)

                commands.clear()
                realmResponding = false
                shouldThrow<IllegalArgumentException> { rollout.rollOut(snapshot) }
                commands shouldBe emptyList()
                state.current() shouldBe committed
            }
        }
    }

    test("combined host participates once in a coordinated rollout") {
        runTest {
            val root = Files.createTempDirectory("typewriter-rollout")
            val realmId = RealmId("realm")
            val host = ServiceId("combined")
            val selection = RealmDeploymentSelection(host, setOf(host), mapOf(host to ArtifactVersion("1.0.0")))
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
                            runtimeEntrypointClass = "fixture.Runtime",
                            contributions = emptyList(),
                        ),
                    panel.coordinate.id to engineManifest(panel),
                    primary.coordinate.id to engineManifest(primary),
                )
            val state = FileRolloutStateRepository(realmId, root)
            val commands = mutableListOf<ApplyRolloutCommandRequest>()
            var currentStatus: ParticipantStatus? = null
            var activeProjection: ActiveProjection? = null
            var rejectCommit = false
            val messenger =
                object : RolloutMessenger {
                    override suspend fun discover(
                        expected: Set<ServiceId>,
                        timeout: Duration,
                    ) = listOf(presence(host, RuntimePlacement.entries.toSet(), activeProjection))

                    override suspend fun command(
                        request: ApplyRolloutCommandRequest,
                        timeout: Duration,
                    ): List<ApplyRolloutCommandResponse> {
                        commands += request
                        withTimeout(timeout) { delay(6.seconds) }
                        val reference = request.projectionFor(host)
                        val phase =
                            when (val command = request.command) {
                                is RolloutCommand.StageWrapper -> {
                                    staged(reference, activeProjection)
                                }

                                is RolloutCommand.CommitWrapper -> {
                                    active(reference).also { activeProjection = it.value.current }
                                }

                                is RolloutCommand.RollBackWrapper -> {
                                    when (
                                        val target =
                                            command.value.participants
                                                .findByKey(host.value)
                                                ?.target
                                    ) {
                                        is RollbackTarget.ProjectionWrapper -> {
                                            active(target.value).also { activeProjection = it.value.current }
                                        }

                                        else -> {
                                            activeProjection = null
                                            ParticipantPhase.IDLE
                                        }
                                    }
                                }

                                else -> {
                                    ParticipantPhase.IDLE
                                }
                            }
                        currentStatus = status(request.attempt, host, phase)
                        val rejected = rejectCommit && request.command is RolloutCommand.CommitWrapper
                        return listOf(
                            if (rejected) {
                                ApplyRolloutCommandResponse.createCommandRejectedError(serviceId = host.value, reason = "rejected")
                            } else {
                                accepted(host)
                            },
                        )
                    }

                    override suspend fun statuses(
                        request: QueryParticipantStatusRequest,
                        expected: Set<ServiceId>,
                        timeout: Duration,
                    ): Map<ServiceId, ParticipantStatus> = currentStatus?.let { mapOf(host to it) }.orEmpty()
                }
            val blobs = FileDigestBlobStore(root)

            val rollout =
                CoordinatedRollout(
                    realmId,
                    selection,
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
            commands.map { it.command.commandKind } shouldContainExactly listOf(RolloutCommandKind.STAGE, RolloutCommandKind.COMMIT)
            commands.forEach { it.command.serviceIds shouldBe setOf(host.value) }

            commands.clear()
            activeProjection = null
            rollout.reconcileCommitted(committed)

            commands.map { it.command.commandKind } shouldContainExactly listOf(RolloutCommandKind.STAGE, RolloutCommandKind.COMMIT)
            commands.forEach { it.command.serviceIds shouldBe setOf(host.value) }

            rejectCommit = true
            for (reconcile in listOf(false, true)) {
                commands.clear()
                activeProjection = null
                shouldThrow<IllegalArgumentException> {
                    if (reconcile) rollout.reconcileCommitted(committed) else rollout.rollOut(snapshot)
                }
                val rollback = commands.last().command as RolloutCommand.RollBackWrapper
                rollback.value.participants
                    .findByKey(host.value)
                    ?.target shouldBe RollbackTarget.EMPTY
                currentStatus shouldBe status(commands.last().attempt, host, ParticipantPhase.IDLE)
                state.current() shouldBe committed
            }
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

            val deleted =
                service.delete(
                    command.id,
                    published.descriptor.revision,
                    SharedArtifactProvenance.HostedRuntime("paper", "primary"),
                ) as PublishResult.Published
            deleted.catalogRevision.value shouldBe published.catalogRevision.value + 1
            deleted.descriptor.deleted shouldBe true
            val restartedCatalog = FileSharedArtifactRepository(root.resolve("shared.cbor")).catalog()
            restartedCatalog.revision shouldBe deleted.catalogRevision
            restartedCatalog.artifacts shouldContainExactly listOf(deleted.descriptor)
        }
    }

    test("stabilization restarts after an incomplete authoritative status snapshot") {
        runTest {
            val root = Files.createTempDirectory("typewriter-stabilization")
            val realmId = RealmId("realm")
            val host = ServiceId("combined")
            val selection = RealmDeploymentSelection(host, setOf(host), mapOf(host to ArtifactVersion("1.0.0")))
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
                            runtimeEntrypointClass = "fixture.Runtime",
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
                        expected: Set<ServiceId>,
                        timeout: Duration,
                    ) = listOf(presence(host, RuntimePlacement.entries.toSet()))

                    override suspend fun command(
                        request: ApplyRolloutCommandRequest,
                        timeout: Duration,
                    ): List<ApplyRolloutCommandResponse> {
                        val reference = request.projectionFor(host)
                        val phase =
                            when (request.command) {
                                is RolloutCommand.StageWrapper -> staged(reference)
                                is RolloutCommand.CommitWrapper -> active(reference)
                                else -> ParticipantPhase.IDLE
                            }
                        status = status(request.attempt, host, phase)
                        return listOf(accepted(host))
                    }

                    override suspend fun statuses(
                        request: QueryParticipantStatusRequest,
                        expected: Set<ServiceId>,
                        timeout: Duration,
                    ): Map<ServiceId, ParticipantStatus> {
                        val current = status ?: return emptyMap()
                        if (current.phase is ParticipantPhase.ActiveWrapper) {
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
                    selection,
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
                    runtimeEntrypointClass = "fixture.Runtime",
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
            val artifact = root.resolve("inbox/manual/realm.jar")
            writeArtifactJar(
                artifact,
                RealmManifest(
                    id = ArtifactId("typewritermc:realm"),
                    version = ArtifactVersion("1.0.0"),
                    hostApi = VersionConstraint("^1"),
                    runtimeEntrypointClass = "fixture.Runtime",
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

    test("inbox reconciliation ignores artifacts outside the manual inbox") {
        runTest {
            val root = Files.createTempDirectory("typewriter-inbox-boundary")
            val candidates = FileCandidateRepository(root)
            val reconciler = ArtifactInboxReconciler(root, FileDigestBlobStore(root), candidates, Duration.ZERO)
            val manifest =
                RealmManifest(
                    id = ArtifactId("typewritermc:realm"),
                    version = ArtifactVersion("1.0.0"),
                    hostApi = VersionConstraint("^1"),
                    runtimeEntrypointClass = "fixture.Runtime",
                    contributions = emptyList(),
                )
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
            writeArtifactJar(
                artifact,
                RealmManifest(
                    id = ArtifactId("typewritermc:realm"),
                    version = ArtifactVersion("1.0.0"),
                    hostApi = VersionConstraint("^1"),
                    runtimeEntrypointClass = "fixture.Runtime",
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
        runtimeEntrypointClass = "fixture.Runtime",
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

private fun presence(
    host: ServiceId,
    roles: Set<RuntimePlacement>,
    activeProjection: ActiveProjection? = null,
) = RealmHostPresence(
    serviceId = host.value,
    hostApi = "1.0.0",
    assignedRoles = roles.map { it.toSkir() },
    activeProjection = activeProjection,
)

private fun ApplyRolloutCommandRequest.projectionFor(host: ServiceId): ProjectionReference =
    requireNotNull(command.projectionOf(host.value))

private fun accepted(host: ServiceId) = ApplyRolloutCommandResponse.createAccepted(serviceId = host.value)

private fun status(
    attempt: RolloutAttempt,
    host: ServiceId,
    phase: ParticipantPhase,
) = ParticipantStatus(serviceId = host.value, attempt = attempt, phase = phase)

private fun staged(
    reference: ProjectionReference,
    baseline: ActiveProjection? = null,
) = ParticipantPhase.createStaged(candidate = reference, baseline = baseline)

private fun active(reference: ProjectionReference) =
    ParticipantPhase.createActive(current = ActiveProjection(projection = reference, health = ProjectionHealth.HEALTHY), retained = null)
