package fixture

import com.typewritermc.formula.Dynamics
import com.typewritermc.formula.DynamicProvider
import com.typewritermc.formula.TypewriterDynamicProvider
import com.typewritermc.types.Resource
import com.typewritermc.types.TypewriterType

@TypewriterType(id = "a0000000000000000000000000000961")
data class Crate(
    val name: String = "",
) : Resource

@TypewriterType(id = "a0000000000000000000000000000962")
data class Lid(
    val name: String = "",
) : Resource

@TypewriterDynamicProvider
object Nested : DynamicProvider {
    override fun Dynamics.register() {
        each(CrateDraftType) {
            each(LidDraftType) { } // error: cannot be called in this context with an implicit receiver.
        }
    }
}
