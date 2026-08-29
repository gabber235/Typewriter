@file:OptIn(kotlin.time.ExperimentalTime::class)

package com.typewritermc.types.skir

import com.typewritermc.types.BuiltinTypeId
import com.typewritermc.types.ConversionId
import com.typewritermc.types.DataValue
import com.typewritermc.types.DeclaredTypeId
import com.typewritermc.types.FloatWidth
import com.typewritermc.types.IntegerWidth
import com.typewritermc.types.NominalTypeKind
import com.typewritermc.types.PresentationId
import com.typewritermc.types.ResolvedTypeRef
import com.typewritermc.types.TypeCatalog
import com.typewritermc.types.TypeDefinition
import com.typewritermc.types.TypeExpression
import com.typewritermc.types.TypeField
import com.typewritermc.types.TypeId
import com.typewritermc.types.TypeParameter
import com.typewritermc.types.TypeVariance
import java.math.BigInteger
import skirout.editor.v1.type_catalog.BuiltinTypeId as SkirBuiltinTypeId
import skirout.editor.v1.type_catalog.CollectionConstraints as SkirCollectionConstraints
import skirout.editor.v1.type_catalog.ConversionId as SkirConversionId
import skirout.editor.v1.type_catalog.FloatWidth as SkirFloatWidth
import skirout.editor.v1.type_catalog.IntegerWidth as SkirIntegerWidth
import skirout.editor.v1.type_catalog.NamedPresentation as SkirNamedPresentation
import skirout.editor.v1.type_catalog.NumericConstraints as SkirNumericConstraints
import skirout.editor.v1.type_catalog.PresentationId as SkirPresentationId
import skirout.editor.v1.type_catalog.RecordField as SkirRecordField
import skirout.editor.v1.type_catalog.ResolvedTypeRef as SkirResolvedTypeRef
import skirout.editor.v1.type_catalog.TypeCatalog as SkirTypeCatalog
import skirout.editor.v1.type_catalog.TypeDefinition as SkirTypeDefinition
import skirout.editor.v1.type_catalog.TypeDefinitionKind as SkirTypeDefinitionKind
import skirout.editor.v1.type_catalog.TypeExpression as SkirTypeExpression
import skirout.editor.v1.type_catalog.TypeId as SkirTypeId
import skirout.editor.v1.type_catalog.TypeParameter as SkirTypeParameter
import skirout.editor.v1.type_catalog.TypeVariance as SkirTypeVariance

/** Converts portable Typewriter catalog values to and from generated Skir values. */
object SkirTypeCodec {
    fun encode(catalog: TypeCatalog): SkirConversionResult<SkirTypeCatalog> =
        captureSkirConversion {
            SkirTypeCatalog(definitions = catalog.definitions.mapIndexed { index, value -> at("definition $index") { encode(value) } })
        }

    fun decode(catalog: SkirTypeCatalog): SkirConversionResult<TypeCatalog> =
        captureSkirConversion {
            TypeCatalog(catalog.definitions.mapIndexed { index, value -> at("definition $index") { decode(value) } })
        }

    fun encode(expression: TypeExpression): SkirConversionResult<SkirTypeExpression> = captureSkirConversion { encode(expression) }

    fun decode(expression: SkirTypeExpression): SkirConversionResult<TypeExpression> = captureSkirConversion { decode(expression) }

    fun encode(reference: ResolvedTypeRef): SkirConversionResult<SkirResolvedTypeRef> = captureSkirConversion { encode(reference) }

    fun decode(reference: SkirResolvedTypeRef): SkirConversionResult<ResolvedTypeRef> = captureSkirConversion { decode(reference) }
}

private fun ConversionScope.encode(definition: TypeDefinition): SkirTypeDefinition =
    SkirTypeDefinition(
        displayName = definition.displayName,
        parameters = definition.parameters.mapIndexed { index, value -> at("parameter $index") { encode(value) } },
        directParents = definition.parents.mapIndexed { index, value -> at("parent $index") { encode(value) } },
        representation = at("representation") { encode(definition.representation) },
        typeId = encode(definition.id.id),
        revision = definition.id.revision,
        kind =
            when (definition.kind) {
                NominalTypeKind.CONCRETE -> SkirTypeDefinitionKind.CONCRETE
                NominalTypeKind.OPEN_ABSTRACT -> SkirTypeDefinitionKind.OPEN_ABSTRACT
                NominalTypeKind.SEALED_ABSTRACT -> SkirTypeDefinitionKind.SEALED_ABSTRACT
            },
        defaultPresentationId = definition.defaultPresentationId?.let(::encode),
        namedPresentations =
            definition.namedPresentations.toSortedMap().map { (name, id) ->
                SkirNamedPresentation(name = name, presentationId = encode(id))
            },
        outgoingConversionIds = definition.outgoingConversionIds.map(::encode),
    )

private fun ConversionScope.decode(definition: SkirTypeDefinition): TypeDefinition {
    val id = ResolvedTypeRef(decode(definition.typeId), definition.revision)
    return TypeDefinition(
        id = id,
        kind =
            when (definition.kind) {
                SkirTypeDefinitionKind.CONCRETE -> NominalTypeKind.CONCRETE
                SkirTypeDefinitionKind.OPEN_ABSTRACT -> NominalTypeKind.OPEN_ABSTRACT
                SkirTypeDefinitionKind.SEALED_ABSTRACT -> NominalTypeKind.SEALED_ABSTRACT
                else -> fail("Unknown Skir nominal type kind.")
            },
        representation = at("representation") { decode(definition.representation) },
        parameters = definition.parameters.mapIndexed { index, value -> at("parameter $index") { decode(value) } },
        parents = definition.directParents.mapIndexed { index, value -> at("parent $index") { decode(value) } },
        defaultPresentationId = definition.defaultPresentationId?.let(::decode),
        namedPresentations =
            definition.namedPresentations.associate { value -> value.name to decode(value.presentationId) },
        displayName = definition.displayName,
        outgoingConversionIds = definition.outgoingConversionIds.map(::decode),
    )
}

private fun ConversionScope.encode(parameter: TypeParameter): SkirTypeParameter =
    SkirTypeParameter(
        name = parameter.name,
        variance =
            when (parameter.variance) {
                TypeVariance.INVARIANT -> SkirTypeVariance.INVARIANT
                TypeVariance.COVARIANT -> SkirTypeVariance.COVARIANT
                TypeVariance.CONTRAVARIANT -> SkirTypeVariance.CONTRAVARIANT
            },
        upperBounds = parameter.upperBounds.mapIndexed { index, value -> at("bound $index") { encode(value) } },
    )

private fun ConversionScope.decode(parameter: SkirTypeParameter): TypeParameter =
    TypeParameter(
        name = parameter.name,
        variance =
            when (parameter.variance) {
                SkirTypeVariance.INVARIANT -> TypeVariance.INVARIANT
                SkirTypeVariance.COVARIANT -> TypeVariance.COVARIANT
                SkirTypeVariance.CONTRAVARIANT -> TypeVariance.CONTRAVARIANT
                else -> fail("Unknown Skir type variance.")
            },
        upperBounds = parameter.upperBounds.mapIndexed { index, value -> at("bound $index") { decode(value) } },
    )

private fun ConversionScope.encode(expression: TypeExpression): SkirTypeExpression =
    when (expression) {
        TypeExpression.Any -> {
            SkirTypeExpression.ANY
        }

        TypeExpression.Unit -> {
            SkirTypeExpression.UNIT
        }

        TypeExpression.Boolean -> {
            SkirTypeExpression.BOOLEAN
        }

        is TypeExpression.StringType -> {
            if (expression.patterns.size > 1) fail("Skir supports at most one string pattern.")
            SkirTypeExpression.createString(
                minimumLength = expression.minimumLength,
                maximumLength = expression.maximumLength,
                pattern = expression.patterns.singleOrNull(),
                allowedValues = expression.allowedValues,
            )
        }

        is TypeExpression.Bytes -> {
            SkirTypeExpression.createBytes(
                minimumLength = expression.minimumLength,
                maximumLength = expression.maximumLength,
                uniqueItems = false,
            )
        }

        is TypeExpression.Integer -> {
            encodeInteger(expression)
        }

        is TypeExpression.Float -> {
            SkirTypeExpression.createFloat(
                width = if (expression.width == FloatWidth.FLOAT_32) SkirFloatWidth.THIRTY_TWO_BITS else SkirFloatWidth.SIXTY_FOUR_BITS,
                constraints = expression.numericConstraints,
            )
        }

        is TypeExpression.Decimal -> {
            if (expression.scale != null) fail("Skir does not represent decimal scale.")
            SkirTypeExpression.createDecimal(
                minimum = expression.minimum,
                minimumInclusive = expression.minimumInclusive,
                maximum = expression.maximum,
                maximumInclusive = expression.maximumInclusive,
                multipleOf = expression.multipleOf,
            )
        }

        is TypeExpression.Timestamp -> {
            if (expression.minimum != null || expression.maximum != null) fail("Skir does not represent timestamp bounds.")
            SkirTypeExpression.TIMESTAMP
        }

        is TypeExpression.Duration -> {
            if (expression.minimum != null || expression.maximum != null) fail("Skir does not represent duration bounds.")
            SkirTypeExpression.DURATION
        }

        is TypeExpression.Enumeration -> {
            SkirTypeExpression.createEnumType(
                valueType = at("enum value type") { encode(expression.valueType) },
                canonicalValues = expression.values.mapIndexed { index, value -> at("enum value $index") { encodeDataValue(value) } },
            )
        }

        is TypeExpression.ListType -> {
            SkirTypeExpression.createList(
                element = at("list element") { encode(expression.element) },
                constraints =
                    SkirCollectionConstraints(
                        minimumLength = expression.minimumLength,
                        maximumLength = expression.maximumLength,
                        uniqueItems = expression.unique,
                    ),
            )
        }

        is TypeExpression.MapType -> {
            SkirTypeExpression.createMap(
                key = at("map key") { encode(expression.key) },
                value = at("map value") { encode(expression.value) },
                constraints =
                    SkirCollectionConstraints(
                        minimumLength = expression.minimumLength,
                        maximumLength = expression.maximumLength,
                        uniqueItems = false,
                    ),
            )
        }

        is TypeExpression.Record -> {
            SkirTypeExpression.createRecord(
                fields =
                    expression.fields.map { field ->
                        SkirRecordField(
                            name = field.name,
                            valueType = at(field.name) { encode(field.type) },
                            initializer = field.initialValue?.let { at("${field.name} initializer") { encodeDataValue(it) } },
                        )
                    },
                closed = expression.closed,
            )
        }

        is TypeExpression.Named -> {
            SkirTypeExpression.NamedWrapper(encode(expression.reference))
        }

        is TypeExpression.Parameter -> {
            SkirTypeExpression.ParameterWrapper(expression.name)
        }
    }

private fun ConversionScope.decode(expression: SkirTypeExpression): TypeExpression =
    when (expression) {
        SkirTypeExpression.ANY -> {
            TypeExpression.Any
        }

        SkirTypeExpression.UNIT -> {
            TypeExpression.Unit
        }

        SkirTypeExpression.BOOLEAN -> {
            TypeExpression.Boolean
        }

        SkirTypeExpression.TIMESTAMP -> {
            TypeExpression.Timestamp()
        }

        SkirTypeExpression.DURATION -> {
            TypeExpression.Duration()
        }

        is SkirTypeExpression.StringWrapper -> {
            TypeExpression.StringType(
                minimumLength = expression.value.minimumLength,
                maximumLength = expression.value.maximumLength,
                patterns = listOfNotNull(expression.value.pattern),
                allowedValues = expression.value.allowedValues,
            )
        }

        is SkirTypeExpression.BytesWrapper -> {
            TypeExpression.Bytes(expression.value.minimumLength, expression.value.maximumLength)
        }

        is SkirTypeExpression.SignedIntegerWrapper -> {
            decodeInteger(expression.value, signed = true)
        }

        is SkirTypeExpression.UnsignedIntegerWrapper -> {
            decodeInteger(expression.value, signed = false)
        }

        is SkirTypeExpression.FloatWrapper -> {
            TypeExpression.Float(
                width =
                    when (expression.value.width) {
                        SkirFloatWidth.THIRTY_TWO_BITS -> FloatWidth.FLOAT_32
                        SkirFloatWidth.SIXTY_FOUR_BITS -> FloatWidth.FLOAT_64
                        else -> fail("Unknown Skir float width.")
                    },
                minimum =
                    expression.value.constraints.minimum
                        ?.toDoubleOrNull() ?: invalidNumber(expression.value.constraints.minimum),
                maximum =
                    expression.value.constraints.maximum
                        ?.toDoubleOrNull() ?: invalidNumber(expression.value.constraints.maximum),
                minimumInclusive = expression.value.constraints.minimumInclusive,
                maximumInclusive = expression.value.constraints.maximumInclusive,
                multipleOf =
                    expression.value.constraints.multipleOf
                        ?.toDoubleOrNull()
                        ?: invalidNumber(expression.value.constraints.multipleOf),
            )
        }

        is SkirTypeExpression.DecimalWrapper -> {
            TypeExpression.Decimal(
                minimum = expression.value.minimum,
                maximum = expression.value.maximum,
                minimumInclusive = expression.value.minimumInclusive,
                maximumInclusive = expression.value.maximumInclusive,
                multipleOf = expression.value.multipleOf,
            )
        }

        is SkirTypeExpression.ListWrapper -> {
            TypeExpression.ListType(
                element = at("list element") { decode(expression.value.element) },
                minimumLength = expression.value.constraints.minimumLength,
                maximumLength = expression.value.constraints.maximumLength,
                unique = expression.value.constraints.uniqueItems,
            )
        }

        is SkirTypeExpression.MapWrapper -> {
            TypeExpression.MapType(
                key = at("map key") { decode(expression.value.key) },
                value = at("map value") { decode(expression.value.value) },
                minimumLength = expression.value.constraints.minimumLength,
                maximumLength = expression.value.constraints.maximumLength,
            )
        }

        is SkirTypeExpression.RecordWrapper -> {
            TypeExpression.Record(
                fields =
                    expression.value.fields.map { field ->
                        TypeField(
                            name = field.name,
                            type = at(field.name) { decode(field.valueType) },
                            initialValue = field.initializer?.let { at("${field.name} initializer") { decodeDataValue(it) } },
                        )
                    },
                closed = expression.value.closed,
            )
        }

        is SkirTypeExpression.EnumTypeWrapper -> {
            TypeExpression.Enumeration(
                valueType = at("enum value type") { decode(expression.value.valueType) },
                values = expression.value.canonicalValues.mapIndexed { index, value -> at("enum value $index") { decodeDataValue(value) } },
            )
        }

        is SkirTypeExpression.ParameterWrapper -> {
            TypeExpression.Parameter(expression.value)
        }

        is SkirTypeExpression.NamedWrapper -> {
            TypeExpression.Named(decode(expression.value))
        }

        else -> {
            fail("Unknown Skir type expression.")
        }
    }

private fun ConversionScope.encodeInteger(expression: TypeExpression.Integer): SkirTypeExpression {
    val width =
        when (expression.width.bits) {
            8 -> SkirIntegerWidth.EIGHT_BITS
            16 -> SkirIntegerWidth.SIXTEEN_BITS
            32 -> SkirIntegerWidth.THIRTY_TWO_BITS
            else -> SkirIntegerWidth.SIXTY_FOUR_BITS
        }
    return if (expression.width.signed) {
        SkirTypeExpression.createSignedInteger(width = width, constraints = expression.numericConstraints)
    } else {
        SkirTypeExpression.createUnsignedInteger(width = width, constraints = expression.numericConstraints)
    }
}

private fun ConversionScope.decodeInteger(
    value: skirout.editor.v1.type_catalog.IntegerType,
    signed: Boolean,
): TypeExpression.Integer {
    val width =
        when (value.width) {
            SkirIntegerWidth.EIGHT_BITS -> if (signed) IntegerWidth.SIGNED_8 else IntegerWidth.UNSIGNED_8
            SkirIntegerWidth.SIXTEEN_BITS -> if (signed) IntegerWidth.SIGNED_16 else IntegerWidth.UNSIGNED_16
            SkirIntegerWidth.THIRTY_TWO_BITS -> if (signed) IntegerWidth.SIGNED_32 else IntegerWidth.UNSIGNED_32
            SkirIntegerWidth.SIXTY_FOUR_BITS -> if (signed) IntegerWidth.SIGNED_64 else IntegerWidth.UNSIGNED_64
            else -> fail("Unknown Skir integer width.")
        }
    return TypeExpression.Integer(
        width = width,
        minimum = value.constraints.minimum?.toBigIntegerOrNull() ?: invalidInteger(value.constraints.minimum),
        maximum = value.constraints.maximum?.toBigIntegerOrNull() ?: invalidInteger(value.constraints.maximum),
        minimumInclusive = value.constraints.minimumInclusive,
        maximumInclusive = value.constraints.maximumInclusive,
        multipleOf = value.constraints.multipleOf?.toBigIntegerOrNull() ?: invalidInteger(value.constraints.multipleOf),
    )
}

private val TypeExpression.Integer.numericConstraints: SkirNumericConstraints
    get() =
        SkirNumericConstraints(
            minimum = minimum?.toString(),
            minimumInclusive = minimumInclusive,
            maximum = maximum?.toString(),
            maximumInclusive = maximumInclusive,
            multipleOf = multipleOf?.toString(),
        )

private val TypeExpression.Float.numericConstraints: SkirNumericConstraints
    get() =
        SkirNumericConstraints(
            minimum = minimum?.toString(),
            minimumInclusive = minimumInclusive,
            maximum = maximum?.toString(),
            maximumInclusive = maximumInclusive,
            multipleOf = multipleOf?.toString(),
        )

private fun ConversionScope.encode(reference: ResolvedTypeRef): SkirResolvedTypeRef =
    SkirResolvedTypeRef(
        typeId = encode(reference.id),
        revision = reference.revision,
        arguments = reference.arguments.mapIndexed { index, value -> at("argument $index") { encode(value) } },
    )

private fun ConversionScope.decode(reference: SkirResolvedTypeRef): ResolvedTypeRef =
    ResolvedTypeRef(
        id = decode(reference.typeId),
        revision = reference.revision,
        arguments = reference.arguments.mapIndexed { index, value -> at("argument $index") { decode(value) } },
    )

private fun encode(id: TypeId): SkirTypeId =
    when (id) {
        is TypeId.Builtin -> {
            SkirTypeId.BuiltinWrapper(
                when (id.id) {
                    BuiltinTypeId.OPTION -> SkirBuiltinTypeId.OPTION
                    BuiltinTypeId.SOME -> SkirBuiltinTypeId.SOME
                    BuiltinTypeId.NONE -> SkirBuiltinTypeId.NONE
                },
            )
        }

        is TypeId.Declared -> {
            SkirTypeId.createDeclared(value = id.id.toString())
        }

        is TypeId.Qualified -> {
            SkirTypeId.createQualified(namespace = id.namespace, name = id.name)
        }
    }

private fun ConversionScope.decode(id: SkirTypeId): TypeId =
    when (id) {
        is SkirTypeId.BuiltinWrapper -> {
            when (id.value) {
                SkirBuiltinTypeId.OPTION -> TypeId.Builtin(BuiltinTypeId.OPTION)
                SkirBuiltinTypeId.SOME -> TypeId.Builtin(BuiltinTypeId.SOME)
                SkirBuiltinTypeId.NONE -> TypeId.Builtin(BuiltinTypeId.NONE)
                else -> fail("Unknown Skir builtin type id.")
            }
        }

        is SkirTypeId.DeclaredWrapper -> {
            val declared = runCatching { DeclaredTypeId.parse(id.value.value) }.getOrElse { fail("Invalid declared type UUID.") }
            TypeId.Declared(declared)
        }

        is SkirTypeId.QualifiedWrapper -> {
            TypeId.Qualified(id.value.namespace, id.value.name)
        }

        else -> {
            fail("Unknown Skir type id.")
        }
    }

private fun encode(id: PresentationId) = SkirPresentationId(namespace = id.namespace, name = id.name)

private fun decode(id: SkirPresentationId) = PresentationId(namespace = id.namespace, name = id.name)

private fun encode(id: ConversionId) = SkirConversionId(namespace = id.namespace, name = id.name)

private fun decode(id: SkirConversionId) = ConversionId(namespace = id.namespace, name = id.name)

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

private fun ConversionScope.invalidInteger(source: String?): BigInteger? {
    if (source != null) fail("Invalid integer constraint $source.")
    return null
}

private fun ConversionScope.invalidNumber(source: String?): Double? {
    if (source != null) fail("Invalid numeric constraint $source.")
    return null
}
