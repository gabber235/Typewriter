package com.typewritermc.realm.search

import com.surrealdb.RecordId
import com.surrealdb.Surreal
import com.typewritermc.authoring.ArgumentSelection
import com.typewritermc.authoring.AuthoringRecord
import com.typewritermc.authoring.ResourceDefinitionId
import com.typewritermc.authoring.SearchSelectorId
import com.typewritermc.authoring.TypeSelection
import com.typewritermc.checking.SnapshotId
import com.typewritermc.realm.authoring.authoringStorageJson
import com.typewritermc.realm.repository.utils.unifiedSurrealId
import com.typewritermc.types.ParameterKey
import com.typewritermc.types.RepresentationTemplate
import com.typewritermc.types.ResourceId
import com.typewritermc.types.TypeDefinition
import com.typewritermc.types.TypeDefinitionId
import com.typewritermc.types.TypeId
import com.typewritermc.types.TypeParameter
import com.typewritermc.types.TypeTemplate
import com.typewritermc.types.TypeUse
import com.typewritermc.types.catalog.DefaultCheckedCatalog
import de.infix.testBalloon.framework.core.testSuite
import kotlinx.serialization.encodeToString

class IndexedSelectorFilterTest {
    fun indexedSearchPagesPastIncompatibleCandidates() {
        val parent = definition("parent")
        val compatible = definition("compatible")
        val incompatible = definition("incompatible")
        val catalog =
            DefaultCheckedCatalog(
                com.typewritermc.checking.CatalogGeneration("catalog"),
                listOf(
                    TypeDefinition(parent, representation = RepresentationTemplate.Record(emptyList(), abstract = true)),
                    TypeDefinition(
                        compatible,
                        representation = RepresentationTemplate.Record(emptyList()),
                        parents = listOf(TypeTemplate.Named(parent)),
                    ),
                    TypeDefinition(incompatible, representation = RepresentationTemplate.Record(emptyList())),
                ),
            )
        Surreal().use { database ->
            openSearchDatabase(database)
            repeat(256) { index ->
                database.insertSearchRow("a_${index.toString().padStart(3, '0')}", TypeUse.Named(incompatible))
            }
            database.insertSearchRow("z_compatible", TypeUse.Named(compatible))

            val results =
                SurrealAuthoringSearchRepository(database)
                    .search(
                        snapshot = SnapshotId("realm:0"),
                        catalog = catalog,
                        query = "",
                        contexts = emptySet(),
                        selectors = IndexedSelectorFilter.All,
                        roots = setOf(parent),
                        target = null,
                        limit = 100,
                    ).readyCandidates()

            assertEquals(listOf(ResourceId("z_compatible")), results.map { it.resource })
        }
    }

    fun negatedSelectorReturnsOnlyResourcesOutsideTheMatchedSet() {
        val type = definition("resource")
        val catalog =
            DefaultCheckedCatalog(
                com.typewritermc.checking.CatalogGeneration("catalog"),
                listOf(TypeDefinition(type, representation = RepresentationTemplate.Record(emptyList()))),
            )
        Surreal().use { database ->
            openSearchDatabase(database)
            database.insertSearchRow("draft", TypeUse.Named(type))
            database.insertSearchRow("published", TypeUse.Named(type))
            database.insertSelector(ResourceId("draft"), "status", "draft")
            database.insertSelector(ResourceId("published"), "status", "published")

            val results =
                SurrealAuthoringSearchRepository(database)
                    .search(
                        snapshot = SnapshotId("realm:0"),
                        catalog = catalog,
                        query = "",
                        contexts = emptySet(),
                        selectors =
                            IndexedSelectorFilter.Not(
                                IndexedSelectorFilter.Match(SearchSelectorId("status"), "draft"),
                            ),
                        roots = emptySet(),
                        target = null,
                        limit = 10,
                    ).readyCandidates()

            assertEquals(listOf(ResourceId("published")), results.map { it.resource })
        }
    }

    fun pendingGenericSearchRequiresProvableAppliedArguments() {
        val box = definition("box")
        val first = definition("first")
        val second = definition("second")
        val parameter = ParameterKey(box, 0)
        val catalog =
            DefaultCheckedCatalog(
                com.typewritermc.checking.CatalogGeneration("catalog"),
                listOf(
                    TypeDefinition(
                        box,
                        parameters = listOf(TypeParameter(parameter, "T")),
                        representation = RepresentationTemplate.Record(emptyList()),
                    ),
                    TypeDefinition(first, representation = RepresentationTemplate.Record(emptyList())),
                    TypeDefinition(second, representation = RepresentationTemplate.Record(emptyList())),
                ),
            )
        Surreal().use { database ->
            openSearchDatabase(database)
            database.insertSearchRow(
                "pending",
                TypeSelection.Pending(box, listOf(ArgumentSelection.Chosen(TypeUse.Named(first)))),
            )
            val repository = SurrealAuthoringSearchRepository(database)

            val matching =
                repository
                    .search(
                        snapshot = SnapshotId("realm:0"),
                        catalog = catalog,
                        query = "",
                        contexts = emptySet(),
                        selectors = IndexedSelectorFilter.All,
                        roots = emptySet(),
                        target = TypeUse.Named(box, listOf(TypeUse.Named(first))),
                        limit = 10,
                    ).readyCandidates()
            val mismatched =
                repository
                    .search(
                        snapshot = SnapshotId("realm:0"),
                        catalog = catalog,
                        query = "",
                        contexts = emptySet(),
                        selectors = IndexedSelectorFilter.All,
                        roots = emptySet(),
                        target = TypeUse.Named(box, listOf(TypeUse.Named(second))),
                        limit = 10,
                    ).readyCandidates()

            assertEquals(listOf(ResourceId("pending")), matching.map { it.resource })
            assertEquals(emptyList<ResourceId>(), mismatched.map { it.resource })
        }
    }

    fun searchRejectsAChangedDurableSnapshot() {
        val type = definition("resource")
        val catalog =
            DefaultCheckedCatalog(
                com.typewritermc.checking.CatalogGeneration("catalog"),
                listOf(TypeDefinition(type, representation = RepresentationTemplate.Record(emptyList()))),
            )
        Surreal().use { database ->
            openSearchDatabase(database)
            database.insertSearchRow("resource", TypeUse.Named(type))

            val result =
                SurrealAuthoringSearchRepository(database)
                    .search(
                        snapshot = SnapshotId("realm:1"),
                        catalog = catalog,
                        query = "",
                        contexts = emptySet(),
                        selectors = IndexedSelectorFilter.All,
                        roots = emptySet(),
                        target = null,
                        limit = 10,
                    )

            assertEquals(IndexedAuthoringSearchResult.SnapshotChanged, result)
        }
    }

    fun multiwordQueryMatchesIndexedBookTitle() {
        val type = definition("book")
        val catalog =
            DefaultCheckedCatalog(
                com.typewritermc.checking.CatalogGeneration("catalog"),
                listOf(TypeDefinition(type, representation = RepresentationTemplate.Record(emptyList()))),
            )
        Surreal().use { database ->
            openSearchDatabase(database)
            database.query(
                "DEFINE ANALYZER authoring_text TOKENIZERS class FILTERS lowercase; " +
                    "DEFINE ANALYZER authoring_approximate TOKENIZERS class FILTERS lowercase, ngram(2, 4); " +
                    "DEFINE INDEX authoring_search_text ON authoring_search FIELDS text " +
                    "FULLTEXT ANALYZER authoring_text BM25; " +
                    "DEFINE INDEX authoring_search_approximate ON authoring_search FIELDS text " +
                    "FULLTEXT ANALYZER authoring_approximate BM25;",
            )
            database.insertSearchRow("book", TypeUse.Named(type), "Metadata verification 20261004")

            val results =
                SurrealAuthoringSearchRepository(database)
                    .search(
                        snapshot = SnapshotId("realm:0"),
                        catalog = catalog,
                        query = "Metadata verification",
                        contexts = emptySet(),
                        selectors = IndexedSelectorFilter.All,
                        roots = emptySet(),
                        target = null,
                        limit = 10,
                    ).readyCandidates()

            assertEquals(listOf(ResourceId("book")), results.map { it.resource })
        }
    }
}

private fun openSearchDatabase(database: Surreal) {
    database.connect("memory")
    database.useNs("test").useDb("test")
    database.query(
        "DEFINE TABLE resource SCHEMALESS; " +
            "DEFINE TABLE authoring_search SCHEMALESS; " +
            "DEFINE TABLE authoring_search_selector SCHEMALESS; " +
            "CREATE ONLY authoring_acceptance_fence:current CONTENT { revision: 0 };",
    )
}

private fun Surreal.insertSearchRow(
    id: String,
    type: TypeUse.Named,
    text: String = "",
) = insertSearchRow(id, TypeSelection.Complete(type), text)

private fun Surreal.insertSearchRow(
    id: String,
    selection: TypeSelection,
    text: String = "",
) {
    val resource = ResourceId(id)
    val record = AuthoringRecord(selection, emptyMap())
    query(
        "CREATE ONLY \$search CONTENT { resource: \$resource, definition: \$definition, " +
            "content: \$content, text: \$text, owner_path: [] };",
        mapOf(
            "search" to RecordId("authoring_search", id),
            "resource" to resource.unifiedSurrealId(),
            "definition" to ResourceDefinitionId("test.resource").value,
            "content" to authoringStorageJson.encodeToString(AuthoringRecord.serializer(), record),
            "text" to text,
        ),
    ).take(0)
}

private fun Surreal.insertSelector(
    resource: ResourceId,
    facet: String,
    value: String,
) {
    query(
        "CREATE authoring_search_selector CONTENT { resource: \$resource, facet: \$facet, " +
            "normalized: \$normalized, display: \$display };",
        mapOf(
            "resource" to resource.unifiedSurrealId(),
            "facet" to facet,
            "normalized" to value,
            "display" to value,
        ),
    ).take(0)
}

private fun definition(name: String): TypeDefinitionId = TypeDefinitionId(TypeId.Qualified("test", name), 1)

private fun IndexedAuthoringSearchResult.readyCandidates(): List<IndexedAuthoringSearchCandidate> =
    (this as IndexedAuthoringSearchResult.Ready).candidates

val IndexedSelectorFilterTestSuite by testSuite {
    test("indexedSearchPagesPastIncompatibleCandidates") { IndexedSelectorFilterTest().indexedSearchPagesPastIncompatibleCandidates() }
    test("negatedSelectorReturnsOnlyResourcesOutsideTheMatchedSet") {
        IndexedSelectorFilterTest().negatedSelectorReturnsOnlyResourcesOutsideTheMatchedSet()
    }
    test("pendingGenericSearchRequiresProvableAppliedArguments") {
        IndexedSelectorFilterTest().pendingGenericSearchRequiresProvableAppliedArguments()
    }
    test("searchRejectsAChangedDurableSnapshot") {
        IndexedSelectorFilterTest().searchRejectsAChangedDurableSnapshot()
    }
    test("multiwordQueryMatchesIndexedBookTitle") {
        IndexedSelectorFilterTest().multiwordQueryMatchesIndexedBookTitle()
    }
}
