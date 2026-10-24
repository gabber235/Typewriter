package com.typewritermc.expression

import com.typewritermc.types.TypeUse
import com.typewritermc.types.skir.SkirTypeCodec
import com.typewritermc.types.skir.getOrThrow
import skirout.editor.v1.expression.ExpressionMappingType
import skirout.editor.v1.expression.ExpressionType
import skirout.editor.v1.expression.ExpressionValueType

/** Describes a declared value while keeping derived collections and lexical entries structural. */
fun nominalExpressionType(
    use: TypeUse,
    mayBeMissing: Boolean = false,
): ExpressionType =
    ExpressionType(value = ExpressionValueType.NominalWrapper(SkirTypeCodec.encode(use).getOrThrow()), mayBeMissing = mayBeMissing)

fun ExpressionType.nominalUseOrNull(): TypeUse? =
    (value as? ExpressionValueType.NominalWrapper)?.value?.let { use ->
        when (val decoded = SkirTypeCodec.decode(use)) {
            is com.typewritermc.types.skir.SkirConversionResult.Success -> decoded.value
            is com.typewritermc.types.skir.SkirConversionResult.Failure -> null
        }
    }

fun listExpressionType(
    item: ExpressionType,
    mayBeMissing: Boolean = false,
): ExpressionType = ExpressionType(value = ExpressionValueType.ListWrapper(item), mayBeMissing = mayBeMissing)

fun mapExpressionType(
    key: ExpressionType,
    value: ExpressionType,
    mayBeMissing: Boolean = false,
): ExpressionType =
    ExpressionType(value = ExpressionValueType.MapWrapper(ExpressionMappingType(key = key, value = value)), mayBeMissing = mayBeMissing)

fun entryExpressionType(
    key: ExpressionType,
    value: ExpressionType,
    mayBeMissing: Boolean = false,
): ExpressionType =
    ExpressionType(value = ExpressionValueType.EntryWrapper(ExpressionMappingType(key = key, value = value)), mayBeMissing = mayBeMissing)
