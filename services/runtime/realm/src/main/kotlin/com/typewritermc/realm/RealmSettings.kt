package com.typewritermc.realm

import com.typewritermc.types.use
import java.nio.file.Files
import java.nio.file.Path
import java.util.Properties

/**
 * Resolves nonblank settings in system property, environment, configuration file, then default order.
 *
 * The system factory snapshots process inputs and loads TYPEWRITER_CONFIG_FILE when specified. Missing configured
 * files fail immediately; settings do not refresh automatically.
 */
internal class RealmSettings(
    private val systemProperties: Map<String, String> = emptyMap(),
    private val environment: Map<String, String> = emptyMap(),
    private val configuration: Map<String, String> = emptyMap(),
) {
    /**
     * Returns one nonblank setting using the precedence system properties, environment, file, then default.
     *
     * The lookup is a snapshot of the maps supplied to this instance. A blank higher precedence value is ignored,
     * allowing deployment configuration to fall through to a useful lower precedence value.
     */
    fun get(
        name: String,
        default: String? = null,
    ): String? =
        systemProperties.nonBlank(name)
            ?: environment.nonBlank(name)
            ?: configuration.nonBlank(name)
            ?: default

    companion object {
        /** Captures process settings and the optional configuration file selected by the process. */
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

        /** Loads a fixed configuration file, primarily for composition and deterministic tests. */
        fun fromFile(path: Path): RealmSettings = RealmSettings(configuration = readConfiguration(path))
    }
}

private const val CONFIGURATION_FILE_SETTING = "TYPEWRITER_CONFIG_FILE"

private fun Map<String, String>.nonBlank(name: String): String? = get(name)?.takeIf(String::isNotBlank)

private fun readConfiguration(path: Path): Map<String, String> {
    require(Files.isRegularFile(path)) { "Realm configuration file does not exist: $path" }
    val properties = Properties()
    Files.newBufferedReader(path).use(properties::load)
    return properties.stringPropertyNames().associateWith(properties::getProperty)
}
