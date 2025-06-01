package com.typewritermc.core.utils

fun String.replaceAll(vararg pairs: Pair<String, String>): String {
    return pairs.fold(this) { acc, (from, to) ->
        acc.replace(from, to)
    }
}

fun tryCatch(error: (Exception) -> Unit = { it.printStackTrace() }, block: () -> Unit) {
    try {
        block()
    } catch (e: Throwable) {
        error(e)
    }
}

suspend fun tryCatchSuspend(error: suspend (Exception) -> Unit = { it.printStackTrace() }, block: suspend () -> Unit) {
    try {
        block()
    } catch (e: Throwable) {
        error(e)
    }
}
