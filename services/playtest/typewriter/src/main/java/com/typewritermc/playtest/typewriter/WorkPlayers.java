package com.typewritermc.playtest.typewriter;

import com.typewritermc.loader.api.work.WorkSubject;
import java.util.HashSet;
import java.util.Set;
import java.util.UUID;

/** The Paper players whose work an item of Typewriter's in flight work is. */
final class WorkPlayers {
    /** The subject kind of a Minecraft player, whose id is the player's UUID. */
    private static final String MINECRAFT = "minecraft";

    private WorkPlayers() {}

    /**
     * The players among [subjects]: null when the work is for no subject in particular, empty when it is
     * for subjects of which none is a Minecraft player, such as a panel user.
     */
    static Set<UUID> of(Set<WorkSubject> subjects) {
        if (subjects == null) return null;
        Set<UUID> players = new HashSet<>();
        for (WorkSubject subject : subjects) {
            if (subject.getKind().equals(MINECRAFT)) players.add(UUID.fromString(subject.getId()));
        }
        return Set.copyOf(players);
    }
}
