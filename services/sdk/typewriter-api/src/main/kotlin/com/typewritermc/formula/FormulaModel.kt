package com.typewritermc.formula

import com.typewritermc.types.DeletionPolicy
import com.typewritermc.types.FORMULA_TYPE_ID
import com.typewritermc.types.Many
import com.typewritermc.types.Ref
import com.typewritermc.types.ReferenceContract
import com.typewritermc.types.RelationDeletePolicy
import com.typewritermc.types.Resource
import com.typewritermc.types.TypewriterType
import kotlinx.serialization.Serializable

/** A range of a formula's source text, in UTF-16 code units, end exclusive. */
@Serializable
@TypewriterType(id = TEXT_SPAN_TYPE_ID)
data class TextSpan(
    val start: Int,
    val end: Int,
)

/**
 * Links content to the resources it names. Creator references inside content types and the targets of formula
 * references are both links of this one contract. Deleting a target clears the link.
 */
@ReferenceContract(CONTENT_REFERENCES_RELATION_ID)
interface ContentReferencesContract {
    interface Source : Many<Resource>

    @DeletionPolicy(RelationDeletePolicy.CLEAR)
    interface Target : Many<Resource>
}

/** A name in a formula's source at [at] that resolved to [target]. A rename of the target rewrites nothing. */
@Serializable
@TypewriterType(id = FORMULA_REFERENCE_TYPE_ID)
data class FormulaReference(
    val at: TextSpan,
    val target: Ref<ContentReferences.Source, Resource>,
)

/**
 * The stored body of a function: its source text and the resources the source names. Every function type stores its
 * values as this record.
 */
@Serializable
@TypewriterType(id = FORMULA_TYPE_ID)
data class Formula(
    val source: String,
    val references: List<FormulaReference> = emptyList(),
)

/**
 * A value an author either writes plainly or computes with a formula. In the catalog `Var<T, F>` is a closed record
 * whose second argument is the function type `(context of F) -> T`, so picking the plain or the formula form is
 * picking a case. [F] is only a marker in Kotlin: an interface whose properties are what the formula may read.
 */
@Serializable
@TypewriterType(id = VAR_TYPE_ID)
sealed interface Var<T, F> {
    /** The value as written. A function typed value stores its body here, as a [Formula]. */
    @Serializable
    data class Value<T, F>(
        val value: T,
    ) : Var<T, F>

    /** The value computed by [formula], which reads the context [F] names. */
    @Serializable
    data class Computed<T, F>(
        val formula: Formula,
    ) : Var<T, F>
}

/** The context of a Definition's formulas: it names nothing, so they are pure by construction. */
interface DefinitionScope

const val VAR_TYPE_ID = "acacc4ba2c064f5484d99d06a597d05b"
const val TEXT_SPAN_TYPE_ID = "a869bc7c438547b3a3e8969864bfbe64"
const val FORMULA_REFERENCE_TYPE_ID = "71cb6e564abe4e89ba39d207bd227744"
const val CONTENT_REFERENCES_RELATION_ID = "4e4373d69e5a4445870fd0f8f472b2b0"
