package com.typewritermc.codegen.fixtures

/** The expected errors no report matches, and the reported errors no expectation claims; each report pairs once. */
fun List<ExpectedError>.pairWith(reported: List<ReportedError>): Pair<List<ExpectedError>, List<ReportedError>> {
    val unpaired = reported.toMutableList()
    val missing =
        filter { expected ->
            val match = unpaired.firstOrNull { it.matches(expected) } ?: return@filter true
            unpaired.remove(match)
            false
        }
    return missing to unpaired
}
