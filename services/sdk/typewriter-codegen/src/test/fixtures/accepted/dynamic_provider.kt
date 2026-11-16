package fixture

import com.typewritermc.checking.DraftType
import com.typewritermc.discovery.DeploymentFacts
import com.typewritermc.discovery.DiscoveryDomains
import com.typewritermc.discovery.GeneratedProviderArtifact
import com.typewritermc.discovery.GeneratedProviderLoader
import com.typewritermc.formula.BindBuilder
import com.typewritermc.formula.BindParameter
import com.typewritermc.formula.DynamicBuilder
import com.typewritermc.formula.Dynamics
import com.typewritermc.formula.DynamicProvider
import com.typewritermc.formula.TypewriterDynamicProvider
import com.typewritermc.imprint.ArtifactId
import com.typewritermc.types.Resource
import com.typewritermc.types.TypewriterType
import io.kotest.matchers.shouldBe
import skirout.editor.v1.type_catalog.TypeDefinitionId
import skirout.kernel.v1.resource_id.ResourceId
import java.nio.file.Path

@TypewriterType(id = "a0000000000000000000000000000941")
data class Shelf(
    val name: String = "",
) : Resource

/** Every shelf exports its name. */
@TypewriterDynamicProvider
object ShelfDynamic : DynamicProvider {
    override fun Dynamics.register() {
        each(ShelfDraftType) { exports { value(ShelfFields.name) } }
    }
}

/** Records which draft types a provider registers hooks for. */
class RecordingDynamics : Dynamics {
    val types = mutableListOf<DraftType<*>>()

    override fun <D> each(
        type: DraftType<D>,
        dynamic: DynamicBuilder.(D) -> Unit,
    ) {
        types += type
    }

    override fun each(
        definition: TypeDefinitionId,
        dynamic: DynamicBuilder.(ResourceId) -> Unit,
    ) = Unit

    override fun <D> bind(
        parameter: BindParameter<D>,
        bind: BindBuilder.(D) -> Unit,
    ) = Unit
}

/** The loader finds the generated provider, and registering it registers the object's hook. */
fun main(args: Array<String>) {
    GeneratedProviderLoader()
        .load(
            listOf(GeneratedProviderArtifact(ArtifactId("fixture"), Path.of(args.single()))),
            DeploymentFacts(emptyMap()),
            DiscoveryDomains.Realm,
        ).use { deployment ->
            val dynamics = deployment.providers.contributions.dynamics
            dynamics.size shouldBe 1
            val recording = RecordingDynamics()
            dynamics.single().provider.run { recording.register() }
            // The loader runs the artifact in its own class loader, so the hook's draft type is its own instance.
            recording.types.map { it.match } shouldBe listOf(ShelfDraftType.match)
        }
}
