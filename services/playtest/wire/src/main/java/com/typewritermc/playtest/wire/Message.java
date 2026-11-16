package com.typewritermc.playtest.wire;

import java.util.List;
import java.util.UUID;

/**
 * Every message between the parts of the game verification framework. The pool sits in the middle:
 * test JVM sessions, the Paper plugin and the client mod each hold one connection to it, and the
 * first message on every connection is a {@link Hello}.
 */
public sealed interface Message {
    /** Who opened a connection to the pool. */
    enum Role { SESSION, PAPER, CLIENT }

    /** What happened to {@code player}, for the session whose attempt holds that player. */
    sealed interface PlayerEvent extends Message {
        String player();
    }

    /** A session's request to the game, which a {@link Reply} answers under the same {@code request}. */
    sealed interface Request extends Message {
        long request();

        /** The same request under another id, as the pool hands it on under a pool wide one. */
        Request withRequest(long request);
    }

    /** A request Paper answers. */
    sealed interface PaperRequest extends Request {}

    /** A request the client of {@code player} answers. */
    sealed interface ClientRequest extends Request {
        UUID player();
    }

    /** The answer to the session's request {@code request}: a probe, a query, an input or a capture. */
    sealed interface Reply extends Message {
        long request();

        /** The same answer to another request, as the pool hands it on under the asker's own id. */
        Reply withRequest(long request);
    }

    /** The first message on every connection to the pool. */
    record Hello(Role role, String name) implements Message {}

    /** Pool to session: the game cannot run; every requirement of the session fails with this reason. */
    record Refused(String reason) implements Message {}

    /** What a requirement's case demonstrates: the path it exists for, a failure it reports, or an edge it holds at. */
    enum Demonstrates { HAPPY_PATH, FAILURE, EDGE_CASE }

    /**
     * One attempt of a requirement to run once {@code players} players are free. Every attempt of one
     * requirement case carries the same {@code testId}, so they land in one case of the run file. With
     * {@code restartsPaper} the attempt runs on a Paper of its own, which its body may kill and boot
     * again: a kill drops every client on a Paper.
     */
    record Submit(long submission, String testId, String requirement, int players, Demonstrates demonstrates, boolean restartsPaper) {}

    /**
     * Session to pool: run these attempts side by side. The pool claims the players of all of them at
     * the same moment and leases them at the same moment, each as an attempt of its own.
     */
    record Queue(List<Submit> together) implements Message {}

    /**
     * Session to pool: the submission's attempt goes on with the same players, released and claimed
     * again as the next attempt would get them: wiped, in a new region. The pool answers with a new
     * {@link Lease}. Only the framework's own test kit sends it, to prove the wipe.
     */
    record Reclaim(long submission) implements Message {}

    /** Pool to session: the pool can never run the submission; {@code reason} says why. */
    record Declined(long submission, String reason) implements Message {}

    /**
     * Pool to session: the submission's attempt failed before its lease, as its own Paper was lost while
     * it booted; {@code reason} says why and where the Paper's log is. The pool recorded the attempt.
     */
    record LeaseFailed(long submission, String reason) implements Message {}

    /**
     * Session to pool: kill the Paper of the submission's attempt, which runs on a Paper of its own, as
     * a crash would, and boot it again on the same world. The pool answers with {@link Restarted} once
     * every player of the attempt is back.
     */
    record Restart(long request, long submission) implements Message {}

    /**
     * Pool to session: the attempt's Paper booted again after its kill and every player's client is
     * back and holds what Paper sends it, from after {@code tick} of the new Paper on.
     */
    record Restarted(long request, int tick) implements Reply {
        @Override
        public Restarted withRequest(long request) {
            return new Restarted(request, tick);
        }
    }

    /** One player a lease hands to an attempt. */
    record Player(String name, UUID uuid) {}

    /**
     * An attempt's own part of the world: the blocks within {@link #RADIUS} of {@code x}, {@code z} across
     * the ground, at every height. No other attempt of the pool ever uses it, and regions lie
     * {@link #SPACING} blocks apart, so nothing one attempt places, spawns or plays reaches another.
     */
    record Region(int x, int z) {
        public static final int SPACING = 1024;
        public static final int RADIUS = SPACING / 2;
    }

    /**
     * Pool to session: these players belong to the submission's attempt until its {@link Result}, each
     * wiped and standing in the attempt's {@code region} on the Paper named {@code paper}: the shared
     * Paper, or the attempt's own, named after the attempt.
     */
    record Lease(long submission, List<Player> players, Region region, String paper) implements Message {}

    /**
     * One thing an attempt did: it began at {@code atMillis}, Unix milliseconds, and took
     * {@code durationMillis}. {@code says} starts with what kind of thing it was: claim, wipe, probe,
     * input, window or settle.
     */
    record AttemptStep(long atMillis, long durationMillis, String says) {}

    /**
     * Session to pool: the attempt ended and its players are free again. {@code failure} is null for a
     * pass; {@code firstBroken} names the requirement line that failed, when it is known. {@code steps}
     * are what the attempt's bodies did, in order. {@code folder} holds the attempt's evidence, relative
     * to the run file's folder, or is empty when it left none; {@code screenshots} are the frames it
     * wrote there, relative to {@code folder}.
     */
    record Result(
            long submission,
            long durationMillis,
            String failure,
            String firstBroken,
            List<AttemptStep> steps,
            String folder,
            List<String> screenshots)
        implements Message {}

    /** How a run makes its requirements' attempts: failed ones again, up to {@code attempts} in total, or each exactly {@code attempts} times. */
    record AttemptPolicy(Kind kind, int attempts) {
        public enum Kind { RERUN_FAILURES, EXACTLY }
    }

    /** Session to pool: the session is done; the pool writes its run, made under {@code policy}, into {@code testRunFile}. */
    record End(String run, String testRunFile, AttemptPolicy policy) implements Message {}

    /** Pool to session: the run file is written. */
    record Ended() implements Message {}

    /**
     * Session to Paper: run {@code action} between ticks. An action on a player runs for each of
     * {@code players}; an action on the world runs once, in the region of their attempt. Paper answers
     * with {@link ProbeDone} once the client of each of {@code players} holds what it caused.
     */
    record Probe(long request, List<UUID> players, ProbeAction action) implements PaperRequest {
        @Override
        public Probe withRequest(long request) {
            return new Probe(request, players, action);
        }
    }

    /**
     * Paper to session: the probe ran after {@code tick} ended, so its effects can show from the next
     * tick, and its players' clients now hold all it caused. {@code failure} is null when it ran, or says
     * why it could not.
     */
    record ProbeDone(long request, int tick, String failure) implements Reply {
        @Override
        public ProbeDone withRequest(long request) {
            return new ProbeDone(request, tick, failure);
        }
    }

    /**
     * Session to Paper: run ticks, each once the player acked the one before, until {@code tick} has
     * ended and been acked; then send the player barrier {@code barrier}.
     */
    record StepUntil(UUID player, int tick, int barrier) implements Message {}

    /** Session to Paper: the player's window is decided; run no more ticks for it. */
    record StopStepping(UUID player) implements Message {}

    /**
     * Session to Paper: which kinds of state {@code player} still carries a mark of. Paper answers with
     * {@link Marks}. Only the framework's own test kit asks, for kinds no player can see.
     */
    record Query(long request, UUID player) implements PaperRequest {
        @Override
        public Query withRequest(long request) {
            return new Query(request, player);
        }
    }

    /** Paper to session: the kinds the player carries a mark of; {@code failure} is null when Paper could look. */
    record Marks(long request, List<Kind> marked, String failure) implements Reply {
        @Override
        public Marks withRequest(long request) {
            return new Marks(request, marked, failure);
        }
    }

    /**
     * A kind of per player state an attempt can leave behind for the next attempt on the same player.
     * Paper's wipe clears the vanilla and Paper kinds; each plugin resets the kinds it owns when Paper
     * wipes a player, here the framework's own Paper plugin.
     */
    enum Kind {
        /** Teams on the main scoreboard the player belongs to, and its scores. */
        SCOREBOARD,
        /** Items in the player's ender chest. */
        ENDER_CHEST,
        /** Potion effects on the player. */
        EFFECTS,
        /** Experience levels and progress. */
        EXPERIENCE,
        /** Keys in the player's persistent data container. */
        PERSISTENT_DATA,
        /** A time of day or weather the player sees instead of the world's. */
        PLAYER_TIME,
        /**
         * Boss bars shown to the player that Paper can list: every adventure bar and every keyed Bukkit
         * bar. A Bukkit bar without a key is the plugin's that created it, which hides it on the wipe.
         */
        BOSS_BAR,
        /** Recipes the player's recipe book holds. */
        RECIPES,
        /** Advancement criteria the player earned. */
        ADVANCEMENTS,
        /** A game mode other than the server's default. */
        GAME_MODE,
        /** A selected hotbar slot other than the first. */
        HELD_SLOT,
        /** An open container, or any other screen Paper opened for the player, such as a sign editor. */
        OPEN_CONTAINER,
        /** A vehicle the player rides, passengers riding the player, and parrots on its shoulders. */
        RIDING,
        /** Whether the player may fly and flies, and whether flying lets it take fall damage. */
        FLIGHT,
        /** The player's walking and flying speed. */
        SPEED,
        /** Base values of the player's attributes other than a new player's, and modifiers on them. */
        ATTRIBUTES,
        /** Health below the maximum, and hearts the client scales. */
        HEALTH,
        /** Food level, saturation and exhaustion, and the rates at which food heals or starves the player. */
        FOOD,
        /** Air below the maximum, and a maximum other than vanilla's. */
        AIR,
        /** Fire ticks, and fire the player shows without burning. */
        FIRE,
        /** Freeze ticks, and a lock that keeps them. */
        FREEZE,
        /** The last damage the player took, who killed it, and how long it stays immune after a hit. */
        COMBAT,
        /** Where the player last died, and the score its death screen shows. */
        DEATH,
        /** Values of the player's statistics: blocks mined, items crafted, mobs killed and the rest. */
        STATISTICS,
        /** A bed or respawn anchor the player respawns at. */
        SPAWN_POINT,
        /** A compass target a plugin set for the player. */
        COMPASS,
        /** Item cooldowns, the portal cooldown and the experience pickup cooldown. */
        COOLDOWNS,
        /**
         * Flags a plugin sets on the player as an entity: invulnerable, silent, without gravity, not
         * collidable, unable to pick up items, without physics, ignored for sleeping, not counted for
         * spawning, sneaking, sprinting, or held in a fixed pose.
         */
        ENTITY_FLAGS,
        /**
         * How others see the player: its display name, its name, order, header and footer in the player
         * list, glowing, invisible, arrows and stingers in its body, its locator bar colour and profile
         * properties such as a skin.
         */
        APPEARANCE,
        /** Scoreboard tags on the player. */
        TAGS,
        /** A world border the player sees instead of the world's. */
        WORLD_BORDER,
        /** View, send and simulation distances set for the player instead of the world's. */
        VIEW_DISTANCE,
        /** The warden warning level a shrieker raised for the player, and its cooldown. */
        WARDEN,
        /** Having seen the credits, which a new player sees when it first leaves the End. */
        CREDITS,
        /** The seed that picks the player's enchanting table offers. */
        ENCHANTMENT_SEED,
        /** A value a plugin stores for the player in a file. */
        STORED_VALUE,
        /** A permission a plugin stores for the player in a file. */
        STORED_PERMISSION,
        /** A permission a plugin attached to the online player. */
        ATTACHED_PERMISSION,
        /** Metadata a plugin set on the player. */
        METADATA,
        /** A session a plugin keeps for the player, with its history. */
        SESSION,
        /** Mail a plugin queued for the player. */
        MAIL,
        /** A hold a plugin keeps for a short grace after it ends, which a new one would adopt. */
        HOLD
    }

    /**
     * Pool to Paper: {@code players} belong to attempt {@code attempt} from now on. Paper wipes each of
     * them, puts them in the attempt's {@code region}, shows them only to one another, and from now on
     * holds back ticks for the work their plugins count. It answers with {@link Claimed}.
     */
    record Claim(long attempt, List<UUID> players, Region region) implements Message {}

    /**
     * Paper to pool: the attempt's players are wiped and in its region, and their clients hold all of
     * it. {@code failure} is null when it worked, or says why it could not.
     */
    record Claimed(long attempt, String failure) implements Message {}

    /**
     * Pool to Paper: the regions the next claims get, in the order they get them, sent once Paper connects
     * and again after every claim. Paper loads the ground around each ahead of time and keeps it loaded
     * until the attempt in that region ends, so a claim finds its chunks ready.
     */
    record RegionsAhead(List<Region> regions) implements Message {}

    /** Pool to Paper: the attempt ended; its players' work no longer holds back ticks and their windows close. */
    record Release(long attempt) implements Message {}

    /**
     * The attempt's body ended; it is done once the work its players' plugins count is quiet. Session to
     * pool with {@code id} the session's submission, pool to Paper with {@code id} the attempt. Answered
     * with {@link Settled} once no player of the attempt has work that is neither ended nor hung.
     */
    record Settle(long id) implements Message {}

    /** Paper to pool with {@code id} the attempt, pool to session with {@code id} the submission: see {@link Settle}. */
    record Settled(long id) implements Message {}

    /**
     * Paper to the session holding {@code player}: the player's work {@code work}, which began after
     * tick {@code beganAfter}, still ran 1 s later. Paper never cancels it and lets it hold no more
     * ticks; the attempt fails.
     */
    record WorkHung(String player, String work, int beganAfter) implements PlayerEvent {}

    /**
     * Paper to pool: {@code player} left Paper, for {@code reason}; its client no longer holds back any
     * tick.
     */
    record PlayerLeft(String player, String reason) implements Message {}

    /**
     * Pool to the session holding {@code player}: the player's client is lost, for {@code reason}; the
     * attempt fails and the pool starts a new client for the player.
     */
    record ClientLost(String player, String reason) implements PlayerEvent {}

    /**
     * Paper to pool: {@code player}'s client acked nothing for 5 s of wall clock while behind, after tick
     * {@code lastAcked}; it holds back no tick any more and counts as lost.
     */
    record ClientStalled(String player, int lastAcked) implements Message {}

    /**
     * Pool to the session holding {@code player}: the Paper of its attempt, one of its own, was lost,
     * for {@code reason}, which names the Paper's log; the attempt fails.
     */
    record PaperLost(String player, String reason) implements PlayerEvent {}

    /**
     * Pool to Paper: Paper booted again under attempt {@code attempt} after a kill, and {@code players}
     * belong to it again, unwiped and where Paper put them. From now on their counted work holds back
     * ticks. Paper answers with {@link Resumed}.
     */
    record Resume(long attempt, List<UUID> players) implements Message {}

    /**
     * Paper to pool: the resumed attempt's players' clients hold all Paper sends them, from after
     * {@code tick} on. {@code failure} is null when it worked, or says why it could not.
     */
    record Resumed(long attempt, int tick, String failure) implements Message {}

    /** Paper to pool: {@code player}'s work {@code work}, reported hung earlier, ended. */
    record HungEnded(String player, String work) implements Message {}

    /** Pool to Paper: from now on a tick runs only when the step policy grants it. */
    record Stepping() implements Message {}

    /**
     * Pool to client: join the Paper at this address, first leaving the one the client is on, the way
     * the pause menu leaves.
     */
    record Connect(String host, int port) implements Message {}

    /**
     * Client to pool: the client lost the Paper on {@code port} without being told to leave it, for
     * {@code reason}: its connection dropped or it could not join. It draws nothing until the next
     * {@link Connect}.
     */
    record Disconnected(int port, String reason) implements Message {}

    /** Client to pool: the player is in the world and nothing covers the game, so Paper may start stepping. */
    record Joined() implements Message {}

    /** Client to pool: the client steps with Paper, so everything it receives from now on has a tick; it can serve a lease. */
    record Ready() implements Message {}

    /**
     * Pool to client: a new attempt starts. The client releases every key and button, closes every
     * screen, drops the chat draft and its watches, takes the mouse, starts what it eases from tick to
     * tick (sky and fog) and what it counts down between inputs (the delay after a broken block) afresh,
     * and perceives afresh.
     */
    record Reset() implements Message {}

    /** Client to pool: the reset is done; every later record shows only what came after it. */
    record ResetDone() implements Message {}

    /**
     * Session to the player's client: what a person does with the keyboard and mouse, as window input
     * the client sends to its own window. The steps run in order on the client's ticks; the client answers with
     * {@link InputDone} once the last one ran.
     */
    record Input(long request, UUID player, List<InputStep> steps) implements ClientRequest {
        @Override
        public Input withRequest(long request) {
            return new Input(request, player, steps);
        }
    }

    /**
     * Client to session: the input's steps ran. Its first event reached the client after {@code tick}
     * ended, so the input shows from the next tick. {@code failure} is null when every step ran, or
     * says which step could not, for example an aim that left something else under the crosshair.
     */
    record InputDone(long request, int tick, String failure) implements Reply {
        @Override
        public InputDone withRequest(long request) {
            return new InputDone(request, tick, failure);
        }
    }

    /**
     * Session to the player's client: draw the frame as the client holds it now, for real, and write it
     * as a PNG to {@code path}. The client answers with {@link Captured}.
     */
    record Capture(long request, UUID player, String path) implements ClientRequest {
        @Override
        public Capture withRequest(long request) {
            return new Capture(request, player, path);
        }
    }

    /** Client to session: the frame is written, drawn by {@code renderer}; {@code failure} is null when it was. */
    record Captured(long request, Renderer renderer, String failure) implements Reply {
        @Override
        public Captured withRequest(long request) {
            return new Captured(request, renderer, failure);
        }
    }

    /**
     * What drew a frame: the graphics backend, the device and the driver it reports, the operating
     * system and the CPU architecture. Two renderers draw the same scene alike to the pixel only when
     * all five match.
     */
    record Renderer(String backend, String device, String driver, String os, String arch) {}

    /** Client to session: what the player perceives changed. */
    record Perceived(String player, Perception perception) implements PlayerEvent {}

    /**
     * Client to session: the barrier arrived, after every record of the ticks before it. Paper sends a
     * barrier once the window's last tick ran, so its echo closes the window.
     */
    record BarrierSeen(String player, int barrier) implements PlayerEvent {}

    /** A block position in the world. */
    record BlockPos(int x, int y, int z) {}

    /** What a probe does on Paper. Names of items, blocks and entity types are Minecraft ids such as {@code minecraft:stick}. */
    sealed interface ProbeAction {}

    /** An action on a player: it runs for each player of its probe. */
    sealed interface PlayerAction extends ProbeAction {}

    /** An action on the world: it runs once, in the world of its probe's players. */
    sealed interface WorldAction extends ProbeAction {}

    /** Paper sends {@code text} to the player as a chat line. */
    record ProbeChat(String text) implements PlayerAction {}

    /** The player's game mode becomes {@code mode}: survival, creative, adventure or spectator. */
    record ProbeGameMode(String mode) implements PlayerAction {}

    /** The player stands at this position, looking this way. */
    record ProbeTeleport(double x, double y, double z, float yaw, float pitch) implements PlayerAction {}

    /** The player's inventory slot {@code slot} (0 to 8 hotbar, 9 to 35 the rest, 40 the off hand) holds {@code count} of {@code item}. */
    record ProbeGive(int slot, String item, int count) implements PlayerAction {}

    /** The player holds hotbar slot {@code slot}, 0 to 8. */
    record ProbeSelectSlot(int slot) implements PlayerAction {}

    /**
     * An entity {@code uuid} of {@code type} that only the player's client knows, as Paper never holds
     * it, stands still at this position, facing {@code yaw}. It reacts as a {@link ProbeSpawn} entity.
     */
    record ProbePacketEntity(UUID uuid, String type, double x, double y, double z, float yaw, String onHit, String onClick) implements PlayerAction {}

    /**
     * The player may run the command {@code /name}, which exists for no player a probe did not give it
     * to: its argument suggests every entry of {@code suggestions} that starts with what is typed, and
     * running it answers with a chat line of {@code answer}, a space and the arguments.
     */
    record ProbeCommand(String name, List<String> suggestions, String answer) implements PlayerAction {}

    /** Every block from {@code from} to {@code to}, both included, becomes {@code block}, a block state such as {@code minecraft:oak_leaves[persistent=true]}. */
    record ProbeFill(BlockPos from, BlockPos to, String block) implements WorldAction {}

    /**
     * An entity {@code uuid} of {@code type} stands still at this position, facing {@code yaw}, and
     * {@code invisible} as the invisibility effect makes it. When a player hits it, its name tag shows
     * {@code onHit}; when a player uses it, {@code onClick}; null leaves that reaction out.
     */
    record ProbeSpawn(UUID uuid, String type, double x, double y, double z, float yaw, boolean invisible, String onHit, String onClick)
        implements WorldAction {}

    /**
     * The block at {@code at} becomes {@code block}, a block state such as
     * {@code minecraft:oak_leaves[persistent=true]}, and every player of the probe watches it: Paper
     * sends the watch on each player's connection ahead of the change.
     */
    record ProbeBlock(BlockPos at, String block) implements WorldAction {}

    /** Paper cancels every break of the block at {@code at}, as a protection plugin would. */
    record ProbeCancelBreaking(BlockPos at) implements WorldAction {}

    /**
     * The player carries a mark of {@code kind}, as an earlier attempt could leave it. Only the
     * framework's own test kit sends it, to prove the wipe clears every kind.
     */
    record ProbeMark(Kind kind) implements PlayerAction {}

    /**
     * The player's work {@code name} runs off the main thread for {@code millis} of wall clock, counted
     * as any plugin counts its work, then sends {@code chat} as a chat line. Only the framework's own
     * test kit sends it, to prove ticks wait for counted work and hung work is reported.
     */
    record ProbeWork(String name, int millis, String chat) implements PlayerAction {}

    /** The player sees a sidebar titled {@code title} holding {@code lines}, top to bottom. */
    record ProbeSidebar(String title, List<String> lines) implements PlayerAction {}

    /** The player sees the time of day stand still at {@code time} ticks: 0 is sunrise, 6000 noon. */
    record ProbeTime(long time) implements PlayerAction {}

    /** Paper writes the player's data to disk now, as it does when the player quits or the world saves. */
    record ProbeSave() implements PlayerAction {}

    /** One step of an {@link Input}. Keys are named as {@link Key} names them. */
    sealed interface InputStep {}

    /** Presses ({@code down}) or releases a key. */
    record KeyStep(Key key, boolean down) implements InputStep {}

    /** Presses or releases a mouse button: 1 left, 2 middle, 3 right. */
    record ButtonStep(int button, boolean down) implements InputStep {}

    /** Turns the mouse wheel by {@code amount} notches; negative scrolls down. */
    record ScrollStep(int amount) implements InputStep {}

    /**
     * Types {@code text} into the chat, opening it with the chat key first when it is closed. While the
     * chat stays open with that text, the client retypes the last character whenever a suggestion
     * request got no answer for 6 ticks, as a person does when no list shows.
     */
    record TypeInChatStep(String text) implements InputStep {}

    /** Waits {@code ticks} client ticks. */
    record WaitStep(int ticks) implements InputStep {}

    /** Turns the view with the mouse until the crosshair is on the entity; fails when it lands on something else. */
    record AimAtEntityStep(UUID entity) implements InputStep {}

    /** Turns the view with the mouse until the crosshair is on the block; fails when it lands on something else. */
    record AimAtBlockStep(BlockPos block) implements InputStep {}

    /** Moves the pointer over the open screen's slot for the player's inventory slot {@code slot}. */
    record PointAtSlotStep(int slot) implements InputStep {}

    /**
     * Faces the point and holds the forward key until the player stands within half a block of it,
     * or {@code maxTicks} passed.
     */
    record WalkToStep(double x, double z, int maxTicks) implements InputStep {}

    /** The keys a requirement may press, as the default key bindings name them. */
    enum Key {
        W, A, S, D, E, F, Q, T, SPACE, LEFT_SHIFT, ENTER, BACKSPACE, ESCAPE, SLASH,
        DIGIT_1, DIGIT_2, DIGIT_3, DIGIT_4, DIGIT_5, DIGIT_6, DIGIT_7, DIGIT_8, DIGIT_9
    }

    /**
     * Everything a player perceives after one tick, complete: the client sends it whole or not at all.
     * {@code texts} is every legible run of text on screen; {@code chat} every chat line that arrived
     * since the attempt's reset, whether it still shows or not; {@code camera} the view the frame was
     * drawn from, or null without a world; {@code items} every item the GUI draws where it can be
     * seen; {@code blocks} and {@code entities} what the watches name.
     */
    record Perception(int tick, List<Text> texts, List<ChatLine> chat, Camera camera, List<Item> items, List<Block> blocks, List<Entity> entities) {}

    /** One legible run of text and the game element that drew it, for example {@code chat}. */
    record Text(String element, String text) {}

    /** A chat line and the tick in which it arrived. */
    record ChatLine(int tick, String text) {}

    /**
     * The view a frame was drawn from: the eye's position, yaw and pitch in degrees, the vertical
     * field of view in degrees, and whether the spyglass overlay covers it.
     */
    record Camera(double x, double y, double z, float yaw, float pitch, float fov, boolean scoped) {}

    /**
     * An item the GUI draws: {@code element} is {@code hotbar} (slot 0 to 8, {@code selected} for the
     * one the selection frame marks), {@code offhand}, {@code carried} (on the pointer) or
     * {@code screen} (a slot of the open screen, numbered by the screen), or {@code other} with slot -1;
     * {@code item} is its id.
     */
    record Item(String element, int slot, boolean selected, String item, int count) {}

    /**
     * A watched block: its block id, whether the player perceives it as it is (its section is
     * compiled since the block last changed, visible and inside the view), and the tick it last changed
     * since the attempt's reset, or -1.
     */
    record Block(BlockPos at, String block, boolean seen, int changed) {}

    /**
     * A watched entity the frame draws after culling: whether it shows the red hurt tint, the name tag
     * drawn above it, or null, and the share of the frame it owns, from 0 to 1: the pixels that differ
     * when the frame is drawn without it, over all of the frame's pixels. {@code share} is
     * {@link #UNMEASURED} in a frame the client drew as any client does, before it steps.
     */
    record Entity(UUID uuid, boolean hurt, String name, double share) {
        public static final double UNMEASURED = -1;
    }
}
