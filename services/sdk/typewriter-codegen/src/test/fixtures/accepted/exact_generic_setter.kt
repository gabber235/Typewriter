package fixture

import com.typewritermc.authoring.EditContext
import com.typewritermc.authoring.PathSegment
import com.typewritermc.authoring.ResourceDefinitionId
import com.typewritermc.authoring.TypewriterResourceDefinition
import com.typewritermc.authoring.ValuePath
import com.typewritermc.authoring.append
import com.typewritermc.types.DataValue
import com.typewritermc.types.Resource
import com.typewritermc.types.TypewriterRecordContract
import com.typewritermc.types.TypewriterType

@TypewriterRecordContract
interface Reward : Resource {
    val name: String
}

@TypewriterType(id = "a0000000000000000000000000000073")
data class CoinReward(
    override val name: String,
) : Reward

@TypewriterType(id = "a0000000000000000000000000000074")
data class Variable<T : Reward>(
    val name: String,
    val value: T,
) : Resource

object FixtureResources {
    @TypewriterResourceDefinition("fixture.variable", Variable::class)
    val VARIABLE = ResourceDefinitionId("fixture.variable")
}

context(edits: EditContext)
suspend fun exactWrite(
    draft: VariableExactDraft<CoinReward, CoinRewardDraft>,
    replacement: CoinReward,
) {
    draft.setValue(replacement)
}

context(edits: EditContext)
suspend fun broadIndependentWrite(
    draft: VariableDraft<RewardDraft>,
) {
    draft.setName("updated")
}

context(edits: EditContext)
suspend fun dynamicCheckedWrite(
    draft: VariableDraft<RewardDraft>,
    replacement: DataValue,
) = edits.checkedSet(
    draft.location.append(ValuePath(listOf(PathSegment.Field("value")))),
    replacement,
)
