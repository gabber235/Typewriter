package com.typewritermc.expression.operations

import com.typewritermc.authoring.CompletenessResult
import com.typewritermc.authoring.complete
import com.typewritermc.types.actualType
import com.typewritermc.types.bigInteger
import com.typewritermc.types.bits
import com.typewritermc.types.catalog.CheckedCatalog
import com.typewritermc.types.catalog.Resolution
import com.typewritermc.types.field
import com.typewritermc.types.fields
import com.typewritermc.types.signed
import com.typewritermc.types.use
import skirout.editor.v1.type_catalog.CollectionKind
import skirout.editor.v1.type_catalog.DataValue
import skirout.editor.v1.type_catalog.FloatWidth
import skirout.editor.v1.type_catalog.ListItem
import skirout.editor.v1.type_catalog.ResolvedRepresentation
import skirout.editor.v1.type_catalog.ScalarKind
import skirout.editor.v1.type_catalog.TypeUse
import java.math.BigInteger

/**
 * The type facts of one checked catalog, as typed operations see them at evaluation time.
 *
 * A named value is an instance of a type its actual type is readable as: the type itself, a nominal ancestor, or a
 * compatible generic application. A structural value (one an operation computed without a nominal wrapper) is an
 * instance when its shape fits the type's resolved representation, item by item. Null is an instance only of
 * nullable types, and unfilled data is an instance of nothing.
 */
class CatalogPortableTypes(
    private val catalog: CheckedCatalog,
) : PortableTypes {
    override fun isInstance(
        value: DataValue,
        type: TypeUse,
    ): Boolean = fits(value, type, validatePayloads = false)

    /** The case names of the enumeration [type] in declaration order; empty when [type] is not an enumeration. */
    override fun enumCases(type: TypeUse): List<String> {
        val resolved = catalog.resolve(type) as? Resolution.Ready ?: return emptyList()
        val enumeration = resolved.value.schema.representation as? ResolvedRepresentation.EnumerationWrapper ?: return emptyList()
        return enumeration.value.cases.map { it.key }
    }

    /**
     * Whether [value] is a complete instance of [type] whose every named payload the catalog admits for its actual
     * type, as content arriving from outside the evaluation must be.
     */
    override fun admits(
        value: DataValue,
        type: TypeUse,
    ): Boolean = fits(value, type, validatePayloads = true)

    private fun fits(
        value: DataValue,
        type: TypeUse,
        validatePayloads: Boolean,
    ): Boolean {
        if (value == DataValue.UNFILLED) return false
        if (type is TypeUse.NullableWrapper) return value == DataValue.NULL || fits(value, type.value.value, validatePayloads)
        if (value == DataValue.NULL) return false
        return when (type) {
            is TypeUse.ScalarWrapper -> {
                fitsScalar(value, type.value)
            }

            is TypeUse.NamedWrapper -> {
                if (value is DataValue.NamedWrapper) {
                    fitsNamed(
                        value,
                        type,
                        validatePayloads,
                    )
                } else {
                    fitsShape(value, type, validatePayloads)
                }
            }

            else -> {
                false
            }
        }
    }

    private fun fitsNamed(
        value: DataValue.NamedWrapper,
        type: TypeUse.NamedWrapper,
        validatePayloads: Boolean,
    ): Boolean {
        val actual = value.actualType.use
        if (actual != type && !catalog.isReadableAs(actual, type)) return false
        if (!validatePayloads) return true
        val resolved = catalog.resolve(actual) as? Resolution.Ready ?: return false
        return resolved.value.complete(value) is CompletenessResult.Complete
    }

    /** A structural value against the resolved representation of a named type. */
    private fun fitsShape(
        value: DataValue,
        type: TypeUse.NamedWrapper,
        validatePayloads: Boolean,
    ): Boolean {
        val resolved = catalog.resolve(type) as? Resolution.Ready ?: return false
        return when (val representation = resolved.value.schema.representation) {
            is ResolvedRepresentation.ScalarWrapper -> {
                fitsScalar(value, representation.value.kind)
            }

            is ResolvedRepresentation.SequenceWrapper -> {
                val items =
                    when (representation.value.kind) {
                        CollectionKind.LIST -> (value as? DataValue.ListValueWrapper)?.value?.items
                        CollectionKind.SET -> (value as? DataValue.SetValueWrapper)?.value?.items
                        else -> null
                    }
                items != null && items.allFit(representation.value.item, validatePayloads)
            }

            is ResolvedRepresentation.MappingWrapper -> {
                val rows = (value as? DataValue.MapValueWrapper)?.value?.rows
                rows != null &&
                    rows.all {
                        fits(it.key, representation.value.key, validatePayloads) &&
                            fits(it.value, representation.value.value, validatePayloads)
                    }
            }

            is ResolvedRepresentation.RecordWrapper -> {
                val record = value as? DataValue.RecordWrapper
                val fields = resolved.value.schema.fields
                record != null && !representation.value.abstract_ &&
                    record.fields.size == fields.size &&
                    fields.all { field -> record.field(field.key)?.let { fits(it, field.type, validatePayloads) } == true }
            }

            is ResolvedRepresentation.EnumerationWrapper -> {
                val case = (value as? DataValue.EnumCaseWrapper)?.value
                case != null && representation.value.cases.any { it.key == case }
            }

            is ResolvedRepresentation.LinkWrapper -> {
                (value as? DataValue.LinkWrapper)?.value?.endpoint == representation.value.endpoint
            }

            else -> {
                false
            }
        }
    }

    private fun List<ListItem>.allFit(
        type: TypeUse,
        validatePayloads: Boolean,
    ): Boolean = all { fits(it.value, type, validatePayloads) }
}

/** Whether a bare scalar has [kind], integers and floats within the kind's width. */
private fun fitsScalar(
    value: DataValue,
    kind: ScalarKind,
): Boolean =
    when (kind) {
        ScalarKind.UNIT -> {
            value == DataValue.UNIT
        }

        ScalarKind.BOOLEAN -> {
            value is DataValue.BooleanWrapper
        }

        ScalarKind.TEXT -> {
            value is DataValue.StringValueWrapper
        }

        ScalarKind.BYTES -> {
            value is DataValue.BytesWrapper
        }

        ScalarKind.DECIMAL -> {
            value is DataValue.DecimalWrapper
        }

        ScalarKind.TIMESTAMP -> {
            value is DataValue.TimestampWrapper
        }

        ScalarKind.DURATION -> {
            value is DataValue.DurationWrapper
        }

        is ScalarKind.IntegerWrapper -> {
            value is DataValue.IntegerWrapper && value.bigInteger in integerRange(kind)
        }

        is ScalarKind.FloatWrapper -> {
            value is DataValue.FloatWrapper &&
                (kind.value.width != FloatWidth.THIRTY_TWO || value.value.toFloat().toDouble() == value.value)
        }

        else -> {
            false
        }
    }

private fun integerRange(kind: ScalarKind.IntegerWrapper): ClosedRange<BigInteger> {
    val width = kind.value.width
    return if (width.signed) {
        BigInteger.ONE.shiftLeft(width.bits - 1).negate()..BigInteger.ONE.shiftLeft(width.bits - 1) - BigInteger.ONE
    } else {
        BigInteger.ZERO..BigInteger.ONE.shiftLeft(width.bits) - BigInteger.ONE
    }
}
