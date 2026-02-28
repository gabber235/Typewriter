package com.typewritermc.services.libs.communicator.routing

fun String.join(other: String): String = when {
    this.isEmpty() -> other
    other.isEmpty() -> this
    else -> "$this.$other"
}
