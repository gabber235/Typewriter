package com.typewritermc.realm

import java.nio.file.Files
import java.nio.file.Path
import java.util.Properties

internal class RealmSettings(
    private val systemProperties: Map<String, String> = emptyMap(),
    private val environment: Map<String, String> = emptyMap(),
    private val configuration: Map<String, String> = emptyMap(),
) {
    fun get(
        name: String,
        default: String? = null,
    ): String? =
        systemProperties.nonBlank(name)
            ?: environment.nonBlank(name)
            ?: configuration.nonBlank(name)
            ?: default

    companion object {
        fun system(): RealmSettings {
            val systemProperties =
                System.getProperties().stringPropertyNames().associateWith(System::getProperty)
            val environment = System.getenv()
            val configurationPath =
                systemProperties.nonBlank(CONFIGURATION_FILE_SETTING)
                    ?: environment.nonBlank(CONFIGURATION_FILE_SETTING)
            val configuration =
                configurationPath
                    ?.let(Path::of)
                    ?.let(::readConfiguration)
                    .orEmpty()
            return RealmSettings(systemProperties, environment, configuration)
        }

        fun fromFile(path: Path): RealmSettings = RealmSettings(configuration = readConfiguration(path))
    }
}

private const val CONFIGURATION_FILE_SETTING = "REALM_CONFIG_FILE"

private fun Map<String, String>.nonBlank(name: String): String? = get(name)?.takeIf(String::isNotBlank)

private fun readConfiguration(path: Path): Map<String, String> {
    require(Files.isRegularFile(path)) { "Realm configuration file does not exist: $path" }
    val properties = Properties()
    Files.newBufferedReader(path).use(properties::load)
    return properties.stringPropertyNames().associateWith(properties::getProperty)
}
