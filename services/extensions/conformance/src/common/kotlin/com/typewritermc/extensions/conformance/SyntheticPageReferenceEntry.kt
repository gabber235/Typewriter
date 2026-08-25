package com.typewritermc.extensions.conformance

import com.typewritermc.elements.ElementInstanceId
import com.typewritermc.elements.EntryExecutionContext
import com.typewritermc.elements.ExecutableEntry
import com.typewritermc.elements.TypewriterElement
import com.typewritermc.types.Ref
import kotlinx.serialization.Serializable

@Serializable
@TypewriterElement(
    id = "019d3a87000270008000000000000002",
    name = "Synthetic Page Reference",
    description = "Verifies generated page kind references",
    icon = "material-symbols:link",
    color = "#536DFE",
)
data class SyntheticPageReferenceEntry(
    override val id: ElementInstanceId,
    val page: Ref<SyntheticPageKind>,
) : ExecutableEntry {
    context(context: EntryExecutionContext)
    override suspend fun execute() = Unit
}
