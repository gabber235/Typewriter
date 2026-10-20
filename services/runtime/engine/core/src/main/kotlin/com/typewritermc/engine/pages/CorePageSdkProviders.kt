package com.typewritermc.engine.pages

import com.typewritermc.authoring.PlacementSdkProvider
import com.typewritermc.discovery.GraphDirection
import com.typewritermc.types.PresentationRole

/**
 * Supplies inherited inspector composition for core entry roles.
 *
 * Priority zero leaves specialized presentations ahead of these defaults. Placement uses its SDK provider,
 * allowing authored entry inspectors to share the core layout without owning panel widget policy.
 */
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
    override val roles = setOf(PresentationRole.WORKSPACE)

    override fun SequencePagePresentationScope.present() {
        elements { graph(GraphDirection.LEFT_TO_RIGHT) }
    }
}

object ScenePageEditor : ScenePagePresentation {
    override val roles = setOf(PresentationRole.WORKSPACE)

    override fun ScenePagePresentationScope.present() {
        elements { timeline() }
    }
}

object StaticPageEditor : StaticPagePresentation {
    override val roles = setOf(PresentationRole.WORKSPACE)

    override fun StaticPagePresentationScope.present() {
        elements { graph(GraphDirection.BOTTOM_TO_TOP) }
    }
}

object ManifestPageEditor : ManifestPagePresentation {
    override val roles = setOf(PresentationRole.WORKSPACE)

    override fun ManifestPagePresentationScope.present() {
        elements { graph(GraphDirection.TOP_TO_BOTTOM) }
    }
}
