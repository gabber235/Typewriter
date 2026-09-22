package com.typewritermc.realm.repository

import com.surrealdb.Surreal
import com.typewritermc.elements.ReferenceSlotId
import com.typewritermc.realm.ResourceDefinitionId
import com.typewritermc.realm.compiler.GraphReadRequirement
import com.typewritermc.realm.repository.utils.inTransaction
import com.typewritermc.types.DataPath
import com.typewritermc.types.DataValue
import com.typewritermc.types.DeclaredTypeId
import com.typewritermc.types.RelationId
import com.typewritermc.types.ResolvedTypeRef
import com.typewritermc.types.ResourceId
import com.typewritermc.types.TypeExpression
import com.typewritermc.types.TypeId
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.matchers.collections.shouldContainExactly
import io.kotest.matchers.collections.shouldContainExactlyInAnyOrder
import io.kotest.matchers.shouldBe

val SurrealBoundedAuthoringGraphLoaderTest by testSuite {
    test("selection loading reads only the selected resource neighborhood") {
        withGraph(
            resources = listOf("root", "child", "unrelated").map(::StoredFixture),
            relations = listOf(declared("root-child", "root", "child")),
        ) { database ->
            val result =
                database.inTransaction { transaction ->
                    SurrealBoundedAuthoringGraphLoader(AuthoringGraphLimits(maxResources = 10, maxEdges = 10)).load(
                        transaction,
                        listOf(
                            GraphSelection(
                                key = "root-neighborhood",
                                seed = ResourceSeed.Ids(listOf(id("root"))),
                                steps = listOf(RelationStep(RelationFilter.Any, RelationDirection.OUTGOING)),
                            ),
                        ),
                    )
                }

            val slice = (result as BoundedGraphLoadResult.Success).slice
            slice.resources.map { it.id.value } shouldContainExactly listOf("child", "root")
            slice.relations.map(StoredResourceRelation::id) shouldContainExactly listOf("root-child")
        }
    }

    test("unbounded scans fail before a database scan") {
        Surreal().use { database ->
            database.connect("memory")
            database.useNs("test").useDb("test")
            val result =
                database.inTransaction { transaction ->
                    SurrealBoundedAuthoringGraphLoader(AuthoringGraphLimits()).load(
                        transaction,
                        listOf(GraphSelection("all", ResourceSeed.Scan())),
                    )
                }

            val invalid = (result as BoundedGraphLoadResult.Invalid).result
            invalid.code shouldBe "unbounded-scan"
        }
    }

    test("a compilation neighborhood excludes unrelated resource definitions") {
        withGraph(
            resources =
                listOf(
                    StoredFixture("page", ResourceDefinitionId("typewriter.page")),
                    StoredFixture("element", ResourceDefinitionId("typewriter.element")),
                    StoredFixture("book", ResourceDefinitionId("typewriter.book")),
                    StoredFixture("tag", ResourceDefinitionId("typewriter.tag")),
                ),
            relations =
                listOf(
                    declared("page-element", "page", "element", RelationId(PAGE_ELEMENTS_RELATION_ID)),
                    declared("page-book", "page", "book", RelationId(PAGE_ELEMENTS_RELATION_ID)),
                    declared("page-tag", "page", "tag", RelationId(PAGE_ELEMENTS_RELATION_ID)),
                ),
        ) { database ->
            val result =
                database.inTransaction { transaction ->
                    SurrealBoundedAuthoringGraphLoader(AuthoringGraphLimits()).load(
                        transaction,
                        listOf(
                            GraphSelection(
                                key = "page-compilation",
                                seed = ResourceSeed.Ids(listOf(id("page"))),
                                steps =
                                    listOf(
                                        RelationStep(
                                            relations = RelationFilter.Declared(setOf(RelationId(PAGE_ELEMENTS_RELATION_ID))),
                                            direction = RelationDirection.OUTGOING,
                                            target =
                                                ResourceFilter(
                                                    definitions =
                                                        setOf(
                                                            ResourceDefinitionId("typewriter.page"),
                                                            ResourceDefinitionId("typewriter.element"),
                                                        ),
                                                ),
                                        ),
                                    ),
                            ),
                        ),
                    )
                }

            val slice = (result as BoundedGraphLoadResult.Success).slice
            slice.resources.map { it.id.value } shouldContainExactly listOf("element", "page")
            slice.relations.map(StoredResourceRelation::id) shouldContainExactly listOf("page-element")
        }
    }

    test("definition scans enforce the resource budget at the query boundary") {
        withGraph(
            resources = listOf("one", "two").map(::StoredFixture),
            relations = emptyList(),
        ) { database ->
            val result =
                database.inTransaction { transaction ->
                    SurrealBoundedAuthoringGraphLoader(AuthoringGraphLimits(maxResources = 1)).load(
                        transaction,
                        listOf(
                            GraphSelection(
                                key = "resources",
                                seed = ResourceSeed.Scan(ResourceFilter(definitions = setOf(DEFAULT_DEFINITION))),
                            ),
                        ),
                    )
                }

            val invalid = (result as BoundedGraphLoadResult.Invalid).result
            invalid.code shouldBe "query-too-large"
            invalid.message shouldBe "Authoring graph resource limit 1 was exceeded."
        }
    }

    test("mutation closure reports a typed depth budget failure") {
        withGraph(
            resources = listOf("root", "child", "grandchild").map(::StoredFixture),
            relations =
                listOf(
                    declared("root-child", "root", "child"),
                    declared("child-grandchild", "child", "grandchild"),
                ),
        ) { database ->
            val result =
                database.inTransaction { transaction ->
                    SurrealMutationGraphLoader().load(
                        transaction,
                        roots = setOf(id("root")),
                        requirement =
                            GraphReadRequirement(
                                definitions = setOf(DEFAULT_DEFINITION),
                                relations = setOf(RelationId(RELATION_DEFINITION_ID)),
                                maximumDepth = 1,
                            ),
                    )
                }

            val invalid = (result as MutationGraphLoadResult.Invalid).diagnostic
            invalid.code shouldBe "mutation-graph-depth-limit-exceeded"
        }
    }

    test("mutation closure enforces declared relation and direction requirements") {
        withGraph(
            resources = listOf("root", "child", "parent").map(::StoredFixture),
            relations =
                listOf(
                    declared("root-child", "root", "child"),
                    declared("parent-root", "parent", "root", RelationId(ALTERNATE_RELATION_DEFINITION_ID)),
                ),
        ) { database ->
            val result =
                database.inTransaction { transaction ->
                    SurrealMutationGraphLoader().load(
                        transaction,
                        roots = setOf(id("root")),
                        requirement =
                            GraphReadRequirement(
                                definitions = setOf(DEFAULT_DEFINITION),
                                relations = setOf(RelationId(RELATION_DEFINITION_ID)),
                                direction = GraphReadRequirement.Direction.OUTGOING,
                                maximumDepth = 1,
                            ),
                    )
                }

            val graph = (result as MutationGraphLoadResult.Success).graph
            graph.resources.keys.map(ResourceId::value) shouldContainExactlyInAnyOrder listOf("child", "root")
            graph.relations.keys shouldContainExactly listOf("root-child")
        }
    }

    test("mutation closure excludes references unless the requirement requests them") {
        withGraph(
            resources = listOf("root", "target").map(::StoredFixture),
            relations = listOf(reference("root-target", "root", "target")),
        ) { database ->
            val result =
                database.inTransaction { transaction ->
                    SurrealMutationGraphLoader().load(
                        transaction,
                        roots = setOf(id("root")),
                        requirement =
                            GraphReadRequirement(
                                definitions = setOf(DEFAULT_DEFINITION),
                                maximumDepth = 1,
                            ),
                    )
                }

            val graph = (result as MutationGraphLoadResult.Success).graph
            graph.resources.keys.map(ResourceId::value) shouldContainExactly listOf("root")
            graph.relations shouldBe emptyMap()

            val included =
                database.inTransaction { transaction ->
                    SurrealMutationGraphLoader().load(
                        transaction,
                        roots = setOf(id("root")),
                        requirement =
                            GraphReadRequirement(
                                definitions = setOf(DEFAULT_DEFINITION),
                                outgoingReferences = true,
                                maximumDepth = 1,
                            ),
                    )
                }
            val includedGraph = (included as MutationGraphLoadResult.Success).graph
            includedGraph.resources.keys.map(ResourceId::value) shouldContainExactlyInAnyOrder listOf("root", "target")
            includedGraph.relations.keys shouldContainExactly listOf("root-target")
        }
    }
}

private fun withGraph(
    resources: List<StoredFixture>,
    relations: List<StoredResourceRelation>,
    block: (Surreal) -> Unit,
) {
    Surreal().use { database ->
        database.connect("memory")
        database.useNs("test").useDb("test")
        database.inTransaction { transaction ->
            val values =
                resources.associate { fixture ->
                    val stored =
                        StoredTypedResource(
                            id = id(fixture.id),
                            definition = fixture.definition,
                            root = rootType,
                            valueWithSlots = DataValue.Record(emptyMap()),
                        )
                    stored.id to DecomposedResourceValue(stored, emptyList())
                }
            SurrealResourceGraphStore().apply(
                transaction,
                AuthoringGraphDelta(
                    resourceUpserts = values,
                    resourceCreates = values.keys,
                    resourceRemovals = emptySet(),
                    relationUpserts = relations.associateBy(StoredResourceRelation::id),
                    relationRemovals = emptySet(),
                ),
            )
        }
        block(database)
    }
}

private data class StoredFixture(
    val id: String,
    val definition: ResourceDefinitionId = DEFAULT_DEFINITION,
)

private fun id(value: String) = ResourceId(value)

private fun declared(
    relationId: String,
    source: String,
    target: String,
    definition: RelationId = RelationId(RELATION_DEFINITION_ID),
) = StoredResourceRelation(relationId, id(source), id(target), ResourceRelationOrigin.Declared(definition))

private fun reference(
    relationId: String,
    source: String,
    target: String,
) = StoredResourceRelation(
    relationId,
    id(source),
    id(target),
    ResourceRelationOrigin.Reference(ReferenceSlotId("target"), DataPath(), TypeExpression.Any),
)

private val DEFAULT_DEFINITION = ResourceDefinitionId("test.resource")
private const val RELATION_DEFINITION_ID = "11111111111111111111111111111111"
private const val ALTERNATE_RELATION_DEFINITION_ID = "33333333333333333333333333333333"
private const val PAGE_ELEMENTS_RELATION_ID = "44444444444444444444444444444444"
private val rootType = ResolvedTypeRef(TypeId.Declared(DeclaredTypeId.parse("22222222222222222222222222222222")), 1)
