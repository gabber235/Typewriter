package com.typewritermc.playtest.client;

import java.util.Locale;
import java.util.function.BooleanSupplier;
import java.util.function.Consumer;
import java.util.function.IntSupplier;
import java.util.function.Supplier;
import org.lwjgl.sdl.SDLEvents;
import org.lwjgl.sdl.SDL_Event;

/**
 * The game's event poll, through which only the playtest's own mouse and key events reach the game while
 * the client steps. On the developer's machine the client's window shows on the screen, where the real
 * cursor can cross it, and the game believes it holds the mouse: any motion SDL reports there would turn
 * the player. The poll drops such an event and logs its kind and the tick. Every own event the game takes
 * counts as handled, so the tick's ack waits until the last one reached the game. Render thread only.
 */
final class OwnInput {
    /** Takes the next queued event into {@code into}; false once the queue is empty. */
    interface Source {
        boolean poll(SDL_Event into);
    }

    private final Source source;
    private final Supplier<InputDevice> device;
    private final BooleanSupplier stepping;
    private final IntSupplier tick;
    private final Consumer<String> log;

    OwnInput(Source source, Supplier<InputDevice> device, BooleanSupplier stepping, IntSupplier tick, Consumer<String> log) {
        this.source = source;
        this.device = device;
        this.stepping = stepping;
        this.tick = tick;
        this.log = log;
    }

    /** Takes the next event the game may handle into {@code event}; false once the queue is empty. */
    boolean poll(SDL_Event event) {
        while (source.poll(event)) {
            String kind = inputKind(event);
            if (kind == null) return true;
            InputDevice hands = device.get();
            if (hands.owns(event)) {
                hands.handled(event);
                return true;
            }
            if (!stepping.getAsBoolean()) return true;
            log.accept("dropped " + kind + " the playtest did not send, at tick " + tick.getAsInt());
        }
        device.get().pollEnded();
        return false;
    }

    /** What a mouse or key event is, as a log line names it; null for any other event. */
    private static String inputKind(SDL_Event event) {
        return switch (event.type()) {
            case SDLEvents.SDL_EVENT_KEY_DOWN -> "a key press";
            case SDLEvents.SDL_EVENT_KEY_UP -> "a key release";
            case SDLEvents.SDL_EVENT_TEXT_EDITING -> "text editing";
            case SDLEvents.SDL_EVENT_TEXT_INPUT -> "text input";
            case SDLEvents.SDL_EVENT_MOUSE_MOTION -> String.format(Locale.ROOT, "a mouse motion to %.0f, %.0f", event.motion().x(), event.motion().y());
            case SDLEvents.SDL_EVENT_MOUSE_BUTTON_DOWN -> "a mouse button press";
            case SDLEvents.SDL_EVENT_MOUSE_BUTTON_UP -> "a mouse button release";
            case SDLEvents.SDL_EVENT_MOUSE_WHEEL -> "a mouse wheel turn";
            default -> null;
        };
    }
}
