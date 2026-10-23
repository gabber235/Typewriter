package com.typewritermc.realm.routes

import com.typewritermc.authoring.of
import com.typewritermc.authoring.requireValid
import com.typewritermc.authoring.root
import com.typewritermc.checking.InputIdentity
import com.typewritermc.realm.authoring.AuthoringLease
import com.typewritermc.realm.authoring.AuthoringSeed
import com.typewritermc.realm.authoring.AuthoringViewDelta
import com.typewritermc.realm.authoring.AuthoringViewStore
import com.typewritermc.realm.authoring.InMemoryAuthoringViewStore
import com.typewritermc.realm.authoring.TestCatalogLease
import com.typewritermc.realm.authoring.record
import com.typewritermc.realm.catalog.RealmCatalogStore
import com.typewritermc.realm.catalog.installTestCatalog
import com.typewritermc.realm.edit.AuthoringRepository
import com.typewritermc.realm.operation.TypeArgumentOperations
import com.typewritermc.services.libs.communicator.router.communicatorRoutes
import com.typewritermc.types.namedUse
import com.typewritermc.types.qualified
import com.typewritermc.types.requireValid
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.matchers.shouldBe
import kotlinx.coroutines.test.runTest
import skirout.editor.v1.authoring.CommitPreparedEditResponse
import skirout.editor.v1.authoring.EditIntent
import skirout.editor.v1.authoring.PrepareTypeArgumentChangeResponse
import skirout.editor.v1.authoring.PreparedEdit
import skirout.editor.v1.authoring.PreviewTypeArgumentChangeRequest
import skirout.editor.v1.authoring.PreviewTypeArgumentChangeResponse
import skirout.editor.v1.authoring.QueryAuthoringStateRequest
import skirout.editor.v1.authoring.QueryAuthoringStateResponse
import skirout.editor.v1.authoring.TypeArgumentChangePreview
import skirout.editor.v1.authoring_facts.EditExpectation
import skirout.editor.v1.checking.CheckInstanceId
import skirout.editor.v1.checking.CheckOutcome
import skirout.editor.v1.checking.CheckTicket
import skirout.editor.v1.checking.FindingSet
import skirout.editor.v1.checking.FindingStatus
import skirout.editor.v1.type_catalog.ArgumentSelection
import skirout.editor.v1.type_catalog.AuthoringRecord
import skirout.editor.v1.type_catalog.CatalogGeneration
import skirout.editor.v1.type_catalog.CheckExecutionId
import skirout.editor.v1.type_catalog.DataValue
import skirout.editor.v1.type_catalog.ResourceId
import skirout.editor.v1.type_catalog.TypeDefinitionId
import skirout.editor.v1.type_catalog.TypeSelection
import skirout.editor.v1.type_catalog.ValueLocation
import skirout.editor.v1.authoring.AuthoringState as SkirAuthoringState
import skirout.editor.v1.checking.CheckOutcome as SkirCheckOutcome
import skirout.editor.v1.type_catalog.AuthoringRecord as SkirAuthoringRecord
import skirout.editor.v1.type_catalog.FieldValue as SkirFieldValue

val AuthoringRoutesTest by testSuite {
    test("current state query returns current findings without revision tokens") {
        runTest {
            val catalogs = RealmCatalogStore().also { it.installTestCatalog("catalog") }
            val catalogIdentity = InputIdentity.Catalog(CatalogGeneration(value = "catalog"))
            val tombstone = InputIdentity.Existence(ResourceId(value = "removed"))
            val views =
                InMemoryAuthoringViewStore(
                    catalogs.captureCurrent(),
                    AuthoringSeed(emptyMap()),
                )
            val missing = ValueLocation.of(ResourceId(value = "resource"))
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
                            catalog = CatalogGeneration(value = "catalog"),
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
                                    generation = CatalogGeneration(value = "catalog"),
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
                    catalog = CatalogGeneration(value = "catalog"),
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
                        prepared,
                        skirout.editor.v1.authoring.PreparedEdit.serializer,
                        CommitPreparedEditResponse.serializer,
                    )

                repository.received shouldBe prepared
                response shouldBe repository.result
            }
        }
    }

    for (invalidInput in listOf("malformed binary", "truncated binary", "unknown intent", "unknown expectation")) {
        test("commit route rejects $invalidInput and accepts the next valid edit") {
            runTest {
                val repository = RecordingAuthoringRepository()
                val prepared =
                    PreparedEdit(
                        catalog = CatalogGeneration(value = "catalog"),
                        expectations = listOf(EditExpectation.createResourceExists(id = ResourceId(value = "resource"), expected = false)),
                        intents =
                            listOf(
                                EditIntent.createCreateResource(
                                    id = ResourceId(value = "resource"),
                                    record = record(name = "created"),
                                ),
                            ),
                    )
                val wire = prepared
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
                            serializer.toBytes(wire.copy(intents = listOf(EditIntent.UNKNOWN))).toByteArray()
                        }

                        "unknown expectation" -> {
                            serializer
                                .toBytes(
                                    wire.copy(expectations = listOf(EditExpectation.UNKNOWN)),
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
                    recoveredResponse shouldBe repository.result
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
                            EditIntent.createCreateResource(
                                id = ResourceId(value = "duplicate"),
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
                            EditIntent.createSetValue(
                                at = ValueLocation.of(ResourceId(value = "resource")),
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
            val resource = ResourceId(value = "resource")
            val authored = record(name = "kept")
            val views =
                InMemoryAuthoringViewStore(
                    catalog,
                    AuthoringSeed(mapOf(resource to authored)),
                )
            val requested =
                TypeSelection.createPending(
                    definition = com.typewritermc.realm.authoring.TEST_TYPE,
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
                                resource = ResourceId(value = resource.value),
                                requested = requested,
                                catalog = catalog.generation,
                            ),
                            PreviewTypeArgumentChangeRequest.serializer,
                            PreviewTypeArgumentChangeResponse.serializer,
                        ) as PreviewTypeArgumentChangeResponse.ReadyWrapper

                    typeArguments.requested shouldBe requested
                    val ready = response
                    ready.value.next.requireValid() shouldBe requested
                    val edit = ready.value.edit.requireValid()
                    edit.intents shouldBe listOf(EditIntent.createConfigureResource(resource = resource, configuration = requested))
                }
            } finally {
                views.close()
            }
        }
    }

    test("snapshot query preserves unavailable resource identity and unrelated resources") {
        runTest {
            val catalog = TestCatalogLease()
            val unavailable = ResourceId(value = "unavailable")
            val available = ResourceId(value = "available")
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
                                    generation = catalog.generation,
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
    PreparedEdit(
        catalog = CatalogGeneration(value = "catalog"),
        expectations = emptyList(),
        intents = emptyList(),
    )

private fun duplicateWireFields(): List<SkirFieldValue> =
    listOf(
        SkirFieldValue(name = "name", value = DataValue.StringValueWrapper("first")),
        SkirFieldValue(name = "name", value = DataValue.StringValueWrapper("second")),
    )

private class RecordingAuthoringRepository : AuthoringRepository {
    val result = CommitPreparedEditResponse.COMMITTED
    var received: PreparedEdit? = null

    override suspend fun commit(edit: PreparedEdit): CommitPreparedEditResponse {
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
    ): PreviewTypeArgumentChangeResponse {
        this.requested = requested
        return PreviewTypeArgumentChangeResponse.ReadyWrapper(
            TypeArgumentChangePreview(
                resource = resource,
                next = requested,
                edit =
                    PreparedEdit(
                        catalog = snapshot.root.catalog.generation,
                        expectations = emptyList(),
                        intents = listOf(EditIntent.createConfigureResource(resource = resource, configuration = requested)),
                    ),
                linkRepairs = emptyList(),
                clearedLocations = emptyList(),
            ),
        )
    }

    override suspend fun prepare(preview: TypeArgumentChangePreview): PrepareTypeArgumentChangeResponse =
        PrepareTypeArgumentChangeResponse.createPrepared(edit = preview.edit.requireValid())
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
