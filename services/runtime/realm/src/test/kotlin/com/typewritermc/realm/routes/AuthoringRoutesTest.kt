@file:OptIn(GeneratedSdkApi::class)

package com.typewritermc.realm.routes

import com.typewritermc.authoring.GeneratedSdkApi
import com.typewritermc.authoring.of
import com.typewritermc.authoring.requireValid
import com.typewritermc.library.TagDefinition
import com.typewritermc.library.book
import com.typewritermc.library.library
import com.typewritermc.protocol.transport.RealmRouteScope
import com.typewritermc.protocol.transport.generated.authoringEditCommit
import com.typewritermc.protocol.transport.generated.authoringStateQuery
import com.typewritermc.protocol.transport.generated.authoringTypeCommit
import com.typewritermc.protocol.transport.generated.authoringTypePreview
import com.typewritermc.realm.authoring.TEST_DEFINITIONS
import com.typewritermc.realm.authoring.record
import com.typewritermc.realm.testing.DefinitionCatalog
import com.typewritermc.realm.testing.RealmFixture
import com.typewritermc.realm.testing.shouldBeCommitted
import com.typewritermc.realm.testing.shouldBeInvalid
import com.typewritermc.realm.testing.text
import com.typewritermc.realm.testing.withSetup
import com.typewritermc.services.libs.communicator.router.communicatorRoutes
import com.typewritermc.setup.setup
import com.typewritermc.types.namedUse
import com.typewritermc.types.qualified
import com.typewritermc.types.requireValid
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.matchers.shouldBe
import io.kotest.matchers.string.shouldContain
import io.kotest.matchers.types.shouldBeInstanceOf
import kotlinx.coroutines.test.runTest
import skirout.editor.v1.authoring.CommitPreparedEditResponse
import skirout.editor.v1.authoring.EditIntent
import skirout.editor.v1.authoring.PrepareTypeArgumentChangeResponse
import skirout.editor.v1.authoring.PreviewTypeArgumentChangeRequest
import skirout.editor.v1.authoring.PreviewTypeArgumentChangeResponse
import skirout.editor.v1.authoring.QueryAuthoringStateRequest
import skirout.editor.v1.authoring.QueryAuthoringStateResponse
import skirout.editor.v1.authoring_facts.EditExpectation
import skirout.editor.v1.checking.FindingSet
import skirout.editor.v1.checking.FindingStatus
import skirout.editor.v1.type_catalog.AuthoringRecord
import skirout.editor.v1.type_catalog.CatalogGeneration
import skirout.editor.v1.type_catalog.DataValue
import skirout.editor.v1.type_catalog.TypeDefinitionId
import skirout.editor.v1.type_catalog.TypeSelection
import skirout.kernel.v1.resource_id.ResourceId

val AuthoringRoutesTest by testSuite {
    val tutorial =
        setup("tutorial") {
            library {
                books.book("tutorial") {
                    title = "Tutorial"
                    handle
                }
            }
        }

    /** Payloads that are no prepared edit at all; the communicator cannot decode them, so they never reach the route. */
    val undecodableCommits =
        listOf(
            InvalidCommit("malformed binary") { byteArrayOf(-1) },
            InvalidCommit("truncated binary") { book -> encode(rename(book, "Renamed").submitted()).dropLast(1).toByteArray() },
        )

    /** Prepared edits no editor may send, each paired with the rule its refusal names. */
    val invalidCommits =
        listOf(
            InvalidCommit("an unknown intent") { book ->
                encode(rename(book, "Renamed").copy(intents = listOf(EditIntent.UNKNOWN)).submitted())
            } to
                "Unknown edit intent",
            InvalidCommit("an unknown expectation") { book ->
                val edit = rename(book, "Renamed")
                encode(edit.copy(expectations = edit.expectations + EditExpectation.UNKNOWN).submitted())
            } to "Unknown edit expectation",
            InvalidCommit("a created record with duplicate field names") { book ->
                val duplicate = AuthoringRecord(configuration = resources.getValue(book.resource).configuration, fields = duplicateTitles())
                encode(edit(EditIntent.createCreateResource(id = ResourceId(value = "copy"), record = duplicate)).submitted())
            } to "Record field title is duplicated",
            InvalidCommit("a nested record with duplicate field names") { book ->
                encode(
                    edit(
                        EditIntent.createSetValue(at = titleOf(book), value = DataValue.createRecord(fields = duplicateTitles())),
                    ).submitted(),
                )
            } to "Record field title is duplicated",
        )

    test("an edit committed over the wire answers with the saved state the state query then returns") {
        runTest {
            withSetup(tutorial) { book ->
                authoringRoutes().use { wire ->
                    val committed = wire.call(RealmRouteScope::authoringEditCommit, rename(book, "Renamed").submitted()).shouldBeCommitted()

                    resources.getValue(book.resource).text("title") shouldBe "Renamed"
                    committed.resources
                        .single { it.id == book.resource }
                        .content
                        .requireValid()
                        .text("title") shouldBe "Renamed"
                    wire.state(generation) shouldBe committed
                }
            }
        }
    }

    for ((invalid, reason) in invalidCommits) {
        test("a commit of ${invalid.name} is refused as invalid with its reason, saves nothing, and the next valid edit commits") {
            runTest {
                withSetup(tutorial) { book ->
                    authoringRoutes().use { wire ->
                        val before = resources

                        val diagnostic =
                            wire
                                .send(RealmRouteScope::authoringEditCommit, invalid.payload(this, book))
                                .shouldBeInstanceOf<CommitPreparedEditResponse.InvalidErrorWrapper>()
                                .value.diagnostics
                                .single()

                        diagnostic.code shouldBe "invalid_edit"
                        diagnostic.message shouldContain reason
                        resources shouldBe before
                        wire.call(RealmRouteScope::authoringEditCommit, rename(book, "Renamed").submitted()).shouldBeCommitted()
                    }
                }
            }
        }
    }

    test("a commit without a submission key is refused as invalid and saves nothing") {
        runTest {
            withSetup(tutorial) { book ->
                authoringRoutes().use { wire ->
                    val before = resources

                    wire
                        .call(RealmRouteScope::authoringEditCommit, rename(book, "Renamed").submitted(submission = ""))
                        .shouldBeInvalid("invalid_submission")
                    resources shouldBe before
                }
            }
        }
    }

    for (undecodable in undecodableCommits) {
        test("a commit of ${undecodable.name} fails without saving anything and the next valid edit commits") {
            runTest {
                withSetup(tutorial) { book ->
                    authoringRoutes().use { wire ->
                        val before = resources

                        wire
                            .send(RealmRouteScope::authoringEditCommit, undecodable.payload(this, book))
                            .shouldBeInstanceOf<CommitPreparedEditResponse.InternalErrorWrapper>()

                        resources shouldBe before
                        wire.call(RealmRouteScope::authoringEditCommit, rename(book, "Renamed").submitted()).shouldBeCommitted()
                    }
                }
            }
        }
    }

    test("a state query for an older catalog is answered with the current generation") {
        runTest {
            withSetup(tutorial) { _ ->
                authoringRoutes().use { wire ->
                    wire
                        .call(
                            RealmRouteScope::authoringStateQuery,
                            QueryAuthoringStateRequest(generation = CatalogGeneration(value = "previous")),
                        ).shouldBeInstanceOf<QueryAuthoringStateResponse.CatalogChangedErrorWrapper>()
                        .value.actualGeneration shouldBe generation
                }
            }
        }
    }

    test("the state query reports a finding current while the values it checked are saved and outdated once they change") {
        runTest {
            withSetup(tutorial) { book ->
                // Stored as outdated: the query judges freshness against the state it returns, not the stored status.
                val finding = titleFinding(book, FindingStatus.OUTDATED)
                authoringRoutes { listOf(finding) }.use { wire ->
                    wire.state(generation).findings shouldBe listOf(finding.copy(status = FindingStatus.CURRENT))

                    commit(rename(book, "Renamed")).shouldBeCommitted()
                    wire.state(generation).findings shouldBe listOf(finding.copy(status = FindingStatus.OUTDATED))

                    commit(rename(book, "Tutorial")).shouldBeCommitted()
                    wire.state(generation).findings shouldBe listOf(finding.copy(status = FindingStatus.CURRENT))
                }
            }
        }
    }

    test("the state query returns a resource whose type the catalog no longer has unchanged beside the others") {
        runTest {
            val removed =
                AuthoringRecord.of(
                    configuration = TypeSelection.CompleteWrapper(TypeDefinitionId.qualified("removed", "resource").namedUse()),
                    fields = mapOf("legacy" to DataValue.StringValueWrapper("preserved")),
                )
            val book = record(name = "book")
            val seed = mapOf(ResourceId(value = "unavailable") to removed, ResourceId(value = "available") to book)
            RealmFixture.of(DefinitionCatalog(TEST_DEFINITIONS), seed).use { realm ->
                realm.authoringRoutes().use { wire ->
                    wire.state(realm.generation).resources.associate { it.id to it.content.requireValid() } shouldBe seed
                }
            }
        }
    }

    test("a type preview of the saved selection is ready and the edit prepared from it commits") {
        runTest {
            withSetup(tutorial) { book ->
                authoringRoutes().use { wire ->
                    val saved = resources.getValue(book.resource).configuration

                    val preview =
                        wire
                            .call(
                                RealmRouteScope::authoringTypePreview,
                                PreviewTypeArgumentChangeRequest(resource = book.resource, requested = saved, catalog = generation),
                            ).shouldBeInstanceOf<PreviewTypeArgumentChangeResponse.ReadyWrapper>()
                            .value
                    preview.next.requireValid() shouldBe saved
                    val prepared =
                        wire
                            .call(RealmRouteScope::authoringTypeCommit, preview)
                            .shouldBeInstanceOf<PrepareTypeArgumentChangeResponse.PreparedWrapper>()
                            .value.edit

                    wire.call(RealmRouteScope::authoringEditCommit, prepared.submitted()).shouldBeCommitted()
                    resources.getValue(book.resource).configuration shouldBe saved
                }
            }
        }
    }

    test("a type preview is refused with the reason it cannot apply") {
        runTest {
            withSetup(tutorial) { book ->
                authoringRoutes().use { wire ->
                    val saved = resources.getValue(book.resource).configuration
                    val tag = TypeSelection.CompleteWrapper(TagDefinition.id.namedUse())

                    wire
                        .call(
                            RealmRouteScope::authoringTypePreview,
                            PreviewTypeArgumentChangeRequest(
                                resource = book.resource,
                                requested = saved,
                                catalog = CatalogGeneration(value = "previous"),
                            ),
                        ).shouldBeInstanceOf<PreviewTypeArgumentChangeResponse.InvalidArgumentsErrorWrapper>()
                        .value
                        .map { it.code } shouldBe listOf("catalog_changed")
                    wire
                        .call(
                            RealmRouteScope::authoringTypePreview,
                            PreviewTypeArgumentChangeRequest(resource = book.resource, requested = tag, catalog = generation),
                        ).shouldBeInstanceOf<PreviewTypeArgumentChangeResponse.InvalidArgumentsErrorWrapper>()
                        .value
                        .map { it.code } shouldBe listOf("type_argument_definition_changed")
                    wire
                        .call(
                            RealmRouteScope::authoringTypePreview,
                            PreviewTypeArgumentChangeRequest(
                                resource = ResourceId(value = "missing"),
                                requested = saved,
                                catalog = generation,
                            ),
                        ).shouldBeInstanceOf<PreviewTypeArgumentChangeResponse.InvalidArgumentsErrorWrapper>()
                        .value
                        .map { it.code } shouldBe listOf("resource_missing")
                }
            }
        }
    }
}
