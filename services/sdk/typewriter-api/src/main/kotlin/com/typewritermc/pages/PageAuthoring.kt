package com.typewritermc.pages

import com.typewritermc.library.Page
import kotlin.reflect.KClass

/**
 * Declares a top level page specification for generation into a persistent page kind and provider.
 *
 * Keep the identity stable across releases. The revision belongs to the page schema consumed by stored pages and
 * catalog lookup.
 */
@Target(AnnotationTarget.FUNCTION)
@Retention(AnnotationRetention.BINARY)
annotation class TypewriterPage(
    val type: KClass<out Page>,
)

/**
 * Selects the direction in which graph relationships are laid out by the editor.
 */
enum class GraphDirection {
    /** Places graph successors to the right of their predecessors. */
    LEFT_TO_RIGHT,

    /** Places graph successors to the left of their predecessors. */
    RIGHT_TO_LEFT,

    /** Places graph successors below their predecessors. */
    TOP_TO_BOTTOM,

    /** Places graph successors above their predecessors. */
    BOTTOM_TO_TOP,
}

/**
 * Selects graph or timeline authoring and the Kotlin role types accepted by that editor.
 *
 * Graph nodes and timeline tracks must be nonempty; each role list must contain unique classes. Catalog assembly
 * resolves these classes into structural type references.
 */
sealed interface PageEditorDefinition {
    data class Graph(
        val direction: GraphDirection,
    ) : PageEditorDefinition

    data object Timeline : PageEditorDefinition
}

/**
 * Defines editor structure and visual metadata before catalog assembly resolves Kotlin classes.
 *
 * An omitted name is derived from the declaration name. Icon and color strings are parsed during assembly, which
 * reports invalid specifications as diagnostics.
 */
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

/**
 * Creates a [PageSpec] for use as the return value of a [TypewriterPage] declaration.
 *
 * The returned strings remain in their authored form until catalog assembly parses the icon and color.
 */
fun page(
    editor: PageEditorDefinition,
    icon: String,
    color: String,
    name: String? = null,
    description: String? = null,
): PageSpec = PageSpec(editor, icon, color, name, description)
