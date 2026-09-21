package com.typewritermc.engine.pages

import com.typewritermc.authoring.GraphPlacement
import com.typewritermc.authoring.TimelineEntryPlacement
import com.typewritermc.elements.Entry
import com.typewritermc.elements.Keyframe
import com.typewritermc.elements.Segment
import com.typewritermc.pages.CommonPageAuthoringRules
import com.typewritermc.pages.GraphDirection
import com.typewritermc.pages.PageEditorDefinition
import com.typewritermc.pages.TypewriterPage
import com.typewritermc.pages.page

/**
 * Marks entries accepted by the core sequence graph page.
 *
 * The marker defines an editor role; execution behavior must be supplied by the entry or a runtime facet.
 */
interface SequenceEntry : Entry {
    override val placement: GraphPlacement
}

/**
 * Marks entries accepted by the core static graph page.
 *
 * The page specification defines layout, while runtime behavior remains separate.
 */
interface StaticEntry : Entry {
    override val placement: GraphPlacement
}

/**
 * Marks entries accepted by the core manifest graph page.
 */
interface ManifestEntry : Entry {
    override val placement: GraphPlacement
}

/**
 * Marks track entries accepted by the core scene timeline alongside segments and keyframes.
 */
interface SceneEntry : Entry {
    override val placement: TimelineEntryPlacement
}

@TypewriterPage(
    id = "01a0b185-85cd-75c3-86c5-1fa6706bed6a",
)
fun sequencePage() =
    page(
        name = "Sequence",
        icon = "material-symbols:account-tree",
        color = "#2196F3",
        editor = PageEditorDefinition.Graph(GraphDirection.LEFT_TO_RIGHT, listOf(SequenceEntry::class)),
        authoringRules = listOf(CommonPageAuthoringRules.noSelfReferences),
    )

@TypewriterPage(
    id = "01a0b185-a1d5-743c-a86b-82d4d61e1041",
)
fun staticPage() =
    page(
        name = "Static",
        icon = "material-symbols:push-pin",
        color = "#673AB7",
        editor = PageEditorDefinition.Graph(GraphDirection.BOTTOM_TO_TOP, listOf(StaticEntry::class)),
    )

@TypewriterPage(
    id = "01a0b185-e711-7769-92ee-044c4f6a4f3c",
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
    id = "01a0b185-fe81-77cf-b98a-6e32e03d155c",
)
fun manifestPage() =
    page(
        name = "Manifest",
        icon = "material-symbols:schema",
        color = "#4CAF50",
        editor = PageEditorDefinition.Graph(GraphDirection.TOP_TO_BOTTOM, listOf(ManifestEntry::class)),
        authoringRules = listOf(CommonPageAuthoringRules.acyclicElementReferences),
    )
