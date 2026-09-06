package com.typewritermc.realm.repository

import com.surrealdb.ErrorKind
import com.surrealdb.ServerException

/**
 * Maps recognized database domain errors to stable protocol identifiers.
 *
 * Thrown message matching is exact; unknown errors remain exceptional rather than being guessed into a domain
 * category.
 */
enum class RepositoryFailure(
    val wireValue: String,
) {
    BOOK_NOT_FOUND("book-not-found-error"),
    PAGE_NOT_FOUND("page-not-found-error"),
    PAGE_NAME_INVALID("page-name-invalid-error"),
    PAGE_CHAPTER_INVALID("page-chapter-invalid-error"),
    ;

    companion object {
        fun fromWireValue(value: String): RepositoryFailure? = entries.singleOrNull { it.wireValue == value }

        fun fromThrownMessage(message: String): RepositoryFailure? =
            entries.singleOrNull { message == "An error occurred: ${it.wireValue}" }
    }
}

/**
 * Separates repository success from recognized domain rejection.
 *
 * Unexpected database and transport errors remain exceptions with their causes preserved.
 */
sealed interface RepositoryResult<out Value> {
    data class Success<Value>(
        val value: Value,
    ) : RepositoryResult<Value>

    data class DomainFailure(
        val failure: RepositoryFailure,
    ) : RepositoryResult<Nothing>
}

/**
 * Converts only recognized Surreal THROWN failures into typed domain results.
 *
 * All other runtime failures propagate unchanged.
 */
internal inline fun <Value> repositoryMutation(operation: () -> Value): RepositoryResult<Value> =
    try {
        RepositoryResult.Success(operation())
    } catch (failure: RuntimeException) {
        val serverFailure =
            generateSequence<Throwable>(failure) { it.cause }
                .filterIsInstance<ServerException>()
                .firstOrNull() ?: throw failure
        val thrown = serverFailure.findCause(ErrorKind.THROWN) ?: throw failure
        val message = thrown.message ?: throw failure
        val domainFailure = RepositoryFailure.fromThrownMessage(message) ?: throw failure
        RepositoryResult.DomainFailure(domainFailure)
    }
