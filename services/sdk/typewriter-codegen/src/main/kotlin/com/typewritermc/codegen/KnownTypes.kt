package com.typewritermc.codegen

import com.google.devtools.ksp.symbol.KSDeclaration
import com.squareup.kotlinpoet.ClassName

/** Kotlin library types codegen gives fixed authoring meaning. The single copy shared by every processor. */
internal object KnownTypes {
    private const val COLLECTIONS = "kotlin.collections"

    /** Types authored as `typewriter/List`. */
    val lists: Set<ClassName> = classes(COLLECTIONS, "List", "MutableList", "ArrayList")

    /** Types authored as `typewriter/Set`. */
    val sets: Set<ClassName> = classes(COLLECTIONS, "Set", "MutableSet", "HashSet", "LinkedHashSet")

    /** Types authored as `typewriter/Map`. */
    val maps: Set<ClassName> = classes(COLLECTIONS, "Map", "MutableMap", "HashMap", "LinkedHashMap")

    /** Container types whose elements sit inside a collection on a relation endpoint path. */
    val containers: Set<ClassName> =
        classes(
            COLLECTIONS,
            "Collection",
            "Iterable",
            "List",
            "Map",
            "MutableCollection",
            "MutableIterable",
            "MutableList",
            "MutableMap",
            "MutableSet",
            "Set",
        ) + ClassName("kotlin", "Array")

    /** Leaf types that can never contain a relation endpoint. */
    val terminals: Set<ClassName> =
        classes(
            "kotlin",
            "Any",
            "Boolean",
            "Byte",
            "Double",
            "Float",
            "Int",
            "Long",
            "Short",
            "String",
            "UByte",
            "UInt",
            "ULong",
            "UShort",
            "Unit",
        ) + classes("kotlin.time", "Duration", "Instant") + classes("java.math", "BigDecimal", "BigInteger")

    private fun classes(
        packageName: String,
        vararg names: String,
    ): Set<ClassName> = names.mapTo(linkedSetOf()) { ClassName(packageName, it) }
}

/** Whether this declaration is one of [types], compared by qualified name. */
internal infix fun KSDeclaration.isOneOf(types: Set<ClassName>): Boolean {
    val qualified = qualifiedName?.asString() ?: return false
    return types.any { it.canonicalName == qualified }
}

/** Whether this declaration is [type], compared by qualified name. */
internal infix fun KSDeclaration.isType(type: ClassName): Boolean = qualifiedName?.asString() == type.canonicalName
