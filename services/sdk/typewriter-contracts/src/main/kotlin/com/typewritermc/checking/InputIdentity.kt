package com.typewritermc.checking

import com.typewritermc.authoring.SelectionId
import com.typewritermc.types.RelationId
import com.typewritermc.types.ResourceId
import kotlinx.serialization.Serializable
import skirout.editor.v1.type_catalog.ValueLocation
import skirout.editor.v1.type_catalog.CatalogGeneration as SkirCatalogGeneration

@JvmInline @Serializable
value class CatalogGeneration(
    val value: String,
)

/** The generated form of this generation, which generated values such as check tickets hold. */
fun CatalogGeneration.toSkir(): SkirCatalogGeneration = SkirCatalogGeneration(value = value)

@JvmInline @Serializable
value class InputToken(
    val value: String,
)

sealed interface InputIdentity {
    data class Value(
        val at: ValueLocation,
    ) : InputIdentity

    data class Existence(
        val resource: ResourceId,
    ) : InputIdentity

    data class Form(
        val at: ValueLocation,
    ) : InputIdentity

    data class Membership(
        val at: ValueLocation,
    ) : InputIdentity

    data class Order(
        val at: ValueLocation,
    ) : InputIdentity

    data class Selection(
        val query: SelectionId,
    ) : InputIdentity

    data class Incoming(
        val resource: ResourceId,
        val relation: RelationId?,
    ) : InputIdentity

    data class Catalog(
        val generation: CatalogGeneration,
    ) : InputIdentity
}
