package com.typewritermc.expression

import com.typewritermc.expression.operations.CatalogPortableTypes
import com.typewritermc.expression.operations.DateTimeFieldsDefinition
import com.typewritermc.expression.operations.NameStyleDefinition
import com.typewritermc.expression.operations.PluralCategoryDefinition
import com.typewritermc.expression.operations.PortableTypes
import com.typewritermc.expression.operations.RegexMatchDefinition
import com.typewritermc.expression.operations.RoundingModeDefinition
import com.typewritermc.expression.operations.SortDirectionDefinition
import com.typewritermc.expression.operations.UnicodeFormDefinition
import com.typewritermc.types.ResourceIdDefinition
import com.typewritermc.types.StandardTypes
import com.typewritermc.types.catalog.DefaultCheckedCatalog
import skirout.editor.v1.type_catalog.CatalogGeneration
import skirout.editor.v1.type_catalog.TypeDefinition

/** The catalog declarations of the operation library the manifest declares, which every expression may use. */
internal val LIBRARY_DEFINITIONS: List<TypeDefinition> =
    StandardTypes.definitions +
        listOf(
            RoundingModeDefinition.definition,
            SortDirectionDefinition.definition,
            UnicodeFormDefinition.definition,
            PluralCategoryDefinition.definition,
            NameStyleDefinition.definition,
            RegexMatchDefinition.definition,
            DateTimeFieldsDefinition.definition,
            ResourceIdDefinition.definition,
        )

/** A checked catalog of the operation library plus [definitions]; a definition replaces a library one with its id. */
internal fun testCatalog(definitions: List<TypeDefinition> = emptyList()): DefaultCheckedCatalog {
    val declared = definitions.map { it.id }.toSet()
    return DefaultCheckedCatalog(
        CatalogGeneration(value = "expression test"),
        LIBRARY_DEFINITIONS.filterNot { it.id in declared } + definitions,
    )
}

/** The type facts of [testCatalog], for evaluators in tests. */
internal fun testPortableTypes(definitions: List<TypeDefinition> = emptyList()): PortableTypes =
    CatalogPortableTypes(testCatalog(definitions))
