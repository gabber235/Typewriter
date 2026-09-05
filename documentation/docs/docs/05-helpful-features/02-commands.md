---
difficulty: Easy
---

# Commands

The Typewriter plugin has some handy commands. Below is a table of these commands:

:::tip[Types]
Some arguments are optional `[]` and some a required `<>`.\
An entry argument accepts the entry identifier and the entry name.
:::

| Command Name                                     | Description                                            | Permissions                     |
| ------------------------------------------------ | ------------------------------------------------------ | ------------------------------- |
| `/tw connect`                                    | Connects you to the typewriter panel.                  | typewriter.connect              |
| `/tw clearChat`                                  | Clears the chat for you in the way typewriter does it. | typewriter.clearChat            |
| `/tw cinematic <start/stop> <pageName> [player]` | plays the chosen cinematic for a specific player.      | typewriter.cinematic.start/stop |
| `/tw reload`                                     | Reloads the plugin.                                    | typewriter.reload               |
| `/tw facts [player]`                             | Gets all the facts of a specific player.               | typewriter.facts                |
| `/tw facts set <factEntry> <value> [player]`     | Sets a fact of a specific player                       | typewriter.facts.set            |
| `/tw facts reset`                                | Resets all the facts of a specific player              | typewriter.facts.reset          |
| `/tw trigger <entry> [player]`                   | triggers an entry for a specific player.               | typewriter.trigger              |
| `/tw assets clean`                               | Clears all assets that are not used.                   | typewriter.assets.clean         |
| `/tw fire <entry> [player]`                      | trigger a fire trigger event entry.                    | typewriter.fire                 |
| `/tw manifest inspect [player]`                  | Inspect the active manifests of a player               | typewriter.manifest.inspect     |
| `/tw quest track <questEntry> [player]`          | Start following a quest for a player.                  | typewriter.quest.track          |
| `/tw untrack [player]`                           | Unfollow the quest of a player.                        | typewriter.quest.untrack        |
| `/tw roadNetwork edit <roadNetworkEntry>`        | Edit a roadNetwork.                                    | typewriter.roadNetwork.edit     |
| `/tw region visualize [definitionEntry] [single/multiple] [seconds]` | Shows a region's boundary; without a region it hides all shown boundaries. | typewriter.region.visualize     |
| `/tw region edit [definitionEntry]`              | Open the in-game region editor, or the multi region workspace without an entry. | typewriter.region.edit          |
| `/tw region debug <definitionEntry>`             | Open the region debugger HUD for a region.             | typewriter.region.debug         |
| `/tw region flags [seconds]`                     | Reports the region flags where you stand and are looking, and highlights the judged block. | typewriter.region.flags         |
