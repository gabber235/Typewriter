package com.typewritermc.realm

import com.typewritermc.authoring.AuthoringPolicyProvider
import com.typewritermc.authoring.AuthoringResourceDefinition
import com.typewritermc.elements.Element
import com.typewritermc.elements.Cue
import com.typewritermc.library.PAGE_CONTRACT_TYPE
import com.typewritermc.library.BOOK_PAGES_RELATION_ID
import com.typewritermc.library.PAGE_ELEMENTS_RELATION_ID
import com.typewritermc.realm.repository.loadTestPrototypes
import com.typewritermc.types.NominalTypeKind
import com.typewritermc.types.RelationDefinition
import com.typewritermc.types.RelationDeletePolicy
import com.typewritermc.types.RelationId
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
        val elementRoot = qualified(Element::class.qualifiedName!!)
        val cueRoot = qualified(Cue::class.qualifiedName!!)
        val types = TypeCatalog(
            definitions + listOf(
                TypeDefinition(elementRoot, NominalTypeKind.OPEN_ABSTRACT),
                TypeDefinition(cueRoot, NominalTypeKind.OPEN_ABSTRACT),
                TypeDefinition(PAGE_CONTRACT_TYPE, NominalTypeKind.OPEN_ABSTRACT),
                TypeDefinition(
                    id = ResolvedTypeRef(TypeId.Qualified("test", "Element"), 1),
                    kind = NominalTypeKind.CONCRETE,
                    representation = TypeExpression.Record(emptyList()),
                    parents = listOf(elementRoot),
                ),
                TypeDefinition(
                    id = ResolvedTypeRef(TypeId.Qualified("test", "Cue"), 1),
                    kind = NominalTypeKind.CONCRETE,
                    representation = TypeExpression.Record(emptyList()),
                    parents = listOf(cueRoot),
                ),
                TypeDefinition(
                    id = ResolvedTypeRef(TypeId.Qualified("test", "Page"), 1),
                    kind = NominalTypeKind.CONCRETE,
                    representation = TypeExpression.Record(emptyList()),
                    parents = listOf(PAGE_CONTRACT_TYPE),
                ),
            ).filterNot { definition -> definitions.any { it.id == definition.id } },
        )
        val extensionDefinition =
            AuthoringResourceDefinition(
                id = ResourceDefinitionId("example.extension_resource"),
                acceptedRoot = TypeExpression.Named(elementRoot),
            )
        val extension = AuthoringPolicyProvider { builder -> builder.definition(extensionDefinition) }

        val catalog =
            RealmAuthoringPolicyAssembler.assemble(
                providers =
                    listOf(
                        CoreAuthoringPolicyProvider(
                            prototypes = prototypes,
                            pageCatalog = testPageCatalog(),
                            elements = com.typewritermc.elements.ContentCatalog(emptyList()),
                            types = types,
                            catalogRevision = { "test" },
                            relations = emptyList(),
                        ),
                        extension,
                    ),
                catalog = types,
                relations =
                    listOf(
                        BOOK_PAGES_RELATION_ID,
                        PAGE_ELEMENTS_RELATION_ID,
                    ).map { id ->
                        RelationDefinition(
                            id = RelationId(id),
                            source = elementRoot,
                            target = elementRoot,
                            onSourceDelete = RelationDeletePolicy.RESTRICT,
                            onTargetDelete = RelationDeletePolicy.RESTRICT,
                        )
                    },
            )

        catalog.definitions.map(AuthoringResourceDefinition::id) shouldContain extensionDefinition.id
    }
}

private fun qualified(name: String) = ResolvedTypeRef(
    TypeId.Qualified(name.substringBeforeLast('.'), name.substringAfterLast('.')),
    1,
)
