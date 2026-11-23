package com.typewritermc.playtest.plugin;

/**
 * What the Typewriter engine on this Paper applies: its last applied publication. The playtest bridge
 * extension on that engine registers one with Bukkit's services manager, and the plugin reads it when the
 * framework asks whether content is live. Any thread may call it.
 *
 * <p>TODO(node 9): temporary test only signal; replace with the engine's reported active publication
 * ("applied on N of M").
 */
public interface AppliedContent {
    /** The id of the publication the engine applies now, or null before its first. */
    String publication();
}
