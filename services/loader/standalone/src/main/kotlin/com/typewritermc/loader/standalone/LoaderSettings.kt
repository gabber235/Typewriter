package com.typewritermc.loader.standalone

import com.typewritermc.services.libs.registrar.RegistrarConfiguration
import com.typewritermc.services.libs.registrar.ServiceRole
import java.net.URI
import java.nio.file.Files
import java.nio.file.Path
import java.util.Properties

internal class LoaderSettings(
    private val properties: Map<String, String> = emptyMap(),
    private val environment: Map<String, String> = emptyMap(),
    private val configuration: Map<String, String> = emptyMap(),
) {
    fun get(
        name: String,
        default: String,
    ): String = getOrNull(name) ?: default

    fun getOrNull(name: String): String? =
        properties[name]?.takeIf(String::isNotBlank)
            ?: environment[name]?.takeIf(String::isNotBlank)
            ?: configuration[name]?.takeIf(String::isNotBlank)

    companion object {
        fun system(): LoaderSettings {
            val properties = System.getProperties().stringPropertyNames().associateWith(System::getProperty)
            val environment = System.getenv()
            val path =
                properties[CONFIGURATION_FILE_SETTING]?.takeIf(String::isNotBlank)
                    ?: environment[CONFIGURATION_FILE_SETTING]?.takeIf(String::isNotBlank)
            return LoaderSettings(properties, environment, path?.let(Path::of)?.let(::readConfiguration).orEmpty())
        }

        fun fromFile(path: Path): LoaderSettings = LoaderSettings(configuration = readConfiguration(path))
    }
}

internal data class LoaderTelemetryConfiguration(
    val otlpEndpoint: String?,
    val sampler: LoaderSamplerConfiguration,
)

internal sealed interface LoaderSamplerConfiguration {
    data object AlwaysOn : LoaderSamplerConfiguration

    data object AlwaysOff : LoaderSamplerConfiguration

    data class TraceIdRatio(
        val ratio: Double,
    ) : LoaderSamplerConfiguration

    data class ParentBasedTraceIdRatio(
        val ratio: Double,
    ) : LoaderSamplerConfiguration
}

internal fun LoaderSettings.telemetryConfiguration(): LoaderTelemetryConfiguration =
    LoaderTelemetryConfiguration(
        otlpEndpoint = get("OTEL_EXPORTER_OTLP_ENDPOINT", "").ifBlank { null },
        sampler = samplerConfiguration(),
    )

internal fun LoaderSettings.registrarConfiguration(): RegistrarConfiguration {
    val apiBase = URI(get("API_BASE_URL", "https://api.typewritermc.com"))
    val authBase = URI(get("AUTH_BASE_URL", "https://auth.typewritermc.com"))

    return RegistrarConfiguration(
        identityIssueUri = apiBase.resolve("/service/identity/issue"),
        sentinelCredentialsUri = apiBase.resolve("/auth/sentinel"),
        oauthTokenUri = authBase.resolve("/application/o/token/"),
        oauthClientId = get("JWT_CLIENT_ID", "typewriter-services"),
        oauthScopes = get("JWT_SCOPES", "openid profile entitlements").split(' ').filter(String::isNotBlank).toSet(),
        natsServerUri = URI(get("NATS_URL", "nats://nats.seamlezz.com:4222")),
        role = ServiceRole.Host(LOADER_VERSION),
    )
}

private fun readConfiguration(path: Path): Map<String, String> {
    require(Files.isRegularFile(path)) { "Loader configuration file does not exist: $path" }
    val properties = Properties()
    Files.newBufferedReader(path).use(properties::load)
    return properties.stringPropertyNames().associateWith(properties::getProperty)
}

private fun LoaderSettings.samplerConfiguration(): LoaderSamplerConfiguration {
    val ratio = get("OTEL_TRACES_SAMPLER_ARG", "1.0").toDoubleOrNull()?.coerceIn(0.0, 1.0) ?: 1.0
    return when (get("OTEL_TRACES_SAMPLER", "always_on")) {
        "parentbased_traceidratio" -> LoaderSamplerConfiguration.ParentBasedTraceIdRatio(ratio)
        "traceidratio" -> LoaderSamplerConfiguration.TraceIdRatio(ratio)
        "always_off" -> LoaderSamplerConfiguration.AlwaysOff
        else -> LoaderSamplerConfiguration.AlwaysOn
    }
}

private const val CONFIGURATION_FILE_SETTING = "LOADER_CONFIG_FILE"
