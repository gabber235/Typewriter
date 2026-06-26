package com.typewritermc.engine.paper.entry.entity

import com.destroystokyo.paper.profile.PlayerProfile
import com.google.common.cache.CacheBuilder
import com.typewritermc.core.extension.Initializable
import com.typewritermc.core.utils.UntickedAsync
import com.typewritermc.core.utils.launch
import com.typewritermc.engine.paper.entry.entries.EntityProperty
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.Job
import kotlinx.coroutines.future.await
import org.bukkit.Bukkit
import org.bukkit.OfflinePlayer
import org.koin.java.KoinJavaComponent
import java.time.Duration
import java.util.*
import java.util.concurrent.ConcurrentHashMap

data class SkinProperty(
    val texture: String = "",
    val signature: String = "",
) : EntityProperty {
    companion object : SinglePropertyCollectorSupplier<SkinProperty>(SkinProperty::class)
}

class PlayerSkinCache : Initializable {
    private val cache = CacheBuilder.newBuilder()
        .expireAfterAccess(Duration.ofMinutes(10))
        .build<UUID, SkinProperty>()
    private val jobs = ConcurrentHashMap<UUID, Job>()

    context(player: OfflinePlayer?)
    operator fun get(playerId: UUID): SkinProperty {
        cache.getIfPresent(playerId)?.let { return it }
        val offlinePlayer = player ?: Bukkit.getOfflinePlayer(playerId)
        val profile = offlinePlayer.playerProfile

        if (profile.hasTextures()) {
            cache(playerId, profile)?.let { return it }
        }

        cache.put(playerId, SkinProperty())
        jobs[playerId]?.cancel()
        jobs[playerId] = Dispatchers.UntickedAsync.launch {
            val offlinePlayer = player ?: Bukkit.getOfflinePlayer(playerId)
            val profile = offlinePlayer.playerProfile.update().await()
            cache(playerId, profile)
        }
        return SkinProperty()
    }

    private fun cache(playerId: UUID, profile: PlayerProfile): SkinProperty? {
        val textures = profile.properties.firstOrNull { it.name == "textures" } ?: return null
        val skin = SkinProperty(textures.value, textures.signature ?: "")
        cache.put(playerId, skin)
        return skin
    }

    override suspend fun initialize() {}

    override suspend fun shutdown() {
        jobs.values.forEach { it.cancel() }
        jobs.clear()
        cache.invalidateAll()
    }
}

val OfflinePlayer.skin: SkinProperty
    get() = KoinJavaComponent.get<PlayerSkinCache>(PlayerSkinCache::class.java)[uniqueId]