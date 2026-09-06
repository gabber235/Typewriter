package com.typewritermc.realm

import com.typewritermc.realm.schema.RealmDatabaseConfiguration
import com.typewritermc.realm.schema.databaseConfiguration

/**
 * Collects resolved diagnostic and database policy before Realm composition.
 *
 * The settings adapter defaults unknown diagnostic levels to WARN; database configuration performs its own
 * validation.
 */
internal data class RealmApplicationConfiguration(
    val diagnosticLevel: RealmDiagnosticLevel,
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

internal fun RealmSettings.applicationConfiguration(): RealmApplicationConfiguration =
    RealmApplicationConfiguration(
        diagnosticLevel =
            get("TYPEWRITER_DIAGNOSTIC_LEVEL")
                ?.uppercase()
                ?.let { value -> RealmDiagnosticLevel.entries.firstOrNull { it.name == value } }
                ?: RealmDiagnosticLevel.WARN,
        database = databaseConfiguration(),
    )
