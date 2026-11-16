package com.typewritermc.playtest.client;

import com.mojang.blaze3d.platform.InputConstants;
import com.typewritermc.playtest.wire.Message.Key;
import java.nio.ByteBuffer;
import java.util.ArrayList;
import java.util.List;
import java.util.function.Consumer;
import java.util.function.IntSupplier;
import org.lwjgl.sdl.SDLEvents;
import org.lwjgl.sdl.SDLKeyboard;
import org.lwjgl.sdl.SDL_CommonEvent;
import org.lwjgl.sdl.SDL_Event;
import org.lwjgl.system.MemoryUtil;

/**
 * Input as SDL events pushed into the client's own event queue, addressed to its window: what SDL makes
 * of a keyboard and mouse, without the operating system. The developer's real keyboard, mouse and focus
 * stay untouched, so the client pretends the focus and the grab. The window still shows on the
 * developer's screen, where the real cursor can cross it; each pushed event carries a mark in its
 * header's reserved field, which SDL copies with the event, so the client tells its own input from the
 * developer's ({@link OwnInput}).
 */
final class SdlQueue implements InputDevice {
    private static final int KEY_DOWN = 768;
    private static final int KEY_UP = 769;
    private static final int TEXT_INPUT = 771;
    private static final int MOUSE_MOTION = 1024;
    private static final int MOUSE_BUTTON_DOWN = 1025;
    private static final int MOUSE_BUTTON_UP = 1026;
    private static final int MOUSE_WHEEL = 1027;
    /** "PTST": the mark of the events this queue pushed. */
    private static final int MARK = 0x50545354;

    private final IntSupplier windowId;
    /** Text the queued events point at: SDL copies an event, not its text, so the text lives until handled. */
    private final List<ByteBuffer> queuedText = new ArrayList<>();
    private float pointerX;
    private float pointerY;
    /** Pushed events the game has yet to take. */
    private int pending;

    SdlQueue(IntSupplier windowId) {
        this.windowId = windowId;
    }

    @Override
    public boolean real() {
        return false;
    }

    @Override
    public void focus() {}

    @Override
    public boolean owns(SDL_Event event) {
        return MemoryUtil.memGetInt(event.address() + SDL_CommonEvent.RESERVED) == MARK;
    }

    @Override
    public void handled(SDL_Event event) {
        if (pending > 0) pending--;
        if (pending == 0) freeText();
    }

    @Override
    public void pollEnded() {}

    @Override
    public void flushed() {
        pending = 0;
        freeText();
    }

    @Override
    public boolean pending() {
        return pending > 0;
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
        return windowId.getAsInt();
    }

    private void push(Consumer<SDL_Event> fill) {
        try (SDL_Event event = SDL_Event.calloc()) {
            fill.accept(event);
            MemoryUtil.memPutInt(event.address() + SDL_CommonEvent.RESERVED, MARK);
            if (!SDLEvents.SDL_PushEvent(event)) throw new IllegalStateException("SDL refused an input event: " + org.lwjgl.sdl.SDLError.SDL_GetError());
        }
        pending++;
    }

    private void freeText() {
        queuedText.forEach(MemoryUtil::memFree);
        queuedText.clear();
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
