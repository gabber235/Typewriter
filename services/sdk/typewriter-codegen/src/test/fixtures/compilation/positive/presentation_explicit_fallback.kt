package fixture

import com.typewritermc.expression.literal
import com.typewritermc.expression.orElse
import com.typewritermc.types.PresentationRole
import com.typewritermc.types.Resource
import com.typewritermc.types.TypewriterType

@TypewriterType(id = "a0000000000000000000000000000093")
data class FallbackView(
    val repeat: Boolean,
    val name: String,
) : Resource

object FallbackViewEditor : FallbackViewPresentation {
    override val roles: Set<PresentationRole> = setOf(PresentationRole.INSPECTOR)

    override fun FallbackViewPresentationScope.present() {
        showIf(condition = { repeat.orElse(literal(false)) }) {
            text(expressions.name.orElse(literal("Unnamed")))
        }
    }
}
