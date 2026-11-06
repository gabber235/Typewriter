package probe.mod.observe.mixin;

import java.util.Map;
import java.util.UUID;
import net.minecraft.client.gui.components.BossHealthOverlay;
import net.minecraft.client.gui.components.LerpingBossEvent;
import org.spongepowered.asm.mixin.Mixin;
import org.spongepowered.asm.mixin.gen.Accessor;

/** Flexibility test: the one private field A1 needs to know about boss bars. */
@Mixin(BossHealthOverlay.class)
public interface BossAccessor {
    @Accessor("events") Map<UUID, LerpingBossEvent> probe$events();
}
