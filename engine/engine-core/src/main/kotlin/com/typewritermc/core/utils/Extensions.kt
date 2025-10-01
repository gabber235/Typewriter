package com.typewritermc.core.utils

import kotlinx.coroutines.CancellationException
import java.util.Locale.getDefault

fun String.replaceAll(vararg pairs: Pair<String, String>): String {
    return pairs.fold(this) { acc, (from, to) ->
        acc.replace(from, to)
    }
}

val String.formatted
    get() = this.split(".").joinToString(" | ") { group ->
        group.split("_").joinToString(" ") { string ->
            string.replaceFirstChar {
                if (it.isLowerCase()) it.titlecase(
                    getDefault()
                ) else it.toString()
            }
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
    } catch (_: CancellationException) {} catch (e: Throwable) {
        error(e)
    }
}
