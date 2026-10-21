package com.typewritermc.expression

import com.typewritermc.authoring.AuthoredReads
import com.typewritermc.authoring.AuthoringRecord
import com.typewritermc.authoring.Availability
import com.typewritermc.types.ResourceId
import com.typewritermc.types.catalog.CheckedCatalog
import skirout.editor.v1.catalog.PublishedType
import skirout.editor.v1.expression.ExpressionNode
import skirout.editor.v1.expression.ExpressionType
import skirout.editor.v1.type_catalog.TypeDefinitionId
import skirout.editor.v1.type_catalog.TypeUse

/** A traversal path local to one checked expression and its lexical typing environment. */
data class ExpressionOccurrence(
    val children: List<Int> = emptyList(),
) {
    fun child(index: Int): ExpressionOccurrence = ExpressionOccurrence(children + index)
}

data class CheckedQueryCall(
    val operation: skirout.editor.v1.expression.ExpressionQuery.Kind,
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
