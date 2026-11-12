package probe.mod.input;

import java.lang.foreign.Arena;
import java.lang.foreign.FunctionDescriptor;
import java.lang.foreign.Linker;
import java.lang.foreign.MemorySegment;
import java.lang.foreign.SymbolLookup;
import java.lang.foreign.ValueLayout;
import java.lang.invoke.MethodHandle;
import static java.lang.foreign.ValueLayout.ADDRESS;
import static java.lang.foreign.ValueLayout.JAVA_BYTE;
import static java.lang.foreign.ValueLayout.JAVA_INT;
import static java.lang.foreign.ValueLayout.JAVA_LONG;

/**
 * In process input prototype: libX11 and libXtst through the foreign function API, on a connection of
 * this client's own (the X server's view: a second client that injects into the first). Linux only.
 * Every call is made on the render thread, the thread that also polls SDL, so no X locking is needed.
 */
public final class X11 {
    private static final Linker L = Linker.nativeLinker();
    private static final Arena A = Arena.global();
    private static SymbolLookup x11, xtst;
    private static MethodHandle openDisplay, keysymToKeycode, sync, flush, setInputFocus, raiseWindow, sendEvent, translate, defaultRoot,
            fakeKey, fakeButton, fakeRel, fakeMotion, queryExtension;

    public final MemorySegment dpy;
    public final long root;
    public final String name;

    private static synchronized void load() {
        if (x11 != null) return;
        x11 = SymbolLookup.libraryLookup("libX11.so.6", A);
        xtst = SymbolLookup.libraryLookup("libXtst.so.6", A);
        openDisplay = h(x11, "XOpenDisplay", FunctionDescriptor.of(ADDRESS, ADDRESS));
        keysymToKeycode = h(x11, "XKeysymToKeycode", FunctionDescriptor.of(JAVA_BYTE, ADDRESS, JAVA_LONG));
        sync = h(x11, "XSync", FunctionDescriptor.of(JAVA_INT, ADDRESS, JAVA_INT));
        flush = h(x11, "XFlush", FunctionDescriptor.of(JAVA_INT, ADDRESS));
        setInputFocus = h(x11, "XSetInputFocus", FunctionDescriptor.of(JAVA_INT, ADDRESS, JAVA_LONG, JAVA_INT, JAVA_LONG));
        raiseWindow = h(x11, "XRaiseWindow", FunctionDescriptor.of(JAVA_INT, ADDRESS, JAVA_LONG));
        sendEvent = h(x11, "XSendEvent", FunctionDescriptor.of(JAVA_INT, ADDRESS, JAVA_LONG, JAVA_INT, JAVA_LONG, ADDRESS));
        translate = h(x11, "XTranslateCoordinates", FunctionDescriptor.of(JAVA_INT, ADDRESS, JAVA_LONG, JAVA_LONG, JAVA_INT, JAVA_INT, ADDRESS, ADDRESS, ADDRESS));
        defaultRoot = h(x11, "XDefaultRootWindow", FunctionDescriptor.of(JAVA_LONG, ADDRESS));
        fakeKey = h(xtst, "XTestFakeKeyEvent", FunctionDescriptor.of(JAVA_INT, ADDRESS, JAVA_INT, JAVA_INT, JAVA_LONG));
        fakeButton = h(xtst, "XTestFakeButtonEvent", FunctionDescriptor.of(JAVA_INT, ADDRESS, JAVA_INT, JAVA_INT, JAVA_LONG));
        fakeRel = h(xtst, "XTestFakeRelativeMotionEvent", FunctionDescriptor.of(JAVA_INT, ADDRESS, JAVA_INT, JAVA_INT, JAVA_LONG));
        fakeMotion = h(xtst, "XTestFakeMotionEvent", FunctionDescriptor.of(JAVA_INT, ADDRESS, JAVA_INT, JAVA_INT, JAVA_INT, JAVA_LONG));
        queryExtension = h(xtst, "XTestQueryExtension", FunctionDescriptor.of(JAVA_INT, ADDRESS, ADDRESS, ADDRESS, ADDRESS, ADDRESS));
    }

    private static MethodHandle h(SymbolLookup lib, String name, FunctionDescriptor d) {
        return L.downcallHandle(lib.find(name).orElseThrow(() -> new IllegalStateException("missing " + name)), d);
    }

    private static volatile X11 shared;

    /** One connection per client process, to the display this process renders on. */
    public static X11 get() {
        X11 x = shared;
        if (x == null) {
            synchronized (X11.class) {
                if (shared == null) shared = new X11(System.getenv("DISPLAY"));
                x = shared;
            }
        }
        return x;
    }

    private X11(String display) {
        load();
        this.name = display;
        try {
            dpy = (MemorySegment) openDisplay.invokeExact(A.allocateFrom(display));
            if (dpy.address() == 0) throw new IllegalStateException("XOpenDisplay failed for " + display);
            root = (long) defaultRoot.invokeExact(dpy);
            MemorySegment i = A.allocate(JAVA_INT, 4);
            int ok = (int) queryExtension.invokeExact(dpy, i, i.asSlice(4), i.asSlice(8), i.asSlice(12));
            if (ok == 0) throw new IllegalStateException("no XTEST extension on " + display);
        } catch (Throwable t) {
            throw rethrow(t);
        }
    }

    public int keycode(long keysym) {
        try {
            return Byte.toUnsignedInt((byte) keysymToKeycode.invokeExact(dpy, keysym));
        } catch (Throwable t) {
            throw rethrow(t);
        }
    }

    /** Round trip: once it returns, the X server has handled every request and queued the events it caused. */
    public void sync() {
        try {
            int r = (int) sync.invokeExact(dpy, 0);
        } catch (Throwable t) {
            throw rethrow(t);
        }
    }

    public void fakeKey(int keycode, boolean down) {
        try {
            int r = (int) fakeKey.invokeExact(dpy, keycode, down ? 1 : 0, 0L);
        } catch (Throwable t) {
            throw rethrow(t);
        }
    }

    public void fakeButton(int button, boolean down) {
        try {
            int r = (int) fakeButton.invokeExact(dpy, button, down ? 1 : 0, 0L);
        } catch (Throwable t) {
            throw rethrow(t);
        }
    }

    public void fakeRelative(int dx, int dy) {
        try {
            int r = (int) fakeRel.invokeExact(dpy, dx, dy, 0L);
        } catch (Throwable t) {
            throw rethrow(t);
        }
    }

    public void fakeMotion(int x, int y) {
        try {
            int r = (int) fakeMotion.invokeExact(dpy, -1, x, y, 0L);
        } catch (Throwable t) {
            throw rethrow(t);
        }
    }

    public void focus(long window) {
        try {
            int r = (int) raiseWindow.invokeExact(dpy, window);
            r = (int) setInputFocus.invokeExact(dpy, window, 2 /* RevertToParent */, 0L /* CurrentTime */);
        } catch (Throwable t) {
            throw rethrow(t);
        }
    }

    /** The window's top left corner in root coordinates. */
    public int[] origin(long window) {
        try (Arena a = Arena.ofConfined()) {
            MemorySegment x = a.allocate(JAVA_INT), y = a.allocate(JAVA_INT), child = a.allocate(JAVA_LONG);
            int r = (int) translate.invokeExact(dpy, window, root, 0, 0, x, y, child);
            return new int[] {x.get(JAVA_INT, 0), y.get(JAVA_INT, 0)};
        } catch (Throwable t) {
            throw rethrow(t);
        }
    }

    // XEvent is 192 bytes on 64 bit; XKeyEvent, XButtonEvent and XMotionEvent share the first 88 bytes.
    public static final int KEY_PRESS = 2, KEY_RELEASE = 3, BUTTON_PRESS = 4, BUTTON_RELEASE = 5, MOTION = 6;

    /**
     * XSendEvent to one window with an empty mask: the X server hands it to the client that created the window
     * (SDL), whatever SDL selected, and marks it send_event.
     */
    public void send(long window, int type, int x, int y, int state, int detail) {
        try (Arena a = Arena.ofConfined()) {
            MemorySegment e = a.allocate(192, 8);
            e.set(JAVA_INT, 0, type);
            e.set(JAVA_LONG, 8, 0L);          // serial
            e.set(JAVA_INT, 16, 1);           // send_event
            e.set(ADDRESS, 24, dpy);
            e.set(JAVA_LONG, 32, window);
            e.set(JAVA_LONG, 40, root);
            e.set(JAVA_LONG, 48, 0L);         // subwindow
            e.set(JAVA_LONG, 56, 0L);         // time: CurrentTime
            int[] o = origin(window);
            e.set(JAVA_INT, 64, x);
            e.set(JAVA_INT, 68, y);
            e.set(JAVA_INT, 72, x + o[0]);
            e.set(JAVA_INT, 76, y + o[1]);
            e.set(JAVA_INT, 80, state);
            if (type == MOTION) e.set(JAVA_BYTE, 84, (byte) 0); // is_hint
            else e.set(JAVA_INT, 84, detail);  // keycode or button
            e.set(JAVA_INT, 88, 1);           // same_screen
            int r = (int) sendEvent.invokeExact(dpy, window, 0, 0L, e);
            if (r == 0) throw new IllegalStateException("XSendEvent failed");
        } catch (Throwable t) {
            throw rethrow(t);
        }
    }

    static RuntimeException rethrow(Throwable t) {
        return t instanceof RuntimeException r ? r : new RuntimeException(t);
    }

    /** X keysym for an SDL keycode (ASCII keys are their own keysym). */
    public static long keysym(int sdlKey) {
        return switch (sdlKey) {
            case 13 -> 0xff0dL;          // Return
            case 27 -> 0xff1bL;          // Escape
            case 8 -> 0xff08L;           // BackSpace
            case 1073742049 -> 0xffe1L;  // Shift_L
            default -> sdlKey;
        };
    }
}
