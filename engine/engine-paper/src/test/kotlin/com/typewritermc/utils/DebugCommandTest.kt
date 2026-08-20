package com.typewritermc.utils

import com.typewritermc.engine.paper.command.appendUnparsed
import com.typewritermc.engine.paper.command.formatDuration
import io.kotest.core.spec.style.FunSpec
import io.kotest.matchers.shouldBe
import net.kyori.adventure.text.minimessage.MiniMessage
import net.kyori.adventure.text.minimessage.tag.resolver.Placeholder
import net.kyori.adventure.text.minimessage.tag.resolver.TagResolver
import net.kyori.adventure.text.serializer.plain.PlainTextComponentSerializer

class DebugCommandTest : FunSpec({
    test("uptime omits unused leading units") {
        formatDuration(42_000) shouldBe "42s"
        formatDuration(3_661_000) shouldBe "1h 1m 1s"
        formatDuration(90_061_000) shouldBe "1d 1h 1m 1s"
    }

    test("debug values cannot inject custom MiniMessage tags") {
        val value = "<line><confirmation_key>"
        val resolvers = mutableListOf<TagResolver>()
        val message = buildString { appendUnparsed(value, resolvers) }
        val customTags = TagResolver.builder()
            .resolver(Placeholder.parsed("line", "changed"))
            .resolver(Placeholder.parsed("confirmation_key", "changed"))
            .build()
        val miniMessage = MiniMessage.builder().tags(customTags).build()
        val component = miniMessage.deserialize(message, *resolvers.toTypedArray())

        PlainTextComponentSerializer.plainText().serialize(component) shouldBe value
    }
})
