package fixture

import com.typewritermc.types.One
import com.typewritermc.types.ReferenceContract
import com.typewritermc.types.Resource
import com.typewritermc.types.TypewriterType

@TypewriterType(id = "a0000000000000000000000000000941")
data class AliasedReward(val name: String = "") : Resource

typealias RewardAlias = AliasedReward

@TypewriterType(id = "a0000000000000000000000000000942")
data class AliasedHolder<T : AliasedReward>(val value: T) : Resource

@TypewriterType(id = "a0000000000000000000000000000943")
data class AliasedSource(val title: String = "") : Resource

@ReferenceContract("a0000000000000000000000000000944")
interface AliasedEndpointContract { // error: Reference contracts require exactly two One or Many endpoint declarations.
    interface Source : One<AliasedSource>

    interface Target : One<AliasedHolder<RewardAlias>> // error: Relation endpoint arguments must use class or parameter types.
}
