package fixture

import com.typewritermc.formula.Dynamics
import com.typewritermc.formula.DynamicProvider
import com.typewritermc.formula.TypewriterDynamicProvider

@TypewriterDynamicProvider
class NotAnObject : DynamicProvider { // error: A dynamic provider must be an object.
    override fun Dynamics.register() = Unit
}

@TypewriterDynamicProvider
private object Hidden : DynamicProvider { // error: A dynamic provider must be visible.
    override fun Dynamics.register() = Unit
}
