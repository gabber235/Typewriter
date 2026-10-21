package fixture

import skirout.editor.v1.catalog.PresentationRole
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
        showIf(condition = { repeat }) { // error: Return type mismatch: expected 'Expr<Boolean, Handled>', actual 'Expr<Boolean, MayBeMissing>'.
            name { textInput() }
        }
    }
}
