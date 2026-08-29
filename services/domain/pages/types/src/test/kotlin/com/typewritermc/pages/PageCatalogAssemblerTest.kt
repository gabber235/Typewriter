package com.typewritermc.pages

import com.typewritermc.elements.Element
import com.typewritermc.library.PageKind
import com.typewritermc.library.PageKindId
import com.typewritermc.library.PageKindRef
import com.typewritermc.types.ResolvedTypeRef
import com.typewritermc.types.TypeId
import com.typewritermc.types.TypePrototypeRegistry
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.matchers.shouldBe
import kotlin.reflect.KClass

private interface GraphNode : Element

private object FirstKind : PageKind

private object SecondKind : PageKind

val PageCatalogAssemblerTest by testSuite {
    test("resolves qualified roles and derives a stable display name") {
        val catalog =
            PageCatalogAssembler.assemble(
                providers = listOf(provider("questFlowPage", FirstKind::class, kind("00000000000000000000000000000001"))),
                prototypes = TypePrototypeRegistry(emptyList()),
            )

        catalog.definitions.single().name shouldBe "Quest Flow"
        val editor = catalog.definitions.single().editor as ResolvedPageEditorDefinition.Graph
        editor.nodes shouldBe listOf(roleReference(GraphNode::class))
        catalog.diagnostics shouldBe emptyList()
    }

    test("isolates every definition with a duplicate stable identity") {
        val duplicate = kind("00000000000000000000000000000002")
        val catalog =
            PageCatalogAssembler.assemble(
                providers =
                    listOf(
                        provider("firstPage", FirstKind::class, duplicate),
                        provider("secondPage", SecondKind::class, duplicate.copy(revision = 2)),
                    ),
                prototypes = TypePrototypeRegistry(emptyList()),
            )

        catalog.definitions shouldBe emptyList()
        catalog.diagnostics.map(PageDiagnostic::code) shouldBe listOf("duplicate_id", "duplicate_id")
    }
}

private fun provider(
    declarationName: String,
    marker: KClass<out PageKind>,
    kind: PageKindRef,
): PageProvider =
    object : PageProvider {
        override val kind = kind
        override val namespace = "test"
        override val sourcePart = "common"
        override val declarationName = declarationName
        override val marker = marker

        override fun specification() =
            page(
                editor = PageEditorDefinition.Graph(GraphDirection.LEFT_TO_RIGHT, listOf(GraphNode::class)),
                icon = "material-symbols:account-tree",
                color = "#123456",
            )
    }

private fun kind(value: String) =
    PageKindRef(
        PageKindId(
            com.typewritermc.types.DeclaredTypeId
                .parse(value),
        ),
        1,
    )

private fun roleReference(type: KClass<*>): ResolvedTypeRef {
    val name = requireNotNull(type.qualifiedName)
    val packageName = name.substringBeforeLast('.', "")
    return ResolvedTypeRef(TypeId.Qualified(packageName, name.removePrefix("$packageName.")), 1)
}
