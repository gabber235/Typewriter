package fixture

import com.typewritermc.types.Resource
import com.typewritermc.types.TypewriterType

@TypewriterType(id = "a0000000000000000000000000000701")
data class Box<T>(
    val title: String = "",
    val contents: List<T> = emptyList(),
) : Resource

object TextBoxNaming : BoxDisplay<String> // error: Resource displays require a resource type without type parameters; declare the display on a non generic contract that Box implements.
