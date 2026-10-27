package com.typewritermc.types.catalog

import com.typewritermc.testkit.definitions
import com.typewritermc.types.qualified
import com.typewritermc.types.template
import com.typewritermc.types.use
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.assertions.throwables.shouldThrow
import io.kotest.matchers.shouldBe
import skirout.editor.v1.type_catalog.CatalogGeneration
import skirout.editor.v1.type_catalog.ScalarKind
import skirout.editor.v1.type_catalog.TypeDefinitionId

val RuntimeDefinitionClosureTest by testSuite {
    val holder = TypeDefinitionId.qualified("test", "Holder")
    val inner = TypeDefinitionId.qualified("test", "Inner")
    val leaf = TypeDefinitionId.qualified("test", "Leaf")
    val unrelated = TypeDefinitionId.qualified("test", "Unrelated")

    test("runtime definitions are every declaration the seeds reach through fields, once each") {
        val catalog =
            DefaultCheckedCatalog(
                CatalogGeneration(value = "closure"),
                definitions {
                    record(holder) {
                        field("inner", inner.template())
                        field("again", inner.template())
                    }
                    record(inner) { field("leaf", leaf.template()) }
                    record(leaf) { field("text", ScalarKind.TEXT.template) }
                    record(unrelated) { field("text", ScalarKind.TEXT.template) }
                },
            )

        catalog.runtimeDefinitions(listOf(holder.use())).map { it.id } shouldBe listOf(holder, inner, leaf)
    }

    test("runtime definitions fail on a declaration that is unavailable because it references an undeclared type") {
        val catalog =
            DefaultCheckedCatalog(
                CatalogGeneration(value = "closure"),
                definitions { record(holder) { field("inner", inner.template()) } },
            )

        shouldThrow<IllegalStateException> { catalog.runtimeDefinitions(listOf(holder.use())) }.message shouldBe
            "A referenced runtime declaration is unavailable: $holder"
    }
}
