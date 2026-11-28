package com.typewritermc.playtest.pool

/** The pool's own log: what the pool tells whoever reads `pool.log`, into which the build appends its output. */
internal object PoolLog {
    /**
     * Writes [text] as a line of the pool's log.
     *
     * The pool's standard error is its log: the build redirects it into pool.log, and the pool has no telemetry.
     */
    @Suppress("ForbiddenMethodCall")
    fun line(text: String) = System.err.println(text)
}
