package com.typewritermc.engine.paper.snippets

import com.typewritermc.engine.paper.plugin
import com.typewritermc.engine.paper.utils.get
import com.typewritermc.engine.paper.utils.reloadable
import org.bukkit.configuration.file.YamlConfiguration
import org.koin.core.component.KoinComponent
import kotlin.reflect.KClass
import kotlin.reflect.safeCast

interface SnippetDatabase {
    fun get(path: String, default: Any, comment: String = ""): Any
    fun <T : Any> getSnippet(path: String, klass: KClass<T>, default: T, comment: String = ""): T
    fun registerSnippet(path: String, defaultValue: Any, comment: String = "")
}

class SnippetDatabaseImpl : SnippetDatabase, KoinComponent {
    private val file by lazy {
        val file = plugin.dataFolder["snippets.yml"]
        if (!file.exists()) {
            file.parentFile.mkdirs()
            file.createNewFile()
        }
        file
    }

    private val ymlConfiguration by reloadable { YamlConfiguration.loadConfiguration(file) }
    private val cache by reloadable { mutableMapOf<String, Any>() }

    override fun get(path: String, default: Any, comment: String): Any {
        val cached = cache[path]
        if (cached != null) return cached

        val value = ymlConfiguration.get(path) ?: return default

        cache[path] = value
        return value
    }

    override fun <T : Any> getSnippet(path: String, klass: KClass<T>, default: T, comment: String): T {
        val value = get(path, default, comment)

        val casted = klass.safeCast(value) ?: return default

        return casted
    }

    override fun registerSnippet(path: String, defaultValue: Any, comment: String) {
        if (ymlConfiguration.contains(path)) return

        ymlConfiguration.set(path, defaultValue)
        if (comment.isNotBlank()) {
            ymlConfiguration.setComments(path, comment.lines())
        }
        ymlConfiguration.save(file)

        cache[path] = defaultValue
    }
}