package com.typewritermc.pages

import com.typewritermc.authoring.GraphPlacement
import com.typewritermc.elements.ElementTypeId
import com.typewritermc.elements.ReferenceSlotId
import com.typewritermc.library.BookId
import com.typewritermc.library.ChapterPath
import com.typewritermc.library.Page
import com.typewritermc.library.PageDocument
import com.typewritermc.library.PageDocumentElement
import com.typewritermc.library.PageId
import com.typewritermc.library.PageKindId
import com.typewritermc.library.PageKindRef
import com.typewritermc.library.PageReference
import com.typewritermc.library.ref
import com.typewritermc.types.DataValue
import com.typewritermc.types.DeclaredTypeId
import com.typewritermc.types.Resource
import com.typewritermc.types.ResourceId
import com.typewritermc.types.ToOne
import com.typewritermc.types.TypeExpression
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.matchers.collections.shouldContainExactly
import kotlinx.coroutines.test.runTest

val PageAuthoringRulesTest by testSuite {
    test("no self references reports the source element") {
        runTest {
            val document = document("first" to "first")

            CommonPageAuthoringRules.noSelfReferences
                .validate(document.context())
                .map(PageAuthoringRuleViolation::code)
                .shouldContainExactly("page-rule-self-reference")
        }
    }

    test("acyclic references reject a cycle and accept a chain") {
        runTest {
            val cyclic = document("first" to "second", "second" to "first")
            val chain = document("first" to "second")

            CommonPageAuthoringRules.acyclicElementReferences
                .validate(cyclic.context())
                .map(PageAuthoringRuleViolation::code)
                .shouldContainExactly("page-rule-reference-cycle")
            CommonPageAuthoringRules.acyclicElementReferences
                .validate(chain.context())
                .shouldContainExactly()
        }
    }
}

private fun document(vararg edges: Pair<String, String>): PageDocument {
    val pageId = PageId("page")
    val elementIds = edges.flatMap { listOf(it.first, it.second) }.distinct().map(::ResourceId)
    val elementType = ElementTypeId(DeclaredTypeId.parse("40000000000000000000000000000001"))
    return PageDocument(
        page =
            Resource(
                pageId,
                Page(
                    book = ToOne(BookId("book").ref()),
                    name = "page",
                    kind = PageKindRef(PageKindId(DeclaredTypeId.parse("50000000000000000000000000000001")), 1),
                    chapter = ChapterPath.parse(""),
                    priority = 0,
                ),
            ),
        elements =
            elementIds.map { id ->
                PageDocumentElement(id, elementType, 1, DataValue.Unit, GraphPlacement(0, 0, 1, 1))
            },
        references =
            edges.mapIndexed { index, (source, target) ->
                PageReference(
                    ResourceId(source),
                    ReferenceSlotId("target:$index"),
                    ResourceId(target),
                    TypeExpression.Any,
                )
            },
        incomingReferences = emptyList(),
        crossPageTargets = emptyList(),
        crossPageSources = emptyList(),
        diagnostics = emptyList(),
    )
}

private fun PageDocument.context() =
    PageAuthoringRuleContext(
        before = null,
        after = this,
        documentsBefore = emptyMap(),
        documentsAfter = mapOf(page.id to this),
    )
