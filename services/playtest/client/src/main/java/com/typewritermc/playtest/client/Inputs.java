package com.typewritermc.playtest.client;

import com.typewritermc.playtest.client.mixin.AbstractContainerScreenAccessor;
import com.typewritermc.playtest.client.mixin.ChatScreenAccessor;
import com.typewritermc.playtest.client.mixin.CommandSuggestionsAccessor;
import com.typewritermc.playtest.client.mixin.MouseHandlerAccessor;
import com.typewritermc.playtest.wire.Message.AimAtBlockStep;
import com.typewritermc.playtest.wire.Message.AimAtEntityStep;
import com.typewritermc.playtest.wire.Message.ButtonStep;
import com.typewritermc.playtest.wire.Message.Input;
import com.typewritermc.playtest.wire.Message.InputDone;
import com.typewritermc.playtest.wire.Message.InputStep;
import com.typewritermc.playtest.wire.Message.Key;
import com.typewritermc.playtest.wire.Message.KeyStep;
import com.typewritermc.playtest.wire.Message.PointAtSlotStep;
import com.typewritermc.playtest.wire.Message.ScrollStep;
import com.typewritermc.playtest.wire.Message.TypeInChatStep;
import com.typewritermc.playtest.wire.Message.WaitStep;
import com.typewritermc.playtest.wire.Message.WalkToStep;
import java.util.ArrayDeque;
import java.util.Deque;
import java.util.EnumSet;
import java.util.HashSet;
import java.util.Queue;
import java.util.Set;
import java.util.UUID;
import java.util.concurrent.ConcurrentLinkedQueue;
import net.minecraft.client.KeyMapping;
import net.minecraft.client.Minecraft;
import net.minecraft.client.gui.screens.ChatScreen;
import net.minecraft.client.gui.screens.inventory.AbstractContainerScreen;
import net.minecraft.core.BlockPos;
import net.minecraft.world.entity.Entity;
import net.minecraft.world.inventory.Slot;
import net.minecraft.world.phys.BlockHitResult;
import net.minecraft.world.phys.EntityHitResult;
import net.minecraft.world.phys.HitResult;
import net.minecraft.world.phys.Vec3;

/**
 * The player's hands: each {@link Input} becomes a script of steps that send window events through the
 * {@link InputDevice}. Steps run only between ticks, so the next tick handles what they sent. A step runs
 * first right after the step before it ended, and after that once after every tick until it ends; while a
 * script waits on ticks the client is busy, and Paper keeps stepping for it. Render thread only, except
 * {@link #arrive}.
 */
final class Inputs {
    /** Ticks a step waits for the game to answer, such as a screen opening, before it fails. */
    private static final int PATIENCE = 20;

    /** Degrees the view may miss its aim by. */
    private static final double AIM_TOLERANCE = 0.5;

    /** Distance to the point at which walking lets go of the forward key; the player slides the rest. */
    private static final double WALK_RELEASE = 0.35;

    private static final Queue<Input> arrived = new ConcurrentLinkedQueue<>();
    private static final Retype retype = new Retype();
    private static final Set<Key> keysDown = EnumSet.noneOf(Key.class);
    private static final Set<Integer> buttonsDown = new HashSet<>();
    private static InputDevice device;
    private static Script running;

    private Inputs() {}

    /** Whether the window's focus and mouse grab are pretended, because the device cannot give real ones. */
    static boolean pretendsFocus() {
        return !"xtest".equals(System.getProperty("playtest.input", "sdl"));
    }

    /** An input arrived from the session; it starts at the next point between ticks. Any thread. */
    static void arrive(Input input) {
        arrived.add(input);
    }

    /** Whether a script waits on further ticks. */
    static boolean busy() {
        return running != null;
    }

    /** A new attempt: drop every input, let go of every key and button, close every screen, take the mouse. */
    static void reset(Minecraft mc) {
        arrived.clear();
        running = null;
        retype.stop();
        InputDevice hands = device(mc);
        keysDown.forEach(key -> hands.key(key, false));
        buttonsDown.forEach(button -> hands.button(button, false));
        keysDown.clear();
        buttonsDown.clear();
        KeyMapping.releaseAll();
        mc.gui.setScreen(null);
        mc.gui.hud.getChat().discardDraft();
        hands.focus();
        mc.mouseHandler.grabMouse();
    }

    /**
     * A point between ticks: after a tick ended ({@code tickRan}), or in a loop pass that runs no tick.
     * Retypes when a suggestion request went unanswered, moves the running script on, and starts the next
     * input once nothing runs.
     */
    static void betweenTicks(Minecraft mc, boolean tickRan) {
        InputDevice hands = device(mc);
        hands.pass();
        if (tickRan) retypeIfUnanswered(mc, hands);
        if (running != null) {
            if (!tickRan) return;
            running.advance(mc, hands);
        }
        while (running == null) {
            Input next = arrived.poll();
            if (next == null) return;
            running = new Script(next, Stepper.lastRan());
            running.advance(mc, hands);
            if (running != null) Stepper.needTicks();
        }
    }

    private static InputDevice device(Minecraft mc) {
        if (device == null) {
            device = InputDevice.open(mc);
            device.focus();
        }
        return device;
    }

    private static void retypeIfUnanswered(Minecraft mc, InputDevice hands) {
        String shown = null;
        boolean awaiting = false;
        if (mc.gui.screen() instanceof ChatScreen chat) {
            var screen = (ChatScreenAccessor) chat;
            shown = screen.playtest$input().getValue();
            var pending = ((CommandSuggestionsAccessor) screen.playtest$commandSuggestions()).playtest$pendingSuggestions();
            awaiting = pending != null && !pending.isDone();
        }
        if (!retype.afterTick(shown, awaiting)) return;
        int last = shown.codePointBefore(shown.length());
        hands.key(Key.BACKSPACE, true);
        hands.key(Key.BACKSPACE, false);
        hands.type(new String(Character.toChars(last)));
    }

    /** One input's steps in order, from the tick that ended before its first event. */
    private static final class Script {
        private final long request;
        private final int mark;
        private final Deque<Step> steps = new ArrayDeque<>();

        Script(Input input, int mark) {
            this.request = input.request();
            this.mark = mark;
            input.steps().forEach(step -> steps.add(step(step)));
        }

        /** Runs steps until one waits on a tick, the last one ended, or one failed. */
        void advance(Minecraft mc, InputDevice hands) {
            while (!steps.isEmpty()) {
                Progress progress = steps.peek().run(mc, hands);
                if (progress == Progress.WAIT) return;
                steps.poll();
                if (progress != Progress.DONE) {
                    finish(progress.failure());
                    return;
                }
            }
            finish(null);
        }

        private void finish(String failure) {
            running = null;
            PlaytestClient.send(new InputDone(request, mark, failure));
        }
    }

    /** How a step's run went: it ended, it waits on the next tick, or it failed with a reason. */
    private record Progress(boolean ended, String failure) {
        static final Progress DONE = new Progress(true, null);
        static final Progress WAIT = new Progress(false, null);

        static Progress failed(String failure) {
            return new Progress(true, failure);
        }
    }

    private interface Step {
        Progress run(Minecraft mc, InputDevice hands);
    }

    private static Step step(InputStep step) {
        return switch (step) {
            case KeyStep key -> (mc, hands) -> {
                hands.key(key.key(), key.down());
                if (key.down()) keysDown.add(key.key());
                else keysDown.remove(key.key());
                return Progress.DONE;
            };
            case ButtonStep button -> (mc, hands) -> {
                hands.button(button.button(), button.down());
                if (button.down()) buttonsDown.add(button.button());
                else buttonsDown.remove(button.button());
                return Progress.DONE;
            };
            case ScrollStep scroll -> (mc, hands) -> {
                hands.scroll(scroll.amount());
                return Progress.DONE;
            };
            case WaitStep wait -> new Waiting(wait.ticks());
            case TypeInChatStep type -> new TypingInChat(type.text());
            case AimAtEntityStep aim -> new Aiming(aim.entity(), null);
            case AimAtBlockStep aim -> new Aiming(null, new BlockPos(aim.block().x(), aim.block().y(), aim.block().z()));
            case PointAtSlotStep point -> new PointingAtSlot(point.slot());
            case WalkToStep walk -> new Walking(walk.x(), walk.z(), walk.maxTicks());
        };
    }

    /** A step that counts the ticks since it first ran. */
    private abstract static class Timed implements Step {
        private int from = -1;

        final int elapsed() {
            if (from < 0) from = Stepper.lastRan();
            return Stepper.lastRan() - from;
        }
    }

    private static final class Waiting extends Timed {
        private final int ticks;

        Waiting(int ticks) {
            this.ticks = ticks;
        }

        @Override
        public Progress run(Minecraft mc, InputDevice hands) {
            return elapsed() >= ticks ? Progress.DONE : Progress.WAIT;
        }
    }

    /** Opens the chat with its key when it is closed, types, and waits until the chat shows what was typed. */
    private static final class TypingInChat extends Timed {
        private final String text;
        private boolean opening;
        private String expected;

        TypingInChat(String text) {
            this.text = text;
        }

        @Override
        public Progress run(Minecraft mc, InputDevice hands) {
            int elapsed = elapsed();
            if (!(mc.gui.screen() instanceof ChatScreen chat)) {
                if (expected != null) return Progress.failed("the chat closed while typing \"" + text + "\"");
                if (!opening) {
                    opening = true;
                    hands.key(Key.T, true);
                    hands.key(Key.T, false);
                    return Progress.WAIT;
                }
                return elapsed > PATIENCE ? Progress.failed("the chat key opened no chat in " + PATIENCE + " ticks") : Progress.WAIT;
            }
            String shown = ((ChatScreenAccessor) chat).playtest$input().getValue();
            if (expected == null) {
                expected = shown + text;
                hands.type(text);
                return Progress.WAIT;
            }
            if (shown.equals(expected)) {
                retype.typed(expected);
                return Progress.DONE;
            }
            return elapsed > PATIENCE ? Progress.failed("the chat shows \"" + shown + "\", not \"" + expected + "\"") : Progress.WAIT;
        }
    }

    /** Turns the view with the mouse onto an entity or a block, then checks what the crosshair rests on. */
    private static final class Aiming extends Timed {
        private final UUID entity;
        private final BlockPos block;
        private Aim.Direction wanted;

        Aiming(UUID entity, BlockPos block) {
            this.entity = entity;
            this.block = block;
        }

        @Override
        public Progress run(Minecraft mc, InputDevice hands) {
            int elapsed = elapsed();
            var player = mc.player;
            if (player == null || mc.level == null) return Progress.failed("the player is not in a world");
            if (wanted == null) {
                Vec3 target;
                if (entity != null) {
                    Entity subject = mc.level.getEntity(entity);
                    if (subject == null) return Progress.failed("the client knows no entity " + entity);
                    target = subject.getBoundingBox().getCenter();
                } else {
                    target = Vec3.atCenterOf(block);
                }
                Vec3 eye = player.getEyePosition();
                wanted = Aim.toward(eye.x, eye.y, eye.z, target.x, target.y, target.z);
                turn(mc, hands, wanted);
                return Progress.WAIT;
            }
            // The view turns after the tick that handled the motion, so the tick after it picked with it.
            if (!facing(mc, wanted, AIM_TOLERANCE)) {
                return elapsed > PATIENCE ? Progress.failed("the view did not turn onto the target: " + view(mc) + ", wanted " + wanted) : Progress.WAIT;
            }
            HitResult hit = mc.hitResult;
            String missed = entity != null ? missedEntity(hit) : missedBlock(hit);
            if (missed == null) return Progress.DONE;
            return Progress.failed("the crosshair rests on " + missed + ", not on " + target(mc) + " (" + view(mc) + ", wanted " + wanted + ")");
        }

        private String target(Minecraft mc) {
            if (block != null) return "the block at " + block.toShortString() + ", which the client holds as " + mc.level.getBlockState(block);
            Entity subject = mc.level.getEntity(entity);
            return subject == null ? "entity " + entity + ", which the client no longer knows" : subject.getType().toShortString() + " at " + subject.position();
        }

        private String missedEntity(HitResult hit) {
            if (hit instanceof EntityHitResult on && on.getEntity().getUUID().equals(entity)) return null;
            return describe(hit);
        }

        private String missedBlock(HitResult hit) {
            if (hit instanceof BlockHitResult on && hit.getType() == HitResult.Type.BLOCK && on.getBlockPos().equals(block)) return null;
            return describe(hit);
        }
    }

    /** Moves the pointer over the open screen's slot for a slot of the player's inventory. */
    private static final class PointingAtSlot extends Timed {
        private final int slot;

        PointingAtSlot(int slot) {
            this.slot = slot;
        }

        @Override
        public Progress run(Minecraft mc, InputDevice hands) {
            int elapsed = elapsed();
            if (!(mc.gui.screen() instanceof AbstractContainerScreen<?> screen) || mc.player == null) {
                return elapsed > PATIENCE ? Progress.failed("no screen with slots opened in " + PATIENCE + " ticks") : Progress.WAIT;
            }
            for (Slot candidate : screen.getMenu().slots) {
                if (candidate.container != mc.player.getInventory() || candidate.getContainerSlot() != slot) continue;
                var origin = (AbstractContainerScreenAccessor) screen;
                double guiX = origin.playtest$leftPos() + candidate.x + 8;
                double guiY = origin.playtest$topPos() + candidate.y + 8;
                var window = mc.getWindow();
                hands.moveTo(guiX * window.getScreenWidth() / window.getGuiScaledWidth(), guiY * window.getScreenHeight() / window.getGuiScaledHeight());
                return Progress.DONE;
            }
            return Progress.failed("the open screen shows no slot for inventory slot " + slot);
        }
    }

    /** Faces a point, holds the forward key, and lets go once the player will slide onto it. */
    private static final class Walking extends Timed {
        private final double x;
        private final double z;
        private final int maxTicks;
        private Aim.Direction facing;
        private boolean walking;

        Walking(double x, double z, int maxTicks) {
            this.x = x;
            this.z = z;
            this.maxTicks = maxTicks;
        }

        @Override
        public Progress run(Minecraft mc, InputDevice hands) {
            int elapsed = elapsed();
            var player = mc.player;
            if (player == null) return Progress.failed("the player is not in a world");
            double remaining = Math.hypot(x - player.getX(), z - player.getZ());
            if (facing == null) {
                var toward = Aim.toward(player.getX(), 0, player.getZ(), x, 0, z);
                facing = new Aim.Direction(toward.yaw(), player.getXRot());
                turn(mc, hands, facing);
                return Progress.WAIT;
            }
            if (!walking) {
                if (!facing(mc, facing, AIM_TOLERANCE)) {
                    return elapsed > PATIENCE ? Progress.failed("the view did not turn toward the point: " + view(mc)) : Progress.WAIT;
                }
                walking = true;
                hands.key(Key.W, true);
                keysDown.add(Key.W);
                return Progress.WAIT;
            }
            if (remaining <= WALK_RELEASE) {
                hands.key(Key.W, false);
                keysDown.remove(Key.W);
                return Progress.DONE;
            }
            if (elapsed > maxTicks) {
                hands.key(Key.W, false);
                keysDown.remove(Key.W);
                return Progress.failed("after " + maxTicks + " ticks the player stands " + String.format("%.2f", remaining) + " blocks from the point");
            }
            return Progress.WAIT;
        }
    }

    /** Sends the mouse motion that turns the view onto {@code wanted}, settling the pointer first after a grab. */
    private static void turn(Minecraft mc, InputDevice hands, Aim.Direction wanted) {
        var player = mc.player;
        var from = new Aim.Direction(player.getYRot(), player.getXRot());
        var motion = Aim.motion(from, wanted, Aim.degreesPerPixel(mc.options.sensitivity().get()));
        if (((MouseHandlerAccessor) mc.mouseHandler).playtest$ignoreFirstMove()) hands.settle();
        hands.move(motion.x(), motion.y());
    }

    private static boolean facing(Minecraft mc, Aim.Direction wanted, double tolerance) {
        var player = mc.player;
        return Math.abs(Aim.wrap(player.getYRot() - wanted.yaw())) <= tolerance && Math.abs(player.getXRot() - wanted.pitch()) <= tolerance;
    }

    private static String view(Minecraft mc) {
        Vec3 eye = mc.player.getEyePosition();
        return String.format("eye %.2f %.2f %.2f, yaw %.1f pitch %.1f", eye.x, eye.y, eye.z, Aim.wrap(mc.player.getYRot()), mc.player.getXRot());
    }

    private static String describe(HitResult hit) {
        return switch (hit) {
            case null -> "nothing";
            case EntityHitResult on -> on.getEntity().getType().toShortString() + " " + on.getEntity().getUUID();
            case BlockHitResult on when hit.getType() == HitResult.Type.BLOCK -> "the block at " + on.getBlockPos().toShortString();
            default -> "nothing";
        };
    }
}
