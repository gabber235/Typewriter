package com.typewritermc.engine.paper.entry.entity

import com.typewritermc.engine.paper.entry.entries.EntityProperty
import kotlinx.serialization.Serializable
import org.bukkit.OfflinePlayer

@Serializable
data class SkinProperty(
    val texture: String = "",
    val signature: String = "",
) : EntityProperty {
    companion object : SinglePropertyCollectorSupplier<SkinProperty>(SkinProperty::class)
}

val OfflinePlayer.skin: SkinProperty
    get() {
        val profile = playerProfile
        if (!profile.hasTextures()) return SkinProperty()
        val textures = profile.properties.firstOrNull { it.name == "textures" } ?: return SkinProperty()

        return SkinProperty(textures.value, textures.signature ?: "")
    }