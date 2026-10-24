package com.typewritermc.discovery

import com.typewritermc.checking.CatalogGeneration
import com.typewritermc.configuration.ConfigurationProvider
import com.typewritermc.imprint.ArtifactId
import com.typewritermc.imprint.ContributionName
import com.typewritermc.imprint.ContributionSourceId
import com.typewritermc.imprint.ProducerId
import com.typewritermc.types.DeclarationOwner
import com.typewritermc.types.FieldDeclaration
import com.typewritermc.types.FieldOwner
import com.typewritermc.types.ParameterKey
import com.typewritermc.types.PresentationId
import com.typewritermc.types.PresentationRole
import com.typewritermc.types.RepresentationTemplate
import com.typewritermc.types.ScalarKind
import com.typewritermc.types.TypeDefinition
import com.typewritermc.types.TypeDefinitionId
import com.typewritermc.types.TypeId
import com.typewritermc.types.TypeParameter
import com.typewritermc.types.TypeTemplate
import com.typewritermc.types.catalog.DeclarationDiagnostic
import com.typewritermc.types.catalog.DeclarationStatus
import com.typewritermc.types.catalog.DefaultCheckedCatalog
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.assertions.throwables.shouldThrow
import io.kotest.matchers.shouldBe
import kotlinx.coroutines.CancellationException

val CatalogIsolationTest by testSuite {
    test("unknown field dependency makes its declaration unavailable") {
        val broken = id("Broken")
        val definition = record(broken, FieldDeclaration(FieldOwner(broken, "payload"), TypeTemplate.Named(id("Missing"))))
        val assembly =
            CatalogContributions(
                declarations = listOf(OwnedTypeDeclaration(origin, definition)),
            ).assemble(CatalogAssemblyContext(generation))
        (assembly.checked.definition(broken) is DeclarationStatus.Unavailable) shouldBe true
        assembly.snapshot.types
            .single { it.definition.id == broken }
            .status shouldBe assembly.checked.definition(broken)
        assembly.snapshot.recommendations shouldBe emptyList()
    }

    test("quarantine follows parameter bounds and nested parent arguments") {
        val bound = record(id("Bound"))
        val generic =
            TypeDefinition(
                id("Generic"),
                listOf(
                    TypeParameter(
                        ParameterKey(id("Generic"), 0),
                        "T",
                        listOf(TypeTemplate.Named(bound.id)),
                    ),
                ),
                RepresentationTemplate.Record(emptyList()),
            )
        val parent =
            TypeDefinition(
                id("Parent"),
                listOf(TypeParameter(ParameterKey(id("Parent"), 0), "T")),
                RepresentationTemplate.Record(emptyList(), abstract = true),
            )
        val child = record(id("Child")).copy(parents = listOf(TypeTemplate.Named(parent.id, listOf(TypeTemplate.Named(bound.id)))))
        val healthy = record(id("Healthy"))
        val catalog =
            DefaultCheckedCatalog(
                generation,
                listOf(bound, generic, parent, child, healthy),
                quarantine = listOf(DeclarationDiagnostic(bound.id, "configuration_callback_failed")),
            )
        listOf(bound.id, generic.id, child.id).forEach { (catalog.definition(it) is DeclarationStatus.Unavailable) shouldBe true }
        catalog.definition(parent.id) shouldBe DeclarationStatus.Ready
        catalog.definition(healthy.id) shouldBe DeclarationStatus.Ready
    }

    test("configuration quarantine retains its exact original callback cause") {
        val broken = record(id("Callback"))
        val healthy = record(id("Unrelated"))
        val cause = IllegalArgumentException("fixture explanation")
        val assembly =
            CatalogContributions(
                declarations = listOf(broken, healthy).map { OwnedTypeDeclaration(origin, it) },
                configurations = listOf(OwnedConfiguration(origin, broken.id, failingProvider(cause))),
            ).assemble(CatalogAssemblyContext(generation))
        val failure = assembly.callbackFailures.single()
        (failure.cause === cause) shouldBe true
        failure.callback shouldBe CatalogCallback.Configuration(broken.id)
        assembly.snapshot.diagnostics
            .single { it.affected == broken.id }
            .code shouldBe "configuration_callback_failed"
        assembly.checked.definition(healthy.id) shouldBe DeclarationStatus.Ready
    }

    test("representation presentation failure retains its scalar callback context") {
        val cause = IllegalStateException("fixture representation failure")
        val descriptor =
            com.typewritermc.presentation.PresentationDescriptor(
                PresentationId("isolation", "scalar"),
                origin.owner,
                com.typewritermc.presentation.PresentationTarget
                    .Representation(com.typewritermc.configuration.RepresentationKind.Text),
                setOf(PresentationRole.INSPECTOR),
                0,
            )
        val provider =
            object : com.typewritermc.presentation.PresentationProvider {
                override fun build(
                    binding: com.typewritermc.presentation.PresentationBuildBinding,
                ): com.typewritermc.presentation.PresentationBuildResult = throw cause
            }
        val assembly =
            CatalogContributions(emptyList(), presentations = listOf(OwnedPresentation(origin, descriptor, provider)))
                .assemble(CatalogAssemblyContext(generation))
        val failure =
            assembly.callbackFailures.single { failure ->
                (failure.callback as? CatalogCallback.Presentation)?.subject == TypeTemplate.Scalar(ScalarKind.Text)
            }
        (failure.cause === cause) shouldBe true
        (failure.callback as CatalogCallback.Presentation).role shouldBe PresentationRole.INSPECTOR
    }

    test("callback cancellation propagates unchanged") {
        val definition = record(id("Cancelled"))
        val cancellation = CancellationException("fixture cancellation")
        val caught =
            shouldThrow<CancellationException> {
                CatalogContributions(
                    declarations = listOf(OwnedTypeDeclaration(origin, definition)),
                    configurations = listOf(OwnedConfiguration(origin, definition.id, failingProvider(cancellation))),
                ).assemble(CatalogAssemblyContext(generation))
            }
        (caught === cancellation) shouldBe true
    }
}

private val generation = CatalogGeneration("catalog isolation")

private fun id(name: String) = TypeDefinitionId(TypeId.Qualified("isolation", name), 1)

private fun record(
    id: TypeDefinitionId,
    vararg fields: FieldDeclaration,
) = TypeDefinition(
    id,
    representation = RepresentationTemplate.Record(fields.toList()),
)

private val origin =
    ProviderOrigin(
        DeclarationOwner(
            ContributionKey(
                ContributionSourceId("test"),
                "main",
                ProducerId("sdk"),
                ContributionName("isolation"),
            ),
            "isolation",
        ),
        ArtifactId("test:isolation"),
        "main",
    )

private fun failingProvider(cause: Exception) =
    object : ConfigurationProvider {
        override fun collect(
            scope: com.typewritermc.configuration.ConfigurationCollectionScope,
        ): com.typewritermc.configuration.CollectedConfiguration = throw cause
    }
