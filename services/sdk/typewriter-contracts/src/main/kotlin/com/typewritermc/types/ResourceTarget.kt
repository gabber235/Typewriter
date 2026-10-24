package com.typewritermc.types

/** Which resources a declaration such as a resource display applies to. */
sealed interface ResourceTarget {
    /** Every application of [template], including resources whose type is a nominal subtype of it. */
    data class Type(
        val template: TypeTemplate.Named,
    ) : ResourceTarget

    /** Every resource, when nothing more specific is declared. */
    data object AnyResource : ResourceTarget
}
