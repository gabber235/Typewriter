package com.typewritermc.realm

import com.typewritermc.authoring.AuthoringPolicyProvider
import com.typewritermc.authoring.AuthoringResourceDefinition
import com.typewritermc.elements.Element
import com.typewritermc.realm.repository.loadTestPrototypes
import com.typewritermc.types.NominalTypeKind
import com.typewritermc.types.ResolvedTypeRef
import com.typewritermc.types.TypeCatalog
import com.typewritermc.types.TypeDefinition
import com.typewritermc.types.TypeExpression
import com.typewritermc.types.TypeId
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.matchers.collections.shouldContain

val AuthoringPolicyCompositionTest by testSuite {
    test("extension policies enter the production catalog without a core definition switch") {
        val prototypes = loadTestPrototypes()
        val definitions = prototypes.graph(TypeExpression.Any).definitions
        val elementName = requireNotNull(Element::class.qualifiedName)
        val elementRoot =
            definitions
                .single {
                    it.id.id ==
                        TypeId.Qualified(elementName.substringBeforeLast('.'), elementName.substringAfterLast('.'))
                }.id
        val types =
            TypeCatalog(
                definitions +
                    TypeDefinition(
                        id = ResolvedTypeRef(TypeId.Qualified("test", "Element"), 1),
                        kind = NominalTypeKind.CONCRETE,
                        representation = TypeExpression.Record(emptyList()),
                        parents = listOf(elementRoot),
                    ),
            )
        val extensionDefinition =
            AuthoringResourceDefinition(
                id = ResourceDefinitionId("example.quest_board"),
                acceptedRoot = TypeExpression.Any,
            )
        val extension = AuthoringPolicyProvider { builder -> builder.definition(extensionDefinition) }

        val catalog =
            RealmAuthoringPolicyAssembler.assemble(
                providers =
                    listOf(
                        CoreAuthoringPolicyProvider(
                            prototypes = prototypes,
                            pageCatalog = testPageCatalog(),
                            elements = com.typewritermc.elements.ElementCatalog(emptyList()),
                            types = types,
                            catalogRevision = { "test" },
                        ),
                        extension,
                    ),
                catalog = types,
            )

        catalog.definitions.map(AuthoringResourceDefinition::id) shouldContain extensionDefinition.id
    }
}
