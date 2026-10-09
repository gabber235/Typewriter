package com.typewritermc.realm.routes

import com.typewritermc.authoring.ArgumentSelection
import com.typewritermc.authoring.AuthoringRecord
import com.typewritermc.authoring.CheckExecutionId
import com.typewritermc.authoring.CommitResult
import com.typewritermc.authoring.EditExpectation
import com.typewritermc.authoring.EditIntent
import com.typewritermc.authoring.PreparedEdit
import com.typewritermc.authoring.PreparedEditResult
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
import com.typewritermc.realm.authoring.AuthoringLease
import com.typewritermc.realm.authoring.AuthoringSeed
import com.typewritermc.realm.authoring.AuthoringViewDelta
import com.typewritermc.realm.authoring.AuthoringViewStore
import com.typewritermc.realm.authoring.InMemoryAuthoringViewStore
import com.typewritermc.realm.authoring.RESOURCE_SELECTION_INPUT
import com.typewritermc.realm.authoring.TypeArgumentChangePreview
import com.typewritermc.realm.authoring.TypeArgumentOperations
import com.typewritermc.realm.authoring.TypePreviewResult
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
import skirout.editor.v1.authoring.QueryAuthoringStateRequest
import skirout.editor.v1.authoring.QueryAuthoringStateResponse
import skirout.editor.v1.authoring.AuthoringState as SkirAuthoringState
import skirout.editor.v1.authoring.EditIntent as SkirEditIntent
import skirout.editor.v1.authoring.TypePreviewResult as SkirTypePreviewResult
import skirout.editor.v1.authoring_facts.EditExpectation as SkirEditExpectation
import skirout.editor.v1.checking.CheckOutcome as SkirCheckOutcome
import skirout.editor.v1.checking.FindingStatus as SkirFindingStatus
import skirout.editor.v1.type_catalog.AuthoringRecord as SkirAuthoringRecord
import skirout.editor.v1.type_catalog.CatalogGeneration as SkirCatalogGeneration
import skirout.editor.v1.type_catalog.DataValue as SkirDataValue
import skirout.editor.v1.type_catalog.FieldValue as SkirFieldValue
import skirout.editor.v1.type_catalog.ResourceId as SkirResourceId

val AuthoringRoutesTest by testSuite {
    test("current state query returns current findings without revision tokens") {
        runTest {
            val catalogs = RealmCatalogStore().also { it.installTestCatalog("catalog") }
            val catalogIdentity = InputIdentity.Catalog(CatalogGeneration("catalog"))
            val tombstone = InputIdentity.Existence(ResourceId("removed"))
            val snapshots =
                InMemoryAuthoringViewStore(
                    catalogs.captureCurrent(),
                    AuthoringSeed(emptyMap()),
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
                            catalog = CatalogGeneration("catalog"),
                        ),
                    expectations = emptyList(),
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
                                "editor.authoring.state.query",
                                QueryAuthoringStateRequest(
                                    generation = SkirCatalogGeneration(value = "catalog"),
                                    transferId = "snapshot_tokens",
                                ),
                                QueryAuthoringStateRequest.serializer,
                                QueryAuthoringStateResponse.serializer,
                            ).decodeSnapshot()

                    response.generation.value shouldBe "catalog"
                    response.resources shouldBe emptyList()
                    response.links shouldBe emptyList()
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
                    catalog = CatalogGeneration("catalog"),
                    expectations = emptyList(),
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

    for (invalidInput in listOf("malformed binary", "truncated binary", "unknown intent", "unknown expectation")) {
        test("commit route rejects $invalidInput and accepts the next valid edit") {
            runTest {
                val repository = RecordingAuthoringRepository()
                val prepared =
                    PreparedEdit(
                        catalog = CatalogGeneration("catalog"),
                        expectations = listOf(EditExpectation.ResourceExists(ResourceId("resource"), false)),
                        intents =
                            listOf(
                                EditIntent.CreateResource(
                                    ResourceId("resource"),
                                    record(name = "created"),
                                ),
                            ),
                    )
                val wire = SkirAuthoringOperationCodec.encode(prepared).getOrThrow()
                val serializer = skirout.editor.v1.authoring.PreparedEdit.serializer
                val invalidPayload =
                    when (invalidInput) {
                        "malformed binary" -> {
                            byteArrayOf(-1)
                        }

                        "truncated binary" -> {
                            serializer
                                .toBytes(wire)
                                .toByteArray()
                                .dropLast(1)
                                .toByteArray()
                        }

                        "unknown intent" -> {
                            serializer.toBytes(wire.copy(intents = listOf(SkirEditIntent.UNKNOWN))).toByteArray()
                        }

                        "unknown expectation" -> {
                            serializer
                                .toBytes(
                                    wire.copy(expectations = listOf(SkirEditExpectation.UNKNOWN)),
                                ).toByteArray()
                        }

                        else -> {
                            error("Unexpected invalid input scenario")
                        }
                    }

                RouteFixture { contracts, _, _ ->
                    communicatorRoutes {
                        AuthoringRoutes(repository, MissingSnapshotStore, { emptyList() }, contracts = contracts).register(this)
                    }
                }.use { fixture ->
                    val invalidResponse =
                        fixture.requestPayload(
                            "editor.authoring.edit.commit",
                            invalidPayload,
                            CommitPreparedEditResponse.serializer,
                        )
                    invalidResponse::class shouldBe CommitPreparedEditResponse.InternalErrorWrapper::class
                    repository.received shouldBe null

                    val recoveredResponse =
                        fixture.request(
                            "editor.authoring.edit.commit",
                            wire,
                            serializer,
                            CommitPreparedEditResponse.serializer,
                        )
                    repository.received shouldBe prepared
                    recoveredResponse as CommitPreparedEditResponse.ResultWrapper
                    recoveredResponse.value shouldBe SkirAuthoringOperationCodec.encode(repository.result).getOrThrow()
                }
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
                InMemoryAuthoringViewStore(
                    catalog,
                    AuthoringSeed(mapOf(resource to authored)),
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
                                catalog = SkirCatalogGeneration(value = catalog.generation.value),
                            ),
                            PreviewTypeArgumentChangeRequest.serializer,
                            PreviewTypeArgumentChangeResponse.serializer,
                        ) as PreviewTypeArgumentChangeResponse.ResultWrapper

                    typeArguments.requested shouldBe requested
                    val ready = response.value as SkirTypePreviewResult.ReadyWrapper
                    SkirAuthoringValueCodec.decode(ready.value.next).getOrThrow() shouldBe requested
                    val edit = SkirAuthoringOperationCodec.decode(ready.value.edit).getOrThrow()
                    edit.intents shouldBe listOf(EditIntent.ConfigureResource(resource, requested))
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
                InMemoryAuthoringViewStore(
                    catalog,
                    AuthoringSeed(
                        resources,
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
                                "editor.authoring.state.query",
                                QueryAuthoringStateRequest(
                                    generation = SkirCatalogGeneration(value = catalog.generation.value),
                                    transferId = "snapshot_unavailable_resource",
                                ),
                                QueryAuthoringStateRequest.serializer,
                                QueryAuthoringStateResponse.serializer,
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

private fun QueryAuthoringStateResponse.decodeSnapshot(): SkirAuthoringState {
    val chunk = (this as QueryAuthoringStateResponse.ChunkWrapper).value.transfer
    return SkirAuthoringState.serializer.fromBytes(chunk.payload)
}

private fun validPreparedEditWire() =
    SkirAuthoringOperationCodec
        .encode(
            PreparedEdit(
                catalog = CatalogGeneration("catalog"),
                expectations = emptyList(),
                intents = emptyList(),
            ),
        ).getOrThrow()

private fun duplicateWireFields(): List<SkirFieldValue> =
    listOf(
        SkirFieldValue(name = "name", value = SkirDataValue.StringValueWrapper("first")),
        SkirFieldValue(name = "name", value = SkirDataValue.StringValueWrapper("second")),
    )

private class RecordingAuthoringRepository : AuthoringRepository {
    val result = CommitResult.Committed
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
        snapshot: AuthoringLease,
    ): TypePreviewResult {
        this.requested = requested
        return TypePreviewResult.Ready(
            TypeArgumentChangePreview(
                resource = resource,
                next = requested,
                edit =
                    PreparedEdit(
                        catalog = snapshot.root.catalog.generation,
                        expectations = emptyList(),
                        intents = listOf(EditIntent.ConfigureResource(resource, requested)),
                    ),
                linkRepairs = emptyList(),
                clearedLocations = emptyList(),
            ),
        )
    }

    override suspend fun prepare(preview: TypeArgumentChangePreview): PreparedEditResult = PreparedEditResult.Prepared(preview.edit)
}

private data object MissingSnapshotStore : AuthoringViewStore {
    override fun <T> read(block: (com.typewritermc.realm.authoring.AuthoringView) -> T): T = error("Not used")

    override fun capture(): AuthoringLease = error("No current view")

    override fun retain(context: com.typewritermc.authoring.ReadContext): AuthoringLease = error("No current view")

    override fun prepare(delta: AuthoringViewDelta): com.typewritermc.realm.authoring.AuthoringView = error("Not used")

    override fun install(view: com.typewritermc.realm.authoring.AuthoringView) = error("Not used")

    override fun invalidate(reload: () -> AuthoringSeed) = error("Not used")

    override fun close() = Unit
}
