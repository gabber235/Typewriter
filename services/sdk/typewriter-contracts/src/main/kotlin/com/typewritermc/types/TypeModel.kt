package com.typewritermc.types

import kotlinx.serialization.ExperimentalSerializationApi
import kotlinx.serialization.KSerializer
import kotlinx.serialization.MetaSerializable
import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable
import kotlinx.serialization.decodeFromString
import kotlinx.serialization.descriptors.PrimitiveKind
import kotlinx.serialization.descriptors.PrimitiveSerialDescriptor
import kotlinx.serialization.descriptors.SerialDescriptor
import kotlinx.serialization.encodeToString
import kotlinx.serialization.encoding.Decoder
import kotlinx.serialization.encoding.Encoder
import kotlinx.serialization.json.Json
import java.math.BigInteger
import kotlin.time.Duration
import kotlin.time.Instant
import kotlin.uuid.Uuid

/**
 * Provides a persistent nominal identity that survives Kotlin class renames and deployment changes.
 *
 * [parse] accepts hexadecimal UUID text with or without separators. Rendering uses hexadecimal UUID form; callers
 * should compare typed identities rather than input spelling.
 */
@JvmInline
@Serializable(with = DeclaredTypeIdSerializer::class)
@TypewriterString
value class DeclaredTypeId(
    val value: Uuid,
) {
    companion object {
        fun parse(value: String): DeclaredTypeId = DeclaredTypeId(Uuid.parse(value))
    }

    override fun toString(): String = value.toHexString()
}

/**
 * Opts a concrete type into default Kotlin serialization, generated structural metadata, and runtime prototypes.
 *
 * The id is persistent content identity, not a class name. Preserve it across refactors and evolve the revision
 * deliberately when stored shape changes.
 */
@OptIn(ExperimentalSerializationApi::class)
@MetaSerializable
@Target(AnnotationTarget.CLASS)
@Retention(AnnotationRetention.BINARY)
annotation class TypewriterType(
    val id: String,
    val revision: Int = 1,
)

/** Declares that a Kotlin type uses a logical string serializer in Typewriter data. */
@Target(AnnotationTarget.CLASS)
@Retention(AnnotationRetention.BINARY)
annotation class TypewriterString

/** Identifies the option family built into the Typewriter type model. */
@Serializable
enum class BuiltinTypeId {
    OPTION,
    SOME,
    NONE,
}

/**
 * Distinguishes built in, persistently declared, and qualified nominal identities.
 *
 * Declared identities decouple stored content from Kotlin names. Qualified identities describe named types such as
 * abstract contracts. A revision and generic arguments belong to [ResolvedTypeRef], not this identity.
 */
@Serializable
sealed interface TypeId {
    @Serializable
    @SerialName("builtin")
    data class Builtin(
        val id: BuiltinTypeId,
    ) : TypeId

    @Serializable
    @SerialName("declared")
    data class Declared(
        val id: DeclaredTypeId,
    ) : TypeId

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

    companion object {
        /** Built in identity for the generic option type. */
        val Option: TypeId = Builtin(BuiltinTypeId.OPTION)

        /** Built in identity for a present option value. */
        val Some: TypeId = Builtin(BuiltinTypeId.SOME)

        /** Built in identity for an absent option value. */
        val None: TypeId = Builtin(BuiltinTypeId.NONE)
    }
}

/**
 * Identifies a particular schema revision and optional generic instantiation.
 *
 * Revisions must be positive. Definitions use references without arguments, while use sites may supply arguments;
 * consumers must apply the definition parameters when interpreting them.
 */
@Serializable(with = ResolvedTypeRefSerializer::class)
@TypewriterString
@TypewriterType(id = "8f96c94c17b946d788e0e5e7049c8536")
data class ResolvedTypeRef(
    val id: TypeId,
    val revision: Int,
    val arguments: List<TypeExpression> = emptyList(),
) {
    init {
        require(revision > 0) { "Type revision must be positive." }
    }

    /** Returns this reference with a copied list of generic arguments. */
    fun withArguments(arguments: Iterable<TypeExpression>) = copy(arguments = arguments.toList())
}

object ResolvedTypeRefSerializer : KSerializer<ResolvedTypeRef> {
    override val descriptor: SerialDescriptor = PrimitiveSerialDescriptor("ResolvedTypeRef", PrimitiveKind.STRING)

    override fun serialize(
        encoder: Encoder,
        value: ResolvedTypeRef,
    ) {
        encoder.encodeString(
            typeReferenceJson.encodeToString(
                ResolvedTypeRefSurrogate.serializer(),
                ResolvedTypeRefSurrogate(value.id, value.revision, value.arguments),
            ),
        )
    }

    override fun deserialize(decoder: Decoder): ResolvedTypeRef {
        val value = typeReferenceJson.decodeFromString(ResolvedTypeRefSurrogate.serializer(), decoder.decodeString())
        return ResolvedTypeRef(value.id, value.revision, value.arguments)
    }
}

@Serializable
private data class ResolvedTypeRefSurrogate(
    val id: TypeId,
    val revision: Int,
    val arguments: List<TypeExpression>,
)

private val typeReferenceJson = Json { classDiscriminator = "_kind" }

/** Describes the bit width and signedness of a portable integer expression. */
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

/** Describes the precision of a portable floating point expression. */
@Serializable
enum class FloatWidth {
    FLOAT_32,
    FLOAT_64,
}

/**
 * Describes portable value structure independently of Kotlin reflection, persistence, and wire frameworks.
 *
 * Named expressions refer into a catalog and parameters require substitution at use sites. Constraints are
 * metadata with local constructor checks; constructing an expression does not validate a corresponding
 * [DataValue].
 */
@Serializable
sealed interface TypeExpression {
    /** An unconstrained expression used when no structural representation is available. */
    @Serializable
    @SerialName("any")
    data object Any : TypeExpression

    /** The zero field value used for unit shaped data. */
    @Serializable
    @SerialName("unit")
    data object Unit : TypeExpression

    /** A portable Boolean expression. */
    @Serializable
    @SerialName("boolean")
    data object Boolean : TypeExpression

    /** A string expression with optional length, pattern, and enumeration constraints. */
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

    /** An integer expression whose bounds use arbitrary precision values before width validation. */
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

    /** A finite floating point expression with optional numeric constraints. */
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

    /** A decimal text expression whose canonical syntax is preserved without binary rounding. */
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

    /** An instant expression with optional temporal bounds. */
    @Serializable
    @SerialName("timestamp")
    data class Timestamp(
        val minimum: Instant? = null,
        val maximum: Instant? = null,
    ) : TypeExpression

    /** A duration expression with optional temporal bounds. */
    @Serializable
    @SerialName("duration")
    data class Duration(
        val minimum: kotlin.time.Duration? = null,
        val maximum: kotlin.time.Duration? = null,
    ) : TypeExpression

    /** An expression whose value must be one of the declared portable values. */
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

    /** A homogeneous ordered collection expression. */
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

    /** A collection expression that preserves typed keys and values as entries. */
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

    /** A named field expression, optionally allowing fields outside the declared set. */
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

    /** A reference to a catalog definition, including any generic arguments. */
    @Serializable
    @SerialName("named")
    data class Named(
        val reference: ResolvedTypeRef,
    ) : TypeExpression

    /** A resource address constrained by the nominal target type. */
    @Serializable
    @SerialName("reference")
    data class Reference(
        val target: ResolvedTypeRef,
    ) : TypeExpression

    /** A generic parameter placeholder resolved from its enclosing definition. */
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

/**
 * Defines a serialized record field and an optional editor initial value.
 *
 * The name is the serialized name, which may differ from the Kotlin property. An initial value is catalog
 * metadata, not evidence that a decoder supplies a missing field.
 */
@Serializable
data class TypeField(
    val name: String,
    val type: TypeExpression,
    val initialValue: DataValue? = null,
    val defaulted: Boolean = false,
) {
    init {
        require(name.isNotBlank()) { "Type field name must not be blank." }
    }
}

/** Controls how a nominal type parameter participates in subtype relationships. */
@Serializable
enum class TypeVariance {
    INVARIANT,
    COVARIANT,
    CONTRAVARIANT,
}

/** Defines whether a nominal type has a runtime representation or only contracts for descendants. */
@Serializable
enum class NominalTypeKind {
    CONCRETE,
    OPEN_ABSTRACT,
    SEALED_ABSTRACT,
}

/** Declares a generic parameter, its bounds, and variance in a type definition. */
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

/** Identifies a presentation by namespace and name. */
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

/** Identifies the semantic surface for which a presentation is selected. */
@Serializable
enum class PresentationRole {
    REFERENCE_SUMMARY,
    REFERENCE_OPTION,
    CATALOG_OPTION,
    AUTHORING_RESULT,
    PAGE_TILE,
    GRAPH_NODE,
    INSPECTOR_HEADER,
}

/** Addresses a nested value while retaining field, list, and map identity. */
@Serializable
data class DataPath(
    val segments: List<DataPathSegment> = emptyList(),
) {
    companion object {
        /** Creates a path to one record field. */
        fun field(name: String): DataPath = DataPath(listOf(DataPathSegment.Field(name)))
    }
}

/** One segment in a typed value path. */
@Serializable
sealed interface DataPathSegment {
    /** Selects a named record field. */
    @Serializable
    data class Field(
        val name: String,
    ) : DataPathSegment {
        init {
            require(name.isNotBlank()) { "Field path names must not be blank." }
        }
    }

    /** Selects an ordered collection item. */
    @Serializable
    data class Index(
        val index: Int,
    ) : DataPathSegment {
        init {
            require(index >= 0) { "Path indexes must not be negative." }
        }
    }

    /** Selects a map entry by its portable key. */
    @Serializable
    data class MapKey(
        val key: DataValue,
    ) : DataPathSegment
}

/** Closed reconciliation strategies understood by the shared editor. */
@Serializable
enum class FieldMergeStrategy {
    SET_MEMBERSHIP,
}

/** Associates one canonical field path with its shared reconciliation strategy. */
@Serializable
data class FieldMergePolicy(
    val path: DataPath,
    val strategy: FieldMergeStrategy,
) {
    init {
        require(path.segments.isNotEmpty()) { "Merge policy paths must not be empty." }
    }
}

/** Identifies a conversion offered from a type definition. */
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

/**
 * Declares a nominal schema, its generic parameters, inheritance, and editor associations.
 *
 * [id] must have no type arguments and parameter names must be unique. Catalog assembly may attach presentations
 * without changing the structural representation. Parent references describe subtype relationships; executable
 * codecs live in prototypes.
 */
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
    val rolePresentations: Map<PresentationRole, PresentationId> = emptyMap(),
    val fieldMergePolicies: List<FieldMergePolicy> = emptyList(),
    val declarationOwner: String = defaultDeclarationOwner(id),
) {
    init {
        require(id.arguments.isEmpty()) { "Type definition identity must not contain type arguments." }
        require(declarationOwner.isNotBlank()) { "Type declaration owner must not be blank." }
        require(parameters.map(TypeParameter::name).distinct().size == parameters.size) {
            "Type parameter names must be unique."
        }
        require(namedPresentations.keys.none(String::isBlank)) { "Named presentation names must not be blank." }
        require(fieldMergePolicies.map(FieldMergePolicy::path).distinct().size == fieldMergePolicies.size) {
            "Merge policy paths must be unique."
        }
    }
}

private fun defaultDeclarationOwner(id: ResolvedTypeRef): String =
    when (val typeId = id.id) {
        is TypeId.Builtin -> "builtin"
        is TypeId.Declared -> typeId.id.toString()
        is TypeId.Qualified -> typeId.namespace
    }

private val ResolvedTypeRef.displayName: String
    get() =
        when (val typeId = id) {
            is TypeId.Builtin -> {
                when (typeId.id) {
                    BuiltinTypeId.OPTION -> "Option"
                    BuiltinTypeId.SOME -> "Some"
                    BuiltinTypeId.NONE -> "None"
                }
            }

            is TypeId.Declared -> {
                typeId.id.toString()
            }

            is TypeId.Qualified -> {
                typeId.name
            }
        }

/**
 * Holds uniquely identified nominal definitions for discovery and editor interpretation.
 *
 * Construction checks duplicate identities, not graph closure. Subtype lookup follows known parents with cycle
 * protection, retains abstract descendants, and returns a stable ordering.
 */
@Serializable
data class TypeCatalog(
    val definitions: List<TypeDefinition>,
) {
    init {
        require(definitions.map(TypeDefinition::id).distinct().size == definitions.size) {
            "Type definition identities must be unique."
        }
    }

    /** Returns every direct and transitive subtype while retaining abstract descendants. */
    fun subtypesOf(target: ResolvedTypeRef): List<TypeDefinition> {
        val definitionsById = definitions.associateBy { it.id }
        return definitions
            .filter { it.isSubtypeOf(target, definitionsById, emptySet()) }
            .sortedBy { it.id.stableSortKey }
    }
}

private fun TypeDefinition.isSubtypeOf(
    target: ResolvedTypeRef,
    definitions: Map<ResolvedTypeRef, TypeDefinition>,
    visited: Set<ResolvedTypeRef>,
): Boolean {
    if (id in visited) return false
    if (parents.any { it.id == target.id && it.revision == target.revision }) return true
    val nextVisited = visited + id
    return parents.any { parent ->
        definitions[parent.copy(arguments = emptyList())]
            ?.isSubtypeOf(target, definitions, nextVisited) == true
    }
}

private val ResolvedTypeRef.stableSortKey: String
    get() = "$id:$revision:${arguments.joinToString()}"

/**
 * Packages a root expression with the nominal definitions needed to interpret it.
 *
 * Producers are responsible for graph closure. Construction only rejects duplicate definition identities;
 * consumers may still fail when a named dependency is absent.
 */
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

/**
 * Pairs a structural expression with its portable value for transport.
 *
 * Construction does not prove the value satisfies the expression or supply definitions for named types; the
 * receiving boundary must provide that context.
 */
@Serializable
data class TypedValueEnvelope(
    val rootType: TypeExpression,
    val rootValue: DataValue,
)

/** Cardinality exposed by one generated synchronized relation endpoint. */
@Serializable
enum class RelationCardinality {
    ONE,
    MANY,
}

/** Identifies which declared marker endpoint owns one typed field. */
@Serializable
enum class RelationEndpointSide {
    SOURCE,
    TARGET,
}

/** Maps one Kotlin endpoint property onto its ordinary authored reference path. */
@Serializable
data class RelationEndpointDefinition(
    val owner: ResolvedTypeRef,
    val path: DataPath,
    val side: RelationEndpointSide,
    val cardinality: RelationCardinality,
)

/**
 * Complete generated policy for one synchronized authored relationship.
 *
 * Either endpoint may be absent when only one side is declared. Assembly merges compatible partial definitions
 * and rejects conflicting marker identities, endpoint declarations, or deletion policy.
 */
@Serializable
data class RelationDefinition(
    val id: RelationId,
    val source: ResolvedTypeRef,
    val target: ResolvedTypeRef,
    val onSourceDelete: RelationDeletePolicy,
    val onTargetDelete: RelationDeletePolicy,
    val sourceEndpoint: RelationEndpointDefinition? = null,
    val targetEndpoint: RelationEndpointDefinition? = null,
) {
    init {
        require(sourceEndpoint == null || sourceEndpoint.side == RelationEndpointSide.SOURCE) {
            "Source relation endpoints must use the source side."
        }
        require(targetEndpoint == null || targetEndpoint.side == RelationEndpointSide.TARGET) {
            "Target relation endpoints must use the target side."
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
