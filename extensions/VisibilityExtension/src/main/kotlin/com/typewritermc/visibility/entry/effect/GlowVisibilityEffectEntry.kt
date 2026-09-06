package com.typewritermc.visibility.entry.effect

import com.typewritermc.core.books.pages.Colors
import com.typewritermc.core.extension.annotations.Entry
import com.typewritermc.core.extension.annotations.Help
import com.typewritermc.engine.paper.entry.entries.ConstVar
import com.typewritermc.engine.paper.entry.entries.Var
import com.typewritermc.engine.paper.utils.Color
import com.typewritermc.visibility.effector.VisibilityEffector
import com.typewritermc.visibility.packet.EntityFlag
import com.typewritermc.visibility.packet.EntityFlagOverlay
import com.typewritermc.visibility.packet.TeamContribution
import com.typewritermc.visibility.packet.TeamContributionKind
import com.typewritermc.visibility.packet.VisibilityTeamManager
import com.typewritermc.visibility.rule.VisibilityRule
import net.kyori.adventure.text.format.NamedTextColor
import net.kyori.adventure.text.format.TextColor
import org.bukkit.entity.Player
import org.koin.core.component.KoinComponent
import org.koin.core.component.inject

@Entry(
    "glow_visibility_effect",
    "Makes the target glow with a colored outline for the viewer",
    Colors.YELLOW,
    "fa6-solid:lightbulb"
)
/**
 * The `Glow Visibility Effect` gives the target a glowing outline that only the viewer can see.
 * The outline color is the closest team color to the configured color, and is resolved for the
 * viewer when the effect activates.
 *
 * The glow also colors the target's nametag, which is vanilla behavior for glowing entities.
 *
 * ## How could this be used?
 * Highlight quest targets, mark party members through walls, or point out the impostor to the
 * player who unlocked detective vision.
 */
class GlowVisibilityEffectEntry(
    override val id: String = "",
    override val name: String = "",
    @Help("The color of the glow outline.")
    val color: Var<Color> = ConstVar(Color.WHITE),
    @Help("Also apply this effect to the target's own view of themselves.")
    val self: Var<Boolean> = ConstVar(false),
) : VisibilityEffectEntry {
    override val supportsSelf: Boolean get() = true

    override fun appliesToSelf(viewer: Player): Boolean = self.get(viewer)

    override fun constantSelf(): Boolean? = (self as? ConstVar)?.value

    override fun createEffector(rule: VisibilityRule): VisibilityEffector = GlowVisibilityEffector(rule, color)
}

private class GlowVisibilityEffector(
    private val rule: VisibilityRule,
    private val color: Var<Color>,
) : VisibilityEffector, KoinComponent {
    private val teamManager: VisibilityTeamManager by inject()
    private val overlay = EntityFlagOverlay(rule, EntityFlag.GLOWING)

    override suspend fun initialize() = overlay.attach { viewer, target ->
        val teamColor = NamedTextColor.nearestTo(TextColor.color(color.get(viewer).color))
        teamManager.contribute(
            viewer,
            target,
            TeamContribution(kind = TeamContributionKind.GLOW, color = teamColor),
        )
    }

    override suspend fun dispose() = overlay.detach { entityId ->
        teamManager.withdraw(rule.viewer, entityId, TeamContributionKind.GLOW)
    }
}
