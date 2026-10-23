package com.typewritermc.expression.operations

import com.typewritermc.types.named
import skirout.editor.v1.type_catalog.DataValue
import skirout.editor.v1.type_catalog.ListItem
import skirout.editor.v1.type_catalog.TypeUse

/** Realm's kernel of the enumeration operations; cases come from the catalog's type facts. */
internal object PortableEnumKernel : EnumKernel {
    override fun cases(
        eType: TypeUse,
        types: PortableTypes,
    ): List<ListItem> = positionalItems(types.enumCases(eType).map { case -> enumValue(eType, case) })

    override fun fromName(
        name: String,
        eType: TypeUse,
        types: PortableTypes,
    ): DataValue = if (name in types.enumCases(eType)) enumValue(eType, name) else DataValue.NULL

    private fun enumValue(
        type: TypeUse,
        case: String,
    ): DataValue {
        val named = type as? TypeUse.NamedWrapper ?: throw illTyped("An enumeration is a named type.")
        return DataValue.named(named.value, DataValue.EnumCaseWrapper(case))
    }
}
