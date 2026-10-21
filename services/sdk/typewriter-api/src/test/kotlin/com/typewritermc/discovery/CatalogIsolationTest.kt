package com.typewritermc.discovery

import com.typewritermc.checking.CatalogGeneration
import com.typewritermc.configuration.ConfigurationProvider
import com.typewritermc.imprint.ArtifactId
import com.typewritermc.imprint.ContributionName
import com.typewritermc.imprint.ContributionSourceId
import com.typewritermc.imprint.ProducerId
import com.typewritermc.types.catalog.DeclarationDiagnostic
import com.typewritermc.types.catalog.DeclarationStatus
import com.typewritermc.types.catalog.DefaultCheckedCatalog
import com.typewritermc.types.namedTemplate
import com.typewritermc.types.qualified
import com.typewritermc.types.skir.SkirTypeCodec
import com.typewritermc.types.skir.getOrThrow
import com.typewritermc.types.template
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.assertions.throwables.shouldThrow
import io.kotest.matchers.shouldBe
import kotlinx.coroutines.CancellationException
import skirout.editor.v1.catalog.PresentationRole
import skirout.editor.v1.type_catalog.DeclarationOwner
import skirout.editor.v1.type_catalog.FieldDeclaration
import skirout.editor.v1.type_catalog.FieldOwner
import skirout.editor.v1.type_catalog.ParameterKey
import skirout.editor.v1.type_catalog.PresentationId
import skirout.editor.v1.type_catalog.RepresentationTemplate
import skirout.editor.v1.type_catalog.ScalarKind
import skirout.editor.v1.type_catalog.TypeDefinition
import skirout.editor.v1.type_catalog.TypeDefinitionId
import skirout.editor.v1.type_catalog.TypeParameter

val CatalogIsolationTest by testSuite {
    test("unknown field dependency makes its declaration unavailable") {
        val broken = id("Broken")
        val definition =
            record(
                broken,
                FieldDeclaration.partial(owner = FieldOwner(definition = broken, name = "payload"), type = id("Missing").template()),
            )
        val assembly =
            CatalogContributions(
                declarations = listOf(OwnedTypeDeclaration(origin, definition)),
            ).assemble(CatalogAssemblyContext(generation))
        (assembly.checked.definition(broken) is DeclarationStatus.Unavailable) shouldBe true
        assembly.editorCatalog.types
            .single { it.definition.id == broken }
            .status shouldBe SkirTypeCodec.encode(assembly.checked.definition(broken)).getOrThrow()
        assembly.editorCatalog.recommendations shouldBe emptyList()
    }

    test("quarantine follows parameter bounds and nested parent arguments") {
        val bound = record(id("Bound"))
        val generic =
            TypeDefinition.partial(
                id = id("Generic"),
                parameters =
                    listOf(
                        TypeParameter(
                            key = ParameterKey(owner = id("Generic"), index = 0),
                            name = "T",
                            bounds = listOf(bound.id.template()),
                        ),
                    ),
                representation = RepresentationTemplate.createRecord(fields = emptyList(), abstract_ = false),
            )
        val parent =
            TypeDefinition.partial(
                id = id("Parent"),
                parameters = listOf(TypeParameter.partial(key = ParameterKey(owner = id("Parent"), index = 0), name = "T")),
                representation = RepresentationTemplate.createRecord(fields = emptyList(), abstract_ = true),
            )
        val child = record(id("Child")).copy(parents = listOf(parent.id.namedTemplate(listOf(bound.id.template()))))
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
        assembly.editorCatalog.diagnostics
            .single { it.affected == broken.id }
            .code shouldBe "configuration_callback_failed"
        assembly.checked.definition(healthy.id) shouldBe DeclarationStatus.Ready
    }

    test("representation presentation failure retains its scalar callback context") {
        val cause = IllegalStateException("fixture representation failure")
        val descriptor =
            com.typewritermc.presentation.PresentationDescriptor(
                PresentationId(namespace = "isolation", name = "scalar"),
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
                (failure.callback as? CatalogCallback.Presentation)?.subject == ScalarKind.TEXT.template
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

private fun id(name: String) = TypeDefinitionId.qualified("isolation", name)

private fun record(
    id: TypeDefinitionId,
    vararg fields: FieldDeclaration,
) = TypeDefinition.partial(id = id, representation = RepresentationTemplate.createRecord(fields = fields.toList(), abstract_ = false))

private val origin =
    ProviderOrigin(
        DeclarationOwner(
            source =
                contributionKey(
                    ContributionSourceId("test"),
                    "main",
                    ProducerId("sdk"),
                    ContributionName("isolation"),
                ),
            localIdentity = "isolation",
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
