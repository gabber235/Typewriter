package com.typewritermc.realm.routes

import com.typewritermc.authoring.CommitResult
import com.typewritermc.authoring.EditExpectation
import com.typewritermc.authoring.EditIntent
import com.typewritermc.authoring.PreparedEdit
import com.typewritermc.authoring.PreparedEditResult
import com.typewritermc.authoring.of
import com.typewritermc.authoring.root
import com.typewritermc.authoring.skir.SkirAuthoringOperationCodec
import com.typewritermc.checking.CatalogGeneration
import com.typewritermc.checking.InputIdentity
import com.typewritermc.checking.toSkir
import com.typewritermc.realm.authoring.AuthoringLease
import com.typewritermc.realm.authoring.AuthoringSeed
import com.typewritermc.realm.authoring.AuthoringViewDelta
import com.typewritermc.realm.authoring.AuthoringViewStore
import com.typewritermc.realm.authoring.InMemoryAuthoringViewStore
import com.typewritermc.realm.authoring.TypeArgumentOperations
import com.typewritermc.realm.authoring.TypePreviewResult
import com.typewritermc.realm.catalog.RealmCatalogStore
import com.typewritermc.realm.catalog.installTestCatalog
import com.typewritermc.realm.checking.TestCatalogLease
import com.typewritermc.realm.checking.record
import com.typewritermc.realm.repository.AuthoringRepository
import com.typewritermc.services.libs.communicator.router.communicatorRoutes
import com.typewritermc.types.ResourceId
import com.typewritermc.types.namedUse
import com.typewritermc.types.qualified
import com.typewritermc.types.requireValid
import com.typewritermc.types.skir.getOrThrow
import com.typewritermc.types.toSkir
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.matchers.shouldBe
import kotlinx.coroutines.test.runTest
import skirout.editor.v1.authoring.CommitPreparedEditResponse
import skirout.editor.v1.authoring.PreviewTypeArgumentChangeRequest
import skirout.editor.v1.authoring.PreviewTypeArgumentChangeResponse
import skirout.editor.v1.authoring.QueryAuthoringStateRequest
import skirout.editor.v1.authoring.QueryAuthoringStateResponse
import skirout.editor.v1.authoring.TypeArgumentChangePreview
import skirout.editor.v1.checking.CheckInstanceId
import skirout.editor.v1.checking.CheckOutcome
import skirout.editor.v1.checking.CheckTicket
import skirout.editor.v1.checking.FindingSet
import skirout.editor.v1.checking.FindingStatus
import skirout.editor.v1.type_catalog.ArgumentSelection
import skirout.editor.v1.type_catalog.AuthoringRecord
import skirout.editor.v1.type_catalog.CheckExecutionId
import skirout.editor.v1.type_catalog.DataValue
import skirout.editor.v1.type_catalog.TypeDefinitionId
import skirout.editor.v1.type_catalog.TypeSelection
import skirout.editor.v1.type_catalog.ValueLocation
import skirout.editor.v1.authoring.AuthoringState as SkirAuthoringState
import skirout.editor.v1.authoring.EditIntent as SkirEditIntent
import skirout.editor.v1.authoring_facts.EditExpectation as SkirEditExpectation
import skirout.editor.v1.checking.CheckOutcome as SkirCheckOutcome
import skirout.editor.v1.type_catalog.AuthoringRecord as SkirAuthoringRecord
import skirout.editor.v1.type_catalog.CatalogGeneration as SkirCatalogGeneration
import skirout.editor.v1.type_catalog.FieldValue as SkirFieldValue
import skirout.editor.v1.type_catalog.ResourceId as SkirResourceId

val AuthoringRoutesTest by testSuite {
    test("current state query returns current findings without revision tokens") {
        runTest {
            val catalogs = RealmCatalogStore().also { it.installTestCatalog("catalog") }
            val catalogIdentity = InputIdentity.Catalog(CatalogGeneration("catalog"))
            val tombstone = InputIdentity.Existence(ResourceId("removed"))
            val views =
                InMemoryAuthoringViewStore(
                    catalogs.captureCurrent(),
                    AuthoringSeed(emptyMap()),
                )
            val missing = ValueLocation.of(ResourceId("resource"))
            val finding =
                FindingSet(
                    ticket =
                        CheckTicket(
                            instance =
                                CheckInstanceId(
                                    rule =
                                        skirout.editor.v1.type_catalog.RuleId(
                                            origin =
                                                skirout.editor.v1.type_catalog.RuleOrigin(
                                                    owner = TypeDefinitionId.qualified("test", "rule"),
                                                    ordinal = 3,
                                                ),
                                            localIndex = 7,
                                        ),
                                    location = missing,
                                ),
                            incarnation = "catalog:1",
                            execution = CheckExecutionId(value = "execution:1"),
                            catalog = CatalogGeneration("catalog").toSkir(),
                        ),
                    expectations = emptyList(),
                    outcome = CheckOutcome.NeedsInputWrapper(listOf(missing)),
                    findings = emptyList(),
                    status = FindingStatus.OUTDATED,
                )
            try {
                RouteFixture { address, _ ->
                    communicatorRoutes {
                        AuthoringRoutes(RecordingAuthoringRepository(), views, { listOf(finding) }, address = address)
                            .register(this)
                    }
                }.use { fixture ->
                    val response =
                        fixture
                            .request(
                                "editor.authoring.state.query",
                                QueryAuthoringStateRequest(
                                    generation = SkirCatalogGeneration(value = "catalog"),
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
                        .status shouldBe FindingStatus.CURRENT
                    response.findings
                        .single()
                        .outcome shouldBe
                        SkirCheckOutcome.NeedsInputWrapper(
                            listOf(missing),
                        )
                }
            } finally {
                views.close()
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
            RouteFixture { address, _ ->
                communicatorRoutes {
                    AuthoringRoutes(repository, MissingViewStore, { emptyList() }, address = address).register(this)
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
                response shouldBe SkirAuthoringOperationCodec.encode(repository.result).getOrThrow()
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

                RouteFixture { address, _ ->
                    communicatorRoutes {
                        AuthoringRoutes(repository, MissingViewStore, { emptyList() }, address = address).register(this)
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
                    recoveredResponse shouldBe SkirAuthoringOperationCodec.encode(repository.result).getOrThrow()
                }
            }
        }
    }

    test("commit route rejects duplicate root record fields before repository admission") {
        runTest {
            val repository = RecordingAuthoringRepository()
            val encoded = validPreparedEditWire()
            val configuration = record().configuration
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

            RouteFixture { address, _ ->
                communicatorRoutes {
                    AuthoringRoutes(repository, MissingViewStore, { emptyList() }, address = address).register(this)
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
                                at = ValueLocation.of(ResourceId("resource")),
                                value = DataValue.createRecord(fields = duplicateWireFields()),
                            ),
                        ),
                )

            RouteFixture { address, _ ->
                communicatorRoutes {
                    AuthoringRoutes(repository, MissingViewStore, { emptyList() }, address = address).register(this)
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
            val views =
                InMemoryAuthoringViewStore(
                    catalog,
                    AuthoringSeed(mapOf(resource to authored)),
                )
            val requested =
                TypeSelection.createPending(
                    definition = com.typewritermc.realm.checking.TEST_TYPE,
                    arguments = listOf(ArgumentSelection.UNFILLED),
                )
            val typeArguments = RecordingTypeArgumentOperations()
            try {
                RouteFixture { address, _ ->
                    communicatorRoutes {
                        AuthoringRoutes(
                            RecordingAuthoringRepository(),
                            views,
                            { emptyList() },
                            typeArguments,
                            address,
                        ).register(this)
                    }
                }.use { fixture ->
                    val response =
                        fixture.request(
                            "editor.authoring.type.preview",
                            PreviewTypeArgumentChangeRequest(
                                resource = SkirResourceId(value = resource.value),
                                requested = requested,
                                catalog = SkirCatalogGeneration(value = catalog.generation.value),
                            ),
                            PreviewTypeArgumentChangeRequest.serializer,
                            PreviewTypeArgumentChangeResponse.serializer,
                        ) as PreviewTypeArgumentChangeResponse.ReadyWrapper

                    typeArguments.requested shouldBe requested
                    val ready = response
                    ready.value.next.requireValid() shouldBe requested
                    val edit = SkirAuthoringOperationCodec.decode(ready.value.edit).getOrThrow()
                    edit.intents shouldBe listOf(EditIntent.ConfigureResource(resource, requested))
                }
            } finally {
                views.close()
            }
        }
    }

    test("snapshot query preserves unavailable resource identity and unrelated resources") {
        runTest {
            val catalog = TestCatalogLease()
            val unavailable = ResourceId("unavailable")
            val available = ResourceId("available")
            val unavailableType = TypeDefinitionId.qualified("removed", "resource")
            val unavailableRecord =
                AuthoringRecord.of(
                    configuration = TypeSelection.CompleteWrapper(unavailableType.namedUse()),
                    fields = mapOf("legacy" to DataValue.StringValueWrapper("preserved")),
                )
            val resources = mapOf(unavailable to unavailableRecord, available to record(name = "book"))
            val views =
                InMemoryAuthoringViewStore(
                    catalog,
                    AuthoringSeed(resources),
                )
            try {
                RouteFixture { address, _ ->
                    communicatorRoutes {
                        AuthoringRoutes(RecordingAuthoringRepository(), views, { emptyList() }, address = address)
                            .register(this)
                    }
                }.use { fixture ->
                    val response =
                        fixture
                            .request(
                                "editor.authoring.state.query",
                                QueryAuthoringStateRequest(
                                    generation = SkirCatalogGeneration(value = catalog.generation.value),
                                ),
                                QueryAuthoringStateRequest.serializer,
                                QueryAuthoringStateResponse.serializer,
                            ).decodeSnapshot()

                    response.resources.map { it.id.value }.toSet() shouldBe setOf("available", "unavailable")
                    val unavailableWire = response.resources.single { it.id.value == unavailable.value }
                    unavailableWire.content.requireValid() shouldBe unavailableRecord
                }
            } finally {
                views.close()
            }
        }
    }
}

private fun QueryAuthoringStateResponse.decodeSnapshot(): SkirAuthoringState = (this as QueryAuthoringStateResponse.StateWrapper).value

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
        SkirFieldValue(name = "name", value = DataValue.StringValueWrapper("first")),
        SkirFieldValue(name = "name", value = DataValue.StringValueWrapper("second")),
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
                resource = resource.toSkir(),
                next = requested,
                edit =
                    SkirAuthoringOperationCodec
                        .encode(
                            PreparedEdit(
                                catalog = snapshot.root.catalog.generation,
                                expectations = emptyList(),
                                intents = listOf(EditIntent.ConfigureResource(resource, requested)),
                            ),
                        ).getOrThrow(),
                linkRepairs = emptyList(),
                clearedLocations = emptyList(),
            ),
        )
    }

    override suspend fun prepare(preview: TypeArgumentChangePreview): PreparedEditResult =
        PreparedEditResult.Prepared(SkirAuthoringOperationCodec.decode(preview.edit).getOrThrow())
}

private data object MissingViewStore : AuthoringViewStore {
    override val changes = kotlinx.coroutines.flow.MutableStateFlow(0L)

    override fun <T> read(block: (com.typewritermc.realm.authoring.AuthoringView) -> T): T = error("Not used")

    override fun capture(): AuthoringLease = error("No current view")

    override fun retain(context: com.typewritermc.authoring.ReadContext): AuthoringLease = error("No current view")

    override fun prepare(delta: AuthoringViewDelta): com.typewritermc.realm.authoring.AuthoringView = error("Not used")

    override fun install(view: com.typewritermc.realm.authoring.AuthoringView) = error("Not used")

    override fun invalidate(reload: () -> AuthoringSeed) = error("Not used")

    override fun close() = Unit
}
