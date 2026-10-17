package fixture

import com.typewritermc.types.PresentationRole
import com.typewritermc.types.Resource
import com.typewritermc.types.TypewriterType

@TypewriterType(id = "a0000000000000000000000000000091")
data class ConditionalView(
    val repeat: Boolean,
    val name: String,
) : Resource

object ConditionalViewEditor : ConditionalViewPresentation {
    override val roles: Set<PresentationRole> = setOf(PresentationRole.INSPECTOR)

    override fun ConditionalViewPresentationScope.present() {
        showIf(condition = { repeat }) {
            name { textInput() }
        }
    }
}
