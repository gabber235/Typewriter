package com.typewritermc.types.catalog

import com.typewritermc.types.qualified
import com.typewritermc.types.template
import com.typewritermc.types.use
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.assertions.throwables.shouldThrow
import io.kotest.matchers.shouldBe
import skirout.editor.v1.type_catalog.CatalogGeneration
import skirout.editor.v1.type_catalog.FieldDeclaration
import skirout.editor.v1.type_catalog.FieldOwner
import skirout.editor.v1.type_catalog.RepresentationTemplate
import skirout.editor.v1.type_catalog.ScalarKind
import skirout.editor.v1.type_catalog.TypeDefinition
import skirout.editor.v1.type_catalog.TypeDefinitionId
import skirout.editor.v1.type_catalog.TypeTemplate

val RuntimeDefinitionClosureTest by testSuite {
    val holder = TypeDefinitionId.qualified("test", "Holder")
    val inner = TypeDefinitionId.qualified("test", "Inner")
    val leaf = TypeDefinitionId.qualified("test", "Leaf")
    val unrelated = TypeDefinitionId.qualified("test", "Unrelated")

    test("runtime definitions are every declaration the seeds reach through fields, once each") {
        val catalog =
            DefaultCheckedCatalog(
                CatalogGeneration(value = "closure"),
                listOf(
                    record(holder, "inner" to inner.template(), "again" to inner.template()),
                    record(inner, "leaf" to leaf.template()),
                    record(leaf, "text" to ScalarKind.TEXT.template),
                    record(unrelated, "text" to ScalarKind.TEXT.template),
                ),
            )

        catalog.runtimeDefinitions(listOf(holder.use())).map { it.id } shouldBe listOf(holder, inner, leaf)
    }

    test("runtime definitions fail on a declaration that is unavailable because it references an undeclared type") {
        val catalog = DefaultCheckedCatalog(CatalogGeneration(value = "closure"), listOf(record(holder, "inner" to inner.template())))

        shouldThrow<IllegalStateException> { catalog.runtimeDefinitions(listOf(holder.use())) }.message shouldBe
            "A referenced runtime declaration is unavailable: $holder"
    }
}

private fun record(
    id: TypeDefinitionId,
    vararg fields: Pair<String, TypeTemplate>,
): TypeDefinition =
    TypeDefinition.partial(
        id = id,
        representation =
            RepresentationTemplate.createRecord(
                fields =
                    fields.map { (name, type) ->
                        FieldDeclaration.partial(owner = FieldOwner(definition = id, name = name), type = type)
                    },
                abstract_ = false,
            ),
    )
