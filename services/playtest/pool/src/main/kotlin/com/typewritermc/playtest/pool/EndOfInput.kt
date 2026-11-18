package com.typewritermc.playtest.pool

import java.io.InputStream
import java.io.OutputStream
import kotlin.concurrent.thread

/**
 * Calls [then] once [input] ends: the build that started the pool closed it as its run ended, or died,
 * as the system closes a dead process's end of the pipe. Whatever the build writes is read and dropped.
 */
internal fun onEndOf(
    input: InputStream,
    then: () -> Unit,
): Thread =
    thread(name = "playtest-pool-input", isDaemon = true) {
        // An input that breaks ends the run as its end does.
        try {
            input.transferTo(OutputStream.nullOutputStream())
        } finally {
            then()
        }
    }
