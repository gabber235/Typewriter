package com.typewritermc.expression

import com.typewritermc.authoring.AuthoredReads
import com.typewritermc.authoring.Availability
import com.typewritermc.authoring.BoundCollectionPath
import com.typewritermc.authoring.BoundPath
import com.typewritermc.checking.PartialSelection
import com.typewritermc.checking.TypedSelection
import skirout.editor.v1.type_catalog.CatalogGeneration
import skirout.editor.v1.type_catalog.ItemId
import skirout.editor.v1.type_catalog.TypeUse

/** Reads for fixture expressions, which never read a resource: their inputs arrive through the expression value reader. */
object FixtureReads : AuthoredReads {
    override val catalog = CatalogGeneration(value = "expression fixture")
    override val readContext = com.typewritermc.authoring.ReadContext(catalog)

    override fun <T> read(path: BoundPath<T>): Availability<T> = error("Fixture expressions use ExpressionValueReader.")

    override fun <T> readRepresentation(
        path: BoundPath<*>,
        representation: TypeUse,
    ): Availability<T> = error("Fixture expressions use ExpressionValueReader.")

    override fun presence(path: BoundPath<*>): Availability<Boolean> = error("Fixture expressions use ExpressionValueReader.")

    override fun binding(path: BoundPath<*>): Availability<com.typewritermc.authoring.DraftBinding> =
        error("Fixture expressions use ExpressionValueReader.")

    override fun canonicalValueKey(path: BoundPath<*>): Availability<String> = error("Fixture expressions use ExpressionValueReader.")

    override fun members(path: BoundCollectionPath): List<ItemId> = emptyList()

    override fun <D> select(query: TypedSelection<D>): PartialSelection<D> = error("Fixture expressions do not select resources.")
}
