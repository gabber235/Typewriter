# Commands

A command is three things at once: a [hold](interactions.md#holds) (it exists for a player now, contributed by a derive), an event (it ran, and can be denied), and data (the tree). Every player has one tree of their own, and extensions and creators add to it without knowing about each other. Decided 2026-11-05 in the layer 5 rough design.

Nothing here is built yet. See [Not proven](#not-proven).

## End to end in code

Scenario: `/claim <amount>` exists only while a reward waits.

### 1. An event, and a hold with its nodes

A contribution is a data class whose `nodes` are built with a small data DSL: `literal`, `argument`, `permission`, `runs<Event>()`. A node that can run names a typed event whose fields are filled from the path arguments by name; KSP checks this on every path. A `Protagonist` field with no matching argument is the caller.

```kotlin
@TypewriterType(id = "...")
data class ClaimReward(val who: Protagonist, val amount: Int) : Event

data class ClaimCommand(@Key val who: Protagonist) : CommandContribution {
    override val nodes = literal("claim") {
        argument("amount", Int) { runs<ClaimReward>() }
    }
}
```

### 2. A derive decides when it exists

```kotlin
@Derive
fun PendingReward.command(who: Protagonist) = ClaimCommand(who)
```

### 3. Core puts it in the shared tree

Paper has one dispatcher for the whole server, so the tree holds the union of every contribution. Each node asks whether this player has it right now, which gives every player their own tree when parsing, suggesting, and sending.

```kotlin
@Handler
fun Added<CommandContribution>.install(tree: CommandTree) = tree.add(value.nodes)   // once per engine

@Handler
fun Added<CommandContribution>.send(commands: HasCommands) = commands.refresh()     // per connection

literal("claim").requires { source -> tree.has(source, path) }
```

`refresh` calls `Player.updateCommands()` at most once a tick. `Changed` and `Removed` update the same table.

### 4. The player runs it

Running a node emits its event, so ordinary handlers decide and react.

```kotlin
@Handler
fun ClaimReward.deny(reward: PendingReward): Verdict = if (amount > reward.amount) deny else pass

@Handler
fun ClaimReward.give(wallet: Coins, reward: PendingReward) = ...
```

### 5. The reward is gone

The derive stops, then grace, then `Removed`. `requires` turns false and the client gets a new tree. The node stays in the tree, invisible, so nothing needs removing. Legacy removes commands through reflection (`TypewriterCommandManager.kt`).

## End to end in content

Legacy has one entry per argument type. There is one generic entry, with `T` picked.

```
CommandEntry "claim"
  aliases:   ["c"]
  available: protagonist.rewards > 0
  child: ArgumentEntry<Int> "amount"
           choices: [1, 5, 10]
           triggers: GiveCoins(coins = amount.value)
```

- `LiteralEntry` is the third kind, as `LiteralCommandArgument` is in legacy.
- `available` is a tracked formula. False hides the command, so it replaces permission checks in content and adds commands that depend on state.
- `choices` is an optional formula, so suggestions can come from state.
- `amount.value` is a chain record through `produces { field("value", T) }` ([formula-language.md](formula-language.md)), replacing `WordArgumentContextKeys` and its siblings.
- A type works as `T` when a `CommandArgument<T>` object exists for it, found by supertype. An extension adds its own the same way. The bound on `T` refuses other types.

```kotlin
@Derive
fun CommandEntry.contribute(who: Protagonist, available: Boolean) =
    if (available) ContentCommand(who, this) else null
```

A node with triggers runs `ContentCommandRan(node, args)`, whose handler fires the node's triggers with the arguments as context.

## Other needs

| Need | How |
| --- | --- |
| `/tw fire <player> <entry>` | Held by `Engine`, so it reaches every player and the console. The target comes first, so suggestions follow it |
| An extension adds `/tw quest` | Its contribution also starts with `literal("tw")`, and the nodes merge. `@TypewriterCommand` and its loader scan go away |
| `/accept` during a dialogue | Derived from the step's stored value |
| Detect or cancel another plugin's command | `CancelableEventEntry<CommandLine>`, the [shared event entry](events-and-handlers.md#event-entries), from `PlayerCommandPreprocessEvent`. A condition formula replaces the regex field |
| Permissions | `permission("typewriter.fire")` on a node. Content uses `available` |
| Suggestions from state in code | `argument("quest", oneOf(active))` in a derive. The derive is tracked, so the data stays current, with no lambda |
| Run a command | The `ConsoleCommand` and `PlayerCommand` actions |
| Run for someone else | `who` as a path argument. The caller stays available through `Origin` |

## Merging

- **One tree per player.** There is no path or branch concept. A root command is just a literal node. Each contribution inserts its nodes where they match existing ones.
- **What merges.** The same literal, or the same argument name and type.
- **Two runs at one node.** The highest hold priority runs, which also resolves the same name from two books. A tie is a check warning.
- **Applicability.** Commands from a book that does not apply to a player are hidden for that player.

## Another plugin has the same command

Merging the way legacy does replaces the other plugin's command for every player, also for those who do not have ours (tested on Brigadier). Ours wins only for players who have it (decided 2026-11-05):

```kotlin
literal("claim")
    .requires { ours(it) || theirs(it) }
    .executes { if (ours(source)) emit() else theirsRun() }
// Their children are hidden from holders. Our children are only for holders.
```

A command everyone has therefore replaces theirs, as in legacy, and `/accept` during a dialogue leaves the other plugin's `/accept` working for everyone else. The tree reinstalls this when Paper fires `LifecycleEvents.COMMANDS` again.

## When things go differently

| Case | What happens |
| --- | --- |
| Run during the grace | The event fires, but `PendingReward` is missing, so the handler does not run. The caller sees `NotHandled` |
| Target on another server | The event routes to the engine that holds them |
| Hot publish | Derives rerun. Old nodes stay, invisible |
| Server move | The new server's derives install them there |
| Browser tab | It has no `HasCommands`, so that handler skips it |
| Console | Has no protagonist, so only `Engine` held commands reach it, and an event with no matching argument for its `Protagonist` field is refused |

## What it removes

- The 7 legacy argument entry files, `RunCommandEventEntry`, and `DetectCommandRanEventEntry`.
- `@TypewriterCommand`, the loader's scan for it, and `DslCommandTree`.
- Reflection to remove commands.
- `/tw reload`, because publishing is live. Other `/tw` commands land with their layers.

## Not proven

- **Ran, on Brigadier 1.3.10 and the classes in Paper 26.2's jar, with a throwaway test:** one tree where `/claim 5` is an int for one player and a word for another; usage and rejection that differ per player; a node added while running; access removed with no rebuild; and the wrap above, where neither side reaches the other's arguments.
- **Not run on a server or a real client.** `updateCommands`, keeping the dispatcher after the lifecycle event (legacy does this), and Paper's `BukkitCommandNode` are read from code only. Whether the wrap works over a `BukkitCommandNode` is the first thing to test.
- **Cost.** One hold per player per content command, so 500 players with 20 commands is 10,000 holds. A command with no `available` could be held by `Engine`.
- **Console replies.** The console has no session, so `Origin` needs a way to answer it.
- **A parent type as a lifecycle parameter.** `Added<CommandContribution>` has no precedent.
- **`Protagonist` arguments.** A name can reach the whole network through `sessions`, but a selector such as `@a` only sees this server.
- **Who a content node runs for.** A `runsFor` formula that defaults to the caller is the likely form.
- **Nodes as hold values.** A hold's value is compared each rerun, so the node data must compare by value.
