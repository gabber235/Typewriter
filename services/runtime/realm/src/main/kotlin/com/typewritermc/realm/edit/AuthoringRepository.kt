package com.typewritermc.realm.edit

import com.typewritermc.authoring.SubmissionKey
import com.typewritermc.realm.authoring.AuthoringSeed
import skirout.editor.v1.authoring.AuthoringDiagnostic
import skirout.editor.v1.authoring.AuthoringInvalid
import skirout.editor.v1.authoring.CommitPreparedEditResponse
import skirout.editor.v1.authoring.PreparedEdit
import skirout.editor.v1.authoring.RelationProjectionDelta
import skirout.editor.v1.type_catalog.AuthoringRecord
import skirout.kernel.v1.resource_id.ResourceId

/** Accepts edits when their original expected facts still hold; a committed [submission] is never applied again. */
interface AuthoringRepository {
    suspend fun commit(
        edit: PreparedEdit,
        submission: SubmissionKey,
    ): CommitPreparedEditResponse
}

data class AuthoringMutationPlan(
    val resources: Map<ResourceId, AuthoringRecord>,
    val removedResources: Set<ResourceId>,
    val relations: RelationProjectionDelta,
)

internal interface AuthoringStorage {
    fun readCoherent(): AuthoringSeed

    /** The request digest a kept commit stored under [submission], or null when no kept commit carried it. */
    fun submittedRequest(submission: SubmissionKey): String?

    /** Saves [plan] and the [submission] with its [request] digest in one transaction, forgetting the oldest keys beyond the bound. */
    fun persistAtomic(
        plan: AuthoringMutationPlan,
        submission: SubmissionKey,
        request: String,
    )
}

/** The refusal of a commit request no editor may send, naming [code] and the [message] that explains it. */
internal fun invalidCommit(
    code: String,
    message: String,
) = CommitPreparedEditResponse.InvalidErrorWrapper(
    AuthoringInvalid(diagnostics = listOf(AuthoringDiagnostic(code = code, message = message, resource = null, path = null))),
)
