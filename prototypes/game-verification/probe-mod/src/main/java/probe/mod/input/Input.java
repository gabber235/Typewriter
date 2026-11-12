package probe.mod.input;

import com.mojang.blaze3d.platform.InputConstants;
import io.netty.buffer.ByteBuf;
import java.lang.reflect.Field;
import java.nio.ByteBuffer;
import java.time.Instant;
import java.util.ArrayList;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import java.util.concurrent.CompletableFuture;
import java.util.concurrent.TimeUnit;
import java.util.function.BooleanSupplier;
import it.unimi.dsi.fastutil.ints.Int2ObjectOpenHashMap;
import net.fabricmc.fabric.api.client.networking.v1.ClientPlayNetworking;
import net.fabricmc.fabric.api.networking.v1.PayloadTypeRegistry;
import net.minecraft.client.KeyMapping;
import net.minecraft.client.Minecraft;
import net.minecraft.client.Options;
import net.minecraft.client.gui.components.CommandSuggestions;
import net.minecraft.client.gui.components.EditBox;
import net.minecraft.client.gui.screens.ChatScreen;
import net.minecraft.client.gui.screens.Screen;
import net.minecraft.client.gui.screens.inventory.AbstractContainerScreen;
import net.minecraft.client.gui.screens.inventory.InventoryScreen;
import net.minecraft.client.input.KeyEvent;
import net.minecraft.client.input.MouseButtonInfo;
import net.minecraft.core.BlockPos;
import net.minecraft.core.Direction;
import net.minecraft.core.registries.BuiltInRegistries;
import net.minecraft.network.HashedStack;
import net.minecraft.network.codec.StreamCodec;
import net.minecraft.network.protocol.common.custom.CustomPacketPayload;
import net.minecraft.network.protocol.game.ServerboundAttackPacket;
import net.minecraft.network.protocol.game.ServerboundCommandSuggestionPacket;
import net.minecraft.network.protocol.game.ServerboundContainerClickPacket;
import net.minecraft.network.protocol.game.ServerboundContainerClosePacket;
import net.minecraft.network.protocol.game.ServerboundInteractPacket;
import net.minecraft.network.protocol.game.ServerboundMovePlayerPacket;
import net.minecraft.network.protocol.game.ServerboundPlayerActionPacket;
import net.minecraft.network.protocol.game.ServerboundPlayerInputPacket;
import net.minecraft.network.protocol.game.ServerboundSetCarriedItemPacket;
import net.minecraft.network.protocol.game.ServerboundUseItemPacket;
import net.minecraft.resources.Identifier;
import net.minecraft.world.InteractionHand;
import net.minecraft.world.entity.Entity;
import net.minecraft.world.inventory.ContainerInput;
import net.minecraft.world.phys.BlockHitResult;
import net.minecraft.world.phys.EntityHitResult;
import net.minecraft.world.phys.HitResult;
import net.minecraft.world.phys.Vec3;
import org.lwjgl.sdl.SDLEvents;
import org.lwjgl.sdl.SDLVideo;
import org.lwjgl.sdl.SDL_Event;
import org.lwjgl.system.MemoryUtil;

/**
 * Spike J: one input at a time through one of four paths, run as a script on client ticks, then a
 * mark payload so the server knows every packet the input caused has arrived.
 *
 *   J1 window events: SDL_PushEvent into this client's own SDL queue (in process, never the desktop),
 *      or nothing here when the orchestrator drives the X server with XTest (path X).
 *   J2 the client's input callbacks: KeyboardHandler.keyPress / textInput, MouseHandler.onButton / onMove / onScroll.
 *   J3 the game's actions: KeyMapping state and clicks, screen methods, rotation set directly.
 *   J4 packets through the connection.
 */
public final class Input {
    public static volatile boolean fakeFocus;
    public static volatile String grab = System.getProperty("probe.grab", "cancel");

    public record Mark(int id) implements CustomPacketPayload {
        public static final CustomPacketPayload.Type<Mark> TYPE = new CustomPacketPayload.Type<>(Identifier.parse("probe:mark"));
        public static final StreamCodec<ByteBuf, Mark> CODEC = StreamCodec.of((buf, m) -> buf.writeInt(m.id), buf -> new Mark(buf.readInt()));

        @Override
        public Type<? extends CustomPacketPayload> type() {
            return TYPE;
        }
    }

    public static void init() {
        PayloadTypeRegistry.serverboundPlay().register(Mark.TYPE, Mark.CODEC);
    }

    // ---- script engine ----

    interface Stage {
        /** Runs once per client tick at its head; true when done. */
        boolean tick(Minecraft mc, int t);
    }

    static final class Script {
        final List<Stage> stages = new ArrayList<>();
        final StringBuilder info = new StringBuilder();
        int index;
        int stageStart = -1;
        int startTick;
        long startMicros;
        int markId;
        int settle = 2;
        int settleLeft = -1;
        boolean timedOut;
        final CompletableFuture<String> done = new CompletableFuture<>();

        Script add(Stage s) {
            stages.add(s);
            return this;
        }

        Script now(Runnable r) {
            return add((mc, t) -> {
                r.run();
                return true;
            });
        }

        Script waitTicks(int n) {
            int[] left = {n};
            return add((mc, t) -> --left[0] <= 0);
        }

        Script until(String what, BooleanSupplier cond, int max) {
            int[] left = {max};
            return add((mc, t) -> {
                if (cond.getAsBoolean()) return true;
                if (--left[0] <= 0) {
                    timedOut = true;
                    note("timeout", what);
                    return true;
                }
                return false;
            });
        }

        void note(String k, Object v) {
            info.append(',').append(q(k)).append(':').append(v instanceof Number || v instanceof Boolean ? String.valueOf(v) : q(String.valueOf(v)));
        }
    }

    private static volatile Script running;
    private static int clientTicks;
    private static int lastTickFrame;

    /** Head of Minecraft.tick. */
    public static void headTick(Minecraft mc) {
        clientTicks++;
        inTick = true;
        Script s = running;
        if (s == null) return;
        if (s.settleLeft >= 0) return;
        while (s.index < s.stages.size()) {
            boolean ok;
            try {
                ok = s.stages.get(s.index).tick(mc, clientTicks);
            } catch (Throwable e) {
                s.note("error", e.toString());
                ok = true;
                s.index = s.stages.size();
                break;
            }
            if (!ok) return;
            s.index++;
            // One stage per tick, like events that arrive one loop apart, except zero-time stages chained by now().
            return;
        }
        s.settleLeft = s.settle;
    }

    // ---- spike N: break trace, one token per client tick and per player action packet sent ----

    static volatile StringBuilder trace;
    private static Field[] gm;

    /** Any thread that sends; called from ClientCommonPacketListenerImpl.send. */
    public static void traceSent(net.minecraft.network.protocol.Packet<?> pk) {
        StringBuilder t = trace;
        if (t != null && pk instanceof ServerboundPlayerActionPacket a)
            synchronized (t) { t.append(" SEND@").append(clientTicks).append(':').append(a.getAction().name()).append('#').append(a.getSequence()); }
    }

    private static void traceTick(Minecraft mc) {
        StringBuilder t = trace;
        if (t == null || mc.player == null) return;
        try {
            if (gm == null) {
                Class<?> c = net.minecraft.client.multiplayer.MultiPlayerGameMode.class;
                gm = new Field[] {c.getDeclaredField("isDestroying"), c.getDeclaredField("destroyProgress"), c.getDeclaredField("destroyDelay")};
                for (Field f : gm) f.setAccessible(true);
            }
            HitResult hr = mc.hitResult;
            String hit = hr == null ? "N" : hr.getType() == HitResult.Type.BLOCK ? "B" : hr.getType() == HitResult.Type.ENTITY ? "E" : "M";
            synchronized (t) {
                t.append(" t").append(clientTicks).append(" hit=").append(hit).append(" down=").append(mc.options.keyAttack.isDown() ? 1 : 0)
                        .append(" grab=").append(mc.mouseHandler.isMouseGrabbed() ? 1 : 0).append(" act=").append(mc.isWindowActive() ? 1 : 0)
                        .append(" scr=").append(mc.gui.screen() == null ? 0 : 1).append(" ov=").append(mc.gui.overlay() == null ? "-" : mc.gui.overlay().getClass().getSimpleName()).append(" miss=").append(mc.missTime)
                        .append(" d=").append(gm[0].getBoolean(mc.gameMode) ? 1 : 0).append(" p=").append(String.format(Locale.ROOT, "%.2f", gm[1].getFloat(mc.gameMode)))
                        .append(" dl=").append(gm[2].getInt(mc.gameMode)).append(" g=").append(mc.player.onGround() ? 1 : 0)
                        .append(" y=").append(Math.round(mc.player.getYRot())).append('/').append(Math.round(mc.player.getXRot())).append(';');
            }
        } catch (ReflectiveOperationException e) {
            t.append(" ").append(e);
        }
    }

    /** Tail of Minecraft.tick, after the tick end packet. */
    public static void tailTick(Minecraft mc) {
        inTick = false;
        traceTick(mc);
        Script s = running;
        if (s == null || s.settleLeft < 0) return;
        if (s.settleLeft-- > 0) return;
        running = null;
        s.note("ticks", clientTicks - s.startTick);
        if (injectTick >= 0) {
            s.note("injectTick", injectTick - s.startTick);
            s.note("injectStep", injectStep);
            s.note("injectN", injectN);
            s.note("injectUs", injectNanos / 1000);
            s.note("injectMaxUs", injectMaxNanos / 1000);
        }
        if (handledTick >= 0) {
            s.note("handledDelay", handledTick - injectTick);
            s.note("handledInTick", handledInTick);
            s.note("handledFirst", handledKind);
            s.note("handledN", handledN);
        }
        s.note("endMicros", micros());
        if (s.markId > 0 && mc.getConnection() != null) ClientPlayNetworking.send(new Mark(s.markId));
        s.done.complete("{\"ok\":" + !s.timedOut + ",\"startMicros\":" + s.startMicros + ",\"markMicros\":" + micros() + s.info + "}");
    }

    // ---- drivers: J1s pushes SDL events, J2 calls the handlers ----

    interface Keys {
        void key(int scancode, int keycode, boolean down);
        void text(String s);
        void button(int b, boolean down);
        void scroll(double y);
        /** Relative motion in window pixels (grabbed) or absolute cursor (screens). */
        void motion(double x, double y, double dx, double dy);
    }

    static final class Handlers implements Keys {
        final Minecraft mc;
        Handlers(Minecraft mc) { this.mc = mc; }
        long h() { return mc.getWindow().handle(); }
        public void key(int sc, int kc, boolean down) { mc.keyboardHandler.keyPress(h(), down ? 1 : 0, new KeyEvent(sc, kc, 0)); }
        public void text(String s) { mc.keyboardHandler.textInput(h(), s); }
        public void button(int b, boolean down) { mc.mouseHandler.onButton(h(), new MouseButtonInfo(b, 0), down ? 1 : 0); }
        public void scroll(double y) { mc.mouseHandler.onScroll(h(), 0, y); }
        public void motion(double x, double y, double dx, double dy) { mc.mouseHandler.onMove(h(), x, y, dx, dy); }
    }

    static final class Sdl implements Keys {
        final Minecraft mc;
        Sdl(Minecraft mc) { this.mc = mc; }
        int win() { return SDLVideo.SDL_GetWindowID(mc.getWindow().handle()); }
        void push(java.util.function.Consumer<SDL_Event> fill) {
            try (SDL_Event e = SDL_Event.calloc()) {
                fill.accept(e);
                if (!SDLEvents.SDL_PushEvent(e)) throw new IllegalStateException("SDL_PushEvent failed");
            }
        }
        public void key(int sc, int kc, boolean down) {
            push(e -> e.key().type(down ? 768 : 769).windowID(win()).scancode(sc).key(kc).down(down).repeat(false));
        }
        public void text(String s) {
            // SDL keeps the pointer: a small leak per typed line, fine for a throwaway probe.
            ByteBuffer utf8 = MemoryUtil.memUTF8(s);
            push(e -> e.text().type(771).windowID(win()).text(utf8));
        }
        public void button(int b, boolean down) {
            double x = mc.mouseHandler.xpos(), y = mc.mouseHandler.ypos();
            push(e -> e.button().type(down ? 1025 : 1026).windowID(win()).button((byte) b).down(down).clicks((byte) 1).x((float) x).y((float) y));
        }
        public void scroll(double y) {
            push(e -> e.wheel().type(1027).windowID(win()).y((float) y).integer_y((int) y).direction(0)
                    .mouse_x((float) mc.mouseHandler.xpos()).mouse_y((float) mc.mouseHandler.ypos()));
        }
        public void motion(double x, double y, double dx, double dy) {
            push(e -> e.motion().type(1024).windowID(win()).x((float) x).y((float) y).xrel((float) dx).yrel((float) dy));
        }
    }

    // ---- in process prototype: injection timing, and handler calls the injected events reach ----

    public static volatile boolean inTick;
    static int injectTick = -1, injectStep = -1, injectN, handledTick = -1, handledN;
    static long injectNanos, injectMaxNanos;
    static boolean handledInTick;
    static String handledKind;

    /** Head of the client's input handlers (HandledMixin); render thread. */
    static int moves;

    public static void handled(String kind) {
        if (kind.equals("move")) moves++;
        if (running == null || injectTick < 0) return;
        handledN++;
        if (handledTick >= 0) return;
        handledTick = clientTicks;
        handledInTick = inTick;
        handledKind = kind;
    }

    /** Wraps a driver: when the first event of the script was injected (client tick, server step) and what each call cost. */
    static final class Timed implements Keys {
        final Keys k;
        Timed(Keys k) { this.k = k; }
        void t(Runnable r) {
            if (injectTick < 0) {
                injectTick = clientTicks;
                injectStep = probe.mod.n.N.step();
            }
            long t0 = System.nanoTime();
            r.run();
            long d = System.nanoTime() - t0;
            injectN++;
            injectNanos += d;
            injectMaxNanos = Math.max(injectMaxNanos, d);
        }
        public void key(int sc, int kc, boolean down) { t(() -> k.key(sc, kc, down)); }
        public void text(String s) { t(() -> k.text(s)); }
        public void button(int b, boolean down) { t(() -> k.button(b, down)); }
        public void scroll(double y) { t(() -> k.scroll(y)); }
        public void motion(double x, double y, double dx, double dy) { t(() -> k.motion(x, y, dx, dy)); }
    }

    /** XTest from inside the client, on its own X connection; events go where a real device's would (focus, pointer, grab). */
    static final class XTestKeys implements Keys {
        final Minecraft mc;
        final X11 x = X11.get();
        XTestKeys(Minecraft mc) { this.mc = mc; }
        public void key(int sc, int kc, boolean down) {
            x.fakeKey(x.keycode(X11.keysym(kc)), down);
            x.sync();
        }
        public void text(String s) {
            // A person types: one key press and release per character.
            for (char c : s.toCharArray()) {
                int code = x.keycode(c);
                x.fakeKey(code, true);
                x.fakeKey(code, false);
            }
            x.sync();
        }
        public void button(int b, boolean down) {
            x.fakeButton(b, down);
            x.sync();
        }
        public void scroll(double y) {
            int b = y > 0 ? 4 : 5;
            x.fakeButton(b, true);
            x.fakeButton(b, false);
            x.sync();
        }
        public void motion(double px, double py, double dx, double dy) {
            if (mc.mouseHandler.isMouseGrabbed() && !"fake".equals(grab)) {
                int ix = (int) Math.round(dx), iy = (int) Math.round(dy);
                if (ix == 0 && iy == 0) return; // a physical mouse sends no zero motion
                x.fakeRelative(ix, iy);
            } else {
                int[] o = x.origin(Sends.window(mc));
                x.fakeMotion(o[0] + (int) Math.round(px), o[1] + (int) Math.round(py));
            }
            x.sync();
        }
    }

    /** XSendEvent to this client's own X window: targeted, so it needs no focus or pointer position. */
    static final class Sends implements Keys {
        final Minecraft mc;
        final X11 x = X11.get();
        int state;
        Sends(Minecraft mc) { this.mc = mc; }
        static long window(Minecraft mc) {
            int props = SDLVideo.SDL_GetWindowProperties(mc.getWindow().handle());
            return org.lwjgl.sdl.SDLProperties.SDL_GetNumberProperty(props, SDLVideo.SDL_PROP_WINDOW_X11_WINDOW_NUMBER, 0);
        }
        int cx() { return (int) Math.round(mc.mouseHandler.xpos()); }
        int cy() { return (int) Math.round(mc.mouseHandler.ypos()); }
        public void key(int sc, int kc, boolean down) {
            int before = state;
            if (kc == 1073742049) state = down ? state | 1 : state & ~1;
            x.send(window(mc), down ? X11.KEY_PRESS : X11.KEY_RELEASE, cx(), cy(), before, x.keycode(X11.keysym(kc)));
            x.sync();
        }
        public void text(String s) {
            long w = window(mc);
            for (char c : s.toCharArray()) {
                int code = x.keycode(c);
                x.send(w, X11.KEY_PRESS, cx(), cy(), state, code);
                x.send(w, X11.KEY_RELEASE, cx(), cy(), state, code);
            }
            x.sync();
        }
        public void button(int b, boolean down) {
            x.send(window(mc), down ? X11.BUTTON_PRESS : X11.BUTTON_RELEASE, cx(), cy(), state, b);
            x.sync();
        }
        public void scroll(double y) {
            int b = y > 0 ? 4 : 5;
            long w = window(mc);
            x.send(w, X11.BUTTON_PRESS, cx(), cy(), state, b);
            x.send(w, X11.BUTTON_RELEASE, cx(), cy(), state, b);
            x.sync();
        }
        public void motion(double px, double py, double dx, double dy) {
            x.send(window(mc), X11.MOTION, (int) Math.round(px), (int) Math.round(py), state, 0);
            x.sync();
        }
    }

    static Keys driver(Minecraft mc, String path) {
        Keys k = switch (path) {
            case "J1" -> new Sdl(mc);
            case "XF" -> new XTestKeys(mc);
            case "XS", "XSf" -> new Sends(mc);
            default -> new Handlers(mc);
        };
        return new Timed(k);
    }

    static boolean windowPath(String path) {
        return switch (path) {
            case "J1", "J2", "XF", "XS", "XSf" -> true;
            default -> false;
        };
    }

    // SDL scancodes and keycodes.
    static final int[] T = {InputConstants.KEY_T, 't'}, SLASH = {InputConstants.KEY_SLASH, '/'}, ENTER = {InputConstants.KEY_RETURN, 13},
            ESC = {InputConstants.KEY_ESCAPE, 27}, BACKSPACE = {InputConstants.KEY_BACKSPACE, 8}, F = {InputConstants.KEY_F, 'f'}, E = {InputConstants.KEY_E, 'e'}, W = {InputConstants.KEY_W, 'w'},
            SPACE = {InputConstants.KEY_SPACE, ' '}, SHIFT = {InputConstants.KEY_LSHIFT, 1073742049};

    static int[] digit(int n) {
        return new int[] {InputConstants.KEY_1 + n - 1, '0' + n};
    }

    // ---- request ----

    public static String handle(String name, Map<String, String> p, Minecraft mc) throws Exception {
        return switch (name) {
            case "in.setup" -> {
                if (p.containsKey("focus")) fakeFocus = "fake".equals(p.get("focus"));
                if (p.containsKey("grab")) grab = p.get("grab");
                onClient(mc, () -> {
                    if ("fake".equals(grab)) probe.mod.input.mixin.MouseGrabAccessor.class.cast(mc.mouseHandler).probe$setGrabbed(true);
                    mc.options.autoSuggestions().set(true);
                });
                yield "{\"ok\":true,\"focused\":" + mc.getWindow().isFocused() + ",\"grabbed\":" + mc.mouseHandler.isMouseGrabbed() + "}";
            }
            case "in.run" -> run(mc, p);
            case "in.xsetup" -> {
                // In process X setup: own connection, optional real focus on the own window, pointer to its middle,
                // and an optional first click (XTest or XSendEvent) so the game takes a real grab.
                CompletableFuture<String> f = new CompletableFuture<>();
                mc.execute(() -> {
                    try {
                        X11 x = X11.get();
                        long w = Sends.window(mc);
                        int[] o = x.origin(w);
                        int cx = mc.getWindow().getScreenWidth() / 2, cy = mc.getWindow().getScreenHeight() / 2;
                        if ("1".equals(p.get("focus"))) x.focus(w);
                        if (!"0".equals(p.get("pointer"))) x.fakeMotion(o[0] + cx, o[1] + cy);
                        String click = p.getOrDefault("click", "");
                        if (click.equals("xtest")) {
                            x.fakeButton(1, true);
                            x.fakeButton(1, false);
                        } else if (click.equals("send")) {
                            x.send(w, X11.BUTTON_PRESS, cx, cy, 0, 1);
                            x.send(w, X11.BUTTON_RELEASE, cx, cy, 0, 1);
                        }
                        x.sync();
                        f.complete("{\"ok\":true,\"display\":" + q(x.name) + ",\"window\":" + w + ",\"origin\":[" + o[0] + "," + o[1] + "]}");
                    } catch (Throwable t) {
                        f.complete("{\"ok\":false,\"error\":" + q(t.toString()) + "}");
                    }
                });
                yield f.get(10, TimeUnit.SECONDS);
            }
            case "in.state" -> {
                CompletableFuture<String> f = new CompletableFuture<>();
                mc.execute(() -> f.complete(state(mc, p)));
                yield f.get(10, TimeUnit.SECONDS);
            }
            case "in.mark" -> {
                // For inputs driven from outside the client (XTest): mark after n more client ticks.
                Script s = new Script();
                s.markId = Integer.parseInt(p.get("mark"));
                s.settle = Integer.parseInt(p.getOrDefault("settle", "2"));
                yield start(mc, s);
            }
            case "in.reset" -> {
                // Client state a requirement must not inherit: open screen, chat draft, held keys and buttons.
                onClient(mc, () -> {
                    if (mc.gui.screen() != null) mc.gui.setScreen(null);
                    mc.gui.hud.getChat().discardDraft();
                    KeyMapping.releaseAll();
                });
                yield "{\"ok\":true}";
            }
            case "in.ticks" -> "{\"ticks\":" + clientTicks + ",\"at\":" + micros() + "}";
            default -> null;
        };
    }

    private static String start(Minecraft mc, Script s) throws Exception {
        if (running != null) throw new IllegalStateException("script already running");
        mc.execute(() -> {
            s.startTick = clientTicks;
            s.startMicros = micros();
            injectTick = injectStep = handledTick = -1;
            injectN = handledN = 0;
            injectNanos = injectMaxNanos = 0;
            running = s;
        });
        return s.done.get(60, TimeUnit.SECONDS);
    }

    private static String run(Minecraft mc, Map<String, String> p) throws Exception {
        String path = p.get("path");
        String op = p.get("op");
        Script s = new Script();
        s.markId = Integer.parseInt(p.getOrDefault("mark", "0"));
        boolean keys = windowPath(path);
        Keys k = driver(mc, path);
        Options o = mc.options;
        if (p.containsKey("atStep")) {
            // Every client starts its input on the same server step (cross talk runs).
            int at = Integer.parseInt(p.get("atStep"));
            s.add((mc2, t) -> probe.mod.n.N.step() < 0 || probe.mod.n.N.step() >= at);
            s.now(() -> s.note("startStep", probe.mod.n.N.step()));
        }
        switch (op) {
            case "chat" -> {
                String text = p.get("text");
                if (keys) {
                    press(s, k, T);
                    s.until("chat screen", () -> mc.gui.screen() instanceof ChatScreen, 10);
                    s.now(() -> k.text(text));
                    press(s, k, ENTER);
                } else if (path.equals("J3")) {
                    s.now(() -> KeyMapping.click(o.keyChat.getDefaultKey()));
                    s.until("chat screen", () -> mc.gui.screen() instanceof ChatScreen, 10);
                    s.now(() -> {
                        ChatScreen c = (ChatScreen) mc.gui.screen();
                        EditBox box = field(ChatScreen.class, c, "input");
                        box.setValue(text);
                        c.handleChatInput(box.getValue(), true);
                        // What keyPressed(Enter) does after sending; without it the closed screen saves a draft (seen in the first smoke).
                        setField(ChatScreen.class, c, "exitReason", exitDone());
                        mc.gui.setScreen(null);
                    });
                } else {
                    s.now(() -> mc.getConnection().sendChat(text));
                }
                s.now(() -> s.note("screenAfter", screenName(mc)));
            }
            case "cmd" -> {
                String text = p.get("text");
                if (keys) {
                    press(s, k, SLASH);
                    s.until("chat screen", () -> mc.gui.screen() instanceof ChatScreen, 10);
                    s.now(() -> k.text(text));
                    press(s, k, ENTER);
                } else if (path.equals("J3")) {
                    s.now(() -> KeyMapping.click(o.keyCommand.getDefaultKey()));
                    s.until("chat screen", () -> mc.gui.screen() instanceof ChatScreen, 10);
                    s.now(() -> {
                        ChatScreen c = (ChatScreen) mc.gui.screen();
                        EditBox box = field(ChatScreen.class, c, "input");
                        box.setValue("/" + text);
                        c.handleChatInput(box.getValue(), true);
                        // What keyPressed(Enter) does after sending; without it the closed screen saves a draft (seen in the first smoke).
                        setField(ChatScreen.class, c, "exitReason", exitDone());
                        mc.gui.setScreen(null);
                    });
                } else {
                    s.now(() -> mc.getConnection().sendCommand(text));
                }
                s.now(() -> s.note("screenAfter", screenName(mc)));
            }
            case "suggest" -> {
                String text = p.get("text");
                String want = p.get("want");
                if (keys) {
                    press(s, k, SLASH);
                    s.until("chat screen", () -> mc.gui.screen() instanceof ChatScreen, 10);
                    s.now(() -> k.text(text));
                } else if (path.equals("J3")) {
                    s.now(() -> KeyMapping.click(o.keyCommand.getDefaultKey()));
                    s.until("chat screen", () -> mc.gui.screen() instanceof ChatScreen, 10);
                    s.now(() -> ((EditBox) field(ChatScreen.class, mc.gui.screen(), "input")).setValue("/" + text));
                } else {
                    s.now(() -> mc.getConnection().send(new ServerboundCommandSuggestionPacket(4242, "/" + text)));
                }
                int[] waited = {0};
                int retryAfter = i(p, "retry", 0);
                if (retryAfter > 0 && keys) {
                    // What a person does when no list shows: delete the last character and type it again.
                    boolean[] got = {false};
                    s.add((mc2, t) -> {
                        waited[0]++;
                        got[0] = suggestions(mc).contains(want);
                        return got[0] || waited[0] >= retryAfter;
                    });
                    s.add((mc2, t) -> {
                        if (!got[0]) {
                            s.note("retried", true);
                            k.key(BACKSPACE[0], BACKSPACE[1], true);
                            k.key(BACKSPACE[0], BACKSPACE[1], false);
                        }
                        return true;
                    });
                    s.add((mc2, t) -> {
                        if (!got[0]) k.text(text.substring(text.length() - 1));
                        return true;
                    });
                }
                s.until("suggestions", () -> {
                    waited[0]++;
                    return suggestions(mc).contains(want);
                }, Integer.parseInt(p.getOrDefault("max", "40")));
                s.now(() -> {
                    s.note("suggestions", String.join("|", suggestions(mc)));
                    s.note("suggestTicks", waited[0]);
                });
                // Perceived: the list must be drawn. Draw frames (also while gated) and read the drawn text runs.
                s.add(drawnText(s, want, Integer.parseInt(p.getOrDefault("frames", "3"))));
                if (keys) press(s, k, ESC);
                else s.now(() -> mc.gui.setScreen(null));
                s.now(() -> s.note("screenAfter", screenName(mc)));
            }
            case "break" -> {
                BlockPos pos = new BlockPos(i(p, "x"), i(p, "y"), i(p, "z"));
                Vec3 at = Vec3.atCenterOf(pos);
                int max = i(p, "max");
                aim(s, mc, k, path, at);
                BooleanSupplier gone = () -> mc.level.getBlockState(pos).isAir();
                if (keys) {
                    boolean traced = "1".equals(p.get("trace"));
                    if (traced) s.now(() -> trace = new StringBuilder());
                    s.now(() -> k.button(1, true));
                    s.until("client air", gone, max);
                    s.now(() -> s.note("airAfter", clientTicks - s.startTick));
                    s.now(() -> k.button(1, false));
                } else if (path.equals("J3")) {
                    s.now(() -> {
                        o.keyAttack.setDown(true);
                        KeyMapping.click(o.keyAttack.getDefaultKey());
                    });
                    s.until("client air", gone, max);
                    s.now(() -> s.note("airAfter", clientTicks - s.startTick));
                    s.now(() -> o.keyAttack.setDown(false));
                } else {
                    int hold = i(p, "hold");
                    s.now(() -> mc.getConnection().send(new ServerboundPlayerActionPacket(ServerboundPlayerActionPacket.Action.START_DESTROY_BLOCK, pos, Direction.UP, 0)));
                    s.waitTicks(hold);
                    s.now(() -> mc.getConnection().send(new ServerboundPlayerActionPacket(ServerboundPlayerActionPacket.Action.STOP_DESTROY_BLOCK, pos, Direction.UP, 0)));
                }
                s.waitTicks(i(p, "after", 4));
                s.now(() -> s.note("blockAfter", BuiltInRegistries.BLOCK.getKey(mc.level.getBlockState(pos).getBlock()).toString()));
                s.now(() -> {
                    StringBuilder t = trace;
                    trace = null;
                    if (t != null) s.note("trace", t.toString().trim());
                });
            }
            case "use" -> {
                int hold = i(p, "hold");
                if (keys) {
                    s.now(() -> k.button(3, true));
                    s.waitTicks(hold);
                    s.now(() -> s.note("scoping", mc.player.isScoping()));
                    s.now(() -> k.button(3, false));
                } else if (path.equals("J3")) {
                    s.now(() -> {
                        o.keyUse.setDown(true);
                        KeyMapping.click(o.keyUse.getDefaultKey());
                    });
                    s.waitTicks(hold);
                    s.now(() -> s.note("scoping", mc.player.isScoping()));
                    s.now(() -> o.keyUse.setDown(false));
                } else {
                    s.now(() -> mc.getConnection().send(new ServerboundUseItemPacket(InteractionHand.MAIN_HAND, 0, mc.player.getYRot(), mc.player.getXRot())));
                    s.waitTicks(hold);
                    s.now(() -> s.note("scoping", mc.player.isScoping()));
                    s.now(() -> mc.getConnection().send(new ServerboundPlayerActionPacket(ServerboundPlayerActionPacket.Action.RELEASE_USE_ITEM, BlockPos.ZERO, Direction.DOWN)));
                }
                s.waitTicks(1);
            }
            case "swap" -> {
                if (keys) press(s, k, F);
                else if (path.equals("J3")) s.now(() -> KeyMapping.click(o.keySwapOffhand.getDefaultKey()));
                else s.now(() -> mc.getConnection().send(new ServerboundPlayerActionPacket(ServerboundPlayerActionPacket.Action.SWAP_ITEM_WITH_OFFHAND, BlockPos.ZERO, Direction.DOWN)));
                s.waitTicks(2);
                s.now(() -> s.note("offhand", BuiltInRegistries.ITEM.getKey(mc.player.getOffhandItem().getItem()).toString()));
            }
            case "scroll" -> {
                int dir = i(p, "dir", -1);
                if (keys) s.now(() -> k.scroll(dir));
                else if (path.equals("J3")) s.now(() -> mc.player.getInventory().setSelectedSlot(Math.floorMod(mc.player.getInventory().getSelectedSlot() - dir, 9)));
                else s.now(() -> mc.getConnection().send(new ServerboundSetCarriedItemPacket(Math.floorMod(mc.player.getInventory().getSelectedSlot() - dir, 9))));
                s.waitTicks(2);
                s.now(() -> s.note("slot", mc.player.getInventory().getSelectedSlot()));
            }
            case "num" -> {
                int n = i(p, "n");
                if (keys) press(s, k, digit(n));
                else if (path.equals("J3")) s.now(() -> KeyMapping.click(o.keyHotbarSlots[n - 1].getDefaultKey()));
                else s.now(() -> mc.getConnection().send(new ServerboundSetCarriedItemPacket(n - 1)));
                s.waitTicks(2);
                s.now(() -> s.note("slot", mc.player.getInventory().getSelectedSlot()));
            }
            case "sneak", "jump", "fly" -> {
                int hold = i(p, "hold");
                boolean jump = !op.equals("sneak");
                int[] key = jump ? SPACE : SHIFT;
                KeyMapping m = jump ? o.keyJump : o.keyShift;
                double[] y0 = {0};
                s.now(() -> y0[0] = mc.player.getY());
                double[] top = {0};
                if (keys) {
                    s.now(() -> k.key(key[0], key[1], true));
                    s.waitTicks(hold);
                    s.now(() -> k.key(key[0], key[1], false));
                } else if (path.equals("J3")) {
                    s.now(() -> m.setDown(true));
                    s.waitTicks(hold);
                    s.now(() -> m.setDown(false));
                } else {
                    net.minecraft.world.entity.player.Input in = jump ? new net.minecraft.world.entity.player.Input(false, false, false, false, true, false, false) : new net.minecraft.world.entity.player.Input(false, false, false, false, false, true, false);
                    s.now(() -> mc.getConnection().send(new ServerboundPlayerInputPacket(in)));
                    s.waitTicks(hold);
                    s.now(() -> mc.getConnection().send(new ServerboundPlayerInputPacket(net.minecraft.world.entity.player.Input.EMPTY)));
                }
                s.until("landed", () -> {
                    top[0] = Math.max(top[0], mc.player.getY() - y0[0]);
                    return op.equals("fly") || mc.player.onGround();
                }, 20);
                s.now(() -> s.note("rise", Math.round(top[0] * 1000) / 1000.0));
                s.now(() -> s.note("sneaking", mc.player.isShiftKeyDown()));
            }
            case "attack", "interact" -> {
                int id = i(p, "entity");
                boolean attack = op.equals("attack");
                Vec3 at = new Vec3(d(p, "x"), d(p, "y"), d(p, "z"));
                aim(s, mc, k, path, at);
                s.now(() -> {
                    HitResult hr = mc.hitResult;
                    s.note("hit", hr == null ? "none" : hr.getType().name());
                    s.note("hitEntity", hr instanceof EntityHitResult e ? e.getEntity().getId() : -1);
                });
                int button = attack ? 1 : 3;
                if (keys) {
                    s.now(() -> k.button(button, true));
                    s.waitTicks(1);
                    s.now(() -> k.button(button, false));
                } else if (path.equals("J3")) {
                    KeyMapping m = attack ? o.keyAttack : o.keyUse;
                    s.now(() -> {
                        m.setDown(true);
                        KeyMapping.click(m.getDefaultKey());
                    });
                    s.waitTicks(1);
                    s.now(() -> m.setDown(false));
                } else {
                    s.now(() -> {
                        Entity e = mc.level.getEntity(id);
                        Vec3 rel = e == null ? Vec3.ZERO : at.subtract(e.position());
                        mc.getConnection().send(attack ? new ServerboundAttackPacket(id) : new ServerboundInteractPacket(id, InteractionHand.MAIN_HAND, rel, false));
                    });
                }
                s.waitTicks(1);
            }
            case "inv" -> {
                int slot = i(p, "slot");
                if (keys) {
                    press(s, k, E);
                    s.until("inventory", () -> mc.gui.screen() instanceof InventoryScreen, 10);
                    s.now(() -> {
                        AbstractContainerScreen<?> c = (AbstractContainerScreen<?>) mc.gui.screen();
                        var sl = c.getMenu().slots.get(slot);
                        int left = (int) field(AbstractContainerScreen.class, c, "leftPos"), top = (int) field(AbstractContainerScreen.class, c, "topPos");
                        double scale = mc.getWindow().getGuiScale();
                        double x = (left + sl.x + 8) * scale * mc.getWindow().getScreenWidth() / (double) mc.getWindow().getWidth();
                        double y = (top + sl.y + 8) * scale * mc.getWindow().getScreenHeight() / (double) mc.getWindow().getHeight();
                        double ox = mc.mouseHandler.xpos(), oy = mc.mouseHandler.ypos();
                        k.motion(x, y, x - ox, y - oy);
                    });
                    s.waitTicks(1);
                    s.now(() -> k.button(1, true));
                    s.waitTicks(1);
                    s.now(() -> k.button(1, false));
                    s.waitTicks(1);
                    s.now(() -> s.note("carried", BuiltInRegistries.ITEM.getKey(mc.player.containerMenu.getCarried().getItem()).toString()));
                    press(s, k, E);
                } else if (path.equals("J3")) {
                    s.now(() -> KeyMapping.click(o.keyInventory.getDefaultKey()));
                    s.until("inventory", () -> mc.gui.screen() instanceof InventoryScreen, 10);
                    s.now(() -> mc.gameMode.handleContainerInput(mc.player.containerMenu.containerId, slot, 0, ContainerInput.PICKUP, mc.player));
                    s.waitTicks(1);
                    s.now(() -> s.note("carried", BuiltInRegistries.ITEM.getKey(mc.player.containerMenu.getCarried().getItem()).toString()));
                    s.now(() -> mc.gui.screen().onClose());
                } else {
                    s.now(() -> mc.getConnection().send(new ServerboundContainerClickPacket(0, mc.player.inventoryMenu.getStateId(), (short) slot, (byte) 0,
                            ContainerInput.PICKUP, new Int2ObjectOpenHashMap<>(), HashedStack.EMPTY)));
                    s.waitTicks(1);
                    s.now(() -> mc.getConnection().send(new ServerboundContainerClosePacket(0)));
                }
                s.waitTicks(2);
                s.now(() -> {
                    s.note("screenAfter", screenName(mc));
                    s.note("slotItem", BuiltInRegistries.ITEM.getKey(mc.player.inventoryMenu.slots.get(slot).getItem().getItem()).toString());
                });
            }
            case "move" -> {
                double tx = d(p, "x"), tz = d(p, "z");
                int max = i(p, "max", 80);
                BooleanSupplier there = () -> Math.hypot(mc.player.getX() - tx, mc.player.getZ() - tz) < 0.3;
                // Face the target first, then walk forward like a person would.
                Vec3[] eye = {null};
                s.now(() -> eye[0] = mc.player.getEyePosition());
                aim(s, mc, k, path, null, () -> new Vec3(tx, eye[0].y, tz));
                if (keys) {
                    s.now(() -> k.key(W[0], W[1], true));
                    s.until("there", there, max);
                    s.now(() -> k.key(W[0], W[1], false));
                } else if (path.equals("J3")) {
                    s.now(() -> o.keyUp.setDown(true));
                    s.until("there", there, max);
                    s.now(() -> o.keyUp.setDown(false));
                } else {
                    // Packet walk: one position packet every second tick straight at the target. The client is not moved,
                    // and vanilla disconnects a player that sends two positions in one server tick.
                    double[] at = {0.5, 0, 0.5};
                    int[] n = {0};
                    s.add((mc2, t) -> {
                        if (n[0]++ == 0) {
                            at[1] = mc.player.getY();
                        }
                        if (n[0] % 2 == 1) return false;
                        double dz = tz - at[2];
                        if (Math.abs(dz) < 0.3) return true;
                        at[2] += Math.signum(dz) * Math.min(0.4, Math.abs(dz));
                        mc.getConnection().send(new ServerboundMovePlayerPacket.Pos(at[0], at[1], at[2], true, false));
                        return false;
                    });
                }
                s.waitTicks(i(p, "after", 6));
                s.now(() -> s.note("pos", String.format(Locale.ROOT, "%.2f,%.2f,%.2f", mc.player.getX(), mc.player.getY(), mc.player.getZ())));
            }
            case "cross" -> {
                // Cross talk probe: a number key, a sneak held for a client specific time, a turn by a client
                // specific angle, then a chat line with the client's token. Every client runs it at the same step.
                int n = i(p, "n");
                int hold = i(p, "hold");
                double turn = d(p, "turn");
                String tok = p.get("tok");
                float[] yaw0 = {0};
                int[] moves0 = {0};
                press(s, k, digit(n + 1)); // slot n: the player starts on slot 0, so every client changes slot
                s.waitTicks(2);
                s.now(() -> k.key(SHIFT[0], SHIFT[1], true));
                s.waitTicks(hold);
                s.now(() -> k.key(SHIFT[0], SHIFT[1], false));
                s.waitTicks(1);
                s.now(() -> {
                    yaw0[0] = mc.player.getYRot();
                    s.note("ifm", (boolean) field(net.minecraft.client.MouseHandler.class, mc.mouseHandler, "ignoreFirstMove"));
                    s.note("active", mc.isWindowActive());
                    moves0[0] = moves;
                    if (!path.equals("XF")) k.motion(mc.mouseHandler.xpos(), mc.mouseHandler.ypos(), 0, 0);
                    double ss = mc.options.sensitivity().get() * 0.6F + 0.2F;
                    double dx = turn / (ss * ss * ss * 8.0 * 0.15);
                    k.motion(mc.mouseHandler.xpos() + dx, mc.mouseHandler.ypos(), dx, 0);
                });
                s.waitTicks(2);
                s.now(() -> {
                    s.note("turned", Math.round((mc.player.getYRot() - yaw0[0]) * 100) / 100.0);
                    s.note("movesSeen", moves - moves0[0]);
                    s.note("ifmAfter", (boolean) field(net.minecraft.client.MouseHandler.class, mc.mouseHandler, "ignoreFirstMove"));
                });
                press(s, k, T);
                s.until("chat screen", () -> mc.gui.screen() instanceof ChatScreen, 10);
                s.now(() -> k.text("x" + n + " " + tok));
                press(s, k, ENTER);
                s.waitTicks(2);
                s.now(() -> {
                    s.note("slot", mc.player.getInventory().getSelectedSlot());
                    s.note("screenAfter", screenName(mc));
                    s.note("focused", mc.getWindow().isFocused());
                    s.note("grabbed", mc.mouseHandler.isMouseGrabbed());
                });
            }
            default -> throw new IllegalArgumentException("unknown op " + op);
        }
        return start(mc, s);
    }

    private static void press(Script s, Keys k, int[] key) {
        s.now(() -> k.key(key[0], key[1], true));
        s.now(() -> k.key(key[0], key[1], false));
    }

    private static void aim(Script s, Minecraft mc, Keys k, String path, Vec3 at) {
        aim(s, mc, k, path, at, null);
    }

    /** Turns the view to look at a point. J1, J2: mouse motion through the sensitivity curve; J3: set rotation; J4: rotation packet only. */
    private static void aim(Script s, Minecraft mc, Keys k, String path, Vec3 fixed, java.util.function.Supplier<Vec3> later) {
        s.now(() -> {
            Vec3 at = fixed != null ? fixed : later.get();
            Vec3 eye = mc.player.getEyePosition();
            Vec3 d = at.subtract(eye);
            float yaw = (float) (Math.toDegrees(Math.atan2(-d.x, d.z)));
            float pitch = (float) (-Math.toDegrees(Math.atan2(d.y, Math.hypot(d.x, d.z))));
            float dyaw = net.minecraft.util.Mth.wrapDegrees(yaw - mc.player.getYRot());
            float dpitch = pitch - mc.player.getXRot();
            switch (path) {
                case "J1", "J2", "XF", "XS", "XSf" -> {
                    // The first motion after a grab only sets the cursor (ignoreFirstMove); a person's mouse sends many.
                    if (!path.equals("XF")) k.motion(mc.mouseHandler.xpos(), mc.mouseHandler.ypos(), 0, 0);
                    double ss = mc.options.sensitivity().get() * 0.6F + 0.2F;
                    double perPixel = ss * ss * ss * 8.0 * 0.15;
                    double dx = dyaw / perPixel, dy = dpitch / perPixel;
                    double x = mc.mouseHandler.xpos(), y = mc.mouseHandler.ypos();
                    k.motion(x + dx, y + dy, dx, dy);
                }
                case "J3" -> {
                    mc.player.setYRot(yaw);
                    mc.player.setXRot(pitch);
                    mc.player.yRotO = yaw;
                    mc.player.xRotO = pitch;
                }
                default -> mc.getConnection().send(new ServerboundMovePlayerPacket.Rot(yaw, pitch, mc.player.onGround(), false));
            }
            s.note("aimYaw", Math.round(yaw * 100) / 100.0);
            s.note("aimPitch", Math.round(pitch * 100) / 100.0);
        });
        // The rotation reaches the server in the next tick's movement packet; a person aims before clicking.
        s.waitTicks(2);
        s.now(() -> {
            s.note("yaw", Math.round(mc.player.getYRot() * 100) / 100.0);
            s.note("pitch", Math.round(mc.player.getXRot() * 100) / 100.0);
            HitResult hr = mc.hitResult;
            s.note("aimHit", hr == null ? "none" : hr instanceof BlockHitResult b ? "block:" + b.getBlockPos().toShortString() : hr.getType().name());
        });
    }

    private static Stage drawnText(Script s, String want, int frames) {
        boolean[] asked = {false};
        boolean[] got = {false};
        long[] t0 = {0};
        return (mc, t) -> {
            if (!asked[0]) {
                asked[0] = true;
                t0[0] = System.nanoTime();
                probe.mod.speed.Speed.drawThen(frames, () -> got[0] = true);
                return false;
            }
            if (!got[0]) return false;
            String drawn = probe.mod.observe.Drawn.frameJson();
            s.note("drawnHasWant", drawn.contains(want));
            s.note("drawMs", Math.round((System.nanoTime() - t0[0]) / 1e4) / 100.0);
            return true;
        };
    }

    static List<String> suggestions(Minecraft mc) {
        List<String> out = new ArrayList<>();
        Screen sc = mc.gui.screen();
        if (!(sc instanceof ChatScreen chat)) return out;
        try {
            CommandSuggestions cs = field(ChatScreen.class, chat, "commandSuggestions");
            Object list = field(CommandSuggestions.class, cs, "suggestions");
            if (list == null) return out;
            List<com.mojang.brigadier.suggestion.Suggestion> l = field(list.getClass(), list, "suggestionList");
            for (var x : l) out.add(x.getText());
        } catch (Exception e) {
            out.add("error:" + e);
        }
        return out;
    }

    static String state(Minecraft mc, Map<String, String> p) {
        StringBuilder b = new StringBuilder("{");
        b.append("\"screen\":").append(q(screenName(mc)));
        b.append(",\"focused\":").append(mc.getWindow().isFocused());
        b.append(",\"grabbed\":").append(mc.mouseHandler.isMouseGrabbed());
        b.append(",\"ticks\":").append(clientTicks);
        if (mc.player != null) {
            b.append(",\"slot\":").append(mc.player.getInventory().getSelectedSlot());
            b.append(",\"yaw\":").append(mc.player.getYRot()).append(",\"pitch\":").append(mc.player.getXRot());
            b.append(",\"pos\":[").append(mc.player.getX()).append(',').append(mc.player.getY()).append(',').append(mc.player.getZ()).append(']');
            b.append(",\"main\":").append(q(BuiltInRegistries.ITEM.getKey(mc.player.getMainHandItem().getItem()).toString()));
            b.append(",\"off\":").append(q(BuiltInRegistries.ITEM.getKey(mc.player.getOffhandItem().getItem()).toString()));
            b.append(",\"onGround\":").append(mc.player.onGround());
            b.append(",\"spectator\":").append(mc.player.isSpectator());
        }
        b.append(",\"keysDown\":").append(q(keysDown(mc.options)));
        if (mc.player != null) {
            Vec3 eye = mc.player.getEyePosition();
            b.append(",\"eye\":[").append(eye.x).append(',').append(eye.y).append(',').append(eye.z).append(']');
            double ss = mc.options.sensitivity().get() * 0.6F + 0.2F;
            b.append(",\"perPixel\":").append(ss * ss * ss * 8.0 * 0.15);
            HitResult hr = mc.hitResult;
            b.append(",\"hit\":").append(q(hr == null ? "none" : hr instanceof BlockHitResult bh ? "block:" + bh.getBlockPos().toShortString() : hr.getType().name()));
            b.append(",\"hitEntity\":").append(hr instanceof EntityHitResult eh ? eh.getEntity().getId() : -1);
            b.append(",\"scoping\":").append(mc.player.isScoping());
            b.append(",\"sneaking\":").append(mc.player.isShiftKeyDown());
            b.append(",\"carried\":").append(q(BuiltInRegistries.ITEM.getKey(mc.player.containerMenu.getCarried().getItem()).toString()));
            b.append(",\"suggestions\":").append(q(String.join("|", suggestions(mc))));
            if (p.containsKey("block")) {
                String[] c = p.get("block").split(",");
                BlockPos pos = new BlockPos(Integer.parseInt(c[0]), Integer.parseInt(c[1]), Integer.parseInt(c[2]));
                b.append(",\"block\":").append(q(BuiltInRegistries.BLOCK.getKey(mc.level.getBlockState(pos).getBlock()).toString()));
            }
            if (p.containsKey("slot") && mc.gui.screen() instanceof AbstractContainerScreen<?> c) {
                var sl = c.getMenu().slots.get(Integer.parseInt(p.get("slot")));
                int left = (int) field(AbstractContainerScreen.class, c, "leftPos"), top = (int) field(AbstractContainerScreen.class, c, "topPos");
                double scale = mc.getWindow().getGuiScale();
                double x = (left + sl.x + 8) * scale * mc.getWindow().getScreenWidth() / (double) mc.getWindow().getWidth();
                double y = (top + sl.y + 8) * scale * mc.getWindow().getScreenHeight() / (double) mc.getWindow().getHeight();
                b.append(",\"slotPos\":[").append(x).append(',').append(y).append(']');
            }
        }
        return b.append('}').toString();
    }

    static String keysDown(Options o) {
        StringBuilder b = new StringBuilder();
        for (KeyMapping m : o.keyMappings) if (m.isDown()) b.append(m.getName()).append(' ');
        return b.toString().trim();
    }

    static String screenName(Minecraft mc) {
        return mc.gui.screen() == null ? "none" : mc.gui.screen().getClass().getSimpleName();
    }

    @SuppressWarnings({"unchecked", "rawtypes"})
    static Object exitDone() {
        try {
            return Enum.valueOf((Class) Class.forName("net.minecraft.client.gui.screens.ChatScreen$ExitReason"), "DONE");
        } catch (ClassNotFoundException e) {
            throw new RuntimeException(e);
        }
    }

    static void setField(Class<?> owner, Object target, String name, Object v) {
        try {
            Field f = owner.getDeclaredField(name);
            f.setAccessible(true);
            f.set(target, v);
        } catch (ReflectiveOperationException e) {
            throw new RuntimeException(e);
        }
    }

    @SuppressWarnings("unchecked")
    static <T> T field(Class<?> owner, Object target, String name) {
        try {
            Field f = owner.getDeclaredField(name);
            f.setAccessible(true);
            return (T) f.get(target);
        } catch (ReflectiveOperationException e) {
            throw new RuntimeException(e);
        }
    }

    private static void onClient(Minecraft mc, Runnable r) throws Exception {
        CompletableFuture<Void> f = new CompletableFuture<>();
        mc.execute(() -> {
            try {
                r.run();
                f.complete(null);
            } catch (Throwable t) {
                f.completeExceptionally(t);
            }
        });
        f.get(20, TimeUnit.SECONDS);
    }

    static int i(Map<String, String> p, String k) {
        return Integer.parseInt(p.get(k));
    }

    static int i(Map<String, String> p, String k, int d) {
        return p.containsKey(k) ? Integer.parseInt(p.get(k)) : d;
    }

    static double d(Map<String, String> p, String k) {
        return Double.parseDouble(p.get(k));
    }

    static long micros() {
        Instant now = Instant.now();
        return now.getEpochSecond() * 1_000_000L + now.getNano() / 1000;
    }

    static String q(String s) {
        return '"' + s.replace("\\", "\\\\").replace("\"", "\\\"").replace("\n", " ") + '"';
    }
}
