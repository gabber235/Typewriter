package com.typewritermc.engine.paper.entry

import com.typewritermc.core.entries.Query
import io.kotest.assertions.throwables.shouldThrow
import io.kotest.core.spec.style.FunSpec
import io.kotest.matchers.shouldBe
import io.kotest.matchers.types.shouldBeSameInstanceAs
import io.mockk.mockk
import org.bukkit.event.Event
import org.bukkit.event.player.PlayerJoinEvent
import java.lang.reflect.Parameter

/**
 * Characterization tests for the parameter resolution used when dispatching `@EntryListener`s.
 *
 * They freeze the behaviour of [ParameterGenerator] as it was when resolution happened inside the
 * per-event lambda. Hoisting it to load time must not change which generator is chosen for a
 * parameter, the order generators come back in, or how an unsupported parameter is rejected.
 */
@Suppress("UNUSED_PARAMETER")
private object ListenerShapes {
    @JvmStatic
    fun eventOnly(event: PlayerJoinEvent) = Unit

    @JvmStatic
    fun eventThenQuery(event: PlayerJoinEvent, query: Query<*>) = Unit

    @JvmStatic
    fun queryThenEvent(query: Query<*>, event: PlayerJoinEvent) = Unit

    @JvmStatic
    fun baseEvent(event: Event) = Unit

    @JvmStatic
    fun unsupported(text: String) = Unit

    @JvmStatic
    fun noParameters() = Unit

    fun parametersOf(name: String): Array<Parameter> =
        ListenerShapes::class.java.declaredMethods.first { it.name == name }.parameters
}

class ParameterGeneratorCharacterizationTest : FunSpec({

    test("a lone event parameter resolves to the event generator") {
        val generators = ParameterGenerator.getGenerators(ListenerShapes.parametersOf("eventOnly"))

        generators shouldBe listOf(ParameterGenerator.EventParameterGenerator)
    }

    test("generators come back in parameter order") {
        ParameterGenerator.getGenerators(ListenerShapes.parametersOf("eventThenQuery")) shouldBe
            listOf(ParameterGenerator.EventParameterGenerator, ParameterGenerator.QueryParameterGenerator)

        ParameterGenerator.getGenerators(ListenerShapes.parametersOf("queryThenEvent")) shouldBe
            listOf(ParameterGenerator.QueryParameterGenerator, ParameterGenerator.EventParameterGenerator)
    }

    test("the base Event type is accepted like any subclass") {
        ParameterGenerator.getGenerators(ListenerShapes.parametersOf("baseEvent")) shouldBe
            listOf(ParameterGenerator.EventParameterGenerator)
    }

    test("a method without parameters resolves to no generators") {
        ParameterGenerator.getGenerators(ListenerShapes.parametersOf("noParameters")) shouldBe emptyList()
    }

    test("an unsupported parameter is rejected, and the failure names it") {
        val failure = shouldThrow<IllegalArgumentException> {
            ParameterGenerator.getGenerators(ListenerShapes.parametersOf("unsupported"))
        }

        failure.message!!.contains("unsupported") shouldBe true
    }

    test("resolution is stable: the same shape resolves identically every time") {
        val first = ParameterGenerator.getGenerators(ListenerShapes.parametersOf("eventThenQuery"))
        val second = ParameterGenerator.getGenerators(ListenerShapes.parametersOf("eventThenQuery"))

        first shouldBe second
    }

    test("the event generator claims an event parameter") {
        val parameter = ListenerShapes.parametersOf("eventOnly").first()

        ParameterGenerator.EventParameterGenerator.isApplicable(parameter) shouldBe true
    }

    test("the event generator returns the very event instance it was given") {
        val event = mockk<PlayerJoinEvent>()

        val generated = ParameterGenerator.EventParameterGenerator.generate(event, mockk())

        generated shouldBeSameInstanceAs event
    }

    test("the query generator does not claim an event parameter") {
        val parameter = ListenerShapes.parametersOf("eventOnly").first()

        ParameterGenerator.QueryParameterGenerator.isApplicable(parameter) shouldBe false
    }

    test("the event generator does not claim an unsupported parameter") {
        val parameter = ListenerShapes.parametersOf("unsupported").first()

        ParameterGenerator.EventParameterGenerator.isApplicable(parameter) shouldBe false
    }
})
