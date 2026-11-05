package com.typewritermc.testkit

import com.typewritermc.discovery.ProviderOrigin
import com.typewritermc.discovery.contributionKey
import com.typewritermc.imprint.ArtifactId
import com.typewritermc.imprint.ContributionName
import com.typewritermc.imprint.ContributionSourceId
import com.typewritermc.imprint.ProducerId
import com.typewritermc.presentation.allNodes
import com.typewritermc.types.catalog.Resolution
import com.typewritermc.types.requirePortable
import skirout.editor.v1.catalog.PreparedContent
import skirout.editor.v1.catalog.PreparedValue
import skirout.editor.v1.presentation.AxisChild
import skirout.editor.v1.presentation.ChildrenElement
import skirout.editor.v1.presentation.PresentationElement
import skirout.editor.v1.presentation.PresentationNode
import skirout.editor.v1.type_catalog.DataValue
import skirout.editor.v1.type_catalog.DeclarationOwner

/** The resolved value; fails with the catalog's diagnostics when the resolution is invalid. */
fun <T> Resolution<T>.ready(): T =
    when (this) {
        is Resolution.Ready -> value
        is Resolution.Invalid -> throw AssertionError("Expected a ready resolution, found $diagnostics.")
    }

/** A provider origin in the test contribution source, owned under [name] by the artifact [artifact]. */
fun origin(
    name: String,
    artifact: String = "test:framework",
): ProviderOrigin =
    ProviderOrigin(
        owner =
            DeclarationOwner(
                source =
                    contributionKey(
                        source = ContributionSourceId("test"),
                        sourcePart = "main",
                        producer = ProducerId("test"),
                        name = ContributionName(name.replace(' ', '_')),
                    ),
                localIdentity = name,
            ),
        artifact = ArtifactId(artifact),
        sourcePart = "main",
    )

/** The nodes this column node lays out, in order; fails when it is not a column of fixed children. */
fun PresentationNode.fixedChildren(): List<PresentationNode> {
    val children = element as? PresentationElement.ChildrenWrapper ?: throw AssertionError("Expected a column, found $element.")
    val column = children.value as? ChildrenElement.ColumnWrapper ?: throw AssertionError("Expected a column, found ${children.value}.")
    return column.value.children.map { child ->
        (child as? AxisChild.FixedWrapper)?.value ?: throw AssertionError("Expected a fixed child, found $child.")
    }
}

/** The only node this column lays out. */
fun PresentationNode?.singleFixed(): PresentationNode =
    requireNotNull(this) {
        "Expected a column, found nothing."
    }.fixedChildren().single()

/** Every element of type [E] anywhere in this layout, parents before children. */
inline fun <reified E : PresentationElement> PresentationNode.elementsOf(): List<E> = allNodes().mapNotNull { it.element as? E }

/** The portable wire bytes of this value, as the Skir serializer writes them; fails when the value is not portable. */
fun DataValue.bytes(): ByteArray = DataValue.serializer.toBytes(requirePortable()).toByteArray()

/** The record content of this prepared value; fails when the value is not a record. */
val PreparedValue.record get() = (content as PreparedContent.RecordWrapper).value
