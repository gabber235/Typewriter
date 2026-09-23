package com.typewritermc.realm.repository

import com.surrealdb.Surreal
import com.typewritermc.elements.ReferenceSlotId
import com.typewritermc.realm.ResourceDefinitionId
import com.typewritermc.realm.compiler.GraphReadRequirement
import com.typewritermc.realm.repository.utils.inTransaction
import com.typewritermc.types.DataPath
import com.typewritermc.types.DataValue
import com.typewritermc.types.DeclaredTypeId
import com.typewritermc.types.NominalTypeKind
import com.typewritermc.types.RelationId
import com.typewritermc.types.ResolvedTypeRef
import com.typewritermc.types.ResourceId
import com.typewritermc.types.TypeCatalog
import com.typewritermc.types.TypeDefinition
import com.typewritermc.types.TypeExpression
import com.typewritermc.types.TypeId
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.matchers.collections.shouldContainExactly
import io.kotest.matchers.collections.shouldContainExactlyInAnyOrder
import io.kotest.matchers.shouldBe

val SurrealBoundedAuthoringGraphLoaderTest by testSuite {
    test("resource storage preserves generic root arguments") {
        val genericRoot = rootType.copy(arguments = listOf(TypeExpression.Any))
        withGraph(
            resources = listOf(StoredFixture("generic", root = genericRoot)),
            relations = emptyList(),
        ) { database ->
            val result =
                database.inTransaction { transaction ->
                    SurrealBoundedAuthoringGraphLoader(AuthoringGraphLimits(), TypeCatalog(emptyList())).load(
                        transaction,
                        listOf(GraphSelection("generic", ResourceSeed.Ids(listOf(id("generic"))))),
                    )
                }

            val slice = (result as BoundedGraphLoadResult.Success).slice
            slice.resources.single().root shouldBe genericRoot
        }
    }

    test("definition scans compare complete generic root identities") {
        val requestedRoot = rootType.copy(arguments = listOf(TypeExpression.Any))
        withGraph(
            resources =
                listOf(
                    StoredFixture("a-incompatible", root = rootType),
                    StoredFixture("z-compatible", root = requestedRoot),
                ),
            relations = emptyList(),
        ) { database ->
            val result =
                database.inTransaction { transaction ->
                    SurrealBoundedAuthoringGraphLoader(
                        AuthoringGraphLimits(maxResources = 1),
                        TypeCatalog(emptyList()),
                    ).load(
                        transaction,
                        listOf(
                            GraphSelection(
                                "generic-scan",
                                ResourceSeed.Scan(
                                    ResourceFilter(
                                        definitions = setOf(DEFAULT_DEFINITION),
                                        assignableTo = TypeExpression.Named(requestedRoot),
                                    ),
                                ),
                            ),
                        ),
                    )
                }

            val slice = (result as BoundedGraphLoadResult.Success).slice
            slice.resources.map { it.id.value } shouldContainExactly listOf("z-compatible")
        }
    }

    test("Any scans accept resources without catalog definitions") {
        withGraph(
            resources = listOf(StoredFixture("resource")),
            relations = emptyList(),
        ) { database ->
            val result =
                database.inTransaction { transaction ->
                    SurrealBoundedAuthoringGraphLoader(
                        AuthoringGraphLimits(maxResources = 1),
                        TypeCatalog(emptyList()),
                    ).load(
                        transaction,
                        listOf(
                            GraphSelection(
                                "any-scan",
                                ResourceSeed.Scan(
                                    ResourceFilter(
                                        definitions = setOf(DEFAULT_DEFINITION),
                                        assignableTo = TypeExpression.Any,
                                    ),
                                ),
                            ),
                        ),
                    )
                }

            val slice = (result as BoundedGraphLoadResult.Success).slice
            slice.resources.map { it.id.value } shouldContainExactly listOf("resource")
        }
    }

    test("incompatible id seeds remain diagnostics without consuming resource budgets") {
        val parent = type("01010101010101010101010101010101")
        val child = type("02020202020202020202020202020202")
        val unrelated = type("03030303030303030303030303030303")
        val catalog =
            TypeCatalog(
                listOf(
                    TypeDefinition(id = parent, kind = NominalTypeKind.OPEN_ABSTRACT),
                    TypeDefinition(id = child, kind = NominalTypeKind.CONCRETE, parents = listOf(parent)),
                    TypeDefinition(id = unrelated, kind = NominalTypeKind.CONCRETE),
                ),
            )
        withGraph(
            resources =
                listOf(
                    StoredFixture("compatible", root = child),
                    StoredFixture("incompatible", root = unrelated),
                ),
            relations = emptyList(),
        ) { database ->
            val result =
                database.inTransaction { transaction ->
                    SurrealBoundedAuthoringGraphLoader(
                        AuthoringGraphLimits(maxResources = 1),
                        catalog,
                    ).load(
                        transaction,
                        listOf(
                            GraphSelection(
                                key = "typed-ids",
                                seed =
                                    ResourceSeed.Ids(
                                        values = listOf(id("compatible"), id("incompatible")),
                                        requireAssignableTo = TypeExpression.Named(parent),
                                    ),
                            ),
                        ),
                    )
                }

            val slice = (result as BoundedGraphLoadResult.Success).slice
            slice.resources.map { it.id.value } shouldContainExactly listOf("compatible")
            slice.diagnosticResources.map { it.id.value } shouldContainExactly listOf("incompatible")
        }
    }

    test("incompatible scan seeds are filtered before the database result limit") {
        val parent = type("04040404040404040404040404040404")
        val child = type("05050505050505050505050505050505")
        val unrelated = type("06060606060606060606060606060606")
        val catalog =
            TypeCatalog(
                listOf(
                    TypeDefinition(id = parent, kind = NominalTypeKind.OPEN_ABSTRACT),
                    TypeDefinition(id = child, kind = NominalTypeKind.CONCRETE, parents = listOf(parent)),
                    TypeDefinition(id = unrelated, kind = NominalTypeKind.CONCRETE),
                ),
            )
        withGraph(
            resources =
                listOf(
                    StoredFixture("a-incompatible", root = unrelated),
                    StoredFixture("z-compatible", root = child),
                ),
            relations = emptyList(),
        ) { database ->
            val result =
                database.inTransaction { transaction ->
                    SurrealBoundedAuthoringGraphLoader(
                        AuthoringGraphLimits(maxResources = 1),
                        catalog,
                    ).load(
                        transaction,
                        listOf(
                            GraphSelection(
                                key = "typed-scan",
                                seed =
                                    ResourceSeed.Scan(
                                        ResourceFilter(
                                            definitions = setOf(DEFAULT_DEFINITION),
                                            assignableTo = TypeExpression.Named(parent),
                                        ),
                                    ),
                            ),
                        ),
                    )
                }

            val slice = (result as BoundedGraphLoadResult.Success).slice
            slice.resources.map { it.id.value } shouldContainExactly listOf("z-compatible")
            slice.diagnosticResources shouldBe emptyList()
        }
    }

    test("incompatible traversal candidates do not consume resource or edge budgets") {
        val parent = type("aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa")
        val child = type("bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb")
        val unrelated = type("cccccccccccccccccccccccccccccccc")
        val catalog =
            TypeCatalog(
                listOf(
                    TypeDefinition(id = parent, kind = NominalTypeKind.OPEN_ABSTRACT),
                    TypeDefinition(id = unrelated, kind = NominalTypeKind.CONCRETE),
                    TypeDefinition(id = child, kind = NominalTypeKind.CONCRETE, parents = listOf(parent)),
                ),
            )
        withGraph(
            resources =
                listOf(
                    StoredFixture("root", root = child),
                    StoredFixture("incompatible", root = unrelated),
                    StoredFixture("compatible", root = child),
                ),
            relations =
                listOf(
                    declared("root-incompatible", "root", "incompatible"),
                    declared("root-compatible", "root", "compatible"),
                ),
        ) { database ->
            val result =
                database.inTransaction { transaction ->
                    SurrealBoundedAuthoringGraphLoader(
                        AuthoringGraphLimits(maxResources = 2, maxEdges = 1),
                        catalog,
                    ).load(
                        transaction,
                        listOf(
                            GraphSelection(
                                key = "typed",
                                seed = ResourceSeed.Ids(listOf(id("root"))),
                                steps =
                                    listOf(
                                        RelationStep(
                                            direction = RelationDirection.OUTGOING,
                                            target =
                                                ResourceFilter(
                                                    assignableTo = TypeExpression.Named(parent),
                                                ),
                                        ),
                                    ),
                            ),
                        ),
                    )
                }

            val slice = (result as BoundedGraphLoadResult.Success).slice
            slice.resources.map { it.id.value } shouldContainExactly listOf("compatible", "root")
            slice.relations.map(StoredResourceRelation::id) shouldContainExactly listOf("root-compatible")
        }
    }

    test("ordinary reference expected targets are filtered before edge budgets") {
        val parent = type("eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee")
        val child = type("ffffffffffffffffffffffffffffffff")
        val unrelated = type("12121212121212121212121212121212")
        val catalog =
            TypeCatalog(
                listOf(
                    TypeDefinition(id = parent, kind = NominalTypeKind.OPEN_ABSTRACT),
                    TypeDefinition(id = unrelated, kind = NominalTypeKind.CONCRETE),
                    TypeDefinition(id = child, kind = NominalTypeKind.CONCRETE, parents = listOf(parent)),
                ),
            )
        withGraph(
            resources = listOf("root", "compatible", "incompatible").map(::StoredFixture),
            relations =
                listOf(
                    reference("reference-incompatible", "root", "incompatible", TypeExpression.Named(unrelated)),
                    reference("reference-compatible", "root", "compatible", TypeExpression.Named(child)),
                ),
        ) { database ->
            val result =
                database.inTransaction { transaction ->
                    SurrealBoundedAuthoringGraphLoader(
                        AuthoringGraphLimits(maxResources = 3, maxEdges = 1),
                        catalog,
                    ).load(
                        transaction,
                        listOf(
                            GraphSelection(
                                key = "references",
                                seed = ResourceSeed.Ids(listOf(id("root"))),
                                steps =
                                    listOf(
                                        RelationStep(
                                            relations =
                                                RelationFilter.OrdinaryReferences(
                                                    expectedTarget = TypeExpression.Named(parent),
                                                ),
                                            direction = RelationDirection.OUTGOING,
                                        ),
                                    ),
                            ),
                        ),
                    )
                }

            val slice = (result as BoundedGraphLoadResult.Success).slice
            slice.resources.map { it.id.value } shouldContainExactly listOf("compatible", "root")
            slice.relations.map(StoredResourceRelation::id) shouldContainExactly listOf("reference-compatible")
        }
    }

    test("ordinary reference filtering continues beyond one database page") {
        val parent = type("13131313131313131313131313131313")
        val child = type("14141414141414141414141414141414")
        val unrelated = type("15151515151515151515151515151515")
        val catalog =
            TypeCatalog(
                listOf(
                    TypeDefinition(id = parent, kind = NominalTypeKind.OPEN_ABSTRACT),
                    TypeDefinition(id = child, kind = NominalTypeKind.CONCRETE, parents = listOf(parent)),
                    TypeDefinition(id = unrelated, kind = NominalTypeKind.CONCRETE),
                ),
            )
        withGraph(
            resources = listOf("root", "compatible", "incompatible").map(::StoredFixture),
            relations =
                List(300) { index ->
                    reference(
                        relationId = "a-incompatible-${index.toString().padStart(3, '0')}",
                        source = "root",
                        target = "incompatible",
                        expectedTarget = TypeExpression.Named(unrelated),
                    )
                } + reference("z-compatible", "root", "compatible", TypeExpression.Named(child)),
        ) { database ->
            val result =
                database.inTransaction { transaction ->
                    SurrealBoundedAuthoringGraphLoader(
                        AuthoringGraphLimits(maxResources = 2, maxEdges = 1),
                        catalog,
                    ).load(
                        transaction,
                        listOf(
                            GraphSelection(
                                key = "references",
                                seed = ResourceSeed.Ids(listOf(id("root"))),
                                steps =
                                    listOf(
                                        RelationStep(
                                            relations =
                                                RelationFilter.OrdinaryReferences(
                                                    expectedTarget = TypeExpression.Named(parent),
                                                ),
                                            direction = RelationDirection.OUTGOING,
                                        ),
                                    ),
                            ),
                        ),
                    )
                }

            val slice = (result as BoundedGraphLoadResult.Success).slice
            slice.resources.map { it.id.value } shouldContainExactly listOf("compatible", "root")
            slice.relations.map(StoredResourceRelation::id) shouldContainExactly listOf("z-compatible")
        }
    }

    test("selection loading reads only the selected resource neighborhood") {
        withGraph(
            resources = listOf("root", "child", "unrelated").map(::StoredFixture),
            relations = listOf(declared("root-child", "root", "child")),
        ) { database ->
            val result =
                database.inTransaction { transaction ->
                    SurrealBoundedAuthoringGraphLoader(
                        AuthoringGraphLimits(maxResources = 10, maxEdges = 10),
                        TypeCatalog(emptyList()),
                    ).load(
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

    test("policy dependency loading expands declared and reference edges from one frontier") {
        withGraph(
            resources = listOf("root", "declared", "referenced").map(::StoredFixture),
            relations =
                listOf(
                    declared("root-declared", "root", "declared"),
                    reference("root-referenced", "root", "referenced"),
                ),
        ) { database ->
            val requirement =
                GraphReadRequirement(
                    relations = setOf(RelationId(RELATION_DEFINITION_ID)),
                    direction = GraphReadRequirement.Direction.OUTGOING,
                    outgoingReferences = true,
                    maximumDepth = 1,
                )
            val result =
                database.inTransaction { transaction ->
                    SurrealBoundedAuthoringGraphLoader(
                        AuthoringGraphLimits(maxResources = 3, maxEdges = 2),
                        TypeCatalog(emptyList()),
                    ).load(
                        transaction,
                        listOf(
                            requirement.toSelection(
                                key = "policy",
                                seed = ResourceSeed.Ids(listOf(id("root"))),
                            ),
                        ),
                    )
                }

            val slice = (result as BoundedGraphLoadResult.Success).slice
            slice.resources.map { it.id.value } shouldContainExactly listOf("declared", "referenced", "root")
            slice.relations.map(StoredResourceRelation::id) shouldContainExactly listOf("root-declared", "root-referenced")
        }
    }

    test("policy dependency loading expands both reference directions from one frontier") {
        withGraph(
            resources = listOf("root", "incoming", "outgoing").map(::StoredFixture),
            relations =
                listOf(
                    reference("incoming-root", "incoming", "root"),
                    reference("root-outgoing", "root", "outgoing"),
                ),
        ) { database ->
            val requirement =
                GraphReadRequirement(
                    incomingReferences = true,
                    outgoingReferences = true,
                    maximumDepth = 1,
                )
            val result =
                database.inTransaction { transaction ->
                    SurrealBoundedAuthoringGraphLoader(
                        AuthoringGraphLimits(maxResources = 3, maxEdges = 2),
                        TypeCatalog(emptyList()),
                    ).load(
                        transaction,
                        listOf(
                            requirement.toSelection(
                                key = "policy",
                                seed = ResourceSeed.Ids(listOf(id("root"))),
                            ),
                        ),
                    )
                }

            val slice = (result as BoundedGraphLoadResult.Success).slice
            slice.resources.map { it.id.value } shouldContainExactly listOf("incoming", "outgoing", "root")
            slice.relations.map(StoredResourceRelation::id) shouldContainExactly listOf("incoming-root", "root-outgoing")
        }
    }

    test("policy dependency loading rejects an incomplete depth bounded slice") {
        withGraph(
            resources = listOf("root", "child", "grandchild").map(::StoredFixture),
            relations =
                listOf(
                    declared("root-child", "root", "child"),
                    declared("child-grandchild", "child", "grandchild"),
                ),
        ) { database ->
            val requirement =
                GraphReadRequirement(
                    relations = setOf(RelationId(RELATION_DEFINITION_ID)),
                    direction = GraphReadRequirement.Direction.OUTGOING,
                    maximumDepth = 1,
                )
            val result =
                database.inTransaction { transaction ->
                    SurrealBoundedAuthoringGraphLoader(AuthoringGraphLimits(), TypeCatalog(emptyList())).load(
                        transaction,
                        listOf(
                            requirement.toSelection(
                                key = "policy",
                                seed = ResourceSeed.Ids(listOf(id("root"))),
                            ),
                        ),
                    )
                }

            val invalid = (result as BoundedGraphLoadResult.Invalid).result
            invalid.code shouldBe "query-too-large"
            invalid.message shouldBe "Authoring graph depth limit 1 was exceeded."
        }
    }

    test("selection loading retains edges that return to an already visited resource") {
        withGraph(
            resources = listOf("root", "child").map(::StoredFixture),
            relations =
                listOf(
                    declared("root-child", "root", "child"),
                    declared("child-root", "child", "root"),
                ),
        ) { database ->
            val result =
                database.inTransaction { transaction ->
                    SurrealBoundedAuthoringGraphLoader(
                        AuthoringGraphLimits(maxResources = 10, maxEdges = 10),
                        TypeCatalog(emptyList()),
                    ).load(
                        transaction,
                        listOf(
                            GraphSelection(
                                key = "cyclic-neighborhood",
                                seed = ResourceSeed.Ids(listOf(id("root"))),
                                steps =
                                    listOf(
                                        RelationStep(
                                            RelationFilter.Any,
                                            RelationDirection.BOTH,
                                            maxDepth = 2,
                                        ),
                                    ),
                            ),
                        ),
                    )
                }

            val slice = (result as BoundedGraphLoadResult.Success).slice
            slice.resources.map { it.id.value } shouldContainExactly listOf("child", "root")
            slice.relations.map(StoredResourceRelation::id) shouldContainExactly listOf("child-root", "root-child")
        }
    }

    test("unbounded scans fail before a database scan") {
        Surreal().use { database ->
            database.connect("memory")
            database.useNs("test").useDb("test")
            val result =
                database.inTransaction { transaction ->
                    SurrealBoundedAuthoringGraphLoader(AuthoringGraphLimits(), TypeCatalog(emptyList())).load(
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
                    SurrealBoundedAuthoringGraphLoader(AuthoringGraphLimits(), TypeCatalog(emptyList())).load(
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
                    SurrealBoundedAuthoringGraphLoader(AuthoringGraphLimits(maxResources = 1), TypeCatalog(emptyList())).load(
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
                            root = fixture.root,
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
    val root: ResolvedTypeRef = rootType,
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
    expectedTarget: TypeExpression = TypeExpression.Any,
) = StoredResourceRelation(
    relationId,
    id(source),
    id(target),
    ResourceRelationOrigin.Reference(ReferenceSlotId("target"), DataPath(), expectedTarget),
)

private fun type(value: String) = ResolvedTypeRef(TypeId.Declared(DeclaredTypeId.parse(value)), 1)

private fun named(value: String) = TypeExpression.Named(type(value))

private val DEFAULT_DEFINITION = ResourceDefinitionId("test.resource")
private const val RELATION_DEFINITION_ID = "11111111111111111111111111111111"
private const val ALTERNATE_RELATION_DEFINITION_ID = "33333333333333333333333333333333"
private const val PAGE_ELEMENTS_RELATION_ID = "44444444444444444444444444444444"
private val rootType = ResolvedTypeRef(TypeId.Declared(DeclaredTypeId.parse("22222222222222222222222222222222")), 1)
