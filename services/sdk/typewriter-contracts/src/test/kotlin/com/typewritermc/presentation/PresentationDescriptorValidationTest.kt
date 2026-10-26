package com.typewritermc.presentation

import com.typewritermc.discovery.contributionKey
import com.typewritermc.imprint.ContributionName
import com.typewritermc.imprint.ContributionSourceId
import com.typewritermc.imprint.ProducerId
import com.typewritermc.types.namedTemplate
import com.typewritermc.types.qualified
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.assertions.throwables.shouldThrow
import io.kotest.matchers.shouldBe
import skirout.editor.v1.catalog.PresentationDescriptor
import skirout.editor.v1.catalog.PresentationRole
import skirout.editor.v1.catalog.PresentationTarget
import skirout.editor.v1.catalog.RepresentationKind
import skirout.editor.v1.type_catalog.DeclarationOwner
import skirout.editor.v1.type_catalog.PresentationId
import skirout.editor.v1.type_catalog.TypeDefinitionId

val PresentationDescriptorValidationTest by testSuite {
    val valid =
        PresentationDescriptor.of(
            id = PresentationId(namespace = "test", name = "book card"),
            owner =
                DeclarationOwner(
                    source = contributionKey(ContributionSourceId("test"), "main", ProducerId("test"), ContributionName("book_card")),
                    localIdentity = "book card",
                ),
            target = PresentationTarget.NamedWrapper(TypeDefinitionId.qualified("test", "Book").namedTemplate()),
            roles = setOf(PresentationRole.ITEM, PresentationRole.INSPECTOR),
            priority = 0,
        )

    test("a descriptor built from a role set lists its roles in role order and is valid") {
        valid.roles shouldBe listOf(PresentationRole.ITEM, PresentationRole.INSPECTOR).sortedBy { it.kind.ordinal }
        valid.requireValid() shouldBe valid
    }

    mapOf(
        "an unknown role" to (valid.copy(roles = listOf(PresentationRole.UNKNOWN)) to "A presentation declares only known roles."),
        "a duplicate role" to
            (
                valid.copy(roles = listOf(PresentationRole.ITEM, PresentationRole.ITEM)) to
                    "Presentation roles must be unique and in role order."
            ),
        "roles out of order" to (valid.copy(roles = valid.roles.reversed()) to "Presentation roles must be unique and in role order."),
        "an unknown representation target" to
            (valid.copy(target = PresentationTarget.RepresentationWrapper(RepresentationKind.UNKNOWN)) to "Unknown representation kind."),
        "an unknown target kind" to (valid.copy(target = PresentationTarget.UNKNOWN) to "Unknown presentation target."),
        "a blank namespace" to
            (valid.copy(id = PresentationId(namespace = " ", name = "book card")) to "Presentation namespace must not be blank."),
    ).forEach { (case, rejection) ->
        test("a generated presentation descriptor with $case is refused") {
            shouldThrow<IllegalArgumentException> { rejection.first.requireValid() }.message shouldBe rejection.second
        }
    }
}
