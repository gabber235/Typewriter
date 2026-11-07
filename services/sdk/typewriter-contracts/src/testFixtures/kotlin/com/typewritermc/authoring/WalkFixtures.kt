package com.typewritermc.authoring

import com.typewritermc.types.catalog.CheckedCatalog
import skirout.editor.v1.type_catalog.CollectionKind
import skirout.editor.v1.type_catalog.DataValue
import skirout.editor.v1.type_catalog.ScalarKind
import skirout.editor.v1.type_catalog.TypeDefinitionId
import skirout.editor.v1.type_catalog.TypeUse
import skirout.editor.v1.type_catalog.ValueLocation

/** One node the schema walk handed its visitor: its kind, where it sits, and for a named value its own type. */
data class Visited(
    val kind: String,
    val at: ValueLocation,
    val actual: TypeUse? = null,
)

/** One problem the walk reported, with the type it is about when that type is gone or invalid. */
data class Reported(
    val at: ValueLocation,
    val code: String,
    val type: TypeDefinitionId?,
)

/** What the walk showed a visitor while it walked [value] at [use] from [at]. */
class WalkRecord internal constructor() : ValueVisitor<Unit> {
    val visited = mutableListOf<Visited>()
    val reported = mutableListOf<Reported>()

    override fun problem(
        at: ValueLocation,
        code: String,
        type: TypeDefinitionId?,
    ) {
        reported += Reported(at, code, type)
    }

    override fun placeholder(at: ValueLocation) = Unit

    override fun unfinished(at: ValueLocation) {
        visited += Visited("unfinished", at)
    }

    override fun nullValue(at: ValueLocation) {
        visited += Visited("null", at)
    }

    override fun scalar(
        value: DataValue,
        kind: ScalarKind,
        at: ValueLocation,
    ) {
        visited += Visited("scalar", at)
    }

    override fun link(
        link: DataValue.LinkWrapper,
        at: ValueLocation,
    ) {
        visited += Visited("link", at)
    }

    override fun sequence(
        kind: CollectionKind,
        items: List<Unit>,
        at: ValueLocation,
    ) {
        visited += Visited("sequence", at)
    }

    override fun mapping(
        rows: List<Pair<Unit, Unit>>,
        at: ValueLocation,
    ) {
        visited += Visited("mapping", at)
    }

    override fun record(
        actual: TypeUse,
        fields: Map<String, Unit>,
        at: ValueLocation,
    ) {
        visited += Visited("record", at, actual)
    }

    override fun named(
        actual: TypeUse,
        payload: Unit,
        at: ValueLocation,
    ) {
        visited += Visited("named", at, actual)
    }
}

/** Walks [value] at [use] over [catalog] from [at], recording what the visitor saw. */
fun walked(
    catalog: CheckedCatalog,
    value: DataValue,
    use: TypeUse,
    at: ValueLocation,
): WalkRecord = WalkRecord().also { ValueWalk(catalog, it).walk(value, use, at) }
