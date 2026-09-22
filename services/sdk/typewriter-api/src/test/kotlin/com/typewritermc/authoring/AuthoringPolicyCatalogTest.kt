package com.typewritermc.authoring

import com.typewritermc.types.TypeExpression
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.assertions.throwables.shouldThrow
import io.kotest.matchers.shouldBe

val AuthoringPolicyCatalogTest by testSuite {
    test("assembles an extension policy without Realm types") {
        val definition = AuthoringResourceDefinition(ResourceDefinitionId("example.quest"), TypeExpression.Any)
        val catalog =
            AuthoringPolicyCatalog.assemble(
                listOf(
                    AuthoringPolicyProvider { builder ->
                        builder.definition(definition)
                    },
                ),
            )

        catalog.definitions shouldBe mapOf(definition.id to definition)
        catalog.validations shouldBe emptyMap()
        catalog.search shouldBe emptyMap()
        catalog.presentations shouldBe emptyMap()
        catalog.creationSlots shouldBe emptyMap()
        catalog.compilation shouldBe emptyMap()
    }

    test("rejects duplicate policy identities") {
        val definition = AuthoringResourceDefinition(ResourceDefinitionId("example.quest"), TypeExpression.Any)
        shouldThrow<IllegalArgumentException> {
            AuthoringPolicyCatalog.assemble(
                listOf(
                    AuthoringPolicyProvider { it.definition(definition) },
                    AuthoringPolicyProvider { it.definition(definition) },
                ),
            )
        }
    }
}
