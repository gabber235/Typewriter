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
