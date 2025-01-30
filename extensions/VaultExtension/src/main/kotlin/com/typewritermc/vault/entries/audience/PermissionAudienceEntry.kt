package com.typewritermc.vault.entries.audience

import com.typewritermc.core.books.pages.Colors
import com.typewritermc.core.entries.Ref
import com.typewritermc.core.entries.ref
import com.typewritermc.core.extension.annotations.Entry
import com.typewritermc.core.extension.annotations.Help
import com.typewritermc.engine.paper.entry.entries.*
import com.typewritermc.vault.VaultInitializer
import net.milkbowl.vault.permission.Permission
import org.bukkit.entity.Player
import org.koin.java.KoinJavaComponent

@Entry(
    "permission_audience",
    "Filters an audience based on if they have a specific permission",
    Colors.MEDIUM_SEA_GREEN,
    "fa6-solid:user-shield"
)
/**
 * The `PermissionAudienceEntry` filters an audience based on if they have a specific permission.
 *
 * ## How could this be used?
 * This can be used to show certain content only to players with specific permissions.
 * For example, only showing admin commands to players with the `admin` permission.
 */
class PermissionAudienceEntry(
    override val id: String = "",
    override val name: String = "",
    override val children: List<Ref<AudienceEntry>> = emptyList(),
    @Help("The permission to check for.")
    val permission: String = "",
    override val inverted: Boolean = false,
) : AudienceFilterEntry, Invertible {
    override suspend fun display(): AudienceFilter = PermissionAudienceFilter(ref(), permission)
}

class PermissionAudienceFilter(
    ref: Ref<out AudienceFilterEntry>,
    private val permission: String,
) : AudienceFilter(ref), TickableDisplay {
    override fun filter(player: Player): Boolean {
        val permissionHandler: Permission =
            KoinJavaComponent.get<VaultInitializer>(VaultInitializer::class.java).permissions ?: return false
        return permissionHandler.playerHas(player, permission)
    }

    override fun tick() {
        consideredPlayers.forEach { it.refresh() }
    }
}