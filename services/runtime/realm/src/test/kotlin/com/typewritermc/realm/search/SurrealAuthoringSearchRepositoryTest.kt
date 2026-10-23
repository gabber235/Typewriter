package com.typewritermc.realm.search

import com.surrealdb.Surreal
import com.typewritermc.authoring.RealmRootDefinition
import com.typewritermc.authoring.of
import com.typewritermc.realm.authoring.AuthoringCatalogLease
import com.typewritermc.realm.authoring.AuthoringView
import com.typewritermc.realm.authoring.ResourceValueMapper
import com.typewritermc.realm.authoring.TestCatalogLease
import com.typewritermc.realm.storage.openTestDatabase
import com.typewritermc.realm.storage.surrealRecordId
import com.typewritermc.types.RESOURCE_OWNERSHIP_FAMILY_ID
import com.typewritermc.types.catalog.DefaultCheckedCatalog
import com.typewritermc.types.endpointId
import com.typewritermc.types.namedTemplate
import com.typewritermc.types.namedUse
import com.typewritermc.types.of
import com.typewritermc.types.qualified
import com.typewritermc.types.template
import com.typewritermc.types.use
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.matchers.shouldBe
import skirout.editor.v1.catalog.EndpointCardinality
import skirout.editor.v1.catalog.EndpointDefinition
import skirout.editor.v1.catalog.EndpointSlot
import skirout.editor.v1.catalog.RelationContract
import skirout.editor.v1.catalog.RelationDeletePolicy
import skirout.editor.v1.type_catalog.ArgumentSelection
import skirout.editor.v1.type_catalog.AuthoringRecord
import skirout.editor.v1.type_catalog.DataValue
import skirout.editor.v1.type_catalog.FieldDeclaration
import skirout.editor.v1.type_catalog.FieldOwner
import skirout.editor.v1.type_catalog.LinkTarget
import skirout.editor.v1.type_catalog.NamedTypeUse
import skirout.editor.v1.type_catalog.ParameterKey
import skirout.editor.v1.type_catalog.RelationFamilyId
import skirout.editor.v1.type_catalog.RelationId
import skirout.editor.v1.type_catalog.RepresentationTemplate
import skirout.editor.v1.type_catalog.ResourceId
import skirout.editor.v1.type_catalog.TypeDefinition
import skirout.editor.v1.type_catalog.TypeDefinitionId
import skirout.editor.v1.type_catalog.TypeParameter
import skirout.editor.v1.type_catalog.TypeSelection

class SurrealAuthoringSearchRepositoryTest {
    fun indexedSearchPagesPastIncompatibleCandidates() {
        val parent = definition("parent")
        val compatible = definition("compatible")
        val incompatible = definition("incompatible")
        val catalog =
            DefaultCheckedCatalog(
                skirout.editor.v1.type_catalog
                    .CatalogGeneration(value = "catalog"),
                listOf(
                    TypeDefinition.partial(
                        id = parent,
                        representation = RepresentationTemplate.createRecord(fields = emptyList(), abstract_ = true),
                    ),
                    TypeDefinition.partial(
                        id = compatible,
                        representation = RepresentationTemplate.createRecord(fields = emptyList(), abstract_ = false),
                        parents = listOf(parent.namedTemplate()),
                    ),
                    TypeDefinition.partial(
                        id = incompatible,
                        representation = RepresentationTemplate.createRecord(fields = emptyList(), abstract_ = false),
                    ),
                ),
            )
        Surreal().use { database ->
            openSearchDatabase(database)
            repeat(256) { index ->
                database.insertSearchRow("a_${index.toString().padStart(3, '0')}", incompatible.namedUse())
            }
            database.insertSearchRow("z_compatible", compatible.namedUse())

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

            results.map { it.resource } shouldBe listOf(ResourceId(value = "z_compatible"))
        }
    }

    fun contextRestrictsResultsToItsReachableResources() {
        val type = definition("resource")
        val catalog =
            DefaultCheckedCatalog(
                skirout.editor.v1.type_catalog
                    .CatalogGeneration(value = "catalog"),
                listOf(
                    TypeDefinition.partial(
                        id = type,
                        representation = RepresentationTemplate.createRecord(fields = emptyList(), abstract_ = false),
                    ),
                ),
            )
        Surreal().use { database ->
            openSearchDatabase(database)
            database.insertSearchRow("inside", type.namedUse())
            database.insertSearchRow("outside", type.namedUse())
            val results =
                SurrealAuthoringSearchRepository(database).search(
                    searchView(catalog),
                    "",
                    setOf(ResourceId(value = "inside")),
                    emptySet(),
                    null,
                    10,
                )
            results.map { it.resource } shouldBe listOf(ResourceId(value = "inside"))
        }
    }

    fun pendingGenericSearchRequiresProvableAppliedArguments() {
        val box = definition("box")
        val first = definition("first")
        val second = definition("second")
        val parameter = ParameterKey(owner = box, index = 0)
        val catalog =
            DefaultCheckedCatalog(
                skirout.editor.v1.type_catalog
                    .CatalogGeneration(value = "catalog"),
                listOf(
                    TypeDefinition.partial(
                        id = box,
                        parameters = listOf(TypeParameter.partial(key = parameter, name = "T")),
                        representation = RepresentationTemplate.createRecord(fields = emptyList(), abstract_ = false),
                    ),
                    TypeDefinition.partial(
                        id = first,
                        representation = RepresentationTemplate.createRecord(fields = emptyList(), abstract_ = false),
                    ),
                    TypeDefinition.partial(
                        id = second,
                        representation = RepresentationTemplate.createRecord(fields = emptyList(), abstract_ = false),
                    ),
                ),
            )
        Surreal().use { database ->
            openSearchDatabase(database)
            database.insertSearchRow(
                "pending",
                TypeSelection.createPending(definition = box, arguments = listOf(ArgumentSelection.ChosenWrapper(first.use()))),
            )
            val repository = SurrealAuthoringSearchRepository(database)

            val matching =
                repository
                    .search(
                        view = searchView(catalog),
                        query = "",
                        contexts = emptySet(),
                        roots = emptySet(),
                        target = box.namedUse(listOf(first.use())),
                        limit = 10,
                    )
            val mismatched =
                repository
                    .search(
                        view = searchView(catalog),
                        query = "",
                        contexts = emptySet(),
                        roots = emptySet(),
                        target = box.namedUse(listOf(second.use())),
                        limit = 10,
                    )

            matching.map { it.resource } shouldBe listOf(ResourceId(value = "pending"))
            mismatched.map { it.resource } shouldBe emptyList<ResourceId>()
        }
    }

    fun realmRootIsExcludedWhileSectionsStaySearchable() {
        val section = definition("section")
        val catalog =
            DefaultCheckedCatalog(
                skirout.editor.v1.type_catalog
                    .CatalogGeneration(value = "catalog"),
                listOf(
                    TypeDefinition.partial(
                        id = RealmRootDefinition.id,
                        representation = RepresentationTemplate.createRecord(fields = emptyList(), abstract_ = false),
                    ),
                    TypeDefinition.partial(
                        id = section,
                        representation = RepresentationTemplate.createRecord(fields = emptyList(), abstract_ = false),
                    ),
                ),
            )
        Surreal().use { database ->
            openSearchDatabase(database)
            database.insertSearchRow("root", RealmRootDefinition.id.namedUse())
            database.insertSearchRow("section", section.namedUse())

            val results =
                SurrealAuthoringSearchRepository(database)
                    .search(searchView(catalog), "", emptySet(), emptySet(), null, 10)

            results.map { it.resource } shouldBe listOf(ResourceId(value = "section"))
        }
    }

    fun multiwordQueryMatchesIndexedBookTitle() {
        val type = definition("book")
        val catalog =
            DefaultCheckedCatalog(
                skirout.editor.v1.type_catalog
                    .CatalogGeneration(value = "catalog"),
                listOf(
                    TypeDefinition.partial(
                        id = type,
                        representation = RepresentationTemplate.createRecord(fields = emptyList(), abstract_ = false),
                    ),
                ),
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
            database.insertSearchRow("book", type.namedUse(), "Metadata verification 20261004")

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

            results.map { it.resource } shouldBe listOf(ResourceId(value = "book"))
        }
    }
}

private fun openSearchDatabase(database: Surreal) {
    database.openTestDatabase("test")
    database.query("DEFINE TABLE resource SCHEMALESS;")
}

private fun Surreal.insertSearchRow(
    id: String,
    type: NamedTypeUse,
    text: String = "",
) = insertSearchRow(id, TypeSelection.CompleteWrapper(type), text)

private fun Surreal.insertSearchRow(
    id: String,
    selection: TypeSelection,
    text: String = "",
) {
    val resource = ResourceId(value = id)
    val record = AuthoringRecord.of(selection, emptyMap())
    query(
        "CREATE ONLY \$resource CONTENT { content: \$content, search: { text: \$text } };",
        mapOf(
            "resource" to resource.surrealRecordId(),
            "content" to
                com.typewritermc.realm.storage
                    .encodeSkir(AuthoringRecord.serializer, record),
            "text" to text,
        ),
    ).take(0)
}

private fun definition(name: String): TypeDefinitionId = TypeDefinitionId.qualified("test", name)

private fun searchView(checked: com.typewritermc.types.catalog.CheckedCatalog): AuthoringView {
    val lease =
        object : AuthoringCatalogLease by com.typewritermc.realm.authoring
            .TestCatalogLease() {
            override val checked = checked
        }
    return com.typewritermc.realm.authoring
        .AuthoringView(lease, emptyMap(), emptyMap())
}

val SurrealAuthoringSearchRepositoryTestSuite by testSuite {
    test("ownership context follows descendants, tolerates cycles, and excludes other relations") {
        val type = definition("node")
        val ownedLink = definition("owned_link")
        val relatedLink = definition("related_link")
        val ownership = RelationId(value = "ownership")
        val related = RelationId(value = "related")

        fun contract(
            id: RelationId,
            owns: Boolean,
        ) = RelationContract.of(
            id,
            EndpointDefinition(
                id = id.endpointId(EndpointSlot.FIRST),
                slot = EndpointSlot.FIRST,
                resource = type.namedTemplate(),
                cardinality = EndpointCardinality.ONE,
                onDelete = RelationDeletePolicy.CLEAR,
            ),
            EndpointDefinition(
                id = id.endpointId(EndpointSlot.SECOND),
                slot = EndpointSlot.SECOND,
                resource = type.namedTemplate(),
                cardinality = EndpointCardinality.ONE,
                onDelete = RelationDeletePolicy.CLEAR,
            ),
            if (owns) setOf(RelationFamilyId(value = RESOURCE_OWNERSHIP_FAMILY_ID)) else emptySet(),
        )
        val lease =
            TestCatalogLease(
                definitions =
                    listOf(
                        TypeDefinition.partial(
                            id = type,
                            representation =
                                RepresentationTemplate.createRecord(
                                    fields =
                                        listOf(
                                            FieldDeclaration.partial(
                                                owner = FieldOwner(definition = type, name = "owned"),
                                                type = ownedLink.template(),
                                            ),
                                            FieldDeclaration.partial(
                                                owner = FieldOwner(definition = type, name = "related"),
                                                type = relatedLink.template(),
                                            ),
                                        ),
                                    abstract_ = false,
                                ),
                        ),
                        TypeDefinition.partial(
                            id = ownedLink,
                            representation =
                                RepresentationTemplate.createLink(
                                    endpoint = ownership.endpointId(EndpointSlot.FIRST),
                                    target = type.template(),
                                ),
                        ),
                        TypeDefinition.partial(
                            id = relatedLink,
                            representation =
                                RepresentationTemplate.createLink(
                                    endpoint = related.endpointId(EndpointSlot.FIRST),
                                    target = type.template(),
                                ),
                        ),
                    ),
                relations = listOf(contract(ownership, true), contract(related, false)),
            )
        val root = ResourceId(value = "root")
        val child = ResourceId(value = "child")
        val grandchild = ResourceId(value = "grandchild")
        val outside = ResourceId(value = "outside")

        fun link(
            id: RelationId,
            target: ResourceId,
        ) = DataValue.createLink(
            endpoint = id.endpointId(EndpointSlot.FIRST),
            target = LinkTarget(resource = target, opposite = null),
        )
        val selected = TypeSelection.CompleteWrapper(type.namedUse())
        val resources =
            mapOf(
                root to AuthoringRecord.of(selected, mapOf("owned" to link(ownership, child), "related" to link(related, outside))),
                child to AuthoringRecord.of(selected, mapOf("owned" to link(ownership, grandchild))),
                grandchild to AuthoringRecord.of(selected, mapOf("owned" to link(ownership, root))),
                outside to AuthoringRecord.of(selected, emptyMap()),
            )
        val occurrences = ResourceValueMapper.discover(resources).associateBy { it.id }
        val view = AuthoringView(lease, resources, occurrences)
        view.ownershipClosure(setOf(root)) shouldBe setOf(root, child, grandchild)
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
    test("realmRootIsExcludedWhileSectionsStaySearchable") {
        SurrealAuthoringSearchRepositoryTest().realmRootIsExcludedWhileSectionsStaySearchable()
    }
    test("multiwordQueryMatchesIndexedBookTitle") {
        SurrealAuthoringSearchRepositoryTest().multiwordQueryMatchesIndexedBookTitle()
    }
}
