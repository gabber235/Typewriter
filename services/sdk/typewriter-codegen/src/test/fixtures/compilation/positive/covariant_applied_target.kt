package fixture

import com.typewritermc.authoring.ResourceDefinitionId
import com.typewritermc.authoring.TypewriterResourceDefinition
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

object FixtureResources {
    @TypewriterResourceDefinition("fixture.covariant_source", CovariantSource::class)
    val SOURCE = ResourceDefinitionId("fixture.covariant_source")

    @TypewriterResourceDefinition("fixture.variable", Variable::class)
    val VARIABLE = ResourceDefinitionId("fixture.variable")
}
