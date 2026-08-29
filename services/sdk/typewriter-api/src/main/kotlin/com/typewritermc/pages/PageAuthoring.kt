package com.typewritermc.pages

import com.typewritermc.elements.Element
import com.typewritermc.elements.Entry
import com.typewritermc.elements.Keyframe
import com.typewritermc.elements.Segment
import kotlin.reflect.KClass

/** Marks a top level page specification and assigns its persistent identity. */
@Target(AnnotationTarget.FUNCTION)
@Retention(AnnotationRetention.BINARY)
annotation class TypewriterPage(
    val id: String,
    val revision: Int = 1,
)

/** Marks a generated page kind so other processors can recover its stable identity. */
@Target(AnnotationTarget.CLASS)
@Retention(AnnotationRetention.BINARY)
annotation class GeneratedPageKind(
    val id: String,
    val revision: Int,
)

enum class GraphDirection {
    LEFT_TO_RIGHT,
    RIGHT_TO_LEFT,
    TOP_TO_BOTTOM,
    BOTTOM_TO_TOP,
}

sealed interface PageEditorDefinition {
    data class Graph(
        val direction: GraphDirection,
        val nodes: List<KClass<out Element>>,
    ) : PageEditorDefinition {
        init {
            require(nodes.isNotEmpty()) { "Graph page definitions require at least one node type." }
            require(nodes.distinct().size == nodes.size) { "Graph node types must be unique." }
        }
    }

    data class Timeline(
        val tracks: List<KClass<out Entry>>,
        val segments: List<KClass<out Segment>>,
        val keyframes: List<KClass<out Keyframe>>,
    ) : PageEditorDefinition {
        init {
            require(tracks.isNotEmpty()) { "Timeline page definitions require at least one track type." }
            require(tracks.distinct().size == tracks.size) { "Timeline track types must be unique." }
            require(segments.distinct().size == segments.size) { "Timeline segment types must be unique." }
            require(keyframes.distinct().size == keyframes.size) { "Timeline keyframe types must be unique." }
        }
    }
}

/** Authored page metadata before Kotlin role types are resolved into catalog identities. */
data class PageSpec(
    val editor: PageEditorDefinition,
    val icon: String,
    val color: String,
    val name: String? = null,
    val description: String? = null,
) {
    init {
        require(name == null || name.isNotBlank()) { "Explicit page names must not be blank." }
        require(description == null || description.isNotBlank()) { "Explicit page descriptions must not be blank." }
        require(icon.isNotBlank()) { "Page icons must not be blank." }
        require(color.isNotBlank()) { "Page colors must not be blank." }
    }
}

fun page(
    editor: PageEditorDefinition,
    icon: String,
    color: String,
    name: String? = null,
    description: String? = null,
): PageSpec = PageSpec(editor, icon, color, name, description)
