package com.typewritermc.playtest.client;

import java.util.ArrayList;
import java.util.List;

/**
 * Which frames a clip draws: 30 for every second of game time, so 3 for every 2 ticks. A frame shows
 * the game at its own time, which falls between two ticks, so it is drawn once the later of them ran,
 * that share of the way from the earlier one. Every tick ends with a pass at its end too, the record a
 * gated attempt makes there, whether a clip frame falls on it or not; so windows judge the same records
 * with or without a clip.
 */
final class ClipSchedule {
    /** One pass after a tick: drawn {@code partial} of the way from the tick before, as clip frame {@code frame}, or -1 when it draws no clip frame. */
    record Pass(float partial, int frame) {}

    private int ticks;
    private int frames;

    /** The passes after the clip's next tick, in the order they draw; the last is at the tick's end. */
    List<Pass> ticked() {
        ticks++;
        // Counted in thirds of a tick from the clip's start: frame k falls at 2(k + 1), and this tick
        // covers the thirds after the last tick's end up to its own end.
        int start = 3 * (ticks - 1);
        int end = 3 * ticks;
        var passes = new ArrayList<Pass>(2);
        boolean frameAtEnd = false;
        for (int at = 2 * (frames + 1); at <= end; at = 2 * (frames + 1)) {
            passes.add(new Pass((at - start) / 3f, frames++));
            frameAtEnd = at == end;
        }
        if (!frameAtEnd) passes.add(new Pass(1f, -1));
        return List.copyOf(passes);
    }

    /** The clip frames drawn so far. */
    int frames() {
        return frames;
    }
}
