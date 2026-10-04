package com.typewritermc.realm.routes

import com.typewritermc.authoring.ArgumentSelection
import com.typewritermc.authoring.AuthoringRecord
import com.typewritermc.authoring.BatchId
import com.typewritermc.authoring.CheckExecutionId
import com.typewritermc.authoring.CommitResult
import com.typewritermc.authoring.PreparedEdit
import com.typewritermc.authoring.ResourceDefinitionId
import com.typewritermc.authoring.TypeSelection
import com.typewritermc.authoring.ValueLocation
import com.typewritermc.authoring.ValuePath
import com.typewritermc.authoring.skir.SkirAuthoringOperationCodec
import com.typewritermc.checking.CatalogGeneration
import com.typewritermc.checking.CheckOutcome
import com.typewritermc.checking.FindingStatus
import com.typewritermc.checking.InputIdentity
import com.typewritermc.checking.InputToken
import com.typewritermc.checking.SnapshotId
import com.typewritermc.realm.authoring.AuthoredSnapshotSeed
import com.typewritermc.realm.authoring.AuthoringSnapshotDelta
import com.typewritermc.realm.authoring.AuthoringSnapshotStore
import com.typewritermc.realm.authoring.InMemoryAuthoringSnapshotStore
import com.typewritermc.realm.authoring.RESOURCE_SELECTION_INPUT
import com.typewritermc.realm.authoring.SnapshotCommit
import com.typewritermc.realm.authoring.SnapshotInstallResult
import com.typewritermc.realm.authoring.SnapshotLease
import com.typewritermc.realm.authoring.TypeArgumentChangePreview
import com.typewritermc.realm.authoring.TypeArgumentOperations
import com.typewritermc.realm.authoring.TypePreviewResult
import com.typewritermc.realm.authoring.TypeRepairIntent
import com.typewritermc.realm.catalog.RealmCatalogStore
import com.typewritermc.realm.catalog.installTestCatalog
import com.typewritermc.realm.checking.CheckInstanceId
import com.typewritermc.realm.checking.CheckTicket
import com.typewritermc.realm.checking.FindingSet
import com.typewritermc.realm.checking.TestCatalogLease
import com.typewritermc.realm.checking.record
import com.typewritermc.realm.checking.tokensFor
import com.typewritermc.realm.repository.AuthoringRepository
import com.typewritermc.services.libs.communicator.router.communicatorRoutes
import com.typewritermc.types.DataValue
import com.typewritermc.types.ResourceId
import com.typewritermc.types.TypeDefinitionId
import com.typewritermc.types.TypeId
import com.typewritermc.types.TypeUse
import com.typewritermc.types.skir.SkirAuthoringValueCodec
import com.typewritermc.types.skir.getOrThrow
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.matchers.shouldBe
import kotlinx.coroutines.test.runTest
import skirout.editor.v1.authoring.CommitPreparedEditResponse
import skirout.editor.v1.authoring.PreviewTypeArgumentChangeRequest
import skirout.editor.v1.authoring.PreviewTypeArgumentChangeResponse
import skirout.editor.v1.authoring.QueryAuthoringSnapshotRequest
import skirout.editor.v1.authoring.QueryAuthoringSnapshotResponse
import skirout.editor.v1.authoring.AuthoringSnapshot as SkirAuthoringSnapshot
import skirout.editor.v1.authoring.EditIntent as SkirEditIntent
import skirout.editor.v1.authoring.TypePreviewResult as SkirTypePreviewResult
import skirout.editor.v1.checking.CheckOutcome as SkirCheckOutcome
import skirout.editor.v1.checking.FindingStatus as SkirFindingStatus
import skirout.editor.v1.type_catalog.AuthoringRecord as SkirAuthoringRecord
import skirout.editor.v1.type_catalog.CatalogGeneration as SkirCatalogGeneration
import skirout.editor.v1.type_catalog.DataValue as SkirDataValue
import skirout.editor.v1.type_catalog.FieldValue as SkirFieldValue
import skirout.editor.v1.type_catalog.ResourceId as SkirResourceId

val AuthoringRoutesTest by testSuite {
    test("snapshot query publishes original tokens and the shared absence sentinel") {
        runTest {
            val catalogs = RealmCatalogStore().also { it.installTestCatalog("catalog") }
            val catalogIdentity = InputIdentity.Catalog(CatalogGeneration("catalog"))
            val tombstone = InputIdentity.Existence(ResourceId("removed"))
            val snapshots =
                InMemoryAuthoringSnapshotStore(
                    catalogs.captureCurrent(),
                    AuthoredSnapshotSeed(
                        SnapshotId("snapshot"),
                        emptyMap(),
                        mapOf(
                            catalogIdentity to InputToken("catalog_token"),
                            RESOURCE_SELECTION_INPUT to InputToken("selection_token"),
                            tombstone to InputToken("tombstone_token"),
                        ),
                    ),
                )
            val missing = com.typewritermc.authoring.ValueLocation(ResourceId("resource"), com.typewritermc.authoring.ValuePath())
            val finding =
                FindingSet(
                    ticket =
                        CheckTicket(
                            instance =
                                CheckInstanceId(
                                    com.typewritermc.configuration.RuleId(
                                        com.typewritermc.configuration.RuleOrigin(
                                            TypeDefinitionId(TypeId.Qualified("test", "rule"), 1),
                                            3,
                                        ),
                                        7,
                                    ),
                                    missing,
                                ),
                            incarnation = "catalog:1",
                            execution = CheckExecutionId("execution:1"),
                            snapshot = SnapshotId("snapshot"),
                            catalog = CatalogGeneration("catalog"),
                        ),
                    observations = emptyList(),
                    outcome = CheckOutcome.NeedsInput(listOf(missing)),
                    findings = emptyList(),
                    status = FindingStatus.Outdated,
                )
            try {
                RouteFixture { contracts, _, _ ->
                    communicatorRoutes {
                        AuthoringRoutes(RecordingAuthoringRepository(), snapshots, { listOf(finding) }, contracts = contracts)
                            .register(this)
                    }
                }.use { fixture ->
                    val response =
                        fixture
                            .request(
                                "editor.authoring.snapshot.query",
                                QueryAuthoringSnapshotRequest(
                                    generation = SkirCatalogGeneration(value = "catalog"),
                                    snapshot = null,
                                    transferId = "snapshot_tokens",
                                ),
                                QueryAuthoringSnapshotRequest.serializer,
                                QueryAuthoringSnapshotResponse.serializer,
                            ).decodeSnapshot()

                    response.absentInputToken.value shouldBe "absent"
                    response.observations
                        .map { SkirAuthoringValueCodec.decode(it).getOrThrow() }
                        .toSet() shouldBe
                        setOf(
                            com.typewritermc.checking.InputObservation(catalogIdentity, InputToken("catalog_token")),
                            com.typewritermc.checking.InputObservation(RESOURCE_SELECTION_INPUT, InputToken("selection_token")),
                            com.typewritermc.checking.InputObservation(tombstone, InputToken("tombstone_token")),
                        )
                    response.findings
                        .single()
                        .ticket.instance.rule.localIndex shouldBe 7
                    response.findings
                        .single()
                        .status shouldBe SkirFindingStatus.CURRENT
                    response.findings
                        .single()
                        .outcome shouldBe
                        SkirCheckOutcome.NeedsInputWrapper(
                            listOf(SkirAuthoringValueCodec.encode(missing).getOrThrow()),
                        )
                }
            } finally {
                snapshots.close()
                catalogs.close()
            }
        }
    }

    test("commit route decodes the prepared edit and returns the repository result") {
        runTest {
            val repository = RecordingAuthoringRepository()
            val prepared =
                PreparedEdit(
                    id = BatchId("batch"),
                    catalog = CatalogGeneration("catalog"),
                    snapshot = SnapshotId("snapshot"),
                    observations = emptyList(),
                    intents = emptyList(),
                )
            RouteFixture { contracts, _, _ ->
                communicatorRoutes {
                    AuthoringRoutes(repository, MissingSnapshotStore, { emptyList() }, contracts = contracts).register(this)
                }
            }.use { fixture ->
                val response =
                    fixture.request(
                        "editor.authoring.edit.commit",
                        SkirAuthoringOperationCodec.encode(prepared).getOrThrow(),
                        skirout.editor.v1.authoring.PreparedEdit.serializer,
                        CommitPreparedEditResponse.serializer,
                    )

                repository.received shouldBe prepared
                response as CommitPreparedEditResponse.ResultWrapper
                response.value shouldBe SkirAuthoringOperationCodec.encode(repository.result).getOrThrow()
            }
        }
    }

    test("commit route rejects duplicate root record fields before repository admission") {
        runTest {
            val repository = RecordingAuthoringRepository()
            val encoded = validPreparedEditWire()
            val configuration = SkirAuthoringValueCodec.encode(record()).getOrThrow().configuration
            val duplicate =
                SkirAuthoringRecord(
                    configuration = configuration,
                    fields = duplicateWireFields(),
                )
            val malformed =
                encoded.copy(
                    intents =
                        listOf(
                            SkirEditIntent.createCreateResource(
                                id = SkirResourceId(value = "duplicate"),
                                record = duplicate,
                            ),
                        ),
                )

            RouteFixture { contracts, _, _ ->
                communicatorRoutes {
                    AuthoringRoutes(repository, MissingSnapshotStore, { emptyList() }, contracts = contracts).register(this)
                }
            }.use { fixture ->
                val response =
                    fixture.request(
                        "editor.authoring.edit.commit",
                        malformed,
                        skirout.editor.v1.authoring.PreparedEdit.serializer,
                        CommitPreparedEditResponse.serializer,
                    )

                response::class shouldBe CommitPreparedEditResponse.InternalErrorWrapper::class
                repository.received shouldBe null
            }
        }
    }

    test("commit route rejects duplicate nested record fields before repository admission") {
        runTest {
            val repository = RecordingAuthoringRepository()
            val encoded = validPreparedEditWire()
            val malformed =
                encoded.copy(
                    intents =
                        listOf(
                            SkirEditIntent.createSetValue(
                                at = SkirAuthoringValueCodec.encode(ValueLocation(ResourceId("resource"), ValuePath())).getOrThrow(),
                                value = SkirDataValue.createRecord(fields = duplicateWireFields()),
                            ),
                        ),
                )

            RouteFixture { contracts, _, _ ->
                communicatorRoutes {
                    AuthoringRoutes(repository, MissingSnapshotStore, { emptyList() }, contracts = contracts).register(this)
                }
            }.use { fixture ->
                val response =
                    fixture.request(
                        "editor.authoring.edit.commit",
                        malformed,
                        skirout.editor.v1.authoring.PreparedEdit.serializer,
                        CommitPreparedEditResponse.serializer,
                    )

                response::class shouldBe CommitPreparedEditResponse.InternalErrorWrapper::class
                repository.received shouldBe null
            }
        }
    }

    test("type argument preview route preserves an unfinished selection and configuration repair") {
        runTest {
            val catalog = TestCatalogLease()
            val resource = ResourceId("resource")
            val authored = record(name = "kept")
            val snapshots =
                InMemoryAuthoringSnapshotStore(
                    catalog,
                    AuthoredSnapshotSeed(
                        SnapshotId("snapshot"),
                        mapOf(resource to authored),
                        tokensFor(mapOf(resource to authored), catalog.generation),
                    ),
                )
            val requested =
                TypeSelection.Pending(
                    com.typewritermc.realm.checking.TEST_TYPE,
                    listOf(ArgumentSelection.Unfilled),
                )
            val typeArguments = RecordingTypeArgumentOperations()
            try {
                RouteFixture { contracts, _, _ ->
                    communicatorRoutes {
                        AuthoringRoutes(
                            RecordingAuthoringRepository(),
                            snapshots,
                            { emptyList() },
                            typeArguments,
                            contracts,
                        ).register(this)
                    }
                }.use { fixture ->
                    val response =
                        fixture.request(
                            "editor.authoring.type.preview",
                            PreviewTypeArgumentChangeRequest(
                                resource = SkirResourceId(value = resource.value),
                                requested = SkirAuthoringValueCodec.encode(requested).getOrThrow(),
                                snapshot =
                                    skirout.editor.v1.type_catalog
                                        .SnapshotId(value = "snapshot"),
                                catalog = SkirCatalogGeneration(value = catalog.generation.value),
                            ),
                            PreviewTypeArgumentChangeRequest.serializer,
                            PreviewTypeArgumentChangeResponse.serializer,
                        ) as PreviewTypeArgumentChangeResponse.ResultWrapper

                    typeArguments.requested shouldBe requested
                    val ready = response.value as SkirTypePreviewResult.ReadyWrapper
                    SkirAuthoringValueCodec.decode(ready.value.next).getOrThrow() shouldBe requested
                    val repair = ready.value.intents.single()
                    repair as skirout.editor.v1.authoring.TypeRepairIntent.ConfigureResourceWrapper
                    SkirAuthoringValueCodec.decode(repair.value.configuration).getOrThrow() shouldBe requested
                }
            } finally {
                snapshots.close()
            }
        }
    }

    test("snapshot query preserves unavailable resource identity and unrelated resources") {
        runTest {
            val catalog = TestCatalogLease()
            val unavailable = ResourceId("unavailable")
            val available = ResourceId("available")
            val unavailableType = TypeDefinitionId(TypeId.Qualified("removed", "resource"), 1)
            val unavailableRecord =
                AuthoringRecord(
                    configuration = TypeSelection.Complete(TypeUse.Named(unavailableType)),
                    fields = mapOf("legacy" to DataValue.StringValue("preserved")),
                )
            val resources = mapOf(unavailable to unavailableRecord, available to record(name = "book"))
            val snapshots =
                InMemoryAuthoringSnapshotStore(
                    catalog,
                    AuthoredSnapshotSeed(
                        SnapshotId("snapshot"),
                        resources,
                        tokensFor(resources, catalog.generation),
                        mapOf(
                            unavailable to ResourceDefinitionId("removed_definition"),
                            available to ResourceDefinitionId("test"),
                        ),
                    ),
                )
            try {
                RouteFixture { contracts, _, _ ->
                    communicatorRoutes {
                        AuthoringRoutes(RecordingAuthoringRepository(), snapshots, { emptyList() }, contracts = contracts)
                            .register(this)
                    }
                }.use { fixture ->
                    val response =
                        fixture
                            .request(
                                "editor.authoring.snapshot.query",
                                QueryAuthoringSnapshotRequest(
                                    generation = SkirCatalogGeneration(value = catalog.generation.value),
                                    snapshot = null,
                                    transferId = "snapshot_unavailable_resource",
                                ),
                                QueryAuthoringSnapshotRequest.serializer,
                                QueryAuthoringSnapshotResponse.serializer,
                            ).decodeSnapshot()

                    response.resources.associate { it.id.value to it.definition.value } shouldBe
                        mapOf("available" to "test", "unavailable" to "removed_definition")
                    val unavailableWire = response.resources.single { it.id.value == unavailable.value }
                    SkirAuthoringValueCodec.decode(unavailableWire.content).getOrThrow() shouldBe unavailableRecord
                }
            } finally {
                snapshots.close()
            }
        }
    }
}

private fun QueryAuthoringSnapshotResponse.decodeSnapshot(): SkirAuthoringSnapshot {
    val chunk = (this as QueryAuthoringSnapshotResponse.ChunkWrapper).value.transfer
    return SkirAuthoringSnapshot.serializer.fromBytes(chunk.payload)
}

private fun validPreparedEditWire() =
    SkirAuthoringOperationCodec
        .encode(
            PreparedEdit(
                id = BatchId("batch"),
                catalog = CatalogGeneration("catalog"),
                snapshot = SnapshotId("snapshot"),
                observations = emptyList(),
                intents = emptyList(),
            ),
        ).getOrThrow()

private fun duplicateWireFields(): List<SkirFieldValue> =
    listOf(
        SkirFieldValue(name = "name", value = SkirDataValue.StringValueWrapper("first")),
        SkirFieldValue(name = "name", value = SkirDataValue.StringValueWrapper("second")),
    )

private class RecordingAuthoringRepository : AuthoringRepository {
    val result = CommitResult.Committed(SnapshotId("snapshot_2"), emptySet())
    var received: PreparedEdit? = null

    override suspend fun commit(edit: PreparedEdit): CommitResult {
        received = edit
        return result
    }
}

private class RecordingTypeArgumentOperations : TypeArgumentOperations {
    var requested: TypeSelection? = null

    override fun preview(
        resource: ResourceId,
        requested: TypeSelection,
        snapshot: SnapshotLease,
    ): TypePreviewResult {
        this.requested = requested
        return TypePreviewResult.Ready(
            TypeArgumentChangePreview(
                resource = resource,
                next = requested,
                catalog = snapshot.root.catalog.generation,
                sourceSnapshot = snapshot.root.id,
                observations = emptyList(),
                intents = listOf(TypeRepairIntent.ConfigureResource(resource, requested)),
                linkRepairs = emptyList(),
                clearedLocations = emptyList(),
            ),
        )
    }

    override suspend fun confirm(preview: TypeArgumentChangePreview): CommitResult =
        CommitResult.Committed(SnapshotId("committed"), emptySet())
}

private data object MissingSnapshotStore : AuthoringSnapshotStore {
    override fun <T> commitAndInstall(commit: () -> SnapshotCommit<T>): T = error("Not used")

    override fun capture(): SnapshotLease = error("No snapshot")

    override fun retain(id: SnapshotId): SnapshotLease = error("No snapshot")

    override fun install(delta: AuthoringSnapshotDelta): SnapshotInstallResult = error("Not used")

    override fun currentToken(identity: InputIdentity): InputToken = error("Not used")

    override fun close() = Unit
}
