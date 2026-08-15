package com.typewritermc.realm.routes

import de.infix.testBalloon.framework.core.testSuite
import io.kotest.matchers.collections.shouldContainExactly
import io.kotest.matchers.shouldBe
import kotlinx.coroutines.test.runTest
import skirout.editor.v1.diagnostic.DiagnosticCode
import skirout.editor.v1.search.RealmPresentationSearchRequest
import skirout.editor.v1.search.RealmPresentationSearchStatus
import skirout.editor.v1.search.RealmPresentationSearchUpdate
import skirout.editor.v1.search.RealmSearchQuery
import skirout.editor.v1.type_catalog.RealmActionId
import skirout.editor.v1.type_catalog.TypeExpression
import skirout.editor.v1.type_catalog.TypedValue

val RealmPresentationSearchRoutesTest by testSuite {
    test("production presentation search source returns typed unavailable diagnostics") {
        runTest {
            RouteFixture().use { fixture ->
                val response = fixture.search(validSearchRequest())
                val unavailable = response as RealmPresentationSearchUpdate.UnavailableWrapper

                unavailable.value.subscriptionId shouldBe "search"
                unavailable.value.diagnostics
                    .single()
                    .message shouldBe
                    "Realm presentation search source is unavailable"
            }
        }
    }

    test("route passes the complete request and publishes complete replacement snapshots") {
        runTest {
            val source = FakeRealmPresentationSearchSource()
            val request = validSearchRequest()
            RouteFixture(presentationSearch = source).use { fixture ->
                val initial = fixture.search(request) as RealmPresentationSearchUpdate.SnapshotWrapper
                val update =
                    fixture
                        .publishedTo("editor.presentation.search", RealmPresentationSearchUpdate.serializer)
                        .single() as RealmPresentationSearchUpdate.SnapshotWrapper

                source.request shouldBe request
                initial.value.status shouldBe RealmPresentationSearchStatus.LOADING
                update.value.subscriptionId shouldBe request.subscriptionId
                update.value.status shouldBe RealmPresentationSearchStatus.READY
                update.value.values shouldContainExactly listOf(TypedValue.StringWrapper("Alex"))
                update.value.guidance shouldContainExactly listOf("Search by player name")
            }
        }
    }

    test("invalid requests are rejected before reaching the source") {
        runTest {
            val source = FakeRealmPresentationSearchSource()
            val invalid =
                validSearchRequest().copy(
                    realmActionId = RealmActionId(namespace = "", name = ""),
                    payload = TypedValue.UNKNOWN,
                    resultType = TypeExpression.UNKNOWN,
                )
            RouteFixture(presentationSearch = source).use { fixture ->
                val response = fixture.search(invalid) as RealmPresentationSearchUpdate.SnapshotWrapper

                source.request shouldBe null
                response.value.status shouldBe RealmPresentationSearchStatus.ERROR
                response.value.diagnostics.map { it.code } shouldContainExactly
                    listOf(
                        DiagnosticCode.INVALID_VALUE,
                        DiagnosticCode.INVALID_VALUE,
                        DiagnosticCode.INVALID_VALUE,
                        DiagnosticCode.INVALID_VALUE,
                    )
            }
        }
    }

    test("mismatched source subscriptions become correlated error snapshots") {
        runTest {
            val source = FakeRealmPresentationSearchSource(initialSubscriptionId = "different")
            RouteFixture(presentationSearch = source).use { fixture ->
                val response = fixture.search(validSearchRequest()) as RealmPresentationSearchUpdate.SnapshotWrapper

                response.value.subscriptionId shouldBe "search"
                response.value.status shouldBe RealmPresentationSearchStatus.ERROR
                response.value.diagnostics
                    .single()
                    .message shouldBe
                    "Realm presentation search response used a different subscription ID"
            }
        }
    }
}

private class FakeRealmPresentationSearchSource(
    private val initialSubscriptionId: String? = null,
) : RealmPresentationSearchSource {
    var request: RealmPresentationSearchRequest? = null

    override suspend fun watch(
        request: RealmPresentationSearchRequest,
        updates: RealmPresentationSearchUpdatePublisher,
    ): RealmPresentationSearchUpdate {
        this.request = request
        updates.publish(
            RealmPresentationSearchUpdate.createSnapshot(
                subscriptionId = request.subscriptionId,
                status = RealmPresentationSearchStatus.READY,
                values = listOf(TypedValue.StringWrapper("Alex")),
                guidance = listOf("Search by player name"),
                diagnostics = emptyList(),
            ),
        )
        return RealmPresentationSearchUpdate.createSnapshot(
            subscriptionId = initialSubscriptionId ?: request.subscriptionId,
            status = RealmPresentationSearchStatus.LOADING,
            values = emptyList(),
            guidance = emptyList(),
            diagnostics = emptyList(),
        )
    }
}

private suspend fun RouteFixture.search(request: RealmPresentationSearchRequest): RealmPresentationSearchUpdate =
    request(
        "editor.presentation.search",
        request,
        RealmPresentationSearchRequest.serializer,
        RealmPresentationSearchUpdate.serializer,
    )

private fun validSearchRequest() =
    RealmPresentationSearchRequest(
        subscriptionId = "search",
        realmActionId = RealmActionId(namespace = "minecraft", name = "searchPlayers"),
        payload = TypedValue.StringWrapper("server"),
        resultType = TypeExpression.UNIT,
        query =
            RealmSearchQuery(
                normalizedQuery = "alex",
                selectors = emptyList(),
                selectorExpression = null,
            ),
    )
