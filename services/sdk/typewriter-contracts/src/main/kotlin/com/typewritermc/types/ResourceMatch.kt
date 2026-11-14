package com.typewritermc.types

import skirout.editor.v1.type_catalog.ResourceMatch

/** Checks that a match read from a generated provider names a valid definition, a valid type, or every resource. */
fun ResourceMatch.requireValid(): ResourceMatch =
    apply {
        when (this) {
            is ResourceMatch.TypeWrapper -> value.requireValid()
            is ResourceMatch.DefinitionWrapper -> Unit
            ResourceMatch.ANY_RESOURCE -> Unit
            else -> throw IllegalArgumentException("Unknown resource match.")
        }
    }

/** The definition this match names, or null for every resource. */
val ResourceMatch.definition: skirout.editor.v1.type_catalog.TypeDefinitionId?
    get() =
        when (this) {
            is ResourceMatch.TypeWrapper -> value.definition
            is ResourceMatch.DefinitionWrapper -> value
            else -> null
        }
