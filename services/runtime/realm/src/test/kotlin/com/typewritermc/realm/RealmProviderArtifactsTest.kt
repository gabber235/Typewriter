@file:OptIn(GeneratedSdkApi::class)

package com.typewritermc.realm

import com.typewritermc.authoring.AppliedNativeArguments
import com.typewritermc.authoring.GeneratedSdkApi
import com.typewritermc.discovery.CatalogAssemblyContext
import com.typewritermc.discovery.DeploymentFacts
import com.typewritermc.discovery.DiscoveryDomains
import com.typewritermc.discovery.GENERATED_PROVIDER_INDEX_PATH
import com.typewritermc.discovery.GeneratedPresentationProvider
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
import com.typewritermc.presentation.PresentationDescriptor
import com.typewritermc.presentation.PresentationTarget
import com.typewritermc.types.GeneratedRecordNativeBinding
import com.typewritermc.types.NativeBindingFactory
import com.typewritermc.types.catalog.CheckedType
import com.typewritermc.types.catalog.DeclarationStatus
import com.typewritermc.types.catalog.Resolution
import com.typewritermc.types.named
import com.typewritermc.types.namedTemplate
import com.typewritermc.types.namedUse
import com.typewritermc.types.qualified
import com.typewritermc.types.record
import com.typewritermc.types.use
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.matchers.shouldBe
import skirout.editor.v1.catalog.PresentationRole
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
        test("common authoring providers survive engine disposition $disposition") {
            val directory = Files.createTempDirectory("realm-common-providers")
            val runtime = directory.resolve("realm.jar").also { providerJar(it, emptyList()) }
            val extension =
                directory.resolve("extension.jar").also {
                    providerJar(
                        it,
                        listOf(
                            Triple("type", RealmCommonTypeProvider::class.java, "common"),
                            Triple("nativeBinding", RealmCommonBindingProvider::class.java, "common"),
                            Triple("presentation", RealmCommonPresentationProvider::class.java, "common"),
                            Triple("registrar", RealmCommonRegistrarProvider::class.java, "common"),
                            Triple("registrar", RealmExecutionRegistrarProvider::class.java, "common"),
                            Triple("type", RealmTargetedTypeProvider::class.java, "paper"),
                        ),
                    )
                }
            val manifest =
                ExtensionManifest(
                    id = ArtifactId("fixture:extension"),
                    version = ArtifactVersion("1.0.0"),
                    sourceParts =
                        listOf(
                            CommonExtensionSourcePart,
                            EngineExtensionSourcePart(
                                "paper",
                                ArtifactRequirement(ArtifactId("fixture:paper"), VersionConstraint("^1")),
                                ResolvedArtifact(ArtifactId("fixture:paper"), ArtifactVersion("1.0.0"), ArtifactKind.ENGINE),
                                emptyList(),
                            ),
                        ),
                    buildProvenance = emptyList(),
                    contributions = emptyList(),
                )
            val artifacts =
                HostedArtifactPackage(
                    runtimeArtifact =
                        HostedArtifact(
                            runtime,
                            RealmManifest(
                                id = ArtifactId("fixture:realm"),
                                version = ArtifactVersion("1.0.0"),
                                hostApi = VersionConstraint("^1"),
                                runtimeEntrypointClass = "fixture.Runtime",
                                contributions = emptyList(),
                            ),
                        ),
                    extensions =
                        listOf(
                            HostedExtensionArtifact(
                                manifest.id,
                                extension,
                                manifest,
                                listOf(
                                    HostedSourcePart("common", disposition),
                                    HostedSourcePart("paper", SourcePartDisposition.Eligible(setOf(RuntimePlacement.PRIMARY_ENGINE))),
                                ),
                            ),
                        ),
                    catalogArtifacts = emptyList(),
                ).realmProviderArtifacts()
            artifacts.single { it.artifact == manifest.id }.acceptedSourceParts shouldBe setOf("common")
            RealmProviderFixture.realmRegistrars = 0
            RealmProviderFixture.executionRegistrars = 0
            GeneratedProviderLoader().load(artifacts, DeploymentFacts(), DiscoveryDomains.Realm).use { deployment ->
                val assembly =
                    deployment.providers.contributions.assemble(
                        CatalogAssemblyContext(CatalogGeneration(value = "realm common")),
                    )
                val published = assembly.editorCatalog.types.single { it.definition.id == RealmProviderFixture.type }
                published.status shouldBe skirout.editor.v1.catalog.DeclarationStatus.READY
                val checked = (assembly.checked.resolve(RealmProviderFixture.type.use()) as Resolution.Ready).value
                val native = assembly.bindings.bind(checked)
                @Suppress("UNCHECKED_CAST")
                (native as com.typewritermc.types.NativeBinding<Unit>).encode(Unit) shouldBe
                    DataValue.named(RealmProviderFixture.type.namedUse(), DataValue.record(emptyMap()))
                assembly.editorCatalog.presentations
                    .single()
                    .target shouldBe
                    skirout.editor.v1.catalog.PresentationTarget
                        .NamedWrapper(RealmProviderFixture.type.namedTemplate())
                deployment.providers.registrars
                    .single()
                    .descriptor.id shouldBe RuntimeRegistrarId("fixture.realm")
                RealmProviderFixture.realmRegistrars shouldBe 1
                RealmProviderFixture.executionRegistrars shouldBe 0
                deployment.providers.contributions.declarations
                    .single()
                    .origin.sourcePart shouldBe "common"
                deployment.providers.contributions.declarations
                    .single()
                    .origin.artifact shouldBe manifest.id
            }
        }
    }
}

object RealmProviderFixture {
    val type = TypeDefinitionId.qualified("fixture", "RealmCommon")
    var realmRegistrars = 0
    var executionRegistrars = 0
    val registrar =
        object : RuntimeRegistrar {
            context(scope: RuntimeScope)
            override suspend fun register() = Unit
        }
}

class RealmCommonTypeProvider : GeneratedTypeProvider {
    override val definition =
        TypeDefinition.partial(
            id = RealmProviderFixture.type,
            representation = RepresentationTemplate.createRecord(fields = emptyList(), abstract_ = false),
        )
}

class RealmCommonBindingProvider : NativeBindingFactory {
    override val definition = RealmProviderFixture.type
    override val provider = NativeBindingId(value = "fixture.common")

    override fun bind(
        actual: CheckedType,
        arguments: AppliedNativeArguments,
    ) = GeneratedRecordNativeBinding(actual, provider, "fixture.common", Unit::class, emptyList()) { Unit }
}

class RealmCommonPresentationProvider : GeneratedPresentationProvider {
    override fun descriptor(origin: ProviderOrigin) =
        PresentationDescriptor(
            PresentationId(namespace = "fixture", name = "common"),
            origin.owner,
            PresentationTarget.Named(RealmProviderFixture.type.namedTemplate()),
            setOf(PresentationRole.INSPECTOR),
            0,
        )

    override fun build(binding: PresentationBuildBinding) = DefaultPresentationRuntime().build(binding) {}
}

class RealmCommonRegistrarProvider : GeneratedRuntimeRegistrarProvider {
    override val descriptor = RuntimeRegistrarDescriptor(RuntimeRegistrarId("fixture.realm"), setOf(DiscoveryDomains.Realm))

    override fun bind(instantiator: GeneratedProviderInstantiator): RuntimeRegistrar {
        RealmProviderFixture.realmRegistrars += 1
        return RealmProviderFixture.registrar
    }
}

class RealmExecutionRegistrarProvider : GeneratedRuntimeRegistrarProvider {
    override val descriptor = RuntimeRegistrarDescriptor(RuntimeRegistrarId("fixture.execution"), setOf(DiscoveryDomains.Execution))

    override fun bind(instantiator: GeneratedProviderInstantiator): RuntimeRegistrar {
        RealmProviderFixture.executionRegistrars += 1
        return RealmProviderFixture.registrar
    }
}

class RealmTargetedTypeProvider : GeneratedTypeProvider {
    init {
        error("Targeted engine code must never be constructed by Realm.")
    }

    override val definition =
        TypeDefinition.partial(
            id = RealmProviderFixture.type,
            representation = RepresentationTemplate.createRecord(fields = emptyList(), abstract_ = false),
        )
}

private fun providerJar(
    path: Path,
    providers: List<Triple<String, Class<*>, String>>,
) {
    JarOutputStream(Files.newOutputStream(path)).use { archive ->
        archive.putNextEntry(JarEntry(GENERATED_PROVIDER_INDEX_PATH))
        archive.write(providers.joinToString("") { (kind, type, part) -> "$kind\t${type.name}\t$part\n" }.encodeToByteArray())
        archive.closeEntry()
        providers.forEach { (_, type, _) ->
            val name = type.name.replace('.', '/') + ".class"
            archive.putNextEntry(JarEntry(name))
            archive.write(requireNotNull(type.getResourceAsStream("/$name")).use { it.readBytes() })
            archive.closeEntry()
        }
    }
}
