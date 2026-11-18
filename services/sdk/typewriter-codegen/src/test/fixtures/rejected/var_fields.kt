package fixture

import com.typewritermc.formula.Var
import com.typewritermc.types.Resource
import com.typewritermc.types.TypewriterType

@TypewriterType(id = "a0000000000000000000000000000912")
data class BadVar(
    val x: Var<Int, String>, // error: The context of a Var must be an interface.
) : Resource
