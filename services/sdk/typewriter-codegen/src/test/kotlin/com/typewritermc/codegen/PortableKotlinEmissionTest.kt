package com.typewritermc.codegen

import com.squareup.kotlinpoet.CodeBlock
import com.typewritermc.types.DeclaredTypeId
import com.typewritermc.types.ParameterKey
import com.typewritermc.types.ScalarKind
import com.typewritermc.types.TypeDefinitionId
import com.typewritermc.types.TypeId
import com.typewritermc.types.TypeTemplate
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.matchers.shouldBe

val PortableKotlinEmissionTest by testSuite {
    test("typed literals preserve quotes dollars and line breaks") {
        "quote \" dollar \$ line\nnext".kotlinLiteral().toString() shouldBe
            "\"\"\"\n|quote \" dollar \${'$'} line\n|next\n\"\"\".trimMargin()"
    }

    test("applied templates use immutable bindings through nested arguments") {
        val owner = TypeDefinitionId(TypeId.Declared(DeclaredTypeId.parse("0199a8aa46f57c17b956baa44c629a25")), 1)
        val parameter = ParameterKey(owner, 0)
        val list = TypeDefinitionId(TypeId.Qualified("typewriter", "List"), 1)
        val template = TypeTemplate.Named(list, listOf(TypeTemplate.Nullable(TypeTemplate.Parameter(parameter))))
        val bindings = TypeParameterBindings.from(mapOf(parameter to CodeBlock.of("argument.expected")))

        with(bindings) { template.appliedUseCode() }.toString() shouldBe
            "com.typewritermc.types.TypeUse.Named(" +
            "com.typewritermc.types.TypeDefinitionId(" +
            "com.typewritermc.types.TypeId.Qualified(\"typewriter\", \"List\"), 1), " +
            "listOf(com.typewritermc.types.TypeUse.Nullable(argument.expected)))"
    }

    test("scalar emission uses enum members as typed references") {
        TypeTemplate.Scalar(ScalarKind.Integer(com.typewritermc.types.IntegerWidth.SIGNED_32)).kotlinCode().toString() shouldBe
            "com.typewritermc.types.TypeTemplate.Scalar(" +
            "com.typewritermc.types.ScalarKind.Integer(com.typewritermc.types.IntegerWidth.SIGNED_32))"
    }
}
