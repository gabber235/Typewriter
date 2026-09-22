package com.typewritermc.authoring

import com.typewritermc.types.Color
import com.typewritermc.types.DataValue
import com.typewritermc.types.Icon
import com.typewritermc.types.RelationId
import com.typewritermc.types.ResolvedTypeRef
import com.typewritermc.types.ResourceId
import com.typewritermc.types.TypeCatalog
import com.typewritermc.types.TypeExpression
import com.typewritermc.types.TypeId
import com.typewritermc.types.TypedValueEnvelope

/**
 * Models an extension authored outside Realm. The fixture deliberately contributes every policy surface so the
 * acceptance test cannot pass by registering only a definition or by using a domain specific Realm branch.
 */
internal object QuestBoardAuthoringPolicyProvider : AuthoringPolicyProvider {
    val boardDefinition = ResourceDefinitionId("fixture.quest_board")
    val taskDefinition = ResourceDefinitionId("fixture.quest_task")
    val boardRoot = ResolvedTypeRef(TypeId.Qualified("fixture.quest", "QuestBoard"), 1)
    val taskRoot = ResolvedTypeRef(TypeId.Qualified("fixture.quest", "QuestTask"), 1)
    val boardConcreteRoot = ResolvedTypeRef(TypeId.Qualified("fixture.quest", "DailyQuestBoard"), 1)
    val taskConcreteRoot = ResolvedTypeRef(TypeId.Qualified("fixture.quest", "CollectQuestTask"), 1)
    val boardTasksRelation = RelationId("11111111111111111111111111111111")
    val searchFacet = SearchFacetId("quest")
    val compilationId = AuthoringCompilationProjectionId("fixture.quest_board")

    override fun contribute(builder: AuthoringPolicyCatalog.Builder) {
        builder.definition(AuthoringResourceDefinition(boardDefinition, TypeExpression.Named(boardRoot)))
        builder.definition(AuthoringResourceDefinition(taskDefinition, TypeExpression.Named(taskRoot)))
        builder.validation(QuestBoardValidation)
        builder.search(QuestBoardSearch)
        builder.search(QuestTaskSearch)
        builder.searchSelector(
            AuthoringSearchSelector(
                id = searchFacet.value,
                key = "quest:",
                multiplicity = AuthoringSearchSelectorMultiplicity.SINGLE,
            ),
        )
        builder.searchFacet(AuthoringSearchFacet(searchFacet.value, "Quest", searchFacet.value))
        builder.presentation(QuestBoardPresentation)
        builder.presentation(QuestTaskPresentation)
        builder.creationSlot(
            AuthoringCreationSlotDefinition(
                id = AuthoringCreationSlotId("fixture.quest_board.standalone"),
                label = "Quest board",
                creates = boardDefinition,
                context = AuthoringCreationContext.Standalone,
                concreteRoots = listOf(boardConcreteRoot),
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
                        relation = boardTasksRelation,
                        direction = AuthoringCreationRelationDirection.OUTGOING,
                    ),
                concreteRoots = listOf(taskConcreteRoot),
            ),
        )
        builder.compilation(QuestBoardCompilation)
    }

    private object QuestBoardValidation : AuthoringValidationRule {
        override val id = AuthoringValidationRuleId("fixture.quest_board.required_name")
        override val graphRequirement =
            GraphReadRequirement(
                definitions = setOf(boardDefinition, taskDefinition),
                declaredRelations = setOf(boardTasksRelation),
                outgoingReferences = true,
                maximumDepth = 2,
            )

        override fun validate(context: AuthoringValidationContext): List<AuthoringDiagnostic> =
            context.proposed.resources.values
                .filter { it.definition == boardDefinition || it.definition == taskDefinition }
                .filter { it.textField("name").isNullOrBlank() }
                .map { resource ->
                    AuthoringDiagnostic(
                        code = "quest.name.required",
                        message = "Quest resources must have a name.",
                        resources = setOf(resource.id),
                    )
                }
    }

    private object QuestBoardSearch : AuthoringSearchProjection {
        override val resourceDefinition = boardDefinition
        override val graphRequirement =
            GraphReadRequirement(definitions = setOf(boardDefinition, taskDefinition), maximumDepth = 1)

        override fun project(
            resource: AuthoringGraphResource,
            graph: AuthoringWorkingGraph,
        ): AuthoringSearchDocument = resource.searchDocument(graph)
    }

    private object QuestTaskSearch : AuthoringSearchProjection {
        override val resourceDefinition = taskDefinition
        override val graphRequirement =
            GraphReadRequirement(definitions = setOf(boardDefinition, taskDefinition), maximumDepth = 1)

        override fun project(
            resource: AuthoringGraphResource,
            graph: AuthoringWorkingGraph,
        ): AuthoringSearchDocument = resource.searchDocument(graph)
    }

    private object QuestBoardPresentation : AuthoringPresentationProjection {
        override val resourceDefinition = boardDefinition
        override val graphRequirement = GraphReadRequirement(definitions = setOf(boardDefinition), maximumDepth = 1)

        override fun project(
            resource: AuthoringGraphResource,
            graph: AuthoringWorkingGraph,
        ) = resource.presentationSubject(boardDefinition, boardConcreteRoot, "Quest board", graph)
    }

    private object QuestTaskPresentation : AuthoringPresentationProjection {
        override val resourceDefinition = taskDefinition
        override val graphRequirement = GraphReadRequirement(definitions = setOf(taskDefinition), maximumDepth = 1)

        override fun project(
            resource: AuthoringGraphResource,
            graph: AuthoringWorkingGraph,
        ) = resource.presentationSubject(taskDefinition, taskConcreteRoot, "Quest task", graph)
    }

    private object QuestBoardCompilation : AuthoringCompilationProjection {
        override val id = compilationId
        override val root = TypeExpression.Named(boardRoot)
        override val graphRequirement =
            GraphReadRequirement(definitions = setOf(boardDefinition, taskDefinition), maximumDepth = 2)

        override fun affectedRoots(
            change: AuthoringChangeSummary,
            before: AuthoringWorkingGraph,
            proposed: AuthoringWorkingGraph,
        ): Set<ResourceId> =
            (
                change.changedResources + change.deletedResources +
                    (before.relations.values + proposed.relations.values)
                        .filter { relation ->
                            relation.id in change.changedEdges ||
                                relation.target in change.changedResources ||
                                relation.target in change.deletedResources
                        }.map(AuthoringGraphRelation::source)
            ).filter { id ->
                before.resources[id]?.definition == boardDefinition || proposed.resources[id]?.definition == boardDefinition
            }.toSet()

        override suspend fun compile(
            root: ResourceId,
            graph: AuthoringWorkingGraph,
        ): AuthoringCompilationResult =
            AuthoringCompilationResult.Success(
                AuthoringCompiledArtifact(
                    root = AuthoringCompilationRoot(id, root),
                    formatRevision = 1,
                    mediaType = "application/vnd.typewriter.quest-board",
                    inputFingerprint = digest('a'),
                    semanticDigest = digest('b'),
                    payload = root.value.toByteArray(),
                ),
            )
    }

    private fun AuthoringGraphResource.searchDocument(graph: AuthoringWorkingGraph): AuthoringSearchDocument =
        AuthoringSearchDocument(
            resource = id,
            definition = definition,
            text = textField("name") ?: id.value,
            selectors = mapOf(searchFacet to setOf(definition.value)),
            ownerPath = graph.ownerPathOf(id),
        )

    private fun AuthoringGraphResource.presentationSubject(
        definition: ResourceDefinitionId,
        concreteRoot: ResolvedTypeRef,
        name: String,
        graph: AuthoringWorkingGraph,
    ) = AuthoringPresentationSubject(
        resource = id,
        definition = definition,
        content = content,
        descriptor =
            ResourceTypeDescriptor(
                type = concreteRoot,
                name = name,
                description = "Fixture authoring resource",
                icon = Icon.Iconify("material-symbols:task-alt"),
                color = Color.parseRgb("#3366CC"),
            ),
        identity = ResourceIdentity(id = id, owner = graph.ownerPathOf(id).firstOrNull()),
        ownerPath = graph.ownerPathOf(id),
    )

    private fun AuthoringGraphResource.textField(name: String): String? =
        (content.rootValue as? DataValue.Record)?.fields?.get(name)?.let { value ->
            (value as? DataValue.StringValue)?.value
        }

    private fun AuthoringWorkingGraph.ownerPathOf(resource: ResourceId): List<ResourceId> =
        relations.values
            .filter { it.target == resource }
            .map { it.source }
            .sortedBy(ResourceId::value)

    private fun digest(character: Char) = AuthoringContentDigest(character.toString().repeat(64))
}

internal fun questBoardResource(
    id: String,
    definition: ResourceDefinitionId = QuestBoardAuthoringPolicyProvider.boardDefinition,
    root: ResolvedTypeRef = QuestBoardAuthoringPolicyProvider.boardRoot,
    name: String = "Daily quests",
) = AuthoringGraphResource(
    id = ResourceId(id),
    definition = definition,
    content =
        TypedValueEnvelope(
            rootType = TypeExpression.Named(root),
            rootValue = DataValue.Record(mapOf("name" to DataValue.StringValue(name))),
        ),
)
