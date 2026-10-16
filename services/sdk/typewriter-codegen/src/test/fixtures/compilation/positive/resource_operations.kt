package fixture

import com.typewritermc.authoring.ResourceDefinitionId
import com.typewritermc.authoring.TypewriterResourceDefinition
import com.typewritermc.checking.CatalogGeneration
import com.typewritermc.discovery.*
import com.typewritermc.imprint.ArtifactId
import com.typewritermc.library.TagOperations
import com.typewritermc.library.TagOperationsScope
import com.typewritermc.operations.*
import com.typewritermc.presentation.DefaultPresentationRuntime
import com.typewritermc.presentation.PresentationRuntime
import com.typewritermc.types.Resource
import com.typewritermc.types.TypewriterRecordContract
import com.typewritermc.types.TypewriterType
import java.nio.file.Path
import java.util.jar.JarFile

@TypewriterRecordContract
interface Reward : Resource {
    val name: String
}

@TypewriterType(id = "a0000000000000000000000000000301")
data class CoinReward(
    override val name: String,
) : Reward

@TypewriterType(id = "a0000000000000000000000000000302")
data class Variable<T : Reward>(
    val value: T,
) : Resource

@TypewriterType(id = "a0000000000000000000000000000303")
data class RenameInput(
    val name: String,
)

object FixtureResources {
    @TypewriterResourceDefinition("fixture.variable", Variable::class)
    val VARIABLE = ResourceDefinitionId("fixture.variable")

    @TypewriterResourceDefinition("fixture.reward", Reward::class)
    val REWARD = ResourceDefinitionId("fixture.reward")
}

object CoinVariableOperations : VariableOperations<CoinReward, CoinRewardDraft> {
    override fun VariableOperationsScope<CoinReward, CoinRewardDraft>.operations() {
        operation("reset", input = operationInput<RenameInput>()) {
            label("Reset reward")
            availability { authored(subjects.map { it.value }) }
            prepare { subjects.forEach { it.setValue(CoinReward(input.name)) } }
        }
    }
}

// SDK dependency contract and implementation in another package.
object ExtraTagOperations : TagOperations {
    override fun TagOperationsScope.operations() {
        operation("rename", input = operationInput<RenameInput>()) {
            label("Rename")
            prepare { subjects.forEach { it.setName(input.name) } }
        }
    }
}

fun main() {
    val artifact = Path.of(System.getProperty("fixtureArtifact"))
    val index =
        JarFile(artifact.toFile()).use { jar ->
            jar.getInputStream(jar.getJarEntry(GENERATED_PROVIDER_INDEX_PATH)).bufferedReader().readText()
        }
    check(index.lines().count { it.startsWith("resourceOperation\t") } == 2)
    GeneratedProviderLoader()
        .load(
            listOf(
                GeneratedProviderArtifact(ArtifactId("fixture"), artifact),
                GeneratedProviderArtifact(
                    ArtifactId("core"),
                    Path.of(
                        TagOperations::class.java.protectionDomain.codeSource.location
                            .toURI(),
                    ),
                ),
            ),
            DeploymentFacts(emptyMap()),
            DiscoveryDomains.Realm,
            runtimeServices = mapOf(PresentationRuntime::class.java to DefaultPresentationRuntime()),
        ).use { deployment ->
            val assembly = deployment.providers.contributions.assemble(CatalogAssemblyContext(CatalogGeneration("fixture")))
            check(assembly.operations.diagnostics.isEmpty()) { assembly.operations.failures.joinToString { it.cause.stackTraceToString() } }
            check(assembly.operations.authoringProviders.count { it.descriptor.id.artifact == "fixture" } == 2)
            check(
                assembly.snapshot.resourceOperations
                    .map { it.presentation.label }
                    .toSet()
                    .containsAll(setOf("Reset reward", "Rename")),
            )
            check(
                assembly.operations.authoringProviders.filter { it.descriptor.id.artifact == "fixture" }.all {
                    it.input.schema != null &&
                        it.input.binding != null
                },
            )
        }
}
