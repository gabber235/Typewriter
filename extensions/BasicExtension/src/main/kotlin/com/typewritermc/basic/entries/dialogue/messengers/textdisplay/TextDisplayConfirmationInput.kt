package com.typewritermc.basic.entries.dialogue.messengers.textdisplay

import java.util.concurrent.atomic.AtomicReference

internal class TextDisplayConfirmationInput {
    private val pending = AtomicReference<Any?>()

    fun press(target: Any?) {
        if (target != null) pending.compareAndSet(null, target)
    }

    fun consume(): Any? = pending.getAndSet(null)
}
