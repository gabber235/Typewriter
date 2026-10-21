@file:JvmName("GenericResourceDisplay")

package fixture

import com.typewritermc.authoring.defaultLabel
import com.typewritermc.expression.orIfBlank
import com.typewritermc.types.Resource
import com.typewritermc.types.ResourceTarget
import com.typewritermc.types.TypewriterRecordContract
import com.typewritermc.types.TypewriterType
import com.typewritermc.types.namedTemplate

/** What every box shares, whatever it holds. */
@TypewriterRecordContract
interface Labeled : Resource {
    val title: String
}

@TypewriterType(id = "a0000000000000000000000000000711")
data class Box<T>(
    override val title: String = "",
    val contents: List<T> = emptyList(),
) : Labeled

/** Names every box by its title through the non generic contract all its applications share. */
object LabeledNaming : LabeledDisplay {
    override fun LabeledDisplayScope.label() = title.orIfBlank(defaultLabel())
}

fun main(args: Array<String>) {
    check(LabeledNaming_LabeledDisplayProvider().target == ResourceTarget.Type(LabeledDefinition.id.namedTemplate(emptyList())))
}
