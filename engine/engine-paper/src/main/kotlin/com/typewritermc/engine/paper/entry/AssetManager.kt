package com.typewritermc.engine.paper.entry

import com.typewritermc.engine.paper.entry.entries.AssetEntry
import com.typewritermc.engine.paper.plugin
import org.koin.core.component.KoinComponent
import org.koin.core.component.inject

interface AssetStorage {
    @Deprecated("Use storeStringAsset or storeBinaryAsset instead.", ReplaceWith("storeStringAsset(path, content)"))
    suspend fun storeAsset(path: String, content: String)
    suspend fun storeStringAsset(path: String, content: String)
    suspend fun storeBinaryAsset(path: String, content: ByteArray)
    suspend fun containsAsset(path: String): Boolean

    @Deprecated("Use fetchStringAsset instead.", ReplaceWith("fetchStringAsset(path)"))
    suspend fun fetchAsset(path: String): Result<String>
    suspend fun fetchStringAsset(path: String): Result<String>
    suspend fun fetchBinaryAsset(path: String): Result<ByteArray>
    suspend fun deleteAsset(path: String)

    suspend fun fetchAllAssetPaths(): Set<String>
}

class AssetManager : KoinComponent {
    private val storage: AssetStorage by inject()

    fun initialize() {
    }

    @Deprecated("Use storeStringAsset or storeBinaryAsset instead.", ReplaceWith("storeStringAsset(entry, content)"))
    suspend fun storeAsset(entry: AssetEntry, content: String) = storeStringAsset(entry, content)

    suspend fun storeStringAsset(entry: AssetEntry, content: String) {
        storage.storeStringAsset(entry.path, content)
    }

    suspend fun storeBinaryAsset(entry: AssetEntry, content: ByteArray) {
        storage.storeBinaryAsset(entry.path, content)
    }

    suspend fun containsAsset(entry: AssetEntry): Boolean {
        return storage.containsAsset(entry.path)
    }

    @Deprecated("Use fetchStringAsset instead.", ReplaceWith("fetchStringAsset(entry)"))
    suspend fun fetchAsset(entry: AssetEntry): String? = fetchStringAsset(entry)

    suspend fun fetchStringAsset(entry: AssetEntry): String? {
        val result = storage.fetchStringAsset(entry.path)
        if (result.isFailure) {
            plugin.logger.severe("Failed to fetch asset ${entry.path}: ${result.exceptionOrNull()?.message}")
            return null
        }
        return result.getOrNull()
    }

    suspend fun fetchBinaryAsset(entry: AssetEntry): ByteArray? {
        val result = storage.fetchBinaryAsset(entry.path)
        if (result.isFailure) {
            plugin.logger.severe("Failed to fetch binary asset ${entry.path}: ${result.exceptionOrNull()?.message}")
            return null
        }
        return result.getOrNull()
    }

    fun shutdown() {
    }
}

class LocalAssetStorage : AssetStorage {
    @Deprecated(
        "Use storeStringAsset or storeBinaryAsset instead.",
        replaceWith = ReplaceWith("storeStringAsset(path, content)")
    )
    override suspend fun storeAsset(path: String, content: String) = storeStringAsset(path, content)

    override suspend fun storeStringAsset(path: String, content: String) {
        val file = plugin.dataFolder.resolve("assets/$path")
        file.parentFile.mkdirs()
        file.writeText(content)
    }

    override suspend fun storeBinaryAsset(path: String, content: ByteArray) {
        val file = plugin.dataFolder.resolve("assets/$path")
        file.parentFile.mkdirs()
        file.writeBytes(content)
    }

    override suspend fun containsAsset(path: String): Boolean {
        return plugin.dataFolder.resolve("assets/$path").exists()
    }

    @Deprecated("Use fetchStringAsset instead.", replaceWith = ReplaceWith("fetchStringAsset(path)"))
    override suspend fun fetchAsset(path: String): Result<String> = fetchStringAsset(path)

    override suspend fun fetchStringAsset(path: String): Result<String> {
        val file = plugin.dataFolder.resolve("assets/$path")
        if (!file.exists()) {
            return Result.failure(IllegalArgumentException("Asset $path not found."))
        }
        return Result.success(file.readText())
    }

    override suspend fun fetchBinaryAsset(path: String): Result<ByteArray> {
        val file = plugin.dataFolder.resolve("assets/$path")
        if (!file.exists()) {
            return Result.failure(IllegalArgumentException("Asset $path not found."))
        }
        return Result.success(file.readBytes())
    }

    override suspend fun deleteAsset(path: String) {
        val asset = plugin.dataFolder.resolve("assets/$path")
        val deletedAsset = plugin.dataFolder.resolve("deleted_assets/$path")
        deletedAsset.parentFile.mkdirs()
        asset.renameTo(deletedAsset)
    }

    override suspend fun fetchAllAssetPaths(): Set<String> {
        return plugin.dataFolder.resolve("assets").walk().filter { it.isFile }
            .map { it.relativeTo(plugin.dataFolder.resolve("assets")).path }.toSet()
    }
}
