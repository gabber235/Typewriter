package com.typewritermc.playtest.client;

import static java.lang.foreign.ValueLayout.ADDRESS;
import static java.lang.foreign.ValueLayout.JAVA_BYTE;
import static java.lang.foreign.ValueLayout.JAVA_INT;
import static java.lang.foreign.ValueLayout.JAVA_LONG;

import com.mojang.blaze3d.platform.Window;
import com.typewritermc.playtest.wire.Message.Key;
import java.lang.foreign.Arena;
import java.lang.foreign.FunctionDescriptor;
import java.lang.foreign.Linker;
import java.lang.foreign.MemorySegment;
import java.lang.foreign.SymbolLookup;
import java.lang.invoke.MethodHandle;
import org.lwjgl.sdl.SDLProperties;
import org.lwjgl.sdl.SDLVideo;

/**
 * Input as XTest events on the client's own X display, through libX11 and libXtst: the X server takes
 * them as a keyboard and mouse, so the window has real focus and SDL grabs the mouse for real. Each
 * client renders on a display of its own, so nothing else receives them. Linux only.
 */
final class XTest implements InputDevice {
    private static final long SHIFT_L = 0xffe1;
    private static final int REVERT_TO_PARENT = 2;
    private static final long CURRENT_TIME = 0;
    private static final int CURRENT_SCREEN = -1;

    private final Window window;
    private final Arena arena = Arena.ofShared();
    private final MemorySegment display;
    private final long root;
    private final MethodHandle keysymToKeycode;
    private final MethodHandle keycodeToKeysym;
    private final MethodHandle fakeKey;
    private final MethodHandle fakeButton;
    private final MethodHandle fakeRelativeMotion;
    private final MethodHandle fakeMotion;
    private final MethodHandle translateCoordinates;
    private final MethodHandle setInputFocus;
    private final MethodHandle sync;

    XTest(Window window) {
        this.window = window;
        String name = System.getenv("DISPLAY");
        if (name == null) throw new IllegalStateException("playtest.input is xtest, but DISPLAY is not set");
        Linker linker = Linker.nativeLinker();
        SymbolLookup x11 = SymbolLookup.libraryLookup("libX11.so.6", arena);
        SymbolLookup xtst = SymbolLookup.libraryLookup("libXtst.so.6", arena);
        MethodHandle openDisplay = function(linker, x11, "XOpenDisplay", FunctionDescriptor.of(ADDRESS, ADDRESS));
        MethodHandle defaultRoot = function(linker, x11, "XDefaultRootWindow", FunctionDescriptor.of(JAVA_LONG, ADDRESS));
        MethodHandle queryExtension = function(linker, xtst, "XTestQueryExtension", FunctionDescriptor.of(JAVA_INT, ADDRESS, ADDRESS, ADDRESS, ADDRESS, ADDRESS));
        keysymToKeycode = function(linker, x11, "XKeysymToKeycode", FunctionDescriptor.of(JAVA_BYTE, ADDRESS, JAVA_LONG));
        keycodeToKeysym = function(linker, x11, "XkbKeycodeToKeysym", FunctionDescriptor.of(JAVA_LONG, ADDRESS, JAVA_BYTE, JAVA_INT, JAVA_INT));
        fakeKey = function(linker, xtst, "XTestFakeKeyEvent", FunctionDescriptor.of(JAVA_INT, ADDRESS, JAVA_INT, JAVA_INT, JAVA_LONG));
        fakeButton = function(linker, xtst, "XTestFakeButtonEvent", FunctionDescriptor.of(JAVA_INT, ADDRESS, JAVA_INT, JAVA_INT, JAVA_LONG));
        fakeRelativeMotion = function(linker, xtst, "XTestFakeRelativeMotionEvent", FunctionDescriptor.of(JAVA_INT, ADDRESS, JAVA_INT, JAVA_INT, JAVA_LONG));
        fakeMotion = function(linker, xtst, "XTestFakeMotionEvent", FunctionDescriptor.of(JAVA_INT, ADDRESS, JAVA_INT, JAVA_INT, JAVA_INT, JAVA_LONG));
        translateCoordinates = function(
                linker, x11, "XTranslateCoordinates", FunctionDescriptor.of(JAVA_INT, ADDRESS, JAVA_LONG, JAVA_LONG, JAVA_INT, JAVA_INT, ADDRESS, ADDRESS, ADDRESS));
        setInputFocus = function(linker, x11, "XSetInputFocus", FunctionDescriptor.of(JAVA_INT, ADDRESS, JAVA_LONG, JAVA_INT, JAVA_LONG));
        sync = function(linker, x11, "XSync", FunctionDescriptor.of(JAVA_INT, ADDRESS, JAVA_INT));
        try {
            display = (MemorySegment) openDisplay.invokeExact(arena.allocateFrom(name));
            if (display.address() == 0) throw new IllegalStateException("cannot open the X display " + name);
            root = (long) defaultRoot.invokeExact(display);
            MemorySegment unused = arena.allocate(JAVA_INT, 4);
            int present = (int) queryExtension.invokeExact(display, unused, unused.asSlice(4), unused.asSlice(8), unused.asSlice(12));
            if (present == 0) throw new IllegalStateException("the X display " + name + " has no XTEST extension");
        } catch (RuntimeException failure) {
            throw failure;
        } catch (Throwable failure) {
            throw new IllegalStateException("cannot reach the X display " + name, failure);
        }
    }

    @Override
    public boolean real() {
        return true;
    }

    @Override
    public void focus() {
        call(() -> {
            int ignored = (int) setInputFocus.invokeExact(display, xWindow(), REVERT_TO_PARENT, CURRENT_TIME);
        });
        flush();
    }

    @Override
    public void pass() {}

    @Override
    public void key(Key key, boolean down) {
        press(keysym(key), down);
        flush();
    }

    @Override
    public void type(String text) {
        text.codePoints().forEach(codePoint -> {
            if (codePoint < 0x20 || codePoint > 0x7e) throw new IllegalArgumentException("XTest types printable ASCII only, not U+" + Integer.toHexString(codePoint));
            int keycode = keycode(codePoint);
            boolean shifted = unshiftedKeysym(keycode) != codePoint;
            if (shifted) press(SHIFT_L, true);
            pressKeycode(keycode, true);
            pressKeycode(keycode, false);
            if (shifted) press(SHIFT_L, false);
        });
        flush();
    }

    @Override
    public void button(int button, boolean down) {
        call(() -> {
            int ignored = (int) fakeButton.invokeExact(display, button, down ? 1 : 0, 0L);
        });
        flush();
    }

    @Override
    public void scroll(int notches) {
        // X reports the wheel as buttons: 4 turns it away from the person, 5 toward them.
        int button = notches > 0 ? 4 : 5;
        for (int notch = 0; notch < Math.abs(notches); notch++) {
            call(() -> {
                int down = (int) fakeButton.invokeExact(display, button, 1, 0L);
                int up = (int) fakeButton.invokeExact(display, button, 0, 0L);
            });
        }
        flush();
    }

    @Override
    public void move(double dx, double dy) {
        int x = (int) Math.round(dx);
        int y = (int) Math.round(dy);
        call(() -> {
            int ignored = (int) fakeRelativeMotion.invokeExact(display, x, y, 0L);
        });
        flush();
    }

    @Override
    public void moveTo(double x, double y) {
        MemorySegment out = arena.allocate(JAVA_LONG, 3);
        call(() -> {
            int ignored = (int) translateCoordinates.invokeExact(
                    display, xWindow(), root, (int) Math.round(x), (int) Math.round(y), out, out.asSlice(8), out.asSlice(16));
        });
        int rootX = out.get(JAVA_INT, 0);
        int rootY = out.get(JAVA_INT, 8);
        call(() -> {
            int ignored = (int) fakeMotion.invokeExact(display, CURRENT_SCREEN, rootX, rootY, 0L);
        });
        flush();
    }

    @Override
    public void settle() {
        // A grabbed pointer reports only motion, so the move that settles it is one pixel.
        move(1, 0);
    }

    private long xWindow() {
        int properties = SDLVideo.SDL_GetWindowProperties(window.handle());
        long id = SDLProperties.SDL_GetNumberProperty(properties, SDLVideo.SDL_PROP_WINDOW_X11_WINDOW_NUMBER, 0);
        if (id == 0) throw new IllegalStateException("the client's window is not an X window");
        return id;
    }

    private void press(long keysym, boolean down) {
        pressKeycode(keycode(keysym), down);
    }

    private void pressKeycode(int keycode, boolean down) {
        call(() -> {
            int ignored = (int) fakeKey.invokeExact(display, keycode, down ? 1 : 0, 0L);
        });
    }

    private int keycode(long keysym) {
        byte[] keycode = new byte[1];
        call(() -> keycode[0] = (byte) keysymToKeycode.invokeExact(display, keysym));
        int unsigned = keycode[0] & 0xff;
        if (unsigned == 0) throw new IllegalStateException("the X keyboard has no key for keysym 0x" + Long.toHexString(keysym));
        return unsigned;
    }

    private long unshiftedKeysym(int keycode) {
        long[] keysym = new long[1];
        call(() -> keysym[0] = (long) keycodeToKeysym.invokeExact(display, (byte) keycode, 0, 0));
        return keysym[0];
    }

    private void flush() {
        call(() -> {
            int ignored = (int) sync.invokeExact(display, 0);
        });
    }

    private static long keysym(Key key) {
        return switch (key) {
            case W -> 'w';
            case A -> 'a';
            case S -> 's';
            case D -> 'd';
            case E -> 'e';
            case F -> 'f';
            case Q -> 'q';
            case T -> 't';
            case SPACE -> ' ';
            case LEFT_SHIFT -> SHIFT_L;
            case ENTER -> 0xff0d;
            case BACKSPACE -> 0xff08;
            case ESCAPE -> 0xff1b;
            case SLASH -> '/';
            case DIGIT_1 -> '1';
            case DIGIT_2 -> '2';
            case DIGIT_3 -> '3';
            case DIGIT_4 -> '4';
            case DIGIT_5 -> '5';
            case DIGIT_6 -> '6';
            case DIGIT_7 -> '7';
            case DIGIT_8 -> '8';
            case DIGIT_9 -> '9';
        };
    }

    private static MethodHandle function(Linker linker, SymbolLookup library, String name, FunctionDescriptor descriptor) {
        return linker.downcallHandle(library.find(name).orElseThrow(() -> new IllegalStateException("no " + name + " in the X libraries")), descriptor);
    }

    private interface NativeCall {
        void run() throws Throwable;
    }

    private static void call(NativeCall call) {
        try {
            call.run();
        } catch (RuntimeException failure) {
            throw failure;
        } catch (Throwable failure) {
            throw new IllegalStateException("an X call failed", failure);
        }
    }
}
