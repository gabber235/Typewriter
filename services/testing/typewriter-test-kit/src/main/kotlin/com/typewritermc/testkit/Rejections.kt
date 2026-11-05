package com.typewritermc.testkit

/**
 * The message of the [IllegalArgumentException] that [block] throws; fails when [block] throws nothing.
 * Any other exception propagates and fails the test with its own cause.
 */
fun rejectionOf(block: () -> Unit): String? {
    try {
        block()
    } catch (rejection: IllegalArgumentException) {
        return rejection.message
    }
    throw AssertionError("Expected an IllegalArgumentException, but nothing was thrown.")
}

/** A value a check must refuse: [check] throws, and the refusal carries [reason]. Tables of refusals name each case with it. */
class Rejection(
    val reason: String,
    val check: () -> Unit,
)
