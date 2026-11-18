package com.typewritermc.engine.pages

import com.typewritermc.formula.DynamicProvider
import com.typewritermc.formula.Dynamics
import com.typewritermc.formula.TypewriterDynamicProvider

/** Naming a Definition gives its value, whatever its type argument: a `Definition<Int>` reads as an Int. */
@TypewriterDynamicProvider
object DefinitionDynamic : DynamicProvider {
    override fun Dynamics.register() {
        each(DefinitionDefinition.id) { exports { value(DefinitionFields.value) } }
    }
}
