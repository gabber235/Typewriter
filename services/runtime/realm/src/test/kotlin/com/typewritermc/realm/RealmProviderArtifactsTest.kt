@file:OptIn(GeneratedSdkApi::class)

package com.typewritermc.realm

import com.typewritermc.authoring.AppliedNativeArguments
import com.typewritermc.authoring.GeneratedSdkApi
import com.typewritermc.discovery.CatalogAssemblyContext
import com.typewritermc.discovery.DeploymentFacts
import com.typewritermc.discovery.DiscoveryDomains
import com.typewritermc.discovery.GENERATED_PROVIDER_INDEX_PATH
import com.typewritermc.discovery.GeneratedPresentationProvider
import com.typewritermc.discovery.GeneratedProviderArtifact
import com.typewritermc.discovery.GeneratedProviderDeployment
import com.typewritermc.discovery.GeneratedProviderInstantiator
import com.typewritermc.discovery.GeneratedProviderLoader
import com.typewritermc.discovery.GeneratedRuntimeRegistrarProvider
import com.typewritermc.discovery.GeneratedTypeProvider
import com.typewritermc.discovery.ProviderOrigin
import com.typewritermc.discovery.RuntimeRegistrar
import com.typewritermc.discovery.RuntimeRegistrarDescriptor
import com.typewritermc.discovery.RuntimeRegistrarId
import com.typewritermc.discovery.RuntimeScope
import com.typewritermc.discovery.assemble
import com.typewritermc.imprint.ArtifactId
import com.typewritermc.imprint.ArtifactKind
import com.typewritermc.imprint.ArtifactRequirement
import com.typewritermc.imprint.ArtifactVersion
import com.typewritermc.imprint.CommonExtensionSourcePart
import com.typewritermc.imprint.EngineExtensionSourcePart
import com.typewritermc.imprint.ExtensionManifest
import com.typewritermc.imprint.RealmManifest
import com.typewritermc.imprint.ResolvedArtifact
import com.typewritermc.imprint.VersionConstraint
import com.typewritermc.loader.api.HostedArtifact
import com.typewritermc.loader.api.HostedArtifactPackage
import com.typewritermc.loader.api.HostedExtensionArtifact
import com.typewritermc.loader.api.HostedSourcePart
import com.typewritermc.loader.api.RuntimePlacement
import com.typewritermc.loader.api.SourcePartDisposition
import com.typewritermc.presentation.DefaultPresentationRuntime
import com.typewritermc.presentation.PresentationBuildBinding
import com.typewritermc.presentation.of
import com.typewritermc.testkit.ready
import com.typewritermc.types.GeneratedRecordNativeBinding
import com.typewritermc.types.NativeBinding
import com.typewritermc.types.NativeBindingFactory
import com.typewritermc.types.catalog.CheckedType
import com.typewritermc.types.named
import com.typewritermc.types.namedTemplate
import com.typewritermc.types.namedUse
import com.typewritermc.types.qualified
import com.typewritermc.types.record
import com.typewritermc.types.use
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.matchers.shouldBe
import skirout.editor.v1.catalog.DeclarationStatus
import skirout.editor.v1.catalog.PresentationDescriptor
import skirout.editor.v1.catalog.PresentationRole
import skirout.editor.v1.catalog.PresentationTarget
import skirout.editor.v1.type_catalog.CatalogGeneration
import skirout.editor.v1.type_catalog.DataValue
import skirout.editor.v1.type_catalog.NativeBindingId
import skirout.editor.v1.type_catalog.PresentationId
import skirout.editor.v1.type_catalog.RepresentationTemplate
import skirout.editor.v1.type_catalog.TypeDefinition
import skirout.editor.v1.type_catalog.TypeDefinitionId
import java.nio.file.Files
import java.nio.file.Path
import java.util.jar.JarEntry
import java.util.jar.JarOutputStream

val RealmProviderArtifactsTest by testSuite {
    listOf(
        SourcePartDisposition.Eligible(setOf(RuntimePlacement.PANEL_ENGINE)),
        SourcePartDisposition.Eligible(setOf(RuntimePlacement.PRIMARY_ENGINE)),
        SourcePartDisposition.Ineligible(listOf("No local engine is available.")),
    ).forEach { disposition ->
        test("Realm accepts only the common source part of an extension whose common part is $disposition") {
            val extension = extensionPackage(disposition)

            extension.artifacts.single { it.artifact == EXTENSION }.acceptedSourceParts shouldBe setOf("common")
        }
    }

    test("Realm never constructs providers of an engine targeted source part") {
        extensionPackage().load { deployment ->
            deployment.providers.contributions.declarations
                .map { it.origin.artifact to it.origin.sourcePart } shouldBe listOf(EXTENSION to "common")
        }
    }

    test("Realm binds Realm registrars and never execution registrars") {
        extensionPackage().load { deployment ->
            deployment.providers.registrars.map { it.descriptor.id } shouldBe listOf(RuntimeRegistrarId("fixture.realm"))
        }
    }

    test("common type, native binding and presentation providers reach the Realm catalog") {
        extensionPackage().load { deployment ->
            val assembly =
                deployment.providers.contributions.assemble(
                    CatalogAssemblyContext(CatalogGeneration(value = "realm common")),
                )
            assembly.editorCatalog.types
                .single { it.definition.id == RealmProviderFixture.type }
                .status shouldBe DeclarationStatus.READY
            val native = assembly.bindings.bind(assembly.checked.ready(RealmProviderFixture.type.use()))
            @Suppress("UNCHECKED_CAST")
            (native as NativeBinding<Unit>).encode(Unit) shouldBe
                DataValue.named(RealmProviderFixture.type.namedUse(), DataValue.record(emptyMap()))
            assembly.editorCatalog.presentations
                .single()
                .target shouldBe
                PresentationTarget.NamedWrapper(RealmProviderFixture.type.namedTemplate())
        }
    }
}
