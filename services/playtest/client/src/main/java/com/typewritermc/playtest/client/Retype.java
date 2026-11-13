package com.typewritermc.playtest.client;

/**
 * The retype a person does when typed command suggestions do not show: after typing into the chat,
 * a suggestion request that gets no answer for {@link #PATIENCE} ticks makes them delete the last
 * character and type it again, which asks once more. It lasts while the chat stays open with the
 * typed text; another edit or a closed chat ends it.
 */
final class Retype {
    static final int PATIENCE = 6;

    private String typed;
    private int waited;

    /** The chat now holds {@code text}, just typed. */
    void typed(String text) {
        typed = text;
        waited = 0;
    }

    void stop() {
        typed = null;
    }

    /**
     * After a tick: whether to retype the last character now. {@code shown} is what the chat holds,
     * or null when it is closed; {@code awaiting} whether its latest suggestion request is unanswered.
     */
    boolean afterTick(String shown, boolean awaiting) {
        if (typed == null) return false;
        if (shown == null || !shown.equals(typed) || shown.isEmpty()) {
            typed = null;
            return false;
        }
        if (!awaiting) {
            waited = 0;
            return false;
        }
        if (++waited < PATIENCE) return false;
        waited = 0;
        return true;
    }
}
