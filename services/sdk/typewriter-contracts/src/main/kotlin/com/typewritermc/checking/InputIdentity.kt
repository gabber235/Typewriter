package com.typewritermc.checking

import skirout.editor.v1.type_catalog.CatalogGeneration
import skirout.editor.v1.type_catalog.RelationId
import skirout.editor.v1.type_catalog.SelectionId
import skirout.editor.v1.type_catalog.ValueLocation
import skirout.kernel.v1.resource_id.ResourceId

sealed interface InputIdentity {
    data class Value(
        val at: ValueLocation,
    ) : InputIdentity

    /** The whole record of [resource]: its existence, configuration, values and declarations. */
    data class Resource(
        val resource: ResourceId,
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

    /** The types [resource] declares. */
    data class Types(
        val resource: ResourceId,
    ) : InputIdentity

    data class Catalog(
        val generation: CatalogGeneration,
    ) : InputIdentity
}
