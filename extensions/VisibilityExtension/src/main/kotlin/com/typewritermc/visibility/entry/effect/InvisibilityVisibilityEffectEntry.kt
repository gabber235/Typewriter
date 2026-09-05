package com.typewritermc.visibility.entry.effect

import com.typewritermc.core.books.pages.Colors
import com.typewritermc.core.extension.annotations.Entry
import com.typewritermc.core.extension.annotations.Help
import com.typewritermc.engine.paper.entry.entries.ConstVar
import com.typewritermc.engine.paper.entry.entries.Var
import com.typewritermc.visibility.effector.VisibilityEffector
import com.typewritermc.visibility.packet.EntityFlag
import com.typewritermc.visibility.packet.EntityFlagOverlay
import com.typewritermc.visibility.rule.VisibilityRule
import org.bukkit.entity.Player

@Entry(
    "invisibility_visibility_effect",
    "Makes the target invisible while keeping their armor and held items",
    Colors.PURPLE,
    "mdi:account-off"
)
/**
 * The `Invisibility Visibility Effect` hides the target's body for the viewer, like the vanilla
 * invisibility potion. Armor and held items keep rendering, so the viewer sees only those. Combine
 * this with an armor visibility effect to hide them too.
 *
 * Unlike the ghost effect this uses no team, so the target is not translucent but fully gone apart
 * from their equipment.
 *
 * ## How could this be used?
 * Give a player a potion style invisibility that others still see the gear of, or hide a target's
 * body while a floating set of armor stalks the players hunting them.
 */
class InvisibilityVisibilityEffectEntry(
    override val id: String = "",
    override val name: String = "",
    @Help("Also apply this effect to the target's own view of themselves.")
    val self: Var<Boolean> = ConstVar(false),
) : VisibilityEffectEntry {
    override val supportsSelf: Boolean get() = true

    override fun appliesToSelf(viewer: Player): Boolean = self.get(viewer)

    override fun constantSelf(): Boolean? = (self as? ConstVar)?.value

    override fun createEffector(rule: VisibilityRule): VisibilityEffector =
        InvisibilityVisibilityEffector(rule)
}

private class InvisibilityVisibilityEffector(rule: VisibilityRule) : VisibilityEffector {
    private val overlay = EntityFlagOverlay(rule, EntityFlag.INVISIBLE)

    override suspend fun initialize() = overlay.attach()

    override suspend fun dispose() = overlay.detach()
}
