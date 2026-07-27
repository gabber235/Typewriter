package com.typewritermc.basic.entries.fact

import com.typewritermc.engine.paper.entry.entries.GroupId
import com.typewritermc.engine.paper.facts.FactData
import com.typewritermc.engine.paper.facts.FactId
import io.kotest.core.spec.style.FunSpec
import io.kotest.matchers.shouldBe
import java.time.LocalDateTime

class CountdownFactSpec : FunSpec({
    val fact = CountdownFact(id = "countdown")
    val id = FactId("countdown", GroupId("group"))

    fun secondsAgo(seconds: Long) = LocalDateTime.now().minusSeconds(seconds)

    test("a countdown with time left has not expired") {
        fact.hasExpired(id, FactData(10, secondsAgo(3))) shouldBe false
    }

    test("a countdown that has run out has expired") {
        fact.hasExpired(id, FactData(10, secondsAgo(10))) shouldBe true
    }

    test("a cancelled countdown never expires, however long ago it was set") {
        fact.hasExpired(id, FactData(-1, secondsAgo(3600))) shouldBe false
    }
})
