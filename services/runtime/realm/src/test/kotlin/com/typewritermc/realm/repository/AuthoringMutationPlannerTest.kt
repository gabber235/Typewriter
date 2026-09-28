package com.typewritermc.realm.repository

import com.surrealdb.Surreal
import com.typewritermc.authoring.AuthoringResourceDefinition
import com.typewritermc.realm.ResourceDefinitionId
import com.typewritermc.realm.repository.utils.inTransaction
import com.typewritermc.types.DataPath
import com.typewritermc.types.DataValue
import com.typewritermc.types.DeclaredTypeId
import com.typewritermc.types.NominalTypeKind
import com.typewritermc.types.Ref
import com.typewritermc.types.Referenceable
import com.typewritermc.types.RelationCardinality
import com.typewritermc.types.RelationDefinition
import com.typewritermc.types.RelationDeletePolicy
import com.typewritermc.types.RelationEndpointDefinition
import com.typewritermc.types.RelationEndpointSide
import com.typewritermc.types.RelationId
import com.typewritermc.types.ResolvedTypeRef
import com.typewritermc.types.ResourceId
import com.typewritermc.types.SerializationConcreteTypePrototype
import com.typewritermc.types.StandardTypes
import com.typewritermc.types.TypeCatalog
import com.typewritermc.types.TypeDefinition
import com.typewritermc.types.TypeExpression
import com.typewritermc.types.TypeField
import com.typewritermc.types.TypeId
import com.typewritermc.types.TypePrototypeRegistry
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.assertions.throwables.shouldThrowAny
import io.kotest.matchers.collections.shouldContainExactlyInAnyOrder
import io.kotest.matchers.shouldBe
import kotlinx.serialization.Serializable

val AuthoringMutationPlannerTest by testSuite {
    test("standalone creation uses its definition and concrete root") {
        val definition = ResourceDefinitionId("test.resource")
        val planner = AuthoringMutationPlanner(
            mapper = ResourceValueMapper(testPrototypes(), emptyList()),
            resourceDefinitions = listOf(AuthoringResourceDefinition(definition, TypeExpression.Named(rootType()))),
            relations = emptyList(),
            catalog = testCatalog(),
        )

        val result = planner.plan(
            graph(resources = emptyList(), relations = emptyList()),
            listOf(AuthoringOperation.CreateResource(id("created"), definition, contentWithHost("created"))),
        ) as AuthoringMutationPlanResult.Valid

        result.plan.delta.resourceCreates shouldBe setOf(id("created"))
    }

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

        result.plan.delta.relationUpserts.values
            .single { relation -> relation.origin is ResourceRelationOrigin.Declared }
            .let { relation ->
                relation.source shouldBe id("source")
                relation.target shouldBe id("target")
                relation.origin shouldBe ResourceRelationOrigin.Declared(relationId())
            }
    }

    test("creation attachment declares its selected relation") {
        val definition = ResourceDefinitionId("test.resource")
        val root = rootType()
        val relation = RelationDefinition(
            id = relationId(),
            source = root,
            target = root,
            onSourceDelete = RelationDeletePolicy.RESTRICT,
            onTargetDelete = RelationDeletePolicy.RESTRICT,
            sourceEndpoint = RelationEndpointDefinition(
                owner = root,
                path = DataPath.field("children"),
                side = RelationEndpointSide.SOURCE,
                cardinality = RelationCardinality.MANY,
            ),
        )
        val planner = AuthoringMutationPlanner(
            mapper = ResourceValueMapper(testPrototypes(), listOf(relation)),
            resourceDefinitions = listOf(AuthoringResourceDefinition(definition, TypeExpression.Named(root))),
            relations = listOf(relation),
            catalog = testCatalog(),
        )
        val result = planner.plan(
            graph(resources = listOf("host"), relations = emptyList()),
            listOf(AuthoringOperation.CreateResource(
                id = id("created"),
                definition = definition,
                content = contentWithHost("host"),
                attachment = CreationAttachment(id("host"), relationId(), RelationEndpointSide.SOURCE),
            )),
        ) as AuthoringMutationPlanResult.Valid

        result.plan.delta.relationUpserts.values.single { it.origin is ResourceRelationOrigin.Declared }.let { edge ->
            edge.source shouldBe id("host")
            edge.target shouldBe id("created")
        }
    }

    test("ordinary reference fields are projected during standalone creation") {
        val definition = ResourceDefinitionId("test.resource")
        val planner = AuthoringMutationPlanner(
            mapper = ResourceValueMapper(testPrototypes(), emptyList()),
            resourceDefinitions = listOf(AuthoringResourceDefinition(definition, TypeExpression.Named(rootType()))),
            relations = emptyList(),
            catalog = testCatalog(),
        )
        val result = planner.plan(
            graph(resources = listOf("host"), relations = emptyList()),
            listOf(AuthoringOperation.CreateResource(
                id = id("created"),
                definition = definition,
                content = com.typewritermc.types.TypedValueEnvelope(
                    TypeExpression.Named(rootType()),
                    DataValue.Record(mapOf("host" to DataValue.Reference(id("host")), "children" to DataValue.ListValue(emptyList()))),
                ),
            )),
        ) as AuthoringMutationPlanResult.Valid

        result.plan.delta.relationUpserts.values.single().let { edge ->
            edge.source shouldBe id("created")
            edge.target shouldBe id("host")
            (edge.origin as ResourceRelationOrigin.Reference).sourcePath shouldBe DataPath.field("host")
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
                                    path = DataPath.field("host"),
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
                                    path = DataPath.field("children"),
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
                    relations = listOf(
                        declared("source-first", "source", "first").copy(
                            origin = ResourceRelationOrigin.Declared(relation, sourceIndex = 0),
                        ),
                    ),
                ),
                listOf(
                    AuthoringOperation.DeclareRelation(relation, id("source"), id("second")),
                ),
            ) as AuthoringMutationPlanResult.Valid

        result.plan.delta.relationUpserts.size shouldBe 1
    }

    test("a plain relation permits shared targets and cycles") {
        val relation = RelationDefinition(
            id = relationId(),
            source = rootType(),
            target = rootType(),
            onSourceDelete = RelationDeletePolicy.RESTRICT,
            onTargetDelete = RelationDeletePolicy.RESTRICT,
            sourceEndpoint = RelationEndpointDefinition(
                owner = rootType(),
                path = DataPath.field("children"),
                side = RelationEndpointSide.SOURCE,
                cardinality = RelationCardinality.MANY,
            ),
        )
        val planner = AuthoringMutationPlanner(
            mapper = ResourceValueMapper(testPrototypes(), listOf(relation)),
            resourceDefinitions = emptyList(),
            relations = listOf(relation),
            catalog = testCatalog(),
        )
        val result = planner.plan(
            graph(resources = listOf("first", "second", "shared"), relations = emptyList()),
            listOf(
                AuthoringOperation.DeclareRelation(relationId(), id("first"), id("shared")),
                AuthoringOperation.DeclareRelation(relationId(), id("second"), id("shared")),
                AuthoringOperation.DeclareRelation(relationId(), id("first"), id("second")),
                AuthoringOperation.DeclareRelation(relationId(), id("second"), id("first")),
            ),
        ) as AuthoringMutationPlanResult.Valid

        result.plan.proposed.relations.values.count { it.target == id("shared") } shouldBe 2
        result.plan.proposed.relations.size shouldBe 4
    }

    test("declared relation insertion preserves authored order") {
        val relation = relationId()
        val root = rootType()
        val definition = RelationDefinition(
            id = relation,
            source = root,
            target = root,
            onSourceDelete = RelationDeletePolicy.RESTRICT,
            onTargetDelete = RelationDeletePolicy.RESTRICT,
            sourceEndpoint = RelationEndpointDefinition(
                owner = root,
                path = DataPath.field("children"),
                side = RelationEndpointSide.SOURCE,
                cardinality = RelationCardinality.MANY,
            ),
        )
        val mapper = ResourceValueMapper(testPrototypes(), listOf(definition))
        val planner = AuthoringMutationPlanner(
            mapper = mapper,
            resourceDefinitions = emptyList(),
                relations = listOf(definition),
            catalog = testCatalog(),
        )
        val before = graph(
            resources = listOf("source", "first", "middle", "last"),
            relations = listOf(
                mapper.declaredRelation(relation, id("source"), id("first")).copy(
                    origin = ResourceRelationOrigin.Declared(relation, sourceIndex = 0),
                ),
                mapper.declaredRelation(relation, id("source"), id("last")).copy(
                    origin = ResourceRelationOrigin.Declared(relation, sourceIndex = 1),
                ),
            ),
        )

        val result = planner.plan(
            before,
            listOf(AuthoringOperation.DeclareRelation(
                relation = relation,
                source = id("source"),
                target = id("middle"),
                sourceBefore = id("last"),
            )),
        ) as AuthoringMutationPlanResult.Valid

        val ordered = result.plan.proposed.relations.values
            .sortedBy { (it.origin as ResourceRelationOrigin.Declared).sourceIndex }
            .map(StoredResourceRelation::target)
        ordered shouldBe listOf(id("first"), id("middle"), id("last"))
        result.plan.delta.relationUpdates.size shouldBe 2
    }

    test("remove relation deletes the exact declared edge") {
        val mapper = ResourceValueMapper(testPrototypes(), emptyList())
        val relation = mapper.declaredRelation(relationId(), id("source"), id("target"))
        val planner =
            AuthoringMutationPlanner(
                mapper = mapper,
                resourceDefinitions = emptyList(),
                relations =
                    listOf(
                        RelationDefinition(
                            id = relationId(),
                            source = rootType(),
                            target = rootType(),
                            onSourceDelete = RelationDeletePolicy.RESTRICT,
                            onTargetDelete = RelationDeletePolicy.RESTRICT,
                        ),
                    ),
                catalog = testCatalog(),
            )

        val result =
            planner.plan(
                graph(resources = listOf("source", "target"), relations = listOf(relation)),
                listOf(AuthoringOperation.RemoveRelation(relationId(), id("source"), id("target"))),
            ) as AuthoringMutationPlanResult.Valid

        result.plan.delta.relationRemovals shouldBe setOf(relation.id)
        result.plan.proposed.relations shouldBe emptyMap()
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

    test("each graph rule receives only its declared bounded dependencies") {
        val observed = mutableListOf<Set<ResourceId>>()
        val rule =
            object : AuthoringGraphRule {
                override val id = "test.isolated"
                override val graphRequirement =
                    com.typewritermc.realm.compiler
                        .GraphReadRequirement(maximumDepth = 0)

                override fun validate(context: AuthoringGraphValidationContext): List<AuthoringDiagnostic> {
                    observed += context.proposed.resources.keys
                    return emptyList()
                }
            }
        val planner =
            AuthoringMutationPlanner(
                mapper = ResourceValueMapper(testPrototypes(), emptyList()),
                resourceDefinitions = emptyList(),
                relations = emptyList(),
                catalog = testCatalog(),
                rules = listOf(rule),
            )

        planner.plan(
            graph(resources = listOf("changed", "unrelated"), relations = emptyList()),
            listOf(AuthoringOperation.DeleteResource(id("changed"), emptyContent())),
        ) as AuthoringMutationPlanResult.Valid

        observed.single() shouldBe emptySet()
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

private fun contentWithHost(host: String) = com.typewritermc.types.TypedValueEnvelope(
    TypeExpression.Named(rootType()),
    DataValue.Record(mapOf("host" to DataValue.Reference(id(host)), "children" to DataValue.ListValue(emptyList()))),
)

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
        StandardTypes.definitions +
            TypeDefinition(
                id = rootType(),
                kind = NominalTypeKind.CONCRETE,
                representation =
                    TypeExpression.Record(
                        listOf(
                            TypeField(
                                "host",
                                TypeExpression.Reference(rootType()),
                            ),
                            TypeField(
                                "children",
                                TypeExpression.ListType(TypeExpression.Reference(rootType())),
                            ),
                        ),
                    ),
            ),
    )

private fun testPrototypes(): TypePrototypeRegistry {
    val definition = testCatalog().definitions.single { it.id == rootType() }
    return TypePrototypeRegistry(
        listOf(
            SerializationConcreteTypePrototype(
                runtimeType = HostedResourceContent::class,
                type = rootType(),
                definition = definition,
                serializer = HostedResourceContent.serializer(),
            ),
        ),
        testCatalog().definitions,
    )
}

@Serializable
private data class HostedResourceContent(
    val host: Ref<HostedResourceContent>,
    val children: List<Ref<HostedResourceContent>> = emptyList(),
) : Referenceable
