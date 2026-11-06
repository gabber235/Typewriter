package fixture

import com.typewritermc.types.One
import com.typewritermc.types.Ref
import com.typewritermc.types.ReferenceContract
import com.typewritermc.types.Resource
import com.typewritermc.types.ResourceDefinition
import com.typewritermc.types.StandardTypes
import com.typewritermc.types.TypewriterRecordContract
import com.typewritermc.types.TypewriterType
import com.typewritermc.types.catalog.DefaultCheckedCatalog
import com.typewritermc.types.catalog.Resolution
import com.typewritermc.types.catalog.resolve
import com.typewritermc.types.use
import skirout.editor.v1.type_catalog.CatalogGeneration
import skirout.editor.v1.type_catalog.ResolvedRepresentation
import skirout.editor.v1.type_catalog.TypeUse

@TypewriterRecordContract
interface LinkedReward : Resource {
    val name: String
}

@TypewriterType(id = "a0000000000000000000000000000601")
data class LinkedCoin(
    override val name: String,
) : LinkedReward

@TypewriterType(id = "a0000000000000000000000000000602")
data class LinkedGem(
    override val name: String,
) : LinkedReward

@TypewriterType(id = "a0000000000000000000000000000603")
data class LinkedVariable<T : LinkedReward>(
    val value: T,
) : Resource

// Two fields reference the same generated endpoint with different concrete targets.
@TypewriterType(id = "a0000000000000000000000000000604")
data class LinkedSource(
    val coin: Ref<LinkedTarget.Source, LinkedVariable<LinkedCoin>>,
    val gem: Ref<LinkedTarget.Source, LinkedVariable<LinkedGem>>,
) : Resource

@ReferenceContract("a0000000000000000000000000000605")
interface LinkedTargetContract {
    interface Source : One<LinkedSource>

    interface Target : One<LinkedVariable<LinkedReward>>
}

fun main() {
    val catalog =
        DefaultCheckedCatalog(
            CatalogGeneration(value = "relation link fixture"),
            StandardTypes.definitions +
                ResourceDefinition.definition +
                LinkedRewardDefinition.definition +
                LinkedCoinDefinition.definition +
                LinkedGemDefinition.definition +
                LinkedVariableDefinition.definition +
                LinkedSourceDefinition.definition +
                LinkedTarget.Source.Definition.definition,
        )
    fun TypeUse.resolved() = (catalog.resolve(this) as Resolution.Ready).value
    val fields = LinkedSourceDefinition.use.use.resolved().schema.fields.associate { it.key to it.type }
    fun link(field: String) = fields.getValue(field).resolved().schema.representation as ResolvedRepresentation.LinkWrapper
    val coin = link("coin").value
    val gem = link("gem").value

    // Both fields are links to the one source endpoint, each keeping its own target.
    check(coin.endpoint == LinkedTarget.contract.first.id)
    check(gem.endpoint == coin.endpoint)
    check(coin.target == LinkedVariableDefinition.applied(listOf(LinkedCoinDefinition.use.use)).use)
    check(gem.target == LinkedVariableDefinition.applied(listOf(LinkedGemDefinition.use.use)).use)
}
