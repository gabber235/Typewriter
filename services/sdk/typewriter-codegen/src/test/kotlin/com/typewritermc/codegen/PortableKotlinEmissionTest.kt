package com.typewritermc.codegen

import com.squareup.kotlinpoet.ClassName
import com.squareup.kotlinpoet.CodeBlock
import com.typewritermc.types.DeclaredTypeId
import com.typewritermc.types.ParameterKey
import com.typewritermc.types.ScalarKind
import com.typewritermc.types.StandardTypes
import com.typewritermc.types.TypeDefinitionId
import com.typewritermc.types.TypeId
import com.typewritermc.types.TypeTemplate
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.assertions.throwables.shouldThrow
import io.kotest.matchers.shouldBe

private val OWNER = TypeDefinitionId(TypeId.Declared(DeclaredTypeId.parse("0199a8aa46f57c17b956baa44c629a25")), 1)
private val OWNER_DEFINITION = ClassName("fixture", "OwnerDefinition")
private val LIST_DEFINITION = ClassName("com.typewritermc.types", "StandardTypes", "List")
private val REFERENCES = DefinitionReferences(mapOf(OWNER to OWNER_DEFINITION, StandardTypes.list to LIST_DEFINITION))

val PortableKotlinEmissionTest by testSuite {
    test("applied templates reference id owners and use immutable bindings through nested arguments") {
        val parameter = ParameterKey(OWNER, 0)
        val template = TypeTemplate.Named(StandardTypes.list, listOf(TypeTemplate.Nullable(TypeTemplate.Parameter(parameter))))
        val bindings = TypeParameterBindings.from(mapOf(parameter to CodeBlock.of("argument.expected")))

        context(bindings, REFERENCES) { template.appliedUseCode() }.toString() shouldBe
            "com.typewritermc.types.TypeUse.Named(com.typewritermc.types.StandardTypes.List.id, " +
            "listOf(com.typewritermc.types.TypeUse.Nullable(argument.expected)))"
    }

    test("an owner object states its own id once and refers to it as id") {
        context(REFERENCES.inside(OWNER)) { TypeTemplate.Parameter(ParameterKey(OWNER, 0)).kotlinCode() }.toString() shouldBe
            "com.typewritermc.types.TypeTemplate.Parameter(com.typewritermc.types.ParameterKey(id, 0))"
        OWNER.declarationCode().toString() shouldBe
            "com.typewritermc.types.TypeDefinitionId(com.typewritermc.types.TypeId.Declared(" +
            "com.typewritermc.types.DeclaredTypeId.parse(\"0199a8aa46f57c17b956baa44c629a25\")), 1)"
    }

    test("an id without an owner object fails instead of emitting a literal") {
        val unowned = TypeDefinitionId(TypeId.Qualified("kotlin", "fixture.Unowned"), 1)
        shouldThrow<IllegalStateException> { context(REFERENCES) { unowned.kotlinCode() } }
    }

    test("scalar emission uses enum members as typed references") {
        context(REFERENCES) { TypeTemplate.Scalar(ScalarKind.Integer(com.typewritermc.types.IntegerWidth.SIGNED_32)).kotlinCode() }
            .toString() shouldBe
            "com.typewritermc.types.TypeTemplate.Scalar(" +
            "com.typewritermc.types.ScalarKind.Integer(com.typewritermc.types.IntegerWidth.SIGNED_32))"
    }

    test("lists are empty, inline for one item, and one item per line otherwise") {
        emptyList<CodeBlock>().listCode().toString() shouldBe "emptyList()"
        listOf(CodeBlock.of("a")).listCode().toString() shouldBe "listOf(a)"
        listOf(CodeBlock.of("a"), CodeBlock.of("b")).listCode().toString() shouldBe "listOf(\n  a,\n  b,\n)"
    }
}
