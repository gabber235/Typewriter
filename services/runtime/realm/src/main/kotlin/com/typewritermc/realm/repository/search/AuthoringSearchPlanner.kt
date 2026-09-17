package com.typewritermc.realm.repository.search

import com.typewritermc.library.ChapterPath

internal object AuthoringSearchPlanner {
    fun rankDefaults(
        candidates: List<AuthoringSearchHit>,
        context: AuthoringSearchContext?,
    ): List<AuthoringSearchHit> =
        candidates.sortedWith(
            compareByDescending<AuthoringSearchHit> { it.contextBoost(context) }
                .thenBy(AuthoringSearchHit::title),
        )

    fun rank(
        candidates: List<AuthoringSearchCandidate>,
        context: AuthoringSearchContext?,
        limit: Int,
    ): List<AuthoringSearchHit> =
        candidates
            .groupBy { it.hit.resource }
            .map { (_, evidence) ->
                val strongest = evidence.maxBy { it.evidence.score }
                val coverage = evidence.mapNotNull { it.evidence.term }.distinct().size * TERM_COVERAGE_BOOST
                RankedHit(
                    strongest.hit,
                    strongest.evidence.score + coverage + strongest.hit.contextBoost(context),
                )
            }.sortedWith(compareByDescending<RankedHit>(RankedHit::score).thenBy { it.hit.title })
            .map(RankedHit::hit)
            .take(limit)
}

private data class RankedHit(
    val hit: AuthoringSearchHit,
    val score: Double,
)

private fun AuthoringSearchHit.contextBoost(context: AuthoringSearchContext?): Double {
    if (context == null || contextBook != context.book) return 0.0
    val pageBoost = if (contextPage == context.page) CURRENT_PAGE_BOOST else 0.0
    val chapterBoost =
        contextChapter?.let { candidate ->
            MAX_CHAPTER_BOOST / (chapterDistance(context.chapter, candidate) + 1)
        } ?: 0.0
    return SAME_BOOK_BOOST + chapterBoost + pageBoost
}

internal fun chapterDistance(
    left: ChapterPath,
    right: ChapterPath,
): Int {
    val leftParts = left.segments()
    val rightParts = right.segments()
    val shared = leftParts.zip(rightParts).takeWhile { (leftPart, rightPart) -> leftPart == rightPart }.size
    return leftParts.size + rightParts.size - 2 * shared
}

private fun ChapterPath.segments(): List<String> = if (isRoot) emptyList() else value.split('.')

private const val CURRENT_PAGE_BOOST = 0.3
private const val MAX_CHAPTER_BOOST = 0.2
private const val SAME_BOOK_BOOST = 0.1
private const val TERM_COVERAGE_BOOST = 0.7
