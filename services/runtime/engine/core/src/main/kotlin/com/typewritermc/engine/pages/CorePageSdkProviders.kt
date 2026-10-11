package com.typewritermc.engine.pages

import com.typewritermc.discovery.GraphDirection
import com.typewritermc.types.PresentationRole

object SequencePageEditor : SequencePagePresentation {
    override val roles = setOf(PresentationRole.EDITOR)

    override fun SequencePagePresentationScope.present() {
        elements { graphPage(GraphDirection.LEFT_TO_RIGHT) }
    }
}

object ScenePageEditor : ScenePagePresentation {
    override val roles = setOf(PresentationRole.EDITOR)

    override fun ScenePagePresentationScope.present() {
        elements { timelinePage() }
    }
}
