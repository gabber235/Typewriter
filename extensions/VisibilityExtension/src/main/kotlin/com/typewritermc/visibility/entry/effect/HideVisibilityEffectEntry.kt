package com.typewritermc.visibility.entry.effect

import com.typewritermc.core.books.pages.Colors
import com.typewritermc.core.extension.annotations.Entry
import com.typewritermc.core.utils.switchContext
import com.typewritermc.engine.paper.utils.Sync
import com.typewritermc.visibility.VisibilityHideRegistry
import com.typewritermc.visibility.effector.VisibilityEffector
import com.typewritermc.visibility.packet.targetPlayer
import com.typewritermc.visibility.packet.viewerPlayer
import com.typewritermc.visibility.rule.VisibilityRule
import kotlinx.coroutines.Dispatchers
import org.koin.core.component.KoinComponent
import org.koin.core.component.inject

@Entry(
    "hide_visibility_effect",
    "Completely hides the target from the viewer",
    Colors.RED,
    "fa6-solid:eye-slash"
)
/**
 * The `Hide Visibility Effect` completely removes the target from the viewer's client, as if the
 * target does not exist.
 *
 * ## How could this be used?
 * Vanish staff members, hide players that are in a different story phase, or keep the members of
 * another minigame arena out of sight.
 */
class HideVisibilityEffectEntry(
    override val id: String = "",
    override val name: String = "",
) : VisibilityEffectEntry {
    override fun createEffector(rule: VisibilityRule): VisibilityEffector = HideVisibilityEffector(rule)
}

private class HideVisibilityEffector(
    private val rule: VisibilityRule,
) : VisibilityEffector, KoinComponent {
    private val hideRegistry: VisibilityHideRegistry by inject()

    override suspend fun initialize() {
        if (rule.isSelf) return
        Dispatchers.Sync.switchContext {
            val viewer = rule.viewerPlayer ?: return@switchContext
            val target = rule.targetPlayer ?: return@switchContext
            hideRegistry.hide(viewer, target)
        }
    }

    override suspend fun dispose() {
        if (rule.isSelf) return
        Dispatchers.Sync.switchContext {
            hideRegistry.show(rule.viewer, rule.target)
        }
    }
}
