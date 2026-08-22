@file:OptIn(kotlin.time.ExperimentalTime::class)

package com.typewritermc.types

import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable
import java.math.BigInteger
import kotlin.time.Duration
import kotlin.time.Instant

/** Stable nominal identity shared by compile time metadata, manifests, Realm, engines, and Skir transport. */
@Serializable
sealed interface TypeId {
    @Serializable
    @SerialName("option")
    data object Option : TypeId

    @Serializable
    @SerialName("some")
    data object Some : TypeId

    @Serializable
    @SerialName("none")
    data object None : TypeId

    @Serializable
    @SerialName("qualified")
    data class Qualified(
        val namespace: String,
        val name: String,
    ) : TypeId {
        init {
            require(namespace.isNotBlank()) { "Type namespace must not be blank." }
            require(name.isNotBlank()) { "Type name must not be blank." }
        }
    }
}

@Serializable
data class ResolvedTypeRef(
    val id: TypeId,
    val revision: Int,
    val arguments: List<TypeExpression> = emptyList(),
) {
    init {
        require(revision > 0) { "Type revision must be positive." }
    }

    fun withArguments(arguments: Iterable<TypeExpression>) = copy(arguments = arguments.toList())
}

@Serializable
enum class IntegerWidth(
    val bits: Int,
    val signed: Boolean,
) {
    SIGNED_8(8, true),
    SIGNED_16(16, true),
    SIGNED_32(32, true),
    SIGNED_64(64, true),
    UNSIGNED_8(8, false),
    UNSIGNED_16(16, false),
    UNSIGNED_32(32, false),
    UNSIGNED_64(64, false),
}

@Serializable
enum class FloatWidth {
    FLOAT_32,
    FLOAT_64,
}

/** Portable structural type expression independent of KSP, storage, and transport frameworks. */
@Serializable
sealed interface TypeExpression {
    @Serializable
    @SerialName("any")
    data object Any : TypeExpression

    @Serializable
    @SerialName("unit")
    data object Unit : TypeExpression

    @Serializable
    @SerialName("boolean")
    data object Boolean : TypeExpression

    @Serializable
    @SerialName("string")
    data class StringType(
        val minimumLength: Int? = null,
        val maximumLength: Int? = null,
        val patterns: List<String> = emptyList(),
        val allowedValues: List<String> = emptyList(),
    ) : TypeExpression {
        init {
            validateLengths(minimumLength, maximumLength)
            require(patterns.none(String::isEmpty)) { "String patterns must not be empty." }
            require(allowedValues.distinct().size == allowedValues.size) { "Allowed string values must be unique." }
        }
    }

    @Serializable
    @SerialName("bytes")
    data class Bytes(
        val minimumLength: Int? = null,
        val maximumLength: Int? = null,
    ) : TypeExpression {
        init {
            validateLengths(minimumLength, maximumLength)
        }
    }

    @Serializable
    @SerialName("integer")
    data class Integer(
        val width: IntegerWidth,
        @Serializable(with = NullableBigIntegerAsStringSerializer::class)
        val minimum: BigInteger? = null,
        @Serializable(with = NullableBigIntegerAsStringSerializer::class)
        val maximum: BigInteger? = null,
        val minimumInclusive: kotlin.Boolean = true,
        val maximumInclusive: kotlin.Boolean = true,
        @Serializable(with = NullableBigIntegerAsStringSerializer::class)
        val multipleOf: BigInteger? = null,
    ) : TypeExpression {
        init {
            require(minimum == null || maximum == null || minimum <= maximum) {
                "Integer minimum must not exceed its maximum."
            }
        }
    }

    @Serializable
    @SerialName("float")
    data class Float(
        val width: FloatWidth,
        val minimum: Double? = null,
        val maximum: Double? = null,
        val minimumInclusive: kotlin.Boolean = true,
        val maximumInclusive: kotlin.Boolean = true,
        val multipleOf: Double? = null,
    ) : TypeExpression {
        init {
            require(minimum == null || minimum.isFinite()) { "Float minimum must be finite." }
            require(maximum == null || maximum.isFinite()) { "Float maximum must be finite." }
            require(multipleOf == null || multipleOf.isFinite()) { "Float multiple must be finite." }
            require(minimum == null || maximum == null || minimum <= maximum) {
                "Float minimum must not exceed its maximum."
            }
        }
    }

    @Serializable
    @SerialName("decimal")
    data class Decimal(
        val minimum: String? = null,
        val maximum: String? = null,
        val scale: Int? = null,
        val minimumInclusive: kotlin.Boolean = true,
        val maximumInclusive: kotlin.Boolean = true,
        val multipleOf: String? = null,
    ) : TypeExpression {
        init {
            minimum?.requireCanonicalDecimal("Decimal minimum")
            maximum?.requireCanonicalDecimal("Decimal maximum")
            multipleOf?.requireCanonicalDecimal("Decimal multiple")
            require(scale == null || scale >= 0) { "Decimal scale must not be negative." }
        }
    }

    @Serializable
    @SerialName("timestamp")
    data class Timestamp(
        val minimum: Instant? = null,
        val maximum: Instant? = null,
    ) : TypeExpression

    @Serializable
    @SerialName("duration")
    data class Duration(
        val minimum: kotlin.time.Duration? = null,
        val maximum: kotlin.time.Duration? = null,
    ) : TypeExpression

    @Serializable
    @SerialName("enumeration")
    data class Enumeration(
        val valueType: TypeExpression,
        val values: List<DataValue>,
    ) : TypeExpression {
        init {
            require(values.isNotEmpty()) { "Enumeration values must not be empty." }
            require(values.distinct().size == values.size) { "Enumeration values must be unique." }
        }
    }

    @Serializable
    @SerialName("list")
    data class ListType(
        val element: TypeExpression,
        val minimumLength: Int? = null,
        val maximumLength: Int? = null,
        val unique: kotlin.Boolean = false,
    ) : TypeExpression {
        init {
            validateLengths(minimumLength, maximumLength)
        }
    }

    @Serializable
    @SerialName("map")
    data class MapType(
        val key: TypeExpression,
        val value: TypeExpression,
        val minimumLength: Int? = null,
        val maximumLength: Int? = null,
    ) : TypeExpression {
        init {
            validateLengths(minimumLength, maximumLength)
        }
    }

    @Serializable
    @SerialName("record")
    data class Record(
        val fields: List<TypeField>,
        val closed: kotlin.Boolean = true,
    ) : TypeExpression {
        init {
            require(fields.map(TypeField::name).distinct().size == fields.size) { "Record field names must be unique." }
        }
    }

    @Serializable
    @SerialName("named")
    data class Named(
        val reference: ResolvedTypeRef,
    ) : TypeExpression

    @Serializable
    @SerialName("parameter")
    data class Parameter(
        val name: String,
    ) : TypeExpression {
        init {
            require(name.isNotBlank()) { "Type parameter name must not be blank." }
        }
    }
}

@Serializable
data class TypeField(
    val name: String,
    val type: TypeExpression,
    val initialValue: DataValue? = null,
) {
    init {
        require(name.isNotBlank()) { "Type field name must not be blank." }
    }
}

@Serializable
enum class TypeVariance {
    INVARIANT,
    COVARIANT,
    CONTRAVARIANT,
}

@Serializable
enum class NominalTypeKind {
    CONCRETE,
    OPEN_ABSTRACT,
    SEALED_ABSTRACT,
}

@Serializable
data class TypeParameter(
    val name: String,
    val upperBounds: List<TypeExpression> = emptyList(),
    val variance: TypeVariance = TypeVariance.INVARIANT,
) {
    init {
        require(name.isNotBlank()) { "Type parameter name must not be blank." }
    }
}

@Serializable
data class PresentationId(
    val namespace: String,
    val name: String,
) {
    init {
        require(namespace.isNotBlank()) { "Presentation namespace must not be blank." }
        require(name.isNotBlank()) { "Presentation name must not be blank." }
    }
}

@Serializable
data class ConversionId(
    val namespace: String,
    val name: String,
) {
    init {
        require(namespace.isNotBlank()) { "Conversion namespace must not be blank." }
        require(name.isNotBlank()) { "Conversion name must not be blank." }
    }
}

@Serializable
data class TypeDefinition(
    val id: ResolvedTypeRef,
    val kind: NominalTypeKind,
    val representation: TypeExpression = TypeExpression.Any,
    val parameters: List<TypeParameter> = emptyList(),
    val parents: List<ResolvedTypeRef> = emptyList(),
    val defaultPresentationId: PresentationId? = null,
    val namedPresentations: Map<String, PresentationId> = emptyMap(),
    val displayName: String = id.displayName,
    val outgoingConversionIds: List<ConversionId> = emptyList(),
) {
    init {
        require(id.arguments.isEmpty()) { "Type definition identity must not contain type arguments." }
        require(parameters.map(TypeParameter::name).distinct().size == parameters.size) {
            "Type parameter names must be unique."
        }
        require(namedPresentations.keys.none(String::isBlank)) { "Named presentation names must not be blank." }
    }
}

private val ResolvedTypeRef.displayName: String
    get() =
        when (val typeId = id) {
            TypeId.Option -> "Option"
            TypeId.Some -> "Some"
            TypeId.None -> "None"
            is TypeId.Qualified -> typeId.name
        }

@Serializable
data class TypeCatalog(
    val definitions: List<TypeDefinition>,
) {
    init {
        require(definitions.map(TypeDefinition::id).distinct().size == definitions.size) {
            "Type definition identities must be unique."
        }
    }
}

/** A closed catalog graph rooted at one expression and containing every nominal definition needed to interpret it. */
@Serializable
data class TypeGraph(
    val root: TypeExpression,
    val definitions: List<TypeDefinition>,
) {
    init {
        require(definitions.map(TypeDefinition::id).distinct().size == definitions.size) {
            "Type graph definition identities must be unique."
        }
    }
}

private fun validateLengths(
    minimum: Int?,
    maximum: Int?,
) {
    require(minimum == null || minimum >= 0) { "Minimum length must not be negative." }
    require(maximum == null || maximum >= 0) { "Maximum length must not be negative." }
    require(minimum == null || maximum == null || minimum <= maximum) { "Minimum length must not exceed maximum length." }
}
