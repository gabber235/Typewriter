package com.typewritermc.discovery

import com.typewritermc.configuration.ConfigurationProvider
import com.typewritermc.presentation.of
import com.typewritermc.testkit.configurationProvider
import com.typewritermc.testkit.origin
import com.typewritermc.testkit.recordType
import com.typewritermc.types.catalog.DefaultCheckedCatalog
import com.typewritermc.types.catalog.of
import com.typewritermc.types.namedTemplate
import com.typewritermc.types.qualified
import com.typewritermc.types.template
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.assertions.throwables.shouldThrow
import io.kotest.matchers.shouldBe
import kotlinx.coroutines.CancellationException
import skirout.editor.v1.catalog.DeclarationStatus
import skirout.editor.v1.catalog.PresentationDescriptor
import skirout.editor.v1.catalog.PresentationRole
import skirout.editor.v1.diagnostic.DeclarationDiagnostic
import skirout.editor.v1.type_catalog.CatalogGeneration
import skirout.editor.v1.type_catalog.FieldDeclaration
import skirout.editor.v1.type_catalog.FieldOwner
import skirout.editor.v1.type_catalog.ParameterKey
import skirout.editor.v1.type_catalog.PresentationId
import skirout.editor.v1.type_catalog.RecordForm
import skirout.editor.v1.type_catalog.RepresentationTemplate
import skirout.editor.v1.type_catalog.ScalarKind
import skirout.editor.v1.type_catalog.TypeDefinition
import skirout.editor.v1.type_catalog.TypeDefinitionId
import skirout.editor.v1.type_catalog.TypeParameter

val CatalogIsolationTest by testSuite {
    val generation = CatalogGeneration(value = "catalog isolation")

    val origin = origin("isolation", artifact = "test:isolation")

    test("unknown field dependency makes its declaration unavailable") {
        val broken = TypeDefinitionId.qualified("isolation", "Broken")
        val definition =
            recordType(
                broken,
                FieldDeclaration.partial(
                    owner = FieldOwner(definition = broken, name = "payload"),
                    type = TypeDefinitionId.qualified("isolation", "Missing").template(),
                ),
            )
        val assembly =
            CatalogContributions(
                declarations = listOf(OwnedTypeDeclaration(origin, definition)),
            ).assemble(CatalogAssemblyContext(generation))
        (assembly.checked.definition(broken) is DeclarationStatus.UnavailableWrapper) shouldBe true
        assembly.editorCatalog.types
            .single { it.definition.id == broken }
            .status shouldBe assembly.checked.definition(broken)
        assembly.editorCatalog.recommendations shouldBe emptyList()
    }

    test("quarantine follows parameter bounds and nested parent arguments") {
        val bound = recordType(TypeDefinitionId.qualified("isolation", "Bound"))
        val generic =
            TypeDefinition.partial(
                id = TypeDefinitionId.qualified("isolation", "Generic"),
                parameters =
                    listOf(
                        TypeParameter(
                            key = ParameterKey(owner = TypeDefinitionId.qualified("isolation", "Generic"), index = 0),
                            name = "T",
                            bounds = listOf(bound.id.template()),
                            derived = false,
                        ),
                    ),
                representation = RepresentationTemplate.createRecord(fields = emptyList(), form = RecordForm.CONCRETE),
            )
        val parent =
            TypeDefinition.partial(
                id = TypeDefinitionId.qualified("isolation", "Parent"),
                parameters =
                    listOf(
                        TypeParameter.partial(
                            key = ParameterKey(owner = TypeDefinitionId.qualified("isolation", "Parent"), index = 0),
                            name = "T",
                        ),
                    ),
                representation = RepresentationTemplate.createRecord(fields = emptyList(), form = RecordForm.OPEN),
            )
        val child =
            recordType(
                TypeDefinitionId.qualified("isolation", "Child"),
            ).copy(parents = listOf(parent.id.namedTemplate(listOf(bound.id.template()))))
        val healthy = recordType(TypeDefinitionId.qualified("isolation", "Healthy"))
        val catalog =
            DefaultCheckedCatalog(
                generation,
                listOf(bound, generic, parent, child, healthy),
                quarantine = listOf(DeclarationDiagnostic.of(bound.id, "configuration_callback_failed")),
            )
        listOf(bound.id, generic.id, child.id).forEach { (catalog.definition(it) is DeclarationStatus.UnavailableWrapper) shouldBe true }
        catalog.definition(parent.id) shouldBe DeclarationStatus.READY
        catalog.definition(healthy.id) shouldBe DeclarationStatus.READY
    }

    test("configuration quarantine retains its exact original callback cause") {
        val broken = recordType(TypeDefinitionId.qualified("isolation", "Callback"))
        val healthy = recordType(TypeDefinitionId.qualified("isolation", "Unrelated"))
        val cause = IllegalArgumentException("fixture explanation")
        val assembly =
            CatalogContributions(
                declarations = listOf(broken, healthy).map { OwnedTypeDeclaration(origin, it) },
                configurations = listOf(OwnedConfiguration(origin, broken.id, configurationProvider { throw cause })),
            ).assemble(CatalogAssemblyContext(generation))
        val failure = assembly.callbackFailures.single()
        (failure.cause === cause) shouldBe true
        failure.callback shouldBe CatalogCallback.Configuration(broken.id)
        assembly.editorCatalog.diagnostics
            .single { it.affected == broken.id }
            .code shouldBe "configuration_callback_failed"
        assembly.checked.definition(healthy.id) shouldBe DeclarationStatus.READY
    }

    test("representation presentation failure retains its scalar callback context") {
        val cause = IllegalStateException("fixture representation failure")
        val descriptor =
            PresentationDescriptor.of(
                PresentationId(namespace = "isolation", name = "scalar"),
                origin.owner,
                skirout.editor.v1.catalog.PresentationTarget
                    .RepresentationWrapper(skirout.editor.v1.catalog.RepresentationKind.TEXT),
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
        val definition = recordType(TypeDefinitionId.qualified("isolation", "Cancelled"))
        val cancellation = CancellationException("fixture cancellation")
        val caught =
            shouldThrow<CancellationException> {
                CatalogContributions(
                    declarations = listOf(OwnedTypeDeclaration(origin, definition)),
                    configurations = listOf(OwnedConfiguration(origin, definition.id, configurationProvider { throw cancellation })),
                ).assemble(CatalogAssemblyContext(generation))
            }
        (caught === cancellation) shouldBe true
    }
}
