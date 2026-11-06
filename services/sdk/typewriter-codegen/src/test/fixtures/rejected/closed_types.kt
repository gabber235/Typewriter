package fixture

import com.typewritermc.types.TypewriterType

@TypewriterType(id = "a0000000000000000000000000000903")
sealed interface Loose

class External : Loose // error: A sealed subtype must be nested in its parent or carry its own @TypewriterType.
