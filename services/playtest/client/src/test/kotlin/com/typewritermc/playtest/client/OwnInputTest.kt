package com.typewritermc.playtest.client

import de.infix.testBalloon.framework.core.testSuite
import io.kotest.matchers.shouldBe
import org.lwjgl.sdl.SDLEvents
import org.lwjgl.sdl.SDLInit
import org.lwjgl.sdl.SDL_Event

val OwnInputTest by testSuite {
    test("a mouse motion the playtest did not send is dropped and logged while the client steps, and its own motion reaches the game") {
        SDLInit.SDL_Init(SDLInit.SDL_INIT_EVENTS) shouldBe true
        SDLEvents.SDL_FlushEvents(SDLEvents.SDL_EVENT_FIRST, SDLEvents.SDL_EVENT_LAST)
        val hands = SdlQueue { 1 }
        val log = mutableListOf<String>()
        val game = OwnInput(SDLEvents::SDL_PollEvent, { hands }, { true }, { 375 }, log::add)

        SDL_Event.calloc().use { cursor ->
            cursor.motion().type(SDLEvents.SDL_EVENT_MOUSE_MOTION).windowID(1).x(600f).y(300f).xrel(132f).yrel(17.8f)
            SDLEvents.SDL_PushEvent(cursor) shouldBe true
        }
        hands.move(0.0, 22.89)
        val reached = mutableListOf<Pair<Float, Float>>()
        SDL_Event.calloc().use { event -> while (game.poll(event)) reached += event.motion().xrel() to event.motion().yrel() }

        reached shouldBe listOf(0f to 22.89f)
        log shouldBe listOf("dropped a mouse motion to 600, 300 the playtest did not send, at tick 375")
    }

    test("the ack keeps waiting when a poll ends before the playtest's own events reached the game") {
        SDLInit.SDL_Init(SDLInit.SDL_INIT_EVENTS) shouldBe true
        SDLEvents.SDL_FlushEvents(SDLEvents.SDL_EVENT_FIRST, SDLEvents.SDL_EVENT_LAST)
        val hands = SdlQueue { 1 }
        val heldBack = OwnInput({ false }, { hands }, { true }, { 375 }, {})
        val game = OwnInput(SDLEvents::SDL_PollEvent, { hands }, { true }, { 375 }, {})

        hands.move(0.0, 22.89)
        SDL_Event.calloc().use { event ->
            heldBack.poll(event) shouldBe false
            hands.pending() shouldBe true

            while (game.poll(event)) Unit
        }

        hands.pending() shouldBe false
    }
}
