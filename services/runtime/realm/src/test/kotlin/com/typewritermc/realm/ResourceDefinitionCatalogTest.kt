package com.typewritermc.realm

import com.typewritermc.types.TypeExpression
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.assertions.throwables.shouldThrow
import io.kotest.matchers.collections.shouldContainExactly
import io.kotest.matchers.shouldBe

val ResourceDefinitionCatalogTest by testSuite {
    test("assembles core and extension definitions without a closed kind enum") {
        val custom =
            AuthoringResourceDefinition(
                id = ResourceDefinitionId("example.quest_board"),
                acceptedRoot = TypeExpression.Any,
            )

        val catalog =
            AuthoringResourceDefinitionCatalog.assemble(
                listOf(
                    AuthoringResourceDefinitionProvider {
                        listOf(
                            AuthoringResourceDefinition(CoreResourceDefinitionIds.BOOK, TypeExpression.Any),
                        )
                    },
                    AuthoringResourceDefinitionProvider { listOf(custom) },
                ),
            )

        catalog.definitions.map(AuthoringResourceDefinition::id) shouldContainExactly
            listOf(CoreResourceDefinitionIds.BOOK, ResourceDefinitionId("example.quest_board"))
        catalog[custom.id] shouldBe custom
    }

    test("rejects duplicate definition identities during assembly") {
        val duplicate = AuthoringResourceDefinition(CoreResourceDefinitionIds.BOOK, TypeExpression.Any)

        shouldThrow<IllegalArgumentException> {
            AuthoringResourceDefinitionCatalog.assemble(
                listOf(
                    AuthoringResourceDefinitionProvider { listOf(duplicate) },
                    AuthoringResourceDefinitionProvider { listOf(duplicate) },
                ),
            )
        }
    }

    test("rejects blank definition identities") {
        shouldThrow<IllegalArgumentException> {
            ResourceDefinitionId(" ")
        }
    }
}
