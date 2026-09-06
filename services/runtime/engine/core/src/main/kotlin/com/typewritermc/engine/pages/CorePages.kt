package com.typewritermc.engine.pages

import com.typewritermc.elements.Entry
import com.typewritermc.elements.Keyframe
import com.typewritermc.elements.Segment
import com.typewritermc.pages.GraphDirection
import com.typewritermc.pages.PageEditorDefinition
import com.typewritermc.pages.TypewriterPage
import com.typewritermc.pages.page

/**
 * Marks entries accepted by the core sequence graph page.
 *
 * The marker defines an editor role; execution behavior must be supplied by the entry or a runtime facet.
 */
interface SequenceEntry : Entry

/**
 * Marks entries accepted by the core static graph page.
 *
 * The page specification defines layout, while runtime behavior remains separate.
 */
interface StaticEntry : Entry

/**
 * Marks entries accepted by the core manifest graph page.
 */
interface ManifestEntry : Entry

/**
 * Marks track entries accepted by the core scene timeline alongside segments and keyframes.
 */
interface SceneEntry : Entry

@TypewriterPage(
    id = "019d3a87001070008000000000000010",
)
fun sequencePage() =
    page(
        name = "Sequence",
        icon = "material-symbols:account-tree",
        color = "#2196F3",
        editor = PageEditorDefinition.Graph(GraphDirection.LEFT_TO_RIGHT, listOf(SequenceEntry::class)),
    )

@TypewriterPage(
    id = "019d3a87001170008000000000000011",
)
fun staticPage() =
    page(
        name = "Static",
        icon = "material-symbols:push-pin",
        color = "#673AB7",
        editor = PageEditorDefinition.Graph(GraphDirection.BOTTOM_TO_TOP, listOf(StaticEntry::class)),
    )

@TypewriterPage(
    id = "019d3a87001270008000000000000012",
)
fun scenePage() =
    page(
        name = "Scene",
        icon = "material-symbols:movie",
        color = "#FF9800",
        editor =
            PageEditorDefinition.Timeline(
                tracks = listOf(SceneEntry::class),
                segments = listOf(Segment::class),
                keyframes = listOf(Keyframe::class),
            ),
    )

@TypewriterPage(
    id = "019d3a87001370008000000000000013",
)
fun manifestPage() =
    page(
        name = "Manifest",
        icon = "material-symbols:schema",
        color = "#4CAF50",
        editor = PageEditorDefinition.Graph(GraphDirection.TOP_TO_BOTTOM, listOf(ManifestEntry::class)),
    )
