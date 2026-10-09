package fixture

import com.typewritermc.types.TypewriterType
import com.typewritermc.types.Resource
import com.typewritermc.types.PresentationRole

@TypewriterType(id = "a00000000000000000000000000000a2")
data class TypedControl(val count: Int) : Resource

object Inspector : TypedControlPresentation {
    override val roles = setOf(PresentationRole.INSPECTOR)
    override fun TypedControlPresentationScope.present() {
        count { textInput() }
    }
}
