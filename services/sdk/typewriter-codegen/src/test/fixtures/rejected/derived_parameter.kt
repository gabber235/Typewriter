package fixture

import com.typewritermc.types.Derived
import com.typewritermc.types.Resource
import com.typewritermc.types.TypewriterType

@TypewriterType(id = "b1b00000000000000000000000000011")
open class OpenBoard<@Derived V>( // error: @Derived marks only a type parameter of a final class that implements Resource.
    val title: String = "",
) : Resource

@TypewriterType(id = "b1b00000000000000000000000000012")
data class Note<@Derived V>( // error: @Derived marks only a type parameter of a final class that implements Resource.
    val text: String = "",
)

fun <@Derived T> pick(value: T): T = value // error: @Derived marks only a type parameter of a final class that implements Resource.
