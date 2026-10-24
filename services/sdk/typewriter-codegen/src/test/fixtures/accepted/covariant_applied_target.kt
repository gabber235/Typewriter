package fixture

import com.typewritermc.types.One
import com.typewritermc.types.Ref
import com.typewritermc.types.ReferenceContract
import com.typewritermc.types.Resource
import com.typewritermc.types.TypewriterRecordContract
import com.typewritermc.types.TypewriterType

@TypewriterRecordContract
interface Reward : Resource {
    val name: String
}

@TypewriterType(id = "a0000000000000000000000000000060")
data class CoinReward(
    override val name: String,
) : Reward

@TypewriterType(id = "a0000000000000000000000000000061")
data class Variable<T : Reward>(
    val value: T,
) : Resource

@TypewriterType(id = "a0000000000000000000000000000062")
data class CovariantSource(
    val target: Ref<CovariantTarget.Source, Variable<CoinReward>>,
) : Resource

@ReferenceContract("a0000000000000000000000000000063")
interface CovariantTargetContract {
    interface Source : One<CovariantSource>

    interface Target : One<Variable<Reward>>
}

