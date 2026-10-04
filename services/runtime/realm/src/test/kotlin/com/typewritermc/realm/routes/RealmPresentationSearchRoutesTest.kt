package com.typewritermc.realm.routes

import de.infix.testBalloon.framework.core.testSuite
import io.kotest.matchers.collections.shouldContainExactly
import io.kotest.matchers.shouldBe
import kotlinx.coroutines.test.runTest
import skirout.editor.v1.search.RealmPresentationSearchRequest
import skirout.editor.v1.search.RealmPresentationSearchStatus
import skirout.editor.v1.search.RealmPresentationSearchUpdate
import skirout.editor.v1.search.RealmSearchQuery
import skirout.editor.v1.type_catalog.CapabilityId
import skirout.editor.v1.type_catalog.CatalogGeneration
import skirout.editor.v1.type_catalog.DataValue
import skirout.editor.v1.type_catalog.TypeTemplate

val RealmPresentationSearchRoutesTest by testSuite {
    test("unavailable source returns a correlated typed diagnostic") {
        runTest {
            val response = UnavailableRealmPresentationSearchSource().watch(validSearchRequest()) { }

            val unavailable = response as RealmPresentationSearchUpdate.UnavailableWrapper
            unavailable.value.subscriptionId shouldBe "search"
            unavailable.value.diagnostics
                .single()
                .message shouldBe "Realm presentation search source is unavailable"
        }
    }

    test("source receives the complete request and can publish replacement snapshots") {
        runTest {
            val source = FakeRealmPresentationSearchSource()
            val request = validSearchRequest()
            val published = mutableListOf<RealmPresentationSearchUpdate>()

            val initial = source.watch(request, published::add) as RealmPresentationSearchUpdate.SnapshotWrapper
            val update = published.single() as RealmPresentationSearchUpdate.SnapshotWrapper

            source.request shouldBe request
            initial.value.status shouldBe RealmPresentationSearchStatus.LOADING
            update.value.subscriptionId shouldBe request.subscriptionId
            update.value.status shouldBe RealmPresentationSearchStatus.READY
            update.value.values shouldContainExactly listOf(DataValue.StringValueWrapper("Alex"))
            update.value.guidance shouldContainExactly listOf("Search by player name")
        }
    }

    test("invalid request is rejected before a source can start") {
        val invalid =
            validSearchRequest().copy(
                capabilityId = CapabilityId(value = ""),
                payload = DataValue.UNKNOWN,
                resultType = TypeTemplate.UNKNOWN,
            )

        val response = requireNotNull(invalidRealmPresentationSearchRequest(invalid)) as RealmPresentationSearchUpdate.SnapshotWrapper

        response.value.status shouldBe RealmPresentationSearchStatus.ERROR
        response.value.diagnostics.size shouldBe 3
    }

    test("mismatched source subscriptions become correlated error snapshots") {
        val response = invalidRealmPresentationSearchResponse("search") as RealmPresentationSearchUpdate.SnapshotWrapper

        response.value.subscriptionId shouldBe "search"
        response.value.status shouldBe RealmPresentationSearchStatus.ERROR
        response.value.diagnostics
            .single()
            .message shouldBe "Realm presentation search response used a different subscription ID"
    }
}

private class FakeRealmPresentationSearchSource : RealmPresentationSearchSource {
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
                values = listOf(DataValue.StringValueWrapper("Alex")),
                guidance = listOf("Search by player name"),
                diagnostics = emptyList(),
            ),
        )
        return RealmPresentationSearchUpdate.createSnapshot(
            subscriptionId = request.subscriptionId,
            status = RealmPresentationSearchStatus.LOADING,
            values = emptyList(),
            guidance = emptyList(),
            diagnostics = emptyList(),
        )
    }

    override fun cancel(subscriptionId: String): Boolean = false
}

private fun validSearchRequest() =
    RealmPresentationSearchRequest(
        subscriptionId = "search",
        generation = CatalogGeneration(value = "generation"),
        capabilityId = CapabilityId(value = "capability"),
        payload = DataValue.StringValueWrapper("server"),
        resultType = TypeTemplate.ScalarWrapper(skirout.editor.v1.type_catalog.ScalarKind.TEXT),
        query =
            RealmSearchQuery(
                normalizedQuery = "alex",
                terms = listOf("alex"),
                selectors = emptyList(),
                selectorExpression = null,
            ),
    )
