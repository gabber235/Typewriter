package com.typewritermc.visibility.entry.effect

import com.github.retrooper.packetevents.protocol.player.TextureProperty
import com.github.retrooper.packetevents.wrapper.play.server.WrapperPlayServerPlayerInfoUpdate
import com.typewritermc.core.books.pages.Colors
import com.typewritermc.core.extension.annotations.Entry
import com.typewritermc.core.extension.annotations.Help
import com.typewritermc.core.utils.switchContext
import com.typewritermc.engine.paper.entry.entity.SkinProperty
import com.typewritermc.engine.paper.entry.entries.ConstVar
import com.typewritermc.engine.paper.entry.entries.Var
import com.typewritermc.engine.paper.utils.Sync
import com.typewritermc.visibility.effector.VisibilityEffector
import com.typewritermc.visibility.packet.ProfilePacketHook
import com.typewritermc.visibility.packet.VisibilityPacketBridge
import com.typewritermc.visibility.packet.targetPlayer
import com.typewritermc.visibility.packet.viewerPlayer
import com.typewritermc.visibility.rule.VisibilityRule
import kotlinx.coroutines.Dispatchers
import org.bukkit.entity.Player
import org.koin.core.component.KoinComponent
import org.koin.core.component.inject
import java.util.EnumSet

@Entry(
    "skin_visibility_effect",
    "Changes the skin the viewer sees on the target",
    Colors.MEDIUM_SEA_GREEN,
    "ant-design:skin-filled"
)
/**
 * The `Skin Visibility Effect` changes the skin the viewer sees on the target, in the world and
 * in the tab list. The target keeps their real skin for everyone else.
 *
 * With the self option the target also sees the skin on themselves. Their client only picks up its
 * own new skin on a respawn, so it respawns in place: the player sees a loading screen for a moment
 * and any open inventory closes. A dead player sees the skin once they respawn.
 *
 * ## How could this be used?
 * Give an undercover player a different identity for the players they are infiltrating, or turn
 * everyone into zombies for a player under a hallucination story effect.
 */
class SkinVisibilityEffectEntry(
    override val id: String = "",
    override val name: String = "",
    @Help("The skin the viewer sees on the target.")
    val skin: Var<SkinProperty> = ConstVar(SkinProperty()),
    @Help("Also apply this effect to the target's own view of themselves. Their client respawns in place to show it, which closes an open inventory.")
    val self: Var<Boolean> = ConstVar(false),
) : VisibilityEffectEntry {
    override val supportsSelf: Boolean get() = true

    override fun appliesToSelf(viewer: Player): Boolean = self.get(viewer)

    override fun constantSelf(): Boolean? = (self as? ConstVar)?.value

    override fun createEffector(rule: VisibilityRule): VisibilityEffector = SkinVisibilityEffector(rule, skin)
}

private class SkinVisibilityEffector(
    private val rule: VisibilityRule,
    private val skin: Var<SkinProperty>,
) : VisibilityEffector, ProfilePacketHook, KoinComponent {
    private val bridge: VisibilityPacketBridge by inject()

    @Volatile
    private var textures: TextureProperty? = null

    @Volatile
    private var hooked = false

    override suspend fun initialize() {
        Dispatchers.Sync.switchContext {
            val viewer = rule.viewerPlayer ?: return@switchContext
            rule.targetPlayer ?: return@switchContext

            val property = skin.get(viewer)
            if (property.texture.isBlank()) return@switchContext
            textures = TextureProperty("textures", property.texture, property.signature)

            bridge.addProfileHook(viewer.uniqueId, rule.target, this@SkinVisibilityEffector)
            hooked = true
        }
    }

    // Stays true once the hook is registered, disposal included: the engine reads it again afterwards
    // to decide whether the client has to receive the target under their real profile again.
    override val needsPairRerender: Boolean get() = hooked

    override fun onPlayerInfo(
        actions: EnumSet<WrapperPlayServerPlayerInfoUpdate.Action>,
        entry: WrapperPlayServerPlayerInfoUpdate.PlayerInfo,
    ) {
        if (WrapperPlayServerPlayerInfoUpdate.Action.ADD_PLAYER !in actions) return
        val textures = textures ?: return
        entry.gameProfile.textureProperties = listOf(textures)
    }

    override suspend fun dispose() {
        if (!hooked) return
        textures = null
        Dispatchers.Sync.switchContext {
            bridge.removeProfileHook(rule.viewer, rule.target, this@SkinVisibilityEffector)
        }
    }
}
