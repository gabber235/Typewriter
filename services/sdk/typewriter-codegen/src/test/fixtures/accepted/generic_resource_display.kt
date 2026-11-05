@file:JvmName("GenericResourceDisplay")

package fixture

import skirout.editor.v1.type_catalog.ResourceTarget
import com.typewritermc.authoring.defaultLabel
import com.typewritermc.expression.shortcuts.orIfBlank
import com.typewritermc.types.DeletionPolicy
import com.typewritermc.types.Many
import com.typewritermc.types.One
import com.typewritermc.types.Owning
import com.typewritermc.types.ReferenceContract
import com.typewritermc.types.RelationDeletePolicy
import com.typewritermc.types.Resource
import com.typewritermc.types.TypewriterRecordContract
import com.typewritermc.types.TypewriterType
import com.typewritermc.discovery.CatalogAssemblyContext
import com.typewritermc.discovery.DeploymentFacts
import com.typewritermc.discovery.DiscoveryDomains
import com.typewritermc.discovery.GeneratedProviderArtifact
import com.typewritermc.discovery.GeneratedProviderLoader
import com.typewritermc.discovery.assemble
import com.typewritermc.imprint.ArtifactId
import com.typewritermc.presentation.DefaultPresentationRuntime
import com.typewritermc.presentation.PresentationRuntime
import com.typewritermc.types.template
import io.kotest.assertions.withClue
import io.kotest.matchers.shouldBe
import java.nio.file.Path
import skirout.editor.v1.type_catalog.CatalogGeneration

/** What every box shares, whatever it holds. */
@TypewriterRecordContract
interface Labeled : Resource {
    val title: String
}

@TypewriterType(id = "a0000000000000000000000000000711")
data class Box<T>(
    override val title: String = "",
    val contents: List<T> = emptyList(),
) : Labeled

/** Boxes nest in boxes, so every application of Box has an owner. */
@ReferenceContract("a0000000000000000000000000000712")
interface BoxNestingContract : Owning {
    @DeletionPolicy(RelationDeletePolicy.CASCADE)
    interface Parent : One<Labeled>

    interface Child : Many<Labeled>
}

/** Names every box by its title through the non generic contract all its applications share. */
object LabeledNaming : LabeledDisplay {
    override fun LabeledDisplayScope.label() = title.orIfBlank(defaultLabel())
}

/** Every application of Box, whatever it holds, is named by the display of its non generic contract. */
fun main(args: Array<String>) {
    GeneratedProviderLoader()
        .load(
            listOf(
                GeneratedProviderArtifact(ArtifactId("fixture"), Path.of(args.single())),
                GeneratedProviderArtifact(ArtifactId("core"), Path.of(Resource::class.java.protectionDomain.codeSource.location.toURI())),
            ),
            DeploymentFacts(emptyMap()),
            DiscoveryDomains.Realm,
            runtimeServices = mapOf(PresentationRuntime::class.java to DefaultPresentationRuntime()),
        ).use { deployment ->
            val assembly = deployment.providers.contributions.assemble(CatalogAssemblyContext(CatalogGeneration(value = "fixture")))
            withClue(assembly.editorCatalog.diagnostics) {
                assembly.displays.displayFor(BoxDefinition.id, assembly.checked)?.target shouldBe
                    ResourceTarget.TypeWrapper(LabeledDefinition.id.template())
            }
        }
}
