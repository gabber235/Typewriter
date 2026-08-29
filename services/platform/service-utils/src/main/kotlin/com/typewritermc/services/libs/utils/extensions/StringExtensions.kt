package com.typewritermc.services.libs.utils.extensions

fun String.nullIfBlank() = ifBlank { null }
