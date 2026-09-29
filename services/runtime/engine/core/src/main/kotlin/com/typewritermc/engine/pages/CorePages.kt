package com.typewritermc.engine.pages

import com.typewritermc.authoring.GraphPlacement
import com.typewritermc.authoring.TimelineEntryPlacement
import com.typewritermc.discovery.GraphDirection
import com.typewritermc.elements.Entry
import com.typewritermc.library.Book
import com.typewritermc.library.BookPages
import com.typewritermc.library.ChapterPath
import com.typewritermc.library.Page
import com.typewritermc.library.PageElements
import com.typewritermc.pages.TypewriterPage
import com.typewritermc.types.ToMany
import com.typewritermc.types.ToOne
import com.typewritermc.types.TypewriterDisplay
import com.typewritermc.types.TypewriterType

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

@TypewriterType(id = "01a0b18585cd75c386c51fa6706bed6a")
@TypewriterDisplay(name = "Sequence", icon = "material-symbols:account-tree", color = "#2196F3")
@TypewriterPage.Graph(GraphDirection.LEFT_TO_RIGHT)
data class SequencePage(
    override val book: ToOne<BookPages, Book>,
    override val name: String = "",
    override val chapter: ChapterPath = ChapterPath.Root,
    override val priority: Int = 0,
    override val elements: ToMany<PageElements, SequenceEntry> = ToMany.empty(),
) : Page

@TypewriterType(id = "01a0b185a1d5743ca86b82d4d61e1041")
@TypewriterDisplay(name = "Static", icon = "material-symbols:push-pin", color = "#673AB7")
@TypewriterPage.Graph(GraphDirection.BOTTOM_TO_TOP)
data class StaticPage(
    override val book: ToOne<BookPages, Book>,
    override val name: String = "",
    override val chapter: ChapterPath = ChapterPath.Root,
    override val priority: Int = 0,
    override val elements: ToMany<PageElements, StaticEntry> = ToMany.empty(),
) : Page

@TypewriterType(id = "01a0b185e711776992ee044c4f6a4f3c")
@TypewriterDisplay(name = "Scene", icon = "material-symbols:movie", color = "#FF9800")
@TypewriterPage.Timeline
data class ScenePage(
    override val book: ToOne<BookPages, Book>,
    override val name: String = "",
    override val chapter: ChapterPath = ChapterPath.Root,
    override val priority: Int = 0,
    override val elements: ToMany<PageElements, SceneEntry> = ToMany.empty(),
) : Page

@TypewriterType(id = "01a0b185fe8177cfb98a6e32e03d155c")
@TypewriterDisplay(name = "Manifest", icon = "material-symbols:schema", color = "#4CAF50")
@TypewriterPage.Graph(GraphDirection.TOP_TO_BOTTOM)
data class ManifestPage(
    override val book: ToOne<BookPages, Book>,
    override val name: String = "",
    override val chapter: ChapterPath = ChapterPath.Root,
    override val priority: Int = 0,
    override val elements: ToMany<PageElements, ManifestEntry> = ToMany.empty(),
) : Page
