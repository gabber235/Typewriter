package com.typewritermc.extensions.conformance

import com.typewritermc.discovery.runtime.RuntimeRegistrar
import com.typewritermc.discovery.runtime.RuntimeScope
import com.typewritermc.discovery.runtime.TypewriterRegistrar
import com.typewritermc.elements.ElementRuntimeContext
import com.typewritermc.elements.ElementRuntimeFacet
import com.typewritermc.elements.ElementRuntimeHandle
import com.typewritermc.elements.EntryExecutionContext
import com.typewritermc.elements.ExecutableEntry
import com.typewritermc.elements.TypewriterElement
import com.typewritermc.elements.TypewriterElementFacet
import com.typewritermc.types.TypewriterType
import kotlinx.serialization.Serializable

@Serializable
sealed interface SyntheticMessage

@Serializable
@TypewriterType(
    id = "019d1f6c1d2e72499fa386964e89721d",
)
data class LiteralMessage(
    val value: String,
) : SyntheticMessage

@Serializable
@TypewriterType(
    id = "019d1f6d0ac77d3e83304b0be26ed722",
)
data class RepeatedMessage(
    val value: String,
    val repetitions: Int,
) : SyntheticMessage

@Serializable
@TypewriterElement(
    id = "019d1c2a8f7b7cc18c2a4a7b2fd1e281",
    name = "Synthetic Entry",
    description = "Verifies Typewriter discovery",
    icon = "material-symbols:science",
    color = "#7C4DFF",
)
data class SyntheticEntry(
    val message: SyntheticMessage,
) : ExecutableEntry {
    context(context: EntryExecutionContext)
    override suspend fun execute() {
        context.output.send(message)
    }
}

@TypewriterElementFacet(SyntheticEntry::class)
class SyntheticEntryFacet : ElementRuntimeFacet<SyntheticEntry> {
    context(context: ElementRuntimeContext)
    override suspend fun attach(element: SyntheticEntry): ElementRuntimeHandle =
        object : ElementRuntimeHandle {
            override fun close() = Unit
        }
}

@TypewriterRegistrar(id = "synthetic")
class SyntheticRuntimeRegistrar : RuntimeRegistrar {
    context(scope: RuntimeScope)
    override suspend fun register() {
        scope.own {}
    }
}
