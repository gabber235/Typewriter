package fixture

import com.typewritermc.authoring.EditContext
import com.typewritermc.types.Resource
import com.typewritermc.types.TypewriterRecordContract
import com.typewritermc.types.TypewriterType

@TypewriterRecordContract
interface Reward : Resource {
    val name: String
}

@TypewriterType(id = "a0000000000000000000000000000070")
data class CoinReward(
    override val name: String,
) : Reward

@TypewriterType(id = "a0000000000000000000000000000071")
data class GemReward(
    override val name: String,
) : Reward

@TypewriterType(id = "a0000000000000000000000000000072")
data class Variable<T : Reward>(
    val name: String,
    val value: T,
) : Resource

context(edits: EditContext)
suspend fun illegalBroadWrite(
    draft: VariableDraft<RewardDraft>,
    replacement: GemReward,
) {
    draft.setValue(replacement) // error: Unresolved reference 'setValue'
}
