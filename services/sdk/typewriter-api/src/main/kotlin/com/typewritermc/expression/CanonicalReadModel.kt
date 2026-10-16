package com.typewritermc.expression

import com.typewritermc.authoring.ItemId
import com.typewritermc.checking.CatalogGeneration
import com.typewritermc.types.DataValue
import com.typewritermc.types.ListItem
import com.typewritermc.types.ScalarKind
import com.typewritermc.types.TypeDefinition
import com.typewritermc.types.TypeDefinitionId
import com.typewritermc.types.TypeUse
import com.typewritermc.types.catalog.DefaultCheckedCatalog
import com.typewritermc.types.catalog.Resolution
import com.typewritermc.types.catalog.ResolvedRepresentation
import java.math.BigInteger
import kotlin.reflect.KClass

/** Generated canonical field adapters deliberately provide no authoring mutation API. */
class CanonicalReadDescriptor(
    val nativeClass: KClass<*>,
    val definition: TypeDefinitionId,
    val fields: Map<String, (Any) -> Any?> = emptyMap(),
    val construct: ((Map<String, Any?>) -> Any)? = null,
    val unwrap: ((Any) -> Any?)? = null,
    val wrap: ((Any?) -> Any)? = null,
)

class CanonicalReadModel<T : Any> internal constructor(
    val type: TypeUse.Named,
    private val registry: CanonicalReadModelRegistry,
) {
    fun encode(value: T): DataValue.Named = registry.encode(value) as DataValue.Named

    @Suppress("UNCHECKED_CAST")
    fun decode(value: DataValue): T = registry.decode(value) as T
}

/** A finite generated expression schema set, separate from authored type discovery. */
open class CanonicalReadModelRegistry(
    val definitions: List<TypeDefinition>,
    descriptors: List<CanonicalReadDescriptor>,
) {
    private val native = descriptors.associateBy(CanonicalReadDescriptor::nativeClass)
    private val identities = descriptors.associateBy(CanonicalReadDescriptor::definition)
    val catalog = DefaultCheckedCatalog(CatalogGeneration("canonical.read.v1"), definitions)

    fun owns(id: TypeDefinitionId): Boolean = id in identities

    fun supports(use: TypeUse): Boolean =
        when (use) {
            is TypeUse.Named -> owns(use.definition) || use.arguments.any(::supports)
            is TypeUse.Nullable -> supports(use.value)
            is TypeUse.Scalar -> false
        }

    fun <T : Any> model(type: KClass<T>): CanonicalReadModel<T> =
        CanonicalReadModel(TypeUse.Named(requireNotNull(native[type]).definition), this)

    fun encode(
        value: Any?,
        path: List<String> = emptyList(),
        consumeStep: () -> Unit = {},
        consumeItems: (Int) -> Unit = {},
        depth: Int = 0,
    ): DataValue {
        require(depth <= PortableExpressionLimits.MAX_DEPTH) { "The canonical projection exceeded its depth limit." }
        consumeStep()
        if (path.isNotEmpty()) {
            if (value == null) return DataValue.Unfilled
            val descriptor = requireNotNull(native[value::class]) { "Unknown canonical model ${value::class}." }
            val getter = requireNotNull(descriptor.fields[path.first()]) { "Unknown canonical field ${path.first()}." }
            return encode(getter(value), path.drop(1), consumeStep, consumeItems, depth + 1)
        }
        return when (value) {
            null -> {
                DataValue.Null
            }

            Unit -> {
                DataValue.Unit
            }

            is String -> {
                DataValue.StringValue(value)
            }

            is Boolean -> {
                DataValue.Boolean(value)
            }

            is Byte -> {
                DataValue.Integer(value.toLong().toBigInteger())
            }

            is Short -> {
                DataValue.Integer(value.toLong().toBigInteger())
            }

            is Int -> {
                DataValue.Integer(value.toBigInteger())
            }

            is Long -> {
                DataValue.Integer(value.toBigInteger())
            }

            is UInt -> {
                DataValue.Integer(value.toString().toBigInteger())
            }

            is ULong -> {
                DataValue.Integer(value.toString().toBigInteger())
            }

            is Float -> {
                DataValue.Float(value.toDouble())
            }

            is Double -> {
                DataValue.Float(value)
            }

            is Iterable<*> -> {
                val items = value.toList()
                consumeItems(items.size)
                val encoded =
                    items.mapIndexed { index, item ->
                        ListItem(
                            ItemId("canonical:$index"),
                            encode(
                                item,
                                consumeStep = consumeStep,
                                consumeItems = consumeItems,
                                depth =
                                    depth + 1,
                            ),
                        )
                    }
                if (value is Set<*>) DataValue.SetValue(encoded) else DataValue.ListValue(encoded)
            }

            else -> {
                val descriptor = requireNotNull(native[value::class]) { "Unknown canonical model ${value::class}." }
                val representation = ready(TypeUse.Named(descriptor.definition)).schema.representation
                val payload =
                    when (representation) {
                        is ResolvedRepresentation.Record -> {
                            DataValue.Record(
                                descriptor.fields.mapValues { (_, getter) ->
                                    encode(
                                        getter(value),
                                        consumeStep = consumeStep,
                                        consumeItems = consumeItems,
                                        depth =
                                            depth + 1,
                                    )
                                },
                            )
                        }

                        is ResolvedRepresentation.Enumeration -> {
                            DataValue.EnumCase(descriptor.unwrap!!(value) as String)
                        }

                        else -> {
                            encode(descriptor.unwrap!!(value), consumeStep = consumeStep, consumeItems = consumeItems, depth = depth + 1)
                        }
                    }
                DataValue.Named(TypeUse.Named(descriptor.definition), payload)
            }
        }
    }

    fun decode(
        value: DataValue,
        expected: TypeUse? = null,
        depth: Int = 0,
    ): Any? {
        require(depth <= PortableExpressionLimits.MAX_DEPTH) { "The canonical value exceeded its depth limit." }
        return when (value) {
            is DataValue.Named -> {
                val descriptor = requireNotNull(identities[value.actualType.definition]) { "Unknown canonical type." }
                val checked = ready(value.actualType)
                when (val representation = checked.schema.representation) {
                    is ResolvedRepresentation.Record -> {
                        val record = value.payload as DataValue.Record
                        val fields =
                            checked.schema.fields.associate { field ->
                                field.key to
                                    decode(record.fields.getValue(field.key), field.type, depth + 1)
                            }
                        requireNotNull(descriptor.construct) { "A canonical abstract value needs its concrete type." }(fields)
                    }

                    is ResolvedRepresentation.Enumeration -> {
                        descriptor.wrap!!((value.payload as DataValue.EnumCase).key)
                    }

                    else -> {
                        descriptor.wrap!!(
                            decode(
                                value.payload,
                                TypeUse.Scalar((representation as ResolvedRepresentation.Scalar).kind),
                                depth + 1,
                            ),
                        )
                    }
                }
            }

            DataValue.Null -> {
                null
            }

            DataValue.Unit -> {
                Unit
            }

            is DataValue.StringValue -> {
                value.value
            }

            is DataValue.Boolean -> {
                value.value
            }

            is DataValue.Integer -> {
                val kind = (expected as? TypeUse.Scalar)?.kind as? ScalarKind.Integer
                when (kind?.width?.bits) {
                    8 -> value.value.toByte()
                    16 -> value.value.toShort()
                    32 -> value.value.toInt()
                    else -> value.value.toLong()
                }
            }

            is DataValue.Float -> {
                if (((expected as? TypeUse.Scalar)?.kind as? ScalarKind.Float)?.width?.name ==
                    "FLOAT_32"
                ) {
                    value.value.toFloat()
                } else {
                    value.value
                }
            }

            is DataValue.EnumCase -> {
                value.key
            }

            is DataValue.ListValue -> {
                value.items.map { decode(it.value, depth = depth + 1) }
            }

            is DataValue.SetValue -> {
                value.items.mapTo(linkedSetOf()) { decode(it.value, depth = depth + 1) }
            }

            else -> {
                error("The value is not a canonical read model.")
            }
        }
    }

    private fun ready(use: TypeUse) =
        (catalog.resolve(use) as? Resolution.Ready)?.value ?: error("Canonical read schema is unavailable: $use")
}
