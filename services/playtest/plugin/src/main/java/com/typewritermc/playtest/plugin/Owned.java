package com.typewritermc.playtest.plugin;

import com.typewritermc.playtest.wire.Message.Kind;
import java.io.IOException;
import java.io.Reader;
import java.io.UncheckedIOException;
import java.io.Writer;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.StandardOpenOption;
import java.util.ArrayList;
import java.util.EnumSet;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Properties;
import java.util.Set;
import java.util.UUID;
import org.bukkit.Bukkit;
import org.bukkit.entity.Player;
import org.bukkit.event.EventHandler;
import org.bukkit.event.Listener;
import org.bukkit.metadata.FixedMetadataValue;
import org.bukkit.permissions.PermissionAttachment;
import org.bukkit.plugin.Plugin;
import org.bukkit.scheduler.BukkitTask;

/**
 * State this plugin keeps per player in each of the ways plugins keep it: a stored value and a stored
 * permission in a file, a permission attachment, metadata, a session with its history, queued mail, and
 * a hold that lives on for a grace after it ends. Only the framework's own test kit marks it, to prove
 * that a plugin which resets what it owns on the {@link PlayerWipeEvent} leaks nothing into the next
 * attempt. Main thread only.
 */
final class Owned implements Listener {
    /** The kinds this plugin keeps, which it resets when Paper wipes a player. */
    static final Set<Kind> KINDS =
            EnumSet.of(Kind.STORED_VALUE, Kind.STORED_PERMISSION, Kind.ATTACHED_PERMISSION, Kind.METADATA, Kind.SESSION, Kind.MAIL, Kind.HOLD);

    private static final String MARK = "playtest-mark";
    private static final String PERMISSION = "playtest.mark";
    /** A hold outlives its end by a minute, so an attempt that starts within it would adopt it. */
    private static final long HOLD_GRACE_TICKS = 20L * 60;

    private final Plugin plugin;
    private final Path stored;
    private final Path mail;
    private final Map<UUID, PermissionAttachment> attachments = new HashMap<>();
    private final Map<UUID, List<String>> sessions = new HashMap<>();
    private final Map<UUID, BukkitTask> holds = new HashMap<>();

    Owned(Plugin plugin) {
        this.plugin = plugin;
        this.stored = plugin.getDataFolder().toPath().resolve("stored");
        this.mail = plugin.getDataFolder().toPath().resolve("mail");
    }

    /** Leaves a mark of [kind] on the player, as an earlier attempt could. */
    void mark(Player player, Kind kind) {
        UUID id = player.getUniqueId();
        switch (kind) {
            case STORED_VALUE -> store(id, "value", MARK);
            case STORED_PERMISSION -> store(id, "permission", PERMISSION);
            case ATTACHED_PERMISSION -> attachments.computeIfAbsent(id, unused -> player.addAttachment(plugin)).setPermission(PERMISSION, true);
            case METADATA -> player.setMetadata(MARK, new FixedMetadataValue(plugin, MARK));
            case SESSION -> sessions.computeIfAbsent(id, unused -> new ArrayList<>()).add(MARK);
            case MAIL -> append(mail.resolve(id + ".txt"), MARK);
            case HOLD -> {
                BukkitTask old = holds.put(id, Bukkit.getScheduler().runTaskLater(plugin, () -> holds.remove(id), HOLD_GRACE_TICKS));
                if (old != null) old.cancel();
            }
            default -> throw new IllegalArgumentException(kind + " is a kind Paper keeps, not a plugin");
        }
    }

    /** Whether the player carries any mark of [kind] this plugin keeps. */
    boolean marked(Player player, Kind kind) {
        UUID id = player.getUniqueId();
        return switch (kind) {
            case STORED_VALUE -> load(id).containsKey("value");
            case STORED_PERMISSION -> load(id).containsKey("permission");
            case ATTACHED_PERMISSION -> player.hasPermission(PERMISSION);
            case METADATA -> player.hasMetadata(MARK);
            case SESSION -> sessions.containsKey(id);
            case MAIL -> Files.exists(mail.resolve(id + ".txt"));
            case HOLD -> holds.containsKey(id);
            default -> throw new IllegalArgumentException(kind + " is a kind Paper keeps, not a plugin");
        };
    }

    /** Paper wiped the player: everything this plugin keeps for it goes, as for a player who never played. */
    @EventHandler
    public void onWipe(PlayerWipeEvent event) {
        Player player = event.getPlayer();
        UUID id = player.getUniqueId();
        delete(stored.resolve(id + ".properties"));
        PermissionAttachment attachment = attachments.remove(id);
        if (attachment != null) attachment.remove();
        player.removeMetadata(MARK, plugin);
        sessions.remove(id);
        delete(mail.resolve(id + ".txt"));
        BukkitTask hold = holds.remove(id);
        if (hold != null) hold.cancel();
    }

    private Properties load(UUID id) {
        var properties = new Properties();
        Path file = stored.resolve(id + ".properties");
        if (!Files.exists(file)) return properties;
        try (Reader reader = Files.newBufferedReader(file, StandardCharsets.UTF_8)) {
            properties.load(reader);
        } catch (IOException unreadable) {
            throw new UncheckedIOException(unreadable);
        }
        return properties;
    }

    private void store(UUID id, String key, String value) {
        Properties properties = load(id);
        properties.setProperty(key, value);
        try {
            Files.createDirectories(stored);
            try (Writer writer = Files.newBufferedWriter(stored.resolve(id + ".properties"), StandardCharsets.UTF_8)) {
                properties.store(writer, null);
            }
        } catch (IOException unwritable) {
            throw new UncheckedIOException(unwritable);
        }
    }

    private static void append(Path file, String line) {
        try {
            Files.createDirectories(file.getParent());
            Files.writeString(file, line + "\n", StandardCharsets.UTF_8, StandardOpenOption.CREATE, StandardOpenOption.APPEND);
        } catch (IOException unwritable) {
            throw new UncheckedIOException(unwritable);
        }
    }

    private static void delete(Path file) {
        try {
            Files.deleteIfExists(file);
        } catch (IOException undeletable) {
            throw new UncheckedIOException(undeletable);
        }
    }
}
