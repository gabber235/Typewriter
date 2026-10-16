package com.typewritermc.engine.pages

import com.typewritermc.authoring.PlacementSdkProvider
import com.typewritermc.discovery.GraphDirection
import com.typewritermc.types.PresentationRole

object CoreEntryInspectors :
    SequenceEntryPresentation,
    StaticEntryPresentation,
    ManifestEntryPresentation,
    SceneEntryPresentation {
    override val roles = setOf(PresentationRole.INSPECTOR)
    override val priority = 0

    override fun SequenceEntryPresentationScope.present() {
        name()
        remainingFields()
        placement(using = PlacementSdkProvider)
    }

    override fun StaticEntryPresentationScope.present() {
        name()
        remainingFields()
        placement(using = PlacementSdkProvider)
    }

    override fun ManifestEntryPresentationScope.present() {
        name()
        remainingFields()
        placement(using = PlacementSdkProvider)
    }

    override fun SceneEntryPresentationScope.present() {
        name()
        remainingFields()
        placement(using = PlacementSdkProvider)
    }
}

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

object StaticPageEditor : StaticPagePresentation {
    override val roles = setOf(PresentationRole.EDITOR)

    override fun StaticPagePresentationScope.present() {
        elements { graphPage(GraphDirection.BOTTOM_TO_TOP) }
    }
}

object ManifestPageEditor : ManifestPagePresentation {
    override val roles = setOf(PresentationRole.EDITOR)

    override fun ManifestPagePresentationScope.present() {
        elements { graphPage(GraphDirection.TOP_TO_BOTTOM) }
    }
}
