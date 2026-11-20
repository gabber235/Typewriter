package com.typewritermc.playtest.pool

/**
 * A player its attempt sent away from its Paper as a person quits, from its quit until its client steps
 * with that Paper again. It stays on the attempt's lease and is no lost client meanwhile.
 */
internal sealed interface Away {
    /**
     * Its client leaves; Paper seeing it leave answers the session's quit [request]. Without a request
     * the attempt ended meanwhile, and the player comes back to the shared Paper once it left.
     */
    data class Leaving(
        val request: Long?,
    ) : Away

    /** It is off Paper until its attempt asks it back. */
    data object Gone : Away

    /** Its client joins its Paper again; Paper taking it back answers the session's rejoin [request]. */
    data class Joining(
        val request: Long,
    ) : Away

    /** What a Paper seeing the player leave means. */
    sealed interface Left {
        /** A Paper the pool moved the player off saw it go late: it left that one on purpose. */
        data object Moved : Left

        /** Its own Paper saw it leave as it quit: the quit [request] is answered. */
        data class QuitDone(
            val request: Long,
        ) : Left

        /** Its own Paper saw it leave after its attempt ended: it comes back to the shared Paper. */
        data object ComeBack : Left

        /** It left its own Paper on no quit of its attempt: its client is lost. */
        data object Lost : Left
    }

    /**
     * What a Paper seeing the player leave means; [onItsPaper] tells whether that Paper is the one the
     * pool has it on. A Paper it was moved off, as the shared one it left for its attempt's own, can
     * report the leave after the quit began, and must not answer that quit.
     */
    fun left(onItsPaper: Boolean): Left =
        when {
            !onItsPaper -> Left.Moved
            this is Leaving -> request?.let { Left.QuitDone(it) } ?: Left.ComeBack
            else -> Left.Lost
        }
}
