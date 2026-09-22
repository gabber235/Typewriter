package com.typewritermc.realm.repository

import com.surrealdb.Surreal
import com.typewritermc.realm.ResourceDefinitionId
import com.typewritermc.realm.repository.utils.inTransaction
import com.typewritermc.types.DataPath
import com.typewritermc.types.DeclaredTypeId
import com.typewritermc.types.NominalTypeKind
import com.typewritermc.types.RelationCardinality
import com.typewritermc.types.RelationDefinition
import com.typewritermc.types.RelationDeletePolicy
import com.typewritermc.types.RelationEndpointDefinition
import com.typewritermc.types.RelationEndpointSide
import com.typewritermc.types.RelationId
import com.typewritermc.types.ResolvedTypeRef
import com.typewritermc.types.ResourceId
import com.typewritermc.types.TypeCatalog
import com.typewritermc.types.TypeDefinition
import com.typewritermc.types.TypeExpression
import com.typewritermc.types.TypeId
import com.typewritermc.types.TypePrototypeRegistry
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.assertions.throwables.shouldThrowAny
import io.kotest.matchers.collections.shouldContainExactlyInAnyOrder
import io.kotest.matchers.shouldBe

val AuthoringMutationPlannerTest by testSuite {
    test("cascade closure does not depend on delete operation order") {
        val planner = planner(RelationDeletePolicy.CASCADE)
        val graph =
            graph(
                resources = listOf("a", "b", "c"),
                relations = listOf(declared("a-b", "a", "b"), declared("b-c", "b", "c")),
            )

        val first = planner.plan(graph, deleteOperations("a", "b")) as AuthoringMutationPlanResult.Valid
        val second = planner.plan(graph, deleteOperations("b", "a")) as AuthoringMutationPlanResult.Valid

        first.plan.delta.resourceRemovals shouldContainExactlyInAnyOrder setOf(id("a"), id("b"), id("c"))
        second.plan.delta.resourceRemovals shouldContainExactlyInAnyOrder setOf(id("a"), id("b"), id("c"))
        first.plan.delta.relationRemovals shouldBe second.plan.delta.relationRemovals
    }

    test("restrict policy rejects a delete before the store receives a delta") {
        val planner = planner(RelationDeletePolicy.RESTRICT)
        val result =
            planner.plan(
                graph(
                    resources = listOf("source", "target"),
                    relations = listOf(declared("source-target", "source", "target")),
                ),
                deleteOperations("source"),
            ) as AuthoringMutationPlanResult.Invalid

        result.diagnostics.single().code shouldBe "relation-restricts-delete"
        result.diagnostics.single().resource shouldBe id("source")
    }

    test("declared relation intent becomes one normalized graph edge") {
        val planner = planner(RelationDeletePolicy.RESTRICT)

        val result =
            planner.plan(
                graph(resources = listOf("source", "target"), relations = emptyList()),
                listOf(
                    AuthoringOperation.DeclareRelation(
                        relation = relationId(),
                        source = id("source"),
                        target = id("target"),
                    ),
                ),
            ) as AuthoringMutationPlanResult.Valid

        result.plan.delta.relationUpserts.values.single().let { relation ->
            relation.source shouldBe id("source")
            relation.target shouldBe id("target")
            relation.origin shouldBe ResourceRelationOrigin.Declared(relationId())
        }
    }

    test("one cardinality rejects a second declared relation for the same owner") {
        val relation = relationId()
        val root = rootType()
        val planner =
            AuthoringMutationPlanner(
                mapper = ResourceValueMapper(testPrototypes(), emptyList()),
                resourceDefinitions = emptyList(),
                relations =
                    listOf(
                        RelationDefinition(
                            id = relation,
                            source = root,
                            target = root,
                            onSourceDelete = RelationDeletePolicy.RESTRICT,
                            onTargetDelete = RelationDeletePolicy.RESTRICT,
                            sourceEndpoint =
                                RelationEndpointDefinition(
                                    owner = root,
                                    path = DataPath(),
                                    side = RelationEndpointSide.SOURCE,
                                    cardinality = RelationCardinality.ONE,
                                ),
                        ),
                    ),
                catalog = testCatalog(),
            )

        val result =
            planner.plan(
                graph(resources = listOf("source", "first", "second"), relations = emptyList()),
                listOf(
                    AuthoringOperation.DeclareRelation(relation, id("source"), id("first")),
                    AuthoringOperation.DeclareRelation(relation, id("source"), id("second")),
                ),
            ) as AuthoringMutationPlanResult.Invalid

        result.diagnostics.single().code shouldBe "relation-endpoint-cardinality-exceeded"
    }

    test("many cardinality accepts multiple declared relations for the same owner") {
        val relation = relationId()
        val root = rootType()
        val planner =
            AuthoringMutationPlanner(
                mapper = ResourceValueMapper(testPrototypes(), emptyList()),
                resourceDefinitions = emptyList(),
                relations =
                    listOf(
                        RelationDefinition(
                            id = relation,
                            source = root,
                            target = root,
                            onSourceDelete = RelationDeletePolicy.RESTRICT,
                            onTargetDelete = RelationDeletePolicy.RESTRICT,
                            sourceEndpoint =
                                RelationEndpointDefinition(
                                    owner = root,
                                    path = DataPath(),
                                    side = RelationEndpointSide.SOURCE,
                                    cardinality = RelationCardinality.MANY,
                                ),
                        ),
                    ),
                catalog = testCatalog(),
            )

        val result =
            planner.plan(
                graph(
                    resources = listOf("source", "first", "second"),
                    relations = listOf(declared("source-first", "source", "first")),
                ),
                listOf(
                    AuthoringOperation.DeclareRelation(relation, id("source"), id("second")),
                ),
            ) as AuthoringMutationPlanResult.Valid

        result.plan.delta.relationUpserts.size shouldBe 1
    }

    test("contributed graph rule rejects the proposed graph") {
        val rule =
            object : AuthoringGraphRule {
                override val id = "test.reject"
                override val graphRequirement =
                    com.typewritermc.realm.compiler
                        .GraphReadRequirement()

                override fun validate(context: AuthoringGraphValidationContext): List<AuthoringDiagnostic> =
                    listOf(AuthoringDiagnostic("contributed-rule-rejected"))
            }
        val planner =
            AuthoringMutationPlanner(
                mapper = ResourceValueMapper(testPrototypes(), emptyList()),
                resourceDefinitions = emptyList(),
                relations = emptyList(),
                catalog = testCatalog(),
                rules = listOf(rule),
            )

        val result =
            planner.plan(
                graph(resources = listOf("resource"), relations = emptyList()),
                listOf(AuthoringOperation.DeleteResource(id("resource"), emptyContent())),
            ) as AuthoringMutationPlanResult.Invalid

        result.diagnostics.single().code shouldBe "contributed-rule-rejected"
    }

    test("stale delete base is rejected") {
        val result =
            planner(RelationDeletePolicy.RESTRICT).plan(
                graph(resources = listOf("resource"), relations = emptyList()),
                listOf(
                    AuthoringOperation.DeleteResource(
                        id("resource"),
                        com.typewritermc.types.TypedValueEnvelope(
                            TypeExpression.Named(rootType()),
                            com.typewritermc.types.DataValue.Record(
                                mapOf(
                                    "changed" to
                                        com.typewritermc.types.DataValue
                                            .Boolean(true),
                                ),
                            ),
                        ),
                    ),
                ),
            ) as AuthoringMutationPlanResult.Invalid

        result.diagnostics.single().code shouldBe "resource-changed"
    }

    test("transaction rollback removes a partially applied graph delta") {
        Surreal().use { database ->
            database.connect("memory")
            database.useNs("test").useDb("test")
            database.query("DEFINE TABLE resource SCHEMALESS;")
            val value =
                DecomposedResourceValue(
                    resource =
                        StoredTypedResource(
                            id = id("created"),
                            definition = ResourceDefinitionId("test.resource"),
                            root = rootType(),
                            valueWithSlots =
                                com.typewritermc.types.DataValue
                                    .Record(emptyMap()),
                        ),
                    relations = emptyList(),
                )
            shouldThrowAny {
                database.inTransaction { transaction ->
                    SurrealResourceGraphStore().apply(
                        transaction,
                        AuthoringGraphDelta(
                            resourceUpserts = mapOf(value.resource.id to value),
                            resourceCreates = setOf(value.resource.id),
                            resourceRemovals = emptySet(),
                            relationUpserts = emptyMap(),
                            relationRemovals = emptySet(),
                        ),
                    )
                    error("force transaction rollback")
                }
            }
            database
                .query("SELECT * FROM resource")
                .take(0)
                .getArray()
                .len() shouldBe 0
        }
    }
}

private fun planner(policy: RelationDeletePolicy): AuthoringMutationPlanner {
    val root = rootType()
    return AuthoringMutationPlanner(
        mapper = ResourceValueMapper(testPrototypes(), emptyList()),
        resourceDefinitions = emptyList(),
        relations =
            listOf(
                RelationDefinition(
                    id = relationId(),
                    source = root,
                    target = root,
                    onSourceDelete = policy,
                    onTargetDelete = policy,
                ),
            ),
        catalog = testCatalog(),
    )
}

private fun graph(
    resources: List<String>,
    relations: List<StoredResourceRelation>,
): AuthoringWorkingGraph {
    val root = rootType()
    return AuthoringWorkingGraph(
        resources =
            resources.associate { value ->
                id(value) to
                    StoredTypedResource(
                        id = id(value),
                        definition = ResourceDefinitionId("test.resource"),
                        root = root,
                        valueWithSlots =
                            com.typewritermc.types.DataValue
                                .Record(emptyMap()),
                    )
            },
        relations = relations.associateBy(StoredResourceRelation::id),
    )
}

private fun deleteOperations(vararg ids: String): List<AuthoringOperation> =
    ids.map { AuthoringOperation.DeleteResource(id(it), emptyContent()) }

private fun emptyContent() =
    com.typewritermc.types.TypedValueEnvelope(
        TypeExpression.Named(rootType()),
        com.typewritermc.types.DataValue
            .Record(emptyMap()),
    )

private fun declared(
    edgeId: String,
    source: String,
    target: String,
) = StoredResourceRelation(edgeId, id(source), id(target), ResourceRelationOrigin.Declared(relationId()))

private fun id(value: String) = ResourceId(value)

private fun relationId() = RelationId("11111111111111111111111111111111")

private fun rootType() =
    ResolvedTypeRef(
        TypeId.Declared(DeclaredTypeId.parse("22222222222222222222222222222222")),
        1,
    )

private fun testCatalog() =
    TypeCatalog(
        listOf(
            TypeDefinition(
                id = rootType(),
                kind = NominalTypeKind.CONCRETE,
                representation = TypeExpression.Record(emptyList()),
            ),
        ),
    )

private fun testPrototypes() = TypePrototypeRegistry(emptyList(), testCatalog().definitions)
