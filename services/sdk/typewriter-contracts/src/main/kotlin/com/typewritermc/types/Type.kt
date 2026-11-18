package com.typewritermc.types

import skirout.editor.v1.type_catalog.TypeUse

/**
 * A type held as a value, such as the value of a Definition of Type. Its scalar kind is `type`; content types it names
 * are declared on the resource that holds it.
 */
@JvmInline
value class Type(
    val use: TypeUse,
)
