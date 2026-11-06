package fixture

import com.typewritermc.types.TypewriterType

@TypewriterType(id = "a0000000000000000000000000000922")
data class Pairing(
    val two: (Int, Int) -> Int, // error: Name each parameter of a function type with two or more parameters.
)
