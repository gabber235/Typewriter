package com.typewritermc.types

import skirout.editor.v1.type_catalog.NamedTypeTemplate

/** Which resources a declaration such as a resource display applies to. */
sealed interface ResourceTarget {
    /** Every application of [template], including resources whose type is a nominal subtype of it. */
    data class Type(
        val template: NamedTypeTemplate,
    ) : ResourceTarget

    /** Every resource, when nothing more specific is declared. */
    data object AnyResource : ResourceTarget
}
