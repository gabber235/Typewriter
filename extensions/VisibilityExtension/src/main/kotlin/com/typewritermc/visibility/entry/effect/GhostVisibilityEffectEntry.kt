package com.typewritermc.visibility.entry.effect

import com.typewritermc.core.books.pages.Colors
import com.typewritermc.core.extension.annotations.Entry
import com.typewritermc.core.extension.annotations.Help
import com.typewritermc.engine.paper.entry.entries.ConstVar
import com.typewritermc.engine.paper.entry.entries.Var
import com.typewritermc.visibility.effector.VisibilityEffector
import com.typewritermc.visibility.packet.EntityFlag
import com.typewritermc.visibility.packet.EntityFlagOverlay
import com.typewritermc.visibility.packet.TeamContribution
import com.typewritermc.visibility.packet.TeamContributionKind
import com.typewritermc.visibility.packet.VisibilityTeamManager
import com.typewritermc.visibility.rule.VisibilityRule
import org.bukkit.entity.Player
import org.koin.core.component.KoinComponent
import org.koin.core.component.inject

@Entry(
    "ghost_visibility_effect",
    "Renders the target semi transparent for the viewer",
    Colors.CYAN,
    "fa6-solid:ghost"
)
/**
 * The `Ghost Visibility Effect` renders the target's body semi transparent for the viewer.
 *
 * It uses the vanilla teammate invisibility rendering: the target is made invisible and both players
 * are placed in a client side team that can see friendly invisibles. Armor and held items still
 * render normally, so combine this with an armor visibility effect to hide those too.
 *
 * A client can only place a player in one team, and the viewer has to share the team of every ghost
 * they see. All of a viewer's ghost targets therefore live in the same team and share one color and
 * one nametag setting. When several ghost rules disagree, a warning names the viewer.
 *
 * ## How could this be used?
 * Show dead party members as ghosts to the living, or render players that walk the spirit world
 * as translucent figures to players with spirit sight.
 */
class GhostVisibilityEffectEntry(
    override val id: String = "",
    override val name: String = "",
    @Help("Also apply this effect to the target's own view of themselves.")
    val self: Var<Boolean> = ConstVar(false),
) : VisibilityEffectEntry {
    override val supportsSelf: Boolean get() = true

    override fun appliesToSelf(viewer: Player): Boolean = self.get(viewer)

    override fun constantSelf(): Boolean? = (self as? ConstVar)?.value

    override fun createEffector(rule: VisibilityRule): VisibilityEffector = GhostVisibilityEffector(rule)
}

private class GhostVisibilityEffector(
    private val rule: VisibilityRule,
) : VisibilityEffector, KoinComponent {
    private val teamManager: VisibilityTeamManager by inject()
    private val overlay = EntityFlagOverlay(rule, EntityFlag.INVISIBLE)

    override suspend fun initialize() = overlay.attach { viewer, target ->
        teamManager.contribute(
            viewer,
            target,
            TeamContribution(kind = TeamContributionKind.GHOST, friendlyInvisible = true),
        )
    }

    override suspend fun dispose() = overlay.detach { entityId ->
        teamManager.withdraw(rule.viewer, entityId, TeamContributionKind.GHOST)
    }
}
