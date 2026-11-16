package com.typewritermc.types.catalog

import com.typewritermc.types.TEXT
import com.typewritermc.types.catalog
import com.typewritermc.types.id
import com.typewritermc.types.linkDefinition
import com.typewritermc.types.namedUse
import com.typewritermc.types.resourceDefinition
import com.typewritermc.types.rewardDefinition
import com.typewritermc.types.template
import com.typewritermc.types.unavailableCodes
import com.typewritermc.types.use
import com.typewritermc.types.widest
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.matchers.collections.shouldContain
import io.kotest.matchers.shouldBe
import skirout.editor.v1.type_catalog.EndpointId
import skirout.editor.v1.type_catalog.ParameterKey
import skirout.editor.v1.type_catalog.RepresentationTemplate
import skirout.editor.v1.type_catalog.ResolvedRepresentation
import skirout.editor.v1.type_catalog.ResourceMatch
import skirout.editor.v1.type_catalog.ResourceMatchTemplate
import skirout.editor.v1.type_catalog.TypeDefinition
import skirout.editor.v1.type_catalog.TypeParameter

val ResourceMatchTemplateTest by testSuite {
    val resource = resourceDefinition()
    val reward = rewardDefinition(resource.id)
    val pairId = id("pair")
    val first = ParameterKey(owner = pairId, index = 0)

    test("a template answers its widest match while its parameters are unknown") {
        ResourceMatchTemplate.TypeWrapper(reward.id.template()).widest() shouldBe ResourceMatch.TypeWrapper(reward.id.namedUse())
        ResourceMatchTemplate.TypeWrapper(pairId.template(listOf(first.template))).widest() shouldBe ResourceMatch.DefinitionWrapper(pairId)
        ResourceMatchTemplate.TypeWrapper(first.template).widest() shouldBe ResourceMatch.ANY_RESOURCE
        ResourceMatchTemplate.DefinitionWrapper(pairId).widest() shouldBe ResourceMatch.DefinitionWrapper(pairId)
        ResourceMatchTemplate.ANY_RESOURCE.widest() shouldBe ResourceMatch.ANY_RESOURCE
    }

    test("a link resolves its target to the named type its argument binds") {
        val link = linkDefinition(id("link"))
        val resolved = catalog(resource, reward, link).resolve(link.id.namedUse(listOf(reward.id.namedUse().use)).use)

        val representation = ((resolved as Resolution.Ready).value.schema.representation as ResolvedRepresentation.LinkWrapper).value
        representation.target shouldBe ResourceMatch.TypeWrapper(reward.id.namedUse())
    }

    test("a link whose target binds to a type that is not named is invalid") {
        val link = linkDefinition(id("link"))
        val resolved = catalog(link).resolve(link.id.namedUse(listOf(TEXT)).use)

        (resolved as Resolution.Invalid).diagnostics.map { it.code } shouldBe listOf("invalid_resource_match")
    }

    test("a link to a definition keeps that definition in its closure and needs it declared") {
        val link =
            TypeDefinition.partial(
                id = id("any_reward"),
                parameters = emptyList<TypeParameter>(),
                representation =
                    RepresentationTemplate.createLink(
                        endpoint = EndpointId(value = "any_reward"),
                        target = ResourceMatchTemplate.DefinitionWrapper(reward.id),
                    ),
            )

        link.referencedDefinitions() shouldContain reward.id
        link.storedDefinitions() shouldContain reward.id
        catalog(resource, reward, link).unavailableCodes(link.id) shouldBe emptyList()
        catalog(link).unavailableCodes(link.id) shouldContain "unknown_dependency"
    }
}
