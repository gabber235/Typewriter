package com.typewritermc.types

import skirout.editor.v1.type_catalog.ResourceMatch
import skirout.editor.v1.type_catalog.ResourceMatchTemplate
import skirout.editor.v1.type_catalog.TypeDefinitionId
import skirout.editor.v1.type_catalog.TypeTemplate

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
val ResourceMatch.definition: TypeDefinitionId?
    get() =
        when (this) {
            is ResourceMatch.TypeWrapper -> value.definition
            is ResourceMatch.DefinitionWrapper -> value
            else -> null
        }

/** This match as a template with no parameters, the form a declaration holds. */
fun ResourceMatch.toTemplate(): ResourceMatchTemplate =
    when (this) {
        is ResourceMatch.TypeWrapper -> ResourceMatchTemplate.TypeWrapper(value.use.toTemplate())
        is ResourceMatch.DefinitionWrapper -> ResourceMatchTemplate.DefinitionWrapper(value)
        ResourceMatch.ANY_RESOURCE -> ResourceMatchTemplate.ANY_RESOURCE
        else -> unknownVariant(this)
    }

/** Checks that a match template read from a generated provider names a valid definition, a valid type, or every resource. */
fun ResourceMatchTemplate.requireValid(): ResourceMatchTemplate =
    apply {
        when (this) {
            is ResourceMatchTemplate.TypeWrapper -> value.requireValid()
            is ResourceMatchTemplate.DefinitionWrapper -> value.requireValid()
            ResourceMatchTemplate.ANY_RESOURCE -> Unit
            else -> throw IllegalArgumentException("Unknown resource match template.")
        }
    }

/** The definition this template names, or null for every resource and for a type that is a bare parameter. */
val ResourceMatchTemplate.definition: TypeDefinitionId?
    get() =
        when (this) {
            is ResourceMatchTemplate.TypeWrapper -> value.named?.definition
            is ResourceMatchTemplate.DefinitionWrapper -> value
            else -> null
        }

/**
 * The match this template answers while its parameters are unknown. A closed type is that type; an open one fits
 * its definition's nominal subtypes whatever their arguments; a type naming no definition, such as a bare parameter,
 * fits every resource.
 */
fun ResourceMatchTemplate.widest(): ResourceMatch =
    when (this) {
        is ResourceMatchTemplate.TypeWrapper -> {
            value.closedUse?.named?.let { ResourceMatch.TypeWrapper(it) }
                ?: value.named?.let { ResourceMatch.DefinitionWrapper(it.definition) }
                ?: ResourceMatch.ANY_RESOURCE
        }

        is ResourceMatchTemplate.DefinitionWrapper -> {
            ResourceMatch.DefinitionWrapper(value)
        }

        ResourceMatchTemplate.ANY_RESOURCE -> {
            ResourceMatch.ANY_RESOURCE
        }

        else -> {
            unknownVariant(this)
        }
    }

/** This template with [transform] applied to its type; a definition and every resource hold no template and stay. */
fun ResourceMatchTemplate.mapTemplate(transform: (TypeTemplate) -> TypeTemplate): ResourceMatchTemplate =
    when (this) {
        is ResourceMatchTemplate.TypeWrapper -> ResourceMatchTemplate.TypeWrapper(transform(value))
        else -> this
    }
