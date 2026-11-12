package probe.plugin;

import com.destroystokyo.paper.event.player.PlayerJumpEvent;
import com.destroystokyo.paper.event.player.PlayerUseUnknownEntityEvent;
import com.destroystokyo.paper.event.server.AsyncTabCompleteEvent;
import com.destroystokyo.paper.event.brigadier.AsyncPlayerSendSuggestionsEvent;
import io.netty.channel.Channel;
import io.netty.channel.ChannelHandlerContext;
import io.netty.channel.ChannelInboundHandlerAdapter;
import io.papermc.paper.event.player.AsyncChatEvent;
import io.papermc.paper.event.player.PlayerArmSwingEvent;
import io.papermc.paper.event.player.PlayerStopUsingItemEvent;
import io.papermc.paper.event.player.PrePlayerAttackEntityEvent;
import java.nio.ByteBuffer;
import java.time.Instant;
import java.util.ArrayList;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import java.util.UUID;
import net.kyori.adventure.text.serializer.plain.PlainTextComponentSerializer;
import net.minecraft.network.protocol.Packet;
import net.minecraft.network.protocol.common.ServerboundCustomPayloadPacket;
import net.minecraft.network.protocol.game.ClientboundAddEntityPacket;
import net.minecraft.network.protocol.game.ClientboundRemoveEntitiesPacket;
import net.minecraft.network.protocol.game.ServerboundAttackPacket;
import net.minecraft.network.protocol.game.ServerboundCommandSuggestionPacket;
import net.minecraft.network.protocol.game.ServerboundContainerClickPacket;
import net.minecraft.network.protocol.game.ServerboundInteractPacket;
import net.minecraft.network.protocol.game.ServerboundPlayerActionPacket;
import net.minecraft.network.protocol.game.ServerboundPlayerInputPacket;
import net.minecraft.network.protocol.game.ServerboundSetCarriedItemPacket;
import net.minecraft.network.protocol.game.ServerboundUseItemOnPacket;
import net.minecraft.server.MinecraftServer;
import net.minecraft.world.phys.Vec3;
import org.bukkit.Bukkit;
import org.bukkit.GameMode;
import org.bukkit.Location;
import org.bukkit.Material;
import org.bukkit.World;
import org.bukkit.block.Block;
import org.bukkit.command.PluginCommand;
import org.bukkit.craftbukkit.entity.CraftPlayer;
import org.bukkit.entity.Entity;
import org.bukkit.entity.Pig;
import org.bukkit.entity.Player;
import org.bukkit.event.EventHandler;
import org.bukkit.event.EventPriority;
import org.bukkit.event.Listener;
import org.bukkit.event.block.BlockBreakEvent;
import org.bukkit.event.block.BlockDamageAbortEvent;
import org.bukkit.event.block.BlockDamageEvent;
import org.bukkit.event.entity.EntityDamageByEntityEvent;
import org.bukkit.event.inventory.InventoryClickEvent;
import org.bukkit.event.inventory.InventoryCloseEvent;
import org.bukkit.event.inventory.InventoryOpenEvent;
import org.bukkit.event.player.PlayerAnimationEvent;
import org.bukkit.event.player.PlayerCommandPreprocessEvent;
import org.bukkit.event.player.PlayerInputEvent;
import org.bukkit.event.player.PlayerInteractAtEntityEvent;
import org.bukkit.event.player.PlayerInteractEntityEvent;
import org.bukkit.event.player.PlayerInteractEvent;
import org.bukkit.event.player.PlayerItemHeldEvent;
import org.bukkit.event.player.PlayerJoinEvent;
import org.bukkit.event.player.PlayerMoveEvent;
import org.bukkit.event.player.PlayerSwapHandItemsEvent;
import org.bukkit.event.player.PlayerToggleSneakEvent;
import org.bukkit.event.server.TabCompleteEvent;
import org.bukkit.inventory.ItemStack;
import org.bukkit.inventory.PlayerInventory;

/**
 * Spike J server side. Records, per input, the Paper events and the serverbound packets in arrival
 * order, so the same input sent through different paths can be compared with what a person causes.
 */
final class Input implements Listener {
    static final int Y = 65;
    static final int PACKET_PIG = 900_001;
    private static ProbePlugin plugin;
    private static final List<String> log = new ArrayList<>();
    private static int seq;
    private static volatile Location cancelBreak;
    private static final List<Entity> spawned = new ArrayList<>();
    private static boolean packetPigShown;

    static void start(ProbePlugin p) {
        plugin = p;
        Bukkit.getPluginManager().registerEvents(new Input(), p);
        Bukkit.getMessenger().registerIncomingPluginChannel(p, "probe:mark", (channel, player, bytes) -> {
            int id = ByteBuffer.wrap(bytes).getInt();
            boolean main = Bukkit.isPrimaryThread();
            add("ev", "mark", id + (main ? "" : " offmain"));
            if (!main) MinecraftServer.getServer().execute(() -> add("ev", "mark", String.valueOf(id)));
        });
        // Logs the server's view of the player's ground flag whenever it changes (spike J, break at high rates).
        boolean[] lastGround = {false};
        Bukkit.getScheduler().runTaskTimer(p, () -> {
            for (Player pl : Bukkit.getOnlinePlayers()) {
                boolean g = ((CraftPlayer) pl).getHandle().onGround();
                if (g != lastGround[0]) add("ev", "ground", String.valueOf(g));
                lastGround[0] = g;
            }
        }, 1L, 1L);
        PluginCommand claim = p.getCommand("claim");
        claim.setExecutor((sender, cmd, label, args) -> {
            add("ev", "ClaimCommand", String.join(" ", args));
            return true;
        });
        claim.setTabCompleter((sender, cmd, label, args) -> {
            add("ev", "ClaimTabCompleter", String.join(" ", args));
            String last = args.length == 0 ? "" : args[args.length - 1];
            return List.of("here", "home", "help").stream().filter(s -> s.startsWith(last)).toList();
        });
    }

    static synchronized void add(String kind, String name, String detail) {
        String th = Bukkit.isPrimaryThread() ? "main" : Thread.currentThread().getName().startsWith("Netty") ? "net" : "async";
        log.add("{\"seq\":" + (++seq) + ",\"tick\":" + Bukkit.getCurrentTick() + ",\"st\":" + MinecraftServer.getServer().getTickCount() + ",\"tn\":" + q(Thread.currentThread().getName()) + ",\"us\":" + micros() + ",\"th\":\"" + th + "\",\"k\":\"" + kind
                + "\",\"n\":" + q(name) + ",\"d\":" + q(detail) + "}");
    }

    static synchronized String since(int from) {
        StringBuilder b = new StringBuilder("[");
        for (int i = Math.max(0, from); i < log.size(); i++) {
            if (b.length() > 1) b.append(',');
            b.append(log.get(i));
        }
        return b.append(']').toString();
    }

    // ---- packets, in arrival order on the connection's event loop ----

    @EventHandler
    public void join(PlayerJoinEvent e) {
        Channel ch = ((CraftPlayer) e.getPlayer()).getHandle().connection.connection.channel;
        ch.eventLoop().execute(() -> {
            if (ch.pipeline().get("probe_in") == null) ch.pipeline().addBefore("packet_handler", "probe_in", new ChannelInboundHandlerAdapter() {
                @Override
                public void channelRead(ChannelHandlerContext ctx, Object msg) throws Exception {
                    if (msg instanceof Packet<?> pk) packet(pk);
                    super.channelRead(ctx, msg);
                }
            });
        });
    }

    static void packet(Packet<?> pk) {
        String full = pk.getClass().getName();
        String n = full.substring(full.lastIndexOf('.') + 1).replace("Serverbound", "").replace("Packet", "");
        switch (n) {
            case "KeepAlive", "ClientTickEnd", "ChunkBatchReceived", "Pong", "ChatAck", "ClientInformation" -> {
                return;
            }
            default -> {}
        }
        String d = "";
        if (pk instanceof ServerboundPlayerActionPacket a) d = a.getAction().name() + gameTicks();
        else if (pk instanceof ServerboundPlayerInputPacket in) d = in.input().toString().replace("Input[", "").replace("]", "").replace("=false", "").replace(", ", "").replace("=true", "+");
        else if (pk instanceof ServerboundSetCarriedItemPacket s) d = String.valueOf(s.getSlot());
        else if (pk instanceof ServerboundContainerClickPacket c) d = c.slotNum() + "/" + c.containerInput();
        else if (pk instanceof ServerboundInteractPacket i) d = i.entityId() + "/" + i.hand();
        else if (pk instanceof ServerboundAttackPacket a) d = String.valueOf(a.entityId());
        else if (pk instanceof ServerboundCommandSuggestionPacket c) d = c.command();
        else if (pk instanceof ServerboundUseItemOnPacket u) d = u.hitResult().getBlockPos().toShortString();
        else if (pk instanceof ServerboundCustomPayloadPacket c) d = c.payload().type().id().toString();
        if (n.startsWith("MovePlayer")) n = "MovePlayer";
        add("pk", n, d);
    }

    static String gameTicks() {
        try {
            for (Player pl : Bukkit.getOnlinePlayers()) {
                var gm = ((CraftPlayer) pl).getHandle().gameMode;
                var f = net.minecraft.server.level.ServerPlayerGameMode.class.getDeclaredField("gameTicks");
                f.setAccessible(true);
                var g = net.minecraft.server.level.ServerPlayerGameMode.class.getDeclaredField("destroyProgressStart");
                g.setAccessible(true);
                return " gt=" + f.getInt(gm) + " start=" + g.getInt(gm) + " bt=" + Bukkit.getCurrentTick() + " ground=" + ((CraftPlayer) pl).getHandle().onGround();
            }
        } catch (ReflectiveOperationException e) {
            return " " + e;
        }
        return "";
    }

    // ---- events ----

    private static String b(Block b) {
        return b.getX() + "," + b.getY() + "," + b.getZ();
    }

    @EventHandler(priority = EventPriority.MONITOR, ignoreCancelled = false)
    public void chat(AsyncChatEvent e) {
        add("ev", "AsyncChatEvent", PlainTextComponentSerializer.plainText().serialize(e.message()));
    }

    @EventHandler(priority = EventPriority.MONITOR)
    public void command(PlayerCommandPreprocessEvent e) {
        add("ev", "PlayerCommandPreprocessEvent", e.getMessage());
    }

    @EventHandler(priority = EventPriority.MONITOR)
    public void asyncTab(AsyncTabCompleteEvent e) {
        add("ev", "AsyncTabCompleteEvent", e.getBuffer());
    }

    @EventHandler(priority = EventPriority.MONITOR)
    public void tab(TabCompleteEvent e) {
        add("ev", "TabCompleteEvent", e.getBuffer() + " -> " + e.getCompletions());
    }

    @EventHandler(priority = EventPriority.MONITOR)
    public void sendSuggestions(AsyncPlayerSendSuggestionsEvent e) {
        add("ev", "AsyncPlayerSendSuggestionsEvent", e.getBuffer() + " -> " + e.getSuggestions().getList().stream().map(s -> s.getText()).toList());
    }

    @EventHandler(priority = EventPriority.MONITOR)
    public void damage(BlockDamageEvent e) {
        add("ev", "BlockDamageEvent", b(e.getBlock()) + " " + e.getBlock().getType() + (e.getInstaBreak() ? " insta" : ""));
        add("ev", "breakSpeed", String.format(Locale.ROOT, "%.4f ground=%s", e.getBlock().getBreakSpeed(e.getPlayer()), ((CraftPlayer) e.getPlayer()).getHandle().onGround()));
    }

    @EventHandler(priority = EventPriority.MONITOR)
    public void abort(BlockDamageAbortEvent e) {
        add("ev", "BlockDamageAbortEvent", b(e.getBlock()));
    }

    @EventHandler(priority = EventPriority.HIGHEST)
    public void breakBlock(BlockBreakEvent e) {
        Location c = cancelBreak;
        if (c != null && e.getBlock().getLocation().equals(c)) e.setCancelled(true);
        add("ev", "BlockBreakEvent", b(e.getBlock()) + " " + e.getBlock().getType() + (e.isCancelled() ? " cancelled" : ""));
    }

    @EventHandler(priority = EventPriority.MONITOR)
    public void interact(PlayerInteractEvent e) {
        add("ev", "PlayerInteractEvent", e.getAction() + " " + e.getHand() + " " + (e.getItem() == null ? "AIR" : e.getItem().getType())
                + (e.getClickedBlock() == null ? "" : " " + b(e.getClickedBlock())));
    }

    @EventHandler(priority = EventPriority.MONITOR)
    public void stopUsing(PlayerStopUsingItemEvent e) {
        add("ev", "PlayerStopUsingItemEvent", e.getItem().getType() + " held=" + e.getTicksHeldFor());
    }

    @EventHandler(priority = EventPriority.MONITOR)
    public void swap(PlayerSwapHandItemsEvent e) {
        add("ev", "PlayerSwapHandItemsEvent", (e.getOffHandItem() == null ? "AIR" : e.getOffHandItem().getType()) + " to offhand");
    }

    @EventHandler(priority = EventPriority.MONITOR)
    public void held(PlayerItemHeldEvent e) {
        add("ev", "PlayerItemHeldEvent", e.getPreviousSlot() + "->" + e.getNewSlot());
    }

    @EventHandler(priority = EventPriority.MONITOR)
    public void sneak(PlayerToggleSneakEvent e) {
        add("ev", "PlayerToggleSneakEvent", String.valueOf(e.isSneaking()));
    }

    @EventHandler(priority = EventPriority.MONITOR)
    public void input(PlayerInputEvent e) {
        var i = e.getInput();
        StringBuilder s = new StringBuilder();
        if (i.isForward()) s.append("forward+");
        if (i.isBackward()) s.append("backward+");
        if (i.isLeft()) s.append("left+");
        if (i.isRight()) s.append("right+");
        if (i.isJump()) s.append("jump+");
        if (i.isSneak()) s.append("shift+");
        if (i.isSprint()) s.append("sprint+");
        add("ev", "PlayerInputEvent", s.toString() + (e.getPlayer().getGameMode() == GameMode.SPECTATOR ? " spectator" : ""));
    }

    @EventHandler(priority = EventPriority.MONITOR)
    public void jump(PlayerJumpEvent e) {
        add("ev", "PlayerJumpEvent", String.format(Locale.ROOT, "%.2f", e.getFrom().getY()));
    }

    @EventHandler(priority = EventPriority.MONITOR)
    public void move(PlayerMoveEvent e) {
        add("ev", "PlayerMoveEvent", "");
    }

    @EventHandler(priority = EventPriority.MONITOR)
    public void swing(PlayerAnimationEvent e) {
        add("ev", e instanceof PlayerArmSwingEvent s ? "PlayerArmSwingEvent" : "PlayerAnimationEvent", e.getAnimationType().name());
    }

    @EventHandler(priority = EventPriority.MONITOR)
    public void preAttack(PrePlayerAttackEntityEvent e) {
        add("ev", "PrePlayerAttackEntityEvent", e.getAttacked().getType() + " " + e.getAttacked().getEntityId());
    }

    @EventHandler(priority = EventPriority.HIGHEST)
    public void hurt(EntityDamageByEntityEvent e) {
        if (!(e.getDamager() instanceof Player)) return;
        boolean ours = spawned.contains(e.getEntity());
        if (ours) e.setCancelled(true);
        add("ev", "EntityDamageByEntityEvent", e.getEntity().getType() + " " + e.getEntity().getEntityId() + " " + e.getCause());
    }

    @EventHandler(priority = EventPriority.MONITOR)
    public void interactEntity(PlayerInteractEntityEvent e) {
        String n = e instanceof PlayerInteractAtEntityEvent ? "PlayerInteractAtEntityEvent" : "PlayerInteractEntityEvent";
        add("ev", n, e.getRightClicked().getType() + " " + e.getRightClicked().getEntityId() + " " + e.getHand());
    }

    @EventHandler(priority = EventPriority.MONITOR)
    public void unknown(PlayerUseUnknownEntityEvent e) {
        add("ev", "PlayerUseUnknownEntityEvent", e.getEntityId() + (e.isAttack() ? " attack" : " interact") + " " + e.getHand());
    }

    @EventHandler(priority = EventPriority.MONITOR)
    public void open(InventoryOpenEvent e) {
        add("ev", "InventoryOpenEvent", e.getInventory().getType().name());
    }

    @EventHandler(priority = EventPriority.MONITOR)
    public void click(InventoryClickEvent e) {
        add("ev", "InventoryClickEvent", e.getRawSlot() + " " + e.getClick() + " " + (e.getCurrentItem() == null ? "AIR" : e.getCurrentItem().getType()));
    }

    @EventHandler(priority = EventPriority.MONITOR)
    public void close(InventoryCloseEvent e) {
        add("ev", "InventoryCloseEvent", e.getInventory().getType().name() + " " + e.getReason());
    }

    // ---- commands ----

    static boolean run(String name, Map<String, String> q, Player p, Map<String, Object> r) throws Exception {
        switch (name) {
            case "in.arrange" -> arrange(p, q, r);
            case "in.seq" -> {
                synchronized (Input.class) {
                    r.put("seq", log.size());
                }
            }
            case "in.ground" -> {
                var h = ((CraftPlayer) p).getHandle();
                r.put("ground", h.onGround());
                r.put("y", h.getY());
                r.put("flying", p.isFlying());
                r.put("gt", gameTicks());
                r.put("age", h.tickCount);
            }
            case "in.tabpool" -> {
                // Suggestion probe: Paper hands every suggestion request to a 4 thread pool; 1 keeps their order.
                var f = net.minecraft.server.network.ServerGamePacketListenerImpl.class.getDeclaredField("TAB_COMPLETE_EXECUTOR");
                f.setAccessible(true);
                var ex = (java.util.concurrent.ThreadPoolExecutor) f.get(null);
                int n = Integer.parseInt(q.get("n"));
                if (n < ex.getCorePoolSize()) {
                    ex.setCorePoolSize(n);
                    ex.setMaximumPoolSize(n);
                } else {
                    ex.setMaximumPoolSize(n);
                    ex.setCorePoolSize(n);
                }
                r.put("core", ex.getCorePoolSize());
                r.put("max", ex.getMaximumPoolSize());
            }
            case "in.log" -> r.put("log", new RawJson(since(Integer.parseInt(q.getOrDefault("since", "0")))));
            case "in.lag" -> {
                long ms = Long.parseLong(q.get("ms"));
                int after = Integer.parseInt(q.getOrDefault("after", "1"));
                Bukkit.getScheduler().runTaskLater(plugin, () -> {
                    try {
                        Thread.sleep(ms);
                    } catch (InterruptedException ignored) {
                    }
                }, after);
            }
            default -> {
                return false;
            }
        }
        return true;
    }

    record RawJson(String json) {}

    /** Puts the player and the scene the op needs at home. Every op starts from the same state. */
    static void arrange(Player p, Map<String, String> q, Map<String, Object> r) {
        String op = q.get("op");
        World w = p.getWorld();
        for (Entity e : spawned) e.remove();
        spawned.clear();
        var conn = ((CraftPlayer) p).getHandle().connection;
        if (packetPigShown) {
            conn.send(new ClientboundRemoveEntitiesPacket(PACKET_PIG));
            packetPigShown = false;
        }
        for (int x = -4; x <= 4; x++) for (int y = Y; y <= Y + 2; y++) for (int z = -4; z <= 6; z++) w.getBlockAt(x, y, z).setType(Material.AIR, false);
        cancelBreak = null;
        p.closeInventory();
        p.setGameMode(GameMode.valueOf(q.getOrDefault("mode", "SURVIVAL")));
        p.setFlying(false);
        p.setSneaking(false);
        p.setFallDistance(0);
        p.setVelocity(new org.bukkit.util.Vector());
        p.teleport(new Location(w, 0.5, Y, 0.5, 0f, 0f));
        PlayerInventory inv = p.getInventory();
        inv.clear();
        inv.setItem(0, new ItemStack(Material.SPYGLASS));
        inv.setItem(1, new ItemStack(Material.STICK));
        inv.setItem(2, new ItemStack(Material.DIAMOND, 5));
        inv.setItem(3, new ItemStack(Material.APPLE, 3));
        inv.setHeldItemSlot(Integer.parseInt(q.getOrDefault("slot", "0")));
        p.setItemOnCursor(null);
        switch (op) {
            case "break" -> {
                Block b = w.getBlockAt(0, Y, 2);
                b.setType(Material.valueOf(q.getOrDefault("material", "DIRT")), false);
                if (b.getBlockData() instanceof org.bukkit.block.data.type.Leaves leaves) {
                    leaves.setPersistent(true);
                    b.setBlockData(leaves, false);
                }
                if ("1".equals(q.get("cancel"))) cancelBreak = b.getLocation();
                r.put("x", 0);
                r.put("y", Y);
                r.put("z", 2);
            }
            case "attack", "interact" -> {
                boolean packet = "1".equals(q.get("packet"));
                double x = packet ? -1.5 : 1.5, z = 2.5;
                if (packet) {
                    conn.send(new ClientboundAddEntityPacket(PACKET_PIG, UUID.randomUUID(), x, Y, z, 0f, 0f, net.minecraft.world.entity.EntityTypes.PIG, 0, Vec3.ZERO, 0));
                    packetPigShown = true;
                    r.put("entity", PACKET_PIG);
                } else {
                    Pig pig = w.spawn(new Location(w, x, Y, z), Pig.class, e -> {
                        e.setAI(false);
                        e.setSilent(true);
                        e.setPersistent(false);
                    });
                    spawned.add(pig);
                    r.put("entity", pig.getEntityId());
                }
                r.put("x", x);
                r.put("y", Y + 0.45);
                r.put("z", z);
            }
            case "move" -> {
                r.put("x", 0.5);
                r.put("z", 4.5);
            }
            default -> {}
        }
        r.put("pos", "0.5," + Y + ",0.5");
    }

    static long micros() {
        Instant now = Instant.now();
        return now.getEpochSecond() * 1_000_000L + now.getNano() / 1000;
    }

    static String q(String s) {
        return '"' + s.replace("\\", "\\\\").replace("\"", "\\\"").replace("\n", " ") + '"';
    }
}
