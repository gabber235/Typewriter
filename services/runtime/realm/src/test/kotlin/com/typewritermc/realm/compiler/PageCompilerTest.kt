package com.typewritermc.realm.compiler

import com.typewritermc.authoring.GraphPlacement
import com.typewritermc.authoring.Placement
import com.typewritermc.authoring.TimelineKeyframePlacement
import com.typewritermc.elements.ElementTypeId
import com.typewritermc.engine.PageCompileResult
import com.typewritermc.library.BookId
import com.typewritermc.library.ChapterPath
import com.typewritermc.library.Page
import com.typewritermc.library.PageDocument
import com.typewritermc.library.PageDocumentDiagnostic
import com.typewritermc.library.PageDocumentElement
import com.typewritermc.library.PageId
import com.typewritermc.library.PageKindId
import com.typewritermc.library.PageKindRef
import com.typewritermc.library.ref
import com.typewritermc.types.DataValue
import com.typewritermc.types.DeclaredTypeId
import com.typewritermc.types.Resource
import com.typewritermc.types.ResourceId
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.matchers.shouldBe

val PageCompilerTest by testSuite {
    test("graph coordinate changes reuse the same page shard") {
        val compiler = PageCompiler()
        val first = compiler.compile(document(GraphPlacement(0, 0, 2, 2)), "catalog:1")
        val second = compiler.compile(document(GraphPlacement(20, 30, 5, 6)), "catalog:1")

        first as PageCompileResult.Success
        second as PageCompileResult.Success
        second.shard.inputFingerprint shouldBe first.shard.inputFingerprint
        second.shard.digest shouldBe first.shard.digest
    }

    test("timeline timing changes produce a new page shard") {
        val compiler = PageCompiler()
        val first = compiler.compile(document(TimelineKeyframePlacement(1)), "catalog:1")
        val second = compiler.compile(document(TimelineKeyframePlacement(2)), "catalog:1")

        first as PageCompileResult.Success
        second as PageCompileResult.Success
        (second.shard.inputFingerprint == first.shard.inputFingerprint) shouldBe false
        (second.shard.digest == first.shard.digest) shouldBe false
    }

    test("draft diagnostics block compilation") {
        val result =
            PageCompiler().compile(
                document(GraphPlacement(0, 0, 1, 1)).copy(
                    diagnostics = listOf(PageDocumentDiagnostic("dangling-reference", "Missing target", element = ELEMENT_ID)),
                ),
                "catalog:1",
            )

        (result is PageCompileResult.Blocked) shouldBe true
    }
}

private fun document(placement: Placement): PageDocument =
    PageDocument(
        page =
            Resource(
                PageId("page"),
                Page(
                    book = com.typewritermc.types.ToOne(BookId("book").ref()),
                    name = "page",
                    kind = PageKindRef(PageKindId(DeclaredTypeId.parse("50000000000000000000000000000001")), 1),
                    chapter = ChapterPath.Root,
                    priority = 0,
                ),
            ),
        elements =
            listOf(
                PageDocumentElement(
                    id = ELEMENT_ID,
                    elementType = ELEMENT_TYPE,
                    schemaRevision = 1,
                    value =
                        DataValue.Record(
                            mapOf(
                                "name" to DataValue.StringValue("Element"),
                                "text" to DataValue.StringValue("value"),
                            ),
                        ),
                    placement = placement,
                ),
            ),
        references = emptyList(),
        incomingReferences = emptyList(),
        crossPageTargets = emptyList(),
        crossPageSources = emptyList(),
        diagnostics = emptyList(),
    )

private val ELEMENT_ID = ResourceId("kd9pn4fa2s7m8q3v6x0z")
private val ELEMENT_TYPE = ElementTypeId(DeclaredTypeId.parse("60000000000000000000000000000002"))
