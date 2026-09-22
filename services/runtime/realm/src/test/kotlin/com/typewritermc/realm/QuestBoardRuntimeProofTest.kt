package com.typewritermc.realm

import com.surrealdb.Surreal
import com.typewritermc.authoring.AuthoringCompilationProjection
import com.typewritermc.authoring.AuthoringCompilationProjectionId
import com.typewritermc.authoring.AuthoringCompilationResult
import com.typewritermc.authoring.AuthoringCompiledArtifact
import com.typewritermc.authoring.AuthoringContentDigest
import com.typewritermc.authoring.AuthoringCreationContext
import com.typewritermc.authoring.AuthoringCreationHostCardinality
import com.typewritermc.authoring.AuthoringCreationHostFilter
import com.typewritermc.authoring.AuthoringCreationRelationDirection
import com.typewritermc.authoring.AuthoringCreationSlotDefinition
import com.typewritermc.authoring.AuthoringCreationSlotId
import com.typewritermc.authoring.AuthoringGraphRelation
import com.typewritermc.authoring.AuthoringGraphResource
import com.typewritermc.authoring.AuthoringPolicyProvider
import com.typewritermc.authoring.AuthoringPresentationProjection
import com.typewritermc.authoring.AuthoringPresentationSubject
import com.typewritermc.authoring.AuthoringSearchDocument
import com.typewritermc.authoring.AuthoringSearchProjection
import com.typewritermc.authoring.AuthoringSearchSelector
import com.typewritermc.authoring.AuthoringSearchSelectorMultiplicity
import com.typewritermc.authoring.AuthoringValidationRule
import com.typewritermc.authoring.AuthoringValidationRuleId
import com.typewritermc.authoring.AuthoringWorkingGraph
import com.typewritermc.authoring.GraphReadRequirement
import com.typewritermc.authoring.ResourceDefinitionId
import com.typewritermc.authoring.ResourceIdentity
import com.typewritermc.authoring.ResourceTypeDescriptor
import com.typewritermc.authoring.SearchFacetId
import com.typewritermc.engine.CompilationProjectionId
import com.typewritermc.engine.CompilationRoot
import com.typewritermc.realm.repository.AuthoringBatch
import com.typewritermc.realm.repository.AuthoringBatchResult
import com.typewritermc.realm.repository.AuthoringGraphQueryResult
import com.typewritermc.realm.repository.AuthoringOperation
import com.typewritermc.realm.repository.AuthoringRepository
import com.typewritermc.realm.repository.GraphSelection
import com.typewritermc.realm.repository.RelationDirection
import com.typewritermc.realm.repository.RelationFilter
import com.typewritermc.realm.repository.RelationStep
import com.typewritermc.realm.repository.ResourceSeed
import com.typewritermc.realm.repository.ResourceValueMapper
import com.typewritermc.realm.repository.StoredResourceRelation
import com.typewritermc.realm.repository.SurrealAuthoringGraphRepository
import com.typewritermc.realm.repository.SurrealAuthoringRepository
import com.typewritermc.realm.routes.AuthoringPresentationProjector
import com.typewritermc.realm.routes.registeredAuthoringPresentationMaterializer
import com.typewritermc.realm.schema.SchemaMigrator
import com.typewritermc.realm.search.AuthoringSearchIndexer
import com.typewritermc.realm.search.IndexedSelectorFilter
import com.typewritermc.realm.search.SurrealAuthoringSearchRepository
import com.typewritermc.services.libs.telemetry.ErrorSlug
import com.typewritermc.services.libs.telemetry.mainSpan
import com.typewritermc.services.libs.telemetry.testing.TelemetryTestHarness
import com.typewritermc.types.DataValue
import com.typewritermc.types.DeclaredTypeId
import com.typewritermc.types.NominalTypeKind
import com.typewritermc.types.RelationDefinition
import com.typewritermc.types.RelationDeletePolicy
import com.typewritermc.types.RelationId
import com.typewritermc.types.ResolvedTypeRef
import com.typewritermc.types.ResourceId
import com.typewritermc.types.SerializationConcreteTypePrototype
import com.typewritermc.types.TypeCatalog
import com.typewritermc.types.TypeDefinition
import com.typewritermc.types.TypeExpression
import com.typewritermc.types.TypeField
import com.typewritermc.types.TypeId
import com.typewritermc.types.TypePrototypeRegistry
import com.typewritermc.types.TypedValueEnvelope
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.matchers.collections.shouldContainExactlyInAnyOrder
import io.kotest.matchers.shouldBe
import kotlinx.coroutines.runBlocking
import kotlinx.serialization.Serializable

val QuestBoardRuntimeProofTest by testSuite {
    test("QuestBoard crosses every generic Realm boundary") {
        QuestBoardRuntimeFixture().use { fixture ->
            val board = fixture.value("board", "Daily quests")
            val task = fixture.value("task", "Collect three crystals")

            val created =
                fixture
                    .apply(
                        AuthoringBatch(
                            id = fixture.batch("create"),
                            generation = fixture.generation,
                            operations =
                                listOf(
                                    AuthoringOperation.CreateResource(fixture.boardId, fixture.boardDefinition, board),
                                    AuthoringOperation.CreateResource(fixture.taskId, fixture.taskDefinition, task),
                                    AuthoringOperation.DeclareRelation(fixture.relation, fixture.boardId, fixture.taskId),
                                ),
                        ),
                    ).requireApplied()

            created.change.presentations.map { it.resource } shouldContainExactlyInAnyOrder
                setOf(fixture.boardId, fixture.taskId)
            created.change.compilationImpact shouldBe listOf(CompilationRoot(fixture.compilationId, fixture.boardId))
            val taskSubject =
                (
                    created.change.presentations.single { it.resource == fixture.taskId } as
                        com.typewritermc.realm.repository.AuthoringPresentationChange.Upsert
                ).subject
            taskSubject.identity.id shouldBe fixture.taskId
            taskSubject.descriptor.type shouldBe QuestBoardPolicy.taskConcrete

            val queried = fixture.query(fixture.boardId)
            queried.snapshot.resources.map { it.id } shouldContainExactlyInAnyOrder
                setOf(fixture.boardId, fixture.taskId)
            queried.snapshot.edges.map(StoredResourceRelation::source) shouldBe listOf(fixture.boardId)

            val indexed = fixture.search()
            indexed.map { it.resource } shouldBe listOf(fixture.boardId, fixture.taskId)
            indexed.single { it.resource == fixture.taskId }.ownerPath shouldBe listOf(fixture.boardId)

            val committed =
                fixture
                    .apply(
                        AuthoringBatch(
                            id = fixture.batch("commit"),
                            generation = fixture.generation,
                            operations =
                                listOf(
                                    AuthoringOperation.CommitResource(
                                        id = fixture.taskId,
                                        base = task,
                                        proposed = fixture.value("task", "Collect five crystals"),
                                        changedPaths = listOf(com.typewritermc.types.DataPath()),
                                    ),
                                ),
                        ),
                    ).requireApplied()
            committed.change.presentations
                .single { it.resource == fixture.taskId }
                .let { change ->
                    (change as com.typewritermc.realm.repository.AuthoringPresentationChange.Upsert)
                        .subject.ownerPath shouldBe listOf(fixture.boardId)
                }

            val deleted =
                fixture
                    .apply(
                        AuthoringBatch(
                            id = fixture.batch("delete"),
                            generation = fixture.generation,
                            operations = listOf(AuthoringOperation.DeleteResource(fixture.boardId, board)),
                        ),
                    ).requireApplied()
            deleted.change.resources.mapNotNull { change ->
                (change as? com.typewritermc.realm.repository.GraphResourceChange.Remove)?.id
            } shouldContainExactlyInAnyOrder setOf(fixture.boardId, fixture.taskId)
            fixture.search() shouldBe emptyList()
        }
    }
}

private class QuestBoardRuntimeFixture : AutoCloseable {
    val generation = "quest-board-runtime"
    val boardDefinition = QuestBoardPolicy.boardDefinition
    val taskDefinition = QuestBoardPolicy.taskDefinition
    val boardId = ResourceId("quest-board")
    val taskId = ResourceId("quest-task")
    val relation = QuestBoardPolicy.relation
    val compilationId = CompilationProjectionId(QuestBoardPolicy.compilationId.value)

    private val telemetry = TelemetryTestHarness.create()
    private val database = Surreal()
    private val types = QuestBoardPolicy.types
    private val prototypes = QuestBoardPolicy.prototypes
    private val policies =
        RealmAuthoringPolicyAssembler.assemble(listOf(QuestBoardPolicy), types)
    private val relationDefinitions = listOf(QuestBoardPolicy.relationDefinition)
    private val repository: AuthoringRepository
    private val graph: SurrealAuthoringGraphRepository
    private val search = SurrealAuthoringSearchRepository(database)
    private var closed = false
    private var batchSequence = 0

    init {
        database.connect("memory")
        database.useNs("quest_board_runtime").useDb("quest_board_runtime")
        runBlocking {
            telemetry.telemetry.mainSpan(
                name = "test.quest_board.schema",
                unhandledFailureSlug = ErrorSlug.of("test-quest-board-schema-failed"),
            ) {
                SchemaMigrator(database).migrate()
            }
        }
        repository =
            SurrealAuthoringRepository(
                database = database,
                prototypes = prototypes,
                catalogGeneration = { generation },
                resourceDefinitions = { policies.definitions },
                relations = { relationDefinitions },
                typeCatalog = { types },
                validationRules = { policies.validations },
                policyGraphRequirements = { policies.graphRequirements },
                compilationProjections = { policies.compilation },
                searchIndexer = { AuthoringSearchIndexer(policies.search) },
                presentationMaterializer = {
                    registeredAuthoringPresentationMaterializer(
                        prototypes = prototypes,
                        relations = { relationDefinitions },
                        projector = AuthoringPresentationProjector(prototypes, policies.presentations),
                    )
                },
            )
        graph =
            SurrealAuthoringGraphRepository(
                database = database,
                mapper = { ResourceValueMapper(prototypes, relationDefinitions) },
                catalog = { types },
                generation = { generation },
            )
    }

    fun value(
        id: String,
        name: String,
    ): TypedValueEnvelope =
        TypedValueEnvelope(
            rootType =
                TypeExpression.Named(
                    when (id) {
                        "board" -> QuestBoardPolicy.boardConcrete
                        "task" -> QuestBoardPolicy.taskConcrete
                        else -> error("Unknown QuestBoard fixture value $id")
                    },
                ),
            rootValue = DataValue.Record(mapOf("name" to DataValue.StringValue(name))),
        )

    fun batch(label: String): com.typewritermc.realm.repository.BatchId {
        batchSequence++
        return com.typewritermc.realm.repository
            .BatchId("$label-$batchSequence")
    }

    suspend fun apply(batch: AuthoringBatch): AuthoringBatchResult.Applied = repository.apply(batch).requireApplied()

    suspend fun query(root: ResourceId): AuthoringGraphQueryResult.Success =
        graph
            .query(
                generation,
                listOf(
                    GraphSelection(
                        key = "quest-board",
                        seed = ResourceSeed.Ids(listOf(root)),
                        steps =
                            listOf(
                                RelationStep(
                                    relations = RelationFilter.Declared(setOf(relation)),
                                    direction = RelationDirection.OUTGOING,
                                ),
                            ),
                    ),
                ),
            ).let { result ->
                check(result is AuthoringGraphQueryResult.Success) { result }
                result
            }

    fun search() =
        search.search(
            query = "",
            definitions = setOf(boardDefinition, taskDefinition),
            allowedResources = null,
            selectors =
                IndexedSelectorFilter.Or(
                    IndexedSelectorFilter.Match("quest", boardDefinition.value),
                    IndexedSelectorFilter.Match("quest", taskDefinition.value),
                ),
            limit = 10,
        )

    override fun close() {
        if (closed) return
        closed = true
        database.close()
        telemetry.close()
    }
}

private fun AuthoringBatchResult.requireApplied(): AuthoringBatchResult.Applied =
    this as? AuthoringBatchResult.Applied ?: error("Expected applied authoring batch, got $this")

private object QuestBoardPolicy : AuthoringPolicyProvider {
    val boardDefinition = ResourceDefinitionId("fixture.quest_board")
    val taskDefinition = ResourceDefinitionId("fixture.quest_task")
    val boardAbstract = ResolvedTypeRef(TypeId.Declared(DeclaredTypeId.parse("11111111111111111111111111111111")), 1)
    val taskAbstract = ResolvedTypeRef(TypeId.Declared(DeclaredTypeId.parse("22222222222222222222222222222222")), 1)
    val boardConcrete = ResolvedTypeRef(TypeId.Declared(DeclaredTypeId.parse("33333333333333333333333333333333")), 1)
    val taskConcrete = ResolvedTypeRef(TypeId.Declared(DeclaredTypeId.parse("44444444444444444444444444444444")), 1)
    val relation = RelationId("55555555555555555555555555555555")
    val relationDefinition =
        RelationDefinition(
            id = relation,
            source = boardAbstract,
            target = taskAbstract,
            onSourceDelete = RelationDeletePolicy.CASCADE,
            onTargetDelete = RelationDeletePolicy.RESTRICT,
        )
    val compilationId = AuthoringCompilationProjectionId("fixture.quest_board")

    private val boardDefinitionModel =
        TypeDefinition(
            id = boardAbstract,
            kind = NominalTypeKind.OPEN_ABSTRACT,
        )
    private val taskDefinitionModel =
        TypeDefinition(
            id = taskAbstract,
            kind = NominalTypeKind.OPEN_ABSTRACT,
        )
    private val boardConcreteDefinition = concreteDefinition(boardConcrete, boardAbstract)
    private val taskConcreteDefinition = concreteDefinition(taskConcrete, taskAbstract)
    val types =
        TypeCatalog(
            listOf(boardDefinitionModel, taskDefinitionModel, boardConcreteDefinition, taskConcreteDefinition),
        )
    val prototypes =
        TypePrototypeRegistry(
            listOf(
                SerializationConcreteTypePrototype(
                    runtimeType = QuestBoardValue::class,
                    type = boardConcrete,
                    definition = boardConcreteDefinition,
                    serializer = QuestBoardValue.serializer(),
                ),
                SerializationConcreteTypePrototype(
                    runtimeType = QuestTaskValue::class,
                    type = taskConcrete,
                    definition = taskConcreteDefinition,
                    serializer = QuestTaskValue.serializer(),
                ),
            ),
            definitions = types.definitions,
        )

    override fun contribute(builder: com.typewritermc.authoring.AuthoringPolicyCatalog.Builder) {
        builder.definition(com.typewritermc.authoring.AuthoringResourceDefinition(boardDefinition, TypeExpression.Named(boardAbstract)))
        builder.definition(com.typewritermc.authoring.AuthoringResourceDefinition(taskDefinition, TypeExpression.Named(taskAbstract)))
        builder.validation(QuestBoardValidation)
        builder.search(QuestBoardSearch(boardDefinition))
        builder.search(QuestBoardSearch(taskDefinition))
        builder.searchSelector(AuthoringSearchSelector("quest", "quest:", multiplicity = AuthoringSearchSelectorMultiplicity.SINGLE))
        builder.presentation(QuestBoardPresentation(boardDefinition, boardConcrete, "Quest board"))
        builder.presentation(QuestBoardPresentation(taskDefinition, taskConcrete, "Quest task"))
        builder.creationSlot(
            AuthoringCreationSlotDefinition(
                id = AuthoringCreationSlotId("fixture.quest_board.standalone"),
                label = "Quest board",
                creates = boardDefinition,
                context = AuthoringCreationContext.Standalone,
                concreteRoots = listOf(boardConcrete),
            ),
        )
        builder.creationSlot(
            AuthoringCreationSlotDefinition(
                id = AuthoringCreationSlotId("fixture.quest_task.board"),
                label = "Quest task",
                creates = taskDefinition,
                context =
                    AuthoringCreationContext.DeclaredRelation(
                        hosts = AuthoringCreationHostFilter(definitions = setOf(boardDefinition)),
                        cardinality = AuthoringCreationHostCardinality.EXACTLY_ONE,
                        relation = relation,
                        direction = AuthoringCreationRelationDirection.OUTGOING,
                    ),
                concreteRoots = listOf(taskConcrete),
            ),
        )
        builder.compilation(QuestBoardCompilation)
    }

    private fun concreteDefinition(
        root: ResolvedTypeRef,
        parent: ResolvedTypeRef,
    ) = TypeDefinition(
        id = root,
        kind = NominalTypeKind.CONCRETE,
        representation = TypeExpression.Record(listOf(TypeField("name", TypeExpression.StringType()))),
        parents = listOf(parent),
    )

    private object QuestBoardValidation : AuthoringValidationRule {
        override val id = AuthoringValidationRuleId("fixture.quest_board.name")
        override val graphRequirement =
            GraphReadRequirement(
                definitions = setOf(boardDefinition, taskDefinition),
                declaredRelations = setOf(relation),
                outgoingReferences = true,
                maximumDepth = 2,
            )

        override fun validate(context: com.typewritermc.authoring.AuthoringValidationContext) =
            emptyList<com.typewritermc.authoring.AuthoringDiagnostic>()
    }

    private class QuestBoardSearch(
        override val resourceDefinition: ResourceDefinitionId,
    ) : AuthoringSearchProjection {
        override val graphRequirement =
            GraphReadRequirement(
                definitions = setOf(boardDefinition, taskDefinition),
                declaredRelations = setOf(relation),
                maximumDepth = 1,
            )

        override fun project(
            resource: AuthoringGraphResource,
            graph: AuthoringWorkingGraph,
        ) = AuthoringSearchDocument(
            resource = resource.id,
            definition = resource.definition,
            text = resource.id.value,
            selectors = mapOf(SearchFacetId("quest") to setOf(resource.definition.value)),
            ownerPath = graph.ownerPath(resource.id),
        )
    }

    private class QuestBoardPresentation(
        override val resourceDefinition: ResourceDefinitionId,
        private val concreteRoot: ResolvedTypeRef,
        private val label: String,
    ) : AuthoringPresentationProjection {
        override val graphRequirement =
            GraphReadRequirement(
                definitions = setOf(boardDefinition, taskDefinition),
                declaredRelations = setOf(relation),
                maximumDepth = 1,
            )

        override fun project(
            resource: AuthoringGraphResource,
            graph: AuthoringWorkingGraph,
        ) = AuthoringPresentationSubject(
            resource = resource.id,
            definition = resource.definition,
            content = resource.content,
            descriptor =
                ResourceTypeDescriptor(
                    type = concreteRoot,
                    name = label,
                    description = "QuestBoard fixture resource",
                    icon =
                        com.typewritermc.types.Icon
                            .Iconify("material-symbols:task-alt"),
                    color =
                        com.typewritermc.types.Color
                            .parseRgb("#3366CC"),
                ),
            identity = ResourceIdentity(resource.id),
            ownerPath = graph.ownerPath(resource.id),
        )
    }

    private object QuestBoardCompilation : AuthoringCompilationProjection {
        override val id = compilationId
        override val root = TypeExpression.Named(boardAbstract)
        override val graphRequirement =
            GraphReadRequirement(
                definitions = setOf(boardDefinition, taskDefinition),
                declaredRelations = setOf(relation),
                maximumDepth = 2,
            )

        override fun affectedRoots(
            change: com.typewritermc.authoring.AuthoringChangeSummary,
            before: AuthoringWorkingGraph,
            proposed: AuthoringWorkingGraph,
        ): Set<ResourceId> =
            (
                change.changedResources + change.deletedResources +
                    change.changedEdges.flatMap { edge ->
                        listOfNotNull(before.relations[edge], proposed.relations[edge]).map(AuthoringGraphRelation::source)
                    }
            ).filter { id ->
                before.resources[id]?.definition == boardDefinition || proposed.resources[id]?.definition == boardDefinition
            }.toSet()

        override suspend fun compile(
            root: ResourceId,
            graph: AuthoringWorkingGraph,
        ) = AuthoringCompilationResult.Success(
            AuthoringCompiledArtifact(
                root = com.typewritermc.authoring.AuthoringCompilationRoot(id, root),
                formatRevision = 1,
                mediaType = "application/vnd.typewriter.quest-board",
                inputFingerprint = AuthoringContentDigest("a".repeat(64)),
                semanticDigest = AuthoringContentDigest("b".repeat(64)),
                payload = root.value.encodeToByteArray(),
            ),
        )
    }

    private fun AuthoringWorkingGraph.ownerPath(resource: ResourceId): List<ResourceId> =
        relations.values
            .filter { it.target == resource }
            .map(AuthoringGraphRelation::source)
            .sortedBy(ResourceId::value)
}

@Serializable
private data class QuestBoardValue(
    val name: String,
)

@Serializable
private data class QuestTaskValue(
    val name: String,
)
