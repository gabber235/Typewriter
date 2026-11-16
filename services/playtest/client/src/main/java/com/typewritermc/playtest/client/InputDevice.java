package com.typewritermc.playtest.client;

import com.typewritermc.playtest.wire.Message.Key;
import net.minecraft.client.Minecraft;
import org.lwjgl.sdl.SDLVideo;
import org.lwjgl.sdl.SDL_Event;

/**
 * Where the client's input enters: window events for its own window, as a keyboard and mouse would send
 * them. Each call queues events the client handles in its next pass, between ticks. Render thread only.
 */
interface InputDevice {
    /**
     * Whether the window has the input focus and the mouse grab as the operating system gives them. When
     * not, the client pretends both, as the window would have them in front of a person.
     */
    boolean real();

    /** Takes the input focus for the window, when the device can. */
    void focus();

    /**
     * Whether a mouse or key event the client polled is one this device sent. The game handles only
     * those while the client steps.
     */
    boolean owns(SDL_Event event);

    /** The game took one of this device's events. */
    void handled(SDL_Event event);

    /** A poll of the window's events ended: every event the queue held went to the game or was dropped. */
    void pollEnded();

    /** The game dropped every mouse and key event still queued, this device's own among them. */
    void flushed();

    /** Whether events this device sent have yet to reach the game; the tick's ack waits for them. */
    boolean pending();

    void key(Key key, boolean down);

    /** Types {@code text}, one character after the other. */
    void type(String text);

    /** A mouse button: 1 left, 2 middle, 3 right. */
    void button(int button, boolean down);

    /** Turns the wheel by {@code notches}; negative turns it toward the person. */
    void scroll(int notches);

    /** Moves the mouse by {@code dx}, {@code dy} pixels, as a grabbed mouse reports motion. */
    void move(double dx, double dy);

    /** Moves the pointer to {@code x}, {@code y} in the window's coordinates. */
    void moveTo(double x, double y);

    /**
     * The motion that ends the first move after a grab, which the client takes as the pointer's start
     * and never turns the view by.
     */
    void settle();

    /** The device for this client, as the pool chose it with {@code playtest.input}. */
    static InputDevice open(Minecraft mc) {
        String name = System.getProperty("playtest.input", "sdl");
        return switch (name) {
            case "sdl" -> new SdlQueue(() -> SDLVideo.SDL_GetWindowID(mc.getWindow().handle()));
            case "xtest" -> new XTest(mc.getWindow());
            default -> throw new IllegalStateException("playtest.input is " + name + ", not sdl or xtest");
        };
    }
}
