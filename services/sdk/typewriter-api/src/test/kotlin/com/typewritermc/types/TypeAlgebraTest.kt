package com.typewritermc.types

import com.typewritermc.types.catalog.content
import com.typewritermc.types.catalog.mapNamed
import com.typewritermc.types.catalog.referencedDefinitions
import com.typewritermc.types.catalog.remappingContent
import com.typewritermc.types.catalog.storedDefinitions
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.matchers.collections.shouldContain
import io.kotest.matchers.collections.shouldNotContain
import io.kotest.matchers.shouldBe
import io.kotest.property.Arb
import io.kotest.property.PropTestConfig
import io.kotest.property.checkAll
import skirout.editor.v1.type_catalog.ParameterKey
import skirout.editor.v1.type_catalog.ScalarKind
import skirout.editor.v1.type_catalog.TypeDefinitionId
import skirout.kernel.v1.resource_id.ResourceId

val TypeAlgebraTest by testSuite {
    val config = PropTestConfig(seed = 20_261_108L, iterations = 300)
    val marker = TypeDefinitionId.qualified("marker", "marked")
    val parameter = ParameterKey(owner = TypeDefinitionId.qualified("marker", "owner"), index = 0)

    test("every type form rebuilds itself from its own parts") {
        checkAll(config, Arb.templateHole()) { hole ->
            hole.plug(parameter.template).walk().forEach { node -> node.withParts(node.parts()) shouldBe node }
        }
        checkAll(config, Arb.useHole()) { hole ->
            hole.plug(marker.use()).walk().forEach { node -> node.withParts(node.parts()) shouldBe node }
        }
    }

    test("every template walker reaches a type at any position") {
        checkAll(config, Arb.templateHole()) { hole ->
            val named = hole.plug(marker.template())
            named.referencedDefinitions() shouldContain marker
            named.storedDefinitions() shouldContain marker

            val withParameter = hole.plug(parameter.template)
            withParameter.parameterKeys() shouldContain parameter
            withParameter.referencedDefinitions() shouldContain parameter.owner
            withParameter.substitute(mapOf(parameter to marker.template())) shouldBe named
            withParameter.mapTypes { node -> marker.template().takeIf { node == parameter.template } } shouldBe named

            hole.plug(functionTemplate(result = ScalarKind.TEXT.template)).storedDefinitions() shouldContain FORMULA_USE.definition
        }
    }

    test("every use walker reaches a type at any position") {
        val original = ResourceId(value = "original")
        val copy = ResourceId(value = "copy")
        checkAll(config, Arb.useHole()) { hole ->
            val named = hole.plug(marker.use())
            named.referencedDefinitions() shouldContain marker
            named.mapNamed { use -> ScalarKind.TEXT.use.takeIf { use.definition == marker } } shouldBe hole.plug(ScalarKind.TEXT.use)
            hole.plug(TypeDefinitionId.content(original, "kind").use()).remappingContent(mapOf(original to copy)) shouldBe
                hole.plug(TypeDefinitionId.content(copy, "kind").use())
            hole.plug(functionUse(result = ScalarKind.TEXT.use)).storedDefinitions() shouldContain FORMULA_USE.definition
        }
    }

    test("a function type is written without the Formula record its values are stored as") {
        val function = functionUse(parameters = listOf("level" to marker.use()), result = ScalarKind.TEXT.use)

        function.referencedDefinitions() shouldNotContain FORMULA_USE.definition
        function.referencedDefinitions() shouldBe setOf(marker)
        function.storedDefinitions() shouldBe setOf(FORMULA_USE.definition, marker)
    }
}
