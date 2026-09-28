package com.typewritermc.pages

import com.typewritermc.library.Page
import com.typewritermc.types.CatalogMetadataTypePrototype
import com.typewritermc.types.NominalTypeKind
import com.typewritermc.types.ResolvedTypeRef
import com.typewritermc.types.TypeDefinition
import com.typewritermc.types.TypeId
import com.typewritermc.types.TypePrototypeRegistry
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.matchers.shouldBe
import kotlin.reflect.KClass

private interface FirstPage : Page
private interface SecondPage : Page

val PageCatalogAssemblerTest by testSuite {
    test("derives a display name from a registered concrete Page") {
        val type = reference("first")
        val catalog = PageCatalogAssembler.assemble(
            providers = listOf(provider("questFlowPage", FirstPage::class, type)),
            prototypes = registry(FirstPage::class to type),
        )

        catalog.definitions.single().name shouldBe "Quest Flow"
        catalog.definitions.single().editor shouldBe ResolvedPageEditorDefinition.Graph(GraphDirection.LEFT_TO_RIGHT)
        catalog.diagnostics shouldBe emptyList()
    }

    test("rejects every declaration sharing one type identity") {
        val first = reference("shared", 1)
        val second = reference("shared", 2)
        val catalog = PageCatalogAssembler.assemble(
            providers = listOf(
                provider("firstPage", FirstPage::class, first),
                provider("secondPage", SecondPage::class, second),
            ),
            prototypes = registry(FirstPage::class to first, SecondPage::class to second),
        )

        catalog.definitions shouldBe emptyList()
        catalog.diagnostics.map(PageDiagnostic::code) shouldBe listOf("duplicate_id", "duplicate_id")
    }
}

private fun provider(name: String, markerClass: KClass<out Page>, reference: ResolvedTypeRef): PageProvider =
    object : PageProvider {
        override val type = reference
        override val namespace = "test"
        override val sourcePart = "common"
        override val declarationName = name
        override val marker = markerClass

        override fun specification() = page(
            editor = PageEditorDefinition.Graph(GraphDirection.LEFT_TO_RIGHT),
            icon = "material-symbols:account-tree",
            color = "#123456",
        )
    }

private fun registry(vararg entries: Pair<KClass<out Page>, ResolvedTypeRef>): TypePrototypeRegistry =
    TypePrototypeRegistry(entries.map { (page, reference) ->
        CatalogMetadataTypePrototype(page, reference, TypeDefinition(reference, NominalTypeKind.CONCRETE))
    })

private fun reference(name: String, revision: Int = 1) =
    ResolvedTypeRef(TypeId.Qualified("test.pages", name), revision)
