package fixture

import skirout.editor.v1.type_catalog.CatalogGeneration
import com.typewritermc.discovery.*
import com.typewritermc.imprint.ArtifactId
import com.typewritermc.library.TagOperation
import com.typewritermc.library.TagOperationSpec
import com.typewritermc.operations.*
import com.typewritermc.presentation.DefaultPresentationRuntime
import com.typewritermc.presentation.PresentationRuntime
import com.typewritermc.authoring.RealmSection
import com.typewritermc.types.DeletionPolicy
import com.typewritermc.types.Many
import com.typewritermc.types.One
import com.typewritermc.types.Owning
import com.typewritermc.types.Ref
import com.typewritermc.types.ReferenceContract
import com.typewritermc.types.RelationDeletePolicy
import com.typewritermc.types.Resource
import com.typewritermc.types.TypewriterRecordContract
import com.typewritermc.types.TypewriterType
import java.nio.file.Path
import kotlin.io.path.readText

/** Every fixture resource lives on the fixture shelf, a realm section. */
@TypewriterRecordContract
interface Shelved : Resource

@TypewriterType(id = "a0000000000000000000000000000304")
data class Shelf(
    val items: List<Ref<ShelfItems.Shelf, Shelved>> = emptyList(),
) : RealmSection

@ReferenceContract("a0000000000000000000000000000305")
interface ShelfItemsContract : Owning {
    @DeletionPolicy(RelationDeletePolicy.CASCADE)
    interface Shelf : One<fixture.Shelf>

    interface Item : Many<Shelved>
}

@TypewriterRecordContract
interface Reward : Shelved {
    val name: String
}

@TypewriterType(id = "a0000000000000000000000000000301")
data class CoinReward(
    override val name: String,
) : Reward

@TypewriterType(id = "a0000000000000000000000000000302")
data class Variable<T : Reward>(
    val value: T,
) : Shelved

@TypewriterType(id = "a0000000000000000000000000000303")
data class RenameInput(
    val name: String,
)

object ResetReward : VariableOperation<CoinReward, CoinRewardDraft, RenameInput> {
    override fun VariableOperationSpec<CoinReward, CoinRewardDraft, RenameInput>.declare(): PreparedOperation {
        availableWhen { authored(drafts.map { it.value }) }
        return prepare { drafts.forEach { it.setValue(CoinReward(input.name)) } }
    }
}

// SDK dependency contract and implementation in another package.
object Rename : TagOperation<RenameInput> {
    override fun TagOperationSpec<RenameInput>.declare(): PreparedOperation {
        appearance { icon("mdi:rename") }
        return prepare { drafts.forEach { it.setName(input.name) } }
    }
}

/** An operation on every resource; the smallest valid declaration. */
object TouchEverything : ResourceOperation<Unit> {
    override fun ResourceOperationSpec<Unit>.declare(): PreparedOperation = prepare { }
}

fun main(args: Array<String>) {
    val artifact = Path.of(args.single())
    val index = GeneratedProviderIndex.parse(artifact.resolve(GENERATED_PROVIDER_INDEX_PATH).readText())
    check(index.count { it.kind == GeneratedProviderKind.ResourceOperation } == 3)
    GeneratedProviderLoader()
        .load(
            listOf(
                GeneratedProviderArtifact(ArtifactId("fixture"), artifact),
                GeneratedProviderArtifact(
                    ArtifactId("core"),
                    Path.of(
                        TagOperation::class.java.protectionDomain.codeSource.location
                            .toURI(),
                    ),
                ),
            ),
            DeploymentFacts(emptyMap()),
            DiscoveryDomains.Realm,
            runtimeServices = mapOf(PresentationRuntime::class.java to DefaultPresentationRuntime()),
        ).use { deployment ->
            val assembly = deployment.providers.contributions.assemble(CatalogAssemblyContext(CatalogGeneration(value = "fixture")))
            check(assembly.operations.diagnostics.isEmpty()) { assembly.operations.failures.joinToString { it.cause.stackTraceToString() } }
            val fixture = assembly.operations.operations.filter { it.definition.id.artifact == "fixture" }
            check(fixture.map { it.definition.presentation.label }.toSet() == setOf("Reset reward", "Rename", "Touch everything"))
            check(fixture.map { it.definition.id.declaration }.toSet() == setOf("fixture.ResetReward", "fixture.Rename", "fixture.TouchEverything"))
            check(fixture.filter { it.definition.presentation.label != "Touch everything" }.all { it.input.schema != null && it.input.binding != null })
        }
}
