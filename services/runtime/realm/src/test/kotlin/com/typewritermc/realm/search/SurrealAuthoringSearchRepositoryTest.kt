package com.typewritermc.realm.search

import com.surrealdb.RecordId
import com.surrealdb.Surreal
import com.typewritermc.authoring.ArgumentSelection
import com.typewritermc.authoring.AuthoringRecord
import com.typewritermc.authoring.ResourceDefinitionId
import com.typewritermc.authoring.SearchSelectorId
import com.typewritermc.authoring.TypeSelection
import com.typewritermc.realm.authoring.AuthoringCatalogLease
import com.typewritermc.realm.authoring.AuthoringView
import com.typewritermc.realm.authoring.authoringStorageJson
import com.typewritermc.realm.checking.TestCatalogLease
import com.typewritermc.realm.repository.ResourceValueMapper
import com.typewritermc.realm.repository.utils.unifiedSurrealId
import com.typewritermc.realm.schema.openTestDatabase
import com.typewritermc.types.DataValue
import com.typewritermc.types.EndpointCardinality
import com.typewritermc.types.EndpointDefinition
import com.typewritermc.types.EndpointSlot
import com.typewritermc.types.LinkTarget
import com.typewritermc.types.ParameterKey
import com.typewritermc.types.RESOURCE_OWNERSHIP_FAMILY_ID
import com.typewritermc.types.RelationContract
import com.typewritermc.types.RelationDeletePolicy
import com.typewritermc.types.RelationFamilyId
import com.typewritermc.types.RelationId
import com.typewritermc.types.RepresentationTemplate
import com.typewritermc.types.ResourceId
import com.typewritermc.types.TypeDefinition
import com.typewritermc.types.TypeDefinitionId
import com.typewritermc.types.TypeId
import com.typewritermc.types.TypeParameter
import com.typewritermc.types.TypeTemplate
import com.typewritermc.types.TypeUse
import com.typewritermc.types.catalog.DefaultCheckedCatalog
import com.typewritermc.types.endpointId
import de.infix.testBalloon.framework.core.testSuite
import kotlinx.serialization.encodeToString

class SurrealAuthoringSearchRepositoryTest {
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
                        view = searchView(catalog),
                        query = "",
                        contexts = emptySet(),
                        roots = setOf(parent),
                        target = null,
                        limit = 100,
                    )

            assertEquals(listOf(ResourceId("z_compatible")), results.map { it.resource })
        }
    }

    fun contextRestrictsResultsToItsReachableResources() {
        val type = definition("resource")
        val catalog =
            DefaultCheckedCatalog(
                com.typewritermc.checking.CatalogGeneration("catalog"),
                listOf(TypeDefinition(type, representation = RepresentationTemplate.Record(emptyList()))),
            )
        Surreal().use { database ->
            openSearchDatabase(database)
            database.insertSearchRow("inside", TypeUse.Named(type))
            database.insertSearchRow("outside", TypeUse.Named(type))
            val results =
                SurrealAuthoringSearchRepository(database).search(
                    searchView(catalog),
                    "",
                    setOf(ResourceId("inside")),
                    emptySet(),
                    null,
                    10,
                )
            assertEquals(listOf(ResourceId("inside")), results.map { it.resource })
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
                        view = searchView(catalog),
                        query = "",
                        contexts = emptySet(),
                        roots = emptySet(),
                        target = TypeUse.Named(box, listOf(TypeUse.Named(first))),
                        limit = 10,
                    )
            val mismatched =
                repository
                    .search(
                        view = searchView(catalog),
                        query = "",
                        contexts = emptySet(),
                        roots = emptySet(),
                        target = TypeUse.Named(box, listOf(TypeUse.Named(second))),
                        limit = 10,
                    )

            assertEquals(listOf(ResourceId("pending")), matching.map { it.resource })
            assertEquals(emptyList<ResourceId>(), mismatched.map { it.resource })
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
                    "DEFINE INDEX resource_text ON resource FIELDS search.text " +
                    "FULLTEXT ANALYZER authoring_text BM25; " +
                    "DEFINE INDEX resource_approximate ON resource FIELDS search.text " +
                    "FULLTEXT ANALYZER authoring_approximate BM25;",
            )
            database.insertSearchRow("book", TypeUse.Named(type), "Metadata verification 20261004")

            val results =
                SurrealAuthoringSearchRepository(database)
                    .search(
                        view = searchView(catalog),
                        query = "Metadata verification",
                        contexts = emptySet(),
                        roots = emptySet(),
                        target = null,
                        limit = 10,
                    )

            assertEquals(listOf(ResourceId("book")), results.map { it.resource })
        }
    }
}

private fun openSearchDatabase(database: Surreal) {
    database.openTestDatabase("test")
    database.query("DEFINE TABLE resource SCHEMALESS;")
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
        "CREATE ONLY \$resource CONTENT { definition: \$definition, content: \$content, search: { text: \$text } };",
        mapOf(
            "resource" to resource.unifiedSurrealId(),
            "definition" to ResourceDefinitionId("test.resource").value,
            "content" to
                com.typewritermc.realm.authoring.authoredDatabaseValues
                    .encode(AuthoringRecord.serializer(), record),
            "text" to text,
        ),
    ).take(0)
}

private fun definition(name: String): TypeDefinitionId = TypeDefinitionId(TypeId.Qualified("test", name), 1)

private fun searchView(checked: com.typewritermc.types.catalog.CheckedCatalog): AuthoringView {
    val lease =
        object : AuthoringCatalogLease by com.typewritermc.realm.checking
            .TestCatalogLease() {
            override val checked = checked
        }
    return com.typewritermc.realm.authoring
        .AuthoringView(lease, emptyMap(), emptyMap(), emptyMap())
}

val SurrealAuthoringSearchRepositoryTestSuite by testSuite {
    test("ownership context follows descendants, tolerates cycles, and excludes other relations") {
        val type = definition("node")
        val ownedLink = definition("owned_link")
        val relatedLink = definition("related_link")
        val ownership = RelationId("ownership")
        val related = RelationId("related")

        fun contract(
            id: RelationId,
            owns: Boolean,
        ) = RelationContract(
            id,
            EndpointDefinition(
                id.endpointId(EndpointSlot.First),
                EndpointSlot.First,
                TypeTemplate.Named(type),
                EndpointCardinality.One,
                RelationDeletePolicy.CLEAR,
            ),
            EndpointDefinition(
                id.endpointId(EndpointSlot.Second),
                EndpointSlot.Second,
                TypeTemplate.Named(type),
                EndpointCardinality.One,
                RelationDeletePolicy.CLEAR,
            ),
            if (owns) setOf(RelationFamilyId(RESOURCE_OWNERSHIP_FAMILY_ID)) else emptySet(),
        )
        val lease =
            TestCatalogLease(
                definitions =
                    listOf(
                        TypeDefinition(
                            type,
                            representation =
                                RepresentationTemplate.Record(
                                    listOf(
                                        com.typewritermc.types.FieldDeclaration(
                                            com.typewritermc.types.FieldOwner(type, "owned"),
                                            TypeTemplate.Named(ownedLink),
                                        ),
                                        com.typewritermc.types.FieldDeclaration(
                                            com.typewritermc.types.FieldOwner(type, "related"),
                                            TypeTemplate.Named(relatedLink),
                                        ),
                                    ),
                                ),
                        ),
                        TypeDefinition(
                            ownedLink,
                            representation =
                                RepresentationTemplate.Link(
                                    ownership.endpointId(EndpointSlot.First),
                                    TypeTemplate.Named(type),
                                ),
                        ),
                        TypeDefinition(
                            relatedLink,
                            representation = RepresentationTemplate.Link(related.endpointId(EndpointSlot.First), TypeTemplate.Named(type)),
                        ),
                    ),
                resourceRoot = type,
                relations = listOf(contract(ownership, true), contract(related, false)),
            )
        val root = ResourceId("root")
        val child = ResourceId("child")
        val grandchild = ResourceId("grandchild")
        val outside = ResourceId("outside")

        fun link(
            id: RelationId,
            target: ResourceId,
        ) = DataValue.Link(
            id.endpointId(EndpointSlot.First),
            LinkTarget(target, null),
        )
        val selected = TypeSelection.Complete(TypeUse.Named(type))
        val resources =
            mapOf(
                root to AuthoringRecord(selected, mapOf("owned" to link(ownership, child), "related" to link(related, outside))),
                child to AuthoringRecord(selected, mapOf("owned" to link(ownership, grandchild))),
                grandchild to AuthoringRecord(selected, mapOf("owned" to link(ownership, root))),
                outside to AuthoringRecord(selected, emptyMap()),
            )
        val occurrences = ResourceValueMapper.discover(resources).associateBy { it.id }
        val view = AuthoringView(lease, resources, emptyMap(), occurrences)
        assertEquals(setOf(root, child, grandchild), view.ownershipClosure(setOf(root)))
        lease.close()
    }
    test("indexedSearchPagesPastIncompatibleCandidates") {
        SurrealAuthoringSearchRepositoryTest().indexedSearchPagesPastIncompatibleCandidates()
    }
    test("contextRestrictsResultsToItsReachableResources") {
        SurrealAuthoringSearchRepositoryTest().contextRestrictsResultsToItsReachableResources()
    }
    test("pendingGenericSearchRequiresProvableAppliedArguments") {
        SurrealAuthoringSearchRepositoryTest().pendingGenericSearchRequiresProvableAppliedArguments()
    }
    test("multiwordQueryMatchesIndexedBookTitle") {
        SurrealAuthoringSearchRepositoryTest().multiwordQueryMatchesIndexedBookTitle()
    }
}
