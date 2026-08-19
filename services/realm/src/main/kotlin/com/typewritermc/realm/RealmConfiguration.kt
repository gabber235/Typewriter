package com.typewritermc.realm

import com.typewritermc.realm.schema.RealmDatabaseConfiguration
import com.typewritermc.realm.schema.databaseConfiguration
import com.typewritermc.services.libs.registrar.RegistrarConfiguration
import com.typewritermc.services.libs.registrar.ServiceRole
import java.net.URI

internal data class RealmApplicationConfiguration(
    val diagnosticLevel: RealmDiagnosticLevel,
    val telemetry: RealmTelemetryConfiguration,
    val registrar: RegistrarConfiguration,
    val database: RealmDatabaseConfiguration,
)

internal enum class RealmDiagnosticLevel {
    ALL,
    TRACE,
    DEBUG,
    INFO,
    WARN,
    ERROR,
    OFF,
}

internal data class RealmTelemetryConfiguration(
    val otlpEndpoint: String?,
    val sampler: RealmSamplerConfiguration,
)

internal sealed interface RealmSamplerConfiguration {
    data object AlwaysOn : RealmSamplerConfiguration

    data object AlwaysOff : RealmSamplerConfiguration

    data class TraceIdRatio(
        val ratio: Double,
    ) : RealmSamplerConfiguration

    data class ParentBasedTraceIdRatio(
        val ratio: Double,
    ) : RealmSamplerConfiguration
}

internal fun RealmSettings.applicationConfiguration(): RealmApplicationConfiguration =
    RealmApplicationConfiguration(
        diagnosticLevel =
            get("TYPEWRITER_DIAGNOSTIC_LEVEL")
                ?.uppercase()
                ?.let { value -> RealmDiagnosticLevel.entries.firstOrNull { it.name == value } }
                ?: RealmDiagnosticLevel.WARN,
        telemetry =
            RealmTelemetryConfiguration(
                otlpEndpoint = get("OTEL_EXPORTER_OTLP_ENDPOINT"),
                sampler = samplerConfiguration(),
            ),
        registrar = registrarConfiguration(),
        database = databaseConfiguration(),
    )

private fun RealmSettings.registrarConfiguration(): RegistrarConfiguration {
    val apiBase = URI(get("API_BASE_URL", "https://api.typewritermc.com")!!)
    val authBase = URI(get("AUTH_BASE_URL", "https://auth.typewritermc.com")!!)
    return RegistrarConfiguration(
        identityIssueUri = apiBase.resolve("/service/identity/issue"),
        sentinelCredentialsUri = apiBase.resolve("/auth/sentinel"),
        oauthTokenUri = authBase.resolve("/application/o/token/"),
        oauthClientId = get("JWT_CLIENT_ID", "typewriter-services")!!,
        oauthScopes =
            get("JWT_SCOPES", "openid profile entitlements")!!
                .split(' ')
                .filter(String::isNotBlank)
                .toSet(),
        natsServerUri = URI(get("NATS_URL", "nats://nats.seamlezz.com:4222")!!),
        roles = listOf(ServiceRole.Realm(REALM_VERSION)),
    )
}

private fun RealmSettings.samplerConfiguration(): RealmSamplerConfiguration {
    val ratio = get("OTEL_TRACES_SAMPLER_ARG")?.toDoubleOrNull()?.coerceIn(0.0, 1.0) ?: 1.0
    return when (get("OTEL_TRACES_SAMPLER") ?: "always_on") {
        "parentbased_traceidratio" -> RealmSamplerConfiguration.ParentBasedTraceIdRatio(ratio)
        "traceidratio" -> RealmSamplerConfiguration.TraceIdRatio(ratio)
        "always_off" -> RealmSamplerConfiguration.AlwaysOff
        else -> RealmSamplerConfiguration.AlwaysOn
    }
}
