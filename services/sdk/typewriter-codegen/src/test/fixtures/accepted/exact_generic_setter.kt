package fixture

import com.typewritermc.authoring.field
import com.typewritermc.authoring.root
import com.typewritermc.authoring.EditContext
import skirout.editor.v1.type_catalog.ValuePath
import com.typewritermc.authoring.append
import skirout.editor.v1.type_catalog.DataValue
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
    draft.location.append(ValuePath.root.field("value")),
    replacement,
)
