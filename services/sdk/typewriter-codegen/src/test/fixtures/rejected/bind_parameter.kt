package fixture

import com.typewritermc.types.Bind
import com.typewritermc.types.Resource
import com.typewritermc.types.TypewriterType

@TypewriterType(id = "b1b00000000000000000000000000011")
open class OpenBoard<@Bind V>( // error: @Bind marks only a type parameter of a final class that implements Resource.
    val title: String = "",
) : Resource

@TypewriterType(id = "b1b00000000000000000000000000012")
data class Note<@Bind V>( // error: @Bind marks only a type parameter of a final class that implements Resource.
    val text: String = "",
)

fun <@Bind T> pick(value: T): T = value // error: @Bind marks only a type parameter of a final class that implements Resource.
