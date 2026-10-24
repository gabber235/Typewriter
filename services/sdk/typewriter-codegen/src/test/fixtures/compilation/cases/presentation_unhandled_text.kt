package fixture

import com.typewritermc.types.PresentationRole
import com.typewritermc.types.Resource
import com.typewritermc.types.TypewriterType

@TypewriterType(id = "a0000000000000000000000000000092")
data class ComputedView(
    val name: String,
) : Resource

object ComputedViewEditor : ComputedViewPresentation {
    override val roles: Set<PresentationRole> = setOf(PresentationRole.INSPECTOR)

    override fun ComputedViewPresentationScope.present() {
        text(expressions.name)
    }
}
