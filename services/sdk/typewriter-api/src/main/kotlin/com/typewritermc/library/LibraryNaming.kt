package com.typewritermc.library

import com.typewritermc.authoring.defaultAccent
import com.typewritermc.authoring.defaultIcon
import com.typewritermc.authoring.defaultLabel
import com.typewritermc.expression.orElse
import com.typewritermc.expression.orIfBlank

/** A Book names itself by its title and marks itself with its own color and icon. */
object BookNaming : BookDisplay {
    override fun BookDisplayScope.label() = title.orIfBlank(defaultLabel())

    override fun BookDisplayScope.accent() = color.orElse(defaultAccent())

    override fun BookDisplayScope.icon() = icon.orElse(defaultIcon())
}

/** Every page names itself; accent and icon stay those of its page type, so page kinds remain distinguishable. */
object PageNaming : PageDisplay {
    override fun PageDisplayScope.label() = name.orIfBlank(defaultLabel())
}

/** A Tag names itself and marks itself with its own color. */
object TagNaming : TagDisplay {
    override fun TagDisplayScope.label() = name.orIfBlank(defaultLabel())

    override fun TagDisplayScope.accent() = color.orElse(defaultAccent())
}
