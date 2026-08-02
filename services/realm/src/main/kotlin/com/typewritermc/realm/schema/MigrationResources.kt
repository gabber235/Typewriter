package com.typewritermc.realm.schema

import java.security.MessageDigest

private const val MIGRATION_SCHEMA_PATH = "schema/migration.surql"
private const val REALM_SCHEMA_INDEX_PATH = "schema/realm/_index.txt"
private const val REALM_SCHEMA_DIRECTORY = "schema/realm"
private const val PATCH_INDEX_PATH = "schema/patches/_index.txt"
private const val PATCH_DIRECTORY = "schema/patches"
private val SCHEMA_FILENAME_PATTERN = Regex("^(?:[a-z0-9_]+/)*[a-z0-9_]+\\.surql$")
private val PATCH_FILENAME_PATTERN = Regex("^[0-9]{4}_[a-z0-9_]+\\.surql$")

internal class MigrationResources(
    private val loadText: (String) -> String? = ::loadClasspathResource,
) {

    fun loadMigrationSchema(): String = loadRequiredResource(MIGRATION_SCHEMA_PATH)

    fun loadRealmSchema(): List<SchemaResource> {
        val filenames = loadIndex(REALM_SCHEMA_INDEX_PATH)
        require(filenames.isNotEmpty()) { "Realm schema index must not be empty" }

        return filenames.map { filename ->
            require(SCHEMA_FILENAME_PATTERN.matches(filename)) {
                "Invalid Realm schema filename: $filename"
            }
            SchemaResource(
                path = filename,
                script = loadRequiredResource("$REALM_SCHEMA_DIRECTORY/$filename"),
            )
        }
    }

    fun loadPatches(): List<DatabasePatch> {
        val filenames = loadIndex(PATCH_INDEX_PATH)

        require(filenames == filenames.sorted()) {
            "Patch index must be sorted in ascending filename order"
        }

        return filenames.map(::loadPatch)
    }

    private fun loadIndex(path: String): List<String> {
        val index = loadText(path) ?: throw MissingMigrationResourceException(path)
        val filenames = index.lineSequence().map(String::trim).filter(String::isNotEmpty).toList()
        require(filenames.size == filenames.distinct().size) {
            "Resource index contains duplicate filenames: $path"
        }
        return filenames
    }

    private fun loadPatch(filename: String): DatabasePatch {
        require(PATCH_FILENAME_PATTERN.matches(filename)) {
            "Invalid patch filename: $filename"
        }
        val script = loadRequiredResource("$PATCH_DIRECTORY/$filename")
        return DatabasePatch(
            id = filename.removeSuffix(".surql"),
            script = script,
            checksum = script.sha256(),
        )
    }

    private fun loadRequiredResource(path: String): String {
        val content = loadText(path) ?: throw MissingMigrationResourceException(path)
        require(content.isNotBlank()) { "Migration resource is empty: $path" }
        return content
    }
}

internal data class SchemaResource(
    val path: String,
    val script: String,
)

internal data class DatabasePatch(
    val id: String,
    val script: String,
    val checksum: String,
)

internal class MissingMigrationResourceException(path: String) :
    IllegalStateException("Migration resource not found: $path")

private fun loadClasspathResource(path: String): String? =
    MigrationResources::class.java.classLoader
        .getResourceAsStream(path)
        ?.bufferedReader()
        ?.use { it.readText() }

private fun String.sha256(): String = MessageDigest.getInstance("SHA-256")
    .digest(toByteArray(Charsets.UTF_8))
    .joinToString("") { byte -> "%02x".format(byte) }
