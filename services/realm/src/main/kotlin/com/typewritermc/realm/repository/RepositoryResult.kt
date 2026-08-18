package com.typewritermc.realm.repository

import skirout.kernel.v1.record_id.RecordId

sealed interface RepositoryResult<out Value> {
    data class Success<Value>(
        val value: Value,
    ) : RepositoryResult<Value>

    data class DomainFailure(
        val slug: String,
        val relatedIds: List<RecordId> = emptyList(),
    ) : RepositoryResult<Nothing>
}

sealed interface RevisionedRepositoryResult<out Value> {
    data class Success<Value>(
        val value: Value,
    ) : RevisionedRepositoryResult<Value>

    data class Conflict<Value>(
        val actual: Value,
    ) : RevisionedRepositoryResult<Value>

    data class DomainFailure(
        val slug: String,
        val relatedIds: List<RecordId> = emptyList(),
    ) : RevisionedRepositoryResult<Nothing>
}

internal inline fun <Value> revisionedRepositoryMutation(
    relatedIds: List<RecordId> = emptyList(),
    operation: () -> RevisionedRepositoryResult<Value>,
): RevisionedRepositoryResult<Value> =
    try {
        operation()
    } catch (failure: RuntimeException) {
        val slug = failure.domainSlug() ?: throw failure
        RevisionedRepositoryResult.DomainFailure(slug, relatedIds)
    }

internal inline fun <Value> repositoryMutation(
    relatedIds: List<RecordId> = emptyList(),
    operation: () -> Value,
): RepositoryResult<Value> =
    try {
        RepositoryResult.Success(operation())
    } catch (failure: RuntimeException) {
        val slug = failure.domainSlug() ?: throw failure
        RepositoryResult.DomainFailure(slug, relatedIds)
    }

private fun Throwable.domainSlug(): String? =
    generateSequence(this) { it.cause }
        .mapNotNull(Throwable::message)
        .flatMap { DOMAIN_SLUG.findAll(it).map(MatchResult::value) }
        .firstOrNull()

private val DOMAIN_SLUG = Regex("[a-z][a-z0-9-]*-error")
