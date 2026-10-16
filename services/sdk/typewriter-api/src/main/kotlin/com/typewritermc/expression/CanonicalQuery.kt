package com.typewritermc.expression

import com.typewritermc.authoring.AuthoredReads
import com.typewritermc.authoring.AuthoringRecord
import com.typewritermc.authoring.Availability
import com.typewritermc.presentation.ExpressionNode
import com.typewritermc.types.ResourceId
import com.typewritermc.types.TypeDefinitionId
import com.typewritermc.types.TypeUse
import com.typewritermc.types.catalog.CheckedCatalog
import com.typewritermc.types.catalog.PublishedType

enum class CanonicalQueryOperation(
    val id: String,
) {
    ResourceIdentity("typewriter.resource.id"),
    ResourceValue("typewriter.resource.value"),
    ResourceConfiguration("typewriter.resource.configuration"),
    ValueConfiguration("typewriter.value.configuration"),
    CatalogDeclaration("typewriter.catalog.declaration"),
    ;

    companion object {
        fun from(id: String): CanonicalQueryOperation? = entries.firstOrNull { it.id == id }
    }
}

/** A traversal path local to one checked expression and its lexical typing environment. */
data class ExpressionOccurrence(
    val children: List<Int> = emptyList(),
) {
    fun child(index: Int): ExpressionOccurrence = ExpressionOccurrence(children + index)
}

data class CheckedQueryCall(
    val operation: CanonicalQueryOperation,
    val targetType: TypeUse?,
    val result: ExpressionType,
    val sourceIsReference: Boolean,
)

data class CheckedExpressionProgram(
    val body: ExpressionNode,
    val result: ExpressionType,
    val queries: Map<ExpressionOccurrence, CheckedQueryCall>,
)

/** Reads canonical facts through the same authored read context as ordinary expression values. */
interface CanonicalQueryReader {
    val catalog: CheckedCatalog

    context(reads: AuthoredReads)
    fun resource(id: ResourceId): Availability<AuthoringRecord>

    context(reads: AuthoredReads)
    fun declaration(id: TypeDefinitionId): Availability<PublishedType>
}
