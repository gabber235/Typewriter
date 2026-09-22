package com.typewritermc.authoring

import com.typewritermc.types.ResourceId
import com.typewritermc.types.TypeCatalog
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.matchers.collections.shouldContainExactlyInAnyOrder
import io.kotest.matchers.shouldBe

/** Acceptance proof for the policy shape an external extension must be able to contribute. */
val QuestBoardAuthoringPolicyFixtureTest by testSuite {
    test("QuestBoard contributes every generic authoring boundary") {
        val catalog = AuthoringPolicyCatalog.assemble(listOf(QuestBoardAuthoringPolicyProvider))

        catalog.definitions.keys shouldContainExactlyInAnyOrder
            setOf(
                QuestBoardAuthoringPolicyProvider.boardDefinition,
                QuestBoardAuthoringPolicyProvider.taskDefinition,
            )
        catalog.validations.keys shouldBe setOf(AuthoringValidationRuleId("fixture.quest_board.required_name"))
        catalog.search.keys shouldBe
            setOf(
                QuestBoardAuthoringPolicyProvider.boardDefinition,
                QuestBoardAuthoringPolicyProvider.taskDefinition,
            )
        catalog.presentations.keys shouldBe catalog.search.keys
        catalog.searchSelectors.single().id shouldBe QuestBoardAuthoringPolicyProvider.searchFacet.value
        catalog.searchFacets.single().selectorId shouldBe QuestBoardAuthoringPolicyProvider.searchFacet.value
        catalog.creationSlots.keys shouldContainExactlyInAnyOrder
            setOf(
                AuthoringCreationSlotId("fixture.quest_board.standalone"),
                AuthoringCreationSlotId("fixture.quest_task.board"),
            )
        catalog.compilation.keys shouldBe setOf(QuestBoardAuthoringPolicyProvider.compilationId)
    }

    test("QuestBoard policies operate on a bounded graph without domain branches") {
        val catalog = AuthoringPolicyCatalog.assemble(listOf(QuestBoardAuthoringPolicyProvider))
        val board = questBoardResource("board.main")
        val task =
            questBoardResource(
                id = "task.first",
                definition = QuestBoardAuthoringPolicyProvider.taskDefinition,
                root = QuestBoardAuthoringPolicyProvider.taskRoot,
                name = "Collect five apples",
            )
        val relation =
            AuthoringGraphRelation(
                id = "board.main.tasks.task.first",
                source = board.id,
                target = task.id,
                origin = AuthoringRelationOrigin.Declared(QuestBoardAuthoringPolicyProvider.boardTasksRelation),
            )
        val graph =
            AuthoringWorkingGraph(
                resources = mapOf(board.id to board, task.id to task),
                relations = mapOf(relation.id to relation),
            )
        val change =
            AuthoringChangeSummary(
                changedResources = setOf(board.id, task.id),
                changedEdges = setOf(relation.id),
                deletedResources = emptySet(),
            )

        val validation = catalog.validations.getValue(AuthoringValidationRuleId("fixture.quest_board.required_name"))
        validation.validate(
            AuthoringValidationContext(
                catalog = TypeCatalog(emptyList()),
                before = graph,
                proposed = graph,
                change = change,
            ),
        ) shouldBe emptyList()

        val boardSearch = catalog.search.getValue(QuestBoardAuthoringPolicyProvider.boardDefinition)
        boardSearch.project(board, graph).ownerPath shouldBe emptyList()
        boardSearch.project(board, graph).selectors shouldBe
            mapOf(QuestBoardAuthoringPolicyProvider.searchFacet to setOf("fixture.quest_board"))

        val taskPresentation =
            catalog.presentations
                .getValue(QuestBoardAuthoringPolicyProvider.taskDefinition)
                .project(task, graph)
        taskPresentation.resource shouldBe task.id
        taskPresentation.definition shouldBe task.definition
        taskPresentation.content shouldBe task.content
        taskPresentation.identity shouldBe ResourceIdentity(task.id, board.id)
        taskPresentation.ownerPath shouldBe listOf(board.id)
        taskPresentation.descriptor.name shouldBe "Quest task"

        catalog.presentations
            .getValue(QuestBoardAuthoringPolicyProvider.taskDefinition)
            .affectedResources(
                change = change.copy(changedResources = emptySet(), changedEdges = setOf(relation.id)),
                before = graph,
                proposed = graph,
            ) shouldBe setOf(task.id)

        val compilation = catalog.compilation.getValue(QuestBoardAuthoringPolicyProvider.compilationId)
        compilation.affectedRoots(change, graph, graph) shouldBe setOf(board.id)
        compilation.affectedRoots(
            change = change.copy(changedResources = setOf(task.id), changedEdges = emptySet()),
            before = graph,
            proposed = graph,
        ) shouldBe setOf(board.id)
        val result = compilation.compile(board.id, graph)
        result.root shouldBe AuthoringCompilationRoot(QuestBoardAuthoringPolicyProvider.compilationId, board.id)
        (result as AuthoringCompilationResult.Success).artifact.payload.decodeToString() shouldBe board.id.value

        catalog.creationSlots.values
            .single { it.creates == QuestBoardAuthoringPolicyProvider.taskDefinition }
            .context shouldBe
            AuthoringCreationContext.DeclaredRelation(
                hosts =
                    AuthoringCreationHostFilter(
                        definitions = setOf(QuestBoardAuthoringPolicyProvider.boardDefinition),
                    ),
                cardinality = AuthoringCreationHostCardinality.EXACTLY_ONE,
                relation = QuestBoardAuthoringPolicyProvider.boardTasksRelation,
                direction = AuthoringCreationRelationDirection.OUTGOING,
            )
    }

    test("QuestBoard validation reports resource scoped diagnostics") {
        val catalog = AuthoringPolicyCatalog.assemble(listOf(QuestBoardAuthoringPolicyProvider))
        val invalid = questBoardResource("board.invalid", name = "")
        val graph = AuthoringWorkingGraph(mapOf(invalid.id to invalid), emptyMap())
        val diagnostics =
            catalog.validations.values.single().validate(
                AuthoringValidationContext(
                    catalog = TypeCatalog(emptyList()),
                    before = graph,
                    proposed = graph,
                    change = AuthoringChangeSummary(setOf(invalid.id), emptySet(), emptySet()),
                ),
            )

        diagnostics.single().resources shouldBe setOf(ResourceId("board.invalid"))
        diagnostics.single().code shouldBe "quest.name.required"
    }
}
