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

    /** The first message on every connection to the pool. */
    record Hello(Role role, String name) implements Message {}

    /** Pool to session: the game cannot run; every requirement of the session fails with this reason. */
    record Refused(String reason) implements Message {}

    /** Session to pool: run one attempt of a requirement once this many players are free. */
    record Submit(long submission, String testId, String requirement, int players) implements Message {}

    /** One player a lease hands to an attempt. */
    record Player(String name, UUID uuid) {}

    /** Pool to session: these players belong to the submission's attempt until its {@link Result}. */
    record Lease(long submission, List<Player> players) implements Message {}

    /**
     * Session to pool: the attempt ended and its players are free again. {@code failure} is null for a
     * pass; {@code firstBroken} names the requirement line that failed, when it is known.
     */
    record Result(long submission, long durationMillis, String failure, String firstBroken) implements Message {}

    /** Session to pool: the session is done; the pool writes its run into {@code testRunFile}. */
    record End(String run, String testRunFile) implements Message {}

    /** Pool to session: the run file is written. */
    record Ended() implements Message {}

    /**
     * Session to Paper: the chat probe sends {@code text} to the player, between ticks. Paper answers with
     * {@link ProbeDone}.
     */
    record ProbeChat(long request, UUID player, String text) implements Message {}

    /** Paper to session: the probe ran after {@code tick} ended, so its effects can show from the next tick. */
    record ProbeDone(long request, int tick) implements Message {}

    /**
     * Session to Paper: run ticks, each once the player acked the one before, until {@code tick} has
     * ended and been acked; then send the player barrier {@code barrier}.
     */
    record StepUntil(UUID player, int tick, int barrier) implements Message {}

    /** Session to Paper: the player's window is decided; run no more ticks for it. */
    record StopStepping(UUID player) implements Message {}

    /** Pool to Paper: from now on a tick runs only when the step policy grants it. */
    record Stepping() implements Message {}

    /** Pool to client: join the Paper at this address. */
    record Connect(String host, int port) implements Message {}

    /** Client to pool: the player is in the world and nothing covers the game. */
    record Ready() implements Message {}

    /** Pool to client: a new attempt starts; forget what earlier attempts showed and perceive afresh. */
    record Reset() implements Message {}

    /** Client to pool: the reset is done; every later record shows only what came after it. */
    record ResetDone() implements Message {}

    /** Client to session: what the player perceives changed. */
    record Perceived(String player, Perception perception) implements Message {}

    /**
     * Client to session: the barrier arrived, after every record of the ticks before it. Paper sends a
     * barrier once the window's last tick ran, so its echo closes the window.
     */
    record BarrierSeen(String player, int barrier) implements Message {}

    /** Everything a player perceives after one tick, complete: the client sends it whole or not at all. */
    record Perception(int tick, List<Text> texts) {}

    /** One legible run of text and the game element that drew it, for example {@code chat}. */
    record Text(String element, String text) {}
}
