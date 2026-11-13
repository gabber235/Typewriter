package com.typewritermc.playtest.client;

import com.mojang.blaze3d.platform.InputConstants;
import com.mojang.blaze3d.platform.Window;
import com.typewritermc.playtest.wire.Message.Key;
import java.nio.ByteBuffer;
import java.util.ArrayList;
import java.util.List;
import java.util.function.Consumer;
import org.lwjgl.sdl.SDLEvents;
import org.lwjgl.sdl.SDLKeyboard;
import org.lwjgl.sdl.SDLVideo;
import org.lwjgl.sdl.SDL_Event;
import org.lwjgl.system.MemoryUtil;

/**
 * Input as SDL events pushed into the client's own event queue, addressed to its window: what SDL makes
 * of a keyboard and mouse, without the operating system. The developer's real keyboard, mouse and focus
 * stay untouched, so the client pretends the focus and the grab.
 */
final class SdlQueue implements InputDevice {
    private static final int KEY_DOWN = 768;
    private static final int KEY_UP = 769;
    private static final int TEXT_INPUT = 771;
    private static final int MOUSE_MOTION = 1024;
    private static final int MOUSE_BUTTON_DOWN = 1025;
    private static final int MOUSE_BUTTON_UP = 1026;
    private static final int MOUSE_WHEEL = 1027;

    private final Window window;
    /** Text the queued events point at: SDL copies an event, not its text, so the text lives until polled. */
    private final List<ByteBuffer> queuedText = new ArrayList<>();
    private float pointerX;
    private float pointerY;

    SdlQueue(Window window) {
        this.window = window;
    }

    @Override
    public boolean real() {
        return false;
    }

    @Override
    public void focus() {}

    @Override
    public void pass() {
        queuedText.clear();
    }

    @Override
    public void key(Key key, boolean down) {
        int scancode = scancode(key);
        int keycode = SDLKeyboard.SDL_GetKeyFromScancode(scancode, (short) 0, false);
        push(event -> event.key().type(down ? KEY_DOWN : KEY_UP).windowID(windowId()).scancode(scancode).key(keycode).down(down).repeat(false));
    }

    @Override
    public void type(String text) {
        text.codePoints().forEach(codePoint -> {
            ByteBuffer utf8 = MemoryUtil.memUTF8(new String(Character.toChars(codePoint)));
            queuedText.add(utf8);
            push(event -> event.text().type(TEXT_INPUT).windowID(windowId()).text(utf8));
        });
    }

    @Override
    public void button(int button, boolean down) {
        push(event -> event.button().type(down ? MOUSE_BUTTON_DOWN : MOUSE_BUTTON_UP).windowID(windowId()).button((byte) button).down(down).clicks((byte) 1).x(pointerX).y(pointerY));
    }

    @Override
    public void scroll(int notches) {
        push(event -> event.wheel().type(MOUSE_WHEEL).windowID(windowId()).y(notches).integer_y(notches).direction(0).mouse_x(pointerX).mouse_y(pointerY));
    }

    @Override
    public void move(double dx, double dy) {
        push(event -> event.motion().type(MOUSE_MOTION).windowID(windowId()).x(pointerX).y(pointerY).xrel((float) dx).yrel((float) dy));
    }

    @Override
    public void moveTo(double x, double y) {
        float dx = (float) x - pointerX;
        float dy = (float) y - pointerY;
        pointerX = (float) x;
        pointerY = (float) y;
        push(event -> event.motion().type(MOUSE_MOTION).windowID(windowId()).x(pointerX).y(pointerY).xrel(dx).yrel(dy));
    }

    @Override
    public void settle() {
        move(0, 0);
    }

    private int windowId() {
        return SDLVideo.SDL_GetWindowID(window.handle());
    }

    private static void push(Consumer<SDL_Event> fill) {
        try (SDL_Event event = SDL_Event.calloc()) {
            fill.accept(event);
            if (!SDLEvents.SDL_PushEvent(event)) throw new IllegalStateException("SDL refused an input event: " + org.lwjgl.sdl.SDLError.SDL_GetError());
        }
    }

    private static int scancode(Key key) {
        return switch (key) {
            case W -> InputConstants.KEY_W;
            case A -> InputConstants.KEY_A;
            case S -> InputConstants.KEY_S;
            case D -> InputConstants.KEY_D;
            case E -> InputConstants.KEY_E;
            case F -> InputConstants.KEY_F;
            case Q -> InputConstants.KEY_Q;
            case T -> InputConstants.KEY_T;
            case SPACE -> InputConstants.KEY_SPACE;
            case LEFT_SHIFT -> InputConstants.KEY_LSHIFT;
            case ENTER -> InputConstants.KEY_RETURN;
            case BACKSPACE -> InputConstants.KEY_BACKSPACE;
            case ESCAPE -> InputConstants.KEY_ESCAPE;
            case SLASH -> InputConstants.KEY_SLASH;
            case DIGIT_1 -> InputConstants.KEY_1;
            case DIGIT_2 -> InputConstants.KEY_2;
            case DIGIT_3 -> InputConstants.KEY_3;
            case DIGIT_4 -> InputConstants.KEY_4;
            case DIGIT_5 -> InputConstants.KEY_5;
            case DIGIT_6 -> InputConstants.KEY_6;
            case DIGIT_7 -> InputConstants.KEY_7;
            case DIGIT_8 -> InputConstants.KEY_8;
            case DIGIT_9 -> InputConstants.KEY_9;
        };
    }
}
