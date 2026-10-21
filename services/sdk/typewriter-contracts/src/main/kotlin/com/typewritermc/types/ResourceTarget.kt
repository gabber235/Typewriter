package com.typewritermc.types

import skirout.editor.v1.type_catalog.NamedTypeTemplate
import skirout.editor.v1.type_catalog.ResourceTarget
import skirout.editor.v1.type_catalog.TypeTemplate

/** Every application of [template], including resources whose type is a nominal subtype of it. */
fun ResourceTarget.Companion.type(template: NamedTypeTemplate): ResourceTarget.TypeWrapper =
    ResourceTarget.TypeWrapper(TypeTemplate.NamedWrapper(template))

/** The named template whose applications this target selects; a resource target always names a type. */
val ResourceTarget.TypeWrapper.template: NamedTypeTemplate
    get() =
        requireNotNull((value as? TypeTemplate.NamedWrapper)?.value) { "A resource target names a type template." }

/** Checks that a target read from a generated provider names a valid type template or every resource. */
fun ResourceTarget.requireValid(): ResourceTarget =
    apply {
        when (this) {
            is ResourceTarget.TypeWrapper -> template.requireValid()
            ResourceTarget.ANY_RESOURCE -> Unit
            else -> throw IllegalArgumentException("Unknown resource target.")
        }
    }
