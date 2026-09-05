package com.typewritermc.elements

import com.typewritermc.types.DataValue
import com.typewritermc.types.Ref
import com.typewritermc.types.ResourceId
import com.typewritermc.types.TypeExpression
import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable

@Serializable
data class StoredElement(
    val id: ElementInstanceId,
    val elementType: ElementTypeId,
    val schemaRevision: Int,
    val name: String,
    val value: StoredElementValue,
    val placement: ElementPlacement,
) {
    init {
        require(schemaRevision > 0) { "Stored element schema revisions must be positive." }
        require(name.isNotBlank()) { "Stored element names must not be blank." }
    }
}

@Serializable
data class StoredElementValue(
    val valueWithSlots: DataValue,
    val references: List<StoredReference>,
) {
    init {
        require(references.map(StoredReference::slot).distinct().size == references.size) {
            "Stored element reference slots must be unique."
        }
    }
}

@JvmInline
@Serializable
value class ReferenceSlotId(
    val value: String,
) {
    init {
        require(value.isNotBlank()) { "Reference slot ids must not be blank." }
    }
}

@Serializable
data class StoredReference(
    val slot: ReferenceSlotId,
    val target: ResourceId,
    val expectedType: TypeExpression,
)

@Serializable
sealed interface ElementPlacement {
    @Serializable
    @SerialName("graph_v1")
    data class Graph(
        val x: Int,
        val y: Int,
        val width: Int,
        val height: Int,
    ) : ElementPlacement {
        init {
            require(width > 0) { "Graph placement width must be positive." }
            require(height > 0) { "Graph placement height must be positive." }
        }
    }

    @Serializable
    @SerialName("timeline_entry_v1")
    data class TimelineEntry(
        val trackIndex: Int,
    ) : ElementPlacement {
        init {
            require(trackIndex >= 0) { "Timeline entry track index must not be negative." }
        }
    }

    @Serializable
    @SerialName("timeline_segment_v1")
    data class TimelineSegment(
        val startFrame: Int,
        val endFrame: Int,
    ) : ElementPlacement {
        init {
            require(startFrame >= 0) { "Timeline segment start frame must not be negative." }
            require(endFrame >= startFrame) { "Timeline segment end frame must not precede its start frame." }
        }
    }

    @Serializable
    @SerialName("timeline_keyframe_v1")
    data class TimelineKeyframe(
        val frame: Int,
    ) : ElementPlacement {
        init {
            require(frame >= 0) { "Timeline keyframe frame must not be negative." }
        }
    }
}

fun <T : Element> ElementInstanceId.ref(): Ref<T> = Ref(ResourceId("element", value))
