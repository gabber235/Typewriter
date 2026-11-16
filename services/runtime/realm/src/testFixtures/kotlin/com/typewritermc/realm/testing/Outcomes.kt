package com.typewritermc.realm.testing

import com.typewritermc.authoring.text
import com.typewritermc.realm.edit.WorkingViewEditContext
import io.kotest.assertions.withClue
import io.kotest.matchers.collections.shouldContainAll
import io.kotest.matchers.shouldBe
import io.kotest.matchers.types.shouldBeInstanceOf
import skirout.editor.v1.authoring.AuthoringDiagnostic
import skirout.editor.v1.authoring.AuthoringState
import skirout.editor.v1.authoring.CommitPreparedEditResponse
import skirout.editor.v1.authoring.EditIntent
import skirout.editor.v1.authoring.PreparedEdit
import skirout.editor.v1.authoring_facts.EditExpectation
import skirout.editor.v1.diagnostic.ValueProblem

/** A refusal reason where an author sees it: the resource it applies to and its code. */
data class Refusal(
    val resource: String,
    val code: String,
)

/** The refusal reasons of [problems], as resource and code. */
val List<ValueProblem>.refusals: List<Refusal> get() = map { Refusal(it.location.resource.value, it.code) }

/** The codes of [problems]. */
val List<ValueProblem>.codes: List<String> get() = map { it.code }

/** Asserts the commit was refused for at least [codes] and returns every problem it named. */
fun CommitPreparedEditResponse.shouldBeRejected(vararg codes: String): List<ValueProblem> {
    val problems = shouldBeInstanceOf<CommitPreparedEditResponse.RejectedErrorWrapper>().value
    withClue("refused for ${problems.codes}") { problems.codes shouldContainAll codes.toList() }
    return problems
}

/** Asserts the commit was refused for [code] at the path [path] of the resource [resource]. */
fun CommitPreparedEditResponse.shouldBeRejectedAt(
    resource: String,
    path: String,
    code: String,
) {
    shouldBeRejected(code).filter { it.code == code }.map { it.location.resource.value to it.location.path.text } shouldContainAll
        listOf(resource to path)
}

/** Commits [intents], asserts they are refused and that nothing was saved, and returns the problems named. */
suspend fun RealmFixture.expectRefused(vararg intents: EditIntent): List<ValueProblem> = expectUnchanged { commit(*intents) }

/**
 * Commits [intent] alone with no expectations, as a stale or hand written edit would, asserts it is refused and that
 * nothing was saved, and returns the problems named.
 */
suspend fun RealmFixture.expectRefusedUnguarded(intent: EditIntent): List<ValueProblem> =
    expectUnchanged { commit(PreparedEdit(catalog = generation, expectations = emptyList(), intents = listOf(intent))) }

/** The facts as they were saved when the commit conflicted. */
fun CommitPreparedEditResponse.conflictingFacts(): List<EditExpectation> =
    shouldBeInstanceOf<CommitPreparedEditResponse.ConflictErrorWrapper>().value.map { it.actual }

/** Commits what [block] writes, asserts it is refused and that nothing was saved, and returns the problems named. */
internal suspend fun RealmFixture.expectRefused(block: suspend WorkingViewEditContext.() -> Unit): List<ValueProblem> =
    expectUnchanged { commit(block) }

private suspend fun RealmFixture.expectUnchanged(commit: suspend () -> CommitPreparedEditResponse): List<ValueProblem> {
    val before = resources
    val problems = commit().shouldBeRejected()
    resources shouldBe before
    return problems
}

/** Asserts the commit was admitted and returns the saved state its reply carried. */
fun CommitPreparedEditResponse.shouldBeCommitted(): AuthoringState = shouldBeInstanceOf<CommitPreparedEditResponse.CommittedWrapper>().value

/** Asserts the commit was refused as a request no editor may send, for at least [codes], and returns its diagnostics. */
fun CommitPreparedEditResponse.shouldBeInvalid(vararg codes: String): List<AuthoringDiagnostic> {
    val diagnostics = shouldBeInstanceOf<CommitPreparedEditResponse.InvalidErrorWrapper>().value.diagnostics
    diagnostics.map { it.code } shouldContainAll codes.toList()
    return diagnostics
}
