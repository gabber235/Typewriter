package com.typewritermc.buildlogic

import org.gradle.api.GradleException
import org.gradle.api.provider.Provider
import org.gradle.api.provider.ProviderFactory
import org.gradle.process.ProcessExecutionException
import java.util.Base64

/** Realm database login used by local development servers. */
class RealmDatabaseCredentials(
    val username: String,
    val password: String,
)

private val realmDatabaseCredentialsCommand =
    listOf(
        "kubectl",
        "get",
        "secret",
        "surrealdb-credentials-realm-runtime",
        "--namespace",
        "typewriter",
        "--output",
        """jsonpath={.data.username}{"\n"}{.data.password}""",
    )

/**
 * Reads the Realm database credentials from the `typewriter/surrealdb-credentials-realm-runtime` Kubernetes Secret.
 *
 * `kubectl` runs only when the provider is queried. Querying fails with an actionable message when `kubectl` cannot
 * start, the Secret is unavailable, or the Secret lacks a username and password.
 */
fun ProviderFactory.realmDatabaseCredentials(): Provider<RealmDatabaseCredentials> {
    val credentials = kubernetesRealmDatabaseCredentials()
    return provider {
        try {
            credentials.get()
        } catch (failure: ProcessExecutionException) {
            throw failure.withRealmDatabaseCredentialsContext()
        }
    }
}

private fun ProviderFactory.kubernetesRealmDatabaseCredentials(): Provider<RealmDatabaseCredentials> {
    val kubectl =
        exec {
            isIgnoreExitValue = true
            commandLine(realmDatabaseCredentialsCommand)
        }

    return kubectl.result.zip(
        kubectl.standardOutput.asText.zip(kubectl.standardError.asText) { standardOutput, standardError ->
            standardOutput to standardError
        },
    ) { result, output ->
        val (standardOutput, standardError) = output
        require(result.exitValue == 0) {
            buildString {
                appendLine("Unable to load the Kubernetes Realm database credentials.")
                appendLine("Expected Secret: typewriter/surrealdb-credentials-realm-runtime")
                appendLine(
                    "Apply the Typewriter SurrealDB tenant policy and " +
                        "backend/_clusters/local/surrealdb-credentials-realm-runtime.yaml.",
                )
                if (standardError.isNotBlank()) {
                    append("kubectl: ")
                    append(standardError.trim())
                }
            }.trim()
        }

        val values = standardOutput.lineSequence().filter(String::isNotBlank).toList()
        require(values.size == 2) {
            "Realm database Secret must contain username and password"
        }
        RealmDatabaseCredentials(
            username = values[0].decodeBase64(),
            password = values[1].decodeBase64(),
        )
    }
}

private fun String.decodeBase64(): String = Base64.getDecoder().decode(this).decodeToString()

private fun ProcessExecutionException.withRealmDatabaseCredentialsContext(): GradleException =
    GradleException(
        buildString {
            appendLine("Unable to start kubectl while loading the Kubernetes Realm database credentials.")
            appendLine("Command: ${realmDatabaseCredentialsCommand.joinToString(" ")}")
            appendLine("Working directory: ${System.getProperty("user.dir")}")
            appendLine("PATH: ${System.getenv("PATH").orEmpty()}")
            append("Cause: ${generateSequence<Throwable>(this@withRealmDatabaseCredentialsContext) { it.cause }.last().message}")
        },
        this,
    )
