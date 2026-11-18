package com.typewritermc.engine.pages

import com.typewritermc.authoring.GraphPlacement
import com.typewritermc.formula.DefinitionScope
import com.typewritermc.formula.Var
import com.typewritermc.library.PageElements
import com.typewritermc.types.Ref
import com.typewritermc.types.TypewriterDisplay
import com.typewritermc.types.TypewriterType

/**
 * A named value on a static page. [T] is the resource's type argument, so the type argument editor and its repair
 * preview change it like any other. A function is a Definition whose [T] is a function type; its body is stored as a
 * Formula under [Var.Value].
 */
@TypewriterType(id = DEFINITION_TYPE_ID)
@TypewriterDisplay(name = "Definition", icon = "material-symbols:function", color = "#00897B")
data class Definition<T>(
    override val page: Ref<PageElements.Element, StaticPage>,
    override val placement: GraphPlacement,
    override val name: String = "",
    val value: Var<T, DefinitionScope>,
) : StaticEntry

const val DEFINITION_TYPE_ID = "5345a30e76f447d9a5adc49625fe1e4b"
