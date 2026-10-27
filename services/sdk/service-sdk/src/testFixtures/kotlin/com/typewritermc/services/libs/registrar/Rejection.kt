package com.typewritermc.services.libs.registrar

/** One input a configuration or value type must refuse, with the [message] it is refused with. */
class Rejection(
    val input: String,
    val message: String,
    val build: () -> Any,
)
