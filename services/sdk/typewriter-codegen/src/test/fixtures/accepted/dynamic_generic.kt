package fixture

import com.typewritermc.authoring.FieldPath
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

@TypewriterType(id = "a0000000000000000000000000000951")
data class Holder<T>(
    val held: List<T> = emptyList(),
) : Resource

/** Every holder, whatever it holds, exports what it holds. */
@TypewriterDynamicProvider
object HolderDynamic : DynamicProvider {
    override fun Dynamics.register() {
        each(HolderDefinition.id) { exports { value(HolderFields.held) } }
    }
}

/** Runs each hook registered by definition id against a recording builder, keeping what it exports. */
class ExportRecordingDynamics : Dynamics {
    val definitions = mutableListOf<TypeDefinitionId>()

    override fun <D> each(
        type: DraftType<D>,
        dynamic: DynamicBuilder.(D) -> Unit,
    ) = Unit

    override fun each(
        definition: TypeDefinitionId,
        dynamic: DynamicBuilder.(ResourceId) -> Unit,
    ) {
        definitions += definition
    }

    override fun <D> bind(
        parameter: BindParameter<D>,
        bind: BindBuilder.(D) -> Unit,
    ) = Unit
}

/** The hook registers by the generic resource's definition, and its export is the generated field path. */
fun main(args: Array<String>) {
    val field: FieldPath = HolderFields.held
    field.owner shouldBe HolderDefinition.id
    GeneratedProviderLoader()
        .load(
            listOf(GeneratedProviderArtifact(ArtifactId("fixture"), Path.of(args.single()))),
            DeploymentFacts(emptyMap()),
            DiscoveryDomains.Realm,
        ).use { deployment ->
            val recording = ExportRecordingDynamics()
            deployment.providers.contributions.dynamics
                .single()
                .provider
                .run { recording.register() }
            recording.definitions shouldBe listOf(HolderDefinition.id)
        }
}
