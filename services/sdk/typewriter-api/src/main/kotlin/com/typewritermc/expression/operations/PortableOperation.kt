package com.typewritermc.expression.operations

import build.skir.Serializer
import skirout.editor.v1.expression.FailureId
import skirout.editor.v1.expression.OperationId
import skirout.editor.v1.type_catalog.TypeUse

/** Where an operation runs. Realm implements only [RULE]; the panel implements both. */
enum class OperationProfile { RULE, PANEL }

/** What a type parameter of an operation accepts. */
enum class TypeBound {
    ANY,

    /** Integer, float or decimal of any width; one family per call. */
    NUMERIC,

    /** An integer of any width. */
    INTEGER,

    /** Text, bytes or a collection. */
    SIZED,

    /** Text, a number, boolean, timestamp or duration. */
    ORDERED,
}

/** A host capability a kernel receives besides its arguments. */
enum class OperationCapability { METER, TYPES, RESOURCES }

/** How a list, set or map result names its items. */
enum class ItemIdentities { SOURCE, POSITIONAL, NESTED, GROUPED, PREFIXED }

/**
 * How the call rule passes one argument. [VALUE] arguments must be free of unfilled entries, or the call is missing at
 * their locations; [PARTIAL] and [LOCATED] arguments may contain them and [LOCATED] ones also carry their location;
 * [EACH] lambdas run for every item of the first argument before the kernel; [STEP], [COMPARATOR] and [APPLY] lambdas
 * are driven by the kernel.
 */
enum class ParameterKind { VALUE, PARTIAL, LOCATED, EACH, STEP, COMPARATOR, APPLY }

/** One word of the signature vocabulary of operations.yaml. */
sealed interface Signature {
    enum class ScalarWord { TEXT, BOOLEAN, INT32, INTEGER, FLOAT, DECIMAL, BYTES, DURATION, TIMESTAMP, RESOURCE_ID }

    data class Scalar(
        val word: ScalarWord,
    ) : Signature

    /** An enumeration or record of the core library that the manifest declares. */
    data class Named(
        val use: TypeUse,
    ) : Signature

    /** A framework read model, encoded through its canonical read model. */
    data class ReadModel(
        val serializer: Serializer<*>,
    ) : Signature

    data class Variable(
        val name: String,
    ) : Signature

    /** Explicit null allowed; distinct from missing data. */
    data class Nullable(
        val value: Signature,
    ) : Signature

    data class ListOf(
        val item: Signature,
    ) : Signature

    data class SetOf(
        val item: Signature,
    ) : Signature

    data class MapOf(
        val key: Signature,
        val value: Signature,
    ) : Signature

    data class EntryOf(
        val key: Signature,
        val value: Signature,
    ) : Signature

    /** A list, a set, or a map's entries. */
    data class Items(
        val item: Signature,
    ) : Signature

    data class Link(
        val target: Signature,
    ) : Signature

    data class Partial(
        val value: Signature,
    ) : Signature

    data class Located(
        val value: Signature,
    ) : Signature

    /** A result that may be missing data. */
    data class Maybe(
        val value: Signature,
    ) : Signature

    data class Each(
        val item: Signature,
        val result: Signature,
    ) : Signature

    data class Apply(
        val input: Signature,
        val result: Signature,
    ) : Signature

    data class Step(
        val accumulator: Signature,
        val item: Signature,
    ) : Signature

    data class Comparator(
        val item: Signature,
    ) : Signature

    /** A literal field name of the record type [record] names. */
    data class FieldOf(
        val record: Variable,
    ) : Signature

    /** The type of the field that parameter [field] names. */
    data class FieldType(
        val record: Variable,
        val field: String,
    ) : Signature

    /** The payload type of the named type [named]. */
    data class Representation(
        val named: Variable,
    ) : Signature
}

data class OperationTypeParameter(
    val name: String,
    val bound: TypeBound,
    /** Not inferable from the arguments, so calls carry it as a type argument, in declaration order. */
    val explicit: Boolean,
)

data class OperationParameter(
    val name: String,
    val type: Signature,
    val kind: ParameterKind,
    val variadic: Boolean,
    /** The enum case a DSL call uses when it omits this parameter. */
    val defaultCase: String? = null,
)

/** One declared operation of operations.yaml, generated into [PortableOperationCatalog]. */
data class PortableOperation(
    val id: OperationId,
    val profile: OperationProfile,
    val doc: String,
    val typeParameters: List<OperationTypeParameter>,
    val parameters: List<OperationParameter>,
    val result: Signature,
    val failures: List<FailureId>,
    val uses: Set<OperationCapability>,
    val itemIds: ItemIdentities?,
) {
    /** The type parameters calls name as type arguments, in order. */
    val explicitTypeParameters: List<OperationTypeParameter> get() = typeParameters.filter { it.explicit }

    /** Whether a call with [count] arguments fits the declared parameters. */
    fun accepts(count: Int): Boolean =
        if (parameters.lastOrNull()?.variadic == true) count >= parameters.size - 1 else count == parameters.size

    /** The parameter argument [index] binds, repeating a variadic last parameter. */
    fun parameterAt(index: Int): OperationParameter? =
        parameters.getOrNull(index) ?: parameters.lastOrNull()?.takeIf { it.variadic && index >= parameters.size }
}
