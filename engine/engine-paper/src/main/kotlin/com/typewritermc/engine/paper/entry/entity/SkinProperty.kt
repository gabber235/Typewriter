package com.typewritermc.engine.paper.entry.entity

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
        .expireAfterAccess(10, java.util.concurrent.TimeUnit.MINUTES)
        .build<UUID, SkinProperty>()
    private val jobs = ConcurrentHashMap<UUID, Job>()

    operator fun get(playerId: UUID): SkinProperty {
        cache.getIfPresent(playerId)?.let { return it }
        cache.put(playerId, SkinProperty())
        jobs[playerId]?.cancel()
        jobs[playerId] = Dispatchers.UntickedAsync.launch {
            val offlinePlayer = Bukkit.getOfflinePlayer(playerId)
            var profile = offlinePlayer.playerProfile
            if (!profile.hasTextures()) {
                profile = profile.update().await()
            }

            val textures = profile.properties.firstOrNull { it.name == "textures" } ?: return@launch
            val skin = SkinProperty(textures.value, textures.signature ?: "")
            cache.put(playerId, skin)
        }
        return SkinProperty()
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