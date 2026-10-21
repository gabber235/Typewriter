package com.typewritermc.expression

import com.typewritermc.types.isValid
import skirout.editor.v1.expression.ExpressionMappingType
import skirout.editor.v1.expression.ExpressionType
import skirout.editor.v1.expression.ExpressionValueType
import skirout.editor.v1.type_catalog.TypeUse

/** Describes a declared value while keeping derived collections and lexical entries structural. */
fun nominalExpressionType(
    use: TypeUse,
    mayBeMissing: Boolean = false,
): ExpressionType = ExpressionType(value = ExpressionValueType.NominalWrapper(use), mayBeMissing = mayBeMissing)

/** The declared type of a nominal expression type, or null for a structural type or an invalid nominal one. */
fun ExpressionType.nominalUseOrNull(): TypeUse? = (value as? ExpressionValueType.NominalWrapper)?.value?.takeIf { it.isValid }

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
