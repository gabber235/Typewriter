package com.typewritermc.authoring

import skirout.editor.v1.authoring_facts.EditExpectation
import skirout.editor.v1.authoring_facts.LinkProjection
import skirout.editor.v1.authoring_facts.TraversalDirection
import skirout.editor.v1.type_catalog.RelationId
import skirout.kernel.v1.resource_id.ResourceId

/*
 * Edit expectations are the generated Skir EditExpectation: facts from the original read view that must still hold
 * when an edit is accepted. The resource id and link expectations describe sets; these factories give them their
 * canonical form, without duplicates and in a fixed order, so equal facts compare and encode equally.
 */

/** Expects exactly the resources [expected], in id order. */
fun EditExpectation.Companion.resourceIds(expected: Collection<ResourceId>): EditExpectation.ResourceIdsWrapper =
    EditExpectation.ResourceIdsWrapper(expected.canonicalResourceIds())

/** Expects exactly the [expected] links of [contract] at [resource], in the order of their dense Skir JSON. */
fun EditExpectation.Companion.links(
    resource: ResourceId,
    contract: RelationId,
    direction: TraversalDirection,
    expected: Collection<LinkProjection>,
): EditExpectation.LinksWrapper =
    EditExpectation.createLinks(resource = resource, contract = contract, direction = direction, expected = expected.canonicalLinks())

internal fun Collection<ResourceId>.canonicalResourceIds(): List<ResourceId> = distinct().sortedBy { it.value }

internal fun Collection<LinkProjection>.canonicalLinks(): List<LinkProjection> = distinct().sortedBy(LinkProjection.serializer::toJsonCode)
