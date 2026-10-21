package com.typewritermc.types

import skirout.editor.v1.type_catalog.CollectionKind
import skirout.editor.v1.type_catalog.DeclarationOwner
import skirout.editor.v1.type_catalog.DeclaredTypeId
import skirout.editor.v1.type_catalog.EndpointId
import skirout.editor.v1.type_catalog.EnumVariant
import skirout.editor.v1.type_catalog.FieldDeclaration
import skirout.editor.v1.type_catalog.FieldOwner
import skirout.editor.v1.type_catalog.FloatWidth
import skirout.editor.v1.type_catalog.IntegerWidth
import skirout.editor.v1.type_catalog.NamedTypeTemplate
import skirout.editor.v1.type_catalog.NamedTypeUse
import skirout.editor.v1.type_catalog.ParameterKey
import skirout.editor.v1.type_catalog.RelationFamilyId
import skirout.editor.v1.type_catalog.RelationId
import skirout.editor.v1.type_catalog.RepresentationTemplate
import skirout.editor.v1.type_catalog.RuleId
import skirout.editor.v1.type_catalog.RuleOrigin
import skirout.editor.v1.type_catalog.ScalarKind
import skirout.editor.v1.type_catalog.TypeDefinition
import skirout.editor.v1.type_catalog.TypeDefinitionId
import skirout.editor.v1.type_catalog.TypeId
import skirout.editor.v1.type_catalog.TypeParameter
import skirout.editor.v1.type_catalog.TypeTemplate
import skirout.editor.v1.type_catalog.TypeUse

/** The deepest nesting of type applications a type expression may have. */
const val MAX_TYPE_DEPTH = 512

/*
 * Checks the invariants of portable type values where they enter the runtime: from the wire, from storage, and from
 * generated providers. Generated Skir constructors cannot enforce them, so code below these boundaries relies on
 * values that passed one of these checks. Each check fails with an IllegalArgumentException naming the rule.
 */

/** Requires the canonical 32 character lowercase hexadecimal UUID form, so one id never becomes two map keys. */
fun DeclaredTypeId.requireValid(): DeclaredTypeId =
    apply { require(CANONICAL_DECLARED_TYPE_ID.matches(value)) { "Declared type id must be a 32 character lowercase hexadecimal UUID." } }

fun TypeId.requireValid(): TypeId =
    apply {
        when (this) {
            is TypeId.DeclaredWrapper -> {
                value.requireValid()
            }

            is TypeId.QualifiedWrapper -> {
                require(value.namespace.isNotBlank()) { "Type namespace must not be blank." }
                require(value.name.isNotBlank()) { "Type name must not be blank." }
            }

            else -> {
                throw IllegalArgumentException("Unknown type identity variant.")
            }
        }
    }

fun TypeDefinitionId.requireValid(): TypeDefinitionId =
    apply {
        typeId.requireValid()
        require(revision > 0) { "Type revision must be positive." }
    }

fun ParameterKey.requireValid(): ParameterKey =
    apply {
        owner.requireValid()
        require(index >= 0) { "Parameter index must not be negative." }
    }

fun ScalarKind.requireValid(): ScalarKind =
    apply {
        when (this) {
            ScalarKind.UNIT, ScalarKind.BOOLEAN, ScalarKind.TEXT, ScalarKind.BYTES,
            ScalarKind.DECIMAL, ScalarKind.TIMESTAMP, ScalarKind.DURATION,
            -> Unit

            is ScalarKind.IntegerWrapper -> require(value.width != IntegerWidth.UNKNOWN) { "Unknown integer width." }

            is ScalarKind.FloatWrapper -> require(value.width != FloatWidth.UNKNOWN) { "Unknown float width." }

            else -> throw IllegalArgumentException("Unknown scalar kind.")
        }
    }

/** Checks a closed type application, including its nesting depth of at most [MAX_TYPE_DEPTH]. */
fun TypeUse.requireValid(): TypeUse = apply { requireValid(depth = 1) }

fun NamedTypeUse.requireValid(): NamedTypeUse = apply { requireValid(depth = 1) }

/** Checks a declaration type expression, including its nesting depth of at most [MAX_TYPE_DEPTH]. */
fun TypeTemplate.requireValid(): TypeTemplate = apply { requireValid(depth = 1) }

fun NamedTypeTemplate.requireValid(): NamedTypeTemplate = apply { requireValid(depth = 1) }

fun FieldOwner.requireValid(): FieldOwner =
    apply {
        definition.requireValid()
        require(name.isNotBlank()) { "Field name must not be blank." }
    }

fun TypeParameter.requireValid(): TypeParameter =
    apply {
        key.requireValid()
        require(name.isNotBlank()) { "Type parameter name must not be blank." }
        bounds.forEach { it.requireValid() }
    }

fun FieldDeclaration.requireValid(): FieldDeclaration =
    apply {
        owner.requireValid()
        type.requireValid()
        overrides.forEach { it.requireValid() }
    }

fun EnumVariant.requireValid(): EnumVariant = apply { require(key.isNotBlank()) { "Enum variant key must not be blank." } }

fun EndpointId.requireValid(): EndpointId = apply { require(value.isNotBlank()) { "Endpoint ids must not be blank." } }

fun RelationId.requireValid(): RelationId = apply { require(value.isNotBlank()) { "Relation ids must not be blank." } }

fun RelationFamilyId.requireValid(): RelationFamilyId = apply { require(value.isNotBlank()) { "Relation family ids must not be blank." } }

fun RepresentationTemplate.requireValid(): RepresentationTemplate =
    apply {
        when (this) {
            is RepresentationTemplate.ScalarWrapper -> {
                value.kind.requireValid()
            }

            is RepresentationTemplate.RecordWrapper -> {
                value.fields.forEach { it.requireValid() }
            }

            is RepresentationTemplate.SequenceWrapper -> {
                value.item.requireValid()
                require(value.kind != CollectionKind.UNKNOWN) { "Unknown collection kind." }
            }

            is RepresentationTemplate.MappingWrapper -> {
                value.key.requireValid()
                value.value.requireValid()
            }

            is RepresentationTemplate.EnumerationWrapper -> {
                value.cases.forEach { it.requireValid() }
            }

            is RepresentationTemplate.LinkWrapper -> {
                value.endpoint.requireValid()
                value.target.requireValid()
            }

            else -> {
                throw IllegalArgumentException("Unknown representation template.")
            }
        }
    }

fun TypeDefinition.requireValid(): TypeDefinition =
    apply {
        id.requireValid()
        parameters.forEach { it.requireValid() }
        representation.requireValid()
        parents.forEach { it.requireValid() }
    }

fun RuleOrigin.requireValid(): RuleOrigin = apply { owner.requireValid() }

fun RuleId.requireValid(): RuleId = apply { origin.requireValid() }

/** The contribution key is built from imprint ids, which check their own syntax. */
fun DeclarationOwner.requireValid(): DeclarationOwner =
    apply { require(localIdentity.isNotBlank()) { "Local declaration identity must not be blank." } }

/** Whether this type use passes [requireValid]; for values that may come from outside the runtime. */
val TypeUse.isValid: Boolean get() = runCatching { requireValid() }.isSuccess

/** Whether this type template passes [requireValid]; for values that may come from outside the runtime. */
val TypeTemplate.isValid: Boolean get() = runCatching { requireValid() }.isSuccess

/** Whether this named template passes [requireValid]; for values that may come from outside the runtime. */
val NamedTypeTemplate.isValid: Boolean get() = runCatching { requireValid() }.isSuccess

private fun TypeUse.requireValid(depth: Int) {
    requireTypeDepth(depth)
    when (this) {
        is TypeUse.NamedWrapper -> value.requireValid(depth)
        is TypeUse.NullableWrapper -> value.value.requireValid(depth + 1)
        is TypeUse.ScalarWrapper -> value.requireValid()
        else -> throw IllegalArgumentException("Unknown type use variant.")
    }
}

private fun NamedTypeUse.requireValid(depth: Int) {
    requireTypeDepth(depth)
    definition.requireValid()
    arguments.forEach { it.requireValid(depth + 1) }
}

private fun TypeTemplate.requireValid(depth: Int) {
    requireTypeDepth(depth)
    when (this) {
        is TypeTemplate.ParameterWrapper -> value.requireValid()
        is TypeTemplate.NamedWrapper -> value.requireValid(depth)
        is TypeTemplate.NullableWrapper -> value.value.requireValid(depth + 1)
        is TypeTemplate.ScalarWrapper -> value.requireValid()
        else -> throw IllegalArgumentException("Unknown type template variant.")
    }
}

private fun NamedTypeTemplate.requireValid(depth: Int) {
    requireTypeDepth(depth)
    definition.requireValid()
    arguments.forEach { it.requireValid(depth + 1) }
}

private fun requireTypeDepth(depth: Int) = require(depth <= MAX_TYPE_DEPTH) { "Type expression exceeds the supported nesting depth." }

private val CANONICAL_DECLARED_TYPE_ID = Regex("[0-9a-f]{32}")
