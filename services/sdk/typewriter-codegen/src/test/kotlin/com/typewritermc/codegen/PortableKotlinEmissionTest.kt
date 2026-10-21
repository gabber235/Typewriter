package com.typewritermc.codegen

import com.squareup.kotlinpoet.ClassName
import com.squareup.kotlinpoet.CodeBlock
import com.typewritermc.types.StandardTypes
import com.typewritermc.types.declared
import com.typewritermc.types.integerScalar
import com.typewritermc.types.namedTemplate
import com.typewritermc.types.nullable
import com.typewritermc.types.qualified
import com.typewritermc.types.template
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.assertions.throwables.shouldThrow
import io.kotest.matchers.shouldBe
import skirout.editor.v1.type_catalog.DeclaredTypeId
import skirout.editor.v1.type_catalog.IntegerWidth
import skirout.editor.v1.type_catalog.ParameterKey
import skirout.editor.v1.type_catalog.ScalarKind
import skirout.editor.v1.type_catalog.TypeDefinitionId
import skirout.editor.v1.type_catalog.TypeId
import skirout.editor.v1.type_catalog.TypeTemplate

private val OWNER = TypeDefinitionId.declared("0199a8aa46f57c17b956baa44c629a25")
private val OWNER_DEFINITION = ClassName("fixture", "OwnerDefinition")
private val LIST_DEFINITION = ClassName("com.typewritermc.types", "StandardTypes", "List")
private val REFERENCES = DefinitionReferences(mapOf(OWNER to OWNER_DEFINITION, StandardTypes.list to LIST_DEFINITION))

val PortableKotlinEmissionTest by testSuite {
    test("applied templates reference id owners and use immutable bindings through nested arguments") {
        val parameter = ParameterKey(owner = OWNER, index = 0)
        val template = StandardTypes.list.template(listOf(parameter.template.nullable()))
        val bindings = TypeParameterBindings.from(mapOf(parameter to CodeBlock.of("argument.expected")))

        context(bindings, REFERENCES) { template.appliedUseCode() }.toString() shouldBe
            "skirout.editor.v1.type_catalog.TypeUse.createNamed(definition = com.typewritermc.types.StandardTypes.List.id, " +
            "arguments = listOf(skirout.editor.v1.type_catalog.TypeUse.createNullable(value = argument.expected)))"
    }

    test("an owner object states its own id once and refers to it as id") {
        context(REFERENCES.inside(OWNER)) { ParameterKey(owner = OWNER, index = 0).template.kotlinCode() }.toString() shouldBe
            "skirout.editor.v1.type_catalog.TypeTemplate.ParameterWrapper(" +
            "skirout.editor.v1.type_catalog.ParameterKey(owner = id, index = 0))"
        OWNER.declarationCode().toString() shouldBe
            "skirout.editor.v1.type_catalog.TypeDefinitionId(typeId = skirout.editor.v1.type_catalog.TypeId.DeclaredWrapper(" +
            "skirout.editor.v1.type_catalog.DeclaredTypeId(value = \"0199a8aa46f57c17b956baa44c629a25\")), revision = 1)"
    }

    test("an id without an owner object fails instead of emitting a literal") {
        val unowned = TypeDefinitionId.qualified("kotlin", "fixture.Unowned")
        shouldThrow<IllegalStateException> { context(REFERENCES) { unowned.kotlinCode() } }
    }

    test("scalar emission uses enum members as typed references") {
        context(REFERENCES) { integerScalar(IntegerWidth.SIGNED_THIRTY_TWO).template.kotlinCode() }
            .toString() shouldBe
            "skirout.editor.v1.type_catalog.TypeTemplate.ScalarWrapper(skirout.editor.v1.type_catalog.ScalarKind.createInteger(" +
            "width = skirout.editor.v1.type_catalog.IntegerWidth.SIGNED_THIRTY_TWO))"
    }

    test("lists are empty, inline for one item, and one item per line otherwise") {
        emptyList<CodeBlock>().listCode().toString() shouldBe "emptyList()"
        listOf(CodeBlock.of("a")).listCode().toString() shouldBe "listOf(a)"
        listOf(CodeBlock.of("a"), CodeBlock.of("b")).listCode().toString() shouldBe "listOf(\n  a,\n  b,\n)"
    }
}
