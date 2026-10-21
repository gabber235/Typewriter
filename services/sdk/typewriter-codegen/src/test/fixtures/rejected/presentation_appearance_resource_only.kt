package fixture

import skirout.editor.v1.catalog.PresentationRole
import com.typewritermc.types.TypewriterType

@TypewriterType(id = "a00000000000000000000000000000b1")
data class PlainValue(
    val name: String,
)

object PlainValueEditor : PlainValuePresentation {
    override val roles: Set<PresentationRole> = setOf(PresentationRole.INSPECTOR)

    override fun PlainValuePresentationScope.present() {
        appearance // error: Unresolved reference 'appearance'.
    }
}
